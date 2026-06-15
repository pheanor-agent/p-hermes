#!/bin/bash
set -euo pipefail
HERMES_ROOT="${HERMES_ROOT:-$HOME/.hermes}"

# Knowledge Sync Bridge: Job State -> Wiki Entity
# Usage: knowledge-sync.sh <create|update-design|complete> <JOB_ID>

ACTION=$1
JOB_ID=$2
JOB_DIR=$(find $HERMES_ROOT/workspace/jobs -maxdepth 1 -type d -name "$JOB_ID-*" | head -n 1)
WIKI_DIR="$HERMES_ROOT/knowledge/processed/wiki/jobs"
WIKI_FILE="$WIKI_DIR/$JOB_ID.md"
LOCK="${WIKI_FILE}.lock"

mkdir -p "$WIKI_DIR"

# Atomic Write Wrapper (파일 수정 후 검증 포함)
atomic_write() {
    local file=$1
    local content=$2
    local tmpfile="${file}.tmp.$$"
    
    # 임시 파일에 먼저 쓰기
    echo "$content" > "$tmpfile"
    
    # Pre-write 검증: tmpfile 생성 확인
    if [[ ! -f "$tmpfile" ]]; then
        echo "[ERROR] Failed to create tmpfile: $tmpfile" >&2
        return 1
    fi
    
    (
        flock -x 200
        # 실제 파일로 이동
        mv "$tmpfile" "$file"
        # WSL/VFS 캐시 동기화
        sync
        # 추가 동기화 대기 (WSL latency补偿)
        sleep 0.1
    ) 200>"$LOCK"
    rm -f "$LOCK"
    
    # 파일 뮤테이션 검증 (verify-file-mutation.sh 사용)
    if [[ -f $HERMES_ROOT/core/scripts/verify-file-mutation.sh ]]; then
        bash $HERMES_ROOT/core/scripts/verify-file-mutation.sh "$file" > /dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            echo "[OK] File mutation verified: $file"
            return 0
        fi
    fi
    
    # 폴백: 기존 검증 로직
    local timeout=3
    local count=0
    while [[ $count -lt $timeout ]]; do
        if [[ -f "$file" ]] && [[ -s "$file" ]]; then
            # MD5 hash 검증
            local md5
            md5=$(md5sum "$file" | awk '{print $1}')
            if [[ -n "$md5" ]]; then
                return 0
            fi
        fi
        sleep 1
        count=$((count + 1))
    done
    
    echo "[WARN] File mutation not verified for $file after ${timeout}s" >&2
    return 1
}

case $ACTION in
    create)
        TITLE=$(grep -o 'title: .*' "$JOB_DIR/request.md" 2>/dev/null | head -n 1 | sed 's/title: //' || echo "$JOB_ID")
        CONTENT="---
title: $TITLE
created: $(date +%Y-%m-%d)
status: investigation
source: $JOB_DIR
---
# $JOB_ID: $TITLE
## Request
$(grep -A 10 '## 요청' "$JOB_DIR/request.md" 2>/dev/null | tail -n +2 || echo 'N/A')
"
        atomic_write "$WIKI_FILE" "$CONTENT"
        ;;
    update-design)
        if [[ -f "$WIKI_FILE" ]]; then
            DESIGN=$(grep -A 20 '## 2. 현재 vs 변경' "$JOB_DIR/architecture.md" 2>/dev/null || echo 'N/A')
            CONTENT=$(cat "$WIKI_FILE" | sed 's/status: .*/status: approval/')
            CONTENT="$CONTENT
## Design Summary
$DESIGN
"
            atomic_write "$WIKI_FILE" "$CONTENT"
        fi
        ;;
    complete)
        if [[ -f "$WIKI_FILE" ]]; then
            RESULT=$(grep -A 10 '## 작업 내용' "$JOB_DIR/result.md" 2>/dev/null || echo 'N/A')
            LESSONS=$(grep -A 10 '## 교훈' "$JOB_DIR/lessons.md" 2>/dev/null || echo 'N/A')
            CONTENT=$(cat "$WIKI_FILE" | sed 's/status: .*/status: done/')
            CONTENT="$CONTENT
## Result & Lessons
$RESULT
$LESSONS
"
            atomic_write "$WIKI_FILE" "$CONTENT"
        fi
        ;;
esac

echo "Knowledge sync completed for $JOB_ID ($ACTION)"
