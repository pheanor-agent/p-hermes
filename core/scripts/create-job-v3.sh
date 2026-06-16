#!/bin/bash
#==============================================================================
# create-job.sh - 새 작업 생성 스크립트 (v3)
#
# JOB-1288: 전면 개선
#   - flock 기반 원자적 락 메커니즘
#   - 중복 번호 자동 재할당
#   - sanitize_title 일관성 확보
#   - workflow-state JSON 양식 통일
#
# 사용법:
#   create-job.sh -y 기능 "새 이미지 생성 스킬 구현"
#   create-job.sh --parent JOB-1007 -y 정리 "파생 작업"
#   create-job.sh --dry-run 조사 "AI 트렌드 조사"
#
#==============================================================================

set -euo pipefail

# ─── 경로 설정 ───
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$HERMES_ROOT/workspace"
JOBS_DIR="$WORKSPACE/jobs"
JOB_QUEUE="$WORKSPACE/JOB-QUEUE.md"
JOB_INDEX="$WORKSPACE/JOB-INDEX.md"
LOCK_FILE="/tmp/.create-job.lock"

# ─── 옵션 변수 ───
YES_MODE=false
DRY_RUN=false
DEBUG=false
PARENT_JOB=""

# ─── 로그 ───
log_info()  { echo "[INFO] $*" >&2; }
log_debug() { [[ "${DEBUG}" == "true" ]] && echo "[DEBUG] $*" >&2 || true; }
log_error() { echo "[ERROR] $*" >&2; }

# ─── 도움말 ───
show_help() {
    cat << 'EOF'
사용법: create-job.sh [OPTIONS] <유형> <작업 내용>

OPTIONS:
    -h, --help          이 도움말 표시
    -y, --yes           확인 건너뛰기
    -n, --dry-run       실제 수정 없이 결과만 표시
    -d, --debug         디버그 출력
    -p, --parent JOB    부모 JOB 번호 (연계 작업)

유형: 기능 | 수정 | 조사 | 정리 | 운영 | 개선 | 시스템 | 기타

예시:
    create-job.sh -y 기능 "새 스킬 구현"
    create-job.sh --parent JOB-1007 -y 정리 "파생 작업"
    create-job.sh --dry-run 조사 "AI 트렌드"
EOF
}

# ─── 다음 JOB 번호 (디렉토리 스캔 + 중복 검증) ───
get_next_job_number() {
    local max_num=0
    for d in "$JOBS_DIR"/JOB-*/; do
        [[ -d "$d" ]] || continue
        local basename
        basename=$(basename "$d")
        local num
        num=$(echo "$basename" | sed 's/^JOB-//' | grep -oP '^\d+' 2>/dev/null || true)
        [[ -n "$num" ]] && [[ "$num" =~ ^[0-9]+$ ]] && [[ "$num" -gt "$max_num" ]] && max_num=$num
    done
    echo $((max_num + 1))
}

# ─── 중복 번호 검증 및 재할당 ───
validate_and_reassign() {
    local requested_num=$1
    local attempts=0
    local max_attempts=10

    while [[ $attempts -lt $max_attempts ]]; do
        local test_num=$((requested_num + attempts))
        local count=0

        for d in "$JOBS_DIR"/JOB-${test_num}-*/; do
            [[ -d "$d" ]] && count=$((count + 1))
        done

        if [[ $count -eq 0 ]]; then
            echo "$test_num"
            return 0
        fi

        attempts=$((attempts + 1))
    done

    log_error "번호 할당 실패 (최대 시도 횟수 초과)"
    return 1
}

# ─── 제목 sanitize (일관성 확보) ───
sanitize_title() {
    local title="$1"
    # 슬래시 → 하이픈 (JOB-1167: 디렉토리 생성 방지)
    title=$(echo "$title" | tr '/' '-')
    # 콜론 → 하이픈 (Windows/Unix 호환성)
    title=$(echo "$title" | tr ':' '-')
    # 공백/탭/줄바꿈 → 하이픈
    title=$(echo "$title" | tr '\t\n' '  ' | sed 's/[[:space:]]\+/-/g')
    # 선행/후행 하이픈 제거
    title=$(echo "$title" | sed 's/^-*//;s/-*$//')
    # 연속 하이픈 → 단일
    title=$(echo "$title" | sed 's/--\+/-/g')
    # 80자 제한
    title=$(echo "$title" | cut -c1-80)
    # 빈 제목 검증
    if [[ -z "$title" ]]; then
        log_error "제목이 비어있습니다"
        exit 1
    fi
    echo "$title"
}

