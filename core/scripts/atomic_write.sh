#!/bin/bash
# atomic_write.sh — flock 기반 원자적 파일 쓰기 (JOB-1529)
# 사용법: atomic_write.sh <file> <content>
# 또는: echo "content" | atomic_write.sh <file>
#
# 역할:
# 1. flock을 사용한 파일 잠금 (Race condition 방지)
# 2. 원자적 파일 쓰기 (temp file + mv)
# 3. Stale lock 정리 (TTL: 300초)

set -euo pipefail

FILE="${1:-}"
if [[ -z "$FILE" ]]; then
  echo "ERROR: atomic_write.sh <file> <content>" >&2
  exit 1
fi

LOCK_FILE="${FILE}.lock"
TEMP_FILE="${FILE}.tmp.$$"

# Stale lock 정리 (TTL: 300초) (JOB-1354/1356)
if [[ -f "$LOCK_FILE" ]]; then
  LOCK_AGE=$(( $(date +%s) - $(stat -c %Y "$LOCK_FILE" 2>/dev/null || echo 0) ))
  if [[ $LOCK_AGE -gt 300 ]]; then
    rm -f "$LOCK_FILE"
    echo "INFO: Stale lock 정리 ($LOCK_FILE, age: ${LOCK_AGE}s)" >&2
  fi
fi

# 잠금 획득 및 원자적 쓰기
(
  # Exclusive lock (블로킹)
  flock -x 200 || { echo "ERROR: Lock 획득 실패 ($LOCK_FILE)" >&2; exit 1; }
  
  # stdin에서 읽거나 인자로 받은 내용 사용
  if [[ ! -t 0 ]]; then
    # stdin에서 읽음
    cat > "$TEMP_FILE"
  else
    # 인자로 받은 내용 사용 (2번 인자)
    CONTENT="${2:-}"
    echo "$CONTENT" > "$TEMP_FILE"
  fi
  
  # 원자적 이동 (temp → original)
  mv "$TEMP_FILE" "$FILE"
  
) 200>"$LOCK_FILE"

# Lock 파일 정리
rm -f "$LOCK_FILE"

exit 0
