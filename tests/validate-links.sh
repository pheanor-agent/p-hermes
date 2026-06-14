#!/bin/bash
# validate-links.sh — docs/ 내부 markdown 링크 검증
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DOCS_DIR="$PROJECT_DIR/docs"

ERRORS=0

while IFS= read -r f; do
  while IFS= read -r link; do
    [[ "$link" == http* ]] && continue
    base=$(dirname "$f")
    target=$(cd "$base" && realpath -m "$link" 2>/dev/null || echo "$base/$link")
    if [[ ! -f "$target" ]]; then
      echo "❌ $(echo "$f" | sed "s|$PROJECT_DIR/||"): $link → $(echo "$target" | sed "s|$PROJECT_DIR/||") not found"
      ERRORS=$((ERRORS+1))
    fi
  done < <(grep -oP '\]\(\K[^)]+\.md' "$f" 2>/dev/null || true)
done < <(find "$DOCS_DIR" -name "*.md" | sort)

if [[ $ERRORS -gt 0 ]]; then
  echo "❌ 총 $ERRORS개 broken link 발견"
  exit 1
fi

echo "✅ 모든 링크 유효"
exit 0
