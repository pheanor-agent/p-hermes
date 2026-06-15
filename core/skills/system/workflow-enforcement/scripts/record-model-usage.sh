#!/bin/bash
# record-model-usage.sh - 모델 사용 기록 스크립트
# .workflow-state 파일에 stepModels 배열에 모델 사용 정보 추가

set -euo pipefail

STATE_FILE="${1:-}"
STEP="${2:-}"
ACTUAL_MODEL="${3:-$(hermes config get model.default 2>/dev/null || echo 'unknown')}"

if [ -z "$STATE_FILE" ] || [ -z "$STEP" ]; then
  echo "Usage: $0 <.workflow-state path> <step> [actual_model]"
  exit 1
fi

if [ ! -f "$STATE_FILE" ]; then
  echo "Error: $STATE_FILE not found"
  exit 1
fi

# 추천 모델 확인 (workflow-gate.sh에서 설정)
RECOMMENDED_MODEL=$(grep -A 5 "\"step\": \"$STEP\"" "$STATE_FILE" | grep recommended | cut -d'"' -f4 || echo "unknown")

# 현재 타임스탬프
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S+09:00")

# 모델 일치 여부
MATCHED="false"
if [ "$ACTUAL_MODEL" = "$RECOMMENDED_MODEL" ]; then
  MATCHED="true"
fi

# JSON 업데이트 (jq 사용)
jq --arg step "$STEP" \
   --arg recommended "$RECOMMENDED_MODEL" \
   --arg actual "$ACTUAL_MODEL" \
   --arg matched "$MATCHED" \
   --arg timestamp "$TIMESTAMP" \
   '.stepModels += [{"step": $step, "recommended": $recommended, "actual": $actual, "matched": ($matched == "true"), "reason": null, "recordedAt": $timestamp}]' \
   "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"

echo "Model usage recorded: $STEP (recommended: $RECOMMENDED_MODEL, actual: $ACTUAL_MODEL, matched: $MATCHED)"
