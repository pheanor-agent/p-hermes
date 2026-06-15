#!/usr/bin/env bash
# validate-project.sh — 프로젝트 구조 검증
#
# 사용법: bash validate-project.sh <project-slug>

set -euo pipefail

PROJECTS_DIR="${HOME}/.hermes/workspace/projects"

if [[ $# -lt 1 ]]; then
    echo "사용법: $0 <project-slug>"
    exit 1
fi

SLUG="$1"
PROJECT_DIR="${PROJECTS_DIR}/${SLUG}"

if [[ ! -d "${PROJECT_DIR}" ]]; then
    echo "❌ 프로젝트 '${SLUG}'을(를) 찾을 수 없습니다: ${PROJECT_DIR}"
    exit 1
fi

echo "🔍 프로젝트 검증: ${SLUG}"
echo "   위치: ${PROJECT_DIR}"
echo ""

PASS=0
FAIL=0
WARN=0

check_pass() {
    echo "✅ $1"
    PASS=$((PASS + 1))
}

check_fail() {
    echo "❌ $1"
    FAIL=$((FAIL + 1))
}

check_warn() {
    echo "⚠️ $1"
    WARN=$((WARN + 1))
}

# 1. 필수 디렉토리
[[ -d "${PROJECT_DIR}/specs" ]] && check_pass "specs/ 존재" || check_fail "specs/ 누락"
[[ -d "${PROJECT_DIR}/specs/active" ]] && check_pass "specs/active/ 존재" || check_fail "specs/active/ 누락"
[[ -d "${PROJECT_DIR}/specs/active/components" ]] && check_pass "specs/active/components/ 존재" || check_fail "specs/active/components/ 누락"
[[ -d "${PROJECT_DIR}/specs/active/interfaces" ]] && check_pass "specs/active/interfaces/ 존재" || check_fail "specs/active/interfaces/ 누락"
[[ -d "${PROJECT_DIR}/specs/history" ]] && check_pass "specs/history/ 존재" || check_fail "specs/history/ 누락"
[[ -d "${PROJECT_DIR}/src" ]] && check_pass "src/ 존재" || check_fail "src/ 누락"
[[ -d "${PROJECT_DIR}/tests" ]] && check_pass "tests/ 존재" || check_fail "tests/ 누락"

# 2. 필수 파일
[[ -f "${PROJECT_DIR}/specs/_index.yaml" ]] && check_pass "_index.yaml 존재" || check_fail "_index.yaml 누락"
[[ -f "${PROJECT_DIR}/specs/_matrix.json" ]] && check_pass "_matrix.json 존재" || check_fail "_matrix.json 누락"
[[ -f "${PROJECT_DIR}/AGENTS.md" ]] && check_pass "AGENTS.md 존재" || check_fail "AGENTS.md 누락"
[[ -f "${PROJECT_DIR}/README.md" ]] && check_pass "README.md 존재" || check_fail "README.md 누락"

# 3. .gitignore 검증
if [[ -f "${PROJECT_DIR}/.gitignore" ]]; then
    check_pass ".gitignore 존재"
    
    # Hermes 파일 제외 확인
    grep -q '\.hermes/' "${PROJECT_DIR}/.gitignore" 2>/dev/null && \
        check_pass ".gitignore에 .hermes/ 제외" || \
        check_warn ".gitignore에 .hermes/ 누락"
    
    grep -q '\.openclaw/' "${PROJECT_DIR}/.gitignore" 2>/dev/null && \
        check_pass ".gitignore에 .openclaw/ 제외" || \
        check_warn ".gitignore에 .openclaw/ 누락"
    
    grep -q '\.shared/' "${PROJECT_DIR}/.gitignore" 2>/dev/null && \
        check_pass ".gitignore에 .shared/ 제외" || \
        check_warn ".gitignore에 .shared/ 누락"
    
    grep -q 'jobs/' "${PROJECT_DIR}/.gitignore" 2>/dev/null && \
        check_pass ".gitignore에 jobs/ 제외" || \
        check_warn ".gitignore에 jobs/ 누락"
else
    check_fail ".gitignore 누락"
fi

# 4. Git repo 확인
[[ -d "${PROJECT_DIR}/.git" ]] && check_pass "Git repo 존재" || \
    [[ -L "${PROJECT_DIR}/.git" ]] && check_pass "Git repo (symlink) 존재" || \
    check_fail "Git repo 누락"

# 5. Spec 인덱스 검증
if [[ -f "${PROJECT_DIR}/specs/_index.yaml" ]]; then
    grep -q "project:" "${PROJECT_DIR}/specs/_index.yaml" 2>/dev/null && \
        check_pass "_index.yaml에 project 필드 존재" || \
        check_fail "_index.yaml에 project 필드 누락"
    
    grep -q "spec_version:" "${PROJECT_DIR}/specs/_index.yaml" 2>/dev/null && \
        check_pass "_index.yaml에 spec_version 필드 존재" || \
        check_fail "_index.yaml에 spec_version 필드 누락"
fi

# 6. Matrix 검증
if [[ -f "${PROJECT_DIR}/specs/_matrix.json" ]]; then
    python3 -c "import json; json.load(open('${PROJECT_DIR}/specs/_matrix.json'))" 2>/dev/null && \
        check_pass "_matrix.json 유효한 JSON" || \
        check_fail "_matrix.json JSON 파싱 실패"
    
    python3 -c "
import json
d = json.load(open('${PROJECT_DIR}/specs/_matrix.json'))
assert 'project' in d, 'project 필드 누락'
assert 'spec_version' in d, 'spec_version 필드 누락'
assert 'items' in d, 'items 필드 누락'
" 2>/dev/null && \
        check_pass "_matrix.json 필드 완전" || \
        check_fail "_matrix.json 필드 불완전"
fi

# 7. AGENTS.md 검증
if [[ -f "${PROJECT_DIR}/AGENTS.md" ]]; then
    grep -qi "spec" "${PROJECT_DIR}/AGENTS.md" 2>/dev/null && \
        check_pass "AGENTS.md에 Spec 연동 가이드 포함" || \
        check_warn "AGENTS.md에 Spec 연동 가이드 누락"
    
    grep -qi "git" "${PROJECT_DIR}/AGENTS.md" 2>/dev/null && \
        check_pass "AGENTS.md에 Git 정책 포함" || \
        check_warn "AGENTS.md에 Git 정책 누락"
fi

echo ""
echo "📊 검증 결과: ✅ ${PASS} PASS | ❌ ${FAIL} FAIL | ⚠️ ${WARN} WARN"

if [[ ${FAIL} -gt 0 ]]; then
    echo ""
    echo "❌ 검증 실패 — ${FAIL}개 항목 수정 필요"
    exit 1
else
    if [[ ${WARN} -gt 0 ]]; then
        echo ""
        echo "⚠️ 권장사항 ${WARN}개 — 수정 권장하지만 통과"
    fi
    echo ""
    echo "✅ 프로젝트 검증 완료"
    exit 0
fi
