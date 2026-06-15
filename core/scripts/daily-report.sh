#!/bin/bash
# ============================================================================
HERMES_ROOT="${HERMES_ROOT:-$HOME/.hermes}"
# daily-report.sh - 매일 아침 리포트 생성
# ============================================================================
# 실행: 매일 08:00 (schedule)
# 기능:
# 1. JOB-QUEUE 상태 요약 (하루 변화)
# 2. 야간 추가 작업 (모든 야간 등록 작업)
# 3. 우선순위 높은 작업 (상위 3개)
# 4. 스케줄/유휴 백그라운드 작업 결과 상세 분석
# 5. 기술 뉴스 요약
# 6. 시스템 상태
#
# Version: 3.4.0
# Last updated: 2026-05-07
# JOB: JOB-416, JOB-841, JOB-919, JOB-981
# ============================================================================

set -e

# ─── 원자적 쓰기 라이브러리 ────────────────────────────────────────────────
source $HERMES_ROOT/core/scripts/lib/atomic.sh 2>/dev/null || true

WORKSPACE="/home/bot/.openclaw/workspace"
WORKSPACE_IMAGE="/home/bot/.openclaw/workspace_image"
MEMORY_DIR="$WORKSPACE/memory"
LOG_DIR="$WORKSPACE/memory/logs"
REPORT_DIR="$MEMORY_DIR/daily-reports"
JOB_QUEUE="$WORKSPACE/JOB-QUEUE.md"
JOB_COMPLETED="$WORKSPACE/JOB-COMPLETED.md"
STATE_FILE="$MEMORY_DIR/daily-state.json"
BG_LOG="$LOG_DIR/background-tasks.log"
LOG_FILE="$LOG_DIR/daily-report.log"

# 항공권 데이터 경로 (JOB-818)
FLIGHTS_DIR="$MEMORY_DIR/flights"
FLIGHTS_DEALS="$FLIGHTS_DIR/deals"
FLIGHTS_STATE="$FLIGHTS_DIR/state/last-run.json"

# 로그 디렉토리 생성
mkdir -p "$LOG_DIR" "$REPORT_DIR"

# 날짜와 시간
TODAY=$(date '+%Y-%m-%d')
YESTERDAY=$(date -d "yesterday" '+%Y-%m-%d')
NOW=$(date '+%Y-%m-%d %H:%M:%S')
REPORT_FILE="$REPORT_DIR/$TODAY.md"

# 로그 함수
log() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$LOG_FILE"
}

log "INFO" "========== Daily Report Start =========="
log "INFO" "Date: $TODAY"

# ============================================================================
# 1. 상태 파일 처리 (daily-state.json)
# ============================================================================
log "INFO" "[1/6] Loading daily state..."

# 엣지 케이스: 파일 없으면 초기화
if [ ! -f "$STATE_FILE" ]; then
    cat > "$STATE_FILE" << EOF
{
  "date": "$TODAY",
  "pending_count": 0,
  "completed_today": 0,
  "new_registrations": 0,
  "previous_pending": 0,
  "last_updated": "$NOW"
}
EOF
    log "INFO" "Created new daily-state.json"
fi

# jq 확인 및 이전 값 로드
if command -v jq &>/dev/null; then
    PREV_PENDING=$(jq -r '.pending_count // 0' "$STATE_FILE")
    PREV_DATE=$(jq -r '.date // ""' "$STATE_FILE")
else
    PREV_PENDING=$(grep -o '"pending_count":[0-9]*' "$STATE_FILE" 2>/dev/null | cut -d: -f2 || echo "0")
    PREV_DATE=$(grep -o '"date":"[^"]*"' "$STATE_FILE" 2>/dev/null | cut -d'"' -f4 || echo "")
fi

log "INFO" "Previous pending: $PREV_PENDING (from $PREV_DATE)"

# ============================================================================
# 2. JOB-QUEUE 상태 분석 (하루 변화)
# ============================================================================
log "INFO" "[2/6] Analyzing JOB-QUEUE status..."

if [ -f "$JOB_QUEUE" ]; then
    PENDING_NOW=$(grep "^### JOB-" "$JOB_QUEUE" | grep -v "✅ 완료" | wc -l | tr -d ' ')
    NEW_TODAY=$(grep "등록일.*$TODAY" "$JOB_QUEUE" | wc -l | tr -d ' ')
    HIGH_PRIO=$(grep -A5 "우선순위.*High" "$JOB_QUEUE" | grep "^### JOB-" | wc -l | tr -d ' ')
    MED_PRIO=$(grep -A5 "우선순위.*Medium" "$JOB_QUEUE" | grep "^### JOB-" | wc -l | tr -d ' ')
    HIGH_PRIO=${HIGH_PRIO:-0}
    MED_PRIO=${MED_PRIO:-0}
    
    # 델타 계산
    DELTA=$((PENDING_NOW - PREV_PENDING))
    if [ "$DELTA" -gt 0 ]; then
        DELTA_STR="+$DELTA"
    else
        DELTA_STR="$DELTA"
    fi
    
    # 엣지 케이스: 비정상적 변화
    if [ "$DELTA" -lt -100 ]; then
        DELTA_STR="N/A"
    fi
    
    log "INFO" "Pending: $PENDING_NOW, New today: $NEW_TODAY, Delta: $DELTA_STR"
else
    PENDING_NOW=0; NEW_TODAY=0; HIGH_PRIO=0; MED_PRIO=0; DELTA_STR="N/A"
fi

# 오늘 완료된 작업 수
COMPLETED_TODAY=0
COMPLETED_DETAIL=""
if [ -f "$JOB_COMPLETED" ] && grep -q "완료일.*$TODAY" "$JOB_COMPLETED" 2>/dev/null; then
    COMPLETED_TODAY=$(grep -c "완료일.*$TODAY" "$JOB_COMPLETED" 2>/dev/null || echo "0")
    # 완료된 작업 목록 (최대 3개)
    COMPLETED_DETAIL=$(grep -B3 "완료일.*$TODAY" "$JOB_COMPLETED" 2>/dev/null | grep "^### JOB-" | head -3 | sed 's/^### /• /' || true)
fi

