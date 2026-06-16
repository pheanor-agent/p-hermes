#!/bin/bash
# 표현력 시스템 메인 진입점
# 사용법: run.sh <domain> <intent> <content> [context.json]

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$HOME/.hermes/workspace/expression-system/output"

mkdir -p "$OUTPUT_DIR"

DOMAIN="${1:?Usage: run.sh <domain> <intent> <content> [context]}"
INTENT="${2:?Usage: run.sh <domain> <intent> <content> [context]}"
CONTENT="${3:?Usage: run.sh <domain> <intent> <content> [context]}"
CONTEXT="${4:-{}}"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 1. 모델 선택
echo "🔍 모델 선택: intent=$INTENT, domain=$DOMAIN"
MODEL_RESULT=$(python3 "$SKILL_DIR/models/scoring.py" "$INTENT" "$DOMAIN")
SELECTED_MODEL=$(echo "$MODEL_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['selected_model'])")
echo "✅ 선택된 모델: $SELECTED_MODEL"

# 2. 계층 구조 생성
echo "📐 계층 구조 생성..."
TIERS=$(echo "$CONTENT" | python3 "$SKILL_DIR/engine/tier-generator.py" "$DOMAIN" "default")

# 3. 어조 규칙 적용
echo "🎵 어조 규칙 적용..."
TONE=$(python3 "$SKILL_DIR/engine/tone-adapter.py" "$INTENT" "$DOMAIN")

# 4. 검증 (T1 + T2)
echo "🔒 검증 시작..."
VALIDATION=$(echo "$CONTENT" | python3 "$SKILL_DIR/engine/validator.py" "$DOMAIN" "$CONTEXT")

# 5. 결과 조합 (파일 경유로 JSON 안정화)
TMPDIR=$(mktemp -d)
echo "$TIERS" > "$TMPDIR/tiers.json"
echo "$TONE" > "$TMPDIR/tone.json"
echo "$VALIDATION" > "$TMPDIR/validation.json"
echo "$MODEL_RESULT" > "$TMPDIR/model.json"

RESULT=$(python3 -c "
import json

tiers = json.load(open('$TMPDIR/tiers.json'))
tone = json.load(open('$TMPDIR/tone.json'))
validation = json.load(open('$TMPDIR/validation.json'))
model = json.load(open('$TMPDIR/model.json'))

output = {
    'timestamp': '$TIMESTAMP',
    'domain': '$DOMAIN',
    'intent': '$INTENT',
    'model': model['selected_model'],
    'tiers': tiers,
    'tone': tone,
    'validation': validation,
    'status': 'success'
}
print(json.dumps(output, ensure_ascii=False, indent=2))
")

rm -rf "$TMPDIR"

# 6. 출력
echo "$RESULT"

# 7. 히스토리 기록
python3 -c "
import json
line = {'timestamp': '$TIMESTAMP', 'domain': '$DOMAIN', 'intent': '$INTENT', 'model': '$SELECTED_MODEL'}
print(json.dumps(line, ensure_ascii=False))
" >> "$OUTPUT_DIR/history.jsonl"

echo "✅ 완료. 히스토리에 기록됨."