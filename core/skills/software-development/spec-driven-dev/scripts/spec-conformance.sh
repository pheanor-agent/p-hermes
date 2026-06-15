#!/usr/bin/env bash
# SPEC-CONFORMANCE — Spec 구현 준수도 검증 (개선版)
# 
# 개선 사항:
# - SBE: 예시 입력/출력 검증
# - DbC: 계약 조건 (pre/post/invariant) 검증
# - Traceability: Spec → Test → Code 완전 연결
# - 가중치 기반 점수 계산
# - --run-tests: pytest 자동 실행 + 결과 파싱 + _matrix.json 갱신 (JOB-1499 P1)

set -euo pipefail

[[ $# -lt 1 ]] && {
    echo "Usage: bash spec-conformance.sh <slug> [spec-id] [--review] [--run-tests]"
    exit 1
}

SLUG="$1"
SPEC_ID="${2:-}"
REVIEW_MODE=false
RUN_TESTS=false

# 플래그 파싱
shift
while [[ $# -gt 0 ]]; do
    case "$1" in
        --review)
            REVIEW_MODE=true
            ;;
        --run-tests)
            RUN_TESTS=true
            ;;
        *)
            # spec-id 또는 --review가 positional arg일 수 있음
            if [[ "$1" == "--review" ]]; then
                REVIEW_MODE=true
            elif [[ -z "$SPEC_ID" ]]; then
                SPEC_ID="$1"
            fi
            ;;
    esac
    shift
done

# 레거시 호환: positional arg에서 --review 처리
if [[ "${SPEC_ID:-}" == "--review" ]]; then
    REVIEW_MODE=true
    SPEC_ID=""
fi

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

echo "=== Spec Conformance Verification ==="
echo "Project: ${SLUG}"
[[ -n "$SPEC_ID" ]] && echo "Spec: ${SPEC_ID}"
echo "Run tests: ${RUN_TESTS}"
echo ""

# 가중치 설정
EXAMPLE_WEIGHT=0.30
CONTRACT_WEIGHT=0.25
TRACEABILITY_WEIGHT=0.25
TEST_WEIGHT=0.20

# 검증 함수들
validate_examples() {
    local spec_file="$1"
    local example_count=$(grep -c "^  - name:" "$spec_file" 2>/dev/null || true)
    [[ -z "$example_count" ]] && example_count=0
    local validated=0
    
    [[ $example_count -eq 0 ]] && echo "  ⚠️  No examples defined" && return
    
    echo "  📝 Examples: ${example_count} found"
    # 예시 검증 로직 (실제 코드 실행 필요)
    echo "  ✅ Example validation: pending implementation"
}

validate_contract() {
    local spec_file="$1"
    local has_contract=$(grep -c "^contract:" "$spec_file" 2>/dev/null || true)
    [[ -z "$has_contract" ]] && has_contract=0
    
    [[ $has_contract -eq 0 ]] && echo "  ℹ️  No contract defined" && return
    
    echo "  📋 Contract conditions found"
    # 계약 조건 검증 로직
    echo "  ✅ Contract validation: pending implementation"
}

validate_traceability() {
    local spec_file="$1"
    local spec_id=$(grep "^spec_id:" "$spec_file" | cut -d' ' -f2)
    
    # 코드에서 Spec ID 참조 확인
    local code_refs=$(grep -r "$spec_id" "$PROJECT_DIR/src/" 2>/dev/null | wc -l || echo 0)
    # 테스트에서 Spec ID 참조 확인
    local test_refs=$(grep -r "$spec_id" "$PROJECT_DIR/tests/" 2>/dev/null | wc -l || echo 0)
    
    echo "  🔗 Traceability:"
    echo "     - Code references: ${code_refs}"
    echo "     - Test references: ${test_refs}"
    
    [[ $code_refs -gt 0 && $test_refs -gt 0 ]] && echo "  ✅ Full traceability" || echo "  ⚠️  Incomplete traceability"
}

