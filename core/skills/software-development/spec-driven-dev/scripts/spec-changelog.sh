#!/usr/bin/env bash
# spec-changelog.sh — git diff 기반 CHANGELOG 자동 생성
#
# 사용법:
#   bash spec-changelog.sh <slug> [spec-id] [since-commit]
#
# 예시:
#   bash spec-changelog.sh my-api            # 최근 변경 전체 changelog
#   bash spec-changelog.sh my-api SPEC-A001  # 특정 spec만
#   bash spec-changelog.sh my-api HEAD~5     # 최근 5 커밋만
#
# CHANGELOG 형식: Keep a Changelog (https://keepachangelog.com/)

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SKILL_DIR}/spec-version.sh"

# ── 검증 ──────────────────────────────────────────────
[[ $# -lt 1 ]] && {
    echo "Usage: bash spec-changelog.sh <slug> [spec-id] [since-commit]"
    exit 1
}

SLUG="$1"
SPEC_ID="${2:-}"
SINCE_COMMIT="${3:-HEAD~10}"
PROJECT_DIR="$HOME/.hermes/workspace/projects/${SLUG}"

[[ ! -d "$PROJECT_DIR" ]] && {
    echo "❌ 프로젝트 '${SLUG}'을/를 찾을 수 없습니다"
    exit 1
}

CHANGELOG_DIR="$PROJECT_DIR/specs/history"
CHANGELOG_FILE="$CHANGELOG_DIR/CHANGELOG.md"
mkdir -p "$CHANGELOG_DIR"

# ── Spec 파일 찾기 ────────────────────────────────────
find_spec_files() {
    local search_dir="$PROJECT_DIR/specs/active"
    if [[ -n "$SPEC_ID" ]]; then
        find "$search_dir" -name "*.md" -exec grep -l "${SPEC_ID}" {} \; 2>/dev/null || true
    else
        find "$search_dir" -name "*.md" 2>/dev/null || true
    fi
}

SPEC_FILES=$(find_spec_files)
[[ -z "$SPEC_FILES" ]] && {
    echo "⚠️  Spec 파일을 찾을 수 없습니다"
    exit 0
}

# ── CHANGELOG 헤더 확인/생성 ──────────────────────────
if [[ ! -f "$CHANGELOG_FILE" ]]; then
    cat > "$CHANGELOG_FILE" << 'HEADER'
# Spec 변경 이력 (Changelog)

본 파일은 spec-status.sh 및 spec-changelog.sh에 의해 자동 관리됩니다.
변경 이력은 [Keep a Changelog](https://keepachangelog.com/) 형식을 따릅니다.

HEADER
fi

# ── 각 Spec에 대해 diff 기반 entry 생성 ────────────────
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
DATE_TODAY=$(date +%Y-%m-%d)

# 새 entry를 헤더 다음에 삽입할 버퍼
NEW_ENTRIES=""

while IFS= read -r spec_file; do
    [[ -z "$spec_file" ]] && continue
    [[ ! -f "$spec_file" ]] && continue

    # spec 파일에서 metadata 읽기
    SPEC_ID_FROM_FILE=$(grep -E "^spec_id:" "$spec_file" 2>/dev/null | head -1 | awk '{print $2}')
    CURRENT_VERSION=$(grep -E "^version:" "$spec_file" 2>/dev/null | head -1 | awk '{print $2}')
    CURRENT_STATUS=$(grep -E "^status:" "$spec_file" 2>/dev/null | head -1 | awk '{print $2}')

    [[ -z "$SPEC_ID_FROM_FILE" ]] && continue

    # git diff 가져오기
    local_diff=""
    if git -C "$PROJECT_DIR" diff "$SINCE_COMMIT" -- "$spec_file" >/dev/null 2>&1; then
        local_diff=$(git -C "$PROJECT_DIR" diff "$SINCE_COMMIT" -- "$spec_file" 2>/dev/null || true)
    fi

    # diff가 있으면 entry 생성
    if [[ -n "$local_diff" ]]; then
        # 변경된 섹션 추출
        changed_sections=$(echo "$local_diff" | grep -E "^[\+\-]##" | sed 's/^[\+\-]##* //' | sort -u || true)

        # 변경 유형 결정 (버전 변경 확인)
        changelog_type="Changed"
        if echo "$local_diff" | grep -q "+status:.*approved"; then
            changelog_type="Added"
        elif echo "$local_diff" | grep -q "+status:.*verified"; then
            changelog_type="Fixed"
        elif echo "$local_diff" | grep -q "+status:.*deprecated"; then
            changelog_type="Deprecated"
        fi

        # 관련 JOB 추출 (commit message에서)
        related_jobs=$(git -C "$PROJECT_DIR" log "$SINCE_COMMIT..HEAD" --oneline -- "$spec_file" 2>/dev/null | \
            grep -oE "JOB-[0-9]+" | sort -u | tr '\n' ', ' | sed 's/,$//' || true)
        [[ -z "$related_jobs" ]] && related_jobs="(없음)"

        # 변경 요약 (diff에서 + 라인 추출, 최대 5개)
        additions=$(echo "$local_diff" | grep "^+" | grep -v "^+++" | head -5 || true)
        removals=$(echo "$local_diff" | grep "^-" | grep -v "^---" | head -5 || true)

        # Entry 생성 (실제 줄바꿈 사용)
        NL=$'\n'
        entry="${NL}## [${CURRENT_VERSION}] ${SPEC_ID_FROM_FILE} — ${DATE_TODAY}${NL}${NL}"
        entry+="- **변경 유형**: ${changelog_type}${NL}"
        entry+="- **상태**: ${CURRENT_STATUS}${NL}"

        if [[ -n "$changed_sections" ]]; then
            entry+="${NL}### 변경된 섹션${NL}"
            while IFS= read -r section; do
                [[ -n "$section" ]] && entry+="- \`${section}\`${NL}"
            done <<< "$changed_sections"
        fi

        if [[ -n "$additions" ]]; then
            entry+="${NL}### 추가된 내용${NL}"
            entry+="\`\`\`diff${NL}${additions}${NL}\`\`\`${NL}"
        fi

        if [[ -n "$removals" ]]; then
            entry+="${NL}### 제거된 내용${NL}"
            entry+="\`\`\`diff${NL}${removals}${NL}\`\`\`${NL}"
        fi

        entry+="- **관련 JOB**: ${related_jobs}${NL}"
        entry+="- **Spec 파일**: ${spec_file#$PROJECT_DIR/}${NL}"

        NEW_ENTRIES+="${entry}"
    fi
done <<< "$SPEC_FILES"

# ── CHANGELOG에 삽입 ──────────────────────────────────
if [[ -n "$NEW_ENTRIES" ]]; then
    # 헤더 다음에 새로운 entry 삽입
    # 기존 파일에서 헤더 부분과 나머지 분리
    HEADER_CONTENT=$(head -7 "$CHANGELOG_FILE")
    EXISTING_CONTENT=$(tail -n +8 "$CHANGELOG_FILE" 2>/dev/null || true)

    cat > "$CHANGELOG_FILE" << EOF
${HEADER_CONTENT}
${NEW_ENTRIES}
${EXISTING_CONTENT}
EOF

    echo "✅ CHANGELOG 갱신: $CHANGELOG_FILE"
    echo "   새 entry: $(echo "$SPEC_FILES" | wc -l)개 spec 처리"
else
    echo "ℹ️  변경된 spec 없음 (since: $SINCE_COMMIT)"
fi