# Wiki 배경지식 참조
get_wiki_context() {
    local wiki_index="$WORKSPACE/wiki/index.md"
    local topics_dir="$WORKSPACE/wiki/topics"
    [[ ! -f "$wiki_index" ]] && return 0
    [[ ! -d "$topics_dir" ]] && return 0

    # 오늘 진행/완료된 JOB 확인
    local recent_jobs
    recent_jobs=$(grep -oP 'JOB-\d+' "$JOB_QUEUE" "$JOB_COMPLETED" 2>/dev/null \
        | sort -u | head -5)
    [[ -z "$recent_jobs" ]] && return 0

    # JOB 번호를 topics/에서 검색
    local context_lines=()
    for job in $recent_jobs; do
        while IFS= read -r topic_file; do
            if grep -q "$job" "$topic_file" 2>/dev/null; then
                local topic_name
                topic_name=$(basename "$topic_file" .md)
                local insight
                insight=$(sed -n '/패턴 & 통찰/,/^$/p' "$topic_file" 2>/dev/null | grep -v '^$' | head -4)
                [[ -n "$insight" ]] && context_lines+=("[$topic_name] $insight")
            fi
        done < <(find "$topics_dir" -name "*.md" 2>/dev/null)
    done

    if [[ ${#context_lines[@]} -gt 0 ]]; then
        echo "📖 Wiki 배경지식 (자동 참조):"
        printf '  %s\n' "${context_lines[@]}" | head -10
        echo ""
    fi
}

# Subconscious 아이디어 요약
get_subconscious_ideas() {
    local ideas_file="$WORKSPACE/memory/subconscious-ideas.json"
    [[ ! -f "$ideas_file" ]] && return 0

    local pending
    pending=$(jq -r '.ideas | map(select(.status=="pending")) | length' "$ideas_file" 2>/dev/null || echo "0")
    if [[ "$pending" -eq 0 ]]; then
        return 0
    fi

    echo "• $(jq -r '.ideas | map(select(.status=="pending")) | .[0:5] | .[] | "\(.title) (\(.impact))"' "$ideas_file" 2>/dev/null)"
    if [[ "$pending" -gt 5 ]]; then
        echo "• 외 $(($pending - 5))개 더..."
    fi
    echo "(총 $pending개 대기 — "아이디어 확인"으로 리뷰)"
}

# ============================================================================
# 3. 야간 작업 추출 (모든 야간 등록 작업)
# ============================================================================
log "INFO" "[3/6] Extracting overnight jobs..."

# 야간 윈도우: 전날 20:00 ~ 오늘 08:00
OVERNIGHT_JOBS=""
OVERNIGHT_COUNT=0

if [ -f "$JOB_QUEUE" ]; then
    # 오늘 등록된 모든 작업 추출 (등록일 기준)
    OVERNIGHT_JOBS=$(grep -B1 "등록일.*$TODAY" "$JOB_QUEUE" 2>/dev/null | grep "^### JOB-" | sed 's/^### //' || true)
    
    if [ -n "$OVERNIGHT_JOBS" ]; then
        OVERNIGHT_COUNT=$(echo "$OVERNIGHT_JOBS" | wc -l | tr -d ' ')
    fi
fi

log "INFO" "Overnight jobs: $OVERNIGHT_COUNT"

# ============================================================================
# 4. 우선순위 높은 작업 추출 (상위 3개)
# ============================================================================
log "INFO" "[4/6] Extracting priority jobs..."

PRIO_JOBS=""
PRIO_COUNT=0

if [ -f "$JOB_QUEUE" ]; then
    # High 우선순위 작업
    HIGH_JOBS=$(grep -B1 -A6 "우선순위.*High" "$JOB_QUEUE" 2>/dev/null | grep "^### JOB-" | head -3 || true)
    
    # Medium 우선순위 작업
    MED_JOBS=$(grep -B1 -A6 "우선순위.*Medium" "$JOB_QUEUE" 2>/dev/null | grep "^### JOB-" | head -3 || true)
    
    # 합쳐서 상위 3개
    PRIO_JOBS=$(echo -e "$HIGH_JOBS\n$MED_JOBS" | grep -v "^$" | head -3 || true)
    
    # 엣지 케이스: 우선순위 작업 없으면 대기 작업 상위 사용
    if [ -z "$PRIO_JOBS" ]; then
        PRIO_JOBS=$(grep "^### JOB-" "$JOB_QUEUE" 2>/dev/null | grep -v "✅ 완료" | head -3 || true)
    fi
    
    if [ -n "$PRIO_JOBS" ]; then
        PRIO_COUNT=$(echo "$PRIO_JOBS" | wc -l | tr -d ' ')
    fi
fi

log "INFO" "Priority jobs: $PRIO_COUNT"

# ============================================================================
# 5. 백그라운드 작업 분석
# ============================================================================
log "INFO" "[5/6] Analyzing background tasks..."

SCHEDULE_DETAILS=""
SCHEDULE_OK=0
SCHEDULE_RUNS=0

if [ -f "$BG_LOG" ]; then
    # 스케줄 작업 실행 횟수 - Schedule 작업은 cron-schedule.log 에 기록됨
    CRON_LOG="$LOG_DIR/cron-schedule.log"
    if [ -f "$CRON_LOG" ]; then
        SCHEDULE_RUNS=$(grep "$TODAY" "$CRON_LOG" | wc -l | tr -d ' ')
        SCHEDULE_RUNS=${SCHEDULE_RUNS:-0}
    fi
    
    # --- workspace-refiner ---
    WR_DEL=$(grep "$TODAY" "$CRON_LOG" | grep "\.bak 파일 삭제\|삭제 완료" | grep -oP '\d+개' | tail -1 || echo "0")
    WR_EMPTY=$(grep "$TODAY" "$CRON_LOG" | grep "빈 폴더\|빈폴더" | grep -oP '\d+개' | tail -1 || echo "0")
    WR_TMP=$(grep "$TODAY" "$CRON_LOG" | grep "임시 파일\|임시파일" | grep -oP '\d+개' | tail -1 || echo "0")
    
    # D1: 값이 모두 0이면 줄 생략
    if [ -n "$WR_DEL$WR_EMPTY$WR_TMP" ] && [ "$WR_DEL$WR_EMPTY$WR_TMP" != "000" ]; then
        SCHEDULE_DETAILS="${SCHEDULE_DETAILS}• workspace-refiner: .bak ${WR_DEL}, 빈폴더 ${WR_EMPTY}, 임시 ${WR_TMP}\n"
    fi

    # --- md-health-check ---
    MD_TOTAL_ISSUES=$(grep "$TODAY" "$CRON_LOG" | grep -i "md-health\|md health" -A10 | grep -oP '총 \d+개 이슈\|이슈 \d+' | grep -oP '\d+' | tail -1 || echo "0")
    MD_TOTAL_ISSUES=${MD_TOTAL_ISSUES:-0}
    if [ "$MD_TOTAL_ISSUES" -gt 0 ]; then
        SCHEDULE_DETAILS="${SCHEDULE_DETAILS}• md-health-check: 이슈 ${MD_TOTAL_ISSUES}개 → JOB 자동등록\n"
    fi

    # --- auto-research ---
    RESEARCH_REQ=0
    RESEARCH_OK=0
    RESEARCH_LOG_FILE=$(ls -t "$WORKSPACE_IMAGE/research/logs/research_${TODAY}.log" 2>/dev/null | head -1)
    if [ -f "$RESEARCH_LOG_FILE" ]; then
        RESEARCH_REQ=$(grep -c "생성 요청\|Queued\|prompt" "$RESEARCH_LOG_FILE" 2>/dev/null || echo "0")
        RESEARCH_OK=$(grep -c "성공\|completed\|saved\|저장" "$RESEARCH_LOG_FILE" 2>/dev/null || echo "0")
    fi
    # D1: 값이 모두 0이면 줄 생략
    if [ "$RESEARCH_REQ" -gt 0 ] || [ "$RESEARCH_OK" -gt 0 ]; then
        SCHEDULE_DETAILS="${SCHEDULE_DETAILS}• auto-research: 요청 ${RESEARCH_REQ}, 성공 ${RESEARCH_OK}\n"
    fi

    # --- nightly-distill (상세 설명 추가) ---
    DISTILL_STATE="$WORKSPACE/memory/nightly-distill-state.json"
    DISTILL_PROMO=0
    DISTILL_LESSONS=0
    DISTILL_CANDIDATES=0
    DISTILL_RAN_TODAY=0
    
    if [ -f "$DISTILL_STATE" ]; then
        if command -v jq &>/dev/null; then
            DISTILL_PROMO=$(jq -r '.last_promotions // 0' "$DISTILL_STATE" 2>/dev/null || echo "0")
            DISTILL_LESSONS=$(jq -r '.last_lessons // 0' "$DISTILL_STATE" 2>/dev/null || echo "0")
            DISTILL_CANDIDATES=$(jq -r '.last_candidates // 0' "$DISTILL_STATE" 2>/dev/null || echo "0")
            DISTILL_LAST_RUN=$(jq -r '.last_run // ""' "$DISTILL_STATE" 2>/dev/null || echo "")
        else
            DISTILL_PROMO=$(grep -o '"last_promotions":[0-9]*' "$DISTILL_STATE" 2>/dev/null | cut -d: -f2 || echo "0")
            DISTILL_LESSONS=$(grep -o '"last_lessons":[0-9]*' "$DISTILL_STATE" 2>/dev/null | cut -d: -f2 || echo "0")
            DISTILL_CANDIDATES=$(grep -o '"last_candidates":[0-9]*' "$DISTILL_STATE" 2>/dev/null | cut -d: -f2 || echo "0")
            DISTILL_LAST_RUN=$(grep -o '"last_run":"[^"]*"' "$DISTILL_STATE" 2>/dev/null | cut -d'"' -f4 || echo "")
        fi
        
        # 오늘 실행 여부 확인
        if [ "$DISTILL_LAST_RUN" = "$TODAY" ]; then
            DISTILL_RAN_TODAY=1
        fi
    fi
    
    # 오늘 실행했으면 실제 수치, 아니면 생략
    if [ "$DISTILL_RAN_TODAY" -eq 1 ]; then
        SCHEDULE_DETAILS="${SCHEDULE_DETAILS}• nightly-distill: 승급 ${DISTILL_PROMO}개, 교훈 ${DISTILL_LESSONS}개\n"
    fi

    # --- tech-news-daily ---
    TECH_COUNT="0"
    TECH_GITHUB="0"
    TECH_GUIDE="0"
    NEWS_DIR="$MEMORY_DIR/tech-news"
    GUIDE_CANDIDATES_DIR="$MEMORY_DIR/ref-candidates"
    LATEST_NEWS=$(ls -t "$NEWS_DIR"/*.md 2>/dev/null | head -1)
    if [ -f "$LATEST_NEWS" ]; then
        TECH_COUNT=$(grep "^- \[" "$LATEST_NEWS" | wc -l | tr -d ' ')
        # GitHub 자동 추가된 수
        TECH_GITHUB=$(grep "^## ✅ 자동 추가된 리퍼런스" "$LATEST_NEWS" -A 10 | grep "^- \[" | wc -l | tr -d ' ' || echo "0")
    fi
    # guide 후보 수
    if [ -f "$GUIDE_CANDIDATES_DIR/$TODAY.txt" ]; then
        TECH_GUIDE=$(wc -l < "$GUIDE_CANDIDATES_DIR/$TODAY.txt" 2>/dev/null | tr -d ' ' || echo "0")
    fi
    # tech-news-daily: 데이터 있을 때만 표시
    if [ "$TECH_COUNT" -gt 0 ] || [ "$TECH_GITHUB" -gt 0 ] || [ "$TECH_GUIDE" -gt 0 ]; then
        SCHEDULE_DETAILS="${SCHEDULE_DETAILS}• tech-news-daily: ${TECH_COUNT}개 수집, GitHub ${TECH_GITHUB}개 추가, guide ${TECH_GUIDE}개 검토 대기\n"
    fi

    # daily-report: 자기 자신이므로 생략

    # --- openclaw-feature-review (D2: 조건부) ---
    FEATURE_STATE="$WORKSPACE/memory/openclaw-feature-review.json"
    FEATURE_UNUSED=0
    FEATURE_SUGGESTIONS=""
    if [ -f "$FEATURE_STATE" ]; then
        FEATURE_UNUSED=$(jq '.unusedFeatures | length // 0' "$FEATURE_STATE" 2>/dev/null || echo "0")
        FEATURE_LAST=$(jq -r '.lastReview // ""' "$FEATURE_STATE" 2>/dev/null || echo "")
        if [ "$FEATURE_LAST" = "$TODAY" ] && [ "$FEATURE_UNUSED" -gt 0 ]; then
            # 오늘 발견된 제안 내용
            FEATURE_SUGGESTIONS=$(jq -r '.unusedFeatures[] | "• \(.name): \(.suggestion[:60])..."' "$FEATURE_STATE" 2>/dev/null | head -3 || echo "")
        fi
    fi
    if [ "$FEATURE_UNUSED" -gt 0 ]; then
        SCHEDULE_DETAILS="${SCHEDULE_DETAILS}• openclaw-feature-review: 미활용 ${FEATURE_UNUSED}개\n"
        if [ -n "$FEATURE_SUGGESTIONS" ]; then
            # Schedule 섹션에는 개수만 표시 (중복 방지)
            SCHEDULE_DETAILS="${SCHEDULE_DETAILS}    └ 기능 활용 추천 ${FEATURE_UNUSED}개 (상세는 별도 섹션 참조)\n"
        fi
    fi

    # --- 정상 실행 작업들 (요약만, 개별 표시 불필요) ---
    for task in wiki-sync manage-wiki kernel-android-ai-research wiki-compile rotate-logs subconscious-ideas weekly-synthesis guide-review github-reference-checker; do
        if grep -q "$TODAY.*$task" "$CRON_LOG" 2>/dev/null; then
            SCHEDULE_OK=$((SCHEDULE_OK + 1))
        fi
    done
    # github-reference-checker: 업데이트 있으면 예외 표시
    if grep -q "$TODAY.*github-reference-checker" "$CRON_LOG" 2>/dev/null; then
        REF_STATE="$WORKSPACE/reference/github-tracker.json"
        if [ -f "$REF_STATE" ] && command -v jq &>/dev/null; then
            REF_UPDATED=$(jq -r '.last_checked // ""' "$REF_STATE" 2>/dev/null)
            if [ "$REF_UPDATED" = "$TODAY" ]; then
                SCHEDULE_DETAILS="${SCHEDULE_DETAILS}• github-reference-checker: 리퍼런스 업데이트 완료\n"
            fi
        fi
    fi
    # guide-review: 후보 발견 시 예외 표시
    if grep -q "$TODAY.*guide-review" "$CRON_LOG" 2>/dev/null; then
        GUIDE_CANDIDATES=$(/home/bot/.openclaw/workspace/memory/ref-candidates/$TODAY.txt 2>/dev/null | wc -l || echo "0")
        if [ "$GUIDE_CANDIDATES" -gt 0 ]; then
            SCHEDULE_DETAILS="${SCHEDULE_DETAILS}• guide-review: ${GUIDE_CANDIDATES}개 후보 발견\n"
        fi
    fi

    # --- github-reference-checker (일요일만, JOB-918) ---
    if grep -q "$TODAY.*github-reference-checker" "$CRON_LOG" 2>/dev/null; then
        REF_UPDATED=0
        REF_STATE="$WORKSPACE/reference/github-tracker.json"
        if [ -f "$REF_STATE" ] && command -v jq &>/dev/null; then
            REF_UPDATED=$(jq -r '.last_checked // "" | if . == "'$TODAY'" then 1 else 0 end' "$REF_STATE" 2>/dev/null || echo "0")
        fi
        if [ "$REF_UPDATED" -gt 0 ]; then
            SCHEDULE_DETAILS="${SCHEDULE_DETAILS}• github-reference-checker: 리퍼런스 업데이트 완료\n"
        else
            SCHEDULE_DETAILS="${SCHEDULE_DETAILS}• github-reference-checker: 실행 완료\n"
        fi
    fi

fi

# 분석 큐 남은 수
QUEUE_FILE="$WORKSPACE_IMAGE/data/analysis_queue.jsonl"
QUEUE_PENDING=0
if [ -f "$QUEUE_FILE" ]; then
    QUEUE_PENDING=$(wc -l < "$QUEUE_FILE" | tr -d ' ')
fi

# ============================================================================
# 5.5. 항공권 데이터 분석 (JOB-835)
# ============================================================================
log "INFO" "[5.5] Analyzing flight deals..."

# --- 항공권 리포트 생성 함수 ---
build_flight_report() {
    local fetch_date="$1"
    local prices_dir="$WORKSPACE/memory/flights/prices"
    local flight_config="$WORKSPACE/memory/flights/config.json"

    if ! command -v jq &>/dev/null; then
        echo "항공권 데이터 분석 불가 (jq 없음)"
        return
    fi

    local main_report=""
    local drop_report=""
    local route_count=0

    for route_dir in "$prices_dir"/ICN-*/; do
        [ -d "$route_dir" ] || continue
        local route_id=$(basename "$route_dir")
        local route_name=$(jq -r ".routes[] | select(.id == \"$route_id\") | .name" "$flight_config" 2>/dev/null)
        local bench_low=$(jq -r ".routes[] | select(.id == \"$route_id\") | .benchmarks.low" "$flight_config" 2>/dev/null)

        # 1. 2주 후 출발 날짜 찾기
        local ref_date_sec=$(date -d "$fetch_date +14 days" '+%s' 2>/dev/null)
        local nearest_dep=""
        local nearest_diff=999999999

        for price_file in "$route_dir"/*.json; do
            [ -f "$price_file" ] || continue
            local file_fetch=$(jq -r '.fetch_date // ""' "$price_file" 2>/dev/null)
            [ "$file_fetch" = "$fetch_date" ] || continue
            local dep_sec=$(date -d "$(jq -r '.departure_date' "$price_file")" '+%s' 2>/dev/null || echo "0")
            local diff=$((dep_sec - ref_date_sec))
            [ "$diff" -lt 0 ] && diff=$((-diff))
            if [ "$diff" -lt "$nearest_diff" ]; then
                nearest_diff=$diff
                nearest_dep="$price_file"
            fi
        done

        # 2. 해당 노선 섹션 빌드
        local section=""
        local has_data=false

        # 2-1. 2주 후 출발 항공사별 가격
        if [ -n "$nearest_dep" ] && [ -f "$nearest_dep" ]; then
            local dep_date=$(jq -r '.departure_date' "$nearest_dep")
            local dep_fmt=$(date -d "$dep_date" '+%m/%d' 2>/dev/null)
            section="${route_name} (출발 ${dep_fmt})\n"

            # 전체 항공사 (best + other)
            jq -r '([.best_flights[]] + (.other_flights // []))
                | unique_by(.flights[0].airline + "_" + (.price | tostring))
                | sort_by(.price) | .[] |
                .flights[0].airline as $air |
                .price as $p |
                .total_duration as $dur |
                (($dur / 60 | floor) | tostring) as $h |
                (($dur % 60 | floor) | tostring) as $m |
                (if ((.flights | length) - 1) > 0 then "경유\((.flights | length) - 1)회" else "직항" end) as $stop |
                " • \($air) \($p)원 (\($stop), \($h)h\($m)m)"' "$nearest_dep" 2>/dev/null > /tmp/flights_list_$$
            while read -r line; do
                section="${section}${line}\n"
            done < /tmp/flights_list_$$
            rm -f /tmp/flights_list_$$
            has_data=true
        fi

        # 2-2. 7일 이내 가격 하락 항공권 (출발일별 price_history)
        for price_file in "$route_dir"/*.json; do
            [ -f "$price_file" ] || continue
            local file_fetch=$(jq -r '.fetch_date // ""' "$price_file" 2>/dev/null)
            [ "$file_fetch" = "$fetch_date" ] || continue

            local dep_date=$(jq -r '.departure_date' "$price_file")
            local dep_fmt=$(date -d "$dep_date" '+%m/%d' 2>/dev/null)
            local price=$(jq -r '.price // 0' "$price_file")
            local first_h=$(jq -r '.price_history[-7:][0][1] // empty' "$price_file" 2>/dev/null)
            local last_h=$(jq -r '.price_history[-1][1] // empty' "$price_file" 2>/dev/null)
            local airline=$(jq -r '.best_flights[0].flights[0].airline // "?"' "$price_file" 2>/dev/null)
            local stops=$(jq '.best_flights[0].layovers | length' "$price_file" 2>/dev/null)
            local dur=$(jq -r '.best_flights[0].total_duration // 0' "$price_file" 2>/dev/null)

            if [ -n "$first_h" ] && [ -n "$last_h" ]; then
                # 5% 이상 하락만
                local threshold=$((first_h * 95 / 100))
                if [ "$last_h" -lt "$threshold" ]; then
                    local pct=$(echo "$first_h $last_h" | awk '{printf "%.0f", ($2-$1)/$1*100}')
                    local price_str=$(echo "$last_h" | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta' | sed 's/$/원/')
                    local prev_str=$(echo "$first_h" | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta' | sed 's/$/원/')
                    local icon=""
                    [ "$last_h" -lt "$bench_low" ] && icon=" 🟢"
                    local stops_label="직항"
                    [ "$stops" -ge 1 ] && stops_label="경유${stops}회"
                    drop_report="${drop_report} • ${route_name} ${dep_fmt}출발: ${prev_str} → ${price_str} (${pct}%↓) | ${airline} ${stops_label} $((dur/60))h$((dur%60))m${icon}\n"
                fi
            fi
        done

        if [ "$has_data" = true ]; then
            main_report="${main_report}${section}\n"
            route_count=$((route_count + 1))
        fi
    done

    # 최종 조합: 하락만 반환 (기본 노선 목록 제거)
    local result=""
    if [ -n "$drop_report" ]; then
        result="📉 가격 하락 (7일 전 대비)\n${drop_report}"
    fi
    echo "$result"
}

# 실행 주기 정보
get_flight_cycle_info() {
    local flight_state="$WORKSPACE/memory/flights/state/last-run.json"
    [ -f "$flight_state" ] || return

    local cycle=$(grep -oP 'CYCLE_DAYS=\d+' "$WORKSPACE/scripts/flight-monitor.sh" | cut -d= -f2)
    cycle=${cycle:-6}
    local last_full=$(jq -r '.last_full_scan // ""' "$flight_state" 2>/dev/null)
    [ -z "$last_full" ] && return

    local last_epoch=$(date -d "$last_full" '+%s' 2>/dev/null || echo "0")
    local today_epoch=$(date '+%s')
    local days_left=$((cycle - (today_epoch - last_epoch) / 86400))
    echo "(다음: ${days_left}일 후)"
}

# 메인 로직
FLIGHT_CYCLE_INFO=$(get_flight_cycle_info)

if [ -f "$FLIGHTS_DEALS/$TODAY.md" ]; then
    FLIGHT_DEALS="$(build_flight_report "$TODAY")"
elif [ -f "$FLIGHTS_STATE" ]; then
    LAST_FETCH=$(jq -r '.last_full_scan // ""' "$FLIGHTS_STATE" 2>/dev/null)
    if [ -n "$LAST_FETCH" ] && [ -d "$WORKSPACE/memory/flights/prices" ]; then
        LAST_FETCH_FMT=$(date -d "$LAST_FETCH" '+%m/%d' 2>/dev/null || echo "$LAST_FETCH")
        FLIGHT_DEALS="$(build_flight_report "$LAST_FETCH")"
    else
        FLIGHT_DEALS=""
    fi
else
    FLIGHT_DEALS=""
fi

# ============================================================================
# 6. OpenClaw 기능 활용 추천 (D2: 조건부)
# ============================================================================
log "INFO" "[6/8] Generating feature recommendations..."

FEATURE_PROPOSALS="$WORKSPACE/reference/feature-proposals.yaml"
FEATURE_OUTPUT="$WORKSPACE/reference/openclaw-features.md"
FEATURE_RECOMMEND=""

if [ -f "$FEATURE_PROPOSALS" ]; then
    # 최근 JOB 패턴 분석 (최근 7일)
    RECENT_JOBS=$(grep -E "^### JOB-" "$JOB_COMPLETED" 2>/dev/null | head -20 || true)
    JOB_KEYWORDS=""
    
    # 키워드 추출 (뉴스, 코딩, 이미지 등)
    if echo "$RECENT_JOBS" | grep -qi "뉴스\|수집\|스크래핑"; then
        JOB_KEYWORDS="$JOB_KEYWORDS 뉴스,수집,스크래핑"
    fi
    if echo "$RECENT_JOBS" | grep -qi "코딩\|개발\|IDE"; then
        JOB_KEYWORDS="$JOB_KEYWORDS 코딩,IDE,개발"
    fi
    if echo "$RECENT_JOBS" | grep -qi "이미지\|시각화"; then
        JOB_KEYWORDS="$JOB_KEYWORDS 이미지,시각화"
    fi
    
    # 추천 기능 선택
    RECOMMEND_FEATURES=""
    
    # browser 툴 추천 (뉴스 관련 JOB이 있으면 우선)
    if echo "$JOB_KEYWORDS" | grep -q "뉴스\|수집"; then
        RECOMMEND_FEATURES="$RECOMMEND_FEATURES\n• **browser 툴**: 뉴스 수집 시 웹 페이지 이미지 가져오기 (최근 뉴스 관련 작업 기반 추천)"
    fi
    
    # ACP 하네스 추천 (코딩 관련 JOB이 있으면)
    if echo "$JOB_KEYWORDS" | grep -q "코딩\|IDE"; then
        RECOMMEND_FEATURES="$RECOMMEND_FEATURES\n• **ACP 하네스**: IDE 연동으로 코딩 작업 효율화 (최근 코딩 관련 작업 기반 추천)"
    fi
    
    # 기본 추천 (키워드 없으면)
    if [ -z "$RECOMMEND_FEATURES" ]; then
        RECOMMEND_FEATURES="\n• **browser 툴**: 웹 스크래핑, UI 테스트\n• **ACP 하네스**: IDE 연동 (설정 필요)"
    fi
    
    # 카테고리별 기능
    IMMEDIATE=$(grep -A5 "category: immediate" "$FEATURE_PROPOSALS" 2>/dev/null | grep "name:" | head -3 || echo "browser 툴, sessions_spawn, message")
    SETUP=$(grep -A5 "category: setup_required" "$FEATURE_PROPOSALS" 2>/dev/null | grep "name:" | head -1 || echo "ACP 하네스")
    ERROR=$(grep -A3 "category: error" "$FEATURE_PROPOSALS" 2>/dev/null | grep "name:" | head -2 || echo "nodes, devices")
    
    if [ "$FEATURE_UNUSED" -gt 0 ]; then
        FEATURE_RECOMMEND="\n## 🔌 기능 활용 추천\n\n### 추천 (최근 작업 기반)\n$(echo -e "$RECOMMEND_FEATURES")\n\n### 즉시 활용 가능\n• browser 툴: 웹 스크래핑, UI 테스트\n• sessions_spawn: 서브에이전트 실행\n\n### 설정 필요\n• ACP 하네스: openclaw.json 설정 후 IDE 연동\n\n### 오류\n• nodes/devices: 플러그인 설정 오류 (JOB-840에서 해결 예정)\n"
    else
        FEATURE_RECOMMEND=""
    fi

# features.md 업데이트 타임스탬프
if [ -f "$FEATURE_OUTPUT" ]; then
    sed -i "s/_Last updated: .*/_Last updated: $TODAY_/" "$FEATURE_OUTPUT" 2>/dev/null || true
fi
fi

# ============================================================================
# 7. 기술 뉴스 요약
# ============================================================================
log "INFO" "[7/8] Fetching tech news summary......"

if [ -f "$LATEST_NEWS" ]; then
    NEWS_COUNT=$(grep "^- \[" "$LATEST_NEWS" | wc -l | tr -d ' ')
    NEWS_TOP3=$(grep "^- \[" "$LATEST_NEWS" | head -3 | sed 's/^- \[/• [/' | sed 's/\](.*//' || true)
    TECH_COUNT="$NEWS_COUNT"
else
    NEWS_COUNT=0
    TECH_COUNT=0
    NEWS_TOP3="• 없음"
fi

# ============================================================================
# 리포트 생성
# ============================================================================
log "INFO" "Generating daily report..."

# Wiki 배경지식: 제거 (거의 매칭 안 됨)
WIKI_CONTEXT=""

# 한 줄 요약: 항공권 하락 수 계산
FLIGHT_DROP_COUNT=0
if echo "$FLIGHT_DEALS" | grep -q "📉"; then
    FLIGHT_DROP_COUNT=$(echo "$FLIGHT_DEALS" | grep "📉" -A 10 | grep " • " | wc -l | tr -d ' ')
fi
FLIGHT_DROP_COUNT=${FLIGHT_DROP_COUNT:-0}

SUMMARY_LINE="📋 대기 ${PENDING_NOW}건 | 완료 ${COMPLETED_TODAY}건 | 뉴스 ${TECH_COUNT}건 | ✈️ 하락 ${FLIGHT_DROP_COUNT}건"

# D1: 야간 작업 섹션 조건부 출력
OVERNIGHT_SECTION=""
if [ "$OVERNIGHT_COUNT" -gt 0 ]; then
    OVERNIGHT_SECTION="## 🌙 야간 추가 작업 (${OVERNIGHT_COUNT}개)
"
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            # line 형식: "### JOB-416: 일일 리포트 개선..."
            # 제목만 추출
            RAW_TITLE=$(echo "$line" | sed 's/^### //')
            # 30자(한글 10글자)로 제한 - cut 대신 awk 사용
            JOB_TITLE=$(echo "$RAW_TITLE" | awk '{print substr($0, 1, 50)}')
            if [ -n "$JOB_TITLE" ]; then
                OVERNIGHT_SECTION="${OVERNIGHT_SECTION}• ${JOB_TITLE}
"
            fi
        fi
    done <<< "$OVERNIGHT_JOBS"
fi

# D1: 우선순위 작업 섹션 조건부 출력
PRIO_SECTION=""
if [ "$PRIO_COUNT" -gt 0 ]; then
    PRIO_SECTION="## ⭐ 우선순위 작업 (${PRIO_COUNT}개)
"
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            # line 형식: "### JOB-416: 일일 리포트 개선..."
            JOB_ID=$(echo "$line" | grep -oP 'JOB-\d+' || echo "Unknown")
            # 우선순위 추출
            PRIO=$(grep -A6 "^### ${JOB_ID}:" "$JOB_QUEUE" 2>/dev/null | grep "우선순위" | sed 's/.*: //' | awk '{print $1}' || echo "Low")
            # 제목 추출 (### 제거)
            RAW_TITLE=$(echo "$line" | sed 's/^### //')
            # 40자로 제한
            JOB_TITLE=$(echo "$RAW_TITLE" | awk '{print substr($0, 1, 40)}')
            if [ -n "$JOB_TITLE" ]; then
                PRIO_SECTION="${PRIO_SECTION}• ${JOB_TITLE} (${PRIO})
"
            fi
        fi
    done <<< "$PRIO_JOBS"
fi

# Schedule 섹션: 요약 + 예외만
if [ "$SCHEDULE_OK" -gt 0 ] || [ -n "$SCHEDULE_DETAILS" ]; then
    SCHEDULE_SECTION="## ⏰ Schedule (${SCHEDULE_RUNS}회)\n"
    if [ "$SCHEDULE_OK" -gt 0 ]; then
        SCHEDULE_SECTION="${SCHEDULE_SECTION}• 총 ${SCHEDULE_OK}개 정상\n"
    fi
    SCHEDULE_SECTION="${SCHEDULE_SECTION}${SCHEDULE_DETAILS}"
else
    SCHEDULE_SECTION=""
fi

# 이미지 섹션: 과적 경고 + 에이전트별 생성 이력 (JOB-981)
IMAGE_SECTION=""
if [ "$QUEUE_PENDING" -gt 3000 ]; then
    IMAGE_SECTION="## 🖼️ 이미지
• 분석 큐 대기: ${QUEUE_PENDING}개 (과적 경고)
"
fi

# 이미지 생성 에이전트별 이력 요약 (JOB-981)
GEN_LOG="$WORKSPACE_IMAGE/projects/lora-test/GENERATION_LOG.jsonl"
SEQ_LOG="$WORKSPACE_IMAGE/logs/sequence-audit.jsonl"
if [ -f "$GEN_LOG" ] && command -v jq >/dev/null; then
    # 오늘 생성 이력 통계
    TODAY_GEN=$(jq -c "select(.timestamp | startswith(\"$TODAY\"))" "$GEN_LOG" 2>/dev/null | wc -l)
    if [ "$TODAY_GEN" -gt 0 ] 2>/dev/null; then
        # 에이전트별 통계
        AGENT_STATS=$(jq -r "select(.timestamp | startswith(\"$TODAY\")) | .requester // \"unknown\"" "$GEN_LOG" 2>/dev/null | sort | uniq -c | sort -rn)
        # 성공/실패 통계
        SUCCESS_COUNT=$(jq -c "select(.timestamp | startswith(\"$TODAY\")) | select(.result==\"success\")" "$GEN_LOG" 2>/dev/null | wc -l)
        FAIL_COUNT=$(jq -c "select(.timestamp | startswith(\"$TODAY\")) | select(.result==\"failed\" or .result==\"error\")" "$GEN_LOG" 2>/dev/null | wc -l)
        # LoRA별 생성 수 (상위 5개)
        LORA_STATS=$(jq -r "select(.timestamp | startswith(\"$TODAY\")) | .lora" "$GEN_LOG" 2>/dev/null | sort | uniq -c | sort -rn | head -5)

        if [ -z "$IMAGE_SECTION" ]; then
            IMAGE_SECTION="## 🖼️ 이미지 생성 이력

"
        else
            IMAGE_SECTION="${IMAGE_SECTION}
"
        fi
        IMAGE_SECTION="${IMAGE_SECTION}• 금일 생성: ${TODAY_GEN}건 (성공 ${SUCCESS_COUNT}, 실패 ${FAIL_COUNT})

"
        IMAGE_SECTION="${IMAGE_SECTION}**에이전트별:**
"
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            count=$(echo "$line" | awk '{print $1}')
            agent=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ *//')
            IMAGE_SECTION="${IMAGE_SECTION}- ${agent}: ${count}건
"
        done <<< "$AGENT_STATS"
        IMAGE_SECTION="${IMAGE_SECTION}
**LoRA별 (상위 5):**
"
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            count=$(echo "$line" | awk '{print $1}')
            lora=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ *//')
            IMAGE_SECTION="${IMAGE_SECTION}- ${lora}: ${count}건
"
        done <<< "$LORA_STATS"

        # sequence-audit 이력 (있으면, JOB-982 통합)
        if [ -f "$SEQ_LOG" ]; then
            TODAY_SEQ=$(jq -c "select(.timestamp | startswith(\"$TODAY\"))" "$SEQ_LOG" 2>/dev/null)
            if [ -n "$TODAY_SEQ" ]; then
                SEQ_SPAWNS=$(echo "$TODAY_SEQ" | jq -r 'select(.action=="spawn")' 2>/dev/null | wc -l)
                SEQ_COMPLETES=$(echo "$TODAY_SEQ" | jq -r 'select(.action=="sequence_complete")' 2>/dev/null | wc -l)
                SEQ_TIMEOUTS=$(echo "$TODAY_SEQ" | jq -r 'select(.action=="timeout")' 2>/dev/null | wc -l)
                SEQ_RECOVERIES=$(echo "$TODAY_SEQ" | jq -r 'select(.action=="recovery" and .status=="success")' 2>/dev/null | wc -l)
                if [ "$SEQ_SPAWNS" -gt 0 ] || [ "$SEQ_COMPLETES" -gt 0 ] || [ "$SEQ_TIMEOUTS" -gt 0 ] || [ "$SEQ_RECOVERIES" -gt 0 ]; then
                    IMAGE_SECTION="${IMAGE_SECTION}
**sequence-audit:** ${SEQ_SPAWNS} spawns, ${SEQ_RECOVERIES} 복구, ${SEQ_COMPLETES} 완료, ${SEQ_TIMEOUTS} 타임아웃
"
                fi
            fi
        fi
    fi
fi

# 항공권 섹션: 하락만 표시
if [ -n "$FLIGHT_DEALS" ] && echo "$FLIGHT_DEALS" | grep -q "📉"; then
    # 하락 부분만 추출
    FLIGHT_DROPS_ONLY=$(echo "$FLIGHT_DEALS" | sed -n '/📉 가격 하락/,$p')
    if [ -n "$FLIGHT_DROPS_ONLY" ]; then
        FLIGHT_SECTION="## ✈️ 항공권 특가 ${FLIGHT_CYCLE_INFO}

${FLIGHT_DROPS_ONLY}"
    else
        FLIGHT_SECTION=""
    fi
else
    FLIGHT_SECTION=""
fi

# 기술 뉴스 섹션 조건부
if [ "$TECH_COUNT" -gt 0 ]; then
    NEWS_SECTION="## 📰 기술 뉴스: ${NEWS_COUNT}개
${NEWS_TOP3}"
else
    NEWS_SECTION=""
fi

# Guide 후보 섹션 조건부
GUIDE_SECTION=""
if [ "$TECH_GUIDE" -gt 0 ] && [ -f "$GUIDE_CANDIDATES_DIR/$TODAY.txt" ]; then
    GUIDE_SECTION="## 🔍 Guide 후보 (${TECH_GUIDE}개)
"
    while IFS='|' read -r type title url score; do
        if [ -n "$score" ]; then
            GUIDE_SECTION="${GUIDE_SECTION}• [$title]($url) (score: $score)
"
        else
            GUIDE_SECTION="${GUIDE_SECTION}• [$title]($url)
"
        fi
    done < "$GUIDE_CANDIDATES_DIR/$TODAY.txt"
    GUIDE_SECTION="${GUIDE_SECTION}
_에이전트가 web_fetch로 내용 확인 후 reference/에 추가_\n"
fi

# 기능 활용 섹션: 제거 (정적 내용, 정보량 없음)
FEATURE_SECTION=""
# Subconscious 섹션 조건부
SUBCONSCIOUS_IDEAS=$(get_subconscious_ideas)
SUBCONSCIOUS_SECTION=""
if [ -n "$SUBCONSCIOUS_IDEAS" ]; then
    SUBCONSCIOUS_SECTION="## 💡 Subconscious 아이디어
${SUBCONSCIOUS_IDEAS}"
fi

# 작업 큐 섹션: 변동 있으면 상세, 없으면 요약
if [ "$DELTA_STR" = "0" ] && [ "$NEW_TODAY" -eq 0 ] && [ "$COMPLETED_TODAY" -eq 0 ]; then
    QUEUE_SECTION="## 📋 작업 큐
• 변동 없음 (대기 ${PENDING_NOW}건)"
else
    QUEUE_SECTION="## 📋 작업 큐 (하루 변화)
• 신규 등록: ${NEW_TODAY}개 | 완료: ${COMPLETED_TODAY}개 | 대기: ${PENDING_NOW}개 (${DELTA_STR})"
    # 완료된 작업 상세 추가
    if [ -n "$COMPLETED_DETAIL" ]; then
        QUEUE_SECTION="${QUEUE_SECTION}

오늘 완료:
${COMPLETED_DETAIL}"
    fi
fi

# D3: 액션 아이템 섹션 (작업 큐 다음에 위치)
ACTION_ITEMS=""
if [ "$FLIGHT_DROP_COUNT" -gt 0 ]; then
    ACTION_ITEMS="${ACTION_ITEMS}• ✈️ 가격 하락 ${FLIGHT_DROP_COUNT}건 - 예약 고려\n"
fi
if [ "$MD_TOTAL_ISSUES" -gt 0 ]; then
    ACTION_ITEMS="${ACTION_ITEMS}• 📝 MD 파일 이슈 ${MD_TOTAL_ISSUES}건 - 검토 필요\n"
fi
if [ "$QUEUE_PENDING" -gt 3000 ]; then
    ACTION_ITEMS="${ACTION_ITEMS}• 🖼️ 이미지 분석 큐 ${QUEUE_PENDING}건 - 과적, 비우기 고려\n"
fi
if [ "$TECH_GUIDE" -gt 0 ]; then
    ACTION_ITEMS="${ACTION_ITEMS}• 🔍 Guide 후보 ${TECH_GUIDE}건 - 리뷰 필요\n"
fi
if [ "$FEATURE_UNUSED" -gt 0 ]; then
    ACTION_ITEMS="${ACTION_ITEMS}• 🔌 미활용 기능 ${FEATURE_UNUSED}개 - 활용 방법 검토\n"
fi

# 액션 아이템 섹션 생성
if [ -n "$ACTION_ITEMS" ]; then
    ACTION_SECTION="## ⚡ 확인 필요\n$(echo -e "$ACTION_ITEMS")"
else
    ACTION_SECTION=""
fi

cat > "$REPORT_FILE" << EOF
# 📊 매일 리포트 - $TODAY

_생성 시간: ${NOW}_

${SUMMARY_LINE}

---

${QUEUE_SECTION}

EOF

# 액션 아이템 섹션 추가 (있을 때만)
if [ -n "$ACTION_SECTION" ]; then
    echo -e "$ACTION_SECTION" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

# 야간 작업 섹션 추가 (있을 때만)
if [ -n "$OVERNIGHT_SECTION" ]; then
    echo -e "$OVERNIGHT_SECTION" >> "$REPORT_FILE"
fi

# 우선순위 작업 섹션 추가 (있을 때만)
if [ -n "$PRIO_SECTION" ]; then
    echo -e "$PRIO_SECTION" >> "$REPORT_FILE"
fi

# Schedule 섹션 추가 (있을 때만)
if [ -n "$SCHEDULE_SECTION" ]; then
    echo "" >> "$REPORT_FILE"
    echo -e "$SCHEDULE_SECTION" >> "$REPORT_FILE"
fi

# 이미지 생성 이력 섹션 (있을 때만)
if [ -n "$IMAGE_SECTION" ]; then
    echo "" >> "$REPORT_FILE"
    echo -e "$IMAGE_SECTION" >> "$REPORT_FILE"
fi

# 항공권 섹션 추가 (있을 때만)
if [ -n "$FLIGHT_SECTION" ]; then
    echo "" >> "$REPORT_FILE"
    echo "---" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo -e "$FLIGHT_SECTION" >> "$REPORT_FILE"
fi

# 뉴스 섹션 추가 (있을 때만)
if [ -n "$NEWS_SECTION" ]; then
    echo "" >> "$REPORT_FILE"
    echo "---" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo -e "$NEWS_SECTION" >> "$REPORT_FILE"
fi

# 프로바이더 토큰 섹션 (JOB-1030)
PROVIDER_STATE="$MEMORY_DIR/provider-token-usage.json"
if [ -f "$PROVIDER_STATE" ] && command -v jq &>/dev/null; then
    echo "" >> "$REPORT_FILE"
    echo "---" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "## 📊 프로바이더 토큰 사용량" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    PROVIDER_NAMES=$(jq -r '.providers | keys[]' "$PROVIDER_STATE" 2>/dev/null)
    while IFS= read -r pname; do
        [ -z "$pname" ] && continue
        TOTAL_K=$(jq -r ".providers[\"$pname\"].total_tokens // 0" "$PROVIDER_STATE" 2>/dev/null)
        TOTAL_K=$(echo "$TOTAL_K" | awk '{printf "%.0f", $1/1000}')
        THRESH_K=$(jq -r ".providers[\"$pname\"].threshold // 0" "$PROVIDER_STATE" 2>/dev/null)
        THRESH_K=$(echo "$THRESH_K" | awk '{printf "%.0f", $1/1000}')
        CYCLE=$(jq -r ".providers[\"$pname\"].reset_cycle // \"?\"" "$PROVIDER_STATE" 2>/dev/null)
        LAST_RPT=$(jq -r ".providers[\"$pname\"].last_reported_pct // \"\"" "$PROVIDER_STATE" 2>/dev/null)
        # Alert if approaching threshold
        PCT=0
        if [ "$THRESH_K" -gt 0 ] 2>/dev/null; then
            PCT=$(echo "$TOTAL_K $THRESH_K" | awk '{printf "%.0f", $1/$2*100}')
        fi
        ALERT_FLAG=""
        if [ "$PCT" -ge 80 ] 2>/dev/null; then
            ALERT_FLAG=" ⚠️"
        fi
        RPT_INFO=""
        if [ -n "$LAST_RPT" ]; then
            RPT_INFO=" (사용자 리포트: $LAST_RPT)"
        fi
        echo "• ${pname}: ${TOTAL_K}K / ${THRESH_K}K (${CYCLE})${ALERT_FLAG}${RPT_INFO}" >> "$REPORT_FILE"
    done <<< "$PROVIDER_NAMES"
fi

# OpenClaw 크론잡 토큰 소모 (JOB-1184)
RUNS_DIR="/home/bot/.openclaw/cron/runs"
JOBS_FILE="/home/bot/.openclaw/cron/jobs.json"
SEVEN_DAYS_AGO=$(date -d "7 days ago" +%s)
TOTAL_TOKENS=0
TOKEN_LINES=""

if [ -d "$RUNS_DIR" ]; then
    for run_file in "$RUNS_DIR"/*.jsonl; do
        [ -f "$run_file" ] || continue
        job_id=$(basename "$run_file" .jsonl)
        
        result=$(python3 << PYEOF
import json
seven_days_ago = $SEVEN_DAYS_AGO
count = 0; total = 0; ok = 0; fail = 0
try:
    with open("$run_file") as f:
        for line in f:
            line = line.strip()
            if not line: continue
            try:
                d = json.loads(line)
                ts = d.get('ts', 0) / 1000 if d.get('ts') else 0
                if ts >= seven_days_ago:
                    count += 1
                    u = d.get('usage', {})
                    total += u.get('total_tokens', 0) or (u.get('input_tokens', 0) + u.get('output_tokens', 0))
                    if d.get('status') == 'ok': ok += 1
                    else: fail += 1
            except: pass
    if count > 0:
        print(f"{count}\t{total}\t{ok}\t{fail}")
except: pass
PYEOF
        ) || continue
        
        [ -z "$result" ] && continue
        
        run_count=$(echo "$result" | cut -f1)
        total_tokens=$(echo "$result" | cut -f2)
        ok_count=$(echo "$result" | cut -f3)
        fail_count=$(echo "$result" | cut -f4)
        
        job_name=$(python3 -c "
import json
try:
    with open('$JOBS_FILE') as f:
        data = json.load(f)
    for j in data.get('jobs', []):
        if j.get('id') == '$job_id':
            print(j.get('name', 'unknown')); break
    else: print('unknown')
except: print('unknown')
" 2>/dev/null)
        
        avg_tokens=$((total_tokens / run_count))
        TOTAL_TOKENS=$((TOTAL_TOKENS + total_tokens))
        TOKEN_LINES="${TOKEN_LINES}• ${job_name}: ${run_count}회, ${total_tokens}토큰 (avg ${avg_tokens}/회) [✅${ok_count} / ❌${fail_count}]\n"
    done
fi

if [ -n "$TOKEN_LINES" ]; then
    echo "" >> "$REPORT_FILE"
    echo "---" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "## 📈 크론잡 토큰 소모 (최근 7일)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo -e "$TOKEN_LINES" >> "$REPORT_FILE"
    echo "총 ${TOTAL_TOKENS}토큰" >> "$REPORT_FILE"
fi

# 시스템 섹션 (항상)
echo "" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "## 💾 시스템" >> "$REPORT_FILE"
echo "• 디스크: $(df -h "$WORKSPACE" | awk 'NR==2 {print $5}' | tr -d '%')% | 메모리: $(du -sh "$MEMORY_DIR" 2>/dev/null | awk '{print $1}')" >> "$REPORT_FILE"

# 메모리 시스템 요약 (JOB-896)
MEMORY_HEALTH_FILE="$MEMORY_DIR/metrics/memory-health.json"
if [[ -f "$MEMORY_HEALTH_FILE" ]]; then
    MEM_DISTILL=$(jq -r '"\(.distillation.promoted)/\(.distillation.promotion_candidates)"' "$MEMORY_HEALTH_FILE" 2>/dev/null || echo "?")
    MEM_WIKI=$(jq -r '.wiki.total_pages' "$MEMORY_HEALTH_FILE" 2>/dev/null || echo "?")
    MEM_DREAM=$(jq -r '.dreaming.short_term_recall_entries' "$MEMORY_HEALTH_FILE" 2>/dev/null || echo "?")
    echo "• 🧠 메모리 시스템: 증류 ${MEM_DISTILL} | 위키 ${MEM_WIKI}p | 드리밍 ${MEM_DREAM}캔디" >> "$REPORT_FILE"
fi

# 이미지 에이전트 요약 (JOB-897, JOB-919)
IMAGE_HEALTH_FILE="$MEMORY_DIR/metrics/image-health.json"
PROGRESS_FILE="$WORKSPACE_IMAGE/PROGRESS.json"
if [[ -f "$IMAGE_HEALTH_FILE" ]]; then
    IMG_GEN=$(jq -r '.productivity.images_generated_today' "$IMAGE_HEALTH_FILE" 2>/dev/null || echo "?")
    IMG_LORA=$(jq -r '"\(.utilization.active_loras)/\(.utilization.total_loras)"' "$IMAGE_HEALTH_FILE" 2>/dev/null || echo "?")
    IMG_MISSING=$(jq -r '.issues.missing_files' "$IMAGE_HEALTH_FILE" 2>/dev/null || echo "?")
    IMG_SCORE=$(jq -r '.quality.avg_overall' "$IMAGE_HEALTH_FILE" 2>/dev/null || echo "N/A")
    # 점수 소수점 1자리 반올림
    if [ "$IMG_SCORE" != "N/A" ] && command -v awk &>/dev/null; then
        IMG_SCORE=$(echo "$IMG_SCORE" | awk '{printf "%.1f", $1}')
    fi
    # PROGRESS.json 완료율 (JOB-919)
    IMG_PROGRESS=""
    if [ -f "$PROGRESS_FILE" ] && command -v jq &>/dev/null; then
        PROGRESS_TOTAL=$(jq '[.lora_data // {} | to_entries[] | .value.scenes // [] | length] | add' "$PROGRESS_FILE" 2>/dev/null || echo "0")
        PROGRESS_DONE=$(jq '[.lora_data // {} | to_entries[] | .value.scenes // [] | .[] | select(.status=="complete" or .status=="completed") ] | length' "$PROGRESS_FILE" 2>/dev/null || echo "0")
        if [ "$PROGRESS_TOTAL" -gt 0 ] 2>/dev/null; then
            IMG_PROGRESS=" | 진행 ${PROGRESS_DONE}/${PROGRESS_TOTAL}"
        fi
    fi
    echo "• 🎨 이미지: 일 ${IMG_GEN}건 | LoRA ${IMG_LORA} | 평균 ${IMG_SCORE}점${IMG_PROGRESS} | MISSING ${IMG_MISSING}" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Subconscious 섹션 추가 (있을 때만)
if [ -n "$SUBCONSCIOUS_SECTION" ]; then
    echo -e "$SUBCONSCIOUS_SECTION" >> "$REPORT_FILE"
fi

if [ -n "$SUBCONSCIOUS_SECTION" ]; then
    echo "" >> "$REPORT_FILE"
fi

# 스킬 검증 상태 (JOB-906)
log "INFO" "Checking skill validation status..."

SKILL_STATE="${MEMORY_DIR}/skill-validator-state.json"
CONTENT_STATE="${MEMORY_DIR}/skill-content-validator-state.json"
SKILL_STATIC_ISSUES=0
SKILL_CONTENT_ISSUES=0

if [ -f "$SKILL_STATE" ]; then
    SKILL_STATIC_ISSUES=$(jq -r '.total_issues // 0' "$SKILL_STATE" 2>/dev/null || echo "0")
fi

if [ -f "$CONTENT_STATE" ]; then
    SKILL_CONTENT_ISSUES=$(jq -r '.total_issues // 0' "$CONTENT_STATE" 2>/dev/null || echo "0")
fi

if [ "$SKILL_STATIC_ISSUES" -gt 0 ] || [ "$SKILL_CONTENT_ISSUES" -gt 0 ]; then
    echo "" >> "$REPORT_FILE"
    echo "### ⚠️ 스킬 검증 이슈" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "| 레이어 | 이슈 수 | 마지막 검증 |" >> "$REPORT_FILE"
    echo "|-------|---------|----------|" >> "$REPORT_FILE"
    echo "| Layer 1 (정적) | ${SKILL_STATIC_ISSUES}개 | $(jq -r '.last_run // "-"' "$SKILL_STATE" 2>/dev/null || '-') |" >> "$REPORT_FILE"
    echo "| Layer 2 (구조) | ${SKILL_CONTENT_ISSUES}개 | $(jq -r '.last_run // "-"' "$CONTENT_STATE" 2>/dev/null || '-') |" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "→ 이슈 상세: memory/logs/skill-content-validation.log" >> "$REPORT_FILE"
    log "INFO" "Skill validation issues: static=${SKILL_STATIC_ISSUES}, content=${SKILL_CONTENT_ISSUES}"
else
    log "INFO" "Skill validation: OK"
fi

# 크로스 워크스페이스 daily note 백업 (JOB-908)
log "INFO" "Checking cross-workspace daily notes..."

TODAY_UTC=$(date -u +"%Y-%m-%d")
TODAY_KST=$(TZ=Asia/Seoul date +"%Y-%m-%d")
if [ "$TODAY_UTC" != "$TODAY_KST" ]; then
    CHECK_DATES="$TODAY_UTC $TODAY_KST"
else
    CHECK_DATES="$TODAY_UTC"
fi

BACKUP_COUNT=0
MISSING_NOTES=""

if command -v python3 &>/dev/null; then
    RESULT=$(python3 << 'PYEOF'
import json, os, glob, datetime

targets = [
    ("discord_agent", "/home/bot/.openclaw/agents/discord_agent/sessions", "/home/bot/.openclaw/workspace_discord"),
    ("group_agent", "/home/bot/.openclaw/agents/group_agent/sessions", "/home/bot/.openclaw/workspace_group"),
    ("writer_agent", "/home/bot/.openclaw/agents/writer_agent/sessions", "/home/bot/.openclaw/workspace_writer"),
    ("image_agent", "/home/bot/.openclaw/agents/image_agent/sessions", "/home/bot/.openclaw/workspace_image"),
    ("reviewer", "/home/bot/.openclaw/agents/reviewer/sessions", "/home/bot/.openclaw/workspace_reviewer"),
    ("image_lab_agent", "/home/bot/.openclaw/agents/image_lab_agent/sessions", "/home/bot/.openclaw/workspace_image_lab"),
]

results = []

for agent_name, sessions_dir, workspace_dir in targets:
    if not os.path.isdir(workspace_dir):
        continue
    memory_dir = os.path.join(workspace_dir, "memory")
    if not os.path.isdir(memory_dir):
        continue
    kst_now = datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=9)))
    date_str = kst_now.strftime("%Y-%m-%d")
    daily_path = os.path.join(memory_dir, f"{date_str}.md")
    if os.path.exists(daily_path):
        continue
    traj_files = sorted(glob.glob(os.path.join(sessions_dir, "*.trajectory.jsonl")), reverse=True)
    if not traj_files:
        continue
    entries = []
    for tf in traj_files[:5]:
        try:
            with open(tf) as f:
                for line in f:
                    try:
                        d = json.loads(line)
                        ts = d.get("ts", "")
                        if ts.startswith(date_str):
                            entries.append(d)
                    except:
                        pass
        except:
            pass
    if not entries:
        continue
    sessions_today = [e for e in entries if e.get("type") == "session.started"]
    all_texts = []
    for e in entries:
        if e.get("type") == "trace.artifacts":
            texts = e.get("data", {}).get("assistantTexts", [])
            all_texts.extend(texts)
    if not sessions_today and not all_texts:
        continue
    note_lines = [f"# {date_str} Daily Note (auto-backup)", "", f"_Generated by daily-report.sh cross-workspace backup_", "", "## 활동 요약", "", f"- 세션 수: {len(sessions_today)}", f"- 응답 수: {len(all_texts)}", ""]
    if all_texts:
        note_lines.append("## 주요 응답")
        note_lines.append("")
        seen = set()
        for t in all_texts:
            t_short = t[:100]
            if t_short not in seen:
                seen.add(t_short)
                note_lines.append(f"- {t[:200]}")
        note_lines.append("")
    note_content = "\n".join(note_lines)
    try:
        with open(daily_path, "w") as f:
            f.write(note_content)
        results.append(f"{agent_name}: created {date_str}.md ({len(sessions_today)} sessions, {len(all_texts)} texts)")
    except Exception as e:
        results.append(f"{agent_name}: ERROR - {e}")

print("\n".join(results) if results else "")
PYEOF
)

    if [ -n "$RESULT" ]; then
        log "INFO" "Cross-workspace daily note backup:"
        log "INFO" "$RESULT"
        BACKUP_COUNT=$(echo "$RESULT" | wc -l)
        MISSING_NOTES="$RESULT"
    else
        log "INFO" "All agents have daily notes for today"
    fi
else
    log "WARN" "python3 not available, skipping cross-workspace daily note backup"
fi

# Daily Note 백업 결과를 리포트에 추가 (footer 앞)
if [ "$BACKUP_COUNT" -gt 0 ]; then
    echo "" >> "$REPORT_FILE"
    echo "### 📝 Daily Note 백업" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "$MISSING_NOTES" >> "$REPORT_FILE"
fi

# Footer
echo "" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"
echo "_자동 생성: daily-report.sh v3.3_" >> "$REPORT_FILE"

log "INFO" "Report saved to $REPORT_FILE"

# ============================================================================
# daily-state.json 업데이트
# ============================================================================
log "INFO" "Updating daily-state.json..."

if command -v jq &>/dev/null; then
    result=$(jq --arg date "$TODAY" \
       --argjson pending "$PENDING_NOW" \
       --argjson completed "$COMPLETED_TODAY" \
       --argjson newreg "$NEW_TODAY" \
       --argjson prev "$PENDING_NOW" \
       --arg updated "$NOW" \
       '.date = $date | .pending_count = $pending | .completed_today = $completed | .new_registrations = $newreg | .previous_pending = $prev | .last_updated = $updated' \
       "$STATE_FILE")
    atomic_write "$STATE_FILE" "$result"
else
    cat > "$STATE_FILE" << EOF
{
  "date": "$TODAY",
  "pending_count": $PENDING_NOW,
  "completed_today": $COMPLETED_TODAY,
  "new_registrations": $NEW_TODAY,
  "previous_pending": $PENDING_NOW,
  "last_updated": "$NOW"
}
EOF
fi

log "INFO" "daily-state.json updated"

# ============================================================================
# 사용자 알림
# ============================================================================
log "INFO" "Sending user notification..."

NOTIFY_SCRIPT="/home/bot/.hermes/scripts/notify-report.sh"
if [ -x "$NOTIFY_SCRIPT" ]; then
    "$NOTIFY_SCRIPT" || log "WARN" "notify-report.sh failed (non-critical)"
else
    log "WARN" "notify-report.sh not found or not executable"
fi

log "INFO" "========== Daily Report End =========="
log "INFO" "Report: $REPORT_FILE"

echo ""
echo "=========================================="
echo "매일 리포트 생성 완료"
echo "=========================================="
echo "📊 리포트: $REPORT_FILE"
echo "📋 신규: ${NEW_TODAY}개 | 완료: ${COMPLETED_TODAY}개 | 대기: ${PENDING_NOW}개 (${DELTA_STR})"

# Self-test
self_test() {
    echo "=== daily-report.sh Self-Test ==="
    
    # 1. 필수 디렉토리 확인
    echo -n "[1/4] memory 디렉토리 존재: "
    [[ -d "$WORKSPACE/memory" ]] && echo "OK" || echo "FAIL"
    
    # 2. daily-reports 디렉토리 확인
    echo -n "[2/4] daily-reports 디렉토리 존재: "
    [[ -d "$WORKSPACE/memory/daily-reports" ]] && echo "OK" || echo "FAIL"
    
    # 3. jq 명령 확인
    echo -n "[3/4] jq 명령 존재: "
    command -v jq &>/dev/null && echo "OK" || echo "FAIL"
    
    # 4. JOB-QUEUE.md 존재
    echo -n "[4/4] JOB-QUEUE.md 존재: "
    [[ -f "$WORKSPACE/JOB-QUEUE.md" ]] && echo "OK" || echo "FAIL"
    
    echo "=== Self-Test 완료 ==="
}

[[ "$1" == "--self-test" ]] && { self_test; exit 0; }
exit 0
