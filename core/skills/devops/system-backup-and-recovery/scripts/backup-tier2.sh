#!/bin/bash
# Hermes Tier 2 Backup: Warm Archive
# Logic: Compress latest Tier 1 snapshot into an encrypted tarball.
# Retention: 7 daily bundles.

set -euo pipefail

BACKUP_ROOT="/home/bot/.hermes/backups"
SNAPSHOT_DIR="$BACKUP_ROOT/snapshots"
ARCHIVE_DIR="$BACKUP_ROOT/tier2"
LOG_FILE="$BACKUP_ROOT/backup-tier2.log"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
DATE_ONLY=$(date '+%Y%m%d')
RETENTION_DAILY=7

mkdir -p "$ARCHIVE_DIR"
touch "$LOG_FILE"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

# Find latest snapshot
LATEST_SNAPSHOT=$(ls -td "$SNAPSHOT_DIR"/*/ 2>/dev/null | head -n 1)

if [ -z "$LATEST_SNAPSHOT" ]; then
    log "ERROR: No Tier 1 snapshot found. Run Tier 1 first."
    exit 1
fi

log "=== Tier 2 Warm Archive ==="
log "Source: $LATEST_SNAPSHOT"

# Create compressed archive
ARCHIVE_FILE="$ARCHIVE_DIR/hermes-tier2-${DATE_ONLY}_${TIMESTAMP}.tar.gz.enc"

cd "$(dirname "$LATEST_SNAPSHOT")"
SNAPSHOT_BASENAME=$(basename "$LATEST_SNAPSHOT")

# tar + gzip + openssl encryption (AES-256-CBC, PBKDF2)
ENCRYPT_PASS="hermes-tier2-$(date '+%Y%m')"
tar -czf - "$SNAPSHOT_BASENAME" \
  | openssl enc -aes-256-cbc -salt -pbkdf2 -pass "pass:${ENCRYPT_PASS}" \
  > "$ARCHIVE_FILE"

ARCHIVE_SIZE=$(du -h "$ARCHIVE_FILE" | cut -f1)
log "Archive created: $ARCHIVE_FILE (${ARCHIVE_SIZE})"

# Retention: keep last 7 daily archives
log "Enforcing retention: keep last ${RETENTION_DAILY} daily archives"
OLD_FILES=$(find "$ARCHIVE_DIR" -name "hermes-tier2-*.tar.gz.enc" -type f | sort)
TOTAL=$(echo "$OLD_FILES" | wc -l)
if [ "$TOTAL" -gt "$RETENTION_DAILY" ]; then
    REMOVE_COUNT=$((TOTAL - RETENTION_DAILY))
    echo "$OLD_FILES" | head -n "$REMOVE_COUNT" | while read -r old_file; do
        log "Removing old archive: $(basename "$old_file")"
        rm -f "$old_file"
    done
fi

# Summary
TOTAL_ARCHIVES=$(ls "$ARCHIVE_DIR"/hermes-tier2-*.tar.gz.enc 2>/dev/null | wc -l)
TOTAL_SIZE=$(du -sh "$ARCHIVE_DIR" | cut -f1)
log "=== Tier 2 Complete ==="
log "Total archives: $TOTAL_ARCHIVES | Total size: $TOTAL_SIZE"
