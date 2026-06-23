#!/usr/bin/env python3
"""
강의 슬라이드 TEMPLATE.md 준수 검증 스크립트.
사용법: python3 validate-course.py <lecture.html>
반환값: 0 (통과), 1 (경고), 2 (실패)
"""
import re
import sys
from pathlib import Path

def check_slide_structure(html, path):
    errors = []
    warnings = []
    lines = html.split('\n')
    
    # 1. lecture-badge 확인
    lecture_badge_class_count = html.count('class="lecture-badge"')
    if lecture_badge_class_count == 0:
        errors.append("lecture-badge 없음")
    
    # 2. hero ring 확인 (첫 슬라이드 필수)
    hero_ring = 'class="ring"' in html
    if not hero_ring:
        warnings.append("첫 슬라이드에 hero ring 없음 (선택사항)")
    
    # 3. two-col max-width 확인
    two_col_maxwidths = re.findall(r'max-width:\s*(\d+px)', html)
    if any(mw != '640px' for mw in two_col_maxwidths if 'two-col' in html[:html.index(mw) if mw in html else 0]):
        # 간단히 검사: 900px max-width 찾기
        if 'max-width: 900px' in html and '.two-col' in html:
            warnings.append(".two-col max-width가 900px (TEMPLATE.md: 640px)")
    
    # 4. slide-counter 확인
    if 'slide-counter' not in html:
        warnings.append("slide-counter 없음")
    
    # 5. data-notes 확인
    slide_count = len(re.findall(r'id="slide-\d+"', html))
    notes_count = html.count('data-notes=')
    if notes_count < slide_count:
        warnings.append(f"발표자 노트 누락: {notes_count}/{slide_count} 슬라이드")
    
    # 6. slide-{n} ID 형식 확인
    slide_ids = re.findall(r'id="slide-(\d+)"', html)
    if slide_ids:
        ids = [int(x) for x in slide_ids]
        expected = list(range(len(ids)))
        if ids != expected:
            errors.append(f"slide ID 불일치: {ids[0]}~{ids[-1]} (예상: {expected[0]}~{expected[-1]})")
    
    # 7. compact flow 확인 (5+ 노드 슬라이드)
    flows = re.findall(r'<div class="flow[^"]*">', html)
    for f in flows:
        if 'compact' not in f:
            node_count = len(re.findall(r'<div class="node[^"]*">', html.split(f)[1].split('</div>')[0] if '</div>' in html.split(f)[1] else ''))
            if node_count >= 4:
                # 이건 정확하지 않아서 경고만
                pass
    
    # 8. JS 패턴 확인
    if 'deck.scrollLeft' not in html or 'slideCounter' not in html:
        warnings.append("JS 네비게이션 패턴 불일치")
    
    # 9. 슬라이드 수 확인
    if slide_count < 15:
        warnings.append(f"슬라이드 수 적음: {slide_count}장")
    
    # 10. lecture-badge 개수 = 슬라이드 개수 확인
    if lecture_badge_class_count != slide_count:
        warnings.append(f"lecture-badge 불일치: {lecture_badge_class_count}/{slide_count} 슬라이드")
    
    return errors, warnings


def main():
    if len(sys.argv) < 2:
        print("사용법: python3 validate-course.py <lecture.html>")
        sys.exit(1)
    
    path = Path(sys.argv[1])
    if not path.exists():
        print(f"❌ 파일 없음: {path}")
        sys.exit(2)
    
    html = path.read_text(encoding='utf-8')
    errors, warnings = check_slide_structure(html, path)
    
    if errors:
        print(f"❌ [{path.name}] 템플릿 위반 ({len(errors)}개):")
        for e in errors:
            print(f"   - {e}")
    
    if warnings:
        print(f"⚠️  [{path.name}] 경고 ({len(warnings)}개):")
        for w in warnings:
            print(f"   - {w}")
    
    if not errors and not warnings:
        print(f"✅ [{path.name}] 템플릿 준수 확인")
        sys.exit(0)
    elif not errors:
        print(f"⚠️ [{path.name}] 경고만 있음")
        sys.exit(1)
    else:
        sys.exit(2)


if __name__ == '__main__':
    main()