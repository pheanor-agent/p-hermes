#!/bin/bash
set -euo pipefail
HERMES_ROOT="${HERMES_ROOT:-$HOME/.hermes}"

# ─── 원자적 쓰기 라이브러리 ────────────────────────────────────────────────
# JOB-1611 P0: 파일 쓰기 원자성 보장 (tmp → sync → mv)
source $HERMES_ROOT/core/scripts/lib/atomic.sh 2>/dev/null || true

# ─── 이벤트 버스 연동 (JOB-1621) ──────────────────────────────────────────
source "$HERMES_ROOT/core/skills/shared/system-common/lib/event.sh" 2>/dev/null || true
source "$HERMES_ROOT/core/skills/shared/system-common/lib/log.sh" 2>/dev/null || true

# 상관 ID 생성
WF_CORRELATION_ID="WF-$(date +%Y%m%d-%H%M)-$$"
export WF_CORRELATION_ID

# 원자적 상태 파일 업데이트 (workflow-gate 전용)
atomize_state_update() {
    local state_file="$1"
    local jq_filter="$2"
    
    local result
    result=$(jq "$jq_filter" "$state_file")
    atomic_write "$state_file" "$result"
}

# Workflow Gate: JOB 상태 관리 및 후처리 훅
# 사용법: workflow-gate.sh [--skip-spec-check] <JOB_ID> <start|complete|checkpoint>
#
# 역할:
# 1. .workflow-state JSON 업데이트
# 2. 완료 시 .done 파일 생성
# 3. 완료 시 post-job-hook.sh 비동기 호출
# 4. checkpoint: 검증 결과 파일 확인 (I15, I16, I-spec-ref, I-spec-matrix)
#
# 플래그:
#   --skip-spec-check  Spec 체크포인트 전체 스킵 (응급 override)

# ─── JOB 자동 백업 함수 (JOB-1622) ─────────────────────────────────────────

backup_job() {
    local job_id="$1"
    local job_dir="$2"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_dir="$HERMES_ROOT/backups/jobs/${job_id}-${timestamp}"
    
    # 디스크 공간 체크 (1GB 미만 시 경고 + 스킵)
    local available_space=$(df -BG "$HERMES_ROOT/backups" | tail -1 | awk '{print $4}' | sed 's/G//')
    if (( available_space < 1 )); then
        echo "⚠️  디스크 공간 부족 (${available_space}GB) — 백업 스킵"
        return 0  # 실패가 아닌 경고로 처리
    fi
    
    mkdir -p "$backup_dir"
    
    # 백업 (상태 파일 제외, symlink 제외)
    find "$job_dir" -maxdepth 1 -type f \
        ! -name ".workflow-state" \
        ! -name ".done" \
        ! -name ".workflow-audit.log" \
        -exec cp -a {} "$backup_dir/" \;
    
    echo "📦 JOB 백업: $backup_dir"
    return 0
}

# ─── 검증 체크포인트 함수 ────────────────────────────────────────────────

# I15: 화 단위 검증 결과 확인 (Phase 2.5)
validate_episode_checkpoint() {
  local ep_dir="$1"
  local ep_num="$2"
  local json_file="$ep_dir/ep${ep_num}-validation.json"
  
  # 1) 파일 존재 확인
  if [[ ! -f "$json_file" ]]; then
    echo "FAIL: I15 검증 결과 파일 부재 (${json_file})"
    return 1
  fi
  
  # 2) status 필드가 PASS인지 확인
  local status
  status=$(jq -r '.status // "FAIL"' "$json_file" 2>/dev/null || echo "FAIL")
  if [[ "$status" != "PASS" ]]; then
    echo "FAIL: I15 검증 상태 ${status} (PASS 필요)"
    return 1
  fi
  
  # 3) 에러 수 확인 (0이어야 함)
  local errors
  errors=$(jq -r '.stats.errors // 99' "$json_file" 2>/dev/null || echo "99")
  if (( errors > 0 )); then
    echo "FAIL: I15 검증 에러 ${errors}개"
    return 1
  fi
  
  echo "PASS: I15 ep${ep_num} 검증 완료"
  return 0
}

