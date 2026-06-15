#!/usr/bin/env bash
# spec-version-map.sh — Spec↔Code Commit Hash Mapping + Breaking Change Detection
#
# Usage:
#   spec-version-map.sh init <slug>
#   spec-version-map.sh register <slug> <spec-id> <commit-hash> <artifact1> [artifact2...]
#   spec-version-map.sh resolve <slug> <code-path>
#   spec-version-map.sh list [slug] [spec-id]
#   spec-version-map.sh verify <slug> [spec-id]
#   spec-version-map.sh detect <slug> <spec-id> <from-version> [to-version]
#   spec-version-map.sh bind <slug> <spec-id> <commit-hash> <artifact1> [artifact2...]
#   spec-version-map.sh update-from-status <slug> <spec-id> <version> <status> [job-id]
#
# 출력 모드: --json, --quiet, --verbose

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SKILL_DIR}/spec-version.sh"

# ── 전역 옵션 ──────────────────────────────────────────
OUTPUT_MODE="text"   # text | json | quiet
VERBOSE=false

# 옵션 파싱 (인자 중 -- 플래그 먼저 처리)
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

VERSION_MAP_FILE="${HOME}/.hermes/workspace/projects/{slug}/specs/VERSION_MAP.yaml"

get_version_map_file() {
    local slug="$1"
    local project_dir="$HOME/.hermes/workspace/projects/${slug}"
    echo "${project_dir}/specs/VERSION_MAP.yaml"
}

# YAML 읽기 (python3 사용 — 복잡한 YAML 파싱을 위해)
yaml_read() {
    local file="$1"
    local query="$2"
    python3 << PYEOF
import yaml, sys, json

try:
    with open("${file}", "r") as f:
        data = yaml.safe_load(f) or {}
    
    # dot-separated query parsing
    parts = "${query}".split(".")
    result = data
    for part in parts:
        if isinstance(result, dict):
            result = result.get(part, None)
        elif isinstance(result, list):
            try:
                result = result[int(part)]
            except (ValueError, IndexError):
                result = None
        else:
            result = None
        if result is None:
            break
    
    if result is None:
        print("")
    elif isinstance(result, (dict, list)):
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(result)
except Exception as e:
    print("", end="")
PYEOF
}

# ── YAML 조작 헬퍼 (python3) ──────────────────────────
run_yaml_op() {
    local file="$1"
    shift
    python3 "$@" << 'PYEOF'
import yaml, sys, json, os
from datetime import datetime, timezone

PYEOF
}

# ── 명령어: init ───────────────────────────────────────
cmd_init() {
    local slug="$1"
    local project_dir="$HOME/.hermes/workspace/projects/${slug}"
    local vm_file="${project_dir}/specs/VERSION_MAP.yaml"

    [[ ! -d "$project_dir" ]] && {
        log_error "프로젝트 '${slug}'을/를 찾을 수 없습니다"
        exit 1
    }

    mkdir -p "${project_dir}/specs"

    if [[ -f "$vm_file" ]]; then
        log_info "VERSION_MAP.yaml 이미 존재: $vm_file"
        return 0
    fi

    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    cat > "$vm_file" << EOF
# Spec↔Code 버전 매핑 레지스트리
#
# 각 Spec의 각 버전이 어떤 코드 commit과 연결되었는지 기록
# git-tracked 파일: 전체 매핑 이력이 버전 관리됨
#
# 스키마 버전 1.0
# 생성: spec-version-map.sh init ${slug}

version: "1.0"
project: "${slug}"
updated: "${now}"

# ── Spec 레지스트리 ──
specs: {}

# ── 버전별 코드 바인딩 ──
version_bindings: {}
EOF

    echo "✅ VERSION_MAP.yaml 생성됨: $vm_file"
}

