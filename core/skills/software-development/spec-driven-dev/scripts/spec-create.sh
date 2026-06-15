#!/usr/bin/env bash
# spec-create.sh — Spec Item 생성 (P0: Semantic Versioning 지원)
#
# 사용법: bash spec-create.sh <project-slug> <type> <title>
# 예시:   bash spec-create.sh my-api requirement "JWT 인증"

set -euo pipefail

PROJECTS_DIR="${HOME}/.hermes/workspace/projects"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 버전 헬퍼 로드 ────────────────────────────────────
source "${SKILL_DIR}/spec-version.sh"

FROM_REQUEST=""

# 옵션 파싱
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --from-request)
            FROM_REQUEST="$2"
            shift 2
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done
set -- "${POSITIONAL_ARGS[@]}"

if [[ $# -lt 3 ]]; then
    echo "사용법: $0 <project-slug> <type> <title> [--from-request "요청 텍스트"]"
    echo "예시:   $0 my-api requirement \"JWT 인증\" --from-request \"사용자가 JWT로 인증하길 원함\""
    echo ""
    echo "Type: requirement | component | interface | architecture"
    exit 1
fi

SLUG="$1"
TYPE="$2"
TITLE="$3"
PROJECT_DIR="${PROJECTS_DIR}/${SLUG}"

if [[ ! -d "${PROJECT_DIR}" ]]; then
    echo "❌ 프로젝트 '${SLUG}'을(를) 찾을 수 없습니다"
    exit 1
fi

# Spec ID 할당
INDEX_FILE="${PROJECT_DIR}/specs/_index.yaml"
if [[ ! -f "${INDEX_FILE}" ]]; then
    echo "❌ _index.yaml을(를) 찾을 수 없습니다"
    exit 1
fi

# 카테고리 매핑
case "${TYPE}" in
    requirement)  CATEGORY="A" ;;
    component)    CATEGORY="B" ;;
    interface)    CATEGORY="C" ;;
    architecture) CATEGORY="O" ;;
    *) echo "❌Unknown type: ${TYPE} (requirement|component|interface|architecture)"; exit 1 ;;
esac

# 다음 ID 추출
NEXT_NUM=$(grep -A1 "^${CATEGORY}:" "${INDEX_FILE}" | tail -1 | tr -d ' ' || echo "1")
if [[ -z "${NEXT_NUM}" ]] || [[ ! "${NEXT_NUM}" =~ ^[0-9]+$ ]]; then
    NEXT_NUM=1
fi

SPEC_ID="SPEC-${CATEGORY}${NEXT_NUM}"
NEXT_NUM=$((NEXT_NUM + 1))

# 초기 버전 (SemVer)
INITIAL_VERSION="0.1.0"

echo "📝 Spec 생성: ${SPEC_ID} — ${TITLE}"
echo "   프로젝트: ${SLUG}"
echo "   유형: ${TYPE}"
echo "   버전: ${INITIAL_VERSION}"

# 템플릿 선택
TEMPLATE_DIR="${PROJECT_DIR}/specs/templates"
case "${TYPE}" in
    requirement)  TEMPLATE="${TEMPLATE_DIR}/requirement.md" ;;
    component)    TEMPLATE="${TEMPLATE_DIR}/component.md" ;;
    interface)    TEMPLATE="${TEMPLATE_DIR}/interface.md" ;;
    architecture) TEMPLATE="${TEMPLATE_DIR}/architecture.md" ;;
esac

if [[ ! -f "${TEMPLATE}" ]]; then
    echo "⚠️ 템플릿 없음: ${TEMPLATE} — 기본 생성"
    TEMPLATE=""
fi

# 파일명 생성
FILENAME=$(echo "${TITLE}" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9\-]//g')
if [[ "${TYPE}" == "architecture" ]]; then
    TARGET_DIR="${PROJECT_DIR}/specs/active"
    FILENAME="architecture.md"
else
    TARGET_DIR="${PROJECT_DIR}/specs/active/components"
fi

TARGET_FILE="${TARGET_DIR}/${FILENAME}.md"

# ── Spec 파일 생성 ────────────────────────────────────
TODAY=$(date +%Y-%m-%d)

if [[ -n "${TEMPLATE}" ]]; then
    cp "${TEMPLATE}" "${TARGET_FILE}"
