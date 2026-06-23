#!/usr/bin/env bash
# 새로운 강의 슬라이드 생성 스크립트
# 사용법: bash new-lecture.sh 03 "Skills & Workflow" "Knowing vs Doing"
set -euo pipefail

NUM="${1:-}"
TITLE="${2:-}"
SUBTITLE="${3:-}"
TEMPLATE="docs/playground/courses/TEMPLATE.html"
OUTPUT="docs/playground/courses/lecture-${NUM}.html"

if [ ! -f "$TEMPLATE" ]; then
  echo "❌ 템플릿 없음: $TEMPLATE (먼저 생성 필요)"
  exit 1
fi

if [ -z "$NUM" ] || [ -z "$TITLE" ]; then
  echo "사용법: bash new-lecture.sh NN 'Title' 'Subtitle'"
  echo "  ex) bash new-lecture.sh 03 'Skills & Workflow' 'Knowing vs Doing'"
  exit 1
fi

# 패딩 처리
NUM_PAD=$(printf "%02d" "$NUM")

# 템플릿 복사
cp "$TEMPLATE" "$OUTPUT"

# 콘텐츠 교체
sed -i "s/{{LECTURE_NUM}}/$NUM_PAD/g" "$OUTPUT"
sed -i "s/{{LECTURE_TITLE}}/$TITLE/g" "$OUTPUT"
sed -i "s/{{LECTURE_SUBTITLE}}/$SUBTITLE/g" "$OUTPUT"
sed -i "s/{{LECTURE_URL_TITLE}}/$(echo "$TITLE" | sed 's/ /%20/g')/g" "$OUTPUT"

echo "✅ 강의 $NUM_PAD 생성: $OUTPUT"
echo "다음 단계: $OUTPUT 파일을 열어 슬라이드 콘텐츠를 작성하세요."