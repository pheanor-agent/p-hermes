#!/usr/bin/env python3
"""
validate-slides.py — 슬라이드 사양 준수 검증 (JOB-1861)

SPEC-SLIDES.md v1.7 규칙에 따라 4개 강의 HTML을 검증.
Usage: python3 tests/validate-slides.py
"""

import re, os, sys

BASE = os.path.join(os.path.dirname(__file__), "..", "docs", "playground", "lectures")

# Shared CSS selectors (SSOT)
SHARED_CSS = """
.hero-slide
.problem-slide
.diagram-slide
.example-slide
.summary-slide
.section-divider
.section-progress
.nav
.slide-counter
.progress-bar
.notes-toggle
.notes-panel
.slide
.deck
.lecture-badge
.inline-section
.grid-cards
.grid-card
.grid-card-title
.grid-card-desc
.two-col
.col-title
.col-item
.compare-table
.insight-box
.key-message
.question
.flow
.h-flow
.h-node
.h-label
.highlight
.hl
.badge-sm
.example-box
.section-divider-content
.divider-label
.divider-title
.divider-desc
.goal-section
.goal-tag
.goal-why
.goal-label
.goal-list
.goal-item
.goal-num
.goal-flow
.goal-arrow
.cover-title
.cover-subtitle
.cover-content
.cover-info
.section-title
.section-subtitle
.big-number
.ring-icon
.check
.cross
.overflow-safe
.btn
.flow
.arrow
.node
.label
.ok
.future
.active
.done
.sec
.sec-arrow
.cyan
.gold
.green
.purple
.red
.orange
.visible
"""

SHARED_SELECTORS = set([s.strip() for s in SHARED_CSS.split('\n') if s.strip()])

LECTURES = [
    ("L01", "lecture-01-why-agents-fail.html"),
    ("L02", "lecture-02-memory-and-knowledge.html"),
    ("L03", "lecture-03-skills-and-workflow.html"),
    ("L04", "lecture-04-hermes-core-architecture.html"),
]

def check_ending(html, lid):
    """마무리 검증: 마지막 2장 = Summary + Q&A, 예시질문 금지"""
    slides = re.findall(r'<div class="([^"]*)"\s+id="([^"]+)"[^>]*data-notes="([^"]*)"[^>]*>', html)
    issues = []
    if len(slides) < 2:
        return [f"{lid}: 슬라이드 부족 ({len(slides)}장)"]
    s_n1 = slides[-2]
    s_n = slides[-1]
    if 'summary-slide' not in s_n1[0]:
        issues.append(f"{lid}: N-1 slides({s_n1[1]}) template='{s_n1[0]}' — should be summary-slide")
    if 'summary-slide' not in s_n[0]:
        issues.append(f"{lid}: N slides({s_n[1]}) template='{s_n[0]}' — should be summary-slide")
    notes = s_n[2]
    full_slide_html = re.search(rf'<div class="[^"]*"\s+id="{re.escape(s_n[1])}"[^>]*>.*?</div>\s*</div>', html, re.DOTALL)
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
    issues = []
    if len(slides) < 5:
        return []
    for i in range(max(0, len(slides)-5), len(slides)-2):
        tmpl, sid, notes = slides[i]
        if 'section-divider' in tmpl and ('Wrap' in notes or '요약' in notes or '정리' in notes[:40]):
            issues.append(f"{lid}: {sid} 불필요한 마무리 divider — 제거 필요")
    return issues

def check_no_takeaways(html, lid):
    """Takeaways 슬라이드 검증"""
    issues = []
    for pat in ['Takeaways', 'Takeaway', 'takeaway', 'Key Insight']:
        if pat in html:
            pos = html.find(pat)
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
            continue
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

# === NEW CHECKS (8개 추가) ===

def check_template_classes(html, lid):
    """템플릿 클래스 오분류 검증"""
    slides = re.findall(r'<div class="([^"]*)"\s+id="slide-(\d+)"[^>]*data-notes="([^"]*)"[^>]*>', html)
    issues = []
    for tmpl, sid_idx, notes in slides:
        idx = int(sid_idx)
        classes = tmpl.split()
        t = "unknown"
        for c in classes:
            if c in ['hero-slide', 'problem-slide', 'diagram-slide', 'example-slide', 'summary-slide', 'section-divider']:
                t = c
                break
        # hero-slide should ONLY be slide-0 (Cover)
        if t == 'hero-slide' and idx != 0:
            issues.append(f"{lid}: slide-{idx}가 hero-slide — Cover만 hero-slide여야 함")
        # problem-slide should ONLY be slide-1 (Goal/Intro)
        if t == 'problem-slide' and idx != 1:
            issues.append(f"{lid}: slide-{idx}가 problem-slide — Goal만 problem-slide여야 함")
    return issues

