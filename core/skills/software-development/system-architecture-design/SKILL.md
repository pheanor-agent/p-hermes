---
name: system-architecture-design
description: "System architecture design: iterative design with user feedback, architecture documents, component diagrams, data flow, design change tracking."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [architecture, design, system-design, diagrams, documentation, iterative]
    related_skills: [writing-plans, subagent-driven-development, plan]
---

# System Architecture Design

## Overview

Design system architecture: component relationships, data flow, technology selection, deployment strategy. Produces comprehensive architecture documents with diagrams, schema definitions, and design rationale.

**Core principle:** Architecture design is iterative. Expect multiple feedback rounds. Track all changes in a design change log.

## When to Use

**Use for:**
- Designing new system architecture
- Architecture document creation
- Component relationship diagrams
- Data flow design
- Technology stack selection and justification
- System design with user feedback iteration
- **Auditing and restructuring existing systems** (folder reorganization, domain clarification, symlink migration)

**Don't use for:**
- Implementation task breakdown → use `writing-plans`
- Simple script/tool design → inline design in request.md

## Design Process

### Phase 0: Fundamental Purpose Clarification (Mandatory — JOB-1467 학습)

**⛔ 절대 금지: 목적 이해 없이 구조 설계 시작**

사용자 지적: "사양서 기반으로 코드 작성하는 목적이 뭔지 이해하고 있어?"

**설계 전 반드시 명확히 할 것:**
1. **근본 목적**: 이 시스템이 해결하는 근본 문제가 무엇인가? (의미 손실 방지? 검증 가능성? 변경 영향 예측?)
2. **성공 기준**: "이 시스템이 잘 작동한다"는 무엇을 의미하는가?
3. **대안 불용성**: 왜 기존 방식(또는 더 단순한 접근)으로 충분하지 않은가?

**목적이 불명확하면 설계를 시작하지 말 것.** 사용자에게 확인 질문.

### Phase 1: Investigation (Parallel Subagents + 방법론 조사 — JOB-1467 학습)

**⛔ 절대 금지: 기존 방법론 조사 없이 새로운 구조 설계**

사용자 지적: "리퍼런스나 웹에서 관련 방법론들을 조사한 결과는 있어?"

**의무 조사 항목:**
1. **기존 방법론 조사** (Web + Wiki + 학술):
   - 해당 도메인의 established methodologies (예: MDA, DbC, SBE, Formal Methods 등)
   - 각 방법론의 목적, Spec→Code 매핑 방식, 현재 상태(성공/실패/제한적)
   - 공통 실패 패턴과 성공 조건
2. **기술 조사** (Parallel Subagents):
   - Code analysis tools / parsing approaches
   - Database technology comparison
   - Embedding/vector strategies
   - Deployment options

```
Subagent A: Parser/tools comparison (Tree-sitter, Clang, CodeQL)
Subagent B: Database options (Graph DB, Vector DB)
Subagent C: Chunking and embedding strategies
Self: 방법론 조사 (Web/Wiki) + 리퍼런스 문서화
```

**조사 결과 기록 (미래 확장성 고려 — JOB-1467 학습):**
- `request.md`에 조사 요약 기록
- `references/` 디렉토리에 상세 리퍼런스 문서 작성 (방법론, API, 연구 결과 등)
- **영구 기록 원칙**: 나중에 시스템이 변경되거나 확장될 때 관련 자료를 참고할 수 있도록 JOB 산출물에 포함

### Phase 2: Architecture Design

Create `architecture.md` with:
- Goal and core principles
- Architecture overview diagram (ASCII art)
- Component details
- Data pipeline
- Technology stack with justification
- Implementation roadmap (Phases)
- Acceptance criteria
- Approval options (A/B/C)

### Phase 3: Review Cycle

1. Spawn review subagent
2. Address all REV findings (fix and re-review until PASS)
3. Common issues: missing acceptance criteria, Chinese characters in docs, Phase mapping mismatches

### Phase 4: Approval

Present (A)/(B)/(C) options to user. Record approval in `approval.json`.

