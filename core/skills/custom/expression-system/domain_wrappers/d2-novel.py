#!/usr/bin/env python3
"""
D2 Domain Wrapper: Novel Writing 래핑

공유 엔진 연동:
- Tone Adapter: 캐릭터별 어조/문체 적응
- Validator: T1(분량, 문자셋) + T2(내러티브 흐름, 캐릭터 일관성)
- Tier Generator: 화→절→문장 계층화

기존 스킬: novel-writing (독립 사용 가능)
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


def wrap_novel_writing(
    episode_title: str,
    content: str,
    chapter_number: int = 1,
    characters: Optional[Dict] = None,
    style: str = "literary-fiction"
) -> Dict:
    """
    소설 에피소드 생성 — 공유 엔진 연동.

    Args:
        episode_title: 화 제목
        content: 원본 콘텐츠 (scene-cards, setting 등)
        chapter_number: 화 번호
        characters: 캐릭터 설정 (선택)
        style: 문체 스타일 (literary-fiction, web-novel)

    Returns:
        {
            "tiers": {"L1": "...", "L2": "...", "L3": "..."},
            "tone": {"register": "...", "vocabulary": "..."},
            "validation": {"t1": {...}, "t2": {...}},
            "episode": {...}  # 기존 novel-writing과 호환 구조
        }
    """
    result = {
        "domain": "D2",
        "episode": chapter_number,
        "title": episode_title,
        "style": style,
    }

    # 1. Tier Generator: 화→절→문장 계층화
    tiers = generate_tiers("D2", "소설", content)
    result["tiers"] = tiers

    # 2. Tone Adapter: 캐릭터별 어조 적응
    tone = adapt_tone(style, "D2")
    result["tone"] = tone

    # 3. Validator: 2단계 검증
    context = {"tone": tone, "tiers": tiers, "characters": characters}
    validation = validate(content, "D2", context)
    result["validation"] = validation

    # 4. 기존 novel-writing 스킬 호출 (에피소드 구조 생성)
    episode = _generate_episode(tiers, tone, episode_title, chapter_number)
    result["episode"] = episode

    return result


def _generate_episode(tiers: Dict, tone: Dict, title: str, chapter: int) -> Dict:
    """
    에피소드 구조 생성 - 기존 novel-writing과 호환.

    NOTE: 실제 본문 작성은 novel-writing 스킬이 담당.
    이 wrapper는 계층 구조 + 어조만 제공.
    """
    return {
        "episode": chapter,
        "title": title,
        "structure": {
            "overview": tiers.get("L1", ""),
            "scenes": tiers.get("L2", ""),
            "detail": tiers.get("L3", ""),
        },
        "tone": tone,
    }


def main():
    """CLI: JSON 입력 → D2 소설 에피소드 출력."""
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Usage: d2-novel.py <title> [chapter]"}, ensure_ascii=False))
        sys.exit(1)

    title = sys.argv[1]
    chapter = int(sys.argv[2]) if len(sys.argv) > 2 else 1
    content = sys.stdin.read()

    result = wrap_novel_writing(title, content, chapter)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
