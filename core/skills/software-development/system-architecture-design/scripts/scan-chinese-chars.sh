#!/bin/bash
# scan-chinese-chars.sh — CJK non-Korean character scanner
# Usage: bash scan-chinese-chars.sh <file.md>

file="${1:?Usage: scan-chinese-chars.sh <file.md>}"

echo "Scanning: $file"
echo "---"

# Scan for CJK characters (excluding Korean Hangul range)
# CJK Unified Ideographs: U+4E00 - U+9FFF
matches=$(grep -nP '[\x{4e00}-\x{9fff}]' "$file" 2>/dev/null || true)

if [[ -z "$matches" ]]; then
    echo "✅ No Chinese characters found."
    exit 0
else
    echo "❌ Chinese characters found:"
    echo "$matches"
    echo ""
    echo "Common replacements:"
    echo "  惯習 → 관습"
    echo "  待定 → 미정"
    echo "  覆盖率 → 커버리지"
    echo "  权重 → 가중치"
    echo "  轻量 → 경량"
    echo "  安装包 → 설치 패키지"
    exit 1
fi
