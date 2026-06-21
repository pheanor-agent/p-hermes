#!/bin/bash
# deploy.sh - p-hermes 전체 배포 (문서 + 코드 + SDD 2.0 Living Spec Pipeline)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.." # Go to project root

echo "🚀 p-hermes SDD 2.0 배포 파이프라인 시작"

# SDD 스크립트 경로 (저장소 내 scripts/sdd/에 위치)
SDD_DIR="scripts/sdd"

# 조건부 SDD 실행: scripts/sdd/ 디렉토리가 없으면 건너뜀
if [[ -d "$SDD_DIR" ]]; then
  # 1. [SDD 2.0] Dynamic Injection (런타임 데이터 주입)
  echo "  🔄 데이터 주입 (Dynamic Injection)..."
  python3 "$SDD_DIR/sdd-inject.py" || { echo "❌ 데이터 주입 실패"; exit 1; }

  # 2. [SDD 2.0] Structure Linter (구조 적합성 검사)
  echo "  🏗️ 구조 적합성 검사 (Structure Linter)..."
  python3 "$SDD_DIR/sdd-lint.py" || { echo "❌ 구조 검사 실패"; exit 1; }

  # 3. [SDD 2.0] Full-Graph Validator (링크 무결성 검증)
  echo "  🔗 링크 무결성 검증 (Full-Graph Validator)..."
  python3 "$SDD_DIR/sdd-validate.py" || { echo "❌ 링크 검증 실패"; exit 1; }
else
  echo "  ⚠️ SDD 스크립트 디렉토리($SDD_DIR)가 없어 SDD 단계를 건너뜁니다."
fi

# 3.1 중국어 문자 검증
echo "  🔍 중국어 문자 검증..."
bash tests/validate-chinese.sh docs/ || { echo "❌ 중국어 문자 발견"; exit 1; }

# 4. llms.txt 재생성
echo "  📄 llms.txt 재생성..."
bash scripts/generate-llms.sh || { echo "❌ llms.txt 생성 실패"; exit 1; }

# 5. Git commit & push
echo "  📝 Git commit & push..."
git add -A
git commit -m "deploy: SDD 2.0 synthesized package"
git push origin main

echo "✅ SDD 2.0 배포 완료"
