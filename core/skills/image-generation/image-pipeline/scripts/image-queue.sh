#!/bin/bash
# image-queue.sh — 이미지 생성 큐 관리 스크립트 (v3)
# JOB-963: queue.json 단일 진실 원천, flock 기반 동시성 제어
set -euo pipefail

QUEUE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
QUEUE_FILE="$QUEUE_DIR/queue.json"
LOCK_FILE="$QUEUE_DIR/queue.lock"
BACKUP_DIR="$QUEUE_DIR/backups"
LOCK_TIMEOUT=60  # seconds to wait for flock
LOGIC_LOCK_TIMEOUT=3600  # 60 minutes for logic lock (queue.json.lock)

# ─── 헬퍼 함수 ───

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2; }

die() { log "ERROR: $*"; exit 1; }

ensure_queue_file() {
  if [ ! -f "$QUEUE_FILE" ]; then
    cat > "$QUEUE_FILE" <<'INIT'
{
  "version": 1,
  "lock": { "locked": false, "lockedBy": null, "lockedAt": null },
  "limits": { "global": { "dailyLimit": 50 } },
  "entries": [],
  "completed": [],
  "failed_archive": [],
  "stats": { "today": { "date": "", "global": 0, "projects": {} } }
}
INIT
    log "Created new queue.json"
  fi
}

# Backup before write
backup_queue() {
  local ts=$(date '+%Y%m%d-%H%M%S')
  mkdir -p "$BACKUP_DIR"
  cp "$QUEUE_FILE" "$BACKUP_DIR/queue-${ts}.json" 2>/dev/null || true
  # Keep last 10 backups
  ls -t "$BACKUP_DIR"/queue-*.json 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true
}

# Run with flock
with_lock() {
  exec 200>"$LOCK_FILE"
  if ! flock -w "$LOCK_TIMEOUT" 200; then
    die "Failed to acquire lock within ${LOCK_TIMEOUT}s"
  fi
  "$@"
}

# Check and reset daily stats if date changed
check_daily_reset() {
  local today=$(date '+%Y-%m-%d')
  local current_date=$(jq -r '.stats.today.date // ""' "$QUEUE_FILE")
  if [ "$current_date" != "$today" ]; then
    backup_queue
    local tmp=$(mktemp)
    jq --arg today "$today" '
      .stats.today = {date: $today, global: 0, projects: {}}
    ' "$QUEUE_FILE" > "$tmp" && mv "$tmp" "$QUEUE_FILE"
  fi
}

# Check and auto-unlock stale logic lock
check_logic_lock() {
  local locked=$(jq -r '.lock.locked' "$QUEUE_FILE")
  if [ "$locked" = "true" ]; then
    local locked_at=$(jq -r '.lock.lockedAt // ""' "$QUEUE_FILE")
    if [ -n "$locked_at" ]; then
      local locked_epoch=$(date -d "$locked_at" +%s 2>/dev/null || echo 0)
      local now_epoch=$(date +%s)
      local diff=$((now_epoch - locked_epoch))
      if [ "$diff" -gt "$LOGIC_LOCK_TIMEOUT" ]; then
        log "Logic lock stale (${diff}s old), auto-unlocking"
        local tmp=$(mktemp)
        jq '.lock = {locked: false, lockedBy: null, lockedAt: null}' "$QUEUE_FILE" > "$tmp" && mv "$tmp" "$QUEUE_FILE"
      fi
    fi
  fi
}

# Get daily limit from project.json
get_project_daily_limit() {
  local project_id="$1"
  local project_dir="$QUEUE_DIR/projects/$project_id"
  if [ -f "$project_dir/project.json" ]; then
    jq -r '.limits.dailyLimit // 999' "$project_dir/project.json"
  else
    log "WARN: project.json not found for $project_id, using no limit"
    echo 999
  fi
}

# Get daily usage for project
get_project_daily_count() {
  local project_id="$1"
  jq -r --arg pid "$project_id" '.stats.today.projects[$pid] // 0' "$QUEUE_FILE"
}

# ─── 명령어 구현 ───

