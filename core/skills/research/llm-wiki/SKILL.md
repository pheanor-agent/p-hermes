---
name: llm-wiki
description: "Karpathy's LLM Wiki: build/query interlinked markdown KB."
version: 2.1.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [wiki, knowledge-base, research, notes, markdown, rag-alternative]
    category: research
    related_skills: [obsidian, arxiv]
---

# Karpathy's LLM Wiki

Build and maintain a persistent, compounding knowledge base as interlinked markdown files.
Based on [Andrej Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).

Unlike traditional RAG (which rediscovers knowledge from scratch per query), the wiki
compiles knowledge once and keeps it current. Cross-references are already there.
Contradictions have already been flagged. Synthesis reflects everything ingested.

**Division of labor:** The human curates sources and directs analysis. The agent
summarizes, cross-references, files, and maintains consistency.

## When This Skill Activates

Use this skill when the user:
- Asks to create, build, or start a wiki or knowledge base
- Asks to ingest, add, or process a source into their wiki
- Asks a question and an existing wiki is present at the configured path
- Asks to lint, audit, or health-check their wiki
- References their wiki, knowledge base, or "notes" in a research context

## Wiki Location

**Location:** Set via `WIKI_PATH` environment variable (e.g. in `~/.hermes/.env`).

If unset, defaults to `~/wiki`.

```bash
WIKI="${WIKI_PATH:-$HOME/wiki}"
```

**⚠️ 운영 현실 **(JOB-1394/1399 기준) 이 시스템에서 실제 지식은 `~/.hermes/knowledge/` 하위에 관리:
- `wiki/` — LLM이 가공한 지식 (concepts 31, entities 61, graph.json, 인덱스)
- `references/` — 외부 리퍼런스 (knowledge/ 레벨, 36개)
- `archive/` — 격리된 과거 데이터 (OpenClaw sync, 레거시 구조)
- `_scripts/` — 자동화 (lint.sh, index.sh)

**⚠️ raw/ 전체 삭제 **(JOB-1399) raw/ 폴더 중복 완전 제거:
- `raw/sources/` (3,005개, 37MB) 물리적 복사본 → 삭제
- `raw/job-artifacts/` (symlink) → JOB 원본 `~/.hermes/workspace/jobs/` 직접 참조
- `raw/references/` → `~/.hermes/knowledge/references/` 로 이동 (knowledge/ 레벨)

**⚠️ 원본 직접 참조 **(중복 없음)
- JOB 산출물: `~/.hermes/workspace/jobs/` 직접 읽기
- OpenClaw 메모리: `~/.openclaw/workspace_writer/memory/` (154개) 직접 읽기
- 리퍼런스: `~/.hermes/knowledge/references/` 직접 읽기

**⚠️ OpenClaw 메모리 원본 직접 참조 **(JOB-1399 학습) OpenClaw 메모리는 `~/.openclaw/workspace_writer/memory/` (154개) 에서 **직접 참조**. raw/sources/에 복사본 유지 금지 — 3,005개 중복 파일 (37MB) 삭제됨. symlink도 불필요, 원본 경로 직접 읽기.

새 wiki 생성 전 반드시 기존 구조 확인: `ls ~/.hermes/knowledge/`

**⚠️ CRITICAL PITFALL **(JOB-1393 학습) Wiki 구축 JOB 시작 시 `~/.hermes/knowledge/` 폴더가 이미 존재하고 콘텐츠로 가득 차 있는 경우가 있다. 중복 구축 방지:
```bash
# Wiki 구축 전 필수 확인
ls ~/.hermes/knowledge/wiki/ 2>/dev/null && echo "이미 존재" || echo "새 생성 필요"
find ~/.hermes/knowledge/wiki/concepts/ -name "*.md" 2>/dev/null | wc -l  # 기존 concept 수
```

The wiki is just a directory of markdown files — open it in Obsidian, VS Code, or
any editor. No database, no special tooling required.

## Architecture: Three Layers (JOB-1394 실제 구조 반영, JOB-1399 중복 해결)

