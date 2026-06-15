#!/bin/bash
# blackboard-write.sh: 원자적 파일 쓰기 유틸리티
# 사용법: blackboard-write.sh <target_file> <content>

set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Usage: $0 <target_file> <content>"
    exit 1
fi

TARGET="$1"
CONTENT="$2"
DIR=$(dirname "$TARGET")
LOCK="${DIR}/.lock"

# 디렉토리 생성
mkdir -p "$DIR"

# 잠금
exec 200>"$LOCK"
flock -n 200 || { echo "Lock failed: $TARGET"; exit 1; }

# 원자적 쓰기 (temp -> mv)
TMP_FILE=$(mktemp "$DIR/.tmp.XXXXXX")
echo "$CONTENT" > "$TMP_FILE"
mv "$TMP_FILE" "$TARGET"

# 잠금 해제
flock -u 200
rm -f "$LOCK"
