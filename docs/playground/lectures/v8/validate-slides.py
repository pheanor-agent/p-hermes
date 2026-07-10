#!/usr/bin/env python3
"""
D3 Slide Validator — 슬라이드 품질 자동 검증
사용법: python3 validate-slides.py <deck.html> [--strict]
검증 항목: 텍스트 오버플로우, 레이아웃 정렬, 네비게이션, 콘텐츠 중복
"""

import re
import sys
import json
from collections import Counter
from html.parser import HTMLParser

class SlideParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.slides = []
        self.current_slide = None
        self.current_tag = None
        self.current_text = ""
        self.in_slide = False
        self.slide_attrs = {}
        self.stack = []

    def handle_starttag(self, tag, attrs):
        self.current_tag = tag
        attrs_dict = dict(attrs)
        self.stack.append((tag, attrs_dict))

        if tag == 'section' and 'slide' in attrs_dict.get('class', ''):
            self.in_slide = True
            self.current_slide = {
                'id': attrs_dict.get('id', ''),
                'class': attrs_dict.get('class', ''),
                'text_blocks': [],
                'hero_subtitles': [],
                'compare_blocks': [],
                'feature_items': [],
                'footer_text': '',
                'title': '',
            }
            self.slide_attrs = attrs_dict

    def handle_endtag(self, tag):
        if tag == 'section' and self.in_slide:
            self.in_slide = False
            if self.current_slide:
                self.slides.append(self.current_slide)
                self.current_slide = None

        if self.stack and self.stack[-1][0] == tag:
            self.stack.pop()

    def handle_data(self, data):
        text = data.strip()
        if not text or self.current_slide is None:
            return

        stack_tags = [s[0] for s in self.stack]

        # Hero subtitle
        if 'hero-subtitle' in str(self.stack[-1][1].get('class', '')) if self.stack else False:
            self.current_slide['hero_subtitles'].append(text)

        # Footer text
        if stack_tags and stack_tags[-1] == 'span' and self.in_slide:
            # Check if parent is slide-footer
            for i in range(len(self.stack)-1, -1, -1):
                if self.stack[i][0] == 'div' and 'slide-footer' in self.stack[i][1].get('class', ''):
                    self.current_slide['footer_text'] = text
                    break

        # Feature items
        if self.stack and self.stack[-1][0] == 'div':
            cls = self.stack[-1][1].get('class', '')
            if 'feature-item' in cls:
                self.current_slide['feature_items'].append(text)

        # Compare blocks
        if self.stack and self.stack[-1][0] == 'div':
            cls = self.stack[-1][1].get('class', '')
            if 'compare-content' in cls:
                self.current_slide['compare_blocks'].append(text)

        # General text blocks
        if len(text) > 10:
            self.current_slide['text_blocks'].append(text)


def check_text_overflow(slides, strict=False):
    """한 줄로 표시해야 할 텍스트가 줄바꿈될 수 있는지 검증"""
    issues = []
    # 한 줄 권장 길이 (반응형 기준)
    max_single_line = 70 if strict else 90

    for i, slide in enumerate(slides):
        slide_num = i + 1

        # Hero subtitle: 한 줄 텍스트
        for text in slide.get('hero_subtitles', []):
            if len(text) > max_single_line:
                issues.append({
                    'page': slide_num,
                    'type': 'hero-subtitle-overflow',
                    'severity': 'P1',
                    'text': text[:80] + '...',
                    'length': len(text),
                    'fix': 'white-space:nowrap 추가 또는 텍스트 분할'
                })

        # Footer text: 한 줄 텍스트
        footer = slide.get('footer_text', '')
        if footer and len(footer) > max_single_line:
            issues.append({
                'page': slide_num,
                'type': 'footer-overflow',
                'severity': 'P1',
                'text': footer[:80] + '...',
                'length': len(footer),
                'fix': 'white-space:nowrap 또는 텍스트 축약'
            })

        # content-desc (중요 메시지): 70자 초과 시 경고
        for text in slide.get('text_blocks', []):
            if len(text) > 80 and len(text) < 200:
                # 짧은 문단이지만 한 줄로 의도한 경우
                issues.append({
                    'page': slide_num,
                    'type': 'content-desc-overflow',
                    'severity': 'P2',
                    'text': text[:60] + '...',
                    'length': len(text),
                    'fix': 'white-space:nowrap 또는 <br>로 의도적 줄바꿈'
                })

    return issues


def check_compare_layout(html_content):
    """compare-content 블록이 올바른 구조를 가졌는지 검증"""
    issues = []
    # compare-content 내부에 compare-col이 2개 이상 있는지
    compare_blocks = re.findall(r'class="compare-content"[^>]*>(.*?)</section>', html_content, re.DOTALL)

    for block_idx, block in enumerate(compare_blocks):
        col_count = len(re.findall(r'class="compare-col"', block))
        if col_count < 2:
            issues.append({
                'type': 'compare-missing-column',
                'severity': 'P0',
                'detail': f'compare-content에 compare-col {col_count}개 (최소 2개 필요)',
                'fix': 'compare-col 추가 또는 다른 레이아웃 사용'
            })
        # feature-item 내부 구조 검증
        feature_items = re.findall(r'class="feature-item"[^>]*>(.*?)</div>', block, re.DOTALL)
        for fi_idx, fi in enumerate(feature_items):
            # icon + div 구조 확인
            has_icon = re.search(r'class="feature-icon"', fi)
            has_text_div = re.search(r'><strong|class="metaphor-title"', fi)
            if not has_icon or not has_text_div:
                issues.append({
                    'type': 'compare-feature-structure',
                    'severity': 'P1',
                    'detail': f'feature-item 구조 불일치 (icon+text 필요)',
                    'fix': 'feature-icon + text div 구조 적용'
                })

    return issues


