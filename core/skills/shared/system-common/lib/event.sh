#!/bin/bash
# system-common/lib/event.sh
# POSIX 원자성 기반 무락 이벤트 버스
#
# 사용법:
#   source ~/.hermes/skills/shared/system-common/lib/event.sh
#   emit_event "job.completed" "HERMES-20260613-A7B9" '{"job_id": "JOB-1620"}'
#   claim_event "knowledge" "HERMES-20260613-A7B9.job.completed.json"
#
# 환경변수 (선택):
#   HERMES_EVENTS_DIR    - 이벤트 버스 루트 디렉토리 (기본: ~/.hermes/events)
#   HERMES_LOCK_TTL_MIN  - 워커 락 TTL (분, 기본: 30)

EVENTS_DIR="${HERMES_EVENTS_DIR:-$HOME/.hermes/events}"
BUS_DIR="${EVENTS_DIR}/bus"
WORKERS_DIR="${EVENTS_DIR}/workers"

# 워커 락 TTL (분) - 환경변수로 구성 가능 (JOB-1621)
LOCK_TTL_MIN="${HERMES_LOCK_TTL_MIN:-30}"

# 원자적 이벤트 발행 (Publish)
# mv -n은 POSIX 규격상 동일 파일 시스템 내 원자적 연산
# cross-filesystem 시 tmp → bus/로 복사 후 삭제 폴백 (JOB-1621)
emit_event() {
    local event_type="$1"
    local correlation_id="$2"
    local payload="$3"

    if [[ -z "$event_type" || -z "$correlation_id" ]]; then
        echo "[ERROR] emit_event: event_type와 correlation_id 필수" >&2
        return 1
    fi

    mkdir -p "$BUS_DIR"

    local tmp_file="/tmp/evt_${correlation_id}.json"
    local dest_file="${BUS_DIR}/${correlation_id}.${event_type}.json"

    cat <<EOF > "$tmp_file"
{
  "correlation_id": "${correlation_id}",
  "event_type": "${event_type}",
  "timestamp": "$(date -Iseconds)",
  "payload": ${payload:-{}}
}
EOF

    # 1차: mv -n 원자적 연산 (동일 파일 시스템 내)
    if mv -n "$tmp_file" "$dest_file" 2>/dev/null; then
        return 0
    else
        # 2차: 동일 파일 시스템 확인 후 폴백
        local src_dev=$(stat -c %d "$tmp_file" 2>/dev/null || echo "unknown")
        local dst_dev=$(stat -c %d "$(dirname "$dest_file")" 2>/dev/null || echo "unknown")

        if [[ "$src_dev" == "$dst_dev" ]]; then
            # 동일 FS: install -b (원자적 복사)
            if install -b "$tmp_file" "$dest_file" 2>/dev/null; then
                return 0
            fi
        fi

        # 3차: cross-filesystem 폴백 (복사 후 삭제)
        # 원자성은 보장 못하지만 cross-FS 시 유일한 옵션
        echo "[WARN] cross-FS fallback used for emit_event (non-atomic)" >&2
        if cp "$tmp_file" "$dest_file.tmp" 2>/dev/null && mv "$dest_file.tmp" "$dest_file" 2>/dev/null; then
            rm -f "$tmp_file"
            return 0
        fi

        echo "[ERROR] emit_event: 이벤트 발행 실패 (${dest_file})" >&2
        rm -f "$tmp_file" "$dest_file.tmp"
        return 1
    fi
}

# 원자적 경쟁 획득 (Subscribe & Claim)
# 커널 레벨 mkdir은 동시 요청 시 단 하나만 성공 보장
claim_event() {
    local worker_name="$1"
    local event_file="$2"

    local lock_dir="${WORKERS_DIR}/${worker_name}/${event_file}.lock"

    if mkdir "$lock_dir" 2>/dev/null; then
        return 0  # 락 획득 성공
    else
        return 1  # 경쟁 탈락
    fi
}

# 워커 락 해제
release_lock() {
    local worker_name="$1"
    local event_file="$2"
    local lock_dir="${WORKERS_DIR}/${worker_name}/${event_file}.lock"
    rmdir "$lock_dir" 2>/dev/null
}

# 이벤트 처리 완료 (아카이브 이동)
archive_event() {
    local worker_name="$1"
    local event_file="$2"
    local archive_dir="${EVENTS_DIR}/archive"
    mkdir -p "$archive_dir"
    mv "${BUS_DIR}/${event_file}" "${archive_dir}/" 2>/dev/null
    release_lock "$worker_name" "$event_file"
}

# 워커 타이머 (TTL 초과 락 정리) - TTL은 LOCK_TTL_MIN 환경변수 구성 가능 (JOB-1621)
cleanup_stale_locks() {
    find "${WORKERS_DIR}" -mindepth 2 -maxdepth 2 -type d -mmin +"${LOCK_TTL_MIN}" -exec rmdir {} \; 2>/dev/null
}

# 대기 중인 이벤트 목록 반환
pending_events() {
    ls "${BUS_DIR}"/ 2>/dev/null
}
