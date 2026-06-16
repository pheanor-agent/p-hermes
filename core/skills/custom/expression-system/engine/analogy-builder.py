#!/usr/bin/env python3
"""
Analogy Builder: 비유 생성/검색 엔진 (LLM + 라이브러리)

동작 방식:
1. library.json에서 키워드 기반 검색
2. hit 있으면 룰 기반으로 반환
3. 없으면 LLM이 생성 → pending/ 저장
4. 주간 검토 후 library.json 병합
"""

import json
import os
import re
import sys
from datetime import datetime, timezone
from typing import Dict, List, Optional


SKILL_DIR = os.path.dirname(os.path.abspath(__file__))
LIBRARY_PATH = os.path.join(SKILL_DIR, '..', 'analogies', 'library.json')
PENDING_DIR = os.path.join(SKILL_DIR, '..', 'analogies', 'pending')


def load_library() -> List[Dict]:
    """아날로지 라이브러리 로드."""
    if not os.path.exists(LIBRARY_PATH):
        return []
    with open(LIBRARY_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return data.get('analogies', [])


def save_library(analogies: List[Dict]) -> None:
    """아날로지 라이브러리 저장."""
    data = {
        'version': '1.0.0',
        'updated': datetime.now(timezone.utc).strftime('%Y-%m-%d'),
        'analogies': analogies
    }
    with open(LIBRARY_PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def find_analogy(
    concept: str,
    target: str = 'non-technical',
    domain: str = 'D1',
    threshold: float = 0.6
) -> Optional[Dict]:
    """
    아날로지 검색 - 키워드 매칭 기반 (LLM 시맨틱 검색 폴백)

    Args:
        concept: 검색할 개념
        target: 타겟 독자 (non-technical, technical, visual)
        domain: 도메인 (D1~D5)
        threshold: 매칭 점수 최소치

    Returns:
        아날로지 딕셔너리 또는 None
    """
    analogies = load_library()

    # 키워드 기반 매칭
    concept_lower = concept.lower()
    keywords = re.findall(r'[\w]+', concept_lower)

    best_match = None
    best_score = 0.0

    for analogy in analogies:
        if analogy.get('status') != 'approved':
            continue

        if domain and analogy.get('domain') != domain:
            continue

        # 개념 매칭
        analogy_concept = analogy.get('concept', '').lower()
        analogy_text = analogy.get('analogy', '').lower()

        # 직접 매칭 (가장 높은 점수)
        if concept_lower == analogy_concept:
            score = 1.0
        elif concept_lower in analogy_concept or analogy_concept in concept_lower:
            score = 0.9
        else:
            # 키워드 오버랩 스코어링
            analogy_keywords = set(re.findall(r'[\w]+', analogy_concept))
            overlap = len(set(keywords) & analogy_keywords)
            total = max(len(keywords), len(analogy_keywords))
            score = overlap / total if total > 0 else 0

            # 텍스트 내 개념 언급 확인
            if concept_lower in analogy_text:
                score = max(score, 0.7)

        if score >= threshold and score > best_score:
            best_score = score
            best_match = {
                'id': analogy['id'],
                'concept': analogy['concept'],
                'analogy': analogy['analogy'],
                'domain': analogy.get('domain', 'D1'),
                'quality_score': analogy.get('quality_score', 0.8),
                'usage_count': analogy.get('usage_count', 0),
                'match_score': score,
                'source': 'library'
            }

    if best_match:
        # usage_count 증가
        for analogy in analogies:
            if analogy['id'] == best_match['id']:
                analogy['usage_count'] = analogy.get('usage_count', 0) + 1
                break
        save_library(analogies)

    return best_match


def generate_analogy_prompt(
    concept: str,
    context: str = '',
    target: str = 'non-technical'
) -> str:
    """
    LLM에게 아날로지 생성을 요청하는 프롬프트 생성

    Args:
        concept: 비유할 개념
        context: 추가 컨텍스트
        target: 타겟 독자

    Returns:
        LLM 프롬프트 문자열
    """
    target_descriptions = {
        'non-technical': '비기술적 독자 (일상적 비유, 기술 용어 최소화)',
        'technical': '기술적 독자 (정확한 기술 비유, 원어 유지)',
        'visual': '시각적 학습자 (시각적 메타포, 공간적 비유)'
    }

    return f"""아래 개념에 대해 {target_descriptions.get(target, target)}에게 설명할 수 있는 비유를 생성해주세요.

개념: {concept}
{'컨텍스트: ' + context if context else ''}

요구사항:
1. 일상에서 접할 수 있는 구체적인 예시 사용
2. 기술 용어 최소화 (non-technical인 경우)
3. 1-2문장으로 간결하게
4. 핵심 개념의 본질을 정확히 전달

출력 형식 (JSON):
{{
  "concept": "{concept}",
  "analogy": "생성된 비유",
  "target": "{target}",
  "rationale": "왜 이 비유를 선택했는지 짧은 설명"
}}
"""


def save_pending_analogy(
    concept: str,
    analogy: str,
    target: str = 'non-technical',
    domain: str = 'D1',
    quality_score: float = 0.7
) -> str:
    """
    생성된 아날로지를 pending 폴더에 저장

    Args:
        concept: 개념
        analogy: 비유
        target: 타겟
        domain: 도메인
        quality_score: 품질 점수

    Returns:
        저장된 파일 경로
    """
    os.makedirs(PENDING_DIR, exist_ok=True)

    timestamp = datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')
    filename = f"{concept.replace(' ', '-')}_{timestamp}.md"
    filepath = os.path.join(PENDING_DIR, filename)

    content = f"""# 아날로지 (검토 대기)

- **개념**: {concept}
- **비유**: {analogy}
- **타겟**: {target}
- **도메인**: {domain}
- **품질 점수**: {quality_score}
- **생성일**: {datetime.now(timezone.utc).isoformat()}
- **상태**: pending

## 검토 기준

- [ ] 개념 본질 정확히 전달하는가?
- [ ] 타겟 독자에게 적절한가?
- [ ] 명확하고 간결한가?
- [ ] 기존 아날로지와 중복되는가?

"""

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

    return filepath


def count_pending() -> int:
    """검토 대기 중인 아날로지 수."""
    if not os.path.exists(PENDING_DIR):
        return 0
    return len([f for f in os.listdir(PENDING_DIR) if f.endswith('.md')])


def main():
    """CLI 진입점."""
    if len(sys.argv) < 2:
        print("Usage: analogy-builder.py <search|generate|count> [args...]", file=sys.stderr)
        sys.exit(1)

    command = sys.argv[1]

    if command == 'search':
        concept = sys.argv[2] if len(sys.argv) > 2 else ''
        target = sys.argv[3] if len(sys.argv) > 3 else 'non-technical'
        domain = sys.argv[4] if len(sys.argv) > 4 else 'D1'

        result = find_analogy(concept, target, domain)
        print(json.dumps(result, ensure_ascii=False, indent=2) if result else 'null')

    elif command == 'generate':
        concept = sys.argv[2] if len(sys.argv) > 2 else ''
        target = sys.argv[3] if len(sys.argv) > 3 else 'non-technical'
        context = sys.argv[4] if len(sys.argv) > 4 else ''

        prompt = generate_analogy_prompt(concept, context, target)
        print(prompt)

    elif command == 'count':
        print(json.dumps({'pending_count': count_pending()}))

    elif command == 'save':
        concept = sys.argv[2] if len(sys.argv) > 2 else ''
        analogy = sys.argv[3] if len(sys.argv) > 3 else ''
        target = sys.argv[4] if len(sys.argv) > 4 else 'non-technical'
        domain = sys.argv[5] if len(sys.argv) > 5 else 'D1'

        filepath = save_pending_analogy(concept, analogy, target, domain)
        print(json.dumps({'filepath': filepath}))

    else:
        print(f"Unknown command: {command}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
