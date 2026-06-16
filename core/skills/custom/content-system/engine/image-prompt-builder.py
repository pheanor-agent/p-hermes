#!/usr/bin/env python3
"""
Image Prompt Builder: 이미지 모델용 프롬프트 최적화 엔진

동작 방식:
1. 텍스트 콘텐츠의 핵심 메시지, 분위기, 타겟 추출
2. 시각 요소 매핑 (색상, 구도, 스타일, 구성 요소)
3. 이미지 모델 최적화 프롬프트 생성
4. ComfyUI 연동 흐름 지원
"""

import json
import sys
from typing import Any, Dict, List, Optional


# 이미지 모델별 최적화 설정
MODEL_CONFIGS: Dict[str, Dict[str, Any]] = {
    'gpt-image-2': {
        'max_tokens': 500,
        'supports_text': True,
        'strengths': ['text_rendering', 'composition', 'photorealistic'],
        'prompt_style': 'descriptive'
    },
    'flux-pro': {
        'max_tokens': 1000,
        'supports_text': True,
        'strengths': ['text_rendering', 'detailed', 'creative'],
        'prompt_style': 'detailed'
    },
    'dall-e-3': {
        'max_tokens': 4000,
        'supports_text': True,
        'strengths': ['text_accuracy', 'composition'],
        'prompt_style': 'structured'
    },
    'comfyui': {
        'max_tokens': 75,
        'supports_text': False,
        'strengths': ['stylized', 'creative'],
        'prompt_style': 'keyword'
    }
}


# 시각 스타일 정의
VISUAL_STYLES: Dict[str, Dict[str, str]] = {
    'flat': {
        'description': '플랫 디자인, 모던, 미니멀',
        'keywords': 'flat design, minimalist, clean, modern, geometric shapes'
    },
    'corporate': {
        'description': '기업형, 전문적, 신뢰감',
        'keywords': 'corporate, professional, clean, blue tones, geometric'
    },
    'dramatic': {
        'description': '극적, 대비 강렬, 감성적',
        'keywords': 'dramatic lighting, high contrast, emotional, cinematic'
    },
    'handmade': {
        'description': '수제 느낌, 아날로그, 따뜻함',
        'keywords': 'hand-drawn, sketch, watercolor, warm tones, organic'
    },
    'tech': {
        'description': '기술적, 사이버펑크, 네온',
        'keywords': 'cyberpunk, neon, digital, circuit board, holographic'
    },
    'isometric': {
        'description': '등각투영, 3D, 구조적',
        'keywords': 'isometric, 3D, perspective, structural, clean lines'
    }
}


# 색상 팔레트
COLOR_PALETTES: Dict[str, List[str]] = {
    'morandi': ['#B8C1B2', '#D4C5B0', '#A8B5A0', '#C9B7A8', '#8B9A7E'],
    'neon': ['#FF006E', '#8338EC', '#3A86FF', '#FB5607', '#FFBE0B'],
    'corporate': ['#1E3A5F', '#2E5090', '#E8E8E8', '#FFFFFF', '#333333'],
    'warm': ['#F4A261', '#E76F51', '#E9C46A', '#2A9D8F', '#264653'],
    'cool': ['#264653', '#2A9D8F', '#457B9D', '#1D3557', '#A8DADC']
}


def analyze_intent(
    content: str,
    target_audience: str = 'general'
) -> Dict[str, str]:
    """
    콘텐츠 의도 분석 (간단한 키워드 기반)

    Args:
        content: 텍스트 콘텐츠
        target_audience: 타겟 독자

    Returns:
        의도 분석 결과
    """
    content_lower = content.lower()

    # 의도 분류
    if any(word in content_lower for word in ['왜', '설득', '이유', '좋다']):
        intent = 'persuade'
    elif any(word in content_lower for word in ['설명', '개념', '이해']):
        intent = 'explain'
    elif any(word in content_lower for word in ['재미', '흥미', '스토리']):
        intent = 'entertain'
    elif any(word in content_lower for word in ['데이터', '정확', '통계']):
        intent = 'inform'
    else:
        intent = 'inspire'

    # 분위기 판별
    if any(word in content_lower for word in ['경쾌', '활기', '밝다']):
        mood = 'upbeat'
    elif any(word in content_lower for word in ['진지', '심각', '중요']):
        mood = 'serious'
    elif any(word in content_lower for word in ['미래', '기술', '혁신']):
        mood = 'futuristic'
    else:
        mood = 'neutral'

    return {
        'intent': intent,
        'mood': mood,
        'target_audience': target_audience
    }


