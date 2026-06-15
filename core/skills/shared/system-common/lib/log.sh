#!/bin/bash
# system-common/lib/log.sh
# 분산 추적용 통일 로그 매크로
#
# 사용법:
#   source ~/.hermes/skills/shared/system-common/lib/log.sh
#   log_init
#   log_info "작업 시작"
#   log_error "실패 메시지"

LOG_DIR="${HERMES_LOG_DIR:-$HOME/.hermes/logs}"
LOG_FILE="${LOG_DIR}/system.log"

# 추적 ID 초기화
log_init() {
    export CORRELATION_ID="${CORRELATION_ID:-HERMES-$(date +%Y%m%d-%H%M)-$$}"
    mkdir -p "$LOG_DIR"
}

# 일반 정보 로그
log_info() {
    local message="$1"
    echo "[$(date -Iseconds)] [INFO] [${CORRELATION_ID}] $message" >> "$LOG_FILE"
}

# 경고 로그
log_warn() {
    local message="$1"
    echo "[$(date -Iseconds)] [WARN] [${CORRELATION_ID}] $message" >> "$LOG_FILE"
}

# 오류 로그
log_error() {
    local message="$1"
    echo "[$(date -Iseconds)] [ERROR] [${CORRELATION_ID}] $message" >> "$LOG_FILE"
}

# 디버그 로그
log_debug() {
    local message="$1"
    if [[ "${HERMES_DEBUG:-0}" == "1" ]]; then
        echo "[$(date -Iseconds)] [DEBUG] [${CORRELATION_ID}] $message" >> "$LOG_FILE"
    fi
}

# 현재 추적 ID 출력
log_correlation() {
    echo "${CORRELATION_ID}"
}
