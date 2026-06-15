#!/usr/bin/env bash
# approval.sh — 승인 관련 함수

check_approval() {
    local job_dir="$1"
    local approval_file="$job_dir/approval.json"
    
    if [[ -f "$approval_file" ]]; then
        python3 -c "
import json
approval = json.load(open('$approval_file'))
option = approval.get('option', '')
if option in ('A', 'B', 'C'):
    exit(0)
else:
    exit(1)
" 2>/dev/null
        return $?
    fi
    return 1
}

get_approval_option() {
    local job_dir="$1"
    local approval_file="$job_dir/approval.json"
    
    if [[ -f "$approval_file" ]]; then
        python3 -c "
import json
approval = json.load(open('$approval_file'))
print(approval.get('option', ''))
" 2>/dev/null
    fi
}

# 유효한 승인 검증
require_valid_approval() {
    local job_dir="${1:-}"
    local approval_file="$job_dir/approval.json"
    
    if [[ ! -f "$approval_file" ]]; then
        echo "[ERROR] approval.json 없음" >&2
        return 1
    fi
    
    # option 확인
    python3 -c "
import json, sys
approval = json.load(open('$approval_file'))
option = approval.get('option', '')
approved_by = approval.get('approvedBy', '')
if option in ('A', 'B', 'C') and approved_by:
    sys.exit(0)
else:
    sys.exit(1)
" 2>/dev/null
    return $?
}
