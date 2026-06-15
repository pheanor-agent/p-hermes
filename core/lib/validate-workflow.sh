#!/bin/bash
# validate-workflow.sh — 워크플로우 검증 공통 함수
# 사용: source lib/validate-workflow.sh

# 필수 문서 검증
validate_required_docs() {
  local job_dir="$1"
  local stage="$2"  # complete|transition
  local missing=()
  
  if [[ "$stage" == "complete" ]]; then
    [[ -f "$job_dir/result.md" ]] || missing+=("result.md")
    
    local is_simplified=false
    if [[ -f "$job_dir/architecture.md" ]]; then
      grep -qi "(간소화)" "$job_dir/architecture.md" 2>/dev/null && is_simplified=true
    fi
    if [[ "$is_simplified" == "false" && ! -f "$job_dir/approval.json" ]]; then
      missing+=("approval.json")
    fi
  fi
  
  local step
  step=$(jq -r '.currentStep // ""' "$job_dir/.workflow-state" 2>/dev/null || echo "")
  case "$step" in
    design)
      if [[ ! -f "$job_dir/design.md" && ! -f "$job_dir/architecture.md" ]]; then
        missing+=("design.md")
      fi
      ;;
    execution)
      [[ -f "$job_dir/approval.json" ]] || missing+=("approval.json")
      ;;
  esac
  
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "⛔ 누락된 필수 문서: ${missing[*]}"
    return 1
  fi
  
  return 0
}

# 리뷰 결과 파싱
parse_review_result() {
  local file="$1"
  local status=""
  
  status=$(grep -oiE '\[STATUS:\s*(PASS|FAIL|REV)\]' "$file" 2>/dev/null \
    | grep -oiE '(PASS|FAIL|REV)' \
    | head -1) || true
  
  if [[ -z "$status" ]]; then
    if grep -qiE '(PASS|승인|적절|통과)' "$file" 2>/dev/null; then
      status="PASS"
    elif grep -qiE '(FAIL|거절|불적절|실패)' "$file" 2>/dev/null; then
      status="FAIL"
    else
      status="REV"
    fi
  fi
  
  echo "$status"
}
