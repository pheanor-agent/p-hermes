#!/bin/bash
# Hermes Backup Core Engine (JOB-1540)
# Tier 1: Hot Snapshot using rsync hard-links

BACKUP_ROOT="/home/bot/.hermes/backups"
SNAPSHOT_DIR="/home/bot/.hermes/backups/snapshots"
LOG_FILE="/home/bot/.hermes/backups/backup.log"
RETENTION_COUNT=24

mkdir -p "$SNAPSHOT_DIR"
touch "$LOG_FILE"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
CURRENT_SNAPSHOT="$SNAPSHOT_DIR/$TIMESTAMP"
LATEST_SNAPSHOT=$(ls -td "$SNAPSHOT_DIR"/*/ 2>/dev/null | head -n 1)

log "Starting backup snapshot: $TIMESTAMP"
mkdir -p "$CURRENT_SNAPSHOT"

# TARGETS is injected via a placeholder or defined here
TARGETS=()
TARGETS=("/home/bot/.hermes/workspace/jobs" "/home/bot/.hermes/workspace/projects" "/home/bot/.hermes/skills" "/home/bot/.hermes/knowledge" "/home/bot/.hermes/config.yaml" "/home/bot/.hermes/scripts" "/home/bot/.hermes/cron" "/home/bot/.hermes/memories" "/home/bot/.hermes/plugins" "/home/bot/.hermes/AGENTS.md")

for target in "${TARGETS[@]}"; do
    if [ ! -e "$target" ]; then
        log "Warning: Target $target does not exist. Skipping."
        continue
    fi

    if [ -n "$LATEST_SNAPSHOT" ]; then
        # rsync --link-dest needs the absolute path to the previous snapshot
        rsync -a --delete --link-dest="$LATEST_SNAPSHOT" "$target" "$CURRENT_SNAPSHOT/"
    else
        rsync -a "$target" "$CURRENT_SNAPSHOT/"
    fi
done

log "Snapshot $TIMESTAMP completed successfully."

# Retention
SNAPSHOT_LIST=$(ls -td "$SNAPSHOT_DIR"/*/ 2>/dev/null)
COUNT=0
for snap in $SNAPSHOT_LIST; do
    COUNT=$((COUNT + 1))
    if [ $COUNT -gt $RETENTION_COUNT ]; then
        log "Removing old snapshot: $snap"
        rm -rf "$snap"
    fi
done

echo "Backup completed: $TIMESTAMP"
