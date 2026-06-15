#!/usr/bin/env bash
# SPEC-IMPACT — Spec 변경 영향 분석 + Risk Score 계산
# 
# Usage: bash spec-impact.sh <slug> <spec-id>
# Example: bash spec-impact.sh my-api SPEC-A001
#
# Risk Score 공식:
# (Impact_Code_Count × 0.3) + (Impact_Test_Count × 0.2) + 
# (Implementation_Completion × 0.3) + (Dependency_Count × 0.2) / 최대 100

set -euo pipefail

[[ $# -lt 2 ]] && {
    echo "Usage: bash spec-impact.sh <slug> <spec-id>"
    exit 1
}

SLUG="$1"
SPEC_ID="$2"
PROJECT_DIR="$HOME/.hermes/workspace/projects/${SLUG}"

[[ ! -d "$PROJECT_DIR" ]] && {
    echo "❌ 프로젝트 '${SLUG}'을/를 찾을 수 없습니다"
    exit 1
}

# Matrix에서 Spec 정보 읽기
MATRIX="$PROJECT_DIR/specs/_matrix.json"
[[ ! -f "$MATRIX" ]] && {
    echo "❌ Matrix 파일을 찾을 수 없습니다"
    exit 1
}

# 코드 참조 수
CODE_COUNT=$(python3 -c "
import json
with open('${MATRIX}') as f:
    data = json.load(f)
if '${SPEC_ID}' in data:
    print(len(data['${SPEC_ID}'].get('code_refs', [])))
else:
    print(0)
")

# 테스트 참조 수
TEST_COUNT=$(python3 -c "
import json
with open('${MATRIX}') as f:
    data = json.load(f)
if '${SPEC_ID}' in data:
    print(len(data['${SPEC_ID}'].get('test_refs', [])))
else:
    print(0)
")

# 구현 완료도 (implementation_completion_pct)
COMPLETION=$(python3 -c "
import json
with open('${MATRIX}') as f:
    data = json.load(f)
if '${SPEC_ID}' in data:
    print(data['${SPEC_ID}'].get('implementation_completion_pct', 0))
else:
    print(0)
")

# 의존성 수 (dependencies)
DEPS_COUNT=$(python3 -c "
import json
with open('${MATRIX}') as f:
    data = json.load(f)
if '${SPEC_ID}' in data:
    print(len(data['${SPEC_ID}'].get('dependencies', [])))
else:
    print(0)
")

# Risk Score 계산
RISK_SCORE=$(python3 -c "
code_count = ${CODE_COUNT}
test_count = ${TEST_COUNT}
completion = ${COMPLETION}
deps_count = ${DEPS_COUNT}

# Risk Score = (Impact_Code × 0.3) + (Impact_Test × 0.2) + 
#              (Completion × 0.3) + (Dependency × 0.2) / 최대 100
score = (code_count * 0.3) + (test_count * 0.2) + (completion * 0.3) + (deps_count * 0.2)
print(min(100, max(0, score)))
")

# 결과 출력
echo "=== ${SPEC_ID} 영향 분석 ==="
echo ""
echo "코드 참조: ${CODE_COUNT}개"
echo "테스트 참조: ${TEST_COUNT}개"
echo "구현 완료도: ${COMPLETION}%"
echo "의존성: ${DEPS_COUNT}개"
echo ""
echo "Risk Score: ${RISK_SCORE}"

# Risk Score 기반 권장사항
if (( $(echo "$RISK_SCORE >= 90" | bc -l) )); then
    echo ""
    echo "🔴 높은 위험 (Risk Score ≥ 90)"
    echo "- Architecture Review 필수"
    echo "- Stakeholder 승인 필요"
    echo "- 영향 범위 상세 분석 권장"
elif (( $(echo "$RISK_SCORE >= 70" | bc -l) )); then
    echo ""
    echo "🟡 중간 위험 (Risk Score 70-89)"
    echo "- Technical Review 권장"
    echo "- 변경 이력 기록 필수"
else
    echo ""
    echo "🟢 낮은 위험 (Risk Score < 70)"
    echo "- 일반 변경 관리 프로세스 준수"
fi

# JOB 연동
JOB_COUNT=$(python3 -c "
import json
with open('${MATRIX}') as f:
    data = json.load(f)
if '${SPEC_ID}' in data:
    print(len(data['${SPEC_ID}'].get('job_refs', [])))
else:
    print(0)
")

if [[ "$JOB_COUNT" -gt 0 ]]; then
    echo ""
    echo "연관 JOB: ${JOB_COUNT}개"
    python3 -c "
import json
with open('${MATRIX}') as f:
    data = json.load(f)
if '${SPEC_ID}' in data:
    for job in data['${SPEC_ID}'].get('job_refs', []):
        print(f'  - {job}')
"
fi