```
~/.hermes/knowledge/
├── wiki/                         # Layer 2: LLM이 가공한 지식 (검색/질의용)
│   ├── SCHEMA.md                 # 위키 구조와 규칙
│   ├── index.md                  # master index (카테고리별)
│   ├── log.md                    # 시간순 기록
│   ├── lessons-index.md          # 교훈 통합 인덱스
│   ├── sources-index.json        # 소스 메타데이터 통합
│   ├── graph.json                # wikilinks 그래프
│   ├── concepts/                 # 개념 페이지
│   ├── entities/                 # 엔티티 페이지
│   ├── comparisons/              # 비교 분석 (on-demand)
│   ├── queries/                  # 저장된 쿼리/결과 (on-demand)
│   ├── syntheses/                # 종합 문서 (on-demand)
│   └── topics/                   # 주제별 인덱스
│
├── references/                   # 외부 리퍼런스 (knowledge/ 레벨)
│   ├── github/                   # GitHub 프로젝트 리퍼런스
│   ├── skills/                   # 스킬 리퍼런스
│   ├── agent-patterns/           # 에이전트 패턴
│   └── ... (기타)
│
├── archive/                      # 격리된 과거 데이터 (삭제 아님)
│   ├── openclaw-sync/            # wiki-sync 격리
│   └── legacy/                   # deprecated 구조
│
└── _scripts/                     # 자동화
    ├── lint.sh                   # 건강 검사
    └── index.sh                  # 인덱스 자동 생성
```

**Layer 1 — Raw Sources **(직접 참조, raw/ 없음)
- JOB 산출물: `~/.hermes/workspace/jobs/` 직접 읽기
- OpenClaw 메모리: `~/.openclaw/workspace_writer/memory/` (154개) 직접 읽기
- ❌ raw/ 폴더 없음 — 중복 방지 (JOB-1399)

**Layer 2 — The Wiki (`wiki/`)**: Agent-owned markdown files. Created, updated, and cross-referenced.

**Layer 3 — The Schema (`wiki/SCHEMA.md`)**: 구조, 규칙, 태그 분류학을 정의.

## Resuming an Existing Wiki (CRITICAL — do this every session)

When the user has an existing wiki, **always orient yourself before doing anything**:

① **Read `SCHEMA.md`** — understand the domain, conventions, and tag taxonomy.
② **Read `index.md`** — learn what pages exist and their summaries.
③ **Scan recent `log.md`** — read the last 20-30 entries to understand recent activity.

```bash
WIKI="${WIKI_PATH:-$HOME/wiki}"
# Orientation reads at session start
read_file "$WIKI/SCHEMA.md"
read_file "$WIKI/index.md"
read_file "$WIKI/log.md" offset=<last 30 lines>
```

Only after orientation should you ingest, query, or lint. This prevents:
- Creating duplicate pages for entities that already exist
- Missing cross-references to existing content
- Contradicting the schema's conventions
- Repeating work already logged

For large wikis (100+ pages), also run a quick `search_files` for the topic
at hand before creating anything new.

## Initializing a New Wiki

When the user asks to create or start a wiki:

1. Determine the wiki path (from `$WIKI_PATH` env var, or ask the user; default `~/wiki`)
2. Create the directory structure above
3. Ask the user what domain the wiki covers — be specific
4. Write `SCHEMA.md` customized to the domain (see template below)
5. Write initial `index.md` with sectioned header
6. Write initial `log.md` with creation entry
7. Confirm the wiki is ready and suggest first sources to ingest

### SCHEMA.md Template

Adapt to the user's domain. The schema constrains agent behavior and ensures consistency:

```markdown
# Wiki Schema

## Domain
[What this wiki covers — e.g., "AI/ML research", "personal health", "startup intelligence"]

## Conventions
- File names: lowercase, hyphens, no spaces (e.g., `transformer-architecture.md`)
- Every wiki page starts with YAML frontmatter (see below)
- Use `[[wikilinks]]` to link between pages (minimum 2 outbound links per page)
- When updating a page, always bump the `updated` date
- Every new page must be added to `index.md` under the correct section
- Every action must be appended to `log.md`
- **Provenance markers:** On pages that synthesize 3+ sources, append `^[raw/articles/source-file.md]`
  at the end of paragraphs whose claims come from a specific source. This lets a reader trace each
  claim back without re-reading the whole raw file. Optional on single-source pages where the
  `sources:` frontmatter is enough.

## Frontmatter
  ```yaml
  ---
  title: Page Title
  created: YYYY-MM-DD
  updated: YYYY-MM-DD
  type: entity | concept | comparison | query | summary
  tags: [from taxonomy below]
  sources: [raw/articles/source-name.md]
  # Optional quality signals:
  confidence: high | medium | low        # how well-supported the claims are
  contested: true                        # set when the page has unresolved contradictions
  contradictions: [other-page-slug]      # pages this one conflicts with
  ---
  ```

`confidence` and `contested` are optional but recommended for opinion-heavy or fast-moving
topics. Lint surfaces `contested: true` and `confidence: low` pages for review so weak claims
don't silently harden into accepted wiki fact.

### raw/ Frontmatter

Raw sources ALSO get a small frontmatter block so re-ingests can detect drift:

```yaml
---
source_url: https://example.com/article   # original URL, if applicable
ingested: YYYY-MM-DD
sha256: <hex digest of the raw content below the frontmatter>
---
```

The `sha256:` lets a future re-ingest of the same URL skip processing when content is unchanged,
and flag drift when it has changed. Compute over the body only (everything after the closing
`---`), not the frontmatter itself.

## Tag Taxonomy
[Define 10-20 top-level tags for the domain. Add new tags here BEFORE using them.]

Example for AI/ML:
- Models: model, architecture, benchmark, training
- People/Orgs: person, company, lab, open-source
- Techniques: optimization, fine-tuning, inference, alignment, data
- Meta: comparison, timeline, controversy, prediction

Rule: every tag on a page must appear in this taxonomy. If a new tag is needed,
add it here first, then use it. This prevents tag sprawl.

## Page Thresholds
- **Create a page** when an entity/concept appears in 2+ sources OR is central to one source
- **Add to existing page** when a source mentions something already covered
- **DON'T create a page** for passing mentions, minor details, or things outside the domain
- **Split a page** when it exceeds ~200 lines — break into sub-topics with cross-links
- **Archive a page** when its content is fully superseded — move to `_archive/`, remove from index

## Entity Pages
One page per notable entity. Include:
- Overview / what it is
- Key facts and dates
- Relationships to other entities ([[wikilinks]])
- Source references

## Concept Pages
One page per concept or topic. Include:
- Definition / explanation
- Current state of knowledge
- Open questions or debates
- Related concepts ([[wikilinks]])

## Comparison Pages
Side-by-side analyses. Include:
- What is being compared and why
- Dimensions of comparison (table format preferred)
- Verdict or synthesis
- Sources

## Update Policy
When new information conflicts with existing content:
1. Check the dates — newer sources generally supersede older ones
2. If genuinely contradictory, note both positions with dates and sources
3. Mark the contradiction in frontmatter: `contradictions: [page-name]`
4. Flag for user review in the lint report
```

### index.md Template

The index is sectioned by type. Each entry is one line: wikilink + summary.

```markdown
# Wiki Index

> Content catalog. Every wiki page listed under its type with a one-line summary.
> Read this first to find relevant pages for any query.
> Last updated: YYYY-MM-DD | Total pages: N

## Entities
<!-- Alphabetical within section -->

## Concepts

## Comparisons

## Queries
```

**Scaling rule:** When any section exceeds 50 entries, split it into sub-sections
by first letter or sub-domain. When the index exceeds 200 entries total, create
a `_meta/topic-map.md` that groups pages by theme for faster navigation.

### log.md Template

```markdown
# Wiki Log

> Chronological record of all wiki actions. Append-only.
> Format: `## [YYYY-MM-DD] action | subject`
> Actions: ingest, update, query, lint, create, archive, delete
> When this file exceeds 500 entries, rotate: rename to log-YYYY.md, start fresh.