else
    cat > "${TARGET_FILE}" << EOF
---
spec_id: ${SPEC_ID}
version: ${INITIAL_VERSION}
version_history:
  - version: ${INITIAL_VERSION}
    date: ${TODAY}
    status: proposed
    summary: "초기 생성"
status: proposed
priority: P?
category: ${TYPE}
related_specs: []
code_refs: []
test_refs: []
job_refs: []
created: ${TODAY}
updated: ${TODAY}
---

### [${SPEC_ID}] ${TITLE}

**설명**:

**검증 기준**:
- [ ] 검증 항목 1
- [ ] 검증 항목 2

**Traceability**:
- 코드: \`\`
- 테스트: \`\`
- JOB: \`\`
EOF
fi

# 내용 치환
sed -i "s/SPEC-XXX/${SPEC_ID}/g" "${TARGET_FILE}"
sed -i "s/제목/${TITLE}/g" "${TARGET_FILE}"

# 템플릿에서 version_history의 날짜와 status 초기화
if grep -q "version_history:" "${TARGET_FILE}"; then
    sed -i "/version_history:/,/summary:/ {
        s/date: YYYY-MM-DD/date: ${TODAY}/
    }" "${TARGET_FILE}"
fi

echo "✅ Spec 파일 생성: ${TARGET_FILE}"

# _index.yaml 갱신
sed -i "s/^${CATEGORY}: ${NEXT_NUM-1}$/${CATEGORY}: ${NEXT_NUM}/" "${INDEX_FILE}" 2>/dev/null || true

echo "✅ _index.yaml 갱신 (다음 ${CATEGORY} ID: ${NEXT_NUM})"

# _matrix.json 갱신
python3 << PYEOF
import json
from datetime import date

matrix_file = "${PROJECT_DIR}/specs/_matrix.json"
with open(matrix_file) as f:
    matrix = json.load(f)

matrix["items"]["${SPEC_ID}"] = {
    "title": "${TITLE}",
    "type": "${TYPE}",
    "status": "proposed",
    "version": "${INITIAL_VERSION}",
    "version_history": [
        {
            "version": "${INITIAL_VERSION}",
            "date": str(date.today()),
            "status": "proposed",
            "summary": "초기 생성"
        }
    ],
    "created": str(date.today()),
    "code_refs": [],
    "test_refs": [],
    "job_refs": [],
    "coverage": {
        "code_coverage_pct": 0,
        "test_pass_rate": 0,
        "conformance_score": 0
    }
}

with open(matrix_file, 'w') as f:
    json.dump(matrix, f, indent=2, ensure_ascii=False)
PYEOF

echo "✅ _matrix.json 갱신 (version: ${INITIAL_VERSION})"

# ── CHANGELOG 초기 entry 생성 ─────────────────────────
CHANGELOG_DIR="${PROJECT_DIR}/specs/history"
CHANGELOG_FILE="${CHANGELOG_DIR}/CHANGELOG.md"
mkdir -p "${CHANGELOG_DIR}"

if [[ ! -f "${CHANGELOG_FILE}" ]]; then
    cat > "${CHANGELOG_FILE}" << 'HEADER'
# Spec 변경 이력 (Changelog)

본 파일은 spec-status.sh 및 spec-changelog.sh에 의해 자동 관리됩니다.
변경 이력은 [Keep a Changelog](https://keepachangelog.com/) 형식을 따릅니다.

HEADER
fi

cat >> "${CHANGELOG_FILE}" << EOF

## [${INITIAL_VERSION}] ${SPEC_ID} — ${TODAY}

- **변경 유형**: Added
- **상태**: proposed
- **초기 생성**: ${TITLE}
- **Spec 파일**: ${TARGET_FILE#${PROJECT_DIR}/}
EOF

echo "✅ CHANGELOG 초기 entry 생성"

echo ""
echo "🎉 Spec '${SPEC_ID}' 생성 완료! (version: ${INITIAL_VERSION})"
echo "   파일: ${TARGET_FILE}"
echo ""
echo "다음 단계:"
echo "  1. Spec 파일 편집: ${TARGET_FILE}"
echo "  2. 구조 검증: bash ~/.hermes/scripts/project/validate-project.sh ${SLUG}"
echo "  3. 상태 변경: bash spec-status.sh ${SLUG} ${SPEC_ID} approved"
