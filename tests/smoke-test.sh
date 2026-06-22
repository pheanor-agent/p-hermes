#!/bin/bash
# smoke-test.sh — p-hermes 검증 (Smoke Test)
# 사용법: bash tests/smoke-test.sh [HERMES_HOME]
#   인자 없음: 저장소 자체 검증
#   경로 지정: 설치 환경 검증
set -euo pipefail

HERMES_HOME="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

check() {
  local name="$1"; shift
  if "$@" 2>/dev/null; then
    echo "  ✅ $name"; PASS=$((PASS+1))
  else
    echo "  ❌ $name"; FAIL=$((FAIL+1))
  fi
}

echo "🧪 p-hermes Smoke Test"
echo "━━━━━━━━━━━━━━━━━━━━"

# TC1: 디렉토리 구조 (설치 환경일 때만)
if [[ -n "$HERMES_HOME" && -d "$HERMES_HOME" ]]; then
  check "디렉토리 구조 (6개)" test -d "$HERMES_HOME/core/scripts" -a -d "$HERMES_HOME/runtime/state" -a -d "$HERMES_HOME/infra/cron" -a -d "$HERMES_HOME/release/wiki" -a -d "$HERMES_HOME/knowledge/wiki" -a -d "$HERMES_HOME/interfaces/session"
  check "스크립트 권한 (755)" bash -c "stat -c '%a' '$HERMES_HOME/core/scripts/create-job.sh' 2>/dev/null | grep -q 755"
fi

# TC3: 슬라이드 카운트
check "llms.txt 8 decks" grep -q '8 HTML decks' "$SCRIPT_DIR/llms.txt" 2>/dev/null

# TC4: Blog YAML title 필드
check "Blog YAML title" bash -c 'for f in '"$SCRIPT_DIR"'/docs/blog/posts/*.md; do grep -q "^title:" "$f" 2>/dev/null || exit 1; done'

# TC5: Examples 구조 (result.md 존재)
check "Examples 5개 result.md" bash -c 'for d in design-review slide-generation blog-creation knowledge-management project-management; do test -f "'"$SCRIPT_DIR"'/examples/$d/result.md" || exit 1; done'

# TC6: core/scripts/model-roles.sh
check "model-roles.sh 존재" test -f "$SCRIPT_DIR/core/scripts/model-roles.sh"

# TC7: README 필수 섹션
check "README Hero 태그라인" grep -q 'Persistent AI Agent Framework' "$SCRIPT_DIR/README.md" 2>/dev/null

# TC8: why-hermes 슬라이드 존재
check "why-hermes.html 존재" test -f "$SCRIPT_DIR/docs/slides/decks/why-hermes.html"

echo "━━━━━━━━━━━━━━━━━━━━"
echo "📊 결과: $PASS 통과, $FAIL 실패"
exit $FAIL
