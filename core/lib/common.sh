#!/usr/bin/env bash
# common.sh — 워크플로우 공통 함수

# 반환 코드
EXIT_SUCCESS=0
EXIT_ERROR=1
EXIT_PASS=0
EXIT_FAIL=1
EXIT_FAIL=1

# 색상
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# JOB_DIR 존재 확인
require_job_dir() {
    local job_dir="$1"
    if [[ ! -d "$job_dir" ]]; then
        echo -e "${RED}[ERROR] JOB_DIR 없음: $job_dir${NC}" >&2
        return $EXIT_ERROR
    fi
    return $EXIT_SUCCESS
}

# .workflow-state 읽기 (currentStep 반환)
read_workflow_state() {
    local state_file="$1"
    if [[ ! -f "$state_file" ]]; then
        echo ""
        return $EXIT_ERROR
    fi
    # python3로 JSON 파싱
    python3 -c "
import json, sys
try:
    state = json.load(open('$state_file'))
    print(state.get('currentStep', ''))
except:
    print('')
" 2>/dev/null
}

# .workflow-state 쓰기
write_workflow_state() {
    local state_file="$1"
    local current_step="$2"
    local status="$3"
    
    python3 -c "
import json
from datetime import datetime, timezone, timedelta

KST = timezone(timedelta(hours=9))
now = datetime.now(KST).isoformat()

state_file = '$state_file'
current_step = '$current_step'
status = '$status'

if Path(state_file).exists():
    state = json.load(open(state_file))
else:
    state = {'steps': []}

state['currentStep'] = current_step
state['status'] = status
state['updatedAt'] = now

# steps 업데이트
step_map = {
    'request': 0, '2-investigating': 1, '3-designing': 2,
    '4-reviewing': 3, '5-approved': 4, '6-executing': 5,
    '7-testing': 6, '8-exec-review': 7, '9-done': 8,
    '9-cancelled': 8, '9-superseded': 8
}
idx = step_map.get(current_step, 0)
for i, step in enumerate(state.get('steps', [])):
    if i <= idx:
        step['status'] = 'done'
        if 'completedAt' not in step:
            step['completedAt'] = now
    else:
        step['status'] = 'pending'

json.dump(state, open(state_file, 'w'), indent=2, ensure_ascii=False)
" 2>/dev/null
}

# 상태 -> 단계 번호 변환
step_to_number() {
    local step="$1"
    case "$step" in
        request) echo 1 ;;
        2-investigating) echo 2 ;;
        3-designing) echo 3 ;;
        4-reviewing) echo 4 ;;
        5-approved) echo 5 ;;
        6-executing) echo 6 ;;
        7-testing) echo 7 ;;
        8-exec-review) echo 8 ;;
        9-done|9-cancelled|9-superseded) echo 9 ;;
        *) echo 0 ;;
    esac
}

# .workflow-state 업데이트
update_workflow_state() {
    local state_file="${1:-}"
    local current_step="${2:-}"
    local status="${3:-running}"
    
    if [[ -z "$state_file" ]]; then
        echo "[ERROR] state_file 없음" >&2
        return $EXIT_ERROR
    fi
    
    python3 -c "
import json
from datetime import datetime, timezone, timedelta

KST = timezone(timedelta(hours=9))
now = datetime.now(KST).isoformat()

state_file = '$state_file'
current_step = '$current_step'
status = '$status'

state = json.load(open(state_file))
state['currentStep'] = current_step
state['status'] = status
state['updatedAt'] = now

step_map = {
    'request': 0, '2-investigating': 1, '3-designing': 2,
    '4-reviewing': 3, '5-approved': 4, '6-executing': 5,
    '7-testing': 6, '8-exec-review': 7, '9-done': 8,
    '9-cancelled': 8, '9-superseded': 8
}
idx = step_map.get(current_step, 0)
for i, step in enumerate(state.get('steps', [])):
    if i <= idx:
        step['status'] = 'done'
        if 'completedAt' not in step:
            step['completedAt'] = now
    else:
        step['status'] = 'pending'

json.dump(state, open(state_file, 'w'), indent=2, ensure_ascii=False)
" 2>/dev/null
}
