#!/usr/bin/env python3
"""
Template Filler: 도메인별 템플릿 렌더링 엔진

동작 방식:
1. 도메인+의도 → 템플릿 선택
2. string.Template로 구조 렌더링
3. LLM은 내용 부분만 생성 (플레이스홀더 대체)
"""

import json
import os
import sys
from string import Template
from typing import Any, Dict, List, Optional


SKILL_DIR = os.path.dirname(os.path.abspath(__file__))
TEMPLATES_DIR = os.path.join(SKILL_DIR, '..', 'templates')


# 도메인별 템플릿 정의
TEMPLATES: Dict[str, Dict[str, str]] = {
    'D1': {
        'readme': """# {{title}}

{{summary}}

## Quick Start

{{quick_start}}

## Features

{{features}}

## Installation

{{installation}}

## Usage

{{usage}}

## FAQ

{{faq}}""",

        'wiki': """# {{title}}

> {{summary}}

## 개요

{{overview}}

## 핵심 개념

{{concepts}}

## 예시

{{examples}}

## 참고 자료

{{references}}""",

        'blog': """# {{title}}

{{lead}}

## 문제 정의

{{problem}}

## 인사이트

{{insight}}

## 해결책

{{solution}}

## 결론

{{conclusion}}""",

        'guide': """# {{title}}

{{summary}}

## 준비

{{prerequisites}}

## 단계별 가이드

{{steps}}

## 검증 방법

{{verification}}

## 문제 해결

{{troubleshooting}}"""
    },

    'D2': {
        'novel': """# {{title}}

{{setting}}

## {{scene_1_title}}

{{scene_1}}

## {{scene_2_title}}

{{scene_2}}

## {{scene_3_title}}

{{scene_3}}

---
{{ending}}""",

        'essay': """# {{title}}

{{opening}}

## 본론

{{body}}

## 결론

{{conclusion}}

---
{{postscript}}"""
    },

    'D3': {
        'infographic': """# {{title}}

{{summary}}

## 메인 시각화

{{main_chart}}

## 세부 데이터

{{details}}

## 인사이트

{{insights}}

## 출처

{{sources}}""",

        'diagram': """<!-- SVG 다이어그램 -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {{width}} {{height}}">
  {{svg_content}}
</svg>"""
    },

    'D4': {
        'slide': """<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <title>{{title}}</title>
  <style>
    {{css}}
  </style>
</head>
<body>
  <div class="slide">
    {{slide_content}}
  </div>
</body>
</html>""",

        'dashboard': """<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <title>{{title}}</title>
  <style>
    {{css}}
  </style>
</head>
<body>
  <div class="dashboard">
    {{dashboard_content}}
  </div>
</body>
</html>"""
    }
}


def select_template(domain: str, intent: str) -> Optional[str]:
    """
    도메인+의도 → 템플릿 키 매핑

    Args:
        domain: 도메인 코드 (D1~D5)
        intent: 의도 (explain, persuade, 등)

    Returns:
        템플릿 키 또는 None
    """
    mapping = {
        ('D1', 'explain'): 'wiki',
        ('D1', 'persuade'): 'readme',
        ('D1', 'inform'): 'guide',
        ('D1', 'entertain'): 'blog',
        ('D2', 'narrate'): 'novel',
        ('D2', 'entertain'): 'essay',
        ('D3', 'inform'): 'infographic',
        ('D3', 'explain'): 'diagram',
        ('D4', 'inspire'): 'slide',
        ('D4', 'inform'): 'dashboard',
    }

    return mapping.get((domain, intent))