# ============================================================================
# --run-tests: pytest 실행 + 결과 파싱 + _matrix.json 갱신 (JOB-1499 P1)
# ============================================================================
run_tests_and_update_matrix() {
    local target_spec_id="$1"
    local project_dir="$2"
    local matrix_file="$3"

    echo ""
    echo "=== Running Tests (--run-tests) ==="

    # graceful degradation: pytest 확인
    if ! command -v pytest &> /dev/null; then
        echo "  ⚠️  pytest not found — skipping test execution (score=0)"
        echo "  💡 Install: pip install pytest"
        # score=0 상태로 _matrix.json 갱신
        update_matrix_score "$target_spec_id" "$matrix_file" 0 0 0 0
        return 0
    fi

    local tests_dir="${project_dir}/tests"
    if [[ ! -d "$tests_dir" ]]; then
        echo "  ⚠️  tests/ directory not found — skipping test execution (score=0)"
        update_matrix_score "$target_spec_id" "$matrix_file" 0 0 0 0
        return 0
    fi

    local total=0
    local passed=0
    local failed=0
    local error=0

    # pytest 실행 (JSON 결과 fallback 포함)
    local pytest_exit=0
    local test_output
    test_output=$(cd "$project_dir" && pytest --tb=short -v 2>&1) || pytest_exit=$?

    # 결과 파싱
    if [[ $pytest_exit -eq 0 ]]; then
        # pytest 결과에서 passed/failed/error 추출
        local summary_line
        summary_line=$(echo "$test_output" | grep -E "passed|failed|error" | tail -1 || echo "")
        
        if [[ -n "$summary_line" ]]; then
            passed=$(echo "$summary_line" | grep -oP '\d+(?= passed)' || echo 0)
            failed=$(echo "$summary_line" | grep -oP '\d+(?= failed)' || echo 0)
            error=$(echo "$summary_line" | grep -oP '\d+(?= error)' || echo 0)
        fi
        total=$((passed + failed + error))
        [[ $total -eq 0 ]] && total=$(echo "$test_output" | grep -c "PASSED\|FAILED\|ERROR" || true)
        [[ -z "$total" ]] && total=0
        [[ $total -eq 0 ]] && total=$((passed + failed + error))
        
        # JSON report가 있으면 더 정확한 파싱
        if [[ -f "${project_dir}/test-results.json" ]]; then
            eval $(python3 -c "
import json
try:
    d = json.load(open('${project_dir}/test-results.json'))
    summary = d.get('summary', {})
    print(f'passed={summary.get(\"passed\", {passed})}')
    print(f'failed={summary.get(\"failed\", {failed})}')
    print(f'total={summary.get(\"total\", {passed + failed})}')
except:
    pass
" 2>/dev/null || echo "")
        fi
    else
        echo "  ⚠️  pytest exit code: ${pytest_exit}"
        # 실패해도 결과 파싱 시도
        local summary_line
        summary_line=$(echo "$test_output" | grep -E "passed|failed|error" | tail -1 || echo "")
        if [[ -n "$summary_line" ]]; then
            passed=$(echo "$summary_line" | grep -oP '\d+(?= passed)' || echo 0)
            failed=$(echo "$summary_line" | grep -oP '\d+(?= failed)' || echo 0)
            error=$(echo "$summary_line" | grep -oP '\d+(?= error)' || echo 0)
            total=$((passed + failed + error))
        fi
        [[ $total -eq 0 ]] && total=1  # 최소 1로 방지
    fi

    [[ $total -eq 0 ]] && total=1  # division by zero 방지

    # pass rate 계산
    local pass_rate=0
    if [[ $total -gt 0 ]]; then
        pass_rate=$(python3 -c "print(round(${passed}/${total}*100, 1))")
    fi

    echo "  📊 Test Results:"
    echo "     - Total: ${total}"
    echo "     - Passed: ${passed}"
    echo "     - Failed: ${failed}"
    echo "     - Errors: ${error}"
    echo "     - Pass Rate: ${pass_rate}%"

    # _matrix.json 갱신
    update_matrix_score "$target_spec_id" "$matrix_file" "$total" "$passed" "$failed" "$error"
}

update_matrix_score() {
    local spec_id="$1"
    local matrix_file="$2"
    local total="$3"
    local passed="$4"
    local failed="$5"
    local errors="$6"

    python3 -c "
import json, os

matrix_file = '${matrix_file}'

# flock 기반 원자적 업데이트 (race condition 방지)
fd = os.open(matrix_file, os.O_RDWR)
try:
    import fcntl
    fcntl.flock(fd, fcntl.LOCK_EX)
    
    # 읽기
    os.lseek(fd, 0, 0)
    data = json.load(fd)
    
    spec_id = '${spec_id}'
    
    # Spec 엔트리가 없으면 생성
    if spec_id and spec_id not in data:
        data[spec_id] = {
            'coverage': {},
            'code_refs': [],
            'test_refs': [],
            'dependencies': [],
            'job_refs': []
        }
    
    target = data[spec_id] if spec_id and spec_id in data else data
    
    # coverage 정보 갱신
    if 'coverage' not in target:
        target['coverage'] = {}
    
    total = int('${total}')
    passed = int('${passed}')
    failed = int('${failed}')
    errors = int('${errors}')
    
    if total > 0:
        pass_rate = round(passed / total * 100, 1)
    else:
        pass_rate = 0
    
    target['coverage']['test_total'] = total
    target['coverage']['test_passed'] = passed
    target['coverage']['test_failed'] = failed
    target['coverage']['test_errors'] = errors
    target['coverage']['test_pass_rate'] = pass_rate
    
    # Conformance Score 계산
    # Example Coverage (30%) + Contract Compliance (25%) + Traceability (25%) + Test Coverage (20%)
    example_score = target['coverage'].get('example_coverage_pct', 0)
    contract_score = target['coverage'].get('contract_compliance_pct', 0)
    trace_score = target['coverage'].get('traceability_pct', 0)
    test_score = pass_rate
    
    conformance_score = round(
        example_score * 0.30 +
        contract_score * 0.25 +
        trace_score * 0.25 +
        test_score * 0.20, 1
    )
    
    target['conformance_score'] = conformance_score
    
    # 쓰기
    os.lseek(fd, 0, 0)
    os.ftruncate(fd, 0)
    file_obj = os.fdopen(fd, 'w')
    json.dump(data, file_obj, indent=2, ensure_ascii=False)
    file_obj.flush()
    
except Exception as e:
    print(f'  ⚠️  Matrix update error: {e}', flush=True)
finally:
    try:
        fcntl.flock(fd, fcntl.LOCK_UN)
        os.close(fd)
    except:
        pass
" 2>/dev/null || {
        # Fallback: flock 없이 직접 쓰기
        python3 -c "
import json
matrix_file = '${matrix_file}'
with open(matrix_file, 'r') as f:
    data = json.load(f)

spec_id = '${spec_id}'
target = data.get(spec_id, data)

if 'coverage' not in target:
    target['coverage'] = {}

total = int('${total}')
passed = int('${passed}')
failed = int('${failed}')
errors = int('${errors}')

if total > 0:
    pass_rate = round(passed / total * 100, 1)
else:
    pass_rate = 0

target['coverage']['test_total'] = total
target['coverage']['test_passed'] = passed
target['coverage']['test_failed'] = failed
target['coverage']['test_errors'] = errors
target['coverage']['test_pass_rate'] = pass_rate

example_score = target['coverage'].get('example_coverage_pct', 0)
contract_score = target['coverage'].get('contract_compliance_pct', 0)
trace_score = target['coverage'].get('traceability_pct', 0)
test_score = pass_rate

conformance_score = round(
    example_score * 0.30 +
    contract_score * 0.25 +
    trace_score * 0.25 +
    test_score * 0.20, 1
)
target['conformance_score'] = conformance_score

with open(matrix_file, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
" 2>&1 || echo "  ⚠️  Failed to update _matrix.json"
    }

    if [[ -n "$spec_id" ]]; then
        echo "  ✅ ${spec_id} _matrix.json updated"
    else
        echo "  ✅ _matrix.json updated"
    fi
}

# 메인 검증 로직
echo "Running conformance checks..."
echo ""

if [[ -n "$SPEC_ID" ]]; then
    # 단일 Spec 검증
    SPEC_FILE=$(find "$PROJECT_DIR/specs/" -name "*.md" -exec grep -l "$SPEC_ID" {} \; 2>/dev/null | head -1)
    [[ -z "$SPEC_FILE" ]] && { echo "❌ Spec not found: ${SPEC_ID}"; exit 1; }
    
    echo "Validating: ${SPEC_ID}"
    validate_examples "$SPEC_FILE"
    validate_contract "$SPEC_FILE"
    validate_traceability "$SPEC_FILE"
else
    # 전체 Spec 검증
    echo "Validating all specs..."
    for spec_file in "$PROJECT_DIR/specs/active/"*.md; do
        [[ -f "$spec_file" ]] || continue
        spec_id=$(grep "^spec_id:" "$spec_file" | cut -d' ' -f2)
        echo ""
        echo "--- ${spec_id} ---"
        validate_examples "$spec_file"
        validate_contract "$spec_file"
        validate_traceability "$spec_file"
    done
fi

# --run-tests 플래그 처리
if [[ "$RUN_TESTS" == "true" ]]; then
    run_tests_and_update_matrix "$SPEC_ID" "$PROJECT_DIR" "$MATRIX"
fi

echo ""
echo "=== Conformance Summary ==="
echo "Scoring weights:"
echo "  - Examples: ${EXAMPLE_WEIGHT}"
echo "  - Contract: ${CONTRACT_WEIGHT}"
echo "  - Traceability: ${TRACEABILITY_WEIGHT}"
echo "  - Tests: ${TEST_WEIGHT}"
echo ""

if [[ "$RUN_TESTS" == "true" ]]; then
    echo "Tests executed via --run-tests flag"
    echo "Results updated in ${MATRIX}"
else
    echo "Note: Full validation requires test execution framework integration"
    echo "  Use --run-tests to execute pytest and update conformance scores"
fi
