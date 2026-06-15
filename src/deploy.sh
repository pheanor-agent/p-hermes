#!/bin/bash
# deploy.sh - p-hermes 전체 배포 (문서 + 코드)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "📦 p-hermes 전체 배포 시작"

# 1. 링크 검증 (문서)
echo "  🔍 링크 검증..."
bash tests/validate-links.sh || { echo "❌ 링크 검증 실패"; exit 1; }

# 2. llms.txt 재생성
echo "  📄 llms.txt 재생성..."
bash scripts/generate-llms.sh || { echo "❌ llms.txt 생성 실패"; exit 1; }

# 3. 포팅 검증
echo "  🔍 포팅 검증..."
bash verify.sh ~/.hermes || { echo "❌ 포팅 검증 실패"; exit 1; }

# 4. Git commit & push
echo "  📝 Git commit & push..."
git add -A
git commit -m "deploy: p-hermes full package update"
git push origin main

echo "✅ 배포 완료"
