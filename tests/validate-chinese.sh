#!/bin/bash
# validate-chinese.sh - 중국어 문자 검증 스크립트
# 사용법: bash tests/validate-chinese.sh [docs_path]
# 반환: 0 = 성공, 1 = 중국어 문자 발견

set -euo pipefail

DOCS_PATH="${1:-docs/}"

echo "🔍 중국어 문자 검증 시작 ($DOCS_PATH)"

# 중국어 문자 범위: CJK Unified Ideographs (U+4E00 - U+9FFF)
FOUND=$(grep -Prn '[\x{4e00}-\x{9fff}]' "$DOCS_PATH" --include="*.md" --include="*.html" 2>/dev/null || true)

if [[ -n "$FOUND" ]]; then
  echo "❌ 중국어 문자 발견:"
  echo "$FOUND"
  echo ""
  echo "수정 방법: 중국어를 한글로 변경하거나, 기술 용어인 경우 원어 유지"
  exit 1
fi

echo "✅ 중국어 문자 미발견"
exit 0
