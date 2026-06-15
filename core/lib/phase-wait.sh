#!/bin/bash
# phase-wait.sh — phase 완료 대기
HERMES_ROOT="${HERMES_ROOT:-$HOME/.hermes}"
# 사용: source $HERMES_ROOT/core/scripts/lib/phase-wait.sh; wait_for_phase "verify" 3600

wait_for_phase() {
  local phase=$1
  local timeout=$2
  local today=$(date +%Y%m%d)
  local lockfile="$HERMES_ROOT/.${phase}-done.*.${today}"
  
  log_info "Waiting for ${phase} phase (timeout: ${timeout}s)"
  
  # 타임아웃까지 대기 (30초 간격)
  local elapsed=0
  while [[ $elapsed -lt $timeout ]]; do
    if ls $lockfile &>/dev/null; then
      log_info "${phase} phase completed"
      return 0  # 완료
    fi
    sleep 30
    elapsed=$((elapsed + 30))
  done
  
  # 타임아웃: 이전 날 lock file 무시하고 진행
  log_warn "${phase} phase timeout (${timeout}s) - proceeding anyway"
  return 1
}