### Phase 5: Handle Feedback (C-type or B-type)

**C-type (purpose change):** Reset to step 1, re-investigate
- Example: "standalone app, not tied to my environment"

**B-type (scope change):** Update design, re-review
- Example: "use GPT-5.4 mini instead of GPT-4o-mini"

**A-type (implementation detail):** Fix inline, no reset

### Phase 6: Detailed Design Document

Create `design-structure.md` with:
1. Implementation scope (include/exclude)
2. Full architecture diagram (ASCII)
3. Layer responsibilities
4. Technology selection rationale (with alternatives considered)
5. Detailed data schemas (SQL, Python dicts)
6. Search/processing pipeline
7. CLI command specification
8. Domain-specific handling
9. Deployment structure
10. Phase-to-artifact mapping

### Audit Mode: Existing System Restructuring (JOB-1626)

When the task is to **audit and restructure an existing system** (not greenfield design), follow this pattern:

**Phase A: Inventory & Quantification**
1. Scan all directories: `find`, `du`, `grep` for file counts, sizes, relationships
2. Identify **domains** by responsibility area (not by folder name)
3. Map each domain to its physical location(s), file count, and size
4. Read key configuration files: `AGENTS.md`, `config.yaml`, `registry.yaml`, `overview.md`

**Phase B: Data Lifecycle Classification**
Classify each domain into 3 lifecycle categories:

| Lifecycle | Change Frequency | Examples |
|-----------|-----------------|----------|
| **Static** | Low | config, skills, templates, lessons |
| **Dynamic** | Medium | knowledge wiki, jobs, reports |
| **Transient** | High | state, locks, events, cache, sessions |

**Phase C: Reference Graph**
1. Map domain-to-domain references (who reads/writes what)
2. Quantify script references: which scripts reference which directories
3. Identify **circular dependencies** and **overlaps**

**Phase D: Overlap Analysis**
1. Identify domains with responsibility overlap (e.g., "Deploy" vs "Infrastructure")
2. Document overlapping areas, who owns what, and root cause of overlap
3. Recommend name clarification if ambiguous

**Phase E: Problem Identification**
Identify structural problems:
- Flat file dumps (e.g., 190+ scripts in single directory)
- Duplicate data (e.g., 3 wiki copies)
- Mixed concerns (e.g., locks + state + temp results in one folder)
- Policy gaps (e.g., backups without retention policy)
- Naming mismatches (e.g., "Deploy" for infrastructure provisioning)

**Phase F: Migration Strategy**
Design **symlink-based migration** (zero-downtime):
1. Plan new folder structure
2. For each move: create target dir → move files → create symlink at old path
3. Verify: test cron jobs, workflow scripts, state file access after each phase
4. Phase by risk: low-risk first (state classification), high-risk last (scripts reorg)

**Audit Output:**
- `architecture-matrix-analysis.md` — comprehensive analysis report
- `design.md` — restructuring design with migration phases
- Domain matrix table, reference graph, data lifecycle classification

## Architecture Document Structure

### Required Sections

**⚠️ JOB-1467 학습: 폴더 구조, 변경 프로세스, 리퍼런스 기록 필수**

사용자 지적: "시스템 구성을 어떻게 할지 폴더 구조로 보여줘", "조사한 결과는 리퍼런스에 없는건 리퍼런스에 추가해", "나중에 관련 시스템이 구축되면 필요에 맞춰 변경해야 할 필요도 있을테니 그때도 관련 자료들을 잘 참고할 수 있어야 해"

