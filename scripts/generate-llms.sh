#!/bin/bash
# generate-llms.sh — LLM 문서 탐색 진입점 생성
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DOCS_DIR="$PROJECT_DIR/docs"

# llms.txt — 간략 요약
cat > "$PROJECT_DIR/llms.txt" << 'EOF'
# p-hermes Documentation

Hermes Agent system documentation, published via GitHub Pages.

## Entry Point
- README.md — Single entry point for 3-track docs
- Full file index: llms-full.txt

## 3-Track Structure
- docs/wiki/ — Guide Wiki (How-to) — 14 files
- docs/blog/ — Dev Blog (Why) — 8 posts
- docs/slides/ — Concept Slides (What) — 8 HTML decks

## Deploy
bash src/deploy.sh
EOF

# llms-full.txt — 전체 파일 목록 + 요약
{
  echo "# p-hermes Full Documentation Index"
  echo ""
  echo "## Files"
  find "$DOCS_DIR" -name "*.md" -not -path "*/playground/*" | sort | while read -r f; do
    rel=$(echo "$f" | sed "s|$PROJECT_DIR/||")
    lines=$(wc -l < "$f")
    title=$(grep -m1 '^#' "$f" 2>/dev/null | sed 's/^#\{1,3\} *//' || echo "(no heading)")
    echo "- **$rel** ($lines lines): $title"
  done
} > "$PROJECT_DIR/llms-full.txt"

echo "✅ llms.txt + llms-full.txt 생성"
