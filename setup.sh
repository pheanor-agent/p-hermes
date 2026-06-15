#!/bin/bash
# setup.sh - p-hermes 자동 설치 스크립트
# 사용법: bash setup.sh [HERMES_HOME]
# 예: bash setup.sh ~/.hermes
set -euo pipefail

HERMES_HOME="${1:-$HOME/.hermes}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🚀 p-hermes 자동 설치 시작 ($HERMES_HOME)"

# 1. 5-Tier 디렉토리 구조 생성
echo "🏗️ 5-Tier 디렉토리 구조 생성..."
mkdir -p "$HERMES_HOME"/core/{scripts,skills}
mkdir -p "$HERMES_HOME"/runtime/{state,workspace}
mkdir -p "$HERMES_HOME"/interfaces/session
mkdir -p "$HERMES_HOME"/infra/{cron,backups}
mkdir -p "$HERMES_HOME"/release/{wiki,blog,slides}
mkdir -p "$HERMES_HOME"/knowledge/wiki/{system,dev,custom,knowledge}

# 2. 설정 파일 생성 (템플릿 복사)
echo "⚙️ 설정 파일 생성..."
if [[ ! -f "$HERMES_HOME/config.yaml" ]]; then
  cp "$SCRIPT_DIR/config.yaml.example" "$HERMES_HOME/config.yaml"
  echo "  ✅ config.yaml 생성됨 (수정 필요: [필수] 필드)"
else
  echo "  ⚠️ config.yaml 이미 존재 - 건너뛰기"
fi

if [[ ! -f "$HERMES_HOME/AGENTS.md" ]]; then
  cp "$SCRIPT_DIR/AGENTS.md.example" "$HERMES_HOME/AGENTS.md"
  echo "  ✅ AGENTS.md 생성됨"
else
  echo "  ⚠️ AGENTS.md 이미 존재 - 건너뛰기"
fi

# 3. 스크립트 배치
echo "📜 스크립트 배치..."
cp "$SCRIPT_DIR/core/scripts/"*.sh "$HERMES_HOME/core/scripts/ 2>/dev/null || true
chmod +x "$HERMES_HOME/core/scripts/"*.sh
echo "  ✅ 스크립트 배치 완료"

# 4. 스킬 배치
echo "🧠 스킬 배치..."
cp -r "$SCRIPT_DIR/core/skills/"* "$HERMES_HOME/core/skills/ 2>/dev/null || true
echo "  ✅ 스킬 배치 완료"

# 5. Gateway 훅 배치
echo "🪝 Gateway 훅 배치..."
cp -r "$SCRIPT_DIR/hooks/"* "$HERMES_HOME/hooks/ 2>/dev/null || true
echo "  ✅ 훅 배치 완료"

# 6. 크론 레지스트리 초기화
echo "⏰ 크론 레지스트리 초기화..."
if [[ ! -f "$HERMES_HOME/infra/cron/registry.yaml" ]]; then
  cp "$SCRIPT_DIR/infra/cron/registry.yaml.example" "$HERMES_HOME/infra/cron/registry.yaml"
  echo "  ✅ registry.yaml 생성됨"
fi

# 7. 검증 스크립트 실행
echo "🔍 포팅 검증 실행..."
bash "$SCRIPT_DIR/verify.sh" "$HERMES_HOME"

echo ""
echo "🎉 설치 완료!"
echo "⚠️ 다음 단계를 진행하세요:"
echo "  1. $HERMES_HOME/config.yaml의 [필수] 필드를 수정하세요"
echo "  2. API 키를 환경변수에 설정하세요 (export HERMES_API_KEY=...)"
echo "  3. 'hermes start'로 에이전트를 시작하세요"
