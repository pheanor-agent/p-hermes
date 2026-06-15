#!/usr/bin/env bash
# review-status.sh — 리뷰 상태 확인 함수

get_review_status() {
    local job_dir="$1"
    for f in "$job_dir"/review-result-*.md; do
        if [[ -f "$f" ]]; then
            if grep -q "\[STATUS: PASS\]" "$f" 2>/dev/null; then
                echo "PASS"
                return 0
            elif grep -q "\[STATUS: FAIL\]" "$f" 2>/dev/null; then
                echo "FAIL"
                return 1
            elif grep -q "\[STATUS: REV\]" "$f" 2>/dev/null; then
                echo "REV"
                return 1
            fi
        fi
    done
    echo "NONE"
    return 1
}

get_exec_review_status() {
    local job_dir="$1"
    local exec_review="$job_dir/exec-review-result.md"
    if [[ -f "$exec_review" ]]; then
        if grep -q "\[STATUS: PASS\]" "$exec_review" 2>/dev/null; then
            echo "PASS"
            return 0
        elif grep -q "\[STATUS: FAIL\]" "$exec_review" 2>/dev/null; then
            echo "FAIL"
            return 1
        fi
    fi
    echo "NONE"
    return 1
}

has_self_review() {
    local job_dir="$1"
    [[ -f "$job_dir/review-result-self.md" ]]
}

review_status_has_pass() {
    local job_dir="$1"
    local status
    status=$(get_review_status "$job_dir")
    [[ "$status" == "PASS" ]]
}

has_pending_approval_text() {
    local job_dir="$1"
    local request="$job_dir/request.md"
    if [[ -f "$request" ]]; then
        grep -q "승인 요청" "$request" 2>/dev/null
        return $?
    fi
    return 1
}

has_approval_json() {
    local job_dir="$1"
    [[ -f "$job_dir/approval.json" ]]
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

check_approval() {
    local job_dir="$1"
    if [[ -f "$job_dir/approval.json" ]]; then
        python3 -c "
import json
approval = json.load(open('$job_dir/approval.json'))
option = approval.get('option', '')
exit(0 if option in ('A', 'B', 'C') else 1)
" 2>/dev/null
        return $?
    fi
    return 1
}

# 파일 직접 확인
file_has_pass() {
    local file="${1:-}"
    if [[ -f "$file" ]]; then
        grep -q "\[STATUS: PASS\]" "$file" 2>/dev/null
        return $?
    fi
    return 1
}
