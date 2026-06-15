#!/bin/bash
#==============================================================================
HERMES_ROOT="${HERMES_ROOT:-$HOME/.hermes}"
# wiki-periodic-sync.sh - 위키 주기적 동기화
#==============================================================================
#
# 매일 09:00 실행 (Hermes cron, no_agent)
# 지식 원본 전체 → 위키 디렉토리 동기화
#
#==============================================================================

set -euo pipefail

LOG="$HERMES_ROOT/logs/wiki-periodic-sync.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"
}

log "=== 위키 주기 동기화 시작 ==="

# sync-wiki.sh 호출 (전체 모드)
if [[ -f $HERMES_ROOT/core/scripts/hooks/sync-wiki.sh ]]; then
    bash $HERMES_ROOT/core/scripts/hooks/sync-wiki.sh 2>>"$LOG"
    log "sync-wiki.sh 완료"
else
    log "ERROR: sync-wiki.sh 없음"
    echo "❌ sync-wiki.sh 없음"
    exit 1
fi

# rsync-to-local.sh 호출 (로컬 동기화)
if [[ -f $HERMES_ROOT/core/scripts/rsync-to-local.sh ]]; then
    bash $HERMES_ROOT/core/scripts/rsync-to-local.sh 2>>"$LOG"
    log "rsync-to-local 완료"
fi

log "=== 위키 주기 동기화 완료 ==="
echo "✅ 위키 주기 동기화 완료"
