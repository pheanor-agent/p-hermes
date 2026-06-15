#!/usr/bin/env bash
# pre-commit-spec-check.sh — Spec 변경 시 Breaking change 자동 감지
#
# 설치:
#   cp pre-commit-spec-check.sh .git/hooks/pre-commit-spec-check
#   git config core.hooksPath .git/hooks/
#   # 또는 git config core.hooksPath를 사용하지 않고 직접 링크
#
# 동작:
#   - index에 추가된 spec 파일(.md) 감지
#   - breaking change 분석
#   - BREAKING 감지 시 경고 + ADR 확인
#   - --allow-breaking 또는 SPECS_ALLOW_BREAKING=1로 오버라이드
#
# 설치 방법:
#   ln -s ~/.hermes/skills/software-development/spec-driven-dev/scripts/git-hooks/pre-commit-spec-check.sh .git/hooks/pre-commit

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 오버라이드 확인
ALLOW_BREAKING=false
if [[ "${SPECS_ALLOW_BREAKING:-}" == "1" ]] || [[ "${SPECS_ALLOW_BREAKING:-}" == "true" ]]; then
    ALLOW_BREAKING=true
fi

# git commit --allow-breaking 확인 (git 2.29+의 --allow-empty를 확인하는 방식으로)
# NOTE: git commit --allow-breaking은 표준 옵션이 아니므로 환경 변수만 사용

# ── 프로젝트 루트 찾기 ─────────────────────────────────
# .git에서 프로젝트 디렉토리 확인
GIT_DIR=$(git rev-parse --git-dir 2>/dev/null)
[[ -z "$GIT_DIR" ]] && exit 0  # git 저장소가 아니면 무시

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
[[ -z "$REPO_ROOT" ]] && exit 0

# 프로젝트 slug 확인 (workspace/projects/{slug} 패턴)
PROJECT_SLUG=""
if [[ "$REPO_ROOT" == *"workspace/projects/"* ]]; then
    PROJECT_SLUG=$(echo "$REPO_ROOT" | sed 's|.*/workspace/projects/||')
fi

# spec-driven-dev가 workspace에 있을 때만 동작
if [[ -z "$PROJECT_SLUG" ]]; then
    # 스크립트 위치를 통해 workspace/projects 확인
    if [[ "$REPO_ROOT" =~ workspace/projects/([^/]+) ]]; then
        PROJECT_SLUG="${BASH_REMATCH[1]}"
    else
        exit 0  # workspace/projects/{slug}가 아니면 무시
    fi
fi

PROJECT_DIR="$HOME/.hermes/workspace/projects/${PROJECT_SLUG}"
SPECS_DIR="${PROJECT_DIR}/specs"
VERSION_MAP_FILE="${SPECS_DIR}/VERSION_MAP.yaml"

# ── 변경된 spec 파일 감지 ──────────────────────────────
# index에 추가된 .md 파일 중 specs/active/ 내에 있는 것
CHANGED_SPECS=$(git diff --cached --name-only --diff-filter=ACM -- "specs/active/**/*.md" 2>/dev/null || true)

# 만약 위 패턴이 안되면 직접 검색
if [[ -z "$CHANGED_SPECS" ]]; then
    CHANGED_SPECS=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | \
        grep -E "specs/active/.+\.md$" || true)
fi

if [[ -z "$CHANGED_SPECS" ]]; then
    exit 0  # 변경된 spec 파일이 없으면 통과
fi

echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║  Spec Pre-commit Check (${PROJECT_SLUG})              ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

TOTAL_BREAKING=0
TOTAL_WARNING=0
TOTAL_NON_BREAKING=0

