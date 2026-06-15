#!/bin/bash
# night-lib.sh — 야간 작업 공통 함수
HERMES_ROOT="${HERMES_ROOT:-$HOME/.hermes}"
# 사용: source $HERMES_ROOT/core/scripts/lib/night-lib.sh

# 로깅 (JSON lines)
log_info()  { echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"level\":\"info\",\"msg\":\"$1\"}" >> $HERMES_ROOT/logs/cron/night-lib.log; echo "[ℹ️] $1"; }
log_warn()  { echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"level\":\"warn\",\"msg\":\"$1\"}" >> $HERMES_ROOT/logs/cron/night-lib.log; echo "[⚠️] $1"; }
log_error() { echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"level\":\"error\",\"msg\":\"$1\"}" >> $HERMES_ROOT/logs/cron/night-lib.log; echo "[❌] $1"; }

# Discord 전송 (토큰 없으면 스킵)
discord_send() {
  local message="$1"
  if [[ -z "${DISCORD_BOT_TOKEN:-}" ]]; then
    log_warn "DISCORD_BOT_TOKEN 없음 - Discord 전송 스킵"
    return 0
  fi
  curl -s -X POST "https://discord.com/api/channels/1503941910459580450/messages" \
    -H "Authorization: Bot ${DISCORD_BOT_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"content\":\"${message}\"}" > /dev/null 2>&1
}

# Telegram 전송 (토큰 없으면 스킵)
telegram_send() {
  local message="$1"
  if [[ -z "${TELEGRAM_BOT_TOKEN:-}" ]]; then
    log_warn "TELEGRAM_BOT_TOKEN 없음 - Telegram 전송 스킵"
    return 0
  fi
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=-3938942705" \
    -d "text=${message}" \
    -d "parse_mode=Markdown" > /dev/null 2>&1
}

# phase 완료 lock file 생성
mark_phase_done() {
  local phase=$1
  local status=$2  # success | failed
  touch $HERMES_ROOT/.${phase}-done.${status}.$(date +%Y%m%d)
  log_info "${phase} phase ${status}"
}
