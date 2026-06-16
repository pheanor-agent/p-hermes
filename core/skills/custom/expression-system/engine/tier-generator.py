#!/usr/bin/env python3
"""Tier Generator: L1→L2→L3 계층화 (룰 기반)"""

import json
import sys
from typing import Dict, List, Optional

# 도메인별 계층 정의
DOMAIN_TIERS: Dict[str, Dict[str, str]] = {
    "D1": {
        "README": {"L1": "프로젝트 한 줄 설명", "L2": "Quick Start", "L3": "상세 가이드, FAQ"},
        "Wiki": {"L1": "개념 한 문장", "L2": "핵심 설명", "L3": "예시, 시나리오, 관련 링크"},
        "블로그": {"L1": "제목+리드", "L2": "문제 정의", "L3": "인사이트→해결책"},
        "가이드": {"L1": "목표 정의", "L2": "단계별 안내", "L3": "문제 해결, 참고 자료"},
    },
    "D2": {
        "소설": {"L1": "화 개요", "L2": "절(장면)", "L3": "문장(묘사, 대화)"},
        "에세이": {"L1": "주제 문장", "L2": "본론", "L3": "결론, 반성"},
    },
    "D3": {
        "만화": {"L1": "스토리보드 개요", "L2": "페이지 레이아웃", "L3": "패널별 이미지"},
        "인포그래픽": {"L1": "제목", "L2": "라벨+시각 메타포", "L3": "원본 데이터"},
        "다이어그램": {"L1": "아키텍처 개요", "L2": "계층/플로우", "L3": "컴포넌트 상세"},
    },
    "D4": {
        "슬라이드": {"L1": "표지+아이스브레이킹", "L2": "핵심 슬라이드", "L3": "팝업(기술적 심화)"},
        "대시보드": {"L1": "KPI 요약", "L2": "차트", "L3": "데이터 원본"},
    },
    "D5": {
        "이미지": {"L1": "의도/분위기", "L2": "구도/요소", "L3": "프롬프트 세부"},
    },
}

# 도메인별 자수/밀도 규칙
DOMAIN_DENSITY: Dict[str, Dict[str, int]] = {
    "D1": {"L1_max": 100, "L2_max": 500, "L3_max": 2000},
    "D2": {"L1_max": 150, "L2_max": 1000, "L3_max": 5000},
    "D3": {"L1_max": 100, "L2_max": 400, "L3_max": 1500},
    "D4": {"L1_max": 100, "L2_max": 600, "L3_max": 2000},
    "D5": {"L1_max": 100, "L2_max": 300, "L3_max": 1000},
}


def generate_tiers(domain: str, content_type: str, content: str) -> Dict[str, str]:
    """
    도메인과 콘텐츠 유형에 따라 L1→L2→L3 계층 구조 생성.

    Args:
        domain: 도메인 코드 (D1~D5)
        content_type: 콘텐츠 유형 (README, Wiki, 블로그, 소설 등)
        content: 원본 콘텐츠 텍스트

    Returns:
        {"L1": "...", "L2": "...", "L3": "..."} 계층 구조
    """
    if domain not in DOMAIN_TIERS:
        raise ValueError(f"Unknown domain: {domain}. Valid: {list(DOMAIN_TIERS.keys())}")

    tiers = DOMAIN_TIERS[domain]
    if content_type not in tiers:
        # 폴백: 해당 도메인의 첫 번째 타입 사용
        content_type = list(tiers.keys())[0]

    tier_defs = tiers[content_type]
    density = DOMAIN_DENSITY.get(domain, {"L1_max": 100, "L2_max": 500, "L3_max": 2000})

    # L1: 핵심 요약 (density.L1_max 이내)
    l1 = content[:density["L1_max"]].strip()
    if len(content) > density["L1_max"]:
        l1 += "..."

    # L2: 개요 추출 (density.L2_max 이내)
    l2 = content[:density["L2_max"]].strip()
    if len(content) > density["L2_max"]:
        l2 += "..."

    # L3: 상세 내용 (density.L3_max 이내)
    l3 = content[:density["L3_max"]].strip()

    return {
        "L1": l1,
        "L2": l2,
        "L3": l3,
        "tier_definitions": tier_defs,
        "density": density,
    }


def get_tier_definitions(domain: str, content_type: Optional[str] = None) -> Dict:
    """도메인별 계층 정의 반환."""
    if domain not in DOMAIN_TIERS:
        raise ValueError(f"Unknown domain: {domain}")
    if content_type:
        return DOMAIN_TIERS[domain].get(content_type, DOMAIN_TIERS[domain][list(DOMAIN_TIERS[domain].keys())[0]])
    return DOMAIN_TIERS[domain]


def main():
    """CLI: JSON 입력 → 계층 구조 출력."""
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Usage: tier-generator.py <domain> <content_type> <content>"}, ensure_ascii=False))
        sys.exit(1)

    domain = sys.argv[1]
    content_type = sys.argv[2] if len(sys.argv) > 2 else None
    content = sys.stdin.read()

    result = generate_tiers(domain, content_type or "default", content)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