cmd_add() {
  local project_id="" scene_id="" lora_id="" priority=2 prompt_override="" resolution="" seed="" force=false
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project) project_id="$2"; shift 2 ;;
      --scene) scene_id="$2"; shift 2 ;;
      --lora) lora_id="$2"; shift 2 ;;
      --priority) priority="$2"; shift 2 ;;
      --prompt-override) prompt_override="$2"; shift 2 ;;
      --resolution) resolution="$2"; shift 2 ;;
      --seed) seed="$2"; shift 2 ;;
      --force) force=true; shift ;;
      *) die "Unknown option: $1" ;;
    esac
  done

  [ -z "$project_id" ] && die "--project required"
  [ -z "$scene_id" ] && die "--scene required"

  ensure_queue_file
  check_daily_reset

  # Duplicate check (unless --force)
  if [ "$force" = "false" ]; then
    local dup_key="${project_id}|${scene_id}|${lora_id}"
    local dup=$(jq -r --arg dk "$dup_key" '
      [.entries[] | select(.status == "pending" or .status == "running")
       | "\(.projectId)|\(.sceneId)|\(.loraId // "")"] 
      | index($dk) // "null"
    ' "$QUEUE_FILE")
    if [ "$dup" != "null" ]; then
      jq -n --arg msg "Duplicate entry exists for $dup_key (use --force to override)" \
        '{action: "rejected", reason: $msg}'
      return 0
    fi
  fi

  local entry_id="e$(date '+%Y%m%d%H%M%S')$(( RANDOM % 1000 ))"
  local now=$(date '+%Y-%m-%dT%H:%M:%S+09:00')

  # Build metadata
  local metadata="{}"
  [ -n "$prompt_override" ] && metadata=$(echo "$metadata" | jq --arg v "$prompt_override" '.prompt_override = $v')
  [ -n "$resolution" ] && metadata=$(echo "$metadata" | jq --arg v "$resolution" '.resolution = $v')
  [ -n "$seed" ] && metadata=$(echo "$metadata" | jq --arg v "$seed" '.seed = ($v | tonumber)')

  local lora_json="null"
  [ -n "$lora_id" ] && lora_json="\"$lora_id\""

  backup_queue
  local tmp=$(mktemp)
  jq --arg id "$entry_id" \
     --arg pid "$project_id" \
     --arg sid "$scene_id" \
     --argjson lid "$lora_json" \
     --argjson pri "$priority" \
     --arg now "$now" \
     --argjson meta "$metadata" \
  '
    .entries += [{
      id: $id,
      projectId: $pid,
      sceneId: $sid,
      loraId: $lid,
      priority: $pri,
      status: "pending",
      attempts: 0,
      maxAttempts: 3,
      createdAt: $now,
      startedAt: null,
      completedAt: null,
      error: null,
      metadata: $meta
    }]
  ' "$QUEUE_FILE" > "$tmp" && mv "$tmp" "$QUEUE_FILE"

  jq -n --arg id "$entry_id" --arg pid "$project_id" --arg sid "$scene_id" \
    '{action: "added", entry: {id: $id, projectId: $pid, sceneId: $sid}}'
}

