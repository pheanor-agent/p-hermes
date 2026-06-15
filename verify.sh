#!/bin/bash
# verify.sh - p-hermes 포팅 검증 스크립트
# 사용법: bash verify.sh [HERMES_HOME]
set -euo pipefail

HERMES_HOME="${1:-$HOME/.hermes}"
ERRORS=0

echo "=== p-hermes 포팅 검증 ==="
echo "대상: $HERMES_HOME"
echo ""

# 1. 필수 파일 존재 확인
echo "📄 필수 파일 확인..."
for f in config.yaml AGENTS.md; do
  if [[ -f "$HERMES_HOME/$f" ]]; then
    echo "  ✅ 존재: $f"
  else
    echo "  ❌ 누락: $f"
    ERRORS=$((ERRORS+1))
  fi
done

# 2. 5-Tier 구조 확인
echo ""
echo "🏗️ 5-Tier 구조 확인..."
for d in core runtime interfaces infra release; do
  if [[ -d "$HERMES_HOME/$d" ]]; then
    echo "  ✅ 존재: $d/"
  else
    echo "  ❌ 누락: $d/"
    ERRORS=$((ERRORS+1))
  fi
done

# 3. 핵심 스크립트 확인
echo ""
echo "📜 핵심 스크립트 확인..."
for s in workflow-gate.sh create-job.sh atomic_write.sh; do
  if [[ -f "$HERMES_HOME/core/scripts/$s" ]]; then
    echo "  ✅ 존재: $s"
  else
    echo "  ❌ 누락: $s"
    ERRORS=$((ERRORS+1))
  fi
done

# 4. 스킬 확인
echo ""
echo "🧠 스킬 확인..."
SKILL_COUNT=$(find "$HERMES_HOME/core/skills" -name "SKILL.md" 2>/dev/null | wc -l)
if [[ $SKILL_COUNT -gt 0 ]]; then
  echo "  ✅ 스킬: $SKILL_COUNT개"
else
  echo "  ❌ 스킬: 0개"
  ERRORS=$((ERRORS+1))
fi

# 5. 설정 유효성 검사 (YAML 구문)
echo ""
echo "⚙️ 설정 유효성 검사..."
if python3 -c "import yaml; yaml.safe_load(open('$HERMES_HOME/config.yaml'))" 2>/dev/null; then
  echo "  ✅ config.yaml 구문 검사: PASS"
else
  echo "  ⚠️ config.yaml 구문 검사: 실패 (템플릿 상태일 수 있음)"
fi

# 6. 결과 요약
echo ""
echo "=== 검증 완료 ==="
if [[ $ERRORS -eq 0 ]]; then
  echo "✅ 모든 필수 파일 존재 - 포팅 성공!"
  exit 0
else
  echo "❌ $ERRORS개 오류 발견 - 포팅 실패"
  exit 1
fi
