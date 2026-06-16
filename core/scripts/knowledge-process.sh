#!/bin/bash
#==============================================================================
# knowledge-process.sh - 지식 가공 cron (일일 요약)
#==============================================================================
#
# 매일 10:00 (Hermes cron, agent)
# 입력: knowledge/sources/ (전일 수집)
# 출력: wiki/daily-synthesis/ (주제별 요약)
#
#==============================================================================

set -uo pipefail

SOURCE_DIR="$HERMES_ROOT/knowledge/sources"
SYNTHESIS_DIR="$HERMES_ROOT/knowledge/wiki/daily-synthesis"
LOG_DIR="$HERMES_ROOT/logs"
LOG_FILE="$LOG_DIR/knowledge-process.log"

mkdir -p "$SYNTHESIS_DIR" "$LOG_DIR"

# 로깅
log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" >> "$LOG_FILE"
}

# 전일 수집 파일 확인
YESTERDAY=$(date -d "yesterday" '+%Y-%m-%d')
SOURCE_FILE="$SOURCE_DIR/$YESTERDAY.md"

if [ ! -f "$SOURCE_FILE" ]; then
    log "INFO" "전일 수집 파일 없음 - 처리 생략"
    echo "ℹ️ 전일 수집 파일 없음"
    exit 0
fi

# LLM 요약 요청 (prompt)
PROMPT="당신은 기술 지식 가공 전문가입니다.

다음은 $YESTERDAY에 수집된 기술 뉴스/자료 목록입니다.

$(cat "$SOURCE_FILE")

이 자료들을 분석하여 다음 형식으로 요약하세요:

## $YESTERDAY 기술 요약

### AI/ML/LLM
- (중요한 소식 요약, 최대 5개)

### 개발 도구/인프라
- (중요한 소식 요약, 최대 5개)

### 보안/기타
- (중요한 소식 요약, 최대 3개)

### 핵심 키워드
- (트렌드 키워드 10개)

중요도 기준으로 필터링하고, 간결하게 요약하세요."

# 출력 파일
OUTPUT_FILE="$SYNTHESIS_DIR/$YESTERDAY.md"

# LLM 호출 (Hermes API)
log "INFO" "지식 요약 시작: $SOURCE_FILE"

# TODO: Hermes API 호출로 요약 생성
# 현재는 임시 파일 생성
cat > "$OUTPUT_FILE" << EOF
# 지식 요약 ($YESTERDAY)

---

*TODO: LLM 요약 로직 구현 필요*

## 원본 수집 자료

$(head -50 "$SOURCE_FILE")
EOF

log "INFO" "출력: $OUTPUT_FILE"
echo "✅ 지식 가공 완료: $OUTPUT_FILE"
