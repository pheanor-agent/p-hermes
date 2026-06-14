#!/bin/bash
# deploy.sh — docs/ 검증 후 GitHub Pages 배포
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

echo "📦 p-hermes 배포 시작"

# 1. 링크 검증
echo "  🔍 링크 검증..."
bash tests/validate-links.sh || { echo "❌ 검증 실패 — 배포 중단"; exit 1; }

# 2. llms.txt 재생성
echo "  📄 llms.txt 재생성..."
bash scripts/generate-llms.sh

# 3. Git commit + push
echo "  📝 Git commit..."
git add docs/ llms.txt llms-full.txt
git commit -m "docs: $(date +%Y-%m-%d\ %H:%M)" || { echo "✅ 변경사항 없음 — skip"; exit 0; }

echo "  🚀 Git push..."
git push origin main

echo "✅ 배포 완료 (GitHub Pages 1-2분 내 반영)"