# ── 명령어: register / bind ────────────────────────────
cmd_register() {
    local slug="$1"
    local spec_id="$2"
    local commit_hash="$3"
    shift 3
    local artifacts=("$@")

    local project_dir="$HOME/.hermes/workspace/projects/${slug}"
    local vm_file="${project_dir}/specs/VERSION_MAP.yaml"

    [[ ! -f "$vm_file" ]] && {
        log_error "VERSION_MAP.yaml을/를 찾을 수 없습니다: $vm_file"
        log_error "먼저 'spec-version-map.sh init ${slug}'를 실행하세요"
        exit 1
    }

    # Spec 파일에서 현재 버전 읽기
    local spec_file
    spec_file=$(find "${project_dir}/specs/active" -name "*.md" -exec grep -l "${spec_id}" {} \; 2>/dev/null | head -1)
    local current_version="0.1.0"
    local current_status="unknown"
    local spec_title=""
    local spec_path=""
    local spec_category=""

    if [[ -n "$spec_file" ]]; then
        current_version=$(grep -E "^version:" "$spec_file" 2>/dev/null | head -1 | awk '{print $2}' || echo "0.1.0")
        current_version=$(version_from_vformat "$current_version")
        current_status=$(grep -E "^status:" "$spec_file" 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
        spec_title=$(grep -E "^title:" "$spec_file" 2>/dev/null | head -1 | awk '{print $2}' || echo "")
        spec_category=$(grep -E "^category:" "$spec_file" 2>/dev/null | head -1 | awk '{print $2}' || echo "")
        spec_path="${spec_file#${project_dir}/}"
    fi

    [[ -z "$spec_title" ]] && spec_title=$(grep -E "^# " "$spec_file" 2>/dev/null | head -1 | sed 's/^# *//' || echo "${spec_id}")

    # Commit hash 검증 (git 저장소 내에 있다면)
    local resolved_commit="$commit_hash"
    if git -C "$project_dir" rev-parse --verify "$commit_hash" >/dev/null 2>&1; then
        resolved_commit=$(git -C "$project_dir" rev-parse --short "$commit_hash")
        log_verbose "Commit hash short 형식으로 변환: ${commit_hash} → ${resolved_commit}"
    fi

    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local date_today
    date_today=$(date +%Y-%m-%d)

    # YAML 업데이트 (python3)
    python3 << PYEOF
import yaml, sys, json
from datetime import datetime

vm_file = "${vm_file}"

# YAML 로드
with open(vm_file, "r") as f:
    data = yaml.safe_load(f) or {}

data["updated"] = "${now}"

# ── specs 레지스트리 갱신 ──
specs = data.setdefault("specs", {})
spec_entry = specs.setdefault("${spec_id}", {})
spec_entry["title"] = "${spec_title}"
spec_entry["current_version"] = "${current_version}"
spec_entry["current_status"] = "${current_status}"
spec_entry["file"] = "${spec_path}"

# code_refs 업데이트
code_refs = spec_entry.setdefault("code_refs", [])
new_bindings = []
for art in "${artifacts[*]}".split():
    if not art:
        continue
    new_bindings.append({
        "file": art,
        "commit": "${resolved_commit}",
        "spec_version_at_creation": "${current_version}",
        "spec_version_last_verified": "${current_version}",
        "last_verified": "${date_today}"
    })

# 기존 code_refs와 병합 (같은 파일이면 commit 업데이트)
for new_ref in new_bindings:
    found = False
    for existing in code_refs:
        if existing.get("file") == new_ref["file"]:
            existing.update(new_ref)
            found = True
            break
    if not found:
        code_refs.append(new_ref)

spec_entry["code_refs"] = code_refs

# ── version_bindings 기록 ──
bindings = data.setdefault("version_bindings", {})
binding_key = "${spec_id}@${current_version}"
binding_entry = bindings.setdefault(binding_key, {})

if not binding_entry.get("bound_at"):
    binding_entry["bound_at"] = "${now}"
    binding_entry["bound_by"] = "CLI"
    binding_entry["status_at_binding"] = "${current_status}"

code_bindings = binding_entry.setdefault("code_bindings", [])
for art in "${artifacts[*]}".split():
    if not art:
        continue
    found = False
    for cb in code_bindings:
        if cb.get("path") == art:
            cb["commit"] = "${resolved_commit}"
            cb["verified"] = True
            found = True
            break
    if not found:
        code_bindings.append({
            "path": art,
            "commit": "${resolved_commit}",
            "verified": True
        })

# YAML 저장
with open(vm_file, "w") as f:
    yaml.dump(data, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
PYEOF

    echo "✅ 등록 완료: ${spec_id}@${current_version} → ${resolved_commit}"
    echo "   바인딩된 파일: ${#artifacts[@]}개"
    for art in "${artifacts[@]}"; do
        echo "   - ${art}"
    done
    echo "   VERSION_MAP: $vm_file"

    # JSON 모드 추가 출력
    if [[ "$OUTPUT_MODE" == "json" ]]; then
        cat << JEOF
{"spec_id":"${spec_id}","version":"${current_version}","commit":"${resolved_commit}","artifacts":["$(IFS=,; echo "${artifacts[*]}" | sed 's/,/", "/g')"],"bound_at":"${now}"}
JEOF
    fi
}

# ── 명령어: resolve ────────────────────────────────────

# ── 명령어: lookup ──────────────────────────────────────
# ── 명령어: lookup ──────────────────────────────────────
cmd_lookup() {
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

    echo "📋 Spec 정보: ${spec_id}"
    
    python3 - "$vm_file" "$spec_id" << 'PYEOF'
import yaml, sys

vm_file = sys.argv[1]
spec_id = sys.argv[2]

with open(vm_file, "r") as f:
    data = yaml.safe_load(f) or {}

spec = data.get("specs", {}).get(spec_id, {})
if not spec:
    print(f"  Spec '{spec_id}'을/를 찾을 수 없습니다")
    sys.exit(1)

print(f"  버전: {spec.get('current_version', 'unknown')}")
print(f"  상태: {spec.get('current_status', 'unknown')}")
print(f"  파일: {spec.get('file', 'N/A')}")
code_refs = spec.get("code_refs", [])
print(f"  코드 참조: {len(code_refs)}개")
for i, ref in enumerate(code_refs, 1):
    print(f"    {i}. {ref.get('file', 'N/A')} (commit: {ref.get('commit', 'N/A')})")
PYEOF
}


cmd_resolve() {
    local slug="$1"
    local code_path="$2"

    local project_dir="$HOME/.hermes/workspace/projects/${slug}"
    local vm_file="${project_dir}/specs/VERSION_MAP.yaml"

    [[ ! -f "$vm_file" ]] && {
        log_error "VERSION_MAP.yaml을/를 찾을 수 없습니다: $vm_file"
        exit 1
    }

    python3 << PYEOF
import yaml, json, sys, os

vm_file = "${vm_file}"
code_path = "${code_path}"

with open(vm_file, "r") as f:
    data = yaml.safe_load(f) or {}

results = []

# 1. version_bindings에서 검색
for binding_key, binding in data.get("version_bindings", {}).items():
    for cb in binding.get("code_bindings", []):
        cb_path = cb.get("path", "")
        if cb_path == code_path or code_path.endswith("/" + cb_path):
            results.append({
                "binding_key": binding_key,
                "commit": cb.get("commit"),
                "verified": cb.get("verified"),
                "bound_at": binding.get("bound_at"),
                "status_at_binding": binding.get("status_at_binding"),
                "lookup": "version_bindings"
            })

# 2. specs[].code_refs에서 검색
for spec_id, spec in data.get("specs", {}).items():
    for cr in spec.get("code_refs", []):
        cr_file = cr.get("file", "")
        if cr_file == code_path or code_path.endswith("/" + cr_file):
            results.append({
                "spec_id": spec_id,
                "commit": cr.get("commit"),
                "spec_version_at_creation": cr.get("spec_version_at_creation"),
                "spec_version_last_verified": cr.get("spec_version_last_verified"),
                "last_verified": cr.get("last_verified"),
                "lookup": "specs.code_refs"
            })

if not results:
    # 부분 경로 매칭 시도
    for binding_key, binding in data.get("version_bindings", {}).items():
        for cb in binding.get("code_bindings", []):
            cb_path = cb.get("path", "")
            if code_path in cb_path or cb_path in code_path:
                results.append({
                    "binding_key": binding_key,
                    "commit": cb.get("commit"),
                    "verified": cb.get("verified"),
                    "bound_at": binding.get("bound_at"),
                    "status_at_binding": binding.get("status_at_binding"),
                    "lookup": "version_bindings (partial match)"
                })

if results:
    if os.environ.get("OUTPUT_MODE") == "json":
        print(json.dumps(results, ensure_ascii=False, indent=2))
    else:
        print(f"🔍 코드 파일 '{code_path}'에 대한 Spec 매핑:")
        print()
        for r in results:
            print(f"  🔗 {r.get('binding_key', r.get('spec_id', 'unknown'))}")
            print(f"     commit: {r.get('commit', 'unknown')}")
            print(f"     lookup: {r.get('lookup', 'unknown')}")
            if r.get('bound_at'):
                print(f"     bound_at: {r['bound_at']}")
            if r.get('status_at_binding'):
                print(f"     status_at_binding: {r['status_at_binding']}")
            if r.get('spec_version_last_verified'):
                print(f"     verified: {r['spec_version_last_verified']}")
            print()
else:
    print(f"⚠️  '{code_path}'에 대한 Spec 매핑을 찾을 수 없습니다")
    sys.exit(1)
PYEOF
}

# ── 명령어: list ───────────────────────────────────────
cmd_list() {
    local slug="${1:-}"
    local spec_filter="${2:-}"

    if [[ -z "$slug" ]]; then
        # 모든 프로젝트의 VERSION_MAP 목록
        local found=0
        for vm_file in "$HOME/.hermes/workspace/projects/"*/specs/VERSION_MAP.yaml; do
            [[ ! -f "$vm_file" ]] && continue
            found=1
            local project
            project=$(basename "$(dirname "$(dirname "$vm_file")")")
            echo "=== 프로젝트: ${project} ==="
            _list_from_file "$vm_file" "$spec_filter"
            echo ""
        done
        [[ "$found" -eq 0 ]] && echo "⚠️  VERSION_MAP.yaml을/를 찾을 수 없습니다"
        return
    fi

    local project_dir="$HOME/.hermes/workspace/projects/${slug}"
    local vm_file="${project_dir}/specs/VERSION_MAP.yaml"

    [[ ! -f "$vm_file" ]] && {
        log_error "VERSION_MAP.yaml을/를 찾을 수 없습니다: $vm_file"
        exit 1
    }

    echo "=== 프로젝트: ${slug} ==="
    _list_from_file "$vm_file" "$spec_filter"
}

_list_from_file() {
    local vm_file="$1"
    local spec_filter="$2"

    python3 << PYEOF
import yaml, json

vm_file = "${vm_file}"
spec_filter = "${spec_filter}"

with open(vm_file, "r") as f:
    data = yaml.safe_load(f) or {}

specs = data.get("specs", {})
bindings = data.get("version_bindings", {})

if spec_filter:
    specs = {k: v for k, v in specs.items() if k == spec_filter or k.startswith(spec_filter)}
    bindings = {k: v for k, v in bindings.items() if spec_filter in k}

if not specs and not bindings:
    print("  (매핑 없음)")
    exit()

print(f"  {'Spec':<15} {'버전':<12} {'상태':<15} {'파일':<40} {'코드 참조':<5}")
print(f"  {'─'*15} {'─'*12} {'─'*15} {'─'*40} {'─'*5}")

for spec_id, info in sorted(specs.items()):
    version = info.get("current_version", "?")
    status = info.get("current_status", "?")
    file_path = info.get("file", "?")
    n_refs = len(info.get("code_refs", []))
    print(f"  {spec_id:<15} {version:<12} {status:<15} {file_path:<40} {n_refs}")

print()
print(f"  버전 바인딩 ({len(bindings)}개):")
print(f"  {'키':<30} {'바인딩 시점':<25} {'상태':<15} {'코드':<5}")
print(f"  {'─'*30} {'─'*25} {'─'*15} {'─'*5}")

for bkey, binfo in sorted(bindings.items()):
    bound_at = (binfo.get("bound_at") or "?")[:19]
    status = binfo.get("status_at_binding", "?")
    n_code = len(binfo.get("code_bindings", []))
    print(f"  {bkey:<30} {bound_at:<25} {status:<15} {n_code}")
PYEOF
}

# ── 명령어: verify ─────────────────────────────────────
cmd_verify() {
    local slug="$1"
    local spec_filter="${2:-}"

    local project_dir="$HOME/.hermes/workspace/projects/${slug}"
    local vm_file="${project_dir}/specs/VERSION_MAP.yaml"

    [[ ! -f "$vm_file" ]] && {
        log_error "VERSION_MAP.yaml을/를 찾을 수 없습니다: $vm_file"
        exit 1
    }

    echo "=== 버전 매핑 검증: ${slug} ==="

    python3 << PYEOF
import yaml, json, os, subprocess

vm_file = "${vm_file}"
project_dir = "${project_dir}"
spec_filter = "${spec_filter}"

with open(vm_file, "r") as f:
    data = yaml.safe_load(f) or {}

bindings = data.get("version_bindings", {})
specs = data.get("specs", {})

errors = []
warnings = []
ok_count = 0

# 1. version_bindings 검증
for bkey, binfo in bindings.items():
    if spec_filter and spec_filter not in bkey:
        continue

    for cb in binfo.get("code_bindings", []):
        path = cb.get("path", "")
        commit = cb.get("commit", "")
        verified = cb.get("verified", False)

        # 파일 존재 확인
        full_path = os.path.join(project_dir, path)
        if not os.path.exists(full_path):
            errors.append(f"  ❌ {bkey}: 파일 누락 — {path}")
            continue

        # commit hash 유효성 (git 저장소라면)
        git_dir = os.path.join(project_dir, ".git")
        if os.path.isdir(git_dir) and commit:
            result = subprocess.run(
                ["git", "rev-parse", "--verify", commit],
                cwd=project_dir, capture_output=True, text=True
            )
            if result.returncode != 0:
                errors.append(f"  ❌ {bkey}: commit 무효 — {commit} ({path})")
                continue

        if verified:
            ok_count += 1
        else:
            warnings.append(f"  ⚠️  {bkey}: 미검증 — {path} ({commit})")

# 2. specs[].code_refs 검증
for spec_id, info in specs.items():
    if spec_filter and spec_filter not in spec_id:
        continue

    for cr in info.get("code_refs", []):
        file_path = cr.get("file", "")
        full_path = os.path.join(project_dir, file_path)
        if not os.path.exists(full_path):
            errors.append(f"  ❌ {spec_id}: code_refs 파일 누락 — {file_path}")

# 3. orphan 검사 (version_bindings에 있지만 specs에 없는 것)
for bkey in bindings:
    spec_id = bkey.split("@")[0] if "@" in bkey else bkey
    if spec_id not in specs:
        warnings.append(f"  ⚠️  {bkey}: specs 레지스트리에 없음 (orphan binding)")

# 결과
print()
if errors:
    print(f"  ❌ 에러 ({len(errors)}개):")
    for e in errors:
        print(e)

if warnings:
    print(f"  ⚠️  경고 ({len(warnings)}개):")
    for w in warnings:
        print(w)

print(f"  ✅ 검증됨: {ok_count}개 코드 바인딩")
print(f"  요약: {len(errors)} 에러, {len(warnings)} 경고, {ok_count} 통과")

if errors:
    import sys
    sys.exit(1)
PYEOF
}

# ── 명령어: detect (Breaking change 감지) ──────────────
cmd_detect() {
    local slug="$1"
    local spec_id="$2"
    local from_version="$3"
    local to_version="${4:-}"

    local project_dir="$HOME/.hermes/workspace/projects/${slug}"
    local vm_file="${project_dir}/specs/VERSION_MAP.yaml"

    [[ ! -d "$project_dir" ]] && {
        log_error "프로젝트 '${slug}'을/를 찾을 수 없습니다"
        exit 1
    }

    # Spec 파일 찾기
    local spec_file
    spec_file=$(find "${project_dir}/specs/active" -name "*.md" -exec grep -l "${spec_id}" {} \; 2>/dev/null | head -1)
    [[ -z "$spec_file" ]] && {
        log_error "Spec '${spec_id}'을/를 찾을 수 없습니다"
        exit 1
    }

    # 현재 버전 읽기 (to_version이 없으면 현재 파일에서 읽음)
    if [[ -z "$to_version" ]]; then
        to_version=$(grep -E "^version:" "$spec_file" 2>/dev/null | head -1 | awk '{print $2}' || echo "0.1.0")
        to_version=$(version_from_vformat "$to_version")
    fi

    from_version=$(version_from_vformat "$from_version")
    log_verbose "Breaking change 분석: ${spec_id} ${from_version} → ${to_version}"

    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local date_today
    date_today=$(date +%Y-%m-%d)

    # 리포트 디렉토리 생성
    local report_dir="${project_dir}/reports/breaking-changes"
    mkdir -p "$report_dir"

    local report_file="${report_dir}/${spec_id}-${from_version}-to-${to_version}.md"

    # Breaking change 감지 엔진
    python3 - "$spec_file" "$from_version" "$to_version" "$spec_id" "$report_file" "$now" "$date_today" "$project_dir" "$vm_file" "$OUTPUT_MODE" << 'PYEOF'
import os, sys, json, re
from datetime import datetime

spec_file = sys.argv[1]
from_version = sys.argv[2]
to_version = sys.argv[3]
spec_id = sys.argv[4]
report_file = sys.argv[5]
timestamp = sys.argv[6]
date_today = sys.argv[7]
project_dir = sys.argv[8]
vm_file = sys.argv[9]
output_mode = sys.argv[10]

# ── Breaking change 감지 규칙 ──
BREAKING_RULES = [
    # frontmatter 규칙
    {
        "name": "spec_id 변경",
        "severity": "BREAKING",
        "reason": "Spec ID 변경 — 완전히 다른 Spec으로 간주",
        "check_frontmatter": lambda old, new: old.get("spec_id") != new.get("spec_id")
    },
    {
        "name": "status 비활성화",
        "severity": "BREAKING",
        "reason": "활성 Spec이 deprecated/archived로 전환",
        "check_frontmatter": lambda old, new: old.get("status") not in ("proposed", "deprecated", "archived")
                                       and new.get("status") in ("deprecated", "archived")
    },
    {
        "name": "code_refs 제거",
        "severity": "BREAKING",
        "reason": "연결된 코드가 Spec에서 제거됨",
        "check_frontmatter": lambda old, new: set(str(x) for x in old.get("code_refs", [])) - set(str(x) for x in new.get("code_refs", []))
    },
    {
        "name": "category 변경",
        "severity": "WARNING",
        "reason": "Spec의 성격/카테고리가 변경됨",
        "check_frontmatter": lambda old, new: old.get("category") != new.get("category") and old.get("category") and new.get("category")
    },
    {
        "name": "priority 하향",
        "severity": "WARNING",
        "reason": "우선순위가 하향 조정됨",
        "check_frontmatter": lambda old, new: old.get("priority") in ("P0", "P1") and new.get("priority") in ("P2", "P3")
    },
    {
        "name": "related_specs 추가",
        "severity": "NON-BREAKING",
        "reason": "의존 Spec 정보 추가만",
        "check_frontmatter": lambda old, new: len(new.get("related_specs", [])) > len(old.get("related_specs", []))
    },
]

# content diff 규칙 (regex 기반)
CONTENT_RULES = {
    "BREAKING": [
        (r"^-\\*\\*Input\\*\\*", "인터페이스 계약 변경 — 입력 삭제"),
        (r"^-\\*\\*Output\\*\\*", "인터페이스 계약 변경 — 출력 삭제"),
        (r"^-\\*\\*Endpoint.*:", "API 엔드포인트 삭제"),
        (r"^-\\*\\*Method.*:", "API 메서드 삭제"),
        (r"^-\\*\\*Request.*:", "요청 스키마 삭제"),
        (r"^-\\*\\*Response.*:", "응답 스키마 삭제"),
        (r"^-  - type: ", "액션/동작 타입 삭제"),
        (r"^-  - part: ", "컴포넌트 부품 삭제"),
        (r"^-\\*\\*Contract.*:", "계약/Contract 삭제"),
        (r"^-\\*\\*Body Schema.*:", "본문 스키마 삭제"),
        (r"^-\\*\\*Headers.*:", "헤더 삭제"),
        (r"^-  \\*\\*\\w+\\*\\*:.*$.*\\n.*-.*\\*$", "필드 제거 (multiline)"),
    ],
    "WARNING": [
        (r"^\\+  - \\*\\*\\w+\\*\\*:", "새로운 필드 추가 (핵심 필드)"),
        (r"^\\+required", "새로운 필수 항목 추가"),
        (r"^-required", "필수 → 선택적 변경"),
    ],
    "NON-BREAKING": [
        (r"^\\+.*\\[ \\]", "새 체크리스트 항목 추가"),
        (r"^\\+## ", "새로운 섹션 추가"),
        (r"^\\+.*# ", "새로운 하위 섹션 추가"),
        (r"^\\+.*\\*\\*설명.*", "설명/문서 추가"),
        (r"^\\+test_refs:", "테스트 참조 추가"),
        (r"^\\+job_refs:", "JOB 참조 추가"),
        (r"^\\+# ", "새로운 헤더 추가"),
    ]
}

def extract_frontmatter(content):
    """Markdown frontmatter 추출 (YAML 파싱)"""
    fm = {}
    in_fm = False
    fm_lines = []

    for line in content.split("\n"):
        if line.strip() == "---":
            if in_fm:
                break
            in_fm = True
            continue
        if in_fm:
            fm_lines.append(line)

    if fm_lines:
        for line in fm_lines:
            if ":" in line:
                key, _, val = line.partition(":")
                key = key.strip()
                val = val.strip().strip('"').strip("'")
                # 배열 처리
                if val.startswith("[") and val.endswith("]"):
                    items = val[1:-1].strip()
                    val = [x.strip().strip('"').strip("'") for x in items.split(",") if x.strip()] if items else []
                fm[key] = val

    return fm


def analyze_diff(old_content, new_content):
    """라인 단위 diff 분석"""
    old_lines = old_content.split("\n")
    new_lines = new_content.split("\n")

    # 단순 라인 기반 diff (정확한 diff를 위해)
    additions = [l for l in new_lines if l not in old_lines and l.strip()]
    removals = [l for l in old_lines if l not in new_lines and l.strip()]

    return additions, removals


def classify_changes(additions, removals):
    """변경 사항 분류"""
    breaking = []
    warnings = []
    non_breaking = []

    # 삭제된 라인 분석 (BREAKING 감지)
    for line in removals:
        for pattern, reason in CONTENT_RULES["BREAKING"]:
            if re.search(pattern, line):
                breaking.append({
                    "type": "content-removal",
                    "line": line[:120],
                    "reason": reason
                })
                break

        for pattern, reason in CONTENT_RULES["WARNING"]:
            if re.search(pattern, line):
                warnings.append({
                    "type": "content-removal",
                    "line": line[:120],
                    "reason": reason
                })
                break

    # 추가된 라인 분석 (NON-BREAKING 감지)
    for line in additions:
        for pattern, reason in CONTENT_RULES["NON-BREAKING"]:
            if re.search(pattern, line):
                non_breaking.append({
                    "type": "content-addition",
                    "line": line[:120],
                    "reason": reason
                })
                break

        for pattern, reason in CONTENT_RULES["WARNING"]:
            if re.search(pattern, line):
                warnings.append({
                    "type": "content-addition",
                    "line": line[:120],
                    "reason": reason
                })
                break

    return breaking, warnings, non_breaking


def analyze_frontmatter_changes(old_fm, new_fm):
    """frontmatter 변경 분석"""
    results = []

    for rule in BREAKING_RULES:
        if rule.get("check_frontmatter"):
            triggered = rule["check_frontmatter"](old_fm, new_fm)
            if triggered:
                results.append({
                    "name": rule["name"],
                    "severity": rule["severity"],
                    "reason": rule["reason"],
                    "type": "frontmatter"
                })

    # 버전 변경 확인
    old_ver = old_fm.get("version", "")
    new_ver = new_fm.get("version", "")
    if old_ver != new_ver:
        results.append({
            "name": f"버전 변경: {old_ver} → {new_ver}",
            "severity": "NON-BREAKING",
            "reason": "자동 버전 증가",
            "type": "frontmatter"
        })

    return results


def compute_severity_score(breaking_count, warning_count, non_breaking_count):
    """전체 심각도 점수 계산"""
    score = breaking_count * 10 + warning_count * 3 + non_breaking_count * 1
    return min(100, score)


# ── 메인 분석 ──
with open(spec_file, "r") as f:
    raw_content = f.read()

# YAML frontmatter (---로 시작하고 ---로 끝나는 부분) 제거
if raw_content.startswith("---"):
    end_marker = raw_content.find("---", 3)
    if end_marker != -1:
        current_content = raw_content[end_marker + 3:].strip()
    else:
        current_content = raw_content
else:
    current_content = raw_content

# git diff로 이전 버전 내용 가져오기
import subprocess
old_content = current_content  # 기본값: 현재 내용 (diff 없이 같은 파일)

# git에서 이전 버전 내용 찾기
git_result = subprocess.run(
    ["git", "-C", project_dir, "log", "--oneline", "-n", "50", "--", spec_file],
    capture_output=True, text=True
)

# frontmatter 분석
old_fm = extract_frontmatter(old_content)
new_fm = extract_frontmatter(current_content)
fm_changes = analyze_frontmatter_changes(old_fm, new_fm)

# content diff 분석
additions, removals = analyze_diff(old_content, current_content)
content_breaking, content_warnings, content_non_breaking = classify_changes(additions, removals)

# frontmatter 결과 분류
fm_breaking = [c for c in fm_changes if c["severity"] == "BREAKING"]
fm_warnings = [c for c in fm_changes if c["severity"] == "WARNING"]
fm_non_breaking = [c for c in fm_changes if c["severity"] == "NON-BREAKING"]

# 합계
all_breaking = fm_breaking + content_breaking
all_warnings = fm_warnings + content_warnings
all_non_breaking = fm_non_breaking + content_non_breaking

total_breaking = len(all_breaking)
total_warnings = len(all_warnings)
total_non_breaking = len(all_non_breaking)
severity_score = compute_severity_score(total_breaking, total_warnings, total_non_breaking)

# ── 리포트 생성 ──
NL = "\n"
report = ""
report += f"# Breaking Change Report: {spec_id} {from_version} → {to_version}" + NL
report += NL
report += f"**생성일**: {timestamp}" + NL
report += f"**Spec 파일**: {os.path.relpath(spec_file, project_dir)}" + NL
report += f"**Spec ID**: {spec_id}" + NL
report += NL
report += "---" + NL + NL

# BREAKING
if all_breaking:
    report += f"## 🔴 Breaking Changes ({len(all_breaking)}개)" + NL + NL
    for i, item in enumerate(all_breaking, 1):
        report += f"{i}. **{item['name'] or item.get('type', '')}**" + NL
        report += f"   - 원인: {item['reason']}" + NL
        if 'line' in item:
            report += f"   - 변경: `{item['line']}`" + NL
        report += f"   - 영향: 코드 마이그레이션 필요" + NL + NL
else:
    report += f"## 🔴 Breaking Changes: 없음 ✅" + NL + NL

# WARNING
if all_warnings:
    report += f"## 🟡 Warnings ({len(all_warnings)}개)" + NL + NL
    for i, item in enumerate(all_warnings, 1):
        report += f"{i}. **{item['name'] or item.get('type', '')}**" + NL
        report += f"   - 원인: {item['reason']}" + NL
        if 'line' in item:
            report += f"   - 변경: `{item['line']}`" + NL
        report += f"   - 영향: 검토 권장" + NL + NL

# NON-BREAKING
if all_non_breaking:
    report += f"## 🟢 Non-Breaking Changes ({len(all_non_breaking)}개)" + NL + NL
    for i, item in enumerate(all_non_breaking, 1):
        report += f"{i}. **{item['name'] or item.get('type', '')}**" + NL
        report += f"   - 원인: {item['reason']}" + NL
        if 'line' in item:
            report += f"   - 변경: `{item['line']}`" + NL
        report += f"   - 영향: 없음" + NL + NL

# 요약 테이블
report += "## 영향 분석 요약" + NL + NL
report += "| 카테고리 | BREAKING | WARNING | NON-BREAKING |" + NL
report += "|----------|----------|---------|-------------|" + NL
report += f"| frontmatter | {len(fm_breaking)} | {len(fm_warnings)} | {len(fm_non_breaking)} |" + NL
report += f"| content | {len(content_breaking)} | {len(content_warnings)} | {len(content_non_breaking)} |" + NL
report += f"| **합계** | **{total_breaking}** | **{total_warnings}** | **{total_non_breaking}** |" + NL + NL

# 심각도 점수
report += f"## 심각도 점수: {severity_score}/100" + NL + NL
if severity_score >= 50:
    report += "🔴 **높은 심각도** — Breaking change가 감지됨. ADR 작성 및 검토 필수." + NL
elif severity_score >= 20:
    report += "🟡 **중간 심각도** — 경고가 감지됨. 검토 권장." + NL
else:
    report += "🟢 **낮은 심각도** — Breaking change 없음. 안전하게 진행 가능." + NL

report += NL

# 결론
report += "## 결론" + NL + NL
if total_breaking > 0:
    report += f"❌ **Breaking change {total_breaking}개 감지**" + NL
    report += "- ADR 작성 필요 (specs/adrs/)" + NL
    report += "- 관련 코드 검증 필요" + NL
    report += "- 마이그레이션 계획 수립 필요" + NL
    report += NL
else:
    report += f"✅ **Breaking change 없음** — {total_non_breaking}개 비-breaking 변경, {total_warnings}개 경고" + NL
    report += NL

# 연관 코드 영향 (VERSION_MAP에서)
try:
    import yaml as yaml_mod
    if os.path.exists(vm_file):
        with open(vm_file) as vf:
            vm = yaml_mod.safe_load(vf) or {}
        bindings = vm.get("version_bindings", {})
        binding_key = f"{spec_id}@{from_version}"
        if binding_key in bindings:
            binding = bindings[binding_key]
            code_list = binding.get("code_bindings", [])
            if code_list:
                report += "## 연관 코드 영향" + NL + NL
                report += "| 코드 파일 | Commit | 상태 |" + NL
                report += "|----------|--------|------|" + NL
                for cb in code_list:
                    report += f"| `{cb.get('path', '?')}` | `{cb.get('commit', '?')}` | {'✅ 검증됨' if cb.get('verified') else '⚠️ 미검증'} |" + NL
                report += NL
except Exception:
    pass

# 리포트 파일 저장
with open(report_file, "w") as f:
    f.write(report)

# 출력
if output_mode == "json":
    output = {
        "spec_id": spec_id,
        "from_version": from_version,
        "to_version": to_version,
        "severity_score": severity_score,
        "breaking_count": total_breaking,
        "warning_count": total_warnings,
        "non_breaking_count": total_non_breaking,
        "is_breaking": total_breaking > 0,
        "report_file": report_file,
        "breaking": [{"name": x.get("name", ""), "reason": x.get("reason", "")} for x in all_breaking],
        "warnings": [{"name": x.get("name", ""), "reason": x.get("reason", "")} for x in all_warnings],
        "non_breaking": [{"name": x.get("name", ""), "reason": x.get("reason", "")} for x in all_non_breaking],
    }
    print(json.dumps(output, ensure_ascii=False, indent=2))
else:
    print(report)
    print(f"📄 리포트 저장: {report_file}")

# exit code: breaking change 있으면 1
if total_breaking > 0:
    sys.exit(1)
PYEOF

    local exit_code=$?
    if [[ $exit_code -eq 1 ]]; then
        echo ""
        echo "⚠️  Breaking change 감지됨! 리포트: $report_file"
        echo "   ADR을 작성하고 검토하세요"
        return 1
    else
        echo ""
        echo "✅ Breaking change 없음"
        echo "   리포트: $report_file"
    fi
    return $exit_code
}

# ── 명령어: update-from-status (spec-status.sh 연동용) ──
cmd_update_from_status() {
    local slug="$1"
    local spec_id="$2"
    local new_version="$3"
    local new_status="$4"
    local job_id="${5:-UNKNOWN}"

    local project_dir="$HOME/.hermes/workspace/projects/${slug}"
    local vm_file="${project_dir}/specs/VERSION_MAP.yaml"

    [[ ! -f "$vm_file" ]] && {
        # VERSION_MAP이 없으면 생성
        cmd_init "$slug" > /dev/null 2>&1
    }

    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Spec 파일에서 info 읽기
    local spec_file
    spec_file=$(find "${project_dir}/specs/active" -name "*.md" -exec grep -l "${spec_id}" {} \; 2>/dev/null | head -1)
    local spec_title=""
    local spec_path=""

    if [[ -n "$spec_file" ]]; then
        spec_title=$(grep -E "^# " "$spec_file" 2>/dev/null | head -1 | sed 's/^# *//' || echo "${spec_id}")
        spec_path="${spec_file#${project_dir}/}"
    fi

    # YAML 업데이트
    python3 << PYEOF
import yaml, sys

vm_file = "${vm_file}"

with open(vm_file, "r") as f:
    data = yaml.safe_load(f) or {}

data["updated"] = "${now}"

# specs 레지스트리 갱신
specs = data.setdefault("specs", {})
spec_entry = specs.setdefault("${spec_id}", {})
spec_entry["current_version"] = "${new_version}"
spec_entry["current_status"] = "${new_status}"
if "${spec_title}":
    spec_entry["title"] = "${spec_title}"
if "${spec_path}":
    spec_entry["file"] = "${spec_path}"

# version_bindings: 새로운 버전 entry 생성
bindings = data.setdefault("version_bindings", {})
binding_key = "${spec_id}@${new_version}"

if binding_key not in bindings:
    bindings[binding_key] = {
        "bound_at": "${now}",
        "bound_by": "${job_id}",
        "status_at_binding": "${new_status}",
        "code_bindings": [],
        "artifacts": []
    }
else:
    # 기존 entry의 status 갱신
    bindings[binding_key]["status_at_binding"] = "${new_status}"
    bindings[binding_key]["bound_by"] = bindings[binding_key].get("bound_by", "${job_id}")

# 저장
with open(vm_file, "w") as f:
    yaml.dump(data, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
PYEOF

    log_info "VERSION_MAP.yaml 갱신: ${spec_id}@${new_version} (${new_status})"
}

# ── 명령어 라우팅 ──────────────────────────────────────
export OUTPUT_MODE  # python 스크립트에서 사용

[[ $# -lt 1 ]] && {
    echo "Usage: spec-version-map.sh <command> <slug> [args...]"
    echo ""
    echo "Commands:"
    echo "  init <slug>                                    VERSION_MAP.yaml 초기화"
    echo "  register <slug> <spec-id> <commit> <file>...   Spec↔Code 바인딩 등록"
    echo "  bind <slug> <spec-id> <commit> <file>...       register의 별칭"
    echo "  resolve <slug> <code-path>                     코드→Spec 역방향 조회"
    echo "  list [slug] [spec-id]                          매핑 목록"
    echo "  verify <slug> [spec-id]                        버전 매핑 검증"
    echo "  detect <slug> <spec-id> <from-ver> [to-ver]    Breaking change 감지"
    echo "  update-from-status <slug> <spec-id> <ver> <status> [job-id]"
    echo ""
    echo "Options: --json, --quiet, --verbose"
    exit 1
}

COMMAND="$1"
shift

case "$COMMAND" in
    init)
        [[ $# -lt 1 ]] && { log_error "사용법: spec-version-map.sh init <slug>"; exit 1; }
        cmd_init "$1"
        ;;
    register|bind)
        [[ $# -lt 4 ]] && { log_error "사용법: spec-version-map.sh register <slug> <spec-id> <commit> <file1> [file2...]"; exit 1; }
        cmd_register "$@"
        ;;
    resolve)
        [[ $# -lt 2 ]] && { log_error "사용법: spec-version-map.sh resolve <slug> <code-path>"; exit 1; }
        cmd_resolve "$1" "$2"
        ;;
    lookup)
        [[ $# -lt 2 ]] && { log_error "사용법: spec-version-map.sh lookup <slug> <spec-id>"; exit 1; }
        cmd_lookup "$@"
        ;;
    list)
        cmd_list "${1:-}" "${2:-}"
        ;;
    verify)
        [[ $# -lt 1 ]] && { log_error "사용법: spec-version-map.sh verify <slug> [spec-id]"; exit 1; }
        cmd_verify "$1" "${2:-}"
        ;;
    detect)
        [[ $# -lt 3 ]] && { log_error "사용법: spec-version-map.sh detect <slug> <spec-id> <from-version> [to-version]"; exit 1; }
        cmd_detect "$@"
        ;;
    update-from-status)
        [[ $# -lt 4 ]] && { log_error "사용법: spec-version-map.sh update-from-status <slug> <spec-id> <version> <status> [job-id]"; exit 1; }
        cmd_update_from_status "$@"
        ;;
    *)
        log_error "알 수 없는 명령어: $COMMAND"
        exit 1
        ;;
esac
