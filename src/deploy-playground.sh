#!/bin/bash
# deploy-playground.sh — Playground 전용 배포 (playground/ 범위만 커밋)
# playground 외 파일은 절대 포함하지 않음
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."  # Go to project root

echo "🎪 p-hermes Playground 전용 배포 시작"

# 1. Playground 변경사항만 스테이지
echo "  📦 Playground 변경사항 스테이지..."
git add docs/playground/

# 2. 변경 범위 확인 (playground 외 포함 여부 검증)
STAGED_FILES=$(git diff --cached --name-only)
NON_PLAYGROUND=$(echo "$STAGED_FILES" | grep -v "\^docs/playground/" || true)
if [[ -n "$NON_PLAYGROUND" ]]; then
  echo "❌ playground 외 파일이 포함되었습니다:"
  echo "$NON_PLAYGROUND"
  echo "   deploy-playground.sh은 playground/만 배포합니다."
  exit 1
fi

# 3. 슬라이드 검증 (존재 시)
if [[ -f tests/validate-slides.py ]]; then
  echo "  📝 슬라이드 검증..."
  python3 tests/validate-slides.py || { echo "❌ 슬라이드 검증 실패"; exit 1; }
fi

# 4. 중국어 문자 검증 (존재 시)
if [[ -f tests/validate-chinese.sh ]]; then
  echo "  🔍 중국어 문자 검증..."
  bash tests/validate-chinese.sh docs/playground/ || { echo "❌ 중국어 문자 발견"; exit 1; }
fi

# 5. [R4] 링크 검증 (JOB-2064)
echo "  🔗 링크 검증..."
bash tests/validate-links.sh || { echo "❌ 링크 검증 실패"; exit 1; }

# 6. [R4] 인덱스 데이터 검증 (JOB-2064)
echo "  📋 인덱스 검증..."
python3 tests/validate-playground-index.py || { echo "❌ 인덱스 검증 실패"; exit 1; }

# 7. Git commit and push (playground만)
echo "  📝 Git commit and push..."
git commit -m "playground: deploy update"
git push origin main

echo "✅ Playground 배포 완료"