# ─── 부모 JOB 검증 ───
validate_parent() {
    local parent="$1"
    if [[ ! "$parent" =~ ^JOB-[0-9]+$ ]]; then
        log_error "잘못된 부모 JOB 형식: $parent (JOB-XXXX 형식 필요)"
        exit 1
    fi
    local parent_dir=""
    for d in "$JOBS_DIR"/"${parent}"-*/; do
        [[ -d "$d" ]] && parent_dir="$d" && break
    done
    if [[ -z "$parent_dir" ]]; then
        log_error "부모 JOB 디렉토리 없음: $parent"
        exit 1
    fi
    echo "$parent_dir"
}

# ─── 옵션 파싱 ───
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)     show_help; exit 0 ;;
        -y|--yes)      YES_MODE=true; shift ;;
        -n|--dry-run)  DRY_RUN=true; shift ;;
        -d|--debug)    DEBUG=true; shift ;;
        -p|--parent)   PARENT_JOB="$2"; shift 2 ;;
        -*)            log_error "알 수 없는 옵션: $1"; show_help >&2; exit 1 ;;
        *)             break ;;
    esac
done

# ─── 인수 확인 ───
if [[ $# -lt 2 ]]; then
    log_error "유형과 작업 내용을 입력해주세요"
    echo "사용법: create-job.sh <유형> <작업 내용>" >&2
    exit 1
fi

JOB_TYPE="$1"
shift
JOB_CONTENT="$*"

# ─── 유형 검증 ───
case "$JOB_TYPE" in
    기능|수정|조사|정리|운영|개선|시스템|기타) ;;
    *) log_error "잘못된 유형: $JOB_TYPE (기능|수정|조사|정리|운영|개선|시스템|기타)"; exit 1 ;;
esac

# ─── 부모 검증 ───
PARENT_DIR=""
PARENT_NUM=""
if [[ -n "$PARENT_JOB" ]]; then
    PARENT_DIR=$(validate_parent "$PARENT_JOB")
    PARENT_NUM=$(echo "$PARENT_JOB" | grep -oP '\d+')
    log_info "부모 JOB: $PARENT_JOB"
fi

# ─── dry-run은 락 스킵 ───
if [[ "${DRY_RUN}" != "true" ]]; then
    log_info "락 획득 중 (30초 타임아웃)..."
    if ! exec 200>"$LOCK_FILE"; then
        log_error "락 파일 생성 실패: $LOCK_FILE"
        exit 1
    fi
    flock -w 30 200 || {
        log_error "락 획득 실패 (30초 대기 후 타임아웃)"
        exit 1
    }
    log_debug "락 획득 완료"
fi

# ─── JOB 번호 산정 + 중복 검증 ───
JOB_NUM=$(get_next_job_number)
JOB_NUM=$(validate_and_reassign "$JOB_NUM") || {
    log_error "JOB 번호 자동 재할당 실패"
    exit 1
}
JOB_ID="JOB-${JOB_NUM}"
log_info "JOB 번호: $JOB_ID"

# ─── 폴더명 생성 ───
FOLDER_TITLE=$(sanitize_title "$JOB_CONTENT")
FOLDER_NAME="${JOB_ID}-${FOLDER_TITLE}"
JOB_FOLDER="$JOBS_DIR/$FOLDER_NAME"

# ─── 중복 폴더 검증 (최종) ───
if [[ -d "$JOB_FOLDER" ]] && [[ "${DRY_RUN}" != "true" ]]; then
    log_error "폴더 이미 존재: $JOB_FOLDER"
    log_info "자동 재할당 시도..."
    JOB_NUM=$(validate_and_reassign $((JOB_NUM + 1))) || exit 1
    JOB_ID="JOB-${JOB_NUM}"
    FOLDER_NAME="${JOB_ID}-${FOLDER_TITLE}"
    JOB_FOLDER="$JOBS_DIR/$FOLDER_NAME"
fi

# ─── 정보 출력 ───
echo ""
echo "=== JOB 생성 정보 ==="
echo "  번호: $JOB_ID"
echo "  유형: $JOB_TYPE"
echo "  제목: $JOB_CONTENT"
echo "  폴더: $JOB_FOLDER"
[[ -n "$PARENT_JOB" ]] && echo "  부모: $PARENT_JOB"
echo ""

# ─── 확인 (dry-run이면 스킵) ───
if [[ "${YES_MODE}" != "true" ]] && [[ "${DRY_RUN}" != "true" ]]; then
    read -r -p "위 내용으로 생성하시겠습니까? (y/n): " answer
    [[ "$answer" =~ ^[Yy]$ ]] || { log_info "취소됨"; exit 0; }
fi

# ─── dry-run ───
if [[ "${DRY_RUN}" == "true" ]]; then
    echo ""
    echo "=== DRY-RUN: 생성될 파일 ==="
    echo "--- .workflow-state ---"
    echo "request"
    echo ""
    echo "--- request.md ---"
    cat << DRYEOF
