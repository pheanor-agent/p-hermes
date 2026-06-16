#!/bin/bash
#==============================================================================
HERMES_ROOT="${HERMES_ROOT:-$HOME/.hermes}"
# sync.sh - 데이터 동기화 (Hermes→OpenClaw)
#==============================================================================
#
# JOB-1419: 에르메스 크론잡 스크립트 로직 구현
#
# 실행: 04:00 (Hermes cron)
# 기능: Hermes→OpenClaw单向 동기화
#
#==============================================================================

set -euo pipefail

LOG_DIR="/home/bot/.hermes/logs"
LOG_FILE="$LOG_DIR/sync.log"

mkdir -p "$LOG_DIR"

log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" >> "$LOG_FILE"
    echo "[$level] $*"
}

log "INFO" "=== sync.sh 시작 ==="

# rsync-to-openclaw.sh 호출
if [ -x $HERMES_ROOT/core/scripts/rsync-to-openclaw.sh ]; then
    log "INFO" "rsync-to-openclaw.sh 실행..."
    bash $HERMES_ROOT/core/scripts/rsync-to-openclaw.sh 2>&1 | while read -r line; do
        log "INFO" "$line"
    done
    log "INFO" "동기화 완료"
else
    log "WARN" "rsync-to-openclaw.sh 없음 - 직접 rsync 실행"
    rsync -avz --delete         /home/bot/.hermes/knowledge/wiki/         /home/bot/.openclaw/workspace/knowledge/wiki/         2>&1 | while read -r line; do
        log "INFO" "$line"
    done
fi

# JOB-1529: Signal Detector Inbox Flush
log "INFO" "Inbox Flush 시작..."
if [ -x $HERMES_ROOT/core/scripts/inbox-flush.sh ]; then
    bash $HERMES_ROOT/core/scripts/inbox-flush.sh 2>&1 | while read -r line; do
        log "INFO" "$line"
    done
else
    log "WARN" "inbox-flush.sh 없음"
fi

log "INFO" "=== sync.sh 종료 ==="
echo "✅ sync.sh 완료"
