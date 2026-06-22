#!/usr/bin/env python3
import os
import re
import sys
from pathlib import Path

# Strictly limit to p-hermes documentation artifacts to avoid scanning runtime skills
PROJECT_ROOT = Path('/home/pheanor/.hermes/workspace/projects/p-hermes')

VALID_DIRS = [
    PROJECT_ROOT / 'docs',
    PROJECT_ROOT / 'archive/docs',
]

# Playground 디렉토리는 실험 공간 - 링크 검증 제외
EXCLUDE_DIRS = [
    'docs/playground',
]

VALID_ROOT_FILES = [
    PROJECT_ROOT / 'README.md',
    PROJECT_ROOT / 'ARCHITECTURE.md',
]

def find_markdown_files():
    md_files = list(VALID_ROOT_FILES)
    for valid_dir in VALID_DIRS:
        if valid_dir.exists():
            for dirpath, _, filenames in os.walk(valid_dir):
                rel = Path(dirpath).relative_to(PROJECT_ROOT).as_posix()
                skip = False
                for excl in EXCLUDE_DIRS:
                    if rel.startswith(excl):
                        skip = True
                        break
                if skip:
                    continue
                for filename in filenames:
                    if filename.endswith('.md'):
                        md_files.append(Path(dirpath) / filename)
    return md_files

def remove_code_blocks(content):
    content = re.sub(r'```.*?```', '', content, flags=re.DOTALL)
    content = re.sub(r'`[^`]*`', '', content)
    return content

def extract_links(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception:
        return []

    content = remove_code_blocks(content)
    links = re.findall(r'\[([^\]]+)\]\(([^)]+)\)', content)

    internal_links = []
    for text, link in links:
        if not link.startswith(('http', 'https', 'mailto', '#')):
            if not re.search(r'\{|\}', link) and link not in ['url', 'link', 'path']:
                internal_links.append(link)

    return internal_links

def validate():
    md_files = find_markdown_files()
    errors = []

    for md_file in md_files:
        links = extract_links(md_file)
        source_dir = md_file.parent

        for link in links:
            try:
                target_path = (source_dir / link).resolve()
                if not target_path.is_file():
                    rel_source = md_file.relative_to(PROJECT_ROOT)
                    clean_link = link.split('#')[0]
                    errors.append(f"ERROR {rel_source}: '{clean_link}' -> not found")
            except Exception:
                pass

    if errors:
        print("\n".join(errors))
        print(f"\nFAILED Found {len(errors)} broken link(s) in p-hermes docs.")
        return 1
    else:
        print("PASSED Full-Graph Validation passed. All p-hermes internal links are valid.")
        return 0

if __name__ == '__main__':
    sys.exit(validate())
