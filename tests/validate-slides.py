#!/usr/bin/env python3
"""
validate-slides.py — 슬라이드 사양 준수 검증 (JOB-1860)

SPEC-SLIDES.md v1.7 규칙에 따라 4개 강의 HTML을 검증.
Usage: python3 tests/validate-slides.py
"""

import re, os, sys

BASE = os.path.join(os.path.dirname(__file__), "..", "docs", "playground", "courses")
LECTURES = [
    ("L01", "lecture-01-why-agents-fail.html", {
        "total_slides": 24,  # after removing Wrap-Up divider + Takeaways
        "sections": {"문제 인식": (0, 5), "4가지 패턴": (5, 12), "해결: Agent OS": (12, 22)},
    }),
    ("L02", "lecture-02-memory-and-knowledge.html", {
        "total_slides": 25,
        "sections": {"Memory vs Knowledge": (0, 10), "Memory 관리": (10, 18), "Memory만으로 부족": (18, 23)},
    }),
    ("L03", "lecture-03-skills-and-workflow.html", {
        "total_slides": 28,
        "sections": {"Knowledge → Skills": (0, 5), "Workflow": (5, 18), "Engine": (18, 26)},
    }),
    ("L04", "lecture-04-hermes-core-architecture.html", {
        "total_slides": 25,
        "sections": {"Architecture": (0, 15), "Runtime & SSOT": (15, 23)},
    }),
]

def check_ending(html, lid):
    """마무리 검증: 마지막 2장 = Summary + Q&A, 예시질문 금지"""
    slides = re.findall(r'<div class="([^"]*)"\s+id="([^"]+)"[^>]*data-notes="([^"]*)"[^>]*>', html)
    
    issues = []
    if len(slides) < 2:
        return [f"{lid}: 슬라이드 부족 ({len(slides)}장)"]
    
    # Check last 2 slides
    s_n1 = slides[-2]  # N-1 = Summary
    s_n = slides[-1]   # N = Q&A
    
    # N-1 should be summary-slide
    if 'summary-slide' not in s_n1[0]:
        issues.append(f"{lid}: N-1 slides({s_n1[1]}) template='{s_n1[0]}' — should be summary-slide")
    
    # N should be summary-slide
    if 'summary-slide' not in s_n[0]:
        issues.append(f"{lid}: N slides({s_n[1]}) template='{s_n[0]}' — should be summary-slide")
    
    # N should NOT have example questions in data-notes or visible text
    notes = s_n[2]
    full_slide_html = re.search(
        rf'<div class="[^"]*"\s+id="{re.escape(s_n[1])}"[^>]*>.*?</div>\s*</div>',
        html, re.DOTALL
    )
    if full_slide_html:
        visible = re.sub(r'<[^>]+>', ' ', full_slide_html.group(0))
        visible = re.sub(r'&[a-z]+;', ' ', visible)
    else:
        visible = ""
    
    example_patterns = ['예시 질문', '질문 예상', '청중이 실제로', 'Q1', 'Q2', 'Q3', '실제로 질문할']
    for pat in example_patterns:
        if pat in notes or pat in visible:
            issues.append(f"{lid}: Q&A에 예시 질문 발견 ('{pat}') — 금지됨")
    
    return issues

def check_no_wrapup_divider(html, lid):
    """마무리 전 Wrap-Up Divider 검증"""
    slides = re.findall(r'<div class="([^"]*)"\s+id="([^"]+)"[^>]*data-notes="([^"]*)"[^>]*>', html)
    if len(slides) < 5:
        return []
    
    issues = []
    # Check slide N-2 and N-3 for unnecessary dividers before ending
    for i in range(max(0, len(slides)-5), len(slides)-2):
        tmpl, sid, notes = slides[i]
        if 'section-divider' in tmpl and ('Wrap' in notes or '요약' in notes or '정리' in notes[:40]):
            issues.append(f"{lid}: {sid} 불필요한 마무리 divider — 제거 필요")
    
    return issues

