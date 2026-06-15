#!/bin/bash
# archive-sessions.sh — 7일 이전 세션 jsonl 자동 아카이브
HERMES_ROOT="${HERMES_ROOT:-$HOME/.hermes}"
# 사용법: bash $HERMES_ROOT/core/scripts/archive-sessions.sh

set -euo pipefail

SESSIONS_DIR="$HERMES_ROOT/sessions"
ARCHIVE_DIR="$HERMES_ROOT/archive/sessions"
DAYS_OLD=7

mkdir -p "$ARCHIVE_DIR"

ARCHIVED=0
for file in "$SESSIONS_DIR"/*.jsonl; do
    [ -f "$file" ] || continue
    
    file_date=$(stat -c %Y "$file")
    now=$(date +%s)
    cutoff=$((now - DAYS_OLD*86400))
    
    if [ "$file_date" -lt "$cutoff" ]; then
        basename=$(basename "$file")
        # 년/월별 폴더
        file_month=$(echo "$basename" | grep -oP '^\d{6}' | sed 's/\(....\)\(..\)/\1-\2/')
        month_dir="$ARCHIVE_DIR/$file_month"
        mkdir -p "$month_dir"
        
        gzip -c "$file" > "$month_dir/${basename}.gz"
        rm "$file"
        ARCHIVED=$((ARCHIVED + 1))
    fi
done

echo "아카이브 완료: $ARCHIVED 개 파일"
