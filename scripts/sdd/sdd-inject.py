#!/usr/bin/env python3
import os
import re
import glob
import json
from pathlib import Path

# --- Data Providers ---
def get_skill_count():
    # Count all SKILL.md files in the skills directory
    skills = glob.glob('/home/pheanor/.hermes/skills/**/*SKILL.md', recursive=True)
    return len(skills)

def get_model_count():
    # Parse catalog.json for model count
    catalog_path = '/home/pheanor/.hermes/core/skills/custom/model-catalog/catalog.json'
    try:
        with open(catalog_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            # Assuming it's a list of models or has a models key
            if isinstance(data, list):
                return len(data)
            elif 'models' in data:
                return len(data['models'])
            return 0
    except Exception:
        return 0

def get_job_count():
    # Count folders in the jobs workspace
    jobs_dir = '/home/pheanor/.hermes/workspace/jobs/'
    try:
        return len([d for d in os.listdir(jobs_dir) if os.path.isdir(os.path.join(jobs_dir, d))])
    except Exception:
        return 0

# Mapping of placeholders to providers
PROVIDERS = {
    'active_skill_count': get_skill_count,
    'registered_model_count': get_model_count,
    'total_job_count': get_job_count,
}

def synthesize_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find all {{variable}} patterns
    placeholders = re.findall(r'\{\{(.*?)\}\}', content)
    
    modified = False
    for var in placeholders:
        if var in PROVIDERS:
            value = str(PROVIDERS[var]())
            content = content.replace(f'{{{{{var}}}}}', value)
            modified = True
    
    if modified:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    # target directories for injection
    targets = [
        '/home/pheanor/.hermes/workspace/projects/p-hermes/docs/',
        '/home/pheanor/.hermes/workspace/projects/p-hermes/README.md',
        '/home/pheanor/.hermes/workspace/projects/p-hermes/ARCHITECTURE.md'
    ]
    
    count = 0
    for target in targets:
        if os.path.isfile(target):
            if synthesize_file(target):
                count += 1
        elif os.path.isdir(target):
            for md_file in glob.glob(f'{target}/**/*.md', recursive=True):
                if synthesize_file(md_file):
                    count += 1
    
    print(f"✅ SDD Injection complete. Modified {count} files.")

if __name__ == '__main__':
    main()
