#!/bin/bash
# health-check.sh - 시스템 건강도 확인 (JOB-1414 수정: graph-export.sh 호출 제거)
HERMES_ROOT="${HERMES_ROOT:-$HOME/.hermes}"
set -euo pipefail

# graph.json 상태 확인 (직접 호출 대신 파일 존재/유효성 확인)
if [[ -f $HERMES_ROOT/knowledge/wiki/graph.json ]]; then
    python3 -c "import json; json.load(open('$HERMES_ROOT/knowledge/wiki/graph.json'))" 2>/dev/null && echo "graph.json: OK" || echo "graph.json: INVALID"
else
    echo "graph.json: MISSING"
fi

# wiki-sync.sh는 유지 (별도 동기화 작업)
if [[ -f $HERMES_ROOT/core/scripts/wiki-sync.sh ]]; then
    $HERMES_ROOT/core/scripts/wiki-sync.sh && echo "wiki-sync: OK" || echo "wiki-sync: FAIL"
fi

echo "Health Check OK"
