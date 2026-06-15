#!/usr/bin/env bash
# spec-drift.sh — Spec↔Code Drift Detection + Scoring
#
# Usage:
#   spec-drift.sh scan <slug>
#   spec-drift.sh report <slug> <spec-id>
#   spec-drift.sh score <slug>
#
# 출력 모드: --json, --quiet, --verbose

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SKILL_DIR}/spec-version.sh"

# ── 전역 옵션 ──────────────────────────────────────────
OUTPUT_MODE="text"   # text | json | quiet
VERBOSE=false

# 옵션 파싱
FILTERED_ARGS=()
for arg in "$@"; do
    case "$arg" in
        --json) OUTPUT_MODE="json" ;;
        --quiet) OUTPUT_MODE="quiet" ;;
        --verbose) VERBOSE=true ;;
        --json|--quiet|--verbose) ;;
        *) FILTERED_ARGS+=("$arg") ;;
    esac
done
set -- "${FILTERED_ARGS[@]}"

# ── 유틸리티 함수 ──────────────────────────────────────
log_verbose() { [[ "$VERBOSE" == "true" ]] && echo "  [VERBOSE] $*" || true; }
log_info() { [[ "$OUTPUT_MODE" != "quiet" ]] && echo "  ℹ️  $*" || true; }
log_error() { echo "  ❌ $*" >&2; }

# ── 명령어: scan ───────────────────────────────────────
cmd_scan() {
    local slug="$1"

    local project_dir="$HOME/.hermes/workspace/projects/${slug}"
    local vm_file="${project_dir}/specs/VERSION_MAP.yaml"

    [[ ! -d "$project_dir" ]] && {
        log_error "프로젝트 '${slug}'을/를 찾을 수 없습니다"
        exit 1
    }

    [[ ! -f "$vm_file" ]] && {
        log_error "VERSION_MAP.yaml을/를 찾을 수 없습니다"
        exit 1
    }

    log_verbose "Drift 스캔: ${slug}"

    python3 - "$vm_file" "$project_dir" "$OUTPUT_MODE" << 'PYEOF'
import yaml, sys, os, json
from datetime import datetime

vm_file = sys.argv[1]
project_dir = sys.argv[2]
output_mode = sys.argv[3]

# VERSION_MAP.yaml 읽기
with open(vm_file, "r") as f:
    vm_data = yaml.safe_load(f) or {}

drifts = []
total_score = 0

specs = vm_data.get("specs", {})
for spec_id, spec_info in specs.items():
    code_refs = spec_info.get("code_refs", [])
    for ref in code_refs:
        file_path = ref.get("file", "")
        full_path = os.path.join(project_dir, file_path)
        
        # 코드 파일 누락 검사
        if not os.path.exists(full_path):
            drifts.append({
                "spec_id": spec_id,
                "file": file_path,
                "drift_type": "CODE_MISSING",
                "severity": "HIGH",
                "score": 10,
                "description": f"Spec에 정의된 코드 파일이 존재하지 않음: {file_path}"
            })
            total_score += 10

# 결과 출력
if output_mode == "json":
    print(json.dumps({
        "project": os.path.basename(project_dir),
        "scan_time": datetime.now().isoformat(),
        "drift_count": len(drifts),
        "severity_score": min(100, total_score),
        "drifts": drifts
    }, ensure_ascii=False, indent=2))
else:
    print(f"🔍 Drift 스캔 완료: {os.path.basename(project_dir)}")
    print(f"  발견된 drift: {len(drifts)}개")
    print(f"  심각도 점수: {min(100, total_score)}/100")
    if drifts:
        print("")
        for d in drifts:
            print(f"  🔴 {d['spec_id']}: {d['description']}")
    else:
        print("  ✅ Drift 없음")
PYEOF
}

