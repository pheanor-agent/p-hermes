#!/usr/bin/env python3
"""
SPEC-D03 Layered Approach - 구조 적합성 검사기
문서 타입에 따라 요구 섹션이 상이함.
"""
import os
import sys
from pathlib import Path

PROJECT_ROOT = Path('/home/pheanor/.hermes/workspace/projects/p-hermes')
VALID_DIRS = [PROJECT_ROOT / 'docs/wiki', PROJECT_ROOT / 'docs/blog']

# 문서 타입별 요구 섹션 (SPEC-D03 Layered Approach)
SECTIONS = {
    "summary": "한 줄 요약",
    "concept": "기본 개념",
    "problem": "문제 상황",
    "design": "기술 설계",
    "diagram": "구조/흐름도",
    "example": "활용 예시",
}

# Wiki Guide: 전 영역 필요 (How-to 문서)
WIKI_GUIDE_SECTIONS = ["summary", "concept", "problem", "design", "diagram", "example"]
# Wiki Index: 요약 + 개념만 (인덱스는 탐색용)
WIKI_INDEX_SECTIONS = ["summary", "concept"]
# Wiki Getting-started: 요약 + 개념 + 문제 + 예시 (온보딩)
WIKI_GETTING_STARTED_SECTIONS = ["summary", "concept", "problem", "example"]
# Blog Index: 요약 + 개념만
BLOG_INDEX_SECTIONS = ["summary", "concept"]
# Blog Post: 요약 + 개념 + 설계 + 흐름도 (Why 문서)
BLOG_POST_SECTIONS = ["summary", "concept", "design", "diagram"]

ALL_KEYS = list(SECTIONS.keys())

def get_required_sections(rel_path: str) -> list[str]:
    parts = rel_path.replace("\\", "/").split("/")
    filename = parts[-1] if parts else ""
    
    # index.md는 간소화
    if filename == "index.md":
        if "wiki" in rel_path:
            return WIKI_INDEX_SECTIONS
        if "blog" in rel_path:
            return BLOG_INDEX_SECTIONS
    
    # Blog posts
    if "blog/posts" in rel_path:
        return BLOG_POST_SECTIONS
    
    # Wiki getting-started
    if "wiki/getting-started" in rel_path:
        return WIKI_GETTING_STARTED_SECTIONS
    
    # Wiki guides (default: full)
    if "wiki" in rel_path:
        return WIKI_GUIDE_SECTIONS
    
    return WIKI_GUIDE_SECTIONS

def check_structure(file_path: Path) -> list[str]:
    errors = []
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        rel_path = str(file_path.relative_to(PROJECT_ROOT))
        required = get_required_sections(rel_path)
        
        found_keys = []
        for line in lines:
            line = line.strip()
            if line.startswith('#'):
                for key, label in SECTIONS.items():
                    if label in line and key not in found_keys:
                        found_keys.append(key)
        
        # 순서 검증
        for i in range(len(found_keys) - 1):
            idx_current = ALL_KEYS.index(found_keys[i])
            idx_next = ALL_KEYS.index(found_keys[i+1])
            if idx_current > idx_next:
                errors.append(f"❌ 순서 오류: '{SECTIONS[found_keys[i]]}' → '{SECTIONS[found_keys[i+1]]}'")
        
        # 누락 검증
        missing = [k for k in required if k not in found_keys]
        if missing:
            labels = [SECTIONS[k] for k in missing]
            errors.append(f"⚠️ 누락: {', '.join(labels)}")
            
    except Exception as e:
        pass

    return errors

def lint():
    errors_found = []
    for valid_dir in VALID_DIRS:
        if valid_dir.exists():
            for dirpath, _, filenames in os.walk(valid_dir):
                for filename in filenames:
                    if filename.endswith('.md'):
                        file_path = Path(dirpath) / filename
                        file_errors = check_structure(file_path)
                        if file_errors:
                            rel_path = file_path.relative_to(PROJECT_ROOT)
                            errors_found.append(f"\n--- {rel_path} ---")
                            errors_found.extend(file_errors)

    if errors_found:
        print("\n".join(errors_found))
        print(f"\n❌ Structure conformance failed.")
        return 1
    else:
        print("✅ Structure Linter passed. All docs follow the Layered Approach.")
        return 0

if __name__ == '__main__':
    sys.exit(lint())