# ── 각 변경된 spec에 대해 분석 ─────────────────────────
while IFS= read -r spec_file; do
    [[ -z "$spec_file" ]] && continue
    [[ ! -f "$spec_file" ]] && continue

    # 전체 경로
    full_spec_file="${PROJECT_DIR}/${spec_file}"
    [[ ! -f "$full_spec_file" ]] && continue

    # spec_id 추출
    SPEC_ID=$(grep -E "^spec_id:" "$full_spec_file" 2>/dev/null | head -1 | awk '{print $2}')
    [[ -z "$SPEC_ID" ]] && continue

    # 현재 버전
    CURRENT_VERSION=$(grep -E "^version:" "$full_spec_file" 2>/dev/null | head -1 | awk '{print $2}')
    CURRENT_VERSION="${CURRENT_VERSION#v}"
    if [[ "$CURRENT_VERSION" == *.*.* ]]; then
        : # 이미 SemVer
    elif [[ "$CURRENT_VERSION" == *.* ]]; then
        CURRENT_VERSION="${CURRENT_VERSION}.0"
    else
        CURRENT_VERSION="${CURRENT_VERSION}.0.0"
    fi

    echo "📋 ${SPEC_ID} (${spec_file}) — 버전: ${CURRENT_VERSION}"

    # git diff에서 이전 버전 내용 추출
    OLD_CONTENT=$(git show ":${spec_file}" 2>/dev/null || echo "")
    NEW_CONTENT=$(git show ":${spec_file}" 2>/dev/null || cat "$full_spec_file")

    # Breaking change 감지 (간단한 패턴 기반)
    DIFF_OUTPUT=$(git diff --cached -- "${spec_file}" 2>/dev/null || true)

    if [[ -z "$DIFF_OUTPUT" ]]; then
        echo "   ✅ 변경 없음 (새 파일 또는 diff 없음)"
        continue
    fi

    # ── Breaking change 패턴 분석 ──
    BREAKING_COUNT=0
    WARNING_COUNT=0
    NON_BREAKING_COUNT=0
    BREAKING_DETAILS=""

    # 1. frontmatter 변경 분석
    OLD_STATUS=$(echo "$OLD_CONTENT" | grep -E "^status:" | head -1 | awk '{print $2}' || true)
    NEW_STATUS=$(echo "$NEW_CONTENT" | grep -E "^status:" | head -1 | awk '{print $2}' || true)
    OLD_PRIORITY=$(echo "$OLD_CONTENT" | grep -E "^priority:" | head -1 | awk '{print $2}' || true)
    NEW_PRIORITY=$(echo "$NEW_CONTENT" | grep -E "^priority:" | head -1 | awk '{print $2}' || true)
    OLD_CATEGORY=$(echo "$OLD_CONTENT" | grep -E "^category:" | head -1 | awk '{$1=""; print}' | xargs || true)
    NEW_CATEGORY=$(echo "$NEW_CONTENT" | grep -E "^category:" | head -1 | awk '{$1=""; print}' | xargs || true)

    # status 비활성화
    if [[ "$OLD_STATUS" != "proposed" && "$OLD_STATUS" != "deprecated" && "$OLD_STATUS" != "archived" ]] && \
       [[ "$NEW_STATUS" == "deprecated" || "$NEW_STATUS" == "archived" ]]; then
        BREAKING_COUNT=$((BREAKING_COUNT + 1))
        BREAKING_DETAILS+="   🔴 status 비활성화: ${OLD_STATUS} → ${NEW_STATUS}"$'\n'
    fi

    # category 변경
    if [[ -n "$OLD_CATEGORY" && -n "$NEW_CATEGORY" && "$OLD_CATEGORY" != "$NEW_CATEGORY" ]]; then
        WARNING_COUNT=$((WARNING_COUNT + 1))
    fi

    # priority 하향
    if [[ "$OLD_PRIORITY" == "P0" || "$OLD_PRIORITY" == "P1" ]] && \
       [[ "$NEW_PRIORITY" == "P2" || "$NEW_PRIORITY" == "P3" ]]; then
        WARNING_COUNT=$((WARNING_COUNT + 1))
    fi

    # 2. content diff 분석 ( BREAKING 패턴 )
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        BREAKING_COUNT=$((BREAKING_COUNT + 1))
        BREAKING_DETAILS+="   🔴 제거됨: ${line:0:80}"$'\n'
    done < <(echo "$DIFF_OUTPUT" | grep -E "^-" | grep -v "^---" | \
        grep -E "(\\*\\*Input\\*\\*|\\*\\*Output\\*\\*|\\*\\*Endpoint|\\*\\*Method|\\*\\*Request|\\*\\*Response|\\*\\*Contract|\\*\\*Body Schema|\\*\\*Headers)" || true)

    # 새로운 필수 필드 추가 (WARNING)
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        WARNING_COUNT=$((WARNING_COUNT + 1))
    done < <(echo "$DIFF_OUTPUT" | grep -E "^\\+" | grep -v "^+++" | grep -i "required" || true)

    # 3. content diff 분석 ( NON-BREAKING 패턴 )
    NON_BREAKING_COUNT=$(echo "$DIFF_OUTPUT" | grep -E "^\\+" | grep -v "^+++" | \
        grep -cE "(\\[ \\]|## |\\*\\*설명|test_refs|job_refs)" || echo "0")

    # 결과 출력
    if [[ $BREAKING_COUNT -gt 0 ]]; then
        echo "$BREAKING_DETAILS"
        echo "   ❌ Breaking change ${BREAKING_COUNT}개 감지!"
    fi

    if [[ $WARNING_COUNT -gt 0 ]]; then
        echo "   ⚠️  Warning ${WARNING_COUNT}개 — 검토 권장"
    fi

    if [[ $NON_BREAKING_COUNT -gt 0 ]]; then
        echo "   🟢 Non-breaking 변경 ${NON_BREAKING_COUNT}개"
    fi

    TOTAL_BREAKING=$((TOTAL_BREAKING + BREAKING_COUNT))
    TOTAL_WARNING=$((TOTAL_WARNING + WARNING_COUNT))
    TOTAL_NON_BREAKING=$((TOTAL_NON_BREAKING + NON_BREAKING_COUNT))

    echo ""
