#!/usr/bin/env python3
"""
validate-playground-index.py — 인덱스 페이지 데이터 정확성 검증 (JOB-2064)

USAGE: python3 tests/validate-playground-index.py
"""

import re, os, sys

BASE = os.path.join(os.path.dirname(__file__), "..", "docs", "playground")
INDEX = os.path.join(BASE, "index.html")


def count_slides_in_file(html_path):
    """HTML 파일 내 .slide class 수 카운트"""
    try:
        with open(html_path) as f:
            content = f.read()
        return len(re.findall(r'class="[^"]*slide[^"]*"\s+id="slide-\d+"', content))
    except Exception:
        return 0


def check_placeholder_links(html):
    """IDX-04: href='#' 플레이스홀더 없음"""
    placeholders = re.findall(r'href="#"[^>]*>([^<]+)</a>', html)
    return [f"IDX-04: Placeholder link found: '{p}'" for p in placeholders]


def check_version_table(html, base):
    """IDX-01~03: Lecture Courses 테이블 검증"""
    errors = []
    archive = os.path.join(base, "lectures", "archive")

    if not os.path.isdir(archive):
        return ["IDX-01: lectures/archive/ directory not found"]

    # 실제 버전 데이터 수집
    actual_versions = {}
    for entry in sorted(os.listdir(archive)):
        if not entry.startswith("v") or not os.path.isdir(os.path.join(archive, entry)):
            continue
        ver_dir = os.path.join(archive, entry)
        html_files = [f for f in os.listdir(ver_dir) if f.endswith(".html")]
        total_slides = sum(count_slides_in_file(os.path.join(ver_dir, hf)) for hf in html_files)
        actual_versions[entry] = {"lectures": len(html_files), "slides": total_slides}

    # index.html에서 버전 테이블 파싱
    # 테이블 패턴: <tr><td><strong>vX.X</strong></td><td>N</td><td>N</td>...
    table_rows = re.findall(
        r'<tr><td><strong>(v\d+\.\d+)</strong></td><td>(\d+)</td><td>(~?\d+)</td>',
        html
    )

    for ver, claimed_lectures, claimed_slides in table_rows:
        if ver in actual_versions:
            actual = actual_versions[ver]
            # IDX-02: 강의 수 검증
            if int(claimed_lectures) != actual["lectures"]:
                errors.append(
                    f"IDX-02: {ver} lectures mismatch — index: {claimed_lectures}, actual: {actual['lectures']}"
                )
            # IDX-03: 슬라이드 수 검증 (±10% 허용)
            claimed_slides_int = int(claimed_slides.replace("~", ""))
            actual_slides = actual["slides"]
            if actual_slides > 0:
                diff_pct = abs(claimed_slides_int - actual_slides) / actual_slides * 100
                if diff_pct > 10:
                    errors.append(
                        f"IDX-03: {ver} slides mismatch — index: {claimed_slides}, actual: {actual_slides} ({diff_pct:.0f}% diff)"
                    )

    return errors


def check_concept_decks(html, base):
    """IDX-05: Concept Decks 링크 ↔ ops/ 실제 경로"""
    errors = []
    ops = os.path.join(base, "ops")

    if not os.path.isdir(ops):
        return ["IDX-05: ops/ directory not found"]

    # 실제 ops 버전 수집
    actual_ops = {}
    for entry in sorted(os.listdir(ops)):
        entry_path = os.path.join(ops, entry)
        if not os.path.isdir(entry_path):
            continue
        html_count = len([f for f in os.listdir(entry_path) if f.endswith(".html")])
        actual_ops[entry] = html_count

    # Concept Decks 테이블에서 v2~v5 확인
    concept_decks = re.findall(r'<tr><td><strong>(v\d+)</strong></td>', html)
    for ver in concept_decks:
        if ver not in actual_ops:
            errors.append(f"IDX-05: Concept {ver} in table but ops/{ver} does not exist")
        elif actual_ops[ver] == 0:
            errors.append(f"IDX-05: ops/{ver} has no HTML files but shown in table")

    return errors


def check_archive_link(html, base):
    """IDX-06: Archive 링크 ↔ 실제 아카이브 존재"""
    errors = []
    archive = os.path.join(base, "lectures", "archive")
    if "lectures/archive/" in html or "archive/" in html:
        if not os.path.isdir(archive):
            errors.append("IDX-06: Archive link in index but lectures/archive/ does not exist")
    return errors


def main():
    if not os.path.exists(INDEX):
        print(f"ERROR: {INDEX} not found")
        return False

    with open(INDEX) as f:
        html = f.read()

    all_issues = []
    all_issues.extend(check_placeholder_links(html))
    all_issues.extend(check_version_table(html, BASE))
    all_issues.extend(check_concept_decks(html, BASE))
    all_issues.extend(check_archive_link(html, BASE))

    if all_issues:
        print(f"FAIL: {len(all_issues)} issues found:")
        for issue in all_issues:
            print(f"  - {issue}")
        return False

    print("PASS: Playground index validation passed")
    return True


if __name__ == "__main__":
    sys.exit(0 if main() else 1)