```markdown
# [Project] Architecture ([Platform])

## 1. Goal (근본 목적 명시 — JOB-1467 학습)
- 이 시스템이 해결하는 근본 문제
- 성공 기준 (측정 가능한 지표)
- 대안 불용성 (왜 기존 방식으로 충분하지 않은가)

## 2. Architecture Overview (ASCII diagram)

## 3. Folder Structure (폴더 구조 — JOB-1467 학습 필수)
```
<folder_tree>
├── <directory>/
│   ├── <file>.md    # 파일 역할 설명
│   └── <subdir>/
└── <script>.py      # 스크립트 역할 설명
```

## 4. Technology Stack
| Layer | Technology | License | Rationale |
|-------|-----------|---------|-----------|

## 5. Data Pipeline (ASCII diagram)

## 6. Components
### 6.1 Parsing
### 6.2 Storage (Graph + Vector)
### 6.3 Embedding/LLM
### 6.4 Search

## 7. Change Process (변경 프로세스 — JOB-1467 학습)
- 요구사항 변경 분류 (A/B/C)
- Impact Analysis 절차
- 버전 전이 전략
- 롤백 경로

## 8. Domain-Specific Handling

## 9. Search/Processing Pipeline

## 10. Implementation Roadmap (P0-PN)

## 11. Risks

## 12. Acceptance Criteria

## 13. Operations/Observability

## 14. References (리퍼런스 — JOB-1467 학습)
- 조사된 방법론/도구/연구 링크
- `references/` 디렉토리 내 상세 문서 참조
- 미래 확장/변경 시 참고 자료

## 15. Legal Considerations

## Approval
### (A) Recommended
### (B) Simplified
### (C) Minimal
```

## Design Change Log

**Always** create `design-change-log.md` when design changes occur. Use `templates/design-change-log.md` as starting point.

```markdown
# 설계 변경 이력

## v1.0 → v1.1 (date)

### 변경 사유
- User feedback summary

### 변경 내역
| # | 항목 | Before | After | 사유 |
|---|------|--------|-------|------|
| 1 | ... | ... | ... | ... |

### 변경 전/후 설계 비교
| 구성 요소 | v1.0 | v1.1 |
|-----------|------|------|
```

## Diagram Conventions

### ASCII Architecture Diagram

```
┌─────────────────────────────────────┐
│              CLI Layer               │
│  command → parser → handler         │
└──────────────────┬──────────────────┘
                   │
┌──────────────────▼──────────────────┐
│           Application Layer          │
│  ┌────────┐  ┌────────┐  ┌───────┐ │
│  │ Parser │  │ Chunker│  │ Query │ │
│  └────────┘  └────────┘  └───────┘ │
└──────────────────┬──────────────────┘
                   │
┌──────────────────▼──────────────────┐
│            Data Layer                │
│  ┌────────┐  ┌────────┐             │
│  │ Graph  │  │ Vector │             │
│  │ (SQLite│  │(Chroma)│             │
│  └────────┘  └────────┘             │
└─────────────────────────────────────┘
```

### Rules:
- Use box-drawing characters (┌─┐│└┘├┤┬┴┼)
- Keep width ≤80 characters for terminal display
- Show data flow with arrows (│ ▼ ──►)
- Label each component clearly
- External services in separate box

## Separating LLM vs Vector Concerns

When architecture uses both LLM and vector embedding, **always** create separate sections:

### LLM Section Covers:
- Role: language understanding/generation/refinement
- Input/output format
- When it's called (per-query vs batch)
- Model selection rationale
- Cost implications (token-based)

### Vector Section Covers:
- Role: semantic search, similarity matching
- Embedding model and dimensions
- Storage (ChromaDB, Qdrant, etc.)
- When embeddings are created (index time)
- Search algorithm (HNSW, IVF, etc.)
- Metadata filtering

### Comparison Table (Required):

| 구분 | LLM | 벡터 |
|------|-----|------|
| 목적 | 언어 이해/생성 | 의미 기반 검색 |
| 저장 | 저장 X (API 호출만) | DB 저장 |
| 사용 시점 | 질문 시 | indexing 시 + 검색 시 |
| 비용 | 토큰 기반 (입출력) | 토큰 기반 (임베딩) |
| 네트워크 | 필수 | 필수 (임베딩 생성 시) |

## Partial Indexing Support

For large codebases (>1M LOC), **always** include partial indexing:

```bash
# Index specific subsystem only
kernel-chat index --subsystem scheduler

# Multiple subsystems
kernel-chat index --subsystem sched,vfs,net

# Full index (document as long operation)
kernel-chat index --all
```

