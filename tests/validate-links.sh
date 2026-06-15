#!/bin/bash
# validate-links.sh — p-hermes 전역 markdown 링크 검증
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 검증 대상 디렉토리 및 파일 정의 (SPEC-D01 반영)
TARGETS=(
  "$PROJECT_DIR/wiki"
  "$PROJECT_DIR/blog"
  "$PROJECT_DIR/slides"
  "$PROJECT_DIR/README.md"
  "$PROJECT_DIR/ARCHITECTURE.md"
)

ERRORS=0

# 대상별 루프
for target in "${TARGETS[@]}"; do
  if [[ ! -e "$target" ]]; then
    echo "⚠️ Target not found: $target (skipping)"
    continue
  fi

  # 파일 목록 생성 (디렉토리면 하위 .md 검색, 파일이면 해당 파일만)
  if [[ -d "$target" ]]; then
    FILES=$(find "$target" -name "*.md" | sort)
  else
    FILES="$target"
  fi

  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    while IFS= read -r link; do
      [[ "$link" == http* ]] && continue
      # 링크가 앵커(#)만 있는 경우 제외
      [[ "$link" == \#* ]] && continue
      
      base=$(dirname "$f")
      # 경로 계산 및 실존 확인
      target_path=$(cd "$base" && realpath -m "$link" 2>/dev/null || echo "$base/$link")
      
      if [[ ! -f "$target_path" ]]; then
        echo "❌ $(echo "$f" | sed "s|$PROJECT_DIR/||"): $link → $(echo "$target_path" | sed "s|$PROJECT_DIR/||") not found"
        ERRORS=$((ERRORS+1))
      fi
    done < <(grep -oP '\]\(\K[^)]+\.md' "$f" 2>/dev/null || true)
  done <<< "$FILES"
done

if [[ $ERRORS -gt 0 ]]; then
  echo "❌ 총 $ERRORS개 broken link 발견"
  exit 1
fi

echo "✅ 모든 링크 유효"
exit 0