## [YYYY-MM-DD] create | Wiki initialized
- Domain: [domain]
- Structure created with SCHEMA.md, index.md, log.md
```

## Core Operations

### 1. Ingest

When the user provides a source (URL, file, paste), integrate it into the wiki:

① **Capture the raw source:**
   - URL → use `web_extract` to get markdown, save to `raw/articles/`
   - PDF → use `web_extract` (handles PDFs), save to `raw/papers/`
   - Pasted text → save to appropriate `raw/` subdirectory
   - Name the file descriptively: `raw/articles/karpathy-llm-wiki-2026.md`
   - **Add raw frontmatter** (`source_url`, `ingested`, `sha256` of the body).
     On re-ingest of the same URL: recompute the sha256, compare to the stored value —
     skip if identical, flag drift and update if different. This is cheap enough to
     do on every re-ingest and catches silent source changes.

② **Discuss takeaways** with the user — what's interesting, what matters for
   the domain. (Skip this in automated/cron contexts — proceed directly.)

③ **Check what already exists** — search index.md and use `search_files` to find
   existing pages for mentioned entities/concepts. This is the difference between
   a growing wiki and a pile of duplicates.

④ **Write or update wiki pages:**
   - **New entities/concepts:** Create pages only if they meet the Page Thresholds
     in SCHEMA.md (2+ source mentions, or central to one source)
   - **Existing pages:** Add new information, update facts, bump `updated` date.
     When new info contradicts existing content, follow the Update Policy.
   - **Cross-reference:** Every new or updated page must link to at least 2 other
     pages via `[[wikilinks]]`. Check that existing pages link back.
   - **Tags:** Only use tags from the taxonomy in SCHEMA.md
   - **Provenance:** On pages synthesizing 3+ sources, append `^[raw/articles/source.md]`
     markers to paragraphs whose claims trace to a specific source.
   - **Confidence:** For opinion-heavy, fast-moving, or single-source claims, set
     `confidence: medium` or `low` in frontmatter. Don't mark `high` unless the
     claim is well-supported across multiple sources.

⑤ **Update navigation:**
   - Add new pages to `index.md` under the correct section, alphabetically
   - Update the "Total pages" count and "Last updated" date in index header
   - Append to `log.md`: `## [YYYY-MM-DD] ingest | Source Title`
   - List every file created or updated in the log entry

⑥ **Report what changed** — list every file created or updated to the user.

A single source can trigger updates across 5-15 wiki pages. This is normal
and desired — it's the compounding effect.

### 2. Query

When the user asks a question about the wiki's domain:

① **Read `index.md`** to identify relevant pages.
② **For wikis with 100+ pages**, also `search_files` across all `.md` files
   for key terms — the index alone may miss relevant content.
③ **Read the relevant pages** using `read_file`.
④ **Synthesize an answer** from the compiled knowledge. Cite the wiki pages
   you drew from: "Based on [[page-a]] and [[page-b]]..."
⑤ **File valuable answers back** — if the answer is a substantial comparison,
   deep dive, or novel synthesis, create a page in `queries/` or `comparisons/`.
   Don't file trivial lookups — only answers that would be painful to re-derive.
⑥ **Update log.md** with the query and whether it was filed.

### 3. Lint

When the user asks to lint, health-check, or audit the wiki:

① **Orphan pages:** Find pages with no inbound `[[wikilinks]]` from other pages.
```python
# Use execute_code for this — programmatic scan across all wiki pages
import os, re
from collections import defaultdict
wiki = "<WIKI_PATH>"
# Scan all .md files in entities/, concepts/, comparisons/, queries/
# Extract all [[wikilinks]] — build inbound link map
# Pages with zero inbound links are orphans
```

② **Broken wikilinks:** Find `[[links]]` that point to pages that don't exist.

③ **Index completeness:** Every wiki page should appear in `index.md`. Compare
   the filesystem against index entries.

④ **Frontmatter validation:** Every wiki page must have all required fields
   (title, created, updated, type, tags, sources). Tags must be in the taxonomy.

⑤ **Stale content:** Pages whose `updated` date is >90 days older than the most
   recent source that mentions the same entities.

⑥ **Contradictions:** Pages on the same topic with conflicting claims. Look for
   pages that share tags/entities but state different facts. Surface all pages
   with `contested: true` or `contradictions:` frontmatter for user review.

⑦ **Quality signals:** List pages with `confidence: low` and any page that cites
   only a single source but has no confidence field set — these are candidates
   for either finding corroboration or demoting to `confidence: medium`.