Document available subsystems and expected indexing times.

## Technology Selection Template

For each major technology choice, document:

| 기술 | 사용 목적 | 대안 검토 | 선택 사유 |
|------|----------|-----------|----------|
| Tree-sitter | AST 추출 | ctags(정확도 낮음), Clang AST(느림) | 빠른 파싱 (수 MB/초) |

## Design Principles for Cloud/Automated Systems

### Provider-Agnostic Design (JOB-1340)

**Rule**: Architecture design documents must NOT lock in specific providers/services. Use abstract interfaces (Provider A/B) and defer selection to analysis sub-JOBs.

**Why**: Early provider lock-in creates technical debt and limits optimization. Provider selection should be based on empirical analysis, not assumptions.

**How**:
- Define **interface contracts** (required methods, I/O, error codes)
- Specify **selection criteria** (cost, availability, automation capability)
- Document **fallback strategy** (tiered providers with clear trigger conditions)
- Defer **provider-specific details** to analysis documents

### Hardware-Agnostic Design (JOB-1340)

**Rule**: Specify hardware requirements by **capability** (VRAM ≥ 24GB), not by **model name** (RTX 4090).

**Why**: GPU models change, prices fluctuate, availability varies. Capability-based requirements enable automatic optimization.

**How**:
- Use capability thresholds: `VRAM ≥ 24GB`, `CUDA cores ≥ 16GB`, `disk IOPS ≥ X`
- Document tradeoffs: "Higher performance = lower total cost (faster processing = shorter runtime)"
- Enable automatic fallback: `VRAM ≥ 24GB → ≥ 20GB → alert`

### Full Automation Constraint (JOB-1340)

**Rule**: When the controlling UI is async message-based (Telegram, Discord), **all workflows must be fully automatable**. No manual dashboard clicks.

**Design implications**:
- Every step must have an API/CLI equivalent
- State persistence required (async gaps between messages)
- Timeout layers at each stage (provisioning, workload, total)
- Health check + auto-recovery (no human operator)
- Provider selection: API automation capability is a **hard requirement**, not a nice-to-have

### Cost Minimization Strategy (JOB-1340)

**Principle**: `High performance = Low total cost` (when on-demand pricing)

**Formula**: `Total Cost = Runtime × Hourly Rate`
- Faster GPU → shorter runtime → lower total cost (even if hourly rate is higher)
- Example: RTX 4090 ($1.00/hr × 10min) = $0.17 vs RTX 3090 ($0.30/hr × 30min) = $0.15

**Design requirements**:
- On-demand activation (GPU + storage only during work)
- Batch processing maximization (amortize provisioning overhead)
- Immediate shutdown on idle (configurable threshold)
- Real-time cost tracking + hard limits

## Common Pitfalls

### 목적 없이 구조 설계 (JOB-1467 — 사용자 직접 지적)

**증상**: 사용자가 "사양서 기반으로 코드 작성하는 목적이 뭔지 이해하고 있어?"라고 질문 → 근본 목적 파악 없이 구조만 설계함

**근본 원인**: "설계 요청"을 "기술 구조 설계"로만 해석. 비즈니스/도메인 목적을 묻지 않음

**올바른 절차:**
1. **근본 목적 명확화**: "이 시스템이 해결하는 근본 문제는 무엇인가?"
2. **성공 기준 정의**: "어떤 지표로 성공을 측정하는가?"
3. **대안 분석**: "기존 방식으로는 왜 부족하는가?"
4. 목적 명확 확인后才 설계 시작

**패턴**: "목적 이해 확인 → 방법론 조사 → 구조 설계" 순서 강제

### 기존 방법론 조사 없이 설계 (JOB-1467 — 사용자 직접 지적)

**증상**: 사용자가 "리퍼런스나 웹에서 관련 방법론들을 조사한 결과는 있어?"라고 질문 → 웹/Wiki 조사 없이 자체 구조 설계함

**근본 원인**: "새로운 시스템 설계" = "기존 방법론 조사 필요" 인식 부재

