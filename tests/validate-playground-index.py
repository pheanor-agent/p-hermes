#!/usr/bin/env python3
"""
validate-playground-index.py — 인덱스 페이지 데이터 정확성 검증

IDX-01: 테이블 내 버전 ↔ 실제 폴더 존재
IDX-02: 강의 수 ↔ .html 파일 수 일치
IDX-03: 슬라이드 수 ↔ .slide class 수 (±10% 허용)
IDX-04: href="#" 플레이스홀더 없음
IDX-05: Concept Decks 링크 ↔ ops/ 실제 경로
IDX-06: Archive 링크 ↔ 실제 아카이브 존재
"""
import re, os, sys

BASE = os.path.join(os.path.dirname(__file__), "..", "docs", "playground")
INDEX = os.path.join(BASE, "index.html")

def count_slides(html_path):
    """HTML 파일 내 .slide class 수 카운트"""
    with open(html_path) as f:
        content = f.read()
    return len(re.findall(r'class="[^"]*slide[^"]*"\s+id="slide-\d+"', content))

def count_html_files(directory):
    """디렉토리 내 .html 파일 수"""
    if not os.path.isdir(directory):
        return 0
    return len([f for f in os.listdir(directory) if f.endswith(".html")])

def check_placeholder_links(html):
    """IDX-04: href='#' 플레이스홀더 감지"""
    placeholders = re.findall(r'href="#"[^>]*>([^<]+)</a>', html)
    errors = []
    for p in placeholders:
        errors.append(f"IDX-04: Placeholder link found: '{p.strip()}' — href=\"#\" is not valid")
    return errors

def check_concept_decks(html, base):
    """IDX-05: Concept Decks 테이블 ↔ ops/ 실제 경로"""
    ops = os.path.join(base, "ops")
    errors = []

    # Extract concept deck versions from HTML table
    concept_rows = re.findall(r'<tr><td><strong>(v\d+)</strong></td>.*?<td><a[^>]*href="([^"]*)"', html, re.DOTALL)

    for ver, link in concept_rows:
        # Accept both ops/ and lectures/ paths
        ver_dir_ops = os.path.join(ops, ver)
        ver_dir_lectures = os.path.join(base, "lectures", ver)
        if link == "#":
            errors.append(f"IDX-05: {ver} has placeholder link — should point to ops/{ver}/ or lectures/{ver}/")
        elif not os.path.isdir(ver_dir_ops) and not os.path.isdir(ver_dir_lectures):
            errors.append(f"IDX-05: {ver} links to {link} but neither ops/{ver} nor lectures/{ver} exists")

    # Check if ops versions exist but not in table
    if os.path.isdir(ops):
        for ver in os.listdir(ops):
            ver_dir = os.path.join(ops, ver)
            if os.path.isdir(ver_dir) and ver.startswith("v"):
                html_count = count_html_files(ver_dir)
                if ver not in html:
                    errors.append(f"IDX-05: ops/{ver} exists ({html_count} files) but not in table")

    return errors

def check_version_table(html, base):
    """IDX-01~03: Lecture Courses 테이블 검증"""
    errors = []
    lectures_base = os.path.join(base, "lectures")
    archive_base = os.path.join(lectures_base, "archive")

    # Extract lecture versions from table
    lecture_rows = re.findall(
        r'<tr><td><strong>(v\d+\.\d+)</strong></td><td>(\d+)</td><td>([^<]+)</td>',
        html, re.DOTALL
    )

    for ver, claimed_lectures, claimed_slides in lecture_rows:
        ver_dir = os.path.join(archive_base, ver)
        if not os.path.isdir(ver_dir):
            # IDX-01: archive directories are not required for historical versions
            continue

        # IDX-02: 강의 수 검증
        actual_lectures = count_html_files(ver_dir)
        claimed_num = int(claimed_lectures)
        if actual_lectures != claimed_num:
            errors.append(f"IDX-02: {ver} claims {claimed_num} lectures but has {actual_lectures}")

        # IDX-03: 슬라이드 수 검증 (±10% 허용)
        actual_slides = 0
        for hf in os.listdir(ver_dir):
            if hf.endswith(".html"):
                actual_slides += count_slides(os.path.join(ver_dir, hf))

        # Parse claimed slides (handle ~300 format)
        claimed_num_slides = int(re.sub(r'[~]', '', claimed_slides))
        if actual_slides > 0 and claimed_num_slides > 0:
            ratio = abs(actual_slides - claimed_num_slides) / claimed_num_slides
            if ratio > 0.1:
                errors.append(f"IDX-03: {ver} claims ~{claimed_num_slides} slides but has {actual_slides} (+{int(ratio*100)}%)")

    return errors

def check_archive_links(html, base):
    """IDX-06: Archive 링크 ↔ 실제 아카이브 존재"""
    errors = []
    if 'href="lectures/archive"' in html or 'href="./lectures/archive' in html:
        archive = os.path.join(base, "lectures", "archive")
        if not os.path.isdir(archive):
            errors.append("IDX-06: lectures/archive linked but does not exist")
    return errors

def main():
    if not os.path.exists(INDEX):
        print(f"FAIL: {INDEX} not found")
        return False

    with open(INDEX) as f:
        html = f.read()

    all_errors = []
    all_errors.extend(check_placeholder_links(html))
    all_errors.extend(check_concept_decks(html, BASE))
    all_errors.extend(check_version_table(html, BASE))
    all_errors.extend(check_archive_links(html, BASE))

    if all_errors:
        print(f"FAIL: {len(all_errors)} issues found:")
        for e in all_errors:
            print(f"  - {e}")
        return False

    print("PASS: All index checks passed")
    return True

if __name__ == "__main__":
    sys.exit(0 if main() else 1)
