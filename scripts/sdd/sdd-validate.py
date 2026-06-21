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

VALID_ROOT_FILES = [
    PROJECT_ROOT / 'README.md',
    PROJECT_ROOT / 'ARCHITECTURE.md',
]

def find_markdown_files():
    """Recursively find all markdown files in valid directories."""
    md_files = list(VALID_ROOT_FILES)
    for valid_dir in VALID_DIRS:
        if valid_dir.exists():
            for dirpath, _, filenames in os.walk(valid_dir):
                for filename in filenames:
                    if filename.endswith('.md'):
                        md_files.append(Path(dirpath) / filename)
    return md_files

def remove_code_blocks(content):
    """Remove code blocks to prevent false positives (e.g., checkpoint=...)."""
    # Remove ```...``` blocks
    content = re.sub(r'```.*?```', '', content, flags=re.DOTALL)
    # Remove inline `code`
    content = re.sub(r'`[^`]*`', '', content)
    return content

def extract_links(file_path):
    """Extract relative internal links from a markdown file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception:
        return []
    
    content = remove_code_blocks(content)
    
    # Match standard markdown links: [text](path)
    links = re.findall(r'\[([^\]]+)\]\(([^)]+)\)', content)
    
    internal_links = []
    for text, link in links:
        # Filter out external and trivial placeholders
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
            # Normalize path to handle ./ and ../
            try:
                # Resolve relative to source file
                target_path = (source_dir / link).resolve()
                
                # Check if file exists
                if not target_path.is_file():
                    rel_source = md_file.relative_to(PROJECT_ROOT)
                    # Clean up anchor from error message
                    clean_link = link.split('#')[0]
                    errors.append(f"❌ {rel_source}: '{clean_link}' -> not found")
            except Exception as e:
                pass 

    if errors:
        print("\n".join(errors))
        print(f"\n❌ Found {len(errors)} broken link(s) in p-hermes docs.")
        return 1
    else:
        print("✅ Full-Graph Validation passed. All p-hermes internal links are valid.")
        return 0

if __name__ == '__main__':
    sys.exit(validate())