# I16: 장 단위 Coherence 검증 결과 확인 (Phase 3.5)
validate_coherence_checkpoint() {
  local chapter_dir="$1"
  local chapter_num="$2"
  
  local report="$chapter_dir/chapter-${chapter_num}-coherence-report.json"
  if [[ ! -f "$report" ]]; then
    echo "FAIL: I16 Coherence 리포트 부재"
    return 1
  fi
  
  local score
  score=$(jq -r '.overall_score // 0' "$report" 2>/dev/null || echo "0")
  if (( score < 70 )); then
    echo "FAIL: I16 Coherence 점수 ${score}/100 (최소 70 필요)"
    return 1
  fi
  
  echo "PASS: I16 장 ${chapter_num} Coherence 검증 완료 (점수: ${score})"
  return 0
}

# I-spec-ref: request.md에 Spec 참조(SPEC-XXX) 존재 여부 확인 (JOB-1498 P0)
validate_spec_ref_checkpoint() {
  local job_dir="$1"
  local request_file="$job_dir/request.md"

  if [[ ! -f "$request_file" ]]; then
    echo "SKIP: I-spec-ref request.md 부재 (${request_file})"
    return 0
  fi

  local spec_count=0
  spec_count=$(grep -cE 'SPEC-[A-Za-z0-9]+' "$request_file" 2>/dev/null) || true

  if (( spec_count == 0 )); then
    echo "SKIP: I-spec-ref Spec 참조 없음 (spec-free JOB — 검증 생략)"
    return 0
  fi

  echo "PASS: I-spec-ref Spec 참조 ${spec_count}개 확인"
  return 0
}

# I-spec-matrix: architecture.md에 Spec 연동 테이블 존재 여부 확인 (JOB-1498 P0)
validate_spec_matrix_checkpoint() {
  local job_dir="$1"
  local arch_file="$job_dir/architecture.md"

  if [[ ! -f "$arch_file" ]]; then
    echo "SKIP: I-spec-matrix architecture.md 부재"
    return 0
  fi

  # Spec 참조(SPEC-XXX) 또는 Spec 연동 테이블(예: "Spec", "spec_id" 등) 확인
  local has_spec_id=0
  has_spec_id=$(grep -cE 'SPEC-[A-Za-z0-9]+' "$arch_file" 2>/dev/null) || true

  local has_spec_table=0
  has_spec_table=$(grep -ciE '(spec.*연동|spec.*matrix|spec.*mapping|spec.*trace)' "$arch_file" 2>/dev/null) || true

  if (( has_spec_id == 0 && has_spec_table == 0 )); then
    echo "SKIP: I-spec-matrix Spec 연동 정보 없음 (spec-free JOB — 검증 생략)"
    return 0
  fi

  echo "PASS: I-spec-matrix Spec 연동 정보 확인 (spec_ref=${has_spec_id}, table_ref=${has_spec_table})"
  return 0
}

# helper: request.md에 Spec 참조가 있는지 여부 확인 (조건부 검증용)
has_spec_references() {
  local job_dir="$1"
  local request_file="$job_dir/request.md"

  [[ ! -f "$request_file" ]] && return 1
  grep -qE 'SPEC-[A-Za-z0-9]+' "$request_file" 2>/dev/null
}

JOB_ID="${1:-}"
ACTION="${2:-}"
MODEL_FALLBACK=""
SKIP_SPEC_CHECK=false

# 플래그 파싱 (--skip-spec-check, --model-fallback)
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --skip-spec-check)
      SKIP_SPEC_CHECK=true
      ;;
    --model-fallback)
      shift
      MODEL_FALLBACK="${1:-}"
      ;;
  esac
  shift
done
JOB_ID="${1:-}"
ACTION="${2:-}"

if [[ -z "$JOB_ID" || -z "$ACTION" ]]; then
    echo "Usage: $0 [--skip-spec-check] <JOB_ID> <action>"
    echo ""
    echo "Actions:"
    echo "  start              JOB 시작 (investigation 진입)"
    echo "  transition <step>  단계 전환 (design, review, approval, execution, test, execution_review, done)"
    echo "  auto-process       request → approval까지 자동 진행"
    echo "  complete           JOB 완료"
    echo "  checkpoint         검증 (I15, I16, I-spec-ref, I-spec-matrix)"
    echo ""
    echo "Examples:"
    echo "  $0 <JOB_ID> start"
    echo "  $0 <JOB_ID> transition design"
    echo "  $0 <JOB_ID> auto-process"
    echo "  $0 <JOB_ID> complete"
    echo "  $0 <JOB_ID> checkpoint I15 <ep_dir> <ep_num>"
    echo "  $0 <JOB_ID> checkpoint I16 <ch_dir> <ch_num>"
    echo "  $0 <JOB_ID> checkpoint I-spec-ref"
    echo "  $0 <JOB_ID> checkpoint I-spec-matrix"
    echo "  --skip-spec-check  Spec 체크포인트 전체 스킵 (응급 override)"
    exit 1