**올바른 절차:**
1. **방법론 조사**: 해당 도메인의 established methodologies 조사 (Web/Wiki/학술)
   - 예: Spec-driven dev → MDA, DbC, SBE, TDD/BDD, Formal Methods, AI Spec-to-Code
2. **성공/실패 패턴 분석**: 공통 실패 원인과 성공 조건 도출
3. **현재 시스템과의 대응**: 기존 워크플로우가 이미 무엇을 커버하는지 분석
4. 조사 결과 `references/`에 영구 기록

**패턴**: "방법론 조사 → 현재 시스템 대응 분석 → 차별화 포인트 도출 → 설계"

### 리퍼런스 영구 기록 누락 (JOB-1467 — 사용자 직접 지적)

**증상**: 사용자가 "조사한 결과는 리퍼런스에 없는건 리퍼런스에 추가해" + "나중에 관련 시스템이 구축되면 필요에 맞춰 변경해야 할 필요도 있을테니 그때도 관련 자료들을 잘 참고할 수 있어야 해" → 조사 결과가 request.md에만 있어서 미래 세션에서 접근困難

**해결:**
1. `references/` 디렉토리에 상세 리퍼런스 문서 작성
2. 파일명: 도메인별 (예: `spec-driven-methodologies.md`)
3. 내용: 방법론, API, 연구 결과, 성공/실패 패턴 등
4. `architecture.md`의 References 섹션에서 링크

**원칙**: 조사 결과는 JOB 산출물에 영구 기록. 미래 세션에서 재조사가 아닌 참조로 사용 가능해야 함.

### 폴더 구조 누락 (JOB-1467 — 사용자 직접 지적)

**증상**: 사용자가 "시스템 구성을 어떻게 할지 폴더 구조로 보여줘" → 폴더 구조 없이 추상적 계층만 설명

**해결:**
1. `architecture.md`에 필수 Folder Structure 섹션 포함
2. 실제 디렉토리 트리로 표현 (tree 또는 ASCII)
3. 각 파일/디렉토리 역할 명시

### 현실 구조 검증 없이 설계 (JOB-1467 — 사용자 직접 지적)

**증상**: 사용자가 "shared 폴더 구조는 계속 쓰는거야? 듀얼에이전트 시스템 변경 이력을 참고해서 다시 검토해" → AGENTS.md에 정의된 폴더 구조를 실제 파일 시스템 상태와 검증하지 않고 설계에 사용

**근본 원인**: "문서화된 구조" = "실제 구조" 가정. AGENTS.md에 `~/.shared/projects/`, `~/.shared/memory/` 등 정의되어 있지만 실제 파일 시스템에는 `knowledge/`, `storage/`만 존재

**올바른 절차:**
1. **실제 파일 시스템 확인**: `ls -la ~/.shared/`, `ls -la ~/.hermes/workspace/` 등 실제 디렉토리 스캔
2. **기존 프로젝트 구조 분석**: Git repo 위치, docs/ 구조, AGENTS.md 내용 확인
3. **문서화 구조 vs 실제 구조 비교**: 불일치 시 실제 구조 기반 설계
4. **기존 프로젝트와의 연동 방안**: Git repo 격리 전략, 마이그레이션 경로, symlink/이동/복사 결정

**패턴**: "실제 파일 시스템 스캔 → 기존 프로젝트 구조 분석 → 문서화 구조와 비교 → 현실 기반 설계"

### Git 운용 정책 누락 (JOB-1467 — 사용자 직접 지적)

**증상**: 사용자가 "git은 에르메스 백업 등과 충돌은 없어? git 운용 정책도 정리해두는게 좋을 것 같아" → Git repo와 Agent 상태 파일 충돌 가능성 고려하지 않음

