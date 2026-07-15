#!/bin/bash
# validate-links.sh — p-hermes 전역 markdown 링크 검증
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 검증 대상 디렉토리 및 파일 정의 (SPEC-D01 반영)
# NOTE: archive/, playground/는 SPEC-D01 3-트랙 외부이므로 링크 검증 제외 (JOB-1733)
TARGETS=(
  "$PROJECT_DIR/docs/wiki"
  "$PROJECT_DIR/docs/blog"
  "$PROJECT_DIR/docs/slides"
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
      # 로컬 시스템 경로(~/.hermes/)는 검증 제외
      [[ "$link" == \~* ]] && continue
      
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

# ====== playground 링크 검증 (HTML + markdown) ======
PLAYGROUND_DIR="$PROJECT_DIR/docs/playground"
if [[ -d "$PLAYGROUND_DIR" ]]; then
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue

    # [R1] HTML href="#" 플레이스홀더 감지 (JOB-2064) - WARNING only
    while IFS= read -r match; do
      [[ -z "$match" ]] && continue
      echo "⚠️  PLACEHOLDER: $f -> # (link not configured)"
    done < <(grep -oP 'href="#"' "$f" 2>/dev/null || true)

    # [R1a] HTML href="./..." 링크 검증 (쿼리스트링 제거)
    while IFS= read -r link; do
      [[ -z "$link" ]] && continue
      target="${link#href=\"}"
      # 쿼리스트링(?v=8.2 등) 제거 후 파일 존재 확인
      target_noqs="${target%%\?*}"
      full="$(dirname "$f")/$target_noqs"
      [[ -e "$full" ]] || { echo "BROKEN: $f -> $target"; ERRORS=$((ERRORS+1)); }
    done < <(grep -oP 'href="\./[^\\"]+' "$f" 2>/dev/null || true)

    # [R2] HTML 상대 경로 링크 검증 (lectures/, archive/, ops/ 등) (JOB-2064)
    # NOTE: ./ 접두사 링크는 [R1a]에서 처리 (쿼리스트링 포함) — R2에서 제외
    while IFS= read -r link; do
      [[ -z "$link" ]] && continue
      # Remove href=" prefix and trailing quote
      target=$(echo "$link" | sed 's/^href="//;s/"$//')
      # ./ 로 시작하는 링크는 R1a에서 처리
      [[ "$target" == ./* ]] && continue
      # CSS/JS/font/CDN 링크 제외 (쿼리스트링 제거 후 확인)
      target_noqs="${target%%\?*}"
      [[ "$target_noqs" == *.css ]] && continue
      [[ "$target_noqs" == *.js ]] && continue
      [[ "$target" == https* ]] && continue
      [[ "$target" == http* ]] && continue
      full="$(dirname "$f")/$target"
      [[ -e "$full" ]] || { echo "BROKEN: $f -> $target"; ERRORS=$((ERRORS+1)); }
    done < <(grep -oP 'href="[^#/][^"]*"' "$f" 2>/dev/null || true)

    # markdown [](./...) 링크 검증
    while IFS= read -r link; do
      [[ -z "$link" ]] && continue
      [[ "$link" == http* ]] && continue
      [[ "$link" == \#* ]] && continue
      [[ "$link" == \~* ]] && continue
      full="$(dirname "$f")/$link"
      [[ -e "$full" ]] || [[ -d "$full" ]] || { echo "BROKEN: $f -> $link"; ERRORS=$((ERRORS+1)); }
    done < <(grep -oP '\]\(\K\./[^)]+' "$f" 2>/dev/null || true)
  done < <(find "$PLAYGROUND_DIR" -name "*.html" -o -name "*.md" | grep -v '/archive/' | grep -v '/ops/' | sort)

  if [[ $ERRORS -gt 0 ]]; then
    echo "❌ 총 $ERRORS개 broken link 발견 (playground 포함)"
    exit 1
  fi
  echo "✅ playground 링크 유효"
fi

echo "✅ 모든 링크 유효"
exit 0
