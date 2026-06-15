#!/usr/bin/env bash
# spec-rollback.sh — Spec Rollback Lifecycle + History Tracking
#
# Usage:
#   spec-rollback.sh rollback <slug> <spec-id> <target-version> [reason]
#   spec-rollback.sh history <slug> <spec-id>
#   spec-rollback.sh preview <slug> <spec-id> <target-version>
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

get_rollback_log_file() {
    local slug="$1"
    local project_dir="$HOME/.hermes/workspace/projects/${slug}"
    echo "${project_dir}/specs/ROLLBACK_LOG.yaml"
}

# ── 명령어: preview ────────────────────────────────────
cmd_preview() {
    local slug="$1"
    local spec_id="$2"
    local target_version="$3"

    local project_dir="$HOME/.hermes/workspace/projects/${slug}"
    local vm_file="${project_dir}/specs/VERSION_MAP.yaml"
    local rollback_log="${project_dir}/specs/ROLLBACK_LOG.yaml"

    [[ ! -d "$project_dir" ]] && {
        log_error "프로젝트 '${slug}'을/를 찾을 수 없습니다"
        exit 1
    }

    [[ ! -f "$vm_file" ]] && {
        log_error "VERSION_MAP.yaml을/를 찾을 수 없습니다"
        exit 1
    }

    log_verbose "롤백 영향 분석: ${spec_id} → ${target_version}"

    # Breaking change 감지
    local breaking_result
    breaking_result=$(bash "${SKILL_DIR}/spec-version-map.sh" detect "$slug" "$spec_id" "$target_version" "" --quiet 2>&1 || echo "")

    if [[ "$OUTPUT_MODE" == "json" ]]; then
        echo "{"spec_id":"${spec_id}","target_version":"${target_version}","breaking_changes":"${breaking_result}"}"
    else
        echo "🔍 롤백 영향 분석: ${spec_id} → ${target_version}"
        if [[ -n "$breaking_result" ]]; then
            echo ""
            echo "Breaking change:"
            echo "$breaking_result"
        else
            echo "  ✅ Breaking change 없음"
        fi
    fi
}

# ── 명령어: rollback ───────────────────────────────────
cmd_rollback() {
    local slug="$1"
    local spec_id="$2"
    local target_version="$3"
    local reason="${4:-사용자 요청}"

    local project_dir="$HOME/.hermes/workspace/projects/${slug}"
    local vm_file="${project_dir}/specs/VERSION_MAP.yaml"
    local rollback_log="${project_dir}/specs/ROLLBACK_LOG.yaml"

    [[ ! -d "$project_dir" ]] && {
        log_error "프로젝트 '${slug}'을/를 찾을 수 없습니다"
        exit 1
    }

    [[ ! -f "$vm_file" ]] && {
        log_error "VERSION_MAP.yaml을/를 찾을 수 없습니다"
        exit 1
    }

    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    log_verbose "롤백 실행: ${spec_id} → ${target_version}"

    # ROLLBACK_LOG.yaml 업데이트
    mkdir -p "${project_dir}/specs"
    python3 - "$vm_file" "$rollback_log" "$spec_id" "$target_version" "$reason" "$now" << 'PYEOF'
import yaml, sys, os
from datetime import datetime

vm_file = sys.argv[1]
rollback_log = sys.argv[2]
spec_id = sys.argv[3]
target_version = sys.argv[4]
reason = sys.argv[5]
now = sys.argv[6]

# VERSION_MAP.yaml 읽기
with open(vm_file, "r") as f:
    vm_data = yaml.safe_load(f) or {}

# 현재 버전 확인
current_spec = vm_data.get("specs", {}).get(spec_id, {})
current_version = current_spec.get("current_version", "unknown")

# 롤백 이력 추가
if not os.path.exists(rollback_log):
    log_data = {}
else:
    with open(rollback_log, "r") as f:
        log_data = yaml.safe_load(f) or {}

if spec_id not in log_data:
    log_data[spec_id] = []

log_entry = {
    "from_version": current_version,
    "to_version": target_version,
    "reason": reason,
    "rolled_back_at": now,
    "rolled_back_by": "CLI",
    "code_sync_status": "pending"
}

log_data[spec_id].append(log_entry)

# ROLLBACK_LOG.yaml 저장
with open(rollback_log, "w") as f:
    yaml.dump(log_data, f, default_flow_style=False, allow_unicode=True)

print(f"  ✅ 롤백 이력 기록: {current_version} → {target_version}")
PYEOF

    # VERSION_MAP.yaml 업데이트
    bash "${SKILL_DIR}/spec-version-map.sh" register "$slug" "$spec_id" "rollback" "" --quiet 2>/dev/null || true

    if [[ "$OUTPUT_MODE" != "quiet" ]]; then
        echo "✅ 롤백 완료: ${spec_id} → ${target_version}"
        echo "   리ASON: ${reason}"
        echo "   로그: ${rollback_log}"
    fi
}

# ── 명령어: history ────────────────────────────────────
cmd_history() {
    local slug="$1"
    local spec_id="$2"

    local project_dir="$HOME/.hermes/workspace/projects/${slug}"
    local rollback_log="${project_dir}/specs/ROLLBACK_LOG.yaml"

    [[ ! -d "$project_dir" ]] && {
        log_error "프로젝트 '${slug}'을/를 찾을 수 없습니다"
        exit 1
    }

    [[ ! -f "$rollback_log" ]] && {
        log_info "롤백 이력이 없습니다"
        exit 0
    }

    if [[ "$OUTPUT_MODE" == "json" ]]; then
        python3 -c "
import yaml, json
with open('${rollback_log}') as f:
    data = yaml.safe_load(f) or {}
print(json.dumps(data.get('${spec_id}', []), ensure_ascii=False, indent=2))
"
    else
        echo "📜 롤백 이력: ${spec_id}"
        python3 << PYEOF
import yaml
with open('${rollback_log}') as f:
    data = yaml.safe_load(f) or {}
history = data.get('${spec_id}', [])
if not history:
    print('  롤백 이력이 없습니다')
else:
    for i, entry in enumerate(history, 1):
        from_v = entry.get('from_version', '?')
        to_v = entry.get('to_version', '?')
        at = entry.get('rolled_back_at', '?')
        reason = entry.get('reason', 'N/A')
        print(f'  {i}. {from_v} → {to_v} ({at})')
        print(f'     이유: {reason}')
PYEOF
    fi
}

# ── 메인 ───────────────────────────────────────────────
if [[ $# -lt 1 ]]; then
    echo "Usage: spec-rollback.sh <command> <slug> [args...]"
    echo ""
    echo "Commands:"
    echo "  rollback <slug> <spec-id> <target-version> [reason]"
    echo "  history <slug> <spec-id>"
    echo "  preview <slug> <spec-id> <target-version>"
    exit 1
fi

COMMAND="$1"
shift

case "$COMMAND" in
    rollback)
        [[ $# -lt 3 ]] && { log_error "사용법: spec-rollback.sh rollback <slug> <spec-id> <target-version> [reason]"; exit 1; }
        cmd_rollback "$@"
        ;;
    history)
        [[ $# -lt 2 ]] && { log_error "사용법: spec-rollback.sh history <slug> <spec-id>"; exit 1; }
        cmd_history "$@"
        ;;
    preview)
        [[ $# -lt 3 ]] && { log_error "사용법: spec-rollback.sh preview <slug> <spec-id> <target-version>"; exit 1; }
        cmd_preview "$@"
        ;;
    *)
        log_error "알 수 없는 명령어: $COMMAND"
        exit 1
        ;;
esac
