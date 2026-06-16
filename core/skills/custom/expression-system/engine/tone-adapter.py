#!/usr/bin/env python3
"""Tone Adapter: 타겟→어조/어휘/문체 매핑 (룰 기반)"""

import json
import sys
from typing import Dict, Optional

# 타겟→어조/어휘/문체 매핑 테이블
TONE_TABLE: Dict[str, Dict[str, str]] = {
    "non-technical": {
        "tone": "대화체, 친근",
        "vocabulary": "비유 중심, 기술 용어 최소화",
        "style": "\"도서관 카탈로그처럼\" 같은 일상 비유 사용",
        "examples": ["이 시스템은 마치 개인 비서처럼 작동합니다", "데이터가 흐르는 관상처럼 생각하시면 됩니다"],
    },
    "technical": {
        "tone": "설명체, 정밀",
        "vocabulary": "원어 유지, 정확한 용어 사용",
        "style": "\"RAG(Retrieval-Augmented Generation)\" 같이 전문 용어 표기",
        "examples": ["이 파이프라인은 ETL 패턴을 따릅니다", "WAL(WAL Journaling) 모드로 동시성 제어"],
    },
    "casual-blog": {
        "tone": "캐주얼, 유머",
        "vocabulary": "일상어, 슬랭 허용",
        "style": "\"이게 문제였거든\" 같은 캐주얼 표현",
        "examples": ["사실 이게 제일 귀찮았어요", "하지만 다행히 해결책이 있었죠"],
    },
    "professional-blog": {
        "tone": "분석체, 권위",
        "vocabulary": "업계 용어, 인용",
        "style": "\"벤치마크 결과에 따르면\" 같은 객관적 표현",
        "examples": ["데이터에 따르면 23% 향상이 확인되었습니다", "이유는 세 가지로 요약할 수 있습니다"],
    },
    "narrative": {
        "tone": "서술체, 감성",
        "vocabulary": "상징, 묘사, 내러티브",
        "style": "문장 끝의 여운, 감각적 묘사",
        "examples": ["창밖으로 비가 내리고 있었다", "그의 표정은 말하지 않아도 읽혔다"],
    },
    "presentation": {
        "tone": "설득적, 명료",
        "vocabulary": "강조, 반복, 핵심 메시지",
        "style": "짧은 문장, 불렛 포인트, 시각적 휴식",
        "examples": ["핵심은 하나입니다 — 단순함", "세 가지로 요약하면"],
    },
}

# 도메인별 기본 톤
DOMAIN_DEFAULT_TONE: Dict[str, str] = {
    "D1": "technical",
    "D2": "narrative",
    "D3": "technical",
    "D4": "presentation",
    "D5": "technical",
}


def adapt_tone(target: str, domain: Optional[str] = None) -> Dict[str, str]:
    """
    타겟과 도메인에 따라 어조/어휘/문체 규칙 반환.

    Args:
        target: 타겟 정의 (non-technical, technical, casual-blog 등)
        domain: 도메인 코드 (D1~D5)

    Returns:
        {"tone": "...", "vocabulary": "...", "style": "...", "examples": [...]}
    """
    if target in TONE_TABLE:
        return TONE_TABLE[target]

    # 폴백: 도메인 기본 톤
    if domain and domain in DOMAIN_DEFAULT_TONE:
        return TONE_TABLE[DOMAIN_DEFAULT_TONE[domain]]

    # 최종 폴백: technical
    return TONE_TABLE["technical"]


def get_available_tones() -> Dict[str, str]:
    """사용 가능한 톤 목록 반환."""
    return {k: v["tone"] for k, v in TONE_TABLE.items()}


def main():
    """CLI: JSON 입력 → 어조 규칙 출력."""
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Usage: tone-adapter.py <target> [domain]"}, ensure_ascii=False))
        sys.exit(1)

    target = sys.argv[1]
    domain = sys.argv[2] if len(sys.argv) > 2 else None

    result = adapt_tone(target, domain)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