def map_visual_elements(
    intent: str,
    mood: str,
    style_preference: Optional[str] = None
) -> Dict[str, Any]:
    """
    시각 요소 매핑

    Args:
        intent: 의도
        mood: 분위기
        style_preference: 스타일 선호 (None 시 자동 선택)

    Returns:
        시각 요소 딕셔너리
    """
    # 의도→스타일 매핑
    intent_to_style = {
        'persuade': 'dramatic',
        'explain': 'flat',
        'entertain': 'handmade',
        'inform': 'corporate',
        'inspire': 'tech'
    }

    style = style_preference or intent_to_style.get(intent, 'flat')
    style_info = VISUAL_STYLES.get(style, VISUAL_STYLES['flat'])

    # 분위기→색상 매핑
    mood_to_palette = {
        'upbeat': 'warm',
        'serious': 'corporate',
        'futuristic': 'neon',
        'neutral': 'morandi'
    }

    palette = COLOR_PALETTES.get(mood_to_palette.get(mood, 'neutral'), COLOR_PALETTES['morandi'])

    return {
        'style': style,
        'style_keywords': style_info['keywords'],
        'palette': palette,
        'palette_name': mood_to_palette.get(mood, 'morandi')
    }


def build_image_prompt(
    content: str,
    target_model: str = 'flux-pro',
    aspect_ratio: str = '16:9',
    detail_level: str = 'high',
    style_preference: Optional[str] = None,
    text_overlay: Optional[str] = None
) -> Dict[str, Any]:
    """
    이미지 프롬프트 빌딩 (메인 API)

    Args:
        content: 텍스트 콘텐츠
        target_model: 타겟 이미지 모델
        aspect_ratio: 가로세로 비율
        detail_level: 상세도 (high/medium/low)
        style_preference: 스타일 선호 (None 시 자동)
        text_overlay: 이미지 내 텍스트

    Returns:
        이미지 프롬프트 딕셔너리
    """
    # 1. 의도 분석
    intent_analysis = analyze_intent(content)

    # 2. 시각 요소 매핑
    visual_elements = map_visual_elements(
        intent_analysis['intent'],
        intent_analysis['mood'],
        style_preference
    )

    # 3. 모델 설정 로드
    model_config = MODEL_CONFIGS.get(target_model, MODEL_CONFIGS['flux-pro'])

    # 4. 프롬프트 구성
    prompt_parts = []

    # 기본 설명
    prompt_parts.append(f"Image illustrating: {content[:200]}")

    # 스타일 키워드
    prompt_parts.append(visual_elements['style_keywords'])

    # 색상 팔레트
    prompt_parts.append(f"Color palette: {', '.join(visual_elements['palette'])}")

    # 상세도
    if detail_level == 'high':
        prompt_parts.append('highly detailed, intricate, fine details')
    elif detail_level == 'low':
        prompt_parts.append('simple, clean, minimal details')

    # 텍스트 오버레이
    if text_overlay and model_config['supports_text']:
        prompt_parts.append(f'Text overlay: "{text_overlay}"')

    # 최종 프롬프트 조합
    final_prompt = ', '.join(prompt_parts)

    # ComfyUI는 키워드 방식
    if target_model == 'comfyui':
        final_prompt = ', '.join([
            content[:50],
            visual_elements['style_keywords'],
            'masterpiece, best quality'
        ])

    return {
        'image_prompt': {
            'intent': intent_analysis['intent'],
            'mood': intent_analysis['mood'],
            'composition': f"{visual_elements['style']} style, {aspect_ratio}",
            'style': visual_elements['style'],
            'style_keywords': visual_elements['style_keywords'],
            'palette': visual_elements['palette'],
            'elements': _extract_elements(content),
            'text_overlay': text_overlay,
            'detail_level': detail_level,
            'aspect_ratio': aspect_ratio
        },
        'optimized_prompt': final_prompt,
        'model': target_model,
        'model_config': model_config
    }


def _extract_elements(content: str, max_elements: int = 5) -> List[str]:
    """
    콘텐츠에서 시각적 요소 추출 (간단한 키워드 기반)

    Args:
        content: 텍스트 콘텐츠
        max_elements: 최대 요소 수

    Returns:
        시각적 요소 목록
    """
    # 일반적인 시각적 요소 매핑
    element_mapping = {
        '서버': 'server rack',
        '데이터': 'data flow',
        '네트워크': 'network cables',
        '클라우드': 'cloud icon',
        '사용자': 'user silhouette',
        '컨테이너': 'shipping container',
        '코드': 'code editor',
        'API': 'API endpoint',
        '데이터베이스': 'database cylinder',
        '모니터': 'computer screen',
    }

    elements = []
    content_lower = content.lower()

    for korean, english in element_mapping.items():
        if korean in content_lower and english not in elements:
            elements.append(english)
            if len(elements) >= max_elements:
                break

    return elements if elements else ['abstract concept visualization']


def main():
    """CLI 진입점."""
    if len(sys.argv) < 2:
        print("Usage: image-prompt-builder.py <content.json>", file=sys.stderr)
        sys.exit(1)

    with open(sys.argv[1], 'r', encoding='utf-8') as f:
        config = json.load(f)

    result = build_image_prompt(
        content=config.get('content', ''),
        target_model=config.get('model', 'flux-pro'),
        aspect_ratio=config.get('aspect_ratio', '16:9'),
        detail_level=config.get('detail_level', 'high'),
        style_preference=config.get('style'),
        text_overlay=config.get('text_overlay')
    )

    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
