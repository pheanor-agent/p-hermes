#!/usr/bin/env python3
"""
D4 Domain Wrapper: Seminar Slides 래핑

공유 엔진 연동:
- Tier Generator: L1(표지) → L2(핵심 슬라이드) → L3(팝업 심화)
- Tone Adapter: 비기술적↔기술적 어조 적응
- Validator: T1(분량, 문자셋) + T2(내러티브 흐름)

기존 스킬: seminar-slides (독립 사용 가능)
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
tone_adapter = load_engine('tone_adapter', 'engine/tone-adapter.py')
validator = load_engine('validator', 'engine/validator.py')

generate_tiers = tier_generator.generate_tiers
adapt_tone = tone_adapter.adapt_tone
validate = validator.validate


def wrap_seminar_slides(
    title: str,
    content: str,
    target: str = "non-technical",
    output_format: str = "html"
) -> Dict:
    """
    세미나 슬라이드 생성 — 공유 엔진 연동.

    Args:
        title: 슬라이드 제목
        content: 원본 콘텐츠
        target: 타겟 audiencia (non-technical, technical, mixed)
        output_format: 출력 포맷 (html, md)

    Returns:
        {
            "tiers": {"L1": "...", "L2": "...", "L3": "..."},
            "tone": {"register": "...", "vocabulary": "..."},
            "validation": {"t1": {...}, "t2": {...}},
            "slides": [...]  # 기존 seminar-slides에서 생성
        }
    """
    result = {
        "domain": "D4",
        "title": title,
        "target": target,
    }

    # 1. Tier Generator: L1→L2→L3 계층화
    tiers = generate_tiers("D4", "슬라이드", content)
    result["tiers"] = tiers

    # 2. Tone Adapter: 어조 적응
    tone = adapt_tone(target, "D4")
    result["tone"] = tone

    # 3. Validator: 2단계 검증
    validation = validate(content, "D4", {"tone": tone, "tiers": tiers})
    result["validation"] = validation

    # 4. 기존 seminar-slides 스킬 호출 (템플릿 렌더링)
    # NOTE: 기존 스킬은 독립 실행 가능 - wrapper는 엔진만 제공
    slides = _generate_slides(tiers, tone, title)
    result["slides"] = slides

    return result


def _generate_slides(tiers: Dict, tone: Dict, title: str) -> list:
    """
    슬라이드 구조 생성 - 기존 seminar-slides 템플릿과 호환.

    NOTE: 실제 HTML 렌더링은 seminar-slides 스킬이 담당.
    이 wrapper는 계층 구조 + 어조만 제공.
    """
    slides = [
        {
            "type": "cover",
            "title": title,
            "content": tiers.get("L1", ""),
        },
        {
            "type": "section",
            "title": "핵심 내용",
            "content": tiers.get("L2", ""),
        },
        {
            "type": "detail",
            "title": "상세 설명",
            "content": tiers.get("L3", ""),
        },
    ]
    return slides


def main():
    """CLI: JSON 입력 → D4 슬라이드 출력."""
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Usage: d4-slides.py <title> <content>"}, ensure_ascii=False))
        sys.exit(1)

    title = sys.argv[1]
    content = sys.stdin.read()

    target = "non-technical"
    if len(sys.argv) > 2:
        target = sys.argv[2]

    result = wrap_seminar_slides(title, content, target)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
