#!/usr/bin/env python3
"""템플릿 필러 - 도메인/계층별 템플릿 생성"""

import json
import sys

TEMPLATES = {
    "D1": [
        {
            "title": "제목",
            "summary": "핵심 요약 (1-2문장)",
            "sections": ["개요", "세부 내용", "예시", "참고 자료"]
        },
        {
            "title": "제목",
            "summary": "핵심 요약",
            "sections": ["문제 정의", "해결 방안", "검증 방법"]
        },
        {
            "title": "제목",
            "summary": "핵심 요약",
            "sections": ["배경", "목표", "실행 계획", "예상 결과"]
        }
    ],
    "D2": [
        {
            "title": "화 제목",
            "summary": "설정: 장소, 시간, 분위기",
            "sections": ["시작", "전개", " Кульминация", "마무리"]
        },
        {
            "title": "화 제목",
            "summary": "캐릭터 도입 및 관계 설정",
            "sections": ["캐릭터 A 시선", "캐릭터 B 반응", "상호작용", "감정 변화"]
        }
    ],
    "D3": [
        {
            "title": "인포그래픽 제목",
            "summary": "핵심 메트릭 요약",
            "sections": ["메인 차트", "세부 데이터", "인사이트", "출처"]
        }
    ],
    "D4": [
        {
            "title": "프레젠테이션 제목",
            "summary": "1줄 요약",
            "sections": ["배경", "문제", "솔루션", "결과"]
        }
    ]
}

if __name__ == "__main__":
    DOMAIN = sys.argv[1] if len(sys.argv) > 1 else "D1"
    VARIANT = int(sys.argv[2]) - 1 if len(sys.argv) > 2 else 0

    templates = TEMPLATES.get(DOMAIN, TEMPLATES["D1"])
    template = templates[min(VARIANT, len(templates) - 1)]

    print(json.dumps(template, ensure_ascii=False, indent=2))