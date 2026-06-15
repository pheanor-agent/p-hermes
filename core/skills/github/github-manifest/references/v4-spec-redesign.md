# GitHub Manifest v4 Redesign (JOB-1487)

## Session: 2026-06-03

### Problem Statement

- github-manifest v2/v3 lacked role definitions and structured responsibility
- repos.yaml was just metadata — no way to define "what each repo does"
- drift-check existed but wasn't invariant-based (just compared slug lists)
- User requested: "define system concept/role clearly, then review spec-driven-dev applicability"

### Design Decisions

**1. Spec-Driven-Dev: Partial Adoption**
- Full Spec-Driven-Dev pipeline (Spec→Code→Review→Conformance Score) is overkill
- Lightweight spec adopted: `role` field + `spec.{responsability,interface,invariants}`
- `repos.yaml` serves as Spec; `drift-check.sh` serves as verifier

**2. Role Classification**
```
hub     = Central coordination (github-manifest itself)
worker  = Code generation/execution (kernel-chat, screeps)
service = Service/documentation (knowledge-system)
archive = Backup/preservation (hermes-workspace-backup)
```

**3. Invariant System**
```
INV-001: uplink:true repos have project folder
INV-002: uplink:true repos have git remote configured  
INV-003: GitHub ↔ manifest synchronization
INV-004: role:worker repos have project.yaml
```

**4. Path Migration**
- User correction: "shared 폴더는 쓰지 마" → `~/.shared/` is Blackboard-only
- All projects: `~/.hermes/workspace/projects/<slug>/`
- github-manifest: `~/.hermes/workspace/projects/github-manifest/`

### Implementation Notes

**Python boolean → bash mismatch fix:**
```python
# lib.sh repo_field()
if isinstance(val, bool):
    print('true' if val else 'false')
```
Without this, `uplink: true` was compared as `"True" != "true"` → always failed.

**gh CLI compatibility:**
- `--json` flag not supported on installed version
- All API calls use `--jq` instead

**Complementary relationship with project.yaml:**
- project.yaml: project metadata, JOB linkage, timeline
- repos.yaml: GitHub linkage, roles, invariants
- No field duplication between them

### Artifacts

- `repos.yaml` v4 schema with role + spec.invariants
- `drift-check.sh` v4 with invariant verification
- `lib.sh` with nested field support (`repo_field "$json" "spec.responsibility"`)
- `list-repos.sh` v4 with role badges

### Lessons Learned

1. **User explicitly rejected `~/.shared/` for projects** → all project paths under `~/.hermes/workspace/projects/`
2. **Spec-Driven-Dev applicable but needs lightweight adaptation** — full pipeline overkill for manifest management
3. **Invariant-based verification superior to simple comparison** — detects structural issues, not just missing entries
4. **Role classification provides semantic meaning** — `hub` vs `worker` vs `archive` clarifies responsibilities
