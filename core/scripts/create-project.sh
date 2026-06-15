#!/usr/bin/env bash
# create-project.sh — 새 프로젝트 메타데이터 생성
HERMES_ROOT="${HERMES_ROOT:-$HOME/.hermes}"
# 사용법: bash create-project.sh <slug> <name> [--job-id JOB-XXXX | --approved-by "사용자명"]
set -euo pipefail

# 인자 파싱
SLUG=""
NAME=""
JOB_ID=""
APPROVED_BY=""

# positional args
if [[ $# -lt 2 ]]; then
  echo "[ERROR] 사용법: create-project.sh <slug> <name> [--job-id JOB-XXXX | --approved-by \"사용자명\"]"
  exit 1
fi

SLUG="$1"
NAME="$2"
shift 2

# optional args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --job-id)
      JOB_ID="$2"
      shift 2
      ;;
    --approved-by)
      APPROVED_BY="$2"
      shift 2
      ;;
    *)
      echo "[ERROR] 알 수 없는 인자: $1"
      exit 1
      ;;
  esac
done

# slug 검증: 소문자, 숫자, 하이픈만 허용
if [[ ! "$SLUG" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
  echo "[ERROR] slug는 소문자, 숫자, 하이픈만 허용 ($SLUG)"
  exit 1
fi

# --job-id 또는 --approved-by 중 하나 필수
if [[ -z "$JOB_ID" && -z "$APPROVED_BY" ]]; then
  echo "[ERROR] --job-id JOB-XXXX 또는 --approved-by \"사용자명\" 중 하나 필수"
  exit 1
fi

# JOB-ID 검증 (--job-id 사용 시)
if [[ -n "$JOB_ID" ]]; then
  # -d 테스트에서 glob 패턴이 작동하지 않으므로 compgen 사용
  job_match=$(compgen -G "$HERMES_ROOT/workspace/jobs/$JOB_ID*" | head -1)
  if [[ -z "$job_match" ]]; then
    echo "[ERROR] JOB 디렉토리 존재하지 않음: $JOB_ID"
    exit 1
  fi
fi

slug_dir=$HERMES_ROOT/knowledge/projects/$SLUG

if [[ -d "$slug_dir" ]]; then
  echo "[ERROR] 프로젝트 '$SLUG' 이미 존재"
  exit 1
fi

mkdir -p "$slug_dir"

# 코드 폴더 생성 ($HERMES_ROOT/code/<slug>/)
CODE_DIR=$HERMES_ROOT/code/$SLUG
mkdir -p "$CODE_DIR"/{src,data,docs}
touch "$CODE_DIR/.gitkeep" 2>/dev/null || true
touch "$CODE_DIR/src/.gitkeep" 2>/dev/null || true
touch "$CODE_DIR/data/.gitkeep" 2>/dev/null || true
touch "$CODE_DIR/docs/.gitkeep" 2>/dev/null || true

NOW=$(date -u +"%Y-%m-%d")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S+09:00")

# project.yaml 생성
if [[ -n "$JOB_ID" ]]; then
  # JOB-ID가 있는 경우 jobs 배열에 포함
  cat > "$slug_dir/project.yaml" << ENDOFYAML
project_id: proj-$(date +%Y%m%d%H%M%S)
name: $NAME
slug: $SLUG
code_path: $HERMES_ROOT/code/$SLUG
created: $NOW
status: active
description: ""
tech_stack: []
tags: []
jobs:
  - id: $JOB_ID
    role: ""
    summary: ""
    status: active
    date: $NOW
artifacts: []
lessons_refs: []
ENDOFYAML
else
  # 승인자만 있는 경우
  cat > "$slug_dir/project.yaml" << ENDOFYAML
project_id: proj-$(date +%Y%m%d%H%M%S)
name: $NAME
slug: $SLUG
code_path: $HERMES_ROOT/code/$SLUG
created: $NOW
status: active
description: ""
tech_stack: []
tags: []
jobs: []
artifacts: []
lessons_refs: []
ENDOFYAML
fi

# decisions.md 생성
cat > "$slug_dir/decisions.md" << ENDOFMD
# 결정 이력

---
ENDOFMD

# timeline.md 생성
cat > "$slug_dir/timeline.md" << ENDOFMD
# 프로젝트 타임라인

## $NOW
- 프로젝트 생성
ENDOFMD

# context.md 생성
cat > "$slug_dir/context.md" << ENDOFMD
# 현재 상태 요약

**프로젝트**: $NAME
**상태**: active
**생성일**: $NOW
**설명**: 미설정
ENDOFMD

# validate-project.sh 호출 (유효성 검증)
if [[ -f "$HERMES_ROOT/core/scripts/validate-project.sh" ]]; then
  bash "$HERMES_ROOT/core/scripts/validate-project.sh" "$SLUG"
  rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "[ERROR] 유효성 검증 실패 — 롤백"
    rm -rf "$slug_dir"
    exit 1
  fi
fi

# .creation-log.md에 기록
REASON="$JOB_ID"
if [[ -n "$APPROVED_BY" ]]; then
  REASON="$APPROVED_BY"
fi
echo "| $NOW | $SLUG | $NAME | $REASON |" >> $HERMES_ROOT/knowledge/projects/.creation-log.md

# index.md 업데이트
echo "- [[${SLUG}/project.yaml]] - $NAME (active)" >> $HERMES_ROOT/knowledge/projects/index.md

echo "[OK] 프로젝트 '$SLUG' 생성 완료: $slug_dir"