# ── 명령어: report ─────────────────────────────────────
cmd_report() {
    local slug="$1"
    local spec_id="$2"

    local project_dir="$HOME/.hermes/workspace/projects/${slug}"
    local vm_file="${project_dir}/specs/VERSION_MAP.yaml"

    [[ ! -d "$project_dir" ]] && {
        log_error "프로젝트 '${slug}'을/를 찾을 수 없습니다"
        exit 1
    }

    [[ ! -f "$vm_file" ]] && {
        log_error "VERSION_MAP.yaml을/를 찾을 수 없습니다"
        exit 1
    }

    log_verbose "Drift 리포트: ${spec_id}"

    python3 - "$vm_file" "$project_dir" "$spec_id" "$OUTPUT_MODE" << 'PYEOF'
import yaml, sys, os, json
from datetime import datetime

vm_file = sys.argv[1]
project_dir = sys.argv[2]
spec_id = sys.argv[3]
output_mode = sys.argv[4]

# VERSION_MAP.yaml 읽기
with open(vm_file, "r") as f:
    vm_data = yaml.safe_load(f) or {}

spec_info = vm_data.get("specs", {}).get(spec_id, {})
if not spec_info:
    print(f"  ❌ Spec '{spec_id}'을/를 찾을 수 없습니다")
    sys.exit(1)

drifts = []
code_refs = spec_info.get("code_refs", [])

for ref in code_refs:
    file_path = ref.get("file", "")
    full_path = os.path.join(project_dir, file_path)
    
    # 코드 파일 누락 검사
    if not os.path.exists(full_path):
        drifts.append({
            "file": file_path,
            "drift_type": "CODE_MISSING",
            "severity": "HIGH",
            "description": f"코드 파일 누락: {file_path}"
        })

# 결과 출력
if output_mode == "json":
    print(json.dumps({
        "spec_id": spec_id,
        "scan_time": datetime.now().isoformat(),
        "drift_count": len(drifts),
        "drifts": drifts
    }, ensure_ascii=False, indent=2))
else:
    print(f"📊 Drift 리포트: {spec_id}")
    print(f"  버전: {spec_info.get('current_version', 'unknown')}")
    print(f"  상태: {spec_info.get('current_status', 'unknown')}")
    print(f"  발견된 drift: {len(drifts)}개")
    if drifts:
        print("")
        for d in drifts:
            print(f"  🔴 {d['description']}")
    else:
        print("  ✅ Drift 없음")
PYEOF
}

# ── 명령어: score ──────────────────────────────────────
cmd_score() {
    local slug="$1"

    local project_dir="$HOME/.hermes/workspace/projects/${slug}"
    local vm_file="${project_dir}/specs/VERSION_MAP.yaml"

    [[ ! -d "$project_dir" ]] && {
        log_error "프로젝트 '${slug}'을/를 찾을 수 없습니다"
        exit 1
    }

    [[ ! -f "$vm_file" ]] && {
        log_error "VERSION_MAP.yaml을/를 찾을 수 없습니다"
        exit 1
    }

    log_verbose "Drift 점수 계산: ${slug}"

    python3 - "$vm_file" "$project_dir" << 'PYEOF'
import yaml, sys, os, json

vm_file = sys.argv[1]
project_dir = sys.argv[2]

# VERSION_MAP.yaml 읽기
with open(vm_file, "r") as f:
    vm_data = yaml.safe_load(f) or {}

total_score = 0
drift_count = 0

specs = vm_data.get("specs", {})
for spec_id, spec_info in specs.items():
    code_refs = spec_info.get("code_refs", [])
    for ref in code_refs:
        file_path = ref.get("file", "")
        full_path = os.path.join(project_dir, file_path)
        
        if not os.path.exists(full_path):
            drift_count += 1
            total_score += 10

score = min(100, total_score)
if score == 0:
    grade = "🟢 우수"
elif score <= 30:
    grade = "🟡 보통"
elif score <= 70:
    grade = "🟠 경고"
else:
    grade = "🔴 심각"

print(f"📈 Drift 점수: {os.path.basename(project_dir)}")
print(f"  점수: {score}/100 {grade}")
print(f"  drift 수: {drift_count}개")
PYEOF
}

# ── 메인 ───────────────────────────────────────────────
if [[ $# -lt 1 ]]; then
    echo "Usage: spec-drift.sh <command> <slug> [args...]"
    echo ""
    echo "Commands:"
    echo "  scan <slug>                     전체 drift 스캔"
    echo "  report <slug> <spec-id>         Spec별 drift 리포트"
    echo "  score <slug>                    drift 점수 계산"
    exit 1
fi

COMMAND="$1"
shift

case "$COMMAND" in
    scan)
        [[ $# -lt 1 ]] && { log_error "사용법: spec-drift.sh scan <slug>"; exit 1; }
        cmd_scan "$@"
        ;;
    report)
        [[ $# -lt 2 ]] && { log_error "사용법: spec-drift.sh report <slug> <spec-id>"; exit 1; }
        cmd_report "$@"
        ;;
    score)
        [[ $# -lt 1 ]] && { log_error "사용법: spec-drift.sh score <slug>"; exit 1; }
        cmd_score "$@"
        ;;
    *)
        log_error "알 수 없는 명령어: $COMMAND"
        exit 1
        ;;
esac
