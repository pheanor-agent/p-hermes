#!/usr/bin/env bash
# archive-project.sh — 프로젝트 아카이브
HERMES_ROOT="${HERMES_ROOT:-$HOME/.hermes}"
# 사용법: bash archive-project.sh <slug> --reason "아카이브 이유"
set -euo pipefail

slug="${1:?slug 필요}"
shift

# --reason 파싱
REASON=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --reason)
      REASON="$2"
      shift 2
      ;;
    *)
      echo "[ERROR] 알 수 없는 인자: $1"
      exit 1
      ;;
  esac
done

# reason 필수
if [[ -z "$REASON" ]]; then
  echo "[ERROR] --reason 필수 (아카이브 이유 기록)"
  exit 1
fi

# reason 최소 5자 검증
if [[ ${#REASON} -lt 5 ]]; then
  echo "[ERROR] 아카이브 이유는 최소 5자 이상 입력 필요 (현재: ${#REASON}자)"
  exit 1
fi

proj_dir=$HERMES_ROOT/knowledge/projects/$slug
proj_yaml="$proj_dir/project.yaml"

if [[ ! -f "$proj_yaml" ]]; then
  echo "[ARCHIVE] 오류: 프로젝트 '$slug' 없음"
  exit 1
fi

NOW=$(date +"%Y-%m-%d")

# 1. project.yaml status 변경
sed -i 's/^status: active/status: archived/' "$proj_yaml"
sed -i 's/^status: paused/status: archived/' "$proj_yaml"

# 2. context.md 백업 (최종 상태 기록)
if [[ -f "$proj_dir/context.md" ]]; then
  cp "$proj_dir/context.md" "$proj_dir/context-archived-${NOW}.md"
fi

# 3. timeline.md에 아카이브 기록 추가 (이유 포함)
if [[ -f "$proj_dir/timeline.md" ]]; then
  echo "" >> "$proj_dir/timeline.md"
  echo "## ${NOW}: 프로젝트 아카이브" >> "$proj_dir/timeline.md"
  echo "- 이유: $REASON" >> "$proj_dir/timeline.md"
fi

# 4. .creation-log.md에 아카이브 기록
echo "| $NOW | $slug | (아카이브) | $REASON |" >> $HERMES_ROOT/knowledge/projects/.creation-log.md

echo "[ARCHIVE] ✅ 프로젝트 '$slug' 아카이브 완료: $REASON"