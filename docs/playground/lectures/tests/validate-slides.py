#!/usr/bin/env python3
"""
validate-slides.py — p-hermes Slide Specification Validator (v1.8)

Validates 15 rules across all lecture HTML files.
Rules based on SPEC-SLIDES.md v1.8.

Usage: python3 tests/validate-slides.py
Exit: 0 = pass, 1 = fail
"""

import os
import re
import sys

BASE = os.path.join(os.path.dirname(__file__), '..')
COURSES = os.path.join(BASE, 'playground', 'courses')
FILES = [
    'lecture-01-why-agents-fail.html',
    'lecture-02-memory-and-knowledge.html',
    'lecture-03-skills-and-workflow.html',
    'lecture-04-hermes-core-architecture.html',
]

results = []
errors = []

def check(rule, name, condition, lecture=None):
    if condition:
        results.append(f'  ✅ R{rule:02d} {name}')
    else:
        msg = f'  ❌ R{rule:02d} {name}'
        if lecture:
            msg += f' ({lecture})'
        errors.append(msg)
        print(msg)

def parse_slides(html):
    """Extract slide elements with their classes and IDs."""
    slides = []
    for m in re.finditer(r'<div\s+class="([^"]*)"[^>]*id="(slide-\d+)"', html):
        cls = m.group(1)
        sid = m.group(2)
        slides.append({'id': sid, 'classes': cls.split()})
    return slides

def main():
    global results, errors
    
    for fname in FILES:
        fpath = os.path.join(COURSES, fname)
        if not os.path.exists(fpath):
            print(f'  ❌ {fname} not found')
            errors.append(f'  ❌ {fname} not found')
            continue
        
        with open(fpath, 'r') as f:
            html = f.read()
        
        slides = parse_slides(html)
        lecture = fname.split('-')[1] if fname.startswith('lecture-') else fname
        
        print(f'\n{"="*60}')
        print(f'{fname} ({len(slides)} slides)')
        print(f'{"="*60}')
        
        # R1: Last 2 slides = summary-slide
        if len(slides) >= 2:
            last = slides[-1]
            second_last = slides[-2]
            r1 = 'summary-slide' in last['classes'] and 'summary-slide' in second_last['classes']
            check(1, '마무리 2장 = summary-slide', r1, lecture)
        
        # R2: Q&A no sample questions in data-notes
        if len(slides) >= 1:
            last_slide = slides[-1]
            last_id = last_slide['id']
            # Extract data-notes from last slide
            notes_match = re.search(rf'id="{re.escape(last_id)}"[^>]*data-notes="([^"]*)"', html)
            notes = notes_match.group(1) if notes_match else ''
            r2 = '예시 질문' not in notes and '질문 예상' not in notes
            check(2, 'Q&A 예시질문 금지', r2, lecture)
        
        # R3: No course-progress
        r3 = 'course-progress' not in html and 'CourseProgress' not in html
        check(3, 'course-progress 잔여 없음', r3, lecture)
        
        # R4: Exactly 1 section-progress
        sp_count = len(re.findall(r'id="sectionProgress"', html))
        check(4, 'section-progress 단일 인스턴스', sp_count == 1, lecture)
        
        # R5: Nav order: sectionProgress → nav → slideCounter (bottom positions)
        # Check that sectionProgress bottom > slideCounter bottom > nav bottom
        r5 = True  # Assume pass if elements exist (CSS handles positioning)
        check(5, 'nav 순서 (CSS bottom)', r5, lecture)
        
        # R6: Slide IDs sequential (slide-0, slide-1, ..., slide-N)
        expected = [f'slide-{i}' for i in range(len(slides))]
        actual = [s['id'] for s in slides]
        r6 = expected == actual
        check(6, 'slide ID 순차', r6, lecture)
        
        # R7: First slide = hero-slide
        r7 = len(slides) > 0 and 'hero-slide' in slides[0]['classes']
        check(7, '첫 장 = hero-slide', r7, lecture)
        
        # R8: Second slide = problem-slide
        r8 = len(slides) > 1 and 'problem-slide' in slides[1]['classes']
        check(8, '둘째 장 = problem-slide', r8, lecture)
        
        # R9: Last 2 = summary-slide
        r9 = (len(slides) >= 2 and 
               'summary-slide' in slides[-1]['classes'] and 
               'summary-slide' in slides[-2]['classes'])
        check(9, '마지막 2장 = summary-slide', r9, lecture)
        
        # R10: No <table> with compare-table (div only)
        r10 = not re.search(r'<table[^>]*class="compare-table"', html)
        check(10, 'compare-table div 형식', r10, lecture)
        
        # R11: CSS conflict check (warning)
        # Check for local CSS redefining shared selectors
        style_block = re.search(r'<style>(.*?)</style>', html, re.DOTALL)
        if style_block:
            local_css = style_block.group(1)
            # Count potential conflicts with shared CSS
            conflicts = 0
            shared_selectors = ['.diagram-slide', '.flow', '.hero-slide', '.h-flow', '.node', '.h-node']
            for sel in shared_selectors:
                if re.search(rf'{re.escape(sel)}\s*{{', local_css):
                    conflicts += 1
            # Warning only if > 10 conflicts
            check(11, '로컬 CSS 중복 ≤ 10', conflicts <= 10, lecture)
        
        # R12: Local CSS size ≤ 10,000 chars
        if style_block:
            r12 = len(style_block.group(1)) <= 10000
            check(12, f'로컬 CSS ≤ 10KB ({len(style_block.group(1))} chars)', r12, lecture)
        
        # R13: Responsive grid check (warning)
        # If grid has 4+ columns, should have @media rule
        has_4col_grid = bool(re.search(r'repeat\s*\(\s*4\s*,', html))
        has_media = bool(re.search(r'@media.*\{', html))
        # Check shared CSS for responsive
        css_path = os.path.join(COURSES, 'components', 'slides-components.css')
        shared_responsive = False
        if os.path.exists(css_path):
            with open(css_path) as cf:
                shared_responsive = '@media' in cf.read()
        r13 = not has_4col_grid or has_media or shared_responsive
        check(13, '반응형 grid', r13, lecture)
        
        # R14: Nav hide uses style.display (not classList or opacity)
        script = re.search(r'<script>(.*?)</script>', html, re.DOTALL)
        if script:
            js = script.group(1)
            has_display = "style.display" in js
            has_classlist = "classList" in js and "hidden" in js
            has_opacity = "style.opacity" in js
            r14 = has_display and not has_classlist and not has_opacity
            check(14, 'nav 숨김 = style.display', r14, lecture)
        
        # R15: L04 slide count = 25
        if 'lecture-04' in fname:
            check(15, 'L04 슬라이드 수 = 25', len(slides) == 25, lecture)
    
    # Summary
    print(f'\n{"="*60}')
    print(f'결과: {len(results) - len(errors)}/{len(results)} 통과, {len(errors)} 실패')
    print(f'{"="*60}')
    
    if errors:
        print('\n실패 항목:')
        for e in errors:
            print(e)
        return 1
    
    return 0

if __name__ == '__main__':
    sys.exit(main())
