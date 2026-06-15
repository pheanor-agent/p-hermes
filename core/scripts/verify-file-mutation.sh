#!/bin/bash
set -euo pipefail

# 파일 뮤테이션 검증 스크립트
# MD5 hash + inode + 파일 읽기 3중 검증
# Usage: verify-file-mutation.sh <file_path>

FILE="$1"
LOCK="${FILE}.lock"

if [[ ! -f "$FILE" ]]; then
    echo "[ERROR] File not found: $FILE"
    exit 1
fi

echo "=== 파일 뮤테이션 검증: $FILE ==="

# 1. MD5 Hash 검증
echo "[1/3] MD5 Hash 검증..."
MD5_BEFORE=$(md5sum "$FILE" | awk '{print $1}')
sleep 0.1
MD5_AFTER=$(md5sum "$FILE" | awk '{print $1}')

if [[ "$MD5_BEFORE" == "$MD5_AFTER" ]]; then
    echo "  ✅ MD5 Hash 일치: $MD5_BEFORE"
else
    echo "  ❌ MD5 Hash 불일치: $MD5_BEFORE → $MD5_AFTER"
    exit 1
fi

# 2. Inode 검증
echo "[2/3] Inode 검증..."
INODE=$(stat -c %i "$FILE" 2>/dev/null || stat -f %i "$FILE" 2>/dev/null)
echo "  Inode: $INODE"
if [[ -n "$INODE" ]] && [[ "$INODE" != "0" ]]; then
    echo "  ✅ Inode 유효"
else
    echo "  ❌ Inode 무효"
    exit 1
fi

# 3. 파일 읽기 검증 (첫 10줄)
echo "[3/3] 파일 읽기 검증..."
LINES=$(head -n 10 "$FILE" 2>/dev/null | wc -l)
SIZE=$(stat -c %s "$FILE" 2>/dev/null || stat -f %z "$FILE" 2>/dev/null)
echo "  크기: ${SIZE} bytes, 읽은 줄: ${LINES}"

if [[ "$SIZE" -gt 0 ]]; then
    echo "  ✅ 파일 읽기 성공"
else
    echo "  ❌ 파일이 비어있음"
    exit 1
fi

echo ""
echo "=== 검증 완료: $FILE ==="
echo "  MD5: $MD5_BEFORE"
echo "  Inode: $INODE"
echo "  Size: ${SIZE} bytes"
exit 0