def check_no_takeaways(html, lid):
    """Takeaways 슬라이드 검증"""
    issues = []
    takeaway_patterns = ['Takeaways', 'Takeaway', 'takeaway', 'Key Insight']
    for pat in takeaway_patterns:
        if pat in html:
            # Check if it's a separate slide (not text inside another slide)
            pos = html.find(pat)
            # Find the nearest slide div
            slide_before = html.rfind('<div class="', 0, pos)
            if slide_before >= 0:
                slide_content = html[slide_before:pos+200]
                if 'Takeaway' in slide_content:
                    issues.append(f"{lid}: Takeaways 슬라이드 발견 ('{pat}') — 제거 필요")
                    break
    
    return issues

def check_course_progress(html, lid):
    """course-progress 잔여 검증"""
    issues = []
    count = html.count('course-progress')
    if count > 0:
        # section-progress is allowed (the new nav bar)
        course_prog = re.findall(r'class="course-progress"', html)
        if len(course_prog) > 0:
            issues.append(f"{lid}: 'course-progress'가 {len(course_prog)}개 남아있음 — section-progress로 교체 필요")
    
    return issues

def check_slide_ids(html, lid):
    """슬라이드 ID 검증: 전부 slide-N 형식"""
    issues = []
    ids = re.findall(r'<div class="slide[^"]*"\s+id="([^"]+)"', html)
    for sid in ids:
        if sid == 'slideCounter':
            continue  # DOM element, not a slide
        if not re.match(r'slide-\d+$', sid):
            issues.append(f"{lid}: 비정규 슬라이드 ID '{sid}' — slide-N 형식 필요")
    
    return issues

def check_section_progress_position(html, lid):
    """section-progress가 단일 인스턴스인지 검증"""
    issues = []
    count = html.count('class="section-progress"')
    if count > 1:
        issues.append(f"{lid}: section-progress가 {count}개 — 단일 인스턴스여야 함")
    elif count == 0:
        issues.append(f"{lid}: section-progress 없음")
    
    return issues

def check_shared_css(html, lid):
    """Shared CSS 참조 검증"""
    if 'slides-components.css' not in html:
        return [f"{lid}: slides-components.css 참조 없음"]
    return []

def run():
    spec_path = os.path.join(BASE, "SPEC-SLIDES.md")
    if not os.path.exists(spec_path):
        print(f"❌ SPEC-SLIDES.md not found at {spec_path}")
        sys.exit(1)
    
    all_issues = []
    totals = {"pass": 0, "fail": 0, "total": 0}
    
    for lid, fname, meta in LECTURES:
        path = os.path.join(BASE, fname)
        if not os.path.exists(path):
            print(f"❌ {lid}: {fname} not found")
            all_issues.append(f"{lid}: 파일 없음")
            continue
        
        with open(path) as f:
            html = f.read()
        
        lid_issues = []
        
        # Check 1: Ending format
        lid_issues.extend(check_ending(html, lid))
        
        # Check 2: No Wrap-Up divider
        lid_issues.extend(check_no_wrapup_divider(html, lid))
        
        # Check 3: No Takeaways
        lid_issues.extend(check_no_takeaways(html, lid))
        
        # Check 4: No course-progress remnants
        lid_issues.extend(check_course_progress(html, lid))
        
        # Check 5: Slide IDs
        lid_issues.extend(check_slide_ids(html, lid))
        
        # Check 6: section-progress single instance
        lid_issues.extend(check_section_progress_position(html, lid))
        
        # Check 7: Shared CSS
        lid_issues.extend(check_shared_css(html, lid))
        
        if lid_issues:
            print(f"\n{'='*60}")
            print(f"❌ {lid} — {len(lid_issues)} issues")
            print(f"{'='*60}")
            for issue in lid_issues:
                print(f"  • {issue}")
            all_issues.extend(lid_issues)
            totals["fail"] += 1
        else:
            print(f"✅ {lid} — ALL CHECKS PASSED")
            totals["pass"] += 1
        
        totals["total"] += 1
    
    print(f"\n{'='*60}")
    print(f"결과: {totals['pass']}/{totals['total']} 통과")
    if all_issues:
        print(f"이슈: {len(all_issues)}개")
        return False
    else:
        print("✅ 모든 검증 통과")
        return True

if __name__ == "__main__":
    success = run()
    sys.exit(0 if success else 1)
