#!/bin/bash
# review-loop.sh — 리뷰-수정-재리뷰 자동화
# 사용법: bash review-loop.sh <JOB_DIR> <design|exec> <max_attempts>
set -uo pipefail

JOB_DIR="${1:-}"
REVIEW_TYPE="${2:-design}"
MAX_ATTEMPTS="${3:-2}"
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib"
source "$LIB_DIR/night-lib.sh" 2>/dev/null || true

if [[ -z "$JOB_DIR" ]]; then
    echo "[LOOP] 사용법: $0 <JOB_DIR> <design|exec> [max_attempts]"
    exit 1
fi

echo "[LOOP] 리뷰-수정-재리뷰 시작 (최대 $MAX_ATTEMPTS회)"

# 리뷰 결과 파싱 (로뚱한 파싱)
parse_review_result() {
  local file="$1"
  local status=""
  
  # 패턴 1: [STATUS: PASS/FAIL/REV]
  status=$(grep -oiE '\[STATUS:\s*(PASS|FAIL|REV)\]' "$file" 2>/dev/null \
    | grep -oiE '(PASS|FAIL|REV)' \
    | head -1) || true
  
  # 패턴 2: 키워드 기반 폴백
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

# 수정 지침 추출
extract_fix_notes() {
  local file="$1"
  local notes="$1.fix-notes"
  
  # 수정 관련 내용 추출
  grep -iE '(수정|변경|필요|우려|주의|개선|리스크)' "$file" > "$notes" 2>/dev/null || true
  echo "$notes"
}

# 메인 루프
for ((attempt=1; attempt<=MAX_ATTEMPTS; attempt++)); do
  echo "[LOOP] 리뷰 시도 $attempt/$MAX_ATTEMPTS"
  
  # GLM 리뷰 실행
  bash "$LIB_DIR/../scripts/run-review.sh" "$JOB_DIR" "$REVIEW_TYPE" 2>&1
  
  # 결과 확인
  if [[ ! -f "$JOB_DIR/review-result-glm.md" ]]; then
    echo "[LOOP] 리뷰 결과 파일 없음 → 종료"
    exit 1
  fi
  
  # 결과 파싱
  status=$(parse_review_result "$JOB_DIR/review-result-glm.md")
  echo "[LOOP] 리뷰 결과: $status"
  
  case "$status" in
    PASS)
      echo "[LOOP] ✅ PASS - 다음 단계 진행"
      exit 0
      ;;
    FAIL)
      if [[ $attempt -lt $MAX_ATTEMPTS ]]; then
        # 수정 지침 추출
        notes=$(extract_fix_notes "$JOB_DIR/review-result-glm.md")
        echo "[LOOP] 🔧 수정 지침 추출: $notes"
        echo "[LOOP] 에이전트가 수정 후 재시도..."
        # 에이전트에게 수정 의뢰 (여기서 종료, 에이전트가 수정 후 다시 호출)
        exit 1
      else
        echo "[LOOP] 🚨 최대 시도 초과 ($MAX_ATTEMPTS) → 수동 검토 필요"
        exit 2
      fi
      ;;
    REV)
      echo "[LOOP] ⏸️ REV - 수동 승인 필요"
      exit 2
      ;;
  esac
done

echo "[LOOP] 완료"
exit 0
