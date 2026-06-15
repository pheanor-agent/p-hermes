#!/usr/bin/env bash
# SPEC-SYNC — Traceability Matrix 자동 동기화
# 
# Usage: bash spec-sync.sh <slug> [spec-id]
# Example: bash spec-sync.sh my-api
#          bash spec-sync.sh my-api SPEC-A001
#
# 동작:
# 1. src/ 하위 코드 annotation 스캔 (`// SPEC-XXX`)
# 2. tests/ 하위 테스트 annotation 스캔 (`@spec_id("SPEC-XXX")`)
# 3. Matrix 자동 갱신

set -euo pipefail

[[ $# -lt 1 ]] && {
    echo "Usage: bash spec-sync.sh <slug> [spec-id]"
    exit 1
}

SLUG="$1"
SPEC_ID="${2:-}"
PROJECT_DIR="$HOME/.hermes/workspace/projects/${SLUG}"

[[ ! -d "$PROJECT_DIR" ]] && {
    echo "❌ 프로젝트 '${SLUG}'을/를 찾을 수 없습니다"
    exit 1
}

MATRIX="$PROJECT_DIR/specs/_matrix.json"
[[ ! -f "$MATRIX" ]] && {
    echo "❌ Matrix 파일을 찾을 수 없습니다"
    exit 1
}

echo "=== Traceability Matrix 동기화 시작 ==="
echo "프로젝트: ${SLUG}"
echo ""

# 코드 annotation 스캔
echo "📁 코드 annotation 스캔..."
if [[ -d "$PROJECT_DIR/src" ]]; then
    CODE_REFS=$(find "$PROJECT_DIR/src" -name "*.py" -o -name "*.js" -o -name "*.ts" 2>/dev/null | xargs grep -l "SPEC-${SPEC_ID:-[A-Z][0-9]\+}" 2>/dev/null | wc -l || echo "0")
else
    CODE_REFS=0
fi
echo "   코드 참조: ${CODE_REFS}개 파일"

# 테스트 annotation 스캔
echo "🧪 테스트 annotation 스캔..."
if [[ -d "$PROJECT_DIR/tests" ]]; then
    TEST_REFS=$(find "$PROJECT_DIR/tests" -name "*.py" -o -name "*.js" -o -name "*.ts" 2>/dev/null | xargs grep -l "SPEC-${SPEC_ID:-[A-Z][0-9]\+}" 2>/dev/null | wc -l || echo "0")
else
    TEST_REFS=0
fi
echo "   테스트 참조: ${TEST_REFS}개 파일"

# Matrix 갱신
echo ""
echo "🔄 Matrix 갱신..."
export MATRIX PROJECT_DIR SPEC_ID
python3 << PYEOF
import json
import os
import re

matrix_path = os.environ.get('MATRIX', '')
project_dir = os.environ.get('PROJECT_DIR', '')
spec_id = os.environ.get('SPEC_ID', '')

with open(matrix_path) as f:
    data = json.load(f)

# 코드 참조 수집
code_refs = []
if os.path.exists(f"{project_dir}/src"):
    for root, dirs, files in os.walk(f"{project_dir}/src"):
        for file in files:
            if file.endswith(('.py', '.js', '.ts')):
                filepath = os.path.join(root, file)
                with open(filepath) as f:
                    content = f.read()
                    if spec_id:
                        if spec_id in content:
                            code_refs.append(f"src/{file}")
                    else:
                        matches = re.findall(r'SPEC-([A-Z][0-9]+)', content)
                        for match in matches:
                            spec_id_match = f"SPEC-{match}"
                            if spec_id_match not in data:
                                data[spec_id_match] = {
                                    'title': spec_id_match,
                                    'status': 'unknown',
                                    'code_refs': [],
                                    'test_refs': [],
                                    'job_refs': [],
                                    'coverage': {}
                                }
                            if f"src/{file}" not in data[spec_id_match].get('code_refs', []):
                                data[spec_id_match]['code_refs'].append(f"src/{file}")

# 테스트 참조 수집
test_refs = []
if os.path.exists(f"{project_dir}/tests"):
    for root, dirs, files in os.walk(f"{project_dir}/tests"):
        for file in files:
            if file.endswith(('.py', '.js', '.ts')):
                filepath = os.path.join(root, file)
                with open(filepath) as f:
                    content = f.read()
                    if spec_id:
                        if spec_id in content:
                            test_refs.append(f"tests/{file}")
                    else:
                        matches = re.findall(r'@spec_id\("?(SPEC-[A-Z][0-9]+)"?\)', content)
                        for match in matches:
                            spec_id_match = f"SPEC-{match}"
                            if spec_id_match not in data:
                                data[spec_id_match] = {
                                    'title': spec_id_match,
                                    'status': 'unknown',
                                    'code_refs': [],
                                    'test_refs': [],
                                    'job_refs': [],
                                    'coverage': {}
                                }
                            if f"tests/{file}" not in data[spec_id_match].get('test_refs', []):
                                data[spec_id_match]['test_refs'].append(f"tests/{file}")

# 갱신된 Spec 목록
UPDATED_SPECS = []
for sid in data:
    if code_refs or test_refs:
        data[sid]['code_refs'] = list(set(data[sid].get('code_refs', []) + code_refs))
        data[sid]['test_refs'] = list(set(data[sid].get('test_refs', []) + test_refs))
        UPDATED_SPECS.append(sid)

# 저장
with open(matrix_path, 'w') as f:
    json.dump(data, f, indent=2)

print(f"   갱신된 Spec: {len(UPDATED_SPECS)}개")
for sid in UPDATED_SPECS:
    print(f"   - {sid}")

PYEOF

echo ""
echo "✅ Matrix 동기화 완료"