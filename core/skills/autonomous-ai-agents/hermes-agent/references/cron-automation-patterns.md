# Cron Automation Patterns

Operational patterns for managing Hermes cron jobs in the dual-agent system (Hermes + OpenClaw).

## Script Placement Requirements

**Critical constraint**: The `cronjob` tool's `script` parameter must reference scripts in `~/.hermes/scripts/` only.

```bash
# ❌ FAILS: ~/.shared/scripts/wiki-sync.sh
cronjob(action='update', script='~/.shared/scripts/wiki-sync.sh')
# Error: "Script path must be relative to ~/.hermes/scripts/"

# ✅ WORKS: wrapper in ~/.hermes/scripts/
cronjob(action='update', script='wiki-sync.sh')
# Resolves to ~/.hermes/scripts/wiki-sync.sh
```

## Wrapper Script Pattern

For scripts that live in `~/.shared/scripts/` (dual-agent shared infrastructure), create thin wrappers in `~/.hermes/scripts/`:

```bash
# ~/.hermes/scripts/wiki-sync.sh
#!/bin/bash
exec ~/.shared/scripts/wiki-sync.sh "$@"

# ~/.hermes/scripts/sync-all.sh
#!/bin/bash
exec ~/.shared/scripts/sync-all.sh "$@"
```

This pattern is required because:
- `~/.shared/scripts/` contains dual-agent shared infrastructure
- `~/.hermes/scripts/` is the Hermes cron tool's script root
- Wrappers are thin exec forwarders — no logic duplication

## no_agent=True Pattern

For simple script-execution cron jobs, use `no_agent=True`:

```python
cronjob(
    action='update',
    job_id='...',
    no_agent=True,        # Skip LLM agent processing
    script='wiki-sync.sh', # Script runs directly
    deliver='origin',      # Script stdout → user
)
```

**Benefits:**
- No LLM token cost
- No rate limit impact
- Script stdout delivered directly to user
- Avoids `error` status from LLM response processing issues

**When NOT to use:**
- Jobs that need LLM reasoning before/after script execution
- Jobs that need to generate dynamic content based on current context

## GitHub Reference Update Pattern

The `github-reference-update.py` script demonstrates multi-category technical research automation:

```python
# Categories tracked:
CATEGORIES = {
    "github": [],                          # Curated GitHub repos
    "skills": SKILL_REPOS,                 # AI frameworks (LangGraph, CrewAI, vLLM...)
    "mcp": MCP_REPOS,                      # MCP tools
    "evaluation": EVALUATION_REPOS,        # Benchmark tools
    "agent-patterns": AGENT_PATTERNS_REPOS, # Agent design patterns
}
```

**Key behaviors:**
1. Reads `github-tracker.json` for tracked repos
2. Queries GitHub API for latest release/tag
3. Generates markdown reference files in category folders
4. Updates `reference/index.md` with all categories
5. Handles HuggingFace trending models

## Rate Limit Handling

**GitHub API:**
- Without token: 60 req/hr
- With token: 5000 req/hr

The `github-reference-update.py` script handles rate limits gracefully:
- Skips repos when rate limited (logs warning)
- Continues with remaining repos
- Updates `last_checked` timestamp regardless

**Recommendation:** Set `GITHUB_TOKEN` in `~/.hermes/.env` for higher rate limits.

## Cron Job Checklist

When creating/updating cron jobs:

| Step | Action |
|------|--------|
| 1 | Script in `~/.shared/scripts/` |
| 2 | Wrapper in `~/.hermes/scripts/` (if needed) |
| 3 | `no_agent=True` for simple script execution |
| 4 | `deliver='origin'` for user notification |
| 5 | Test script manually first: `bash ~/.shared/scripts/xxx.sh` |
| 6 | Verify cron state: `cronjob(action='list')` |

## Related Files

- `~/.shared/scripts/` — Shared cron scripts (wiki-sync, lessons-sync, graph-export, sync, sync-all)
- `~/.hermes/scripts/` — Wrapper scripts (cronjob tool scripts)
- `~/.shared/scripts/github-reference-update.py` — GitHub reference automation
- `~/.openclaw/workspace/reference/github-tracker.json` — Tracked repos