**해결:**
1. **Git repo 격리**: `~/.hermes/workspace/projects/<project>/`에 Git repo 배치 (운영 파일과 분리)
2. **`.gitignore` 템플릿**: `.hermes/`, `.openclaw/`, `.shared/`, `jobs/` 명시적 제외
3. **브랜치 전략**: `feature/SPEC-XXX`, `fix/SPEC-XXX`, `spec/SPEC-XXX` 등 Spec 기반 브랜치명
4. **Commit 컨벤션**: `feat(SPEC-A001): 메시지` 형식
5. **백업 충돌 방지**: Git repo 내부에 Agent 상태 파일 생성 금지 규칙

**원칙**: Git repo가 Agent 상태 파일과 물리적으로 격리되어야 백업/동기화 충돌 방지

### 도메인 = 폴더명 가정 (JOB-1626 — 시스템 감사 교훈)

**증상**: 폴더 이름으로 도메인을 구분 (예: `scripts/` = 스크립트 도메인, `knowledge/` = 지식 도메인) → 실제 책임 영역과 불일치

**근본 원인**: 도메인은 "책임 영역"으로 정의되어야 하나, 폴더명은 "물리적 위치"만 나타냄. 예: `scripts/image-gen/`는 ComfyUI/GPU 인프라 관리 (Deploy/Infra 도메인), `knowledge/`는 지식 도메인이지만 Wiki 3중 복사본이 다른 경로에 분산

**올바른 절차 (감사 모드):**
1. **책임 기반 도메인 정의**: 각 도메인의 역할/책임/데이터 수명을 먼저 정의
2. **물리적 매핑**: 도메인 → 실제 파일 시스템 위치 매핑 (1:N 관계 가능)
3. **중복/겹침 식별**: 동일 도메인의 데이터가 여러 폴더에 분산되어 있는지 확인
4. **명칭 명확화**: 폴더명과 도메인 역할이 불일치 시 명칭 변경 권장 (예: Deploy → Infra)

**패턴**: "도메인 정의 → 물리적 매핑 → 겹침 분석 → 명칭 명확화 → 폴더 구조 재정의"

### 도메인 / 시스템 / 인프라 용어 3층위 (JOB-1626 — 사용자 직접 교정)

**사용자 지적**: "시스템과 인프라스트럭처는 좀 다르지 않아?"

| 층위 | 질문 | 예시 |
|------|------|------|
| **도메인** | 무엇을 위한가? (관심사) | 지식, 작업, 자동화 |
| **시스템** | 어떻게 동작하는가? (구조) | Wiki 파이프라인+인덱싱, workflow-gate+상태머신 |
| **인프라** | 어떤 환경에서 돌아가는가? (물리적) | GPU, ComfyUI, Docker, RunPod |

- "지식 도메인"이 아니라 "지식"이 도메인. 파이프라인+인덱싱이 "지식 시스템"
- 설계서 용어 정의 섹션으로 3층위를 명시 필수

### Release(배포) ↔ Infra(인프라) 혼동 방지 (JOB-1626 — 사용자 직접 교정)

**사용자 지적**: "원래 배포라는 명칭을 깃헙 대상으로 쓰려고 했던건데 구체화 과정에서 갑자기 comfyui가 언급된거야"

- **Infra**: GPU/ComfyUI 등 물리적 실행 환경
- **Release**: masker+packager → GitHub 패키징 파이프라인
- 상세 설계 중 "배포"가 Infra로 전이됨 방지. 폴더 구조에서 `release/`와 `scripts/infra/` 분리

### Holder 패턴: 구조 위치 설계 (JOB-1626 — 사용자 직접 교정)

**사용자 지적**: "p-hermes 구조 자체를 여기서 구성하지 말고 예시로서 적절한 홀더로서 구조를 포함시킨 전체 구조를 설계하라는 의도야"

- 아키텍처 설계는 **전체 구조에서 해당 요소가 어디에, 어떤 형태로 위치하는지** 설계
- 내부 구조 상세 구성은 별도 JOB 위임
- 설계서에 "예시: holder" 명시 (예: `release/p-hermes/ # 예시 holder`)

### Platform Adapter Separation Verification (JOB-1218)

**Critical:** Before designing hooks/filters, verify ACTUAL message flow paths through the codebase.