done <<< "$CHANGED_SPECS"

# ── 최종 결과 ──────────────────────────────────────────
echo "─────────────────────────────────────────────────"
echo "📊 요약: BREAKING=${TOTAL_BREAKING}, WARNING=${TOTAL_WARNING}, NON-BREAKING=${TOTAL_NON_BREAKING}"
echo "─────────────────────────────────────────────────"

if [[ $TOTAL_BREAKING -gt 0 ]]; then
    if [[ "$ALLOW_BREAKING" == "true" ]]; then
        echo ""
        echo "⚠️  Breaking change 감지됨 — SPECS_ALLOW_BREAKING=1로 강제 진행"
        echo "   ADR 작성 잊지 마세요!"
        exit 0
    else
        echo ""
        echo "❌ Breaking change 감지됨!"
        echo ""
        echo "진행 방법:"
        echo "  1. SPECS_ALLOW_BREAKING=1 git commit"
        echo "  2. ADR 작성: specs/adrs/NNNN-breaking-change.md"
        echo "  3. spec-version-map.sh detect ${PROJECT_SLUG} <spec-id> <from> <to>"
        echo ""
        exit 1
    fi
fi

if [[ $TOTAL_WARNING -gt 0 ]]; then
    echo ""
    echo "⚠️  Warning 감지 — 검토 권장하지만 commit 진행"
fi

echo ""
echo "✅ Spec pre-commit check 통과"
exit 0

# ── 코드 파일의 @spec_id 검증 ─────────────────────────
echo "🔍 코드 파일의 @spec_id 검증 중..."

# index에 추가된 코드 파일 조회 (Python/JavaScript/Bash)
CODE_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(py|js|sh)$' || true)

if [[ -n "$CODE_FILES" ]]; then
    for code_file in $CODE_FILES; do
        # 프로젝트 루트에서 상대 경로로 변환
        if [[ -f "$code_file" ]]; then
            # @spec_id 애노테이션 확인
            if ! grep -q "@spec_id" "$code_file" 2>/dev/null; then
                echo "❌ 코드 파일에 @spec_id 애노테이션이 없습니다: $code_file"
                echo "   해결 방법:"
                echo "   1. 사양서 먼저 생성: bash spec-create.sh <slug> <type> <title>"
                echo "   2. 코드 파일에 @spec_id: SPEC-XXX 주석 추가"
                echo ""
                echo "   또는 --no-verify 플래그로 검증 우회 (사유 기록 필수)"
                exit 1
            else
                echo "✅ $code_file: @spec_id 확인"
            fi
        fi
    done
fi

