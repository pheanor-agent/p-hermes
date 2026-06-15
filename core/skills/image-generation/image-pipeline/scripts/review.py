#!/usr/bin/env python3
"""
이미지 생성 후 검증 스크립트

생성된 이미지가 요청한 의도와 일치하는지 자동 검증 프롬프트 생성.
"""

import json
import sys
from pathlib import Path
from datetime import datetime

def generate_review_prompt(original_prompt, focus_areas=None):
    """검증용 프롬프트 생성"""
    
    if focus_areas is None:
        focus_areas = []
    
    base_prompt = f"""생성된 이미지가 원본 프롬프트 의도와 일치하는지 분석해주세요.

원본 프롬프트:
{original_prompt}

분석 항목:
1. 카테고리 일치도 (인물/패션/풍경/제품/기타)
2. 구도/비율 일치도
3. 주제 정확도 (주요 요소 포함 여부)
4. 스타일 일치도 (리얼리즘/일러스트/애니메이션 등)
5. 색상/분위기 일치도
6. 품질 (해상도, 선명도, 아티팩트)

분석 결과 형식:
{{
  "overall_match": "high/medium/low",
  "match_score": 0-100,
  "details": {{
    "category": "일치 여부 + 설명",
    "composition": "일치 여부 + 설명",
    "subject": "일치 여부 + 설명",
    "style": "일치 여부 + 설명",
    "color_mood": "일치 여부 + 설명",
    "quality": "품질 평가"
  }},
  "discrepancies": ["차이점 목록"],
  "recommendation": "재생성 권장 여부 + 이유"
}}
"""
    
    if focus_areas:
        base_prompt += "\n특별 분석 요청:\n"
        for area in focus_areas:
            base_prompt += f"- {area}\n"
    
    return base_prompt

def focus_on_text():
    """텍스트 렌더링 검증 프롬프트"""
    return """텍스트 렌더링을 특별히 분석해주세요:

1. 프롬프트에 포함된 텍스트가 이미지に表示되었는지
2. 텍스트 가독성 (날카로움, 왜곡 여부)
3. 언어 정확도 (한글/영어/기타)
4. 스펠링 정확도

결과에 "text_rendering" 필드 추가:
{{
  "text_rendering": {{
    "requested_text": "요청한 텍스트",
    "rendered": true/false,
    "readability": "high/medium/low",
    "language_accuracy": "언어 정확도",
    "spelling_accuracy": "スペル 정확도"
  }}
}}
"""

def focus_on_characters():
    """캐릭터 일관성 검증 프롬프트"""
    return """다중 캐릭터 일관성을 분석해주세요:

1. 캐릭터 수 일치
2. 각 캐릭터의 특징 유지 (의상, 헤어, 외모)
3. 상대적 위치/크기 비율
4. 상호작용 자연스러움

결과에 "character_consistency" 필드 추가:
{{
  "character_consistency": {{
    "count_match": true/false,
    "features_consistent": true/false,
    "proportions_correct": true/false,
    "interaction_natural": true/false
  }}
}}
"""

def main():
    if len(sys.argv) < 3:
        print("사용법: review.py <이미지_경로> <원본_프롬프트> [focus_areas...]")
        print("예: review.py image.png 'fashion photo' text characters")
        sys.exit(1)
    
    image_path = sys.argv[1]
    original_prompt = sys.argv[2]
    focus_areas = sys.argv[3:] if len(sys.argv) > 3 else []
    
    # 키워드 감지 → 자동 focus 추가
    prompt_lower = original_prompt.lower()
    
    text_keywords = ["text", "텍스트", "문자", "logo", "로고", "sign", "사인"]
    if any(kw in prompt_lower for kw in text_keywords):
        if "text" not in focus_areas:
            focus_areas.append("text")
    
    character_keywords = ["character", "캐릭터", "people", "사람", "two people", "couple", "커플"]
    if any(kw in prompt_lower for kw in character_keywords):
        if "characters" not in focus_areas:
            focus_areas.append("characters")
    
    review_prompt = generate_review_prompt(original_prompt, focus_areas)
    
    # 특별 분석 추가
    if "text" in focus_areas:
        review_prompt += focus_on_text()
    
    if "characters" in focus_areas:
        review_prompt += focus_on_characters()
    
    # 결과를 파일로 저장
    output = {
        "timestamp": datetime.now().isoformat(),
        "image_path": image_path,
        "original_prompt": original_prompt,
        "focus_areas": focus_areas,
        "review_prompt": review_prompt
    }
    
    output_path = Path(image_path).with_suffix('.review.json')
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(output, f, ensure_ascii=False, indent=2)
    
    print(f"검증 프롬프트 생성 완료: {output_path}")
    print(f"\n다음으로 vision_analyze 호출:")
    print(f'vision_analyze(image_url="{image_path}", question="{review_prompt[:100]}...")')

if __name__ == "__main__":
    main()