⑧ **Source drift:** For each file in `raw/` with a `sha256:` frontmatter, recompute
   the hash and flag mismatches. Mismatches indicate the raw file was edited
   (shouldn't happen — raw/ is immutable) or ingested from a URL that has since
   changed. Not a hard error, but worth reporting.

⑨ **Page size:** Flag pages over 200 lines — candidates for splitting.

⑩ **Tag audit:** List all tags in use, flag any not in the SCHEMA.md taxonomy.

⑪ **Log rotation:** If log.md exceeds 500 entries, rotate it.

⑫ **Report findings** with specific file paths and suggested actions, grouped by
   severity (broken links > orphans > source drift > contested pages > stale content > style issues).

⑬ **Append to log.md:** `## [YYYY-MM-DD] lint | N issues found`

## Working with the Wiki

### Searching

```bash
# Find pages by content
search_files "transformer" path="$WIKI" file_glob="*.md"

# Find pages by filename
search_files "*.md" target="files" path="$WIKI"

# Find pages by tag
search_files "tags:.*alignment" path="$WIKI" file_glob="*.md"

# Recent activity
read_file "$WIKI/log.md" offset=<last 20 lines>
```

### Bulk Ingest

When ingesting multiple sources at once, batch the updates:
1. Read all sources first
2. Identify all entities and concepts across all sources
3. Check existing pages for all of them (one search pass, not N)
4. Create/update pages in one pass (avoids redundant updates)
5. Update index.md once at the end
6. Write a single log entry covering the batch

### Archiving

When content is fully superseded or the domain scope changes:
1. Create `_archive/` directory if it doesn't exist
2. Move the page to `_archive/` with its original path (e.g., `_archive/entities/old-page.md`)
3. Remove from `index.md`
4. Update any pages that linked to it — replace wikilink with plain text + "(archived)"
5. Log the archive action

### Obsidian Integration

The wiki directory works as an Obsidian vault out of the box:
- `[[wikilinks]]` render as clickable links
- Graph View visualizes the knowledge network
- YAML frontmatter powers Dataview queries
- The `raw/assets/` folder holds images referenced via `![[image.png]]`

For best results:
- Set Obsidian's attachment folder to `raw/assets/`
- Enable "Wikilinks" in Obsidian settings (usually on by default)
- Install Dataview plugin for queries like `TABLE tags FROM "entities" WHERE contains(tags, "company")`

If using the Obsidian skill alongside this one, set `OBSIDIAN_VAULT_PATH` to the
same directory as the wiki path.

### Obsidian Headless (servers and headless machines)

On machines without a display, use `obsidian-headless` instead of the desktop app.
It syncs vaults via Obsidian Sync without a GUI — perfect for agents running on
servers that write to the wiki while Obsidian desktop reads it on another device.

**Setup:**
```bash
# Requires Node.js 22+
npm install -g obsidian-headless

# Login (requires Obsidian account with Sync subscription)
ob login --email <email> --password '<password>'

# Create a remote vault for the wiki
ob sync-create-remote --name "LLM Wiki"

# Connect the wiki directory to the vault
cd ~/wiki
ob sync-setup --vault "<vault-id>"

# Initial sync
ob sync

# Continuous sync (foreground — use systemd for background)
ob sync --continuous
```

**Continuous background sync via systemd:**
```ini
# ~/.config/systemd/user/obsidian-wiki-sync.service
[Unit]
Description=Obsidian LLM Wiki Sync
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/path/to/ob sync --continuous
WorkingDirectory=/home/user/wiki
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
```

```bash
systemctl --user daemon-reload
systemctl --user enable --now obsidian-wiki-sync
# Enable linger so sync survives logout:
sudo loginctl enable-linger $USER
```

This lets the agent write to `~/wiki` on a server while you browse the same
vault in Obsidian on your laptop/phone — changes appear within seconds.

## Health Check / Audit Checklist

Periodically verify your wiki against these signals. A healthy wiki should pass most checks:

| Check | Healthy | Warning | Critical |
|-------|---------|---------|----------|
| **SCHEMA.md exists** | ✅ Present | — | ❌ Missing — agent has no behavioral constraints |
| **log.md exists** | ✅ Present with recent entries | Stale >30 days | ❌ Missing — no action history |
| **index.md synced** | All pages listed | Missing pages | ❌ Empty or outdated |
| **Processing ratio** | >20% of raw sources → wiki pages | 5-20% | <5% — just a file dump, not a wiki |
| **wikilinks density** | >2 outbound links per page avg | <2 | <0.5 — isolated pages |
| **concepts/ exists and populated** | >0 pages | 0 — entity-only wiki | — |
| **contradictions flagged** | Some `contested: true` pages | None — may mean no contradictions or no detection | — |
| **compounding working** | Queries filed as wiki pages | Rarely filed | Never — answers vanish in chat |
| **Raw source diversity** | Mix of external + internal | >80% one source type | 100% self-referential (e.g. only agent memory) |

**Quick audit command:**
```bash
# Processing ratio
raw=$(find "$WIKI/raw" -name "*.md" | wc -l)
wiki=$(find "$WIKI/entities" "$WIKI/concepts" "$WIKI/comparisons" "$WIKI/queries" -name "*.md" 2>/dev/null | wc -l)
echo "Processing: $wiki / $raw = $(python3 -c "print(f'{$wiki/$raw*100:.1f}%' if $raw else 'N/A')")"

# Wikilink density
total_links=$(grep -r '\[\[' "$WIKI/entities" "$WIKI/concepts" 2>/dev/null | grep -v '\.\./\|code' | wc -l)
total_pages=$(find "$WIKI/entities" "$WIKI/concepts" -name "*.md" 2>/dev/null | wc -l)
echo "Avg wikilinks/page: $(python3 -c "print(f'{$total_links/$total_pages:.1f}' if $total_pages else 'N/A')")"

# Metachecks
for f in SCHEMA.md log.md index.md; do
  [[ -f "$WIKI/$f" ]] && echo "✅ $f" || echo "❌ $f missing"
done
```

## Common Anti-Patterns (from real deployments)

### "Memory Mirror" — Raw sources are 90%+ agent internal memory
**Symptom**: `sources/` is mostly `bridge-workspace-*` files copying agent memory. External knowledge is <5%.
**Root cause**: The system ingests its own memory as "sources" but never actually collects external documents (papers, articles, books, reports).
**실제 사례 **(JOB-1399) `raw/sources/`에 OpenClaw 메모리 파일 3,005개 물리적 복사본 (37MB) — 원본은 `~/.openclaw/workspace_writer/memory/` (154개) 에 이미 존재. 중복 데이터 유지 문제 발생.
**Fix**:
1. **물리적 복사본 삭제** — raw/sources/ 전체 제거 (아카이브 아님)
2. **원본 경로 직접 참조** — collect.sh가 OpenClaw 원본에서 직접 읽도록 수정
3. **외부 지능적 수집** — internal memory를 ONE source type으로 취급, 외부 문서 능동적 수집
A wiki that only mirrors its own memory is a knowledge echo chamber, not a knowledge base.

### "Copy, Don't Process" — Raw sources become wiki pages without transformation
**Symptom**: Each raw source → 1 wiki page with near-identical content. No entity extraction, no concept synthesis, no cross-referencing.
**Root cause**: The ingest pipeline copies content instead of reading and integrating. Karpathy's spec says "1 source → 10-15 wiki page updates."
**Fix**: The ingest step must EXTRACT entities/concepts, UPDATE existing pages, and CREATE cross-references. A raw source should rarely produce a 1:1 wiki page.

### "Graph Without Semantics" — Edges are structural, not semantic
**Symptom**: graph.json has thousands of edges but almost none are `wikilink` type. Most edges are `references_job` or `temporal_memory` (structural groupings).
**Root cause**: The system connects files by metadata (same JOB, same date) but not by meaning (same entity, same concept).
**Fix**: Wikilinks must encode semantic relationships. "JOB-1234 produced both file A and file B" is structural. "File A mentions Transformer Architecture, which is also discussed in File C" is semantic.

### "Answers Vanish" — No compounding
**Symptom**: Great query answers, comparisons, and analyses exist only in chat history. Re-asking the same question produces a different answer.
**Root cause**: The "file good answers back" step is missing from the query workflow.
**Fix**: After any substantial query answer, ask: "Is this worth filing?" If yes, create a page in `queries/` or `comparisons/`. This is the compounding mechanism.

## Pitfalls

- **Never modify files in `raw/`** — sources are immutable. Corrections go in wiki pages.
- **Always orient first** — read SCHEMA + index + recent log before any operation in a new session.
  Skipping this causes duplicates and missed cross-references.
- **Always update index.md and log.md** — skipping this makes the wiki degrade. These are the
  navigational backbone.
- **Don't create pages for passing mentions** — follow the Page Thresholds in SCHEMA.md. A name
  appearing once in a footnote doesn't warrant an entity page.
- **Don't create pages without cross-references** — isolated pages are invisible. Every page must
  link to at least 2 other pages.
- **Frontmatter is required** — it enables search, filtering, and staleness detection.
- **Tags must come from the taxonomy** — freeform tags decay into noise. Add new tags to SCHEMA.md
  first, then use them.
- **Keep pages scannable** — a wiki page should be readable in 30 seconds. Split pages over
  200 lines. Move detailed analysis to dedicated deep-dive pages.
- **Ask before mass-updating** — if an ingest would touch 10+ existing pages, confirm
  the scope with the user first.
- **Rotate the log** — when log.md exceeds 500 entries, rename it `log-YYYY.md` and start fresh.
  The agent should check log size during lint.
- **Handle contradictions explicitly** — don't silently overwrite. Note both claims with dates,
  mark in frontmatter, flag for user review.

**⚠️ 원본 데이터 중복 금지 **(JOB-1399 학습) 외부 시스템에서 온 원본 데이터를 raw/에 물리적으로 복사 금지:
- `raw/sources/` 폴더에서 3,005개 중복 파일 (37MB) 발견 → 삭제
- 아카이브도 "나중에 참조할 수 있다"는 해석 가능 → 단순 이동도 문제
- symlink도 오버헤드만 증가 — **원본 경로 직접 참조**가 정답
- 예: OpenClaw 메모리는 `~/.openclaw/workspace_writer/memory/` 에서 직접 읽기 (collect.sh 수정)
- 확인 방법: `file ~/.hermes/knowledge/raw/sources/*.md` → symlink가 아니면 문제

**검증 스크립트**:
```bash
# raw/ 하위 물리적 파일 확인 (symlink가 아니면 문제)
find ~/.hermes/knowledge/raw/ -type f -name "*.md" | head -5
# 원본 존재 확인
ls ~/.openclaw/workspace_writer/memory/*.md | head -5
```

**⚠️ Lessons.md Lifecycle **(JOB-1394 구조 적용)
Lessons는 "원본 JOB 폴더 + wiki 인덱스" 방식으로 관리:
- `~/.hermes/workspace/jobs/JOB-XXXX/lessons.md` — JOB별 교훈 원본 (9단계 산출물)
- `~/.hermes/knowledge/wiki/lessons-index.md` — 통합 교훈 인덱스

**작동 방식**:
1. JOB 완료 시 `lessons.md`가 JOB 폴더에 생성 (원본)
2. `raw/job-artifacts/JOB-XXXX/` symlink로 raw에서 참조
3. `wiki/lessons-index.md`에 인덱스 항목 추가
4. 원본은 JOB 폴더에 유지 — knowledge 시스템은 인덱스만 관리

**검증**: `grep "JOB-XXXX" ~/.hermes/knowledge/wiki/lessons-index.md`로 등록 확인.

**⚠️ CRITICAL: references/ + wiki/ 동시 업데이트 **(JOB-1405, 2026-05-31)
`references/`에 외부 리퍼런스를 추가할 때 **반드시** `wiki/entities/` 또는 `wiki/concepts/`에도 대응 엔티티 페이지를 함께 생성해야 함. 수동 누락이 실제 발생(JOB-1405 유발):
- `references/`만 업데이트하고 `wiki/` 잊음 → 지식 불일치
- 체크리스트: `references/index.md` ✓ → `references/xxx.md` ✓ → `wiki/entities/xxx.md` ✓ → `wiki/index.md` ✓ → `wiki/log.md` ✓ → `wiki/inbox.md` ✓
- 자동화 스크립트 부재: `generate-llms.sh`는 AGENTS.md에 언급되나 실제 미존재. ingest 자동화는 현재 수동.
- **피할 수 있는 실수**: 리퍼런스 추가 후 항상 `wiki/index.md`와 `wiki/log.md`도 확인. 누락 시 즉시补填.

## Dual Agent Systems

In dual agent systems (e.g. OpenClaw as Librarian + Hermes as Researcher):

- **Single manager**: One agent owns wiki maintenance (the Librarian). The other reads only.
- **Avoid rsync --delete conflict**: If the Researcher creates wiki files, they may be deleted by sync. Use `--exclude` rules or keep files in separate directories.
- **원본 직접 참조 **(직접 경로 사용) 메타데이터만 저장하고 원본 경로를 참조. 물리적 복사나 symlink 모두 피함 — 중복 데이터 방지 (JOB-1399).
- **Direct API calls over queue waiting**: Use Bridge API directly rather than waiting for heartbeat batch processing.

See also: `dual-agent-wiki-design` skill for detailed patterns.

## Related Tools

[llm-wiki-compiler](https://github.com/atomicmemory/llm-wiki-compiler) is a Node.js CLI that
compiles sources into a concept wiki with the same Karpathy inspiration. It's Obsidian-compatible,
so users who want a scheduled/CLI-driven compile pipeline can point it at the same vault this
skill maintains. Trade-offs: it owns page generation (replaces the agent's judgment on page
creation) and is tuned for small corpora. Use this skill when you want agent-in-the-loop curation;
use llmwiki when you want batch compile of a source directory.
