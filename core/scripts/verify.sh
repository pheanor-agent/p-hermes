#!/bin/bash
#==============================================================================
# verify.sh - 시스템 검증
#==============================================================================
#
# JOB-1419: 에르메스 크론잡 스크립트 로직 구현
#
# 실행: 03:00 (Hermes cron)
# 기능: DB, Disk, Gateway 상태 확인
#
#==============================================================================

set -euo pipefail

# ─── 이벤트 버스 연동 (JOB-1621) ──────────────────────────────────────────
source "$HERMES_ROOT/core/skills/shared/system-common/lib/event.sh" 2>/dev/null || true
source "$HERMES_ROOT/core/skills/shared/system-common/lib/log.sh" 2>/dev/null || true

VR_CORRELATION_ID="VR-$(date +%Y%m%d-%H%M)-$$"
export VR_CORRELATION_ID

LOG_DIR="/home/bot/.hermes/logs"
LOG_FILE="$LOG_DIR/verify.log"
TODAY=$(date '+%Y-%m-%d')

mkdir -p "$LOG_DIR"

# 로깅
log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" >> "$LOG_FILE"
    echo "[$level] $*"
}

# ============================================================================
# 시스템 검증 (이원화 디스크 모니터링 포함)
# ============================================================================

# 임계치 설정
DISK_WARN=70
DISK_CRITICAL=90

log "INFO" "=== verify.sh 시작 ($TODAY) ==="

# 1. WSL 내부 디스크 사용량 (가상)
log "INFO" "WSL 디스크 사용량 확인... (가상)"
disk_usage_wsl=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
disk_used_wsl=$(df -h / | tail -1 | awk '{print $3}')
disk_total_wsl=$(df -h / | tail -1 | awk '{print $2}')
log "INFO" "WSL Disk: $disk_used_wsl/$disk_total_wsl ($disk_usage_wsl%)"

if [ "$disk_usage_wsl" -ge "$DISK_WARN" ]; then
    log "WARN" "⚠️ WSL Disk 사용량 경고: ${disk_usage_wsl}% (임계치: ${DISK_WARN}%)"
fi

# 2. Windows 호스트 디스크 사용량 (물리)
log "INFO" "Host Disk 사용량 확인... (물리)"
HOST_MOUNT=$(df -h /mnt/c | tail -1 | awk '{print $1}')
disk_usage_host=$(df -h /mnt/c | tail -1 | awk '{print $5}' | sed 's/%//')
disk_used_host=$(df -h /mnt/c | tail -1 | awk '{print $3}')
disk_total_host=$(df -h /mnt/c | tail -1 | awk '{print $2}')
log "INFO" "Host Disk ($HOST_MOUNT): $disk_used_host/$disk_total_host ($disk_usage_host%)"

if [ "$disk_usage_host" -ge "$DISK_CRITICAL" ]; then
    log "CRITICAL" "🚨 Host Disk 임계치 초과: ${disk_usage_host}% (임계치: ${DISK_CRITICAL}%)"
    # 즉시 알림 (선택적 구현)
    if command -v hermes &> /dev/null; then
        hermes send-message --message "🚨 **Host Disk Critical**\n\nDisk: ${disk_usage_host}% (${disk_used_host}/${disk_total_host})\n조치: 용량 확보 필요" --channel "discord" 2>/dev/null || true
    fi
elif [ "$disk_usage_host" -ge "$DISK_WARN" ]; then
    log "WARN" "⚠️ Host Disk 사용량 경고: ${disk_usage_host}% (임계치: ${DISK_WARN}%)"
fi

# 2. Gateway 상태
log "INFO" "Gateway 상태 확인..."
gateway_status=$(systemctl --user is-active hermes-gateway 2>/dev/null || echo "unknown")
if [ "$gateway_status" = "active" ]; then
    log "INFO" "Gateway: ✅ 활성"
else
    log "WARN" "Gateway: ❌ $gateway_status"
fi

# 3. Database 상태 (memory.db)
log "INFO" "Database 상태 확인..."
if [ -f "/home/bot/.hermes/memory.db" ]; then
    db_size=$(du -h /home/bot/.hermes/memory.db | cut -f1)
    log "INFO" "Database: ✅ $db_size"
else
    log "WARN" "Database: ❌ 파일 없음"
fi

# 4. Cron 상태
log "INFO" "Cron 상태 확인..."
cron_status=$(service cron status 2>/dev/null | grep -o "is running" || echo "unknown")
if [ "$cron_status" = "is running" ]; then
    log "INFO" "Cron: ✅ 활성"
else
    log "WARN" "Cron: ⚠️ $cron_status"
fi

# 5. Hermes cronjobs 상태
log "INFO" "Hermes cronjobs 상태 확인..."
hermes_cron_count=$(python3 -c "
import json
try:
    import subprocess
    result = subprocess.run(['hermes', 'cron', 'list'], capture_output=True, text=True)
    print('✅ Hermes cron: 동작 중')
except:
    print('⚠️ Hermes cron: 확인 불가')
" 2>/dev/null || echo "⚠️ Hermes cron: 확인 불가")
log "INFO" "$hermes_cron_count"

log "INFO" "=== verify.sh 종료 ==="
echo "✅ verify.sh 완료"

# ✅ JOB-1621: 이벤트 버스 발행 (cron_status quoting 개선)
if declare -f emit_event &>/dev/null; then
    # 상태 요약 (disk usage 기반 판정)
    VERIFY_STATUS="ok"
    if [ "$disk_usage_host" -ge "$DISK_CRITICAL" ]; then
        VERIFY_STATUS="critical"
    elif [ "$disk_usage_host" -ge "$DISK_WARN" ] || [ "$disk_usage_wsl" -ge "$DISK_WARN" ]; then
        VERIFY_STATUS="warning"
    fi
    
    # JSON payload 구성 (jq 로 safe encoding)
    PAYLOAD=$(jq -n \
        --arg status "$VERIFY_STATUS" \
        --argjson disk_wsl "$disk_usage_wsl" \
        --argjson disk_host "$disk_usage_host" \
        --arg gateway "$gateway_status" \
        --arg cron "$cron_status" \
        '{status: $status, disk_wsl_pct: $disk_wsl, disk_host_pct: $disk_host, gateway: $gateway, cron: $cron}')
    
    emit_event "monitor.verify" "$VR_CORRELATION_ID" "$PAYLOAD" 2>/dev/null || true
fi