def check_navigation_js(html_content):
    """내비게이션 JS가 scrollIntoView를 사용하지 않는지 검증"""
    issues = []
    # scrollIntoView 사용 여부
    scroll_into_view = re.findall(r'\.scrollIntoView\(', html_content)
    if scroll_into_view:
        issues.append({
            'type': 'nav-scrollintoview',
            'severity': 'P0',
            'detail': f'scrollIntoView() {len(scroll_into_view)}회 사용 (scroll-snap 충돌)',
            'fix': 'window.scrollTo({top: offsetTop})로 교체'
        })

    # scroll-behavior: smooth CSS
    if 'scroll-behavior: smooth' in html_content:
        issues.append({
            'type': 'css-smooth-scroll',
            'severity': 'P0',
            'detail': 'scroll-behavior: smooth가 scroll-snap과 충돌',
            'fix': 'CSS에서 scroll-behavior: smooth 제거'
        })

    return issues


def check_content_duplication(slides):
    """페이지 간 콘텐츠 중복 감지"""
    issues = []
    # 슬라이드 제목 + 주요 텍스트로 중복 판별
    slide_summaries = []
    for i, slide in enumerate(slides):
        texts = ' '.join(slide.get('text_blocks', [])[:3])
        slide_summaries.append({
            'page': i + 1,
            'text': texts.lower()[:200]
        })

    # Jaccard 유사도로 중복 감지
    for i in range(len(slide_summaries)):
        for j in range(i + 1, len(slide_summaries)):
            a = set(slide_summaries[i]['text'].split())
            b = set(slide_summaries[j]['text'].split())
            if len(a) == 0 or len(b) == 0:
                continue
            jaccard = len(a & b) / len(a | b)
            if jaccard > 0.6:
                issues.append({
                    'type': 'content-duplication',
                    'severity': 'P1',
                    'pages': [slide_summaries[i]['page'], slide_summaries[j]['page']],
                    'jaccard': round(jaccard, 2),
                    'detail': f"페이지 {slide_summaries[i]['page']}와 {slide_summaries[j]['page']} 유사도 {jaccard:.0%}",
                    'fix': '중복 콘텐츠 제거 또는 차별화'
                })

    return issues


def check_scroll_snap_css(html_content):
    """scroll-snap 설정이 올바른지 검증"""
    issues = []
    has_snap_type = 'scroll-snap-type: y mandatory' in html_content
    has_snap_align = 'scroll-snap-align: start' in html_content

    if not has_snap_type:
        issues.append({
            'type': 'missing-scroll-snap-type',
            'severity': 'P0',
            'detail': 'html에 scroll-snap-type: y mandatory 누락',
            'fix': 'html { scroll-snap-type: y mandatory; } 추가'
        })
    if not has_snap_align:
        issues.append({
            'type': 'missing-scroll-snap-align',
            'severity': 'P0',
            'detail': '.slide에 scroll-snap-align: start 누락',
            'fix': '.slide { scroll-snap-align: start; } 추가'
        })

    return issues


def main():
    if len(sys.argv) < 2:
        print("사용법: python3 validate-slides.py <deck.html> [--strict]")
        sys.exit(1)

    file_path = sys.argv[1]
    strict = '--strict' in sys.argv

    with open(file_path, 'r', encoding='utf-8') as f:
        html = f.read()

    # 파싱
    parser = SlideParser()
    parser.feed(html)
    slides = parser.slides

    print(f"📊 {len(slides)}개 슬라이드 검증 중...\n")

    all_issues = []
    all_issues.extend(check_text_overflow(slides, strict))
    all_issues.extend(check_compare_layout(html))
    all_issues.extend(check_navigation_js(html))
    all_issues.extend(check_content_duplication(slides))
    all_issues.extend(check_scroll_snap_css(html))

    # 결과 출력
    severity_order = {'P0': 0, 'P1': 1, 'P2': 2}
    all_issues.sort(key=lambda x: severity_order.get(x['severity'], 99))

    if not all_issues:
        print("✅ 모든 검증 통과!")
        sys.exit(0)

    p0 = [i for i in all_issues if i['severity'] == 'P0']
    p1 = [i for i in all_issues if i['severity'] == 'P1']
    p2 = [i for i in all_issues if i['severity'] == 'P2']

    print(f"검증 결과: {len(all_issues)}개 이슈 발견")
    print(f"  🔴 P0: {len(p0)}개 (즉시 수정 필요)")
    print(f"  🟡 P1: {len(p1)}개 (권장)")
    print(f"  🟢 P2: {len(p2)}개 (참고)")
    print()

    for issue in all_issues:
        sev = issue['severity']
        icon = '🔴' if sev == 'P0' else '🟡' if sev == 'P1' else '🟢'
        page = f" (P{issue['page']})" if 'page' in issue else ''
        pages = f" (P{issue['pages'][0]}↔P{issue['pages'][1]})" if 'pages' in issue else ''
        print(f"  {icon} [{sev}] {issue['type']}{page}{pages}")
        print(f"     → {issue.get('detail', issue.get('text', 'N/A'))}")
        print(f"     → 해결: {issue.get('fix', 'N/A')}")
        print()

    # JSON 출력
    output = {
        'total': len(all_issues),
        'p0': len(p0),
        'p1': len(p1),
        'p2': len(p2),
        'issues': all_issues
    }
    print(json.dumps(output, ensure_ascii=False, indent=2))

    sys.exit(1 if p0 else 0)


if __name__ == '__main__':
    main()
