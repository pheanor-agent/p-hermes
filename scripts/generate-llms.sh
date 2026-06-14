#!/bin/bash
# generate-llms.sh — LLM 문서 탐색 진입점 생성
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DOCS_DIR="$PROJECT_DIR/docs"

# llms.txt — 간략 요약
cat > "$PROJECT_DIR/llms.txt" << 'EOF'
# p-hermes Documentation

This repository contains Hermes Agent system documentation, published via GitHub Pages.

## Quick Start
- Main index: docs/index.md
- Systems overview: docs/systems/overview.md
- Full docs: llms-full.txt

## Structure
- docs/systems/ — System documentation (6 systems)
- docs/workflow-pipeline.md — 9-step workflow
- docs/skill-system.md — 146+ skills

## Deploy
bash src/deploy.sh
EOF

# llms-full.txt — 전체 파일 목록 + 요약
{
  echo "# p-hermes Full Documentation Index"
  echo ""
  echo "## Files"
  find "$DOCS_DIR" -name "*.md" | sort | while read -r f; do
    rel=$(echo "$f" | sed "s|$PROJECT_DIR/||")
    lines=$(wc -l < "$f")
    title=$(grep -m1 '^#' "$f" | sed 's/^#\{1,3\} *//')
    echo "- **$rel** ($lines lines): $title"
  done
} > "$PROJECT_DIR/llms-full.txt"

echo "✅ llms.txt + llms-full.txt 생성"
