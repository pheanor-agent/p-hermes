#!/usr/bin/env python3
"""
Migrate OpenClaw skills to Hermes custom skills structure.
Maps skills based on the v4.2 classification found in available_skills.
"""
import os
import shutil

SOURCE_BASE = "/home/bot/.openclaw/workspace/skills"
TARGET_BASE = "/home/bot/.hermes/skills/custom"

# Mapping based on available_skills and request.md
MAPPING = {
    "image-generation": [
        "browser-harness", "image-queue", "image-sequence", "manus-integration", "model-manager"
    ],
    "code-scripts": [
        "agent-workflow-core", "dedup-audit", "failure-analysis", "qa-review", 
        "reference-search", "security-audit", "systematic-debugging", "task-filing", 
        "tdd", "workflow"
    ],
    "research-analysis": [
        "grill", "triage"
    ],
    "novel-writing": [
        "novel-writing"
    ]
}

def migrate():
    migrated = []
    skipped = []
    
    for category, skills in MAPPING.items():
        target_dir = os.path.join(TARGET_BASE, category)
        os.makedirs(target_dir, exist_ok=True)
        
        for skill_name in skills:
            src_skill_dir = os.path.join(SOURCE_BASE, skill_name)
            target_skill_dir = os.path.join(target_dir, skill_name)
            
            if not os.path.exists(src_skill_dir):
                print(f"WARN: Source missing: {src_skill_dir}")
                skipped.append(skill_name)
                continue
            
            # Copy tree
            if os.path.exists(target_skill_dir):
                shutil.rmtree(target_skill_dir)
            shutil.copytree(src_skill_dir, target_skill_dir)
            
            # Update paths in SKILL.md if it exists
            skill_md_path = os.path.join(target_skill_dir, "SKILL.md")
            if os.path.exists(skill_md_path):
                with open(skill_md_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Replace OpenClaw paths with Hermes paths where appropriate
                content = content.replace("/home/bot/.openclaw/workspace", "/home/bot/.hermes/workspace")
                content = content.replace("~/.openclaw/workspace", "~/.hermes/workspace")
                
                with open(skill_md_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                
                migrated.append(skill_name)
                print(f"Migrated: {skill_name} -> {category}")
            else:
                skipped.append(skill_name)
                print(f"SKIP (no SKILL.md): {skill_name}")

    # Create symlink for deprecated workspace/skills
    symlink_path = os.path.join("/home/bot/.hermes/workspace/skills")
    if os.path.exists(symlink_path) or os.path.islink(symlink_path):
        if os.path.islink(symlink_path) or os.path.isdir(symlink_path):
            shutil.rmtree(symlink_path) # Remove existing dir/link
        else:
            os.remove(symlink_path)
            
    if not os.path.exists(symlink_path):
        os.symlink(TARGET_BASE, symlink_path)
        print(f"Symlinked: {symlink_path} -> {TARGET_BASE}")

    print(f"\nDone. Migrated: {len(migrated)}, Skipped: {len(skipped)}")
    if skipped:
        print(f"Skipped: {skipped}")

if __name__ == "__main__":
    migrate()
