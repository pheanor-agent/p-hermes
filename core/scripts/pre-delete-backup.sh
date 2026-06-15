#!/bin/bash
#==============================================================================
HERMES_ROOT="${HERMES_ROOT:-$HOME/.hermes}"
# pre-delete-backup.sh - 대량 삭제 전 자동 백업
#==============================================================================
#
# 사용법: pre-delete-backup.sh {경로} [경로2...]
#
# 규칙:
# - 10개 이상 파일/폴더 삭제 전 자동 백업
# - 백업 위치: $HERMES_ROOT/backups/pre-delete-{timestamp}/
#
#==============================================================================

set -euo pipefail

BACKUP_DIR="$HERMES_ROOT/backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_PATH="$BACKUP_DIR/pre-delete-$TIMESTAMP"

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <path> [path2...]"
    exit 1
fi

# 삭제 대상 수 계산
count_items() {
    local total=0
    for path in "$@"; do
        if [[ -d "$path" ]]; then
            local count=$(find "$path" -mindepth 1 -maxdepth 1 | wc -l)
            total=$((total + count))
        elif [[ -f "$path" ]]; then
            total=$((total + 1))
        fi
    done
    echo $total
}

ITEM_COUNT=$(count_items "$@")

echo "📊 삭제 대상: $ITEM_COUNT개"

# 10개 이상이면 백업
if [[ $ITEM_COUNT -ge 10 ]]; then
    echo "💾 백업 시작: $BACKUP_PATH"
    
    mkdir -p "$BACKUP_PATH"
    
    for path in "$@"; do
        if [[ -e "$path" ]]; then
            name=$(basename "$path")
            cp -a "$path" "$BACKUP_PATH/$name" 2>/dev/null || {
                echo "  ⚠️ 백업 실패: $path"
            }
        fi
    done
    
    echo "✅ 백업 완료: $BACKUP_PATH"
    echo "   대상: $ITEM_COUNT개"
    exit 0
else
    echo "✅ 백업 생략 ($ITEM_COUNT개 < 10개)"
    exit 0
fi