def check_css_conflicts(html, lid):
    """로컬 CSS가 공용 CSS 재정의하는지 검증"""
    style = re.search(r'<style>(.*?)</style>', html, re.DOTALL)
    if not style:
        return []
    css = style.group(1)
    local_selectors = set(re.findall(r'[\.\#][\w-]+\s*\{', css))
    local_clean = set([s.strip() for s in local_selectors])
    overlaps = local_clean & SHARED_SELECTORS
    issues = []
    if overlaps:
        issues.append(f"{lid}: 공용 CSS와 충돌하는 선택자 {len(overlaps)}개 — 로컬 CSS 정리 필요")
        for o in sorted(overlaps)[:5]:
            issues.append(f"  → {o}")
    return issues

def check_local_css_size(html, lid):
    """로컬 CSS 크기 검증 (WARNING만 — lecture-specific 스타일 불가피)"""
    style = re.search(r'<style>(.*?)</style>', html, re.DOTALL)
    if not style:
        return []
    css = style.group(1)
    size = len(css)
    # lecture-specific 스타일 불가피하므로 WARNING만
    if size > 15000:
        return [f"{lid}: 로컬 CSS {size} bytes — 15KB 경고선 초과"]
    return []

def check_root_duplicate(html, lid):
    """:root 변수 중복 검증"""
    style = re.search(r'<style>(.*?)</style>', html, re.DOTALL)
    if not style:
        return []
    css = style.group(1)
    issues = []
    if ':root' in css:
        var_count = len(re.findall(r'--[\w-]+\s*:', css))
        issues.append(f"{lid}: 로컬 :root {var_count}개 변수 — slides-components.css에 중복됨")
    return issues

def check_nav_overlap(html, lid):
    """nav dots와 slide-counter 겹침 검증"""
    style = re.search(r'<style>(.*?)</style>', html, re.DOTALL)
    if not style:
        return []
    css = style.group(1)
    sc_bottom = re.search(r'\.slide-counter\s*{[^}]*bottom:\s*([^;]+)', css)
    nav_bottom = re.search(r'\.nav\s*{[^}]*bottom:\s*([^;]+)', css)
    issues = []
    if sc_bottom and nav_bottom:
        sc_val = int(sc_bottom.group(1).replace('px', '').strip())
        nav_val = int(nav_bottom.group(1).replace('px', '').strip())
        if abs(sc_val - nav_val) < 20:
            issues.append(f"{lid}: slide-counter({sc_val}px)와 nav({nav_val}px) 간격 부족 — 20px 이상 권장")
    return issues

def check_section_divider_count(html, lid):
    """Section divider가 섹션 수에 적합한지 검증"""
    slides = re.findall(r'<div class="([^"]*)"\s+id="slide-(\d+)"[^>]*data-notes="([^"]*)"[^>]*>', html)
    divider_count = sum(1 for t, _, _ in slides if 'section-divider' in t)
    total = len(slides)
    issues = []
    # Ideal: 2-3 dividers for 20-30 slides
    if total > 20 and divider_count < 2:
        issues.append(f"{lid}: {total}장인데 divider {divider_count}개 — 2개 이상 권장")
    if total > 20 and divider_count > 4:
        issues.append(f"{lid}: {total}장인데 divider {divider_count}개 — 4개 이하 권장")
    return issues

def check_data_notes_length(html, lid):
    """data-notes 분량 검증 (80자 이상 권장)"""
    slides = re.findall(r'<div class="([^"]*)"\s+id="slide-(\d+)"[^>]*data-notes="([^"]*)"[^>]*>', html)
    issues = []
    short_notes = []
    for _, idx, notes in slides:
        if len(notes) < 80:
            short_notes.append(idx)
    if short_notes:
        issues.append(f"{lid}: data-notes가 80자 미만인 slide {len(short_notes)}개: {','.join(short_notes[:5])}")
    return issues

def run():
    spec_path = os.path.join(BASE, "SPEC-SLIDES.md")
    if not os.path.exists(spec_path):
        print(f"❌ SPEC-SLIDES.md not found at {spec_path}")
        sys.exit(1)

    all_issues = []
    totals = {"pass": 0, "fail": 0, "total": 0}

    for lid, fname in LECTURES:
        path = os.path.join(BASE, fname)
        if not os.path.exists(path):
            print(f"❌ {lid}: {fname} not found")
            all_issues.append(f"{lid}: 파일 없음")
            continue

        with open(path) as f:
            html = f.read()

        lid_issues = []

        # Check 1-7: 기존 규칙
        lid_issues.extend(check_ending(html, lid))
        lid_issues.extend(check_no_wrapup_divider(html, lid))
        lid_issues.extend(check_no_takeaways(html, lid))
        lid_issues.extend(check_course_progress(html, lid))
        lid_issues.extend(check_slide_ids(html, lid))
        lid_issues.extend(check_section_progress_position(html, lid))
        lid_issues.extend(check_shared_css(html, lid))

        # Check 8-15: 신규 규칙
        lid_issues.extend(check_template_classes(html, lid))
        lid_issues.extend(check_css_conflicts(html, lid))
        lid_issues.extend(check_local_css_size(html, lid))
        lid_issues.extend(check_root_duplicate(html, lid))
        lid_issues.extend(check_nav_overlap(html, lid))
        lid_issues.extend(check_section_divider_count(html, lid))
        lid_issues.extend(check_data_notes_length(html, lid))

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