# ${JOB_ID}: ${JOB_CONTENT}

## 요청
> ${JOB_CONTENT}

## 배경
${PARENT_JOB:+관련 작업: ${PARENT_JOB}}

## 범위
(조사 후 작성)
DRYEOF
    echo ""
    echo "--- JOB-QUEUE.md append ---"
    echo "### ${JOB_ID}: ${JOB_CONTENT} — 대기중 ${PARENT_JOB:+(← ${PARENT_JOB} 파생)}"
    echo ""
    echo "--- JOB-INDEX.md append ---"
    echo "| ${JOB_NUM} | $(date '+%Y-%m-%d') | ${JOB_TYPE} | ${JOB_CONTENT} | 대기 |"
    exit 0
fi

# ─── 폴더 생성 (atomic) ───
if ! mkdir "$JOB_FOLDER" 2>/dev/null; then
    log_error "폴더 생성 실패: $JOB_FOLDER"
    log_info "JOB 번호를 재계산합니다..."
    JOB_NUM=$(validate_and_reassign $((JOB_NUM + 1))) || exit 1
    JOB_ID="JOB-${JOB_NUM}"
    FOLDER_NAME="${JOB_ID}-${FOLDER_TITLE}"
    JOB_FOLDER="$JOBS_DIR/$FOLDER_NAME"
    mkdir "$JOB_FOLDER" || { log_error "재시도 실패"; exit 1; }
fi

# ─── .workflow-state 생성 (JSON 통일) ───
NOW=$(date -u +"%Y-%m-%dT%H:%M:%S+09:00")
cat > "$JOB_FOLDER/.workflow-state" << STATEEOF
{
  "jobId": "$JOB_ID",
  "status": "running",
  "currentStep": "request",
  "steps": [
    { "name": "request", "status": "in_progress", "startedAt": "$NOW" },
    { "name": "investigation", "status": "pending" },
    { "name": "design", "status": "pending" },
    { "name": "review", "status": "pending" },
    { "name": "approval", "status": "pending" },
    { "name": "execution", "status": "pending" },
    { "name": "test", "status": "pending" },
    { "name": "execution_review", "status": "pending" },
    { "name": "done", "status": "pending" }
  ],
  "startedAt": "$NOW",
  "updatedAt": "$NOW",
  "artifacts": []
}
STATEEOF
log_debug ".workflow-state → JSON (request)"

# ─── request.md 생성 ───
cat > "$JOB_FOLDER/request.md" << REQEOF
# ${JOB_ID}: ${JOB_CONTENT}

## 요청
> ${JOB_CONTENT}
${PARENT_JOB:+
## 교훈: ${PARENT_JOB} 파생 작업
이 작업은 ${PARENT_JOB}에서 파생됨
}
## 범위
(조사 후 작성)
REQEOF
log_debug "request.md 생성"

# ─── JOB-QUEUE.md append ───
echo "### ${JOB_ID}: ${JOB_CONTENT} — 대기중 ${PARENT_JOB:+(← ${PARENT_JOB} 파생)}" >> "$JOB_QUEUE"
log_debug "JOB-QUEUE.md 갱신"

# ─── JOB-INDEX.md append ───
echo "| ${JOB_NUM} | $(date '+%Y-%m-%d') | ${JOB_TYPE} | ${JOB_CONTENT} | 대기 |" >> "$JOB_INDEX"
log_debug "JOB-INDEX.md 갱신"

# ─── 부모 backlink ───
if [[ -n "$PARENT_JOB" ]] && [[ -n "$PARENT_DIR" ]]; then
    parent_req="$PARENT_DIR/request.md"
    if [[ -f "$parent_req" ]]; then
        if ! grep -q "파생 작업" "$parent_req" 2>/dev/null; then
            echo "" >> "$parent_req"
            echo "## 파생 작업" >> "$parent_req"
        fi
        echo "- ${JOB_ID}: ${JOB_CONTENT}" >> "$parent_req"
        log_debug "부모 backlink 추가: $PARENT_JOB"
    fi
fi

# ─── 락 해제 ───
if [[ "${DRY_RUN}" != "true" ]]; then
    exec 200>&-
    log_debug "락 해제"
fi

# ─── 결과 출력 ───
echo ""
echo "=== ${JOB_ID} 생성 완료 ==="
echo "  폴더: ${JOB_FOLDER}"
echo "  유형: ${JOB_TYPE}"
echo "  제목: ${JOB_CONTENT}"
[[ -n "$PARENT_JOB" ]] && echo "  부모: $PARENT_JOB"
echo "  다음: 조사 → 설계 → 리뷰 → 승인 → 실행"

exit 0
