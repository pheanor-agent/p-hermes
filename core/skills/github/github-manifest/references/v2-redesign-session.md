# Session Notes — v2 Structural Redesign (2026-06-03)

## Boolean Parsing Bug (repo_field)

**Problem**: Python's `json.load()` returns `True`/`False` (capitalized) for YAML booleans, but bash string comparison expects `true`/`false` (lowercase). This caused `uplink.sh` to skip all repos because `[ "$uplink_flag" != "true" ]` matched `True` ≠ `true`.

**Root cause**: Raw Python extraction in `repo_field()`:
```bash
# Bad — outputs Python True/False
python3 -c "import sys,json; print(json.load(sys.stdin)['uplink'])"
```

**Fix**: Convert booleans in `repo_field()`:
```python
val = json.load(sys.stdin).get('field', '')
if isinstance(val, bool):
    print('true' if val else 'false')
```

**Lesson**: Always use `repo_field()` for boolean fields, never raw Python extraction.

## gh CLI --json Flag Compatibility

**Problem**: `gh api --json` flag not supported in gh v2.92.0. Scripts using `--json` failed silently.

**Fix**: Replace all `--json` with `--jq`:
```bash
# Before
gh api repos/owner/repo --json name,createdAt updatedAt

# After
gh api repos/owner/repo --jq '{name, created: .created_at, updated: .updated_at}'
```

## Files Changed in v2

- `repos.yaml` — Schema v2 with category/lifecycle/depends_on
- `scripts/lib.sh` — New: shared utilities
- `scripts/uplink.sh` — New: merged sync+backup
- `scripts/drift-check.sh` — New: manifest↔GitHub verification
- `scripts/list-repos.sh` — Category-grouped output
- `scripts/init-repo.sh` — Category-aware creation
- `scripts/sync-repo.sh` — Deleted (merged into uplink.sh)
- `scripts/backup-system.sh` — Deleted (merged into uplink.sh)
- `templates/` — Restructured to category-specific subdirs
