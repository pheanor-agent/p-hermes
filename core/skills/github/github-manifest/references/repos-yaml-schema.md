# repos.yaml v2 Schema Reference

## Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `slug` | string | ✅ | GitHub repo name (URL-safe) |
| `category` | enum | ✅ | `code` \| `docs` \| `system` \| `template` |
| `lifecycle` | enum | ✅ | `incubating` \| `active` \| `stable` \| `archived` |
| `visibility` | enum | ✅ | `public` \| `private` |
| `description` | string | ✅ | Short description (shown in list output) |
| `local_path` | string | ✅ | Local filesystem path (supports `~`) |
| `topics` | list | ✅ | GitHub topics array |
| `depends_on` | list | ✅ | List of slug dependencies |
| `uplink` | bool | ✅ | Include in `uplink.sh` automated sync |

## v1 → v2 Migration Changes

| v1 Field | v2 Field | Notes |
|---|---|---|
| `name` | `slug` | More explicit, avoids confusion with display names |
| (none) | `category` | New: classifies repo purpose |
| (none) | `lifecycle` | New: tracks project phase |
| (none) | `depends_on` | New: declares inter-repo dependencies |
| `backup` | — | Removed: merged into `uplink` |
| `deploy` | — | Removed: handled by `deploy-repo.sh` separately |

## Example Entries

```yaml
# Code project
- slug: kernel-chat
  category: code
  lifecycle: stable
  visibility: public
  description: "Semantic indexing and LLM integration"
  local_path: ~/.shared/code/kernel-chat
  topics: [python, llm, semantic-search]
  depends_on: []
  uplink: true

# Documentation
- slug: knowledge-system
  category: docs
  lifecycle: active
  visibility: private
  description: "Hermes knowledge system docs"
  local_path: ~/.shared/knowledge
  topics: [knowledge-management]
  depends_on: []
  uplink: true

# Incubating template
- slug: spec-templates
  category: template
  lifecycle: incubating
  visibility: private
  description: "Spec-driven dev templates"
  local_path: ~/.shared/code/templates
  topics: [templates, spec-driven-dev]
  depends_on: []
  uplink: false
```
