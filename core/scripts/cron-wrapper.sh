#!/usr/bin/env bash
# cron-wrapper.sh — no-agent 크론 잡 실행 래퍼
# history 기록 + 실패 alerting + 메시지 포맷팅 + 이벤트 버스 연동
#
# 사용법:
#   cron-wrapper.sh --name <job_name> --type <cron_job|system_crontab> -- <command>
#   cron-wrapper.sh --name verify --type cron_job -- bash ~/.hermes/scripts/verify.sh
#   cron-wrapper.sh --name memory-monitor --type system_crontab -- bash /path/to/monitor.sh

set -euo pipefail

# 이벤트 버스 연동 (JOB-1620)
source "$HOME/.hermes/skills/shared/system-common/lib/event.sh" 2>/dev/null || true
source "$HOME/.hermes/skills/shared/system-common/lib/log.sh" 2>/dev/null || true

# 상관 ID 생성
CORRELATION_ID="CRON-$(date +%Y%m%d-%H%M)-$$"
export CORRELATION_ID

# --- 파싱 ---
NAME=""
TYPE="cron_job"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) NAME="$2"; shift 2 ;;
    --type) TYPE="$2"; shift 2 ;;
    --) shift; break ;;
    *) break ;;
  esac
done
CMD="$*"

# --- 실행 및 기록 ---
HISTORY_DIR="$HOME/.hermes/cron/history"
HISTORY_FILE="$HISTORY_DIR/${NAME}.json"
mkdir -p "$HISTORY_DIR"

START=$(date +%s)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S+09:00")
RUN_ID=$(date +"%Y-%m-%d_%H%M%S")

# history 파일 초기 생성
if [[ ! -f "$HISTORY_FILE" ]]; then
  cat > "$HISTORY_FILE" <<EOF
{
  "job_name": "${NAME}",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%S+09:00")",
  "max_entries": 90,
  "entries": []
}
EOF
fi

# 명령어 실행 (output 파일로 리다이렉트)
OUTPUT_FILE=$(mktemp)
EXIT_CODE=0
bash -c "$CMD" > "$OUTPUT_FILE" 2>&1 || EXIT_CODE=$?

END=$(date +%s)
DURATION=$((END - START))

# 결과 판정 (exit_code + stdout 키워드 조합)
if [[ $EXIT_CODE -eq 0 ]]; then
  STATUS="completed"
  # stdout 키워드 기반 세부 판정
  if grep -qiE "(warning|warn|임계치|경고|attention)" "$OUTPUT_FILE"; then
    STATUS="warning"
  fi
  ERROR_MSG="null"
else
  STATUS="failed"
  ERROR_MSG="\"$(head -c 200 "$OUTPUT_FILE" | sed 's/"/\\"/g')\""
fi

# 요약 (exit_code≠0 시 전체 출력)
if [[ $EXIT_CODE -eq 0 ]]; then
  SUMMARY="\"$(head -c 200 "$OUTPUT_FILE" | sed 's/"/\\"/g')\""
else
  FULL_OUTPUT=$(cat "$OUTPUT_FILE" | sed 's/"/\\"/g')
  SUMMARY="\"$FULL_OUTPUT\""
fi

# history.json에 신규 엔트리 추가 (jq 사용)
ENTRY=$(jq -n \
  --arg run_id "$RUN_ID" \
  --arg timestamp "$TIMESTAMP" \
  --arg status "$STATUS" \
  --argjson duration "$DURATION" \
  --argjson exit_code "$EXIT_CODE" \
  --arg summary "$SUMMARY" \
  --argjson error "$ERROR_MSG" \
  --arg type "$TYPE" \
  '{run_id:$run_id, timestamp:$timestamp, status:$status, duration_seconds:$duration, exit_code:$exit_code, summary:$summary, error_message:$error, type:$type, mode:"no-agent"}')

# entries 배열에 추가 + max_entries 회전
TMP=$(mktemp)
jq --argjson entry "$ENTRY" \
   '.entries = [$entry] + .entries | .entries = .entries[0:.max_entries]' \
   "$HISTORY_FILE" > "$TMP" && mv "$TMP" "$HISTORY_FILE"

# 메시지 포맷팅
case $STATUS in
  completed)
    SUMMARY_LINE=$(grep -iE "(정상|OK|completed|완료|success)" "$OUTPUT_FILE" | head -1)
    [[ -z "$SUMMARY_LINE" ]] && SUMMARY_LINE="완료"
    echo "✅ $NAME: $SUMMARY_LINE"
    ;;
  warning)
    echo "⚠️ $NAME: $(head -1 "$OUTPUT_FILE")"
    echo "🔗 상세: $HISTORY_FILE"
    ;;
  failed)
    echo "🔴 $NAME: $(head -5 "$OUTPUT_FILE")"
    echo "📋 조치: 로그 확인 및 재실행 고려"
    echo "🔗 상세: $HISTORY_FILE"
    ;;
esac

rm -f "$OUTPUT_FILE"

# --- 실패 alerting ---
if [[ "$STATUS" == "failed" ]]; then
  # 연속 실패 카운팅: entries가 최신순이므로 맨 앞부터 연속된 failed 항목만 세기
  CONSECUTIVE=$(jq '
    .entries | reduce .[] as $entry (
      {count: 0, done: false};
      if .done then .
      elif $entry.status == "failed" then .count += 1
      else .done = true
      end
    ) | .count
  ' "$HISTORY_FILE")
  if [[ $CONSECUTIVE -ge 3 ]]; then
    # Discord 알림 (Hermes CLI 또는 webhook)
    echo "[ALERT] $NAME: ${CONSECUTIVE}회 연속 실패" >&2
  fi
fi

# --- 이벤트 버스 발행 (JOB-1620) ---
if declare -f emit_event &>/dev/null; then
  PAYLOAD=$(jq -n \
    --arg name "$NAME" \
    --arg type "$TYPE" \
    --arg status "$STATUS" \
    --argjson duration "$DURATION" \
    --argjson exit_code "$EXIT_CODE" \
    '{name:$name, type:$type, status:$status, duration_seconds:$duration, exit_code:$exit_code}')
  emit_event "cron.${STATUS}" "$CORRELATION_ID" "$PAYLOAD" 2>/dev/null || true
fi

exit $EXIT_CODE
