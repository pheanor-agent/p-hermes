---
name: github-manifest
description: "Fleet-level GitHub repo management via repos.yaml manifest — role-based classification, spec.invariants, invariant verification"
version: 4.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [GitHub, Repository-Management, Manifest, Spec-Driven, Invariants]
    related_skills: [github-repo-management, github-auth, project-metadata-management]
---

# GitHub Manifest — Spec-Based Repository Fleet Management

Manage all Hermes project GitHub repos from a single manifest (`repos.yaml`). Defines roles, responsibilities, and invariants that are automatically verified.

## Trigger

- Creating a new GitHub repo for a Hermes project
- Syncing projects to GitHub (`uplink`)
- Verifying manifest consistency (`drift-check`)
- Listing fleet status by role/category
- Deploying releases (tag + GitHub Release)

## Location

```
~/.hermes/workspace/projects/github-manifest/   ← manifest + scripts
├── repos.yaml                                  # Single Source of Truth
├── scripts/                                    # Automation
└── templates/                                  # Category-specific init templates
```

**⚠️ Do NOT use `~/.shared/`**. Projects live in `~/.hermes/workspace/projects/<slug>/`.

## Relationship with project.yaml

| Manifest | Responsibility |
|---|---|
| **project.yaml** | Project metadata (name, description, JOB linkage, timeline) |
| **repos.yaml** | GitHub linkage (remote state, uplink settings, topics, roles, invariants) |

They are **complementary**, not redundant. Never duplicate fields between them.

## Repos.yaml Schema v4

```yaml
repos:
  - slug: my-project                # Must match project folder name
    role: worker                    # hub | worker | service | archive
    visibility: private             # public | private
    category: code                  # code | docs | system | template
    lifecycle: active               # incubating | active | stable | archived
    topics: [python, llm]
    uplink: true                    # Include in automated sync
    github_slug: my-project         # Optional: different GitHub name
    spec:
      responsibility:               # What this component is responsible for
        - Primary responsibility 1
        - Primary responsibility 2
      interface:                    # External interface
        input: [input sources]
        output: [output artifacts]
      invariants:                   # Conditions drift-check verifies
        - "project.yaml exists"
        - "src/ directory exists"
```

### Roles

| Role | Purpose | Example |
|---|---|---|
| `hub` | Central coordination; manages other repos | `github-manifest` itself |
| `worker` | Code generation/execution projects | `kernel-chat`, `screeps` |
| `service` | Service/documentation providers | `knowledge-system` |
| `archive` | Backup/preservation | `hermes-workspace-backup` |

### Categories

| Category | Purpose |
|---|---|
| `code` | Source code projects |
| `docs` | Documentation |
| `system` | System/management |
| `template` | Starter kits |

### Lifecycle

`incubating` → `active` → `stable` → `archived`

## Commands

All commands run from `~/.hermes/workspace/projects/github-manifest/`.

### List repos (role + category grouped)

```bash
bash scripts/list-repos.sh                     # all
bash scripts/list-repos.sh kernel-chat         # specific
bash scripts/list-repos.sh --category code     # by category
```

### Create new repo (auto-registers in manifest)

```bash
bash scripts/init-repo.sh <slug> "description" [category] [visibility]
bash scripts/init-repo.sh my-project "desc" code private
```

Creates GitHub repo, initializes `~/.hermes/workspace/projects/<slug>/`, applies templates, registers in `repos.yaml`.

### Sync local → GitHub (uplink)

```bash
bash scripts/uplink.sh                   # all uplink:true repos
bash scripts/uplink.sh kernel-chat       # specific
bash scripts/uplink.sh --category code   # by category
bash scripts/uplink.sh --dry-run         # preview only
```

### Invariant verification (drift-check v4)

```bash
bash scripts/drift-check.sh              # verify all invariants
bash scripts/drift-check.sh kernel-chat  # specific repo
```

**Invariant checks:**
- INV-001: `uplink: true` repos have project folder
- INV-002: `uplink: true` repos have git remote configured
- INV-003: GitHub ↔ manifest synchronization
- INV-004: `role: worker` repos have `project.yaml`

### Deploy (tag + GitHub Release)

```bash
bash scripts/deploy-repo.sh kernel-chat 1.0.0    # create release
bash scripts/deploy-repo.sh kernel-chat          # check latest
```

## Pitfalls

### Python boolean → bash string mismatch (JOB-1487)

When extracting YAML boolean fields via `python3 -c`, Python outputs `True`/`False` (capitalized) but bash expects `true`/`false` (lowercase). The `repo_field()` function in `lib.sh` handles this conversion — **always use `repo_field`** instead of raw Python extraction for boolean fields.

**Bad**: `python3 -c "import sys,json; print(json.load(sys.stdin)['uplink'])"` → `True`
**Good**: `repo_field "$json" "uplink"` → `true`

### gh CLI `--json` flag not supported

Use `--jq` instead of `--json`:

**Bad**: `gh api repos/owner/repo --json name,createdAt`
**Good**: `gh api repos/owner/repo --jq '{name, created: .created_at}'`

### `~/.shared/` is Blackboard-only (JOB-1477)

All projects now live in `~/.hermes/workspace/projects/<slug>/`. The `~/.shared/` directory is reserved for Blackboard (knowledge/references/, storage/images/). Never create new projects or tools under `~/.shared/code/`.

### uplink=false repos skip folder validation

Repos with `uplink: false` (e.g., `knowledge-system`, `hermes-workspace-backup`) may not have project folders in the standard location. `drift-check.sh` skips INV-001/002 for them and only warns.

### Nested field access with repo_field

`repo_field` supports dot notation for nested fields:
```bash
repo_field "$json" "spec.responsibility"    # returns first item
repo_field "$json" "spec.interface.input"   # returns list
```

## Script Architecture

```
scripts/
├── lib.sh           # Shared utilities (YAML parsing, badges, helpers)
├── init-repo.sh     # Create + register new repo
├── list-repos.sh    # Status view (role + category grouped)
├── uplink.sh        # Sync local → GitHub
├── drift-check.sh   # Invariant-based verification (INV-001~004)
└── deploy-repo.sh   # Tag + GitHub Release
```

## Template System

Category-specific templates under `templates/<category>/`:
- `README.md.tmpl` — Project README with `{{NAME}}` and `{{DESCRIPTION}}`
- `.gitignore.tmpl` — Category-appropriate ignore patterns

`init-repo.sh` applies matching template; falls back to `base/` if missing.

## Version History

| Version | Key Change |
|---|---|
| v1 | Initial: flat list, sync+backup separate |
| v2 | Categories, lifecycle, uplink integration, lib.sh common utils |
| v3 | `workspace/projects` path, project.yaml complementary relationship |
| v4 | Role-based classification, spec.invariants, invariant verification |
