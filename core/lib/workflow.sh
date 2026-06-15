#!/usr/bin/env bash
# workflow.sh — 워크플로우 검증 함수

# 단계별 필수 파일 확인
check_step_requirements() {
    local job_dir="$1"
    local step="$2"
    
    case "$step" in
        1) [[ -f "$job_dir/request.md" ]] ;;
        2) [[ -f "$job_dir/request.md" ]] ;;
        3) [[ -f "$job_dir/architecture.md" ]] ;;
        4) ls "$job_dir"/review-result-*.md >/dev/null 2>&1 ;;
        5) [[ -f "$job_dir/approval.json" ]] ;;
        6) [[ -f "$job_dir/execution.md" ]] || [[ -f "$job_dir/architecture.md" ]] ;;
        7) [[ -f "$job_dir/execution.md" ]] ;;
        8) [[ -f "$job_dir/exec-review-result.md" ]] || ls "$job_dir"/review-result-*.md >/dev/null 2>&1 ;;
        9) [[ -f "$job_dir/lessons.md" ]] || [[ -f "$job_dir/execution.md" ]] ;;
        *) return 0 ;;
    esac
}