fi

# JOB 폴더 찾기 (JOB-XXXX-제목 형식)
JOB_DIR=""
for dir in "$HERMES_ROOT/workspace/jobs"/$JOB_ID-*; do
    if [[ -d "$dir" ]]; then
        JOB_DIR="$dir"
        break
    fi
done

if [[ -z "$JOB_DIR" ]]; then
    echo "ERROR: JOB directory not found for $JOB_ID"
    exit 1
fi

STATE_FILE="$JOB_DIR/.workflow-state"
NOW=$(date -u +"%Y-%m-%dT%H:%M:%S+09:00")

# 상태 파일 업데이트 후 JSON 유효성 검증 함수 (JOB-1601)
validate_state_file() {
    if ! jq '.' "$STATE_FILE" > /dev/null 2>&1; then
        echo "[ERROR] Invalid .workflow-state after update - attempting recovery" >&2
        # 백업에서 복구
        if [[ -f "${STATE_FILE}.bak" ]]; then
            cp "${STATE_FILE}.bak" "$STATE_FILE"
            echo "[INFO] Recovered from backup" >&2
        else
            echo "[FATAL] Cannot recover .workflow-state - manual intervention needed" >&2
            exit 1
        fi
    fi
}

# 상태 파일 존재 확인
if [[ ! -f "$STATE_FILE" ]]; then
    echo "ERROR: .workflow-state not found in $JOB_DIR"
    exit 1
fi

