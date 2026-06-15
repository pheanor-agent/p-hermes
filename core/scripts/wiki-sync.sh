#!/usr/bin/env bash
# wiki-sync.sh - Sync Wiki from Local Knowledge Base\n# Uses rsync for efficient incremental sync

set -euo pipefail

SOURCE_DIR="$HOME/.openclaw/workspace/wiki"
DEST_DIR="$HERMES_ROOT/knowledge/wiki-sync"
LOG_FILE="$HERMES_ROOT/logs/wiki-sync.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Ensure directories exist
mkdir -p "$DEST_DIR"

log "Starting Wiki Sync..."

# Use rsync for efficient incremental sync
# -a: archive mode (recursive, preserves permissions/timestamps)
# --delete 제거 (JOB-1392 Phase 2): Hermes에서 생성한 파일 보호
# --exclude='.DS_Store': macOS 쓰레기 파일 제외
# Let's stick to standard mirroring for Wiki.
if command -v rsync &> /dev/null; then
    rsync -a --exclude='.DS_Store' "$SOURCE_DIR/" "$DEST_DIR/" >> "$LOG_FILE" 2>&1
    STATUS=$?
else
    # Fallback to cp if rsync is missing (unlikely on WSL but safe)
    log "rsync not found, using cp -au"
    cp -au "$SOURCE_DIR/"* "$DEST_DIR/" 2>> "$LOG_FILE" || true
    STATUS=$?
fi

if [ $STATUS -eq 0 ]; then
    log "Wiki Sync completed successfully."
else
    log "Wiki Sync completed with errors (exit code: $STATUS)."
    exit $STATUS
fi