cmd_next() {
  ensure_queue_file
  check_daily_reset
  check_logic_lock

  # Check logic lock
  local locked=$(jq -r '.lock.locked' "$QUEUE_FILE")
  if [ "$locked" = "true" ]; then
    jq -n '{action: "wait", reason: "queue locked"}'
    return 0
  fi

  # Check global daily limit
  local global_limit=$(jq -r '.limits.global.dailyLimit // 999' "$QUEUE_FILE")
  local global_count=$(jq -r '.stats.today.global // 0' "$QUEUE_FILE")
  if [ "$global_count" -ge "$global_limit" ]; then
    jq -n '{action: "wait", reason: "global daily limit reached"}'
    return 0
  fi

  # Get next pending entry (priority asc, createdAt asc)
  local next_entry=$(jq '
    [.entries[] | select(.status == "pending")]
    | sort_by(.priority, .createdAt)
    | .[0] // null
  ' "$QUEUE_FILE")

  if [ "$next_entry" = "null" ] || [ -z "$next_entry" ]; then
    jq -n '{action: "empty", reason: "no pending entries"}'
    return 0
  fi

  # Check project daily limit
  local project_id=$(echo "$next_entry" | jq -r '.projectId')
  local project_limit=$(get_project_daily_limit "$project_id")
  local project_count=$(get_project_daily_count "$project_id")
  if [ "$project_count" -ge "$project_limit" ]; then
    jq -n --arg pid "$project_id" '{action: "wait", reason: ("project " + $pid + " daily limit reached")}'
    return 0
  fi

  # Set to running + acquire logic lock
  local entry_id=$(echo "$next_entry" | jq -r '.id')
  local now=$(date '+%Y-%m-%dT%H:%M:%S+09:00')

  backup_queue
  local tmp=$(mktemp)
  jq --arg eid "$entry_id" --arg now "$now" '
    (.entries[] | select(.id == $eid)) |= (
      .status = "running",
      .startedAt = $now
    )
    | .lock = {locked: true, lockedBy: $eid, lockedAt: $now}
  ' "$QUEUE_FILE" > "$tmp" && mv "$tmp" "$QUEUE_FILE"

  # Return the entry
  echo "$next_entry" | jq --arg action "process" '{action: $action, entry: .}'
}

cmd_complete() {
  local entry_id="${1:-}"
  [ -z "$entry_id" ] && die "Entry ID required"

  ensure_queue_file
  check_daily_reset

  local now=$(date '+%Y-%m-%dT%H:%M:%S+09:00')
  local project_id=$(jq -r --arg eid "$entry_id" '.entries[] | select(.id == $eid) | .projectId // ""' "$QUEUE_FILE")
  [ -z "$project_id" ] && die "Entry $entry_id not found in entries"

  backup_queue
  local tmp=$(mktemp)
  jq --arg eid "$entry_id" --arg now "$now" --arg pid "$project_id" '
    # Move entry to completed
    (.entries | map(select(.id != $eid))) as $new_entries
    | (.entries[] | select(.id == $eid) | .status = "completed" | .completedAt = $now) as $completed_entry
    | .entries = $new_entries
    | .completed += [$completed_entry]
    # Release logic lock
    | .lock = {locked: false, lockedBy: null, lockedAt: null}
    # Update stats
    | .stats.today.global = (.stats.today.global + 1)
    | .stats.today.projects[$pid] = ((.stats.today.projects[$pid] // 0) + 1)
  ' "$QUEUE_FILE" > "$tmp" && mv "$tmp" "$QUEUE_FILE"

  jq -n --arg id "$entry_id" '{action: "completed", entry: {id: $id}}'
}

cmd_fail() {
  local entry_id="${1:-}"
  local error_msg=""
  while [[ $# -gt 1 ]]; do
    case "$2" in
      --error) error_msg="$3"; shift 2 ;;
      *) shift ;;
    esac
  done
  [ -z "$entry_id" ] && die "Entry ID required"

  ensure_queue_file

  backup_queue
  local now=$(date '+%Y-%m-%dT%H:%M:%S+09:00')
  local tmp=$(mktemp)

  # Check attempts
  local max_attempts=$(jq -r --arg eid "$entry_id" '.entries[] | select(.id == $eid) | .maxAttempts // 3' "$QUEUE_FILE")
  local current_attempts=$(jq -r --arg eid "$entry_id" '.entries[] | select(.id == $eid) | .attempts // 0' "$QUEUE_FILE")
  local new_attempts=$((current_attempts + 1))

  if [ "$new_attempts" -ge "$max_attempts" ]; then
    # Max attempts reached → mark as failed permanently
    jq --arg eid "$entry_id" --arg now "$now" --arg err "$error_msg" --argjson att "$new_attempts" '
      (.entries[] | select(.id == $eid)) |= (
        .status = "failed",
        .attempts = $att,
        .error = $err
      )
      | .lock = {locked: false, lockedBy: null, lockedAt: null}
    ' "$QUEUE_FILE" > "$tmp" && mv "$tmp" "$QUEUE_FILE"
    jq -n --arg id "$entry_id" --argjson att "$new_attempts" '{action: "failed", entry: {id: $id, attempts: $att}, reason: "max attempts reached"}'
  else
    # Retry → set back to pending
    jq --arg eid "$entry_id" --arg now "$now" --arg err "$error_msg" --argjson att "$new_attempts" '
      (.entries[] | select(.id == $eid)) |= (
        .status = "pending",
        .attempts = $att,
        .error = $err,
        .startedAt = null
      )
      | .lock = {locked: false, lockedBy: null, lockedAt: null}
    ' "$QUEUE_FILE" > "$tmp" && mv "$tmp" "$QUEUE_FILE"
    jq -n --arg id "$entry_id" --argjson att "$new_attempts" '{action: "retry", entry: {id: $id, attempts: $att}}'
  fi
}

cmd_status() {
  ensure_queue_file
  check_daily_reset

  local pending=$(jq '[.entries[] | select(.status == "pending")] | length' "$QUEUE_FILE")
  local running=$(jq '[.entries[] | select(.status == "running")] | length' "$QUEUE_FILE")
  local failed=$(jq '[.entries[] | select(.status == "failed")] | length' "$QUEUE_FILE")
  local completed_today=$(jq -r '.stats.today.global // 0' "$QUEUE_FILE")
  local locked=$(jq -r '.lock.locked' "$QUEUE_FILE")
  local oldest_pending=$(jq -r '[.entries[] | select(.status == "pending") | .createdAt] | sort | .[0] // "none"' "$QUEUE_FILE")
  
  # Per-project limits
  local project_limits="{}"
  for proj_dir in "$QUEUE_DIR"/projects/*/; do
    if [ -d "$proj_dir" ] && [ -f "$proj_dir/project.json" ]; then
      local pid=$(jq -r '.id' "$proj_dir/project.json")
      local plimit=$(jq -r '.limits.dailyLimit // 999' "$proj_dir/project.json")
      local pcount=$(jq -r --arg p "$pid" '.stats.today.projects[$p] // 0' "$QUEUE_FILE")
      project_limits=$(echo "$project_limits" | jq --arg pid "$pid" --argjson limit "$plimit" --argjson count "$pcount" \
        '.[$pid] = {limit: $limit, count: $count}')
    fi
  done

  local global_limit=$(jq -r '.limits.global.dailyLimit // 999' "$QUEUE_FILE")

  jq -n \
    --argjson pending "$pending" \
    --argjson running "$running" \
    --argjson failed "$failed" \
    --argjson completed_today "$completed_today" \
    --argjson locked "$locked" \
    --arg oldest_pending "$oldest_pending" \
    --argjson global_limit "$global_limit" \
    --argjson project_limits "$project_limits" \
  '{
    pending: $pending,
    running: $running,
    failed: $failed,
    completed_today: $completed_today,
    daily_limit: {global: $global_limit, projects: $project_limits},
    locked: $locked,
    oldest_pending: $oldest_pending
  }'
}

cmd_unlock() {
  ensure_queue_file
  backup_queue
  local tmp=$(mktemp)
  jq '.lock = {locked: false, lockedBy: null, lockedAt: null}' "$QUEUE_FILE" > "$tmp" && mv "$tmp" "$QUEUE_FILE"
  jq -n '{action: "unlocked"}'
}

cmd_cleanup() {
  ensure_queue_file
  local include_failed="${1:-}"
  local now_epoch=$(date +%s)
  
  backup_queue
  local tmp=$(mktemp)
  
  # Clean completed entries older than 24h
  local completed_keep="[]"
  local completed_archive="[]"
  
  # Read completed entries and split by age
  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    local completed_at=$(echo "$entry" | jq -r '.completedAt // ""')
    if [ -n "$completed_at" ]; then
      local entry_epoch=$(date -d "$completed_at" +%s 2>/dev/null || echo 0)
      local age=$((now_epoch - entry_epoch))
      if [ "$age" -gt 86400 ]; then
        completed_archive=$(echo "$completed_archive" | jq --argjson e "$entry" '. += [$e]')
      else
        completed_keep=$(echo "$completed_keep" | jq --argjson e "$entry" '. += [$e]')
      fi
    else
      completed_keep=$(echo "$completed_keep" | jq --argjson e "$entry" '. += [$e]')
    fi
  done < <(jq -c '.completed[]' "$QUEUE_FILE")

  # Archive failed entries (72h) or all if --all-failed
  local failed_keep="[]"
  local failed_archive_entries="[]"
  
  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    local last_attempt=$(echo "$entry" | jq -r '.startedAt // .createdAt // ""')
    local should_archive=false
    
    if [ "$include_failed" = "--all-failed" ]; then
      should_archive=true
    elif [ -n "$last_attempt" ]; then
      local entry_epoch=$(date -d "$last_attempt" +%s 2>/dev/null || echo 0)
      local age=$((now_epoch - entry_epoch))
      [ "$age" -gt 259200 ] && should_archive=true  # 72h
    fi
    
    if [ "$should_archive" = "true" ]; then
      failed_archive_entries=$(echo "$failed_archive_entries" | jq --argjson e "$entry" '. += [$e]')
    else
      failed_keep=$(echo "$failed_keep" | jq --argjson e "$entry" '. += [$e]')
    fi
  done < <(jq -c '.entries[] | select(.status == "failed")' "$QUEUE_FILE")

  # Save failed archive
  local archive_count=$(echo "$failed_archive_entries" | jq 'length')
  local completed_archive_count=$(echo "$completed_archive" | jq 'length')
  
  if [ "$archive_count" -gt 0 ] || [ "$completed_archive_count" -gt 0 ]; then
    local archive_date=$(date '+%Y%m%d')
    local archive_file="$QUEUE_DIR/archive/failed/queue-archive-${archive_date}.json"
    mkdir -p "$(dirname "$archive_file")"
    
    # Merge with existing archive if present
    local existing_archive="[]"
    [ -f "$archive_file" ] && existing_archive=$(jq '.' "$archive_file" 2>/dev/null || echo "[]")
    
    local all_archived=$(echo "$existing_archive" | jq --argjson c "$completed_archive" --argjson f "$failed_archive_entries" \
      '. + $c + $f')
    echo "$all_archived" > "$archive_file"
  fi

  # Update queue.json: remove archived entries
  jq --argjson completed_keep "$completed_keep" --argjson failed_keep "$failed_keep" '
    .completed = $completed_keep
    | .entries = (.entries | map(select(.status != "failed")) + $failed_keep)
  ' "$QUEUE_FILE" > "$tmp" && mv "$tmp" "$QUEUE_FILE"

  jq -n --argjson completed "$completed_archive_count" --argjson failed "$archive_count" \
    '{action: "cleaned", archived_completed: $completed, archived_failed: $failed}'
}

cmd_list() {
  ensure_queue_file
  local project_filter="" status_filter=""
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project) project_filter="$2"; shift 2 ;;
      --status) status_filter="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  local filter=".entries[]"
  [ -n "$project_filter" ] && filter="$filter | select(.projectId == \"$project_filter\")"
  [ -n "$status_filter" ] && filter="$filter | select(.status == \"$status_filter\")"

  jq -c "$filter" "$QUEUE_FILE" 2>/dev/null || jq -n '{entries: []}'
}

cmd_cancel() {
  local entry_id="${1:-}"
  [ -z "$entry_id" ] && die "Entry ID required"
  ensure_queue_file

  local status=$(jq -r --arg eid "$entry_id" '.entries[] | select(.id == $eid) | .status // "not_found"' "$QUEUE_FILE")
  if [ "$status" = "not_found" ]; then
    jq -n --arg id "$entry_id" '{action: "not_found", entry: {id: $id}}'
    return 0
  fi
  if [ "$status" = "running" ]; then
    jq -n --arg id "$entry_id" '{action: "rejected", reason: "cannot cancel running entry, use fail instead"}'
    return 0
  fi

  backup_queue
  local tmp=$(mktemp)
  jq --arg eid "$entry_id" '.entries = (.entries | map(select(.id != $eid))' "$QUEUE_FILE" > "$tmp" && mv "$tmp" "$QUEUE_FILE"
  jq -n --arg id "$entry_id" '{action: "cancelled", entry: {id: $id}}'
}

cmd_reprioritize() {
  local entry_id="" new_priority=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --priority) new_priority="$2"; shift 2 ;;
      *) entry_id="$1"; shift ;;
    esac
  done
  [ -z "$entry_id" ] && die "Entry ID required"
  [ -z "$new_priority" ] && die "--priority required"
  ensure_queue_file

  local status=$(jq -r --arg eid "$entry_id" '.entries[] | select(.id == $eid) | .status // "not_found"' "$QUEUE_FILE")
  if [ "$status" = "not_found" ]; then
    jq -n --arg id "$entry_id" '{action: "not_found", entry: {id: $id}}'
    return 0
  fi
  if [ "$status" != "pending" ]; then
    jq -n --arg id "$entry_id" --arg s "$status" '{action: "rejected", reason: ("can only reprioritize pending entries, current: " + $s)}'
    return 0
  fi

  backup_queue
  local tmp=$(mktemp)
  jq --arg eid "$entry_id" --argjson pri "$new_priority" \
    '(.entries[] | select(.id == $eid)).priority = $pri' "$QUEUE_FILE" > "$tmp" && mv "$tmp" "$QUEUE_FILE"
  jq -n --arg id "$entry_id" --argjson pri "$new_priority" '{action: "reprioritized", entry: {id: $id, priority: $pri}}'
}

cmd_reset_stats() {
  ensure_queue_file
  local today=$(date '+%Y-%m-%d')
  backup_queue
  local tmp=$(mktemp)
  jq --arg today "$today" '.stats.today = {date: $today, global: 0, projects: {}}' "$QUEUE_FILE" > "$tmp" && mv "$tmp" "$QUEUE_FILE"
  jq -n '{action: "reset", date: "'"$today"'"}'
}

# ─── 메인 ───

case "${1:-}" in
  add)       shift; with_lock cmd_add "$@" ;;
  next)      shift; with_lock cmd_next "$@" ;;
  complete)  shift; with_lock cmd_complete "$@" ;;
  fail)      shift; with_lock cmd_fail "$@" ;;
  status)    shift; with_lock cmd_status "$@" ;;
  unlock)    shift; with_lock cmd_unlock "$@" ;;
  cleanup)   shift; with_lock cmd_cleanup "$@" ;;
  list)      shift; with_lock cmd_list "$@" ;;
  cancel)    shift; with_lock cmd_cancel "$@" ;;
  reprioritize) shift; with_lock cmd_reprioritize "$@" ;;
  reset-stats)  shift; with_lock cmd_reset_stats "$@" ;;
  help|--help|-h)
    echo "Usage: image-queue.sh <command> [options]"
    echo ""
    echo "Commands:"
    echo "  add         Add entry to queue"
    echo "  next        Get next pending entry (+ lock)"
    echo "  complete    Mark entry completed (- lock)"
    echo "  fail        Mark entry failed (- lock, retry if attempts left)"
    echo "  status      Show queue summary"
    echo "  unlock      Force unlock queue"
    echo "  cleanup     Archive old completed/failed entries"
    echo "  list        List entries (--project, --status filters)"
    echo "  cancel      Cancel a pending entry"
    echo "  reprioritize <id> --priority N"
    echo "  reset-stats Reset daily statistics"
    echo ""
    echo "Options for 'add':"
    echo "  --project ID     Project ID (required)"
    echo "  --scene ID       Scene ID (required)"
    echo "  --lora ID        LoRA ID (optional)"
    echo "  --priority N     Priority 1=high, 2=normal, 3=low (default: 2)"
    echo "  --prompt-override TEXT"
    echo "  --resolution WxH"
    echo "  --seed N"
    echo "  --force          Skip duplicate check"
    ;;
  *) die "Unknown command: ${1:-}. Use 'help' for usage." ;;
esac