case "$ACTION" in
    start)
        # currentStep을 "investigation"으로 변경, request 단계 완료 처리
        jq --arg now "$NOW" '
            .currentStep = "investigation" |
            .updatedAt = $now |
            .steps = [.steps[] | if .name == "request" then .status = "done" | .completedAt = $now elif .name == "investigation" then .status = "in_progress" | .startedAt = $now else . end]
        ' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
        validate_state_file
        echo "JOB $JOB_ID started (investigation)."
        
        # ✅ JOB-1521: 지식 파일 자동 로딩
        if [[ -x "$HERMES_ROOT/core/scripts/pre-investigation.sh" ]]; then
            bash "$HERMES_ROOT/core/scripts/pre-investigation.sh" "$JOB_DIR"
        fi
        
        # ✅ JOB-1621: 이벤트 버스 발행
        if declare -f emit_event &>/dev/null; then
            emit_event "wf.started" "$WF_CORRELATION_ID" "{\"job_id\":\"$JOB_ID\",\"step\":\"investigation\"}" 2>/dev/null || true
        fi
        ;;
    auto-process)
        # ✅ JOB-1494: request → approval까지 자동 진행
        STEPS_TO_AUTO=("investigation" "design" "review" "approval")
        for step in "${STEPS_TO_AUTO[@]}"; do
            # 현재 단계 확인
            current=$(jq -r '.currentStep' "$STATE_FILE")
            if [[ "$current" != "$step" ]]; then
                # 현재 단계 완료 + 다음 단계 시작
                jq --arg now "$NOW" --arg step "$step" --arg job_id "$JOB_ID" --arg by "workflow-gate.sh" '
                    .status = "running" |
                    .currentStep = $step |
                    .updatedAt = $now |
                    .steps = [.steps[] | 
                        if .status == "in_progress" then .status = "done" | .completedAt = $now
                        elif .name == $step then .status = "in_progress" | .startedAt = $now
                        else .
                        end
                    ] |
                    .history += [{"ts": $now, "action": "step_enter", "by": $by, "details": {"step": $step}}]
                ' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
                validate_state_file
                echo "JOB $JOB_ID → $step"
            fi
        done
        echo "JOB $JOB_ID auto-process complete (approval 단계 진입)."
        
        # ✅ JOB-1621: auto-process 이벤트 발행
        if declare -f emit_event &>/dev/null; then
            emit_event "wf.auto_processed" "$WF_CORRELATION_ID" "{\"job_id\":\"$JOB_ID\",\"steps\":[\"investigation\",\"design\",\"review\",\"approval\"]}" 2>/dev/null || true
        fi
        ;;
    transition)
        STEP="${3:-}"
        if [[ -z "$STEP" ]]; then
            echo "ERROR: transition requires a step name (e.g., investigation, design, execution, test, execution_review, done)"
            exit 1
        fi
        
        # ✅ JOB-1580: design 단계 진입 시 architecture.md 필수 검증
        if [[ "$STEP" == "design" ]]; then
            if [[ ! -f "$JOB_DIR/architecture.md" ]]; then
                echo "⛔ BLOCKED: architecture.md not found"
                echo "  Cannot transition to design without architecture.md."
                echo "  Create architecture.md with design document first."
                echo "  Hint: Even simplified jobs require a design document."
                exit 1
            fi
            echo "✅ architecture.md verified"
        fi
        
        # ✅ JOB-1611: Fast-track 자동 approval (execution 진입 시)
        if [[ "$STEP" == "execution" ]]; then
            track=$(jq -r '.track // "standard"' "$STATE_FILE" 2>/dev/null || echo "standard")
            if [[ "$track" == "fast" ]]; then
                # Fast-track: approval.json 불필요, 자동 승인
                if [[ ! -f "$JOB_DIR/approval.json" ]]; then
                    echo '{"jobId":"'"$JOB_ID"'","approvedBy":"fast-track","approvedAt":"'"$NOW"'","autoApproved":true,"reason":"fast-track"}' | \
                    atomic_write "$JOB_DIR/approval.json"
                    echo "✅ Fast-track: auto-approved (investigation/design/review skipped)"
                fi
            fi
        fi
        
        # ✅ JOB-1350: 9-done 진입 전 승인 검증 (신규 JOB만 적용)
        if [[ "$STEP" == "done" || "$STEP" == "9-done" ]]; then
            # 간소화 JOB 예외 확인
            is_simplified=false
            if [[ -f "$JOB_DIR/architecture.md" ]]; then
                if grep -qi "(간소화)" "$JOB_DIR/architecture.md" 2>/dev/null; then
                    is_simplified=true
                fi
            fi
            
            if [[ "$is_simplified" == "false" ]]; then
                # 승인 파일 존재 확인
                if [[ ! -f "$JOB_DIR/approval.json" ]]; then
                    echo "⛔ BLOCKED: approval.json not found"
                    echo "  Cannot transition to done without approval."
                    echo "  Options:"
                    echo "    1. Get user approval and create approval.json"
                    echo "    2. Add '(간소화)' to architecture.md title for simplified jobs"
                    exit 1
                fi
                
                # 승인 파일 유효성 확인 (choice 필드 존재)
                choice=$(jq -r '.choice // ""' "$JOB_DIR/approval.json" 2>/dev/null || echo "")
                if [[ -z "$choice" ]]; then
                    echo "⛔ BLOCKED: approval.json missing 'choice' field"
                    exit 1
                fi
                echo "✅ Approval verified (choice: $choice)"
            else
                echo "✅ Simplified job — approval check skipped"
            fi
        fi

        # ✅ JOB-1498 P0: design/execution 진입 시 Spec 체크포인트 자동 검증
        if [[ "$SKIP_SPEC_CHECK" != "true" ]] && has_spec_references "$JOB_DIR"; then
            echo "── Spec 체크포인트 자동 검증 시작 ──"
            validate_spec_ref_checkpoint "$JOB_DIR"
            validate_spec_matrix_checkpoint "$JOB_DIR"
            echo "── Spec 체크포인트 검증 완료 ──"
        fi
        
        # ✅ JOB-1528/1530/1636/1642: 단계별 모델 동적 변경 (config.yaml model.default + model.provider)
        # JOB-1642 수정: model.default만 변경 시 provider 불일치로 라우팅 오류 발생.
        # model.provider를 model hint의 prefix에 맞춰 함께 변경.
        source ~/.hermes/core/scripts/model-roles.sh 2>/dev/null
        MODEL_HINT=$(get_workflow_model "$STEP" 2>/dev/null || echo "Qwen3.6")

        # provider 추출: zai/glm-5.2 → zai, airouter/Qwen3.6 → airouter
        HINT_PROVIDER=""
        if [[ "$MODEL_HINT" == */* ]]; then
            HINT_PROVIDER="${MODEL_HINT%%/*}"
        fi

        # config provider 매핑
        case "$HINT_PROVIDER" in
            zai)      CONFIG_PROVIDER="zai" ;;
            airouter) CONFIG_PROVIDER="custom:airouter" ;;
            *)        CONFIG_PROVIDER="" ;;
        esac

        # config.yaml model.default + model.provider 동시 변경 → 에이전트가 자동 적용
        CURRENT_MODEL=$(python3 -c "import yaml; c=yaml.safe_load(open('$HOME/.hermes/config.yaml')); print(c.get('model',{}).get('default',''))" 2>/dev/null || echo "")
        CURRENT_PROVIDER=$(python3 -c "import yaml; c=yaml.safe_load(open('$HOME/.hermes/config.yaml')); print(c.get('model',{}).get('provider',''))" 2>/dev/null || echo "")

        # 변경 필요 여부: model.default 또는 model.provider가 다르면
        NEED_CHANGE=0
        if [ "$CURRENT_MODEL" != "$MODEL_HINT" ]; then NEED_CHANGE=1; fi
        if [ -n "$CONFIG_PROVIDER" ] && [ "$CURRENT_PROVIDER" != "$CONFIG_PROVIDER" ]; then NEED_CHANGE=1; fi

        if [ "$NEED_CHANGE" -eq 1 ]; then
            python3 -c "
import yaml
with open('$HOME/.hermes/config.yaml', 'r') as f:
    c = yaml.safe_load(f)
c['model']['default'] = '$MODEL_HINT'
if '$CONFIG_PROVIDER':
    c['model']['provider'] = '$CONFIG_PROVIDER'
with open('$HOME/.hermes/config.yaml', 'w') as f:
    yaml.dump(c, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
" 2>/dev/null
            if [ $? -eq 0 ]; then
                echo "🔄 Model changed: $CURRENT_MODEL ($CURRENT_PROVIDER) → $MODEL_HINT ($CONFIG_PROVIDER)"
                # 변경 이력 기록
                echo "{\"ts\":\"$NOW\",\"job\":\"$JOB_ID\",\"action\":\"model_change\",\"from\":\"$CURRENT_MODEL\",\"to\":\"$MODEL_HINT\",\"from_provider\":\"$CURRENT_PROVIDER\",\"to_provider\":\"$CONFIG_PROVIDER\",\"step\":\"$STEP\"}" \
                  >> "$JOB_DIR/.model-change-log.jsonl"
                # 사후 검증: provider/model 일치성 확인
                python3 "$HERMES_ROOT/core/scripts/model-provider-guard.py" 2>/dev/null || \
                    echo "⚠️ Provider/model mismatch after change — check config"
            fi
        fi

        # .workflow-state에도 기록
        if jq -e '.preferredModel' "$STATE_FILE" >/dev/null 2>&1; then
            jq --arg now "$NOW" --arg model "$MODEL_HINT" '.preferredModel = $model | .modelHintUpdatedAt = $now' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
        else
            jq --arg now "$NOW" --arg step "$STEP" --arg model "$MODEL_HINT" '.preferredModel = $model | .modelHintUpdatedAt = $now' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
        fi
        validate_state_file
        echo "📌 Step '$STEP' using $MODEL_HINT"

        # 현재 단계 완료 처리 + 다음 단계 시작
        jq --arg now "$NOW" --arg step "$STEP" --arg job_id "$JOB_ID" --arg by "workflow-gate.sh" '
            .status = "running" |
            .currentStep = $step |
            .updatedAt = $now |
            .steps = [.steps[] | 
                if .status == "in_progress" then .status = "done" | .completedAt = $now
                elif .name == $step then .status = "in_progress" | .startedAt = $now
                else .
                end
            ] |
            .history += [{"ts": $now, "action": "step_enter", "by": $by, "details": {"step": $step}}]
        ' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
        validate_state_file
        
        # audit.log 기록
        echo "{\"ts\":\"$NOW\",\"job\":\"$JOB_ID\",\"event\":\"step_enter\",\"step\":\"$STEP\",\"by\":\"workflow-gate.sh\"}" \
          >> "$JOB_DIR/.workflow-audit.log"
        
        echo "JOB $JOB_ID transitioned to $STEP."
        
        # ✅ JOB-1621: 이벤트 버스 발행 (from: 실제 이전 단계명)
        if declare -f emit_event &>/dev/null; then
            PREV_STEP=$(jq -r '.currentStep // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")
            emit_event "wf.state_changed" "$WF_CORRELATION_ID" "{\"job_id\":\"$JOB_ID\",\"from\":\"$PREV_STEP\",\"to\":\"$STEP\"}" 2>/dev/null || true
        fi
        ;;
    complete)
        # ✅ JOB-1350: 완료 전 승인 검증
        is_simplified=false
        if [[ -f "$JOB_DIR/architecture.md" ]]; then
            if grep -qi "(간소화)" "$JOB_DIR/architecture.md" 2>/dev/null; then
                is_simplified=true
            fi
        fi
        
        if [[ "$is_simplified" == "false" ]]; then
            if [[ ! -f "$JOB_DIR/approval.json" ]]; then
                echo "⛔ BLOCKED: approval.json not found"
                echo "  Cannot complete job without approval."
                echo "  Options:"
                echo "    1. Get user approval and create approval.json"
                echo "    2. Add '(간소화)' to architecture.md title for simplified jobs"
                exit 1
            fi
            choice=$(jq -r '.choice // ""' "$JOB_DIR/approval.json" 2>/dev/null || echo "")
            if [[ -z "$choice" ]]; then
                echo "⛔ BLOCKED: approval.json missing 'choice' field"
                exit 1
            fi
            echo "✅ Approval verified (choice: $choice)"
        else
            echo "✅ Simplified job — approval check skipped"
        fi
        
        # ✅ JOB-1565: 산출물 검증 (architecture.md, review-result)
        if [[ -x $HERMES_ROOT/core/scripts/validate-deliverables.sh ]]; then
            bash $HERMES_ROOT/core/scripts/validate-deliverables.sh "$JOB_DIR" "$is_simplified"
        fi
        
        # ✅ JOB-1412: result.md 필수 검증
        if [[ ! -f "$JOB_DIR/result.md" ]]; then
            echo "⛔ BLOCKED: result.md not found"
            echo "  Cannot complete job without result documentation."
            echo "  Create result.md summarizing work output."
            exit 1
        fi
        echo "✅ Result verified"
        
        # ✅ JOB-1492: lessons.md 자동 템플릿 생성
        if [[ ! -f "$JOB_DIR/lessons.md" ]]; then
            cat > "$JOB_DIR/lessons.md" << 'LESSONSEOF'
# JOB-XXXX 교훈

## 기술적 교훈
-

## 프로세스 교훈
-
LESSONSEOF
            # JOB ID 치환
            sed -i "s/JOB-XXXX/$JOB_ID/" "$JOB_DIR/lessons.md"
            echo "[INFO] lessons.md 템플릿 자동 생성 ($JOB_ID)"
        fi
        # 간소화 JOB은 빈 파일도 허용
        if [[ "$is_simplified" == "false" ]] && [[ ! -s "$JOB_DIR/lessons.md" ]]; then
            echo "⛔ BLOCKED: lessons.md is empty"
            echo "  Non-simplified jobs require non-empty lessons.md."
            exit 1
        fi
        echo "✅ Lessons verified"
        
        # ✅ JOB-1491: execution.md 필수 검증
        if [[ ! -f "$JOB_DIR/execution.md" ]]; then
            echo "⛔ BLOCKED: execution.md not found"
            echo "  Cannot complete job without execution documentation."
            echo "  Create execution.md documenting implementation details."
            exit 1
        fi
        echo "✅ Execution verified"
        
        # ✅ JOB-1622: 자동 백업 (상태 완료 전)
        if ! backup_job "$JOB_ID" "$JOB_DIR"; then
            echo "⛔ BLOCKED: 백업 실패 — complete 중단"
            exit 1
        fi
        
        # ✅ JOB-1631: 템플릿 폴더 자동 생성 (초기화)
        TEMPLATE_DIR="$HERMES_ROOT/core/scripts/deliverable-templates"
        if [[ ! -d "$TEMPLATE_DIR" ]]; then
            mkdir -p "$TEMPLATE_DIR"
            echo "[INFO] deliverable-templates 폴더 생성"
        fi
        
        # ✅ JOB-1631: 템플릿 품질 체크
        for tmpl in review-result.md.template architecture.md.template; do
            if [[ -f "$TEMPLATE_DIR/$tmpl" ]]; then
                if grep -q "\[TODO:" "$TEMPLATE_DIR/$tmpl"; then
                    echo "[WARN] $tmpl에 [TODO:] 마커 존재 - 템플릿 업데이트 필요"
                fi
            else
                echo "[INFO] $tmpl 생성 필요"
            fi
        done
        
        # ✅ JOB-1631: 모델 사용 리포트
        if [[ -f "$STATE_FILE" ]]; then
            STEP_COUNT=$(jq '.stepModels | length // 0' "$STATE_FILE" 2>/dev/null || echo "0")
            if [[ "$STEP_COUNT" -gt 0 ]]; then
                echo ""
                echo "📊 모델 사용 리포트:"
                jq -r '.stepModels[] | "  \(.step): \(.actual) (recommended: \(.recommended), matched: \(.matched))"' "$STATE_FILE" 2>/dev/null || true
                echo ""
            fi
        fi
        
        # ✅ JOB-1645: JOB 완료 시 model.default 리셋
        DEFAULT_MODEL_ROLE=$(python3 -c "
import yaml, sys, os; c_path=os.path.expanduser('~/.hermes/config.yaml')
with open(c_path) as f: c=yaml.safe_load(f)
print((c.get('roles',{}).get('default','')) or '')
" 2>/dev/null || echo "")
        if [[ -z "$DEFAULT_MODEL_ROLE" ]]; then
            DEFAULT_MODEL_ROLE="airrouter/Qwen3.6"
        fi
        RESET_MODEL=$(get_model_for_role "$DEFAULT_MODEL_ROLE" 2>/dev/null || echo "$DEFAULT_MODEL_ROLE")
        CURRENT_MODEL_AFTER=$(python3 -c "
import yaml, os; c_path=os.path.expanduser('~/.hermes/config.yaml')
with open(c_path) as f: c=yaml.safe_load(f)
print((c.get('model',{}).get('default','')) or '')
" 2>/dev/null || echo "")
        if [[ "$CURRENT_MODEL_AFTER" != "$RESET_MODEL" ]]; then
            echo ""
            echo "🔄 JOB-1645: model.default 리셋 ($CURRENT_MODEL_AFTER → $RESET_MODEL)"
            if command -v hermes &>/dev/null; then
                hermes config set "model.default" "$RESET_MODEL" >> "$HERMES_ROOT/logs/job1645-model-reset.log" 2>&1 || {
                    echo "[WARN] hermes config set 실패 — 직접 수정 폴백"
                    python3 -c "
import yaml,os;c_path=os.path.expanduser('~/.hermes/config.yaml')
with open(c_path) as f:c=yaml.safe_load(f)
c.setdefault('model',{});c['model']['default']='$RESET_MODEL'
with open(c_path,'w') as f:yaml.dump(c,f,default_flow_style=False)
" 2>/dev/null || echo "[ERROR] model.default 리셋 실패"
                }
            else
                echo "[WARN] hermes CLI 없음 — 직접 수정 폴백"
                python3 -c "
import yaml,os;c_path=os.path.expanduser('~/.hermes/config.yaml')
with open(c_path) as f:c=yaml.safe_load(f)
c.setdefault('model',{});c['model']['default']='$RESET_MODEL'
with open(c_path,'w') as f:yaml.dump(c,f,default_flow_style=False)
" 2>/dev/null || echo "[ERROR] model.default 리셋 실패"
            fi
        fi

        # 상태 완료 처리
        jq --arg now "$NOW" '
            .status = "completed" |
            .currentStep = "done" |
            .updatedAt = $now |
            .steps = [.steps[] | if .status != "done" and .status != "completed" then .status = "done" | .completedAt = $now else . end]
        ' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
        validate_state_file
        
        # 완료 마커 생성
        touch "$JOB_DIR/.done"
        echo "JOB $JOB_ID completed."
        
        # ✅ JOB-1621: 이벤트 버스 발행
        if declare -f emit_event &>/dev/null; then
            emit_event "wf.completed" "$WF_CORRELATION_ID" "{\"job_id\":\"$JOB_ID\",\"status\":\"completed\"}" 2>/dev/null || true
        fi
        
# ─── 채널 타겟팅: 동적 쓰레드 ID ──────────────────────────────
# 고정 값 금지. 현재 세션 쓰레드 ID를 환경 변수 또는 세션 컨텍스트에서 읽음
THREAD_ID="${DISCORD_THREAD_ID:-$(jq -r '.threadId // ""' "$STATE_FILE" 2>/dev/null)}"
if [[ -z "$THREAD_ID" ]]; then
    echo "[WARN] 쓰레드 ID 없음 — 알림이 #general 로 갈 수 있습니다."
    echo "  해결: export DISCORD_THREAD_ID=<현재_쓰레드_ID>"
fi
if [[ -n "$THREAD_ID" ]]; then
    echo "[INFO] 채널: discord:1503941910459580450:$THREAD_ID"
fi
        
        # 후처리 훅 호출 (비동기) - JOB-1421: 문서 자동 동기화
        if [[ -x "$HERMES_ROOT/core/scripts/hooks/on-job-complete.sh" ]]; then
            bash "$HERMES_ROOT/core/scripts/hooks/on-job-complete.sh" "$JOB_DIR" "$JOB_ID" >> "$HERMES_ROOT/logs/job-complete-hook.log" 2>&1 &
        fi
        
        # ✅ JOB-1640: 피드백 교훈 자동화 (자유로운 피드백 패턴 감지)
        if [[ -f "$JOB_DIR/request.md" ]]; then
            # [FEEDBACK] 패턴 또는 [피드백] 패턴 감지
            if grep -qiE "\[FEEDBACK\]|\[피드백\]|피드백:" "$JOB_DIR/request.md" 2>/dev/null; then
                echo ""
                echo "[INFO] 피드백 감지 → 교훈 드래프트 생성"
                if [[ -x "$HERMES_ROOT/core/scripts/auto-lessons-draft.sh" ]]; then
                    bash "$HERMES_ROOT/core/scripts/auto-lessons-draft.sh" "$JOB_DIR" >> "$HERMES_ROOT/logs/feedback-lessons.log" 2>&1
                fi
            fi
        fi
        ;;
    checkpoint)
        # 검증 체크포인트 (I15: 화 검증, I16: 장 Coherence)
        CHECKPOINT_TYPE="${3:-}"
        CHECKPOINT_ARG1="${4:-}"
        CHECKPOINT_ARG2="${5:-}"
        
        case "$CHECKPOINT_TYPE" in
            I15)
                # 화 검증: ep_dir, ep_num
                validate_episode_checkpoint "$CHECKPOINT_ARG1" "$CHECKPOINT_ARG2"
                ;;
            I16)
                # 장 Coherence 검증: chapter_dir, chapter_num
                validate_coherence_checkpoint "$CHECKPOINT_ARG1" "$CHECKPOINT_ARG2"
                ;;
            I-spec-ref)
                # request.md Spec 참조 확인 (JOB-1498 P0)
                if [[ "$SKIP_SPEC_CHECK" == "true" ]]; then
                    echo "SKIP: I-spec-ref (--skip-spec-check 플래그로 건너뜀)"
                else
                    validate_spec_ref_checkpoint "$JOB_DIR"
                fi
                ;;
            I-spec-matrix)
                # architecture.md Spec 연동 테이블 확인 (JOB-1498 P0)
                if [[ "$SKIP_SPEC_CHECK" == "true" ]]; then
                    echo "SKIP: I-spec-matrix (--skip-spec-check 플래그로 건너뜀)"
                else
                    validate_spec_matrix_checkpoint "$JOB_DIR"
                fi
                ;;
            *)
                echo "ERROR: Unknown checkpoint type: $CHECKPOINT_TYPE (I15, I16, I-spec-ref, I-spec-matrix)"
                exit 1
                ;;
        esac
        ;;
    *)
        echo "Unknown action: $ACTION"
        exit 1
        ;;
esac