**Anti-pattern:** Assuming all messages flow through one path (e.g., "Bridge sender ID problem affects Telegram").

**Correct approach:**
1. Search for actual adapter files: `ls gateway/platforms/`
2. Trace message flow: `grep -r "_handle_text_message" gateway/platforms/telegram.py`
3. Verify user_id/user_name assignment: Read `_build_message_event()` in the adapter
4. Confirm platform separation: `grep -r "platform=" gateway/platforms/*.py`

**Key insight from JOB-1218:**
- Telegram messages: Telegram API → TelegramAdapter → Gateway (direct, no Bridge)
- Bridge messages: OpenClaw → BridgeAdapter → Gateway (separate platform)
- Bridge's `user_id="openclaw"` hardcoding does NOT affect Telegram messages

**Rule:** Never design features based on assumed message flows. Verify actual code paths first.

### Existing Functionality Discovery (JOB-1218)

Before adding new features, check what's ALREADY implemented in the codebase.

**Anti-pattern:** Designing new mention detection when adapter already has `require_mention`, `mention_patterns`, `free_response_chats`.

**Verification steps:**
1. Search for existing filters: `grep -r "should_process\|require_mention\|mention_patterns" gateway/platforms/`
2. Read the filtering logic: Understand existing trigger conditions
3. Check config options: What's already configurable vs what needs new code

**Key insight from JOB-1218:**
- Telegram adapter already had: @mention check, reply-to-bot, mention_patterns, free_response_chats
- Design initially added: new busy hook, mention pattern matching, conversation tracking, intrusion detection
- After verification: Removed all as unnecessary → 45% less code (55 lines → 30 lines)

**Rule:** Search for existing functionality before designing new hooks/features. Leverage existing patterns.

### Codebase Cross-Validation During Design (JOB-1218)

After creating initial architecture, validate all hook insertion points and call paths against actual code.

**Verification checklist:**
- [ ] Hook insertion points exist at specified line numbers
- [ ] All message paths pass through the hook (no bypass routes)
- [ ] Background tasks/subagents also receive needed context
- [ ] Streaming vs non-streaming paths both covered

**Common bypass routes discovered in JOB-1218:**
- `_handle_active_session_busy_message()` bypassed `pre_gateway_dispatch` hook
- `GatewayStreamConsumer` called `adapter.send()` directly, bypassing `_send_with_retry()`
- `_run_background_task()` didn't receive `ephemeral_system_prompt`

**Rule:** Delegate validity-check subagent to verify all insertion points and bypass routes before approval.

### Chinese Characters in Documents

When working with Korean users, Korean output can accidentally include Chinese characters (慣習, 待疐, 覆盖率, 轻量, 安装包). **Always scan before finalizing:**

```bash
# Use the scanner script
bash ~/.hermes/skills/software-development/system-architecture-design/scripts/scan-chinese-chars.sh architecture.md
```

### Phase Mapping Mismatches

Roadmap phases (P0-P9) must match acceptance criteria phases exactly. Review subagents will catch mismatches.

### Missing Acceptance Criteria

Each phase must have measurable acceptance criteria:
- ❌ "검색 엔진 구축"
- ✅ "Top-5 검색 시 Recall@5 > 80%"

### Missing Before/After Table

Architecture documents must include a Before/After change table for review compliance.

## Execution Handoff

After architecture approval:

1. Create `execution.md` with phase mapping
2. Spawn parallel subagents for independent workstreams:
   - Core implementation (parsing, graph, chunking)
   - Vector/search (embedding, retrieval)
   - Documentation (API reference, guides, concept docs)
3. Track subagent state in `memory/subagent-state.json`
4. Collect outputs into `output-core/`, `output-vector/`, `output-docs/`

## Remember

```
Iterative design — expect feedback rounds
Track all changes in design-change-log.md
Separate LLM vs Vector concerns clearly
Support partial indexing for large codebases
ASCII diagrams ≤80 chars wide
Before/After table for approval
Scan for Chinese characters before finalizing
Phase mapping must be consistent
```

**Good architecture makes implementation obvious and tradeoffs transparent.**