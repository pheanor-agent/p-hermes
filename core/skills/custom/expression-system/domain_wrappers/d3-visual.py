#!/usr/bin/env python3
"""
D3 Domain Wrapper: Visual Content 래핑 (Comic, Infographic, Diagram)

공유 엔진 연동:
- Template Filler: 시각 템플릿 렌더링
- Validator: T1(구조 검증) + T2(시각적 일관성)
- Analogy Builder: 비유→시각 메타포 변환
- Image Prompt Builder: 이미지 모델 프롬프트 최적화

기존 스킬: baoyu-comic, baoyu-infographic, architecture-diagram (독립 사용 가능)
"""

import json
import sys
import os
from typing import Dict, Optional

# expression-system 엔진 경로 추가
SKILL_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, SKILL_DIR)

# 하이픈 포함 모듈 동적 로딩
from engine import load_engine

tier_generator = load_engine('tier_generator', 'engine/tier-generator.py')
template_filler = load_engine('template_filler', 'engine/template-filler.py')
validator = load_engine('validator', 'engine/validator.py')
analogy_builder = load_engine('analogy_builder', 'engine/analogy-builder.py')
image_prompt_builder = load_engine('image_prompt_builder', 'engine/image-prompt-builder.py')

generate_tiers = tier_generator.generate_tiers
fill_template = template_filler.fill_template
validate = validator.validate
find_analogy = analogy_builder.find_analogy
build_prompt = image_prompt_builder.build_image_prompt


def wrap_visual_content(
    content_type: str,
    title: str,
    content: str,
    style: Optional[str] = None,
    layout: Optional[str] = None
) -> Dict:
    """
    시각 콘텐츠 생성 — 공유 엔진 연동.

    Args:
        content_type: 콘텐츠 유형 (comic, infographic, diagram)
        title: 제목
        content: 원본 콘텐츠
        style: 스타일 (선택)
        layout: 레이아웃 (선택)

    Returns:
        {
            "tiers": {"L1": "...", "L2": "...", "L3": "..."},
            "template": {...},
            "analogy": {...},
            "image_prompt": {...},
            "validation": {"t1": {...}, "t2": {...}},
        }
    """
    if content_type not in ["comic", "infographic", "diagram"]:
        raise ValueError(f"Invalid content_type: {content_type}. Valid: comic, infographic, diagram")

    result = {
        "domain": "D3",
        "type": content_type,
        "title": title,
    }

    # 1. Tier Generator: 시각 계층화
    tier_type_map = {
        "comic": "만화",
        "infographic": "인포그래픽",
        "diagram": "다이어그램",
    }
    tiers = generate_tiers("D3", tier_type_map[content_type], content)
    result["tiers"] = tiers

    # 2. Template Filler: 시각 템플릿 렌더링
    template = fill_template("D3", content_type, {
        "title": title,
        "tiers": tiers,
        "style": style,
        "layout": layout,
    })
    result["template"] = template

    # 3. Analogy Builder: 비유→시각 메타포
    analogy = find_analogy(content[:200], "visual")
    result["analogy"] = analogy

    # 4. Image Prompt Builder: 이미지 프롬프트 최적화
    image_prompt = build_prompt(content, content_type, style)
    result["image_prompt"] = image_prompt

    # 5. Validator: 2단계 검증
    validation = validate(content, "D3", {
        "tiers": tiers,
        "template": template,
        "analogy": analogy,
    })
    result["validation"] = validation

    return result


def wrap_comic(title: str, content: str, **kwargs) -> Dict:
    """baoyu-comic 래핑 - D3 시각 콘텐츠의 서브 타입."""
    return wrap_visual_content("comic", title, content, **kwargs)


def wrap_infographic(title: str, content: str, **kwargs) -> Dict:
    """baoyu-infographic 래핑 - D3 시각 콘텐츠의 서브 타입."""
    return wrap_visual_content("infographic", title, content, **kwargs)


def wrap_diagram(title: str, content: str, **kwargs) -> Dict:
    """architecture-diagram 래핑 - D3 시각 콘텐츠의 서브 타입."""
    return wrap_visual_content("diagram", title, content, **kwargs)


def main():
    """CLI: JSON 입력 → D3 시각 콘텐츠 출력."""
    if len(sys.argv) < 3:
        print(json.dumps({"error": "Usage: d3-visual.py <type> <title>"}, ensure_ascii=False))
        sys.exit(1)

    content_type = sys.argv[1]
    title = sys.argv[2]
    content = sys.stdin.read()

    result = wrap_visual_content(content_type, title, content)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