def render_template(
    domain: str,
    template_key: str,
    variables: Dict[str, str]
) -> str:
    """
    템플릿 렌더링 (str.format 사용)

    Args:
        domain: 도메인 코드
        template_key: 템플릿 키
        variables: 변수 딕셔너리

    Returns:
        렌더링된 문자열
    """
    templates = TEMPLATES.get(domain, {})
    template_str = templates.get(template_key)

    if not template_str:
        raise ValueError(f"Template not found: {domain}/{template_key}")

    # {{variable}} 형식을 $variable로 변환하여 string.Template 사용
    from string import Template
    template = Template(template_str.replace('{{', '$').replace('}}', ''))
    return template.safe_substitute(variables)


def fill_template(
    domain: str,
    intent: str,
    content: Dict[str, Any]
) -> Dict[str, Any]:
    """
    템플릿 선택 + 렌더링 (메인 API)

    Args:
        domain: 도메인 코드
        intent: 의도
        content: 콘텐츠 데이터

    Returns:
        결과 딕셔너리 (template_key, rendered, variables)
    """
    template_key = select_template(domain, intent)
    if not template_key:
        template_key = list(TEMPLATES.get(domain, {}).keys())[0] if TEMPLATES.get(domain) else 'readme'

    # 기본 변수 설정
    variables = {
        'title': content.get('title', '제목'),
        'summary': content.get('summary', ''),
    }

    # 템플릿별 변수 매핑
    if domain == 'D1':
        variables.update({
            'quick_start': content.get('quick_start', ''),
            'features': content.get('features', ''),
            'installation': content.get('installation', ''),
            'usage': content.get('usage', ''),
            'faq': content.get('faq', ''),
            'overview': content.get('overview', ''),
            'concepts': content.get('concepts', ''),
            'examples': content.get('examples', ''),
            'references': content.get('references', ''),
            'lead': content.get('lead', ''),
            'problem': content.get('problem', ''),
            'insight': content.get('insight', ''),
            'solution': content.get('solution', ''),
            'conclusion': content.get('conclusion', ''),
            'prerequisites': content.get('prerequisites', ''),
            'steps': content.get('steps', ''),
            'verification': content.get('verification', ''),
            'troubleshooting': content.get('troubleshooting', ''),
        })
    elif domain == 'D2':
        variables.update({
            'setting': content.get('setting', ''),
            'scene_1_title': content.get('scene_1_title', '장면 1'),
            'scene_1': content.get('scene_1', ''),
            'scene_2_title': content.get('scene_2_title', '장면 2'),
            'scene_2': content.get('scene_2', ''),
            'scene_3_title': content.get('scene_3_title', '장면 3'),
            'scene_3': content.get('scene_3', ''),
            'ending': content.get('ending', ''),
            'opening': content.get('opening', ''),
            'body': content.get('body', ''),
            'postscript': content.get('postscript', ''),
        })
    elif domain == 'D3':
        variables.update({
            'main_chart': content.get('main_chart', ''),
            'details': content.get('details', ''),
            'insights': content.get('insights', ''),
            'sources': content.get('sources', ''),
            'width': content.get('width', '800'),
            'height': content.get('height', '600'),
            'svg_content': content.get('svg_content', ''),
        })
    elif domain == 'D4':
        variables.update({
            'css': content.get('css', ''),
            'slide_content': content.get('slide_content', ''),
            'dashboard_content': content.get('dashboard_content', ''),
        })

    rendered = render_template(domain, template_key, variables)

    return {
        'domain': domain,
        'intent': intent,
        'template_key': template_key,
        'rendered': rendered,
        'variables': variables
    }


def main():
    """CLI 진입점."""
    if len(sys.argv) < 3:
        print("Usage: template-filler.py <domain> <intent> <content.json>", file=sys.stderr)
        sys.exit(1)

    domain = sys.argv[1]
    intent = sys.argv[2]

    # 콘텐츠 입력 (JSON 파일 또는 stdin)
    if len(sys.argv) > 3:
        with open(sys.argv[3], 'r', encoding='utf-8') as f:
            content = json.load(f)
    else:
        content = json.load(sys.stdin)

    result = fill_template(domain, intent, content)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
