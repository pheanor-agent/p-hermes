---
name: knowledge-system-architecture
description: "지식 시스템 아키텍처 — Karpathy 3계층 구조, 원본 소스, 가공 파이프라인"
category: custom
version: 3.2.0
---

# Knowledge System Architecture

개인용 AI 에이전트 지식 시스템 설계 및 구축 패턴. Karpathy LLM Wiki 컨셉 기반.

## 지식 원본 (화이트리스트)

명시된 소스만 지식 원본으로 인정함.

| 소스 | 위치 | 형식 |
|------|------|------|
| OpenClaw Memory | `~/.openclaw/workspace/memory/2026-*.md` | MD (루트 `2026-*.md` 패턴만, 하위 폴더 제외) |
| Hermes Sessions | `~/.hermes/sessions/` | JSONL |
| JOB files | `~/.hermes/workspace/jobs/` | MD |
| 뉴스 | `~/.hermes/knowledge/news/` | MD |
| 리퍼런스 | `~/.hermes/knowledge/references/` | MD |

**⚠️ OpenClaw Memory 하위 폴더 제외 **(JOB-1588)
`~/.openclaw/workspace/memory/`는 하위 폴더에 가공 대상이 아닌 데이터가 혼재됨.
- `job-queue-backups/` (679개) — JOB 산출물과 중복
- `tech-news/` (202개) — 별도 뉴스 파이프라인으로 처리
- `backup/` + `.bak/` (232개) — 원본과 동일한 백업
- `2026-*/job-queue/` (~230개) — JOB 태스크 리포트, JOB 산출물과 중복
- `dreaming/` (146개) — 실험적 기능 잔여
- `daily-reports/` (75개) — 별도 파이프라인으로 처리
- `imported-from-writer/` (13개) — 이전 설계 문서 (검토 필요)
- 루트 `2026-*.md`가 아닌 파일 (43개) — 패턴 미일치, 소스 카운팅에서 제외

**소스 카운팅 검증 패턴**: `daily-knowledge-process.sh` Line 126은 `glob("2026-*.md")` 사용 (하위 폴더 제외). `rglob("*.md")` 사용하면 하위 폴더 1,869개가 포함되어 "미가공" 수치가 왜곡됨.

**가공 현황**: 
- **가공된 지식**: entities (190) + concepts (136) = 326개
- **미가공 원본**: 3,522개 (daily cron에서 점진적 처리)

**카운팅 방식**: `daily-knowledge-process.sh`의 소스 카운팅은 entities + concepts만 "가공된 지식"으로 인정. pages/ 포함 금지 (JOB-1557 교훈).

**변경 이력**: `~/.hermes/knowledge/CHANGELOG.md` 참조

### 소스 카운팅 규칙 (JOB-1556, JOB-1573, JOB-1588)

`daily-knowledge-process.sh`의 "지식 소스 현황" 리포트는 **화이트리스트 + 3개 기능 폴더**만 카운트함.

**⚠️ 포함 금지 소스**:
- OpenClaw Session JSON/JSONL (`~/.openclaw/agents/`) — 가공 파이프라인 미연결, 카운트에서 제외 (JOB-1556)
- raw session trajectory 파일 — 가공 대상 아님
- 백업/임시 파일 — 지식 원본 아님 (단, `~/.hermes/scripts/*backup*`은 기능 폴더로 스캔됨)
- **OC Memory 하위 폴더** (`~/.openclaw/workspace/memory/` 하위) — job-queue-backups, tech-news, backup, .bak, dreaming, daily-reports 등은 지식 원본이 아님 (JOB-1588)

**⚠️ 소스 카운팅 Pitfall (JOB-1588)**:
- `rglob("*.md")`는 하위 폴더 재귀 포함 → OC Memory 2,137개 카운팅 (하위 폴더 1,912개 포함)
- `glob("2026-*.md")`은 루트만 → OC Memory 225개 카운팅 (실제 가공 대상)
- `daily-knowledge-process.sh` Line 126: `glob("2026-*.md")` 사용 필수 (하위 폴더 제외)
- **OC Memory 하위 폴더 **(JOB-1588) `job-queue-backups/`, `tech-news/`, `backup/`, `.bak/`, `dreaming/`, `daily-reports/` 등 — 카운팅에 `glob("2026-*.md")` 사용 (하위 폴더 자동 제외). `rglob("*.md")` 사용 시 1,869개 중복 데이터가 포함되어 "미가공" 수치 왜곡.

**원리**: 리포트에서 "원본 소스"로 표시되는 항목은 실제로 가공 파이프라인에 연결되어 wiki entities/concepts로 변환되어야 함. 가공되지 않는 데이터가 "미가공"으로 누적되면 리포트 신뢰성 훼손.

**3개 기능 폴더 + Skills (JOB-1573, JOB-1575)**:
- `~/.hermes/cron/` — 크론 시스템
- `~/.hermes/scripts/*backup*` — 백업 스크립트
- `~/.hermes/hermes-agent/.hermes-local/` — Hermes 로컬 코드 변경점
- `~/.hermes/skills/` — 모든 스킬 변경점 (catalog.json, SKILL.md 등) (JOB-1575)

## Karpathy 3계층 구조

```
Raw Sources (불변 원본) → Wiki (LLM 가공) → Schema (규칙 정의)
```

| 계층 | 위치 | 특성 | 소유자 |
|------|------|------|--------|
| **Raw Sources** | 각 원본 위치 | append-only, 수정/삭제 금지 | 외부/시스템 |
| **Wiki** | `~/.hermes/knowledge/processed/wiki/` | CRUD 가능, 요약/개념/종합 | LLM |
| **Schema** | `AGENTS.md`, `SCHEMA.md` | 규칙 정의, 변경 통제 | 설계자 |

**원본 참조 규칙**: 원본은 절대 복사/이동/symlink 금지. `source:` 필드에 원본 경로 직접 참조만.

### 진입점 계층 구조 (absorbed from knowledge-navigation)

```
L0: glossary.md (용어집 SSOT — 아키텍처 용어 3층위 정의)
L1: knowledge-navigation skill (entry point definition + search workflow)
L2: wiki/index.md (main entry point, LLM catalog)
L3: llms.txt (codebase entry point, 1.7KB)
L4: llms-full.txt (full index, 6.4KB)
```

**용어집(Glossary) SSOT** (JOB-1626):
- 위치: `~/.hermes/knowledge/glossary.md`
- 도메인/시스템/인프라 3층위 용어 정의 + 반례
- 아키텍처 설계 시 용어 일관성 검증 기준
- 새 지식 페이지 생성 시 용어집 참조 권장

**Navigation workflow**:
1. Read entry point (wiki/index.md)
2. Domain/tag filtering (domain-*.md, tag-*.md)
3. Read detail pages (pages/*.md)

### External Research (Investigation Phase)

Investigation phase includes **external sources** beyond internal knowledge:
- **Tools**: `web_search`, `browser_navigate`
- **Targets**: Latest tech news, issues, definitions, official API docs, papers (arXiv)
- **Limits **(JOB-1276)
  - Max **3 attempts** per source, then switch to another.
  - Don't spend more than **2 minutes** on any single source.
  - CAPTCHA or bot detection → **immediately** fall back to model's own knowledge.

### Spec-Based Search (JOB-1500 P2)

Search for knowledge documents related to a Spec ID:

```bash
# 1. Check knowledge/index.md for project/Spec references
grep -nE 'SPEC-[A-Za-z0-9]+' ~/.hermes/knowledge/index.md

# 2. Check domain wiki files
grep -rlE 'SPEC-[A-Za-z0-9]+' ~/.hermes/knowledge/wiki/

# 3. Check Traceability Matrix (if exists)
for m in ~/.hermes/knowledge/wiki/_matrix.json ~/.hermes/knowledge/_matrix.json; do
  [[ -f "$m" ]] && jq '. // {}' "$m"
done

# 4. Search jobs-index for Spec-related JOBs
grep -rlE 'SPEC-[A-Za-z0-9]+' ~/.hermes/knowledge/jobs-index/
```

**Search workflow**: `Spec ID → index.md grep → wiki/ domain grep → _matrix.json → jobs-index`

## 폴더 구조

```
~/.hermes/knowledge/
├── feeds/                    # 외부 피드 수집 (HN, GeekNews, AI Frontier)
├── processed/
│   └── wiki/
│       ├── pages/            # 모든 지식 페이지 (단일 폴더)
│       ├── _data/            # 메타데이터 (JSON 인덱스)
│       ├── index.md          # LLM 카탈로그
│       ├── domain-*.md       # 도메인별 탐색
│       ├── tag-*.md          # 태그별 탐색
│       └── SCHEMA.md         # 규칙 정의
├── synthesis/                # 일일/주간 요약
├── references/               # 구조적 리퍼런스
│   ├── systems/              # 시스템 종합 정보 (JOB-1619)
│   │   ├── overview.md       # 진입점 (정적, 구조도+매트릭스+경로맵)
│   │   ├── systems.md        # 8개 시스템 상세 (스크립트 동적 생성)
│   │   └── maintenance.md    # 유지보수 가이드
│   └── references/index.md   # 인덱스 (시스템 종합 정보 포함)
└── pipeline/                 # 스크립트 + status.json

**SSOT 역할**: 시스템 종합 정보(`overview.md`, `systems.md`)는 공개 문서 배포 시 SSOT로 사용.
**갱신**: `bash update-systems-overview.sh full` → `verify` → commit
**참고**: 문서화/배포 작업 시 먼저 검증 필요 (JOB-1542, workflow skill 참조).

## 공개 문서 배포 패턴 (JOB-1542)

GitHub Pages 기반 공개 문서 리포 유지보수 시 교차 검증 필수.

**교차 참조 검증**:
```bash
# 깨진 참조 검색
grep -rn "ARCHITECTURE\|layer[123]\|\.\./ARCHITECTURE" docs/ --include="*.md"
# 파일 존재 확인
for f in $(grep -roh '\[.*\](.*\.md)' docs/ | sed 's/.*(\(.*\)).*/\1/' | sort -u); do [ -f "$f" ] || echo "MISSING: $f"; done
# 사실 검증: find/wc로 실제 수 측정 (스킬 수, 모델 수 등)
```

**Pitfalls**: patch 중복 라인 → old_string에 기존 전체 포함. GitHub Pages CDN 1-2시간 지연.
**상세**: `references/job-1542-docs-audit-and-redesign.md`

~/.hermes/workspace/
├── jobs/                     # JOB 원본 (각 폴더에 lessons.md 포함)
└── external/                 # 외부 소스
    ├── references/           # 프로젝트/도구 구조적 정보
    └── content/              # 읽기용 콘텐츠 (뉴스/아티클)
```

## 가공 파이프라인

의존성 순서: `process → graph → priority → health` (순차 실행 필수)

| 단계 | 스크립트 | 역할 |
|------|----------|------|
| process | `daily-knowledge-process.sh` | 변경된 원본 파일 스캔 → wiki entities/concepts |
| process | `clean-wiki-pages.sh` | pages/에서 원본 복사본 정리 (JOB-1557) |
| process | `process-openclaw-memory.sh` | OpenClaw Memory → entities 인덱싱 (JOB-1557) |
| process | `process-job-outputs.py` | 완료 JOB → 구조화 요약 → entities (JOB-1557) |
| process | `process-hermes-sessions.sh` | Hermes 세션 → pages 인덱싱 |
| graph | `build-metadata.sh` → `build-graph.sh` | metadata.json + graph_edges.json 생성 |
| priority | `build-scores.sh` | scores.json + index.md 생성 |

**scores.json 구조** (`wiki/_data/scores.json`):
- 루트: `{version, updated, entries, summary}` — `entries`는 **dict** (path→info), list 아님
- entry: `{score: float, priority: "core|working|reference", recency: "YYYY-MM-DD", usage: int, hub_count: int}`
- summary: `{total, core, working, reference, avg_score}` + `scores[]` 배열 (정렬됨)
- 도메인/태그 인덱스는 `wiki/domain-*.md`, `wiki/tag-*.md` (MD 파일, JSON 아님). `domain-indexes/` 폴더에 JSON 없음

| health | `knowledge-health-report.sh` | 일일 건강도 리포트 |

**⚠️ Pitfalls**:
**⚠️ Pitfalls**:
**⚠️ Pitfalls**:\n- **Core Immunity **(JOB-1560): core priority는 `rs=1.0` 고정 (recency decay 면제). 구현: `build-scores.sh` Line 64-69. 백업: `build-scores.sh.bak.job1560`
- **Usage Tracker **(JOB-1564, ✅ 완료): `usage.json` 저장소 + `increment_usage()` 훅 + `build-scores.sh` us 점수 계산. Usage data path: `~/.hermes/knowledge/processed/wiki/_data/usage.json`
- `daily-knowledge-process.sh`의 소스 카운팅 Python 블록이白色리스트와 일치하는지 주기적으로 확인 (JOB-1556)
- **rglob vs glob 구분 **(JOB-1588): `rglob("*.md")`은 하위 폴더 재귀 포함, `glob("2026-*.md")`은 현재 디렉토리만. 소스 카운팅 범위를 제한하려면 `glob` + 패턴 사용. 카운팅 로직과 실제 처리 로직이 일치하는지 반드시 비교해야 "미가공" 수치가 왜곡되지 않음
- **소스 인덱스/사용량 DB 관리 **(JOB-1590): `sources/index.json`과 `.usage.db` 누락 시 health-report에서 ❌ 표시. 재생성: `sources-index-update.sh` 실행, DB 초기화: 스크립트 또는 수동 SQLite 생성. 기존 `health-report` cron (매일 04:30)이 검증 로직 포함
- `process-openclaw-sessions.sh`는 **사용 중지** — `.openclaw/agents/`는 지식 원본이 아님 (JOB-1556)
- OpenClaw Memory(`.openclaw/workspace/memory/`) ≠ OpenClaw Sessions(`.openclaw/agents/`) — 혼동 금지
- **지식 원본 감사 패턴 **(JOB-1573) 세션 이력만으로 폴더 구조 추측 금지. 반드시 `find`/`ls`로 실제 파일 시스템 직접 확인 → `grep wiki/index.md`로 인덱싱 비교 → 누락 식별. 상세: `references/knowledge-source-audit-pattern.md`

## Knowledge Priority Layer (KPL)

3계층 중요도:

| Tier | 명칭 | 점수 | 노출 전략 |
|------|------|------|-----------|
| **T1 Core** | 작업 필수 | ≥0.7 | 항상 노출 |
| **T2 Working** | 관련 지식 | 0.4-0.69 | 도메인 컨텍스트에 따라 |
| **T3 Reference** | 참고용 | <0.4 | 명시적 요청 시만 |

**점수 계산** (build-scores.sh 기준):
```
score = pw × 0.5 + rs × 0.3 + us × 0.2
```
- `pw` (priority weight): core=1.0, working=0.6, reference=0.2
- `rs` (recency): 생성일 기반 (0일=1.0, 7일=0.8, 30일=0.5, 90일=0.3)
- **`us` (usage)**: ✅ **JOB-1564 완료**. `usage.json` 기반 정규화 (`us = usage_count / max_usage`). 현재 `process-job-outputs.py` 훅으로 수집 중.

**Core Immunity **(JOB-1560, 필수 적용됨):
- `priority: core` 아이템은 `rs=1.0` 고정 (recency decay 면제)
- 구현 위치: `build-scores.sh` Line 64-69
- 효과: core 아이템 score = 1.0×0.5 + 1.0×0.3 + us×0.2 = **0.80~1.00** → T1 진입 보장
- 백업: `build-scores.sh.bak.job1560`
- **설계 원칙**: "T1 = Core 지식의 공간". Working 지식의 T1 진입은 `priority` 승격 또는 Usage Boost 경유

**현재 T1 구성**: 16개 core 지식 (score 0.80~1.00). Working 지식은 usage tracker 구현 완료, 실제 사용량 수집 후 T1 진입 가능.

**⚠️ Scoring System 교훈 **(JOB-1560, JOB-1564)
- **단순함 우선**: 복잡한 보너스 점수, 상대값(percentile), 하이브리드 체계 대신 `rs=1.0` 한 줄로 해결
- **Recency decay는 Core 지식의 가치와 상충**: 시간이 지나도 핵심적인 지식이라면 감쇠 로직에 예외 처리 필수
- **Working→Core 승격 경로**: `priority` 변경이 가장 확실한 T1 진입 수단. 자동 승격보다 명시적 승격 선호 (사용자 지적)
- **Usage Tracker 구현 **(JOB-1564): 에이전트 도구 호출 로직 수정 불가 → 지식 파일 읽는 스크립트 (`process-job-outputs.py`) 훅으로 대체 구현. `usage.json` 원자적 파일 락 사용 (fcntl.flock)
- **지식 원본 누락 점검 패턴 **(JOB-1573): 세션 이력만으로 추정하지 말고, `find`/`ls`로 실제 파일 시스템 직접 확인 → `grep wiki/index.md`로 인덱싱 비교 → 누락 식별. 상세: `references/job-1573-knowledge-source-audit-pattern.md`
- **지식 원본 모니터링 **(JOB-1573 ✅완료): 3개 기능 폴더 (cron/backup/hermes-local) 일일 스캔으로 해결. `~/.hermes/scripts/` 전체는 여전히 미스캔. 상세: `references/knowledge-origin-monitoring-gaps.md`

## 프론트매터 스키마

### Wiki pages
```yaml
---
title: 페이지 제목
created: YYYY-MM-DD
updated: YYYY-MM-DD
type: entity | concept | lesson | synthesis | source | report
tags: [tag1, tag2]
domain: agent | system | general | image | memory | session | novel | knowledge | reference | devops
priority: P0 | P1 | P2 | reference
---
```

### References (원본 소스) — date metadata 필수
Reference 파일은 작성 시점과 원본의 updateTime을 반드시 기록. 없으면 staleness 판단 불가.

```yaml
---
title: 문서 제목
author: 작성자
source: https://출처 URL
created: YYYY-MM-DD              # 리퍼런스 추가일 (Hermes에 등록한 날)
source_published: YYYY-MM-DD     # 원본 작성/출판일
source_updated: YYYY-MM-DD       # 원본 마지막 업데이트일 (N/A면 생략)
github_latest_commit: YYYY-MM-DD # GitHub 프로젝트 최신 커밋 (GitHub 소스만)
github_stars: 1234               # GitHub 스타 수 (GitHub 소스만)
github_status: active            # active / archived / stale (3개월 이상 미업데이트)
type: source
tags: [tag1, tag2]
domain: agent | system | general | devops
priority: P0 | P1 | P2
---
```

**해결 **(2026-06-11)
- Non-news reference 47개 전량 `created:` 백필 완료 (16% → 100%)
- News reference 117개: 자동 생성 파일, 별도 패턴 필요 (미처리)
- GitHub 프로젝트 트래킹 시스템 구축: `github-project-tracker.py` + `.tracking.json` + daily cron

## cron 스케줄

| 작업 | 스케줄 | 역할 | 소스 타입 |
|------|--------|------|-----------|
| 지식 가공 일일 파이프라인 | 03:00 | 원본 스캔 → wiki 가공 | 로컬 |
| 지식 그래프 동기화 | 03:30 | metadata + graph_edges | 로컬 |
| 지식 우선순위 계산 | 04:00 | scores + index | 로컬 |
| 지식 건강도 체크 | 04:30 | health report | 로컬 |
| 외부 데이터 수집 (fetch) | 06:00, 18:00 | IT 뉴스 등 | 외부 |
| 지식 수집 (knowledge-collect) | 06:15 | HN, GeekNews, AI Frontier | 외부 |
| **시스템 종합정보** | ✅ JOB-1619 | `update-systems-overview.sh` (auto/full/verify) → `systems/` | 내부 |

### ✅ 지식 원본 모니터링 격차 (JOB-1573, JOB-1575 완료)

**해결책**: `daily-knowledge-process.sh`의 find 대상에 3개 기능 폴더 + Skills 추가.
- `~/.hermes/cron/` — 크론 시스템 스크립트
- `~/.hermes/scripts/*backup*` — 백업 스크립트
- `~/.hermes/hermes-agent/.hermes-local/` — Hermes 로컬 코드 변경점
- `~/.hermes/skills/` — 모든 스킬 변경점 (SKILL.md, catalog.json 등) (JOB-1575)

**테스트 결과**: 431개 → 508개 변경 파일 스캔 (2026-06-11)
**실행**: 매일 03:00 cron으로 자동 실행, `-newermt "어제"` 옵션으로 신규 변경점만 스캔.

**⚠️ 여전히 미스캔**:
- `~/.hermes/scripts/` 전체 (150+ 파일) — 커스텀 스크립트 변경 이력 (백업 스크립트만 별도 스캔)
- `~/.hermes/config.yaml` — 설정 파일 변경 이력 (수동 등록 필요)

## 작업 시스템 vs 지식 시스템 연계 (Job-Knowledge Sync)

두 시스템은 독립적으로 운영되되, **지식으로의 변환**이 특정 시점에 강제됩니다.

| 구분 | 위치 | 역할 |
|------|------|------|
| **Job System (Raw)** | `~/.hermes/workspace/jobs/` | 작업의 실행, 상태 관리, 산출물 보관 (불변 원본) |
| **Knowledge System (Processed)** | `~/.hermes/knowledge/processed/wiki/` | 축적된 교훈, 설계 결정, 핵심 산출물의 지식화 |
| **Indices (Status)** | `JOB-QUEUE.md`, `JOB-COMPLETED.md` | 실시간 상태 요약 (단순 Index일 뿐 지식 아님) |

### 후킹(Hooking) 기반 동기화

**실제 훅 체인** (JOB-1557 검증):
```
JOB 완료 → workflow-gate.sh → on-job-complete.sh → sync-wiki.sh
```

| 상태 전이 시점 | 실제 동작 |
|----------------|-----------|
| **완료** (`done` 진입) | `on-job-complete.sh` 호출 → `sync-wiki.sh` → lessons.md + execution.md → wiki/ |

**⚠️ workflow-gate.sh complete 시 필수 산출물 **(JOB-1572, JOB-1575, JOB-1577 검증)
- `architecture.md` — 설계서 (design.md 복사 가능)
- `review-result-*.md` — 리뷰 결과, **[STATUS: PASS/REV/FAIL]** 태그 필수
- `approval.json` — 승인 파일, **`choice` 필드 필수**
- `result.md` — 작업 결과
- `lessons.md` — 교훈
- `execution.md` — 실행 상세

**knowledge-sync.sh 제한**: 현재 `head -20`/`head -30` 수준의 cp 처리. LLM 요약 아님 (JOB-1557 Phase 5 보류).

**sync-wiki.sh 제한**: 현재 `head -20`/`head -30` 수준의 cp 처리. LLM 요약 아님 (JOB-1557 Phase 5 보류).

## Hermes 역할 (Primary + Librarian) — Wiki 페이지 작성 규칙

**AGENTS.md § "Hermes 역할" 기준**:

- **Hermes**: Wiki 페이지 **직접 읽기/쓰기** 모두 가능 (Primary + Librarian)
- **OpenClaw**: rsync 단방향 동기화로 **읽기 전용**
- **좋은 답변 생성 시**: 직접 Wiki 페이지 작성 (JOB_REQUEST 불필요)
- **작업 시작 시**: `wiki/index.md` 확인 후 관련 페이지 탐색

**⚠️ Pitfall **(JOB-1575, JOB-1577)
- `knowledge-sync.sh`는 **JOB 상태만 동기화**. catalog.json, config 파일, 스크립트 등 일반 파일은 처리하지 않음
- Wiki 페이지 생성은 **Hermes가 직접 작성**. 자동 생성 스크립트는 존재하지 않음
- 지식 시스템에 새 소스 추가 시 `sources-index.json`에 등록 필요 (자동 수집 대상: JOB/Session/Skill/News/Reference)
- **시스템 종합 정보 갱신 **(JOB-1619) `~/.hermes/knowledge/references/systems/` 폴더에 Hermes 전체 시스템 문서화. 정적(overview.md)과 동적(systems.md) 분리. 동적 갱신: `update-systems-overview.sh` (auto/full/verify 모드). `verify` 모드: 매주 월 06:00 cron으로 자동 실행 예정.
- **catalog.json 등록 패턴 **(JOB-1577) `sources-index.json`에 `catalogs` 배열 추가. 형식: `{"name": "model-catalog", "title": "모델 카탈로그", "path": "~/.hermes/skills/custom/model-catalog/catalog.json", "type": "catalog", "ingested_at": "ISO8601"}`. 상세: `references/job-1577-catalog-registration-pattern.md`
- **Skills 폴더 수집 범위 **(JOB-1577) `~/.hermes/skills/` 전체가 daily-knowledge-process.sh 스캔 대상이지만, sources-index.json의 `skills` 배열은 SKILL.md만 명시적 등록. catalog.json 등 추가 파일은 `catalogs` 배열에 별도 등록 필요
**⚠️ workflow-gate.sh complete 시 필수 산출물**: architecture.md, review-result-*.md ([STATUS: PASS/REV/FAIL]), approval.json (choice 필드), result.md, lessons.md, execution.md. 상세: `references/job-1577-workflow-gate-deliverables.md`
- **⚠️ workflow-gate.sh 중복 폴더 Pitfall **(JOB-1590) 같은 JOB에 한글/영문으로 2개 폴더 생성 시 첫 번째 폴더만 확인. `create-job.sh` 생성 폴더에서 작업 완료까지 동일 폴더 사용 필수. 상세: `references/job-1590-workflow-gate-duplicate-folder-pitfall.md`

**Wiki 페이지 생성 조건** (AGENTS.md § "페이지 임계값"):
- 2+ 소스 언급 → 페이지 생성
- 단일 핵심 개념 → 페이지 생성
- 지명 언급 1회 → 페이지 생성 **금지**
- 페이지 200줄 초과 → 하위 주제로 분할

## 수집 대상 (sources-index.json)

**자동 수집 대상**:

| 소스 | 위치 | 상태 |
|------|------|------|
| OpenClaw 메모리 | `~/.openclaw/workspace/memory/` | ✅ 수집 |
| 세션 | `~/.hermes/sessions/` | ✅ 수집 |
| JOB 기록 | `~/.hermes/workspace/jobs/` | ✅ 수집 |
| Skills | `~/.hermes/skills/` | ✅ 수집 (SKILL.md) |
| 뉴스 | `~/.hermes/knowledge/news/` | ✅ 수집 |
| 리퍼런스 | `~/.hermes/knowledge/references/` | ✅ 수집 |

**참고**: `references/job-1588-oc-memory-scope-audit.md` — OC Memory 폴더 구조 감사 및 하위 폴더 제외 근거

**⚠️ 미수집 대상**:
- catalog.json, config 파일, 스크립트 등 일반 파일 — `sources-index.json`에 명시적 등록 필요
- `~/.hermes/scripts/` 전체 (150+ 파일) — 여전히 미스캔

**⚠️ 현재 격차 (2026-06-13 기준)**

JOB-1557, JOB-1590, JOB-1610에서 여러 격차를 해결함. 남은 문제만 나열.

| 영역 | 상태 |
|------|------|
| pages/ 인플레이션 | ✅ 해결: clean-wiki-pages.sh로 원본 복사본 정리 (3,658 → 772) |
| OpenClaw Memory 처리 | ✅ 해결: process-openclaw-memory.sh daily 연결 |
| JOB 산출물 가공 | ✅ 해결: process-job-outputs.py로 83개 JOB 구조화 요약 |
| 소스 카운팅 | ✅ 해결: OC Session JSON 제외 (JOB-1556), whitelist만 카운트 |
| **Reference date metadata** | ✅ **Non-news 100% **(2026-06-11) |
| **Session LLM 요약** | ⏸️ **보류**: process-hermes-sessions.sh가 원문 추출만, LLM 요약은 on-demand 전용 |
| **sync-wiki.sh 수준** | ⏸️ **cp 수준**: head -20/head -30으로 처리, LLM 요약 미구현 |
| **knowledge-sync.sh** | ⏸️ **미연결**: workflow-gate.sh에 hook 안 됨 (on-job-complete.sh 체인이 별도 작동) |
| **catalog.json 수집** | ✅ **JOB-1577 완료**: sources-index.json에 catalogs 배열 추가 |
| **지식 원본 모니터링 격차** | ✅ **JOB-1573/1575 완료**: 공식 5개 원본 + 3개 기능 폴더 (cron/backup/hermes-local) + **Skills** 일일 스캔. `~/.hermes/scripts/` 전체는 여전히 미스캔. 상세: `references/knowledge-source-audit-pattern.md` |
| **소스 인덱스 **(sources/index.json) | ✅ **JOB-1590/1610 완료**: `sources/index.json` 재생성 (jobs 590개, skills 144개). `.usage.db` SQLite DB 초기화. `health-report` cron (매일 04:30) 검증 로직 포함. **경로**: `~/.hermes/knowledge/sources/index.json` (sources 폴더) |
| **usage.db 스키마** | ✅ **JOB-1610 완료**: `.usage.db` SQLite DB + `usage_counts` 테이블 (file_path TEXT, count INTEGER). Python으로 생성 (sqlite3 CLI 부재). 상세: `references/job-1610-knowledge-health-improvement.md` |
| **knowledge-health-report.sh 경로** | ✅ **JOB-1610 완료**: `wiki` → `processed/wiki`, `.usage.db` 경로 수정 |

## 관련 표준 및 포맷

### Open Knowledge Format (OKF) v0.1 (2026-06-13)

Google Cloud가 공개한 **LLM-wiki 패턴의 개방형 스펙**. Hermes가 사용하는 Karpathy 3계층 구조와 동일한 패턴을 표준화.

**핵심**:
- Markdown + YAML frontmatter (type, title, description, resource, tags, timestamp)
- type 필드만 필수, 나머지는 producer 정의 (Minimalism)
- Producer/Consumer 완전 분리, Format not Platform
- Reference: BigQuery enrichment agent, HTML visualizer, sample bundles

**Hermes Wiki와의 차이점**:
- OKF는 `type` 필드를 필수, Hermes는 선택
- Hermes는 scoring 시스템 (T1/T2/T3), OKF는 없음
- Hermes는 processing pipeline, OKF는 static bundle

**적용 가능성**: Hermes wiki를 OKF-conformant로 조정 시 다른 agent/tool과 지식 교환 가능. 현재는 단순 리퍼런스 유지.

**출처**: https://cloud.google.com/blog/products/data-analytics/how-the-open-knowledge-format-can-improve-data-sharing?hl=en
**리퍼런스**: `references/job-1620-open-knowledge-format.md`

## GitHub 프로젝트 트래킹

GitHub reference의 stars, commits, status를 자동 갱신.

**두 가지 트래킹 시스템**:

| 시스템 | 스크립트 | 대상 디렉토리 | 파일 수 | 기능 |
|--------|----------|--------------|--------|------|
| reference-update | `github-reference-update.py` | `~/.shared/knowledge/references/{skills,mcp,...}` | 8+ | 커링된 repo 정보 + release notes 전체 생성 |
| project-tracker | `github-project-tracker.py` | `~/.hermes/knowledge/references/github/` | 4 | 기존 reference 파일의 frontmatter metadata(stars, forks, status) 갱신 |

**⚠️ 중요**: 두 시스템은 **서로 다른 디렉토리, 다른 파일, 다른 tracking DB**를 사용하므로 의존성 없음. 동시 실행 가능 (JOB-1568).

**reference-update 스크립트**:
- 위치: `~/.hermes/scripts/github-reference-update.py`
- Tracking DB: `~/.shared/knowledge/references/github-tracker.json`
- Cron: 매일 06:00 (phase-3-external)

**project-tracker 스크립트**:
- 위치: `~/.hermes/scripts/github-project-tracker.py`
- Tracking DB: `~/.hermes/knowledge/references/github/.tracking.json`
- Cron: 매일 06:00 (phase-3-external)

**사용법**:
```bash
# 단일 repo 갱신
python3 ~/.hermes/scripts/github-project-tracker.py owner/repo

# 전체 tracked repo 갱신
python3 ~/.hermes/scripts/github-project-tracker.py
```

**갱신되는 metadata**: `github_stars`, `github_forks`, `github_commits`, `github_latest_commit`, `github_status`, `source_updated`

**작동 방식**:
1. `.tracking.json`에서 tracked repo 목록 읽기
2. GitHub API (unauthenticated, 60req/hour)로 각 repo 정보 fetch
3. reference 파일 frontmatter에 metadata 갱신
4. `references/` 폴더에서 새로운 GitHub reference 발견 시 tracking에 자동 추가

**⚠️ API limit**: Unauthenticated 60req/hour. 두 시스템 합계 20req 미만이면 매일 1회 cron 안전.

**API rate limit 검증 패턴** (JOB-1568):
```bash
# GitHub API rate limit 확인
curl -s https://api.github.com/rate_limit | python3 -m json.tool | grep -A5 "/rate"

# 각 스크립트의 API 호출 수 추정:
# github-reference-update.py: 8 repos × 2 calls (repo + releases) = 16req
# github-project-tracker.py: 4 repos × 1 call (repo) = 4req
# 합계: 20req < 60req/hour → 안전
```

## 고도화 방향 (JOB-1599)

현재 아키텍처의 미결 과제 (sync-wiki.sh cp 수준, knowledge-sync.sh 미연결, GraphRAG 부재, 지식 충돌 관리 없음) 를 해결하기 위한 Phase별 개선안.

**구현 순서 **(리밸런스됨) Phase 3 (Queue 인프라) → Phase 1 (Contextual Retrieval) → Phase 2 (Self-Reflection) → Phase 4 (GraphRAG)

| Phase | 개선안 | 내용 | 변경 대상 |
|-------|--------|------|-----------|
| **3** | 비동기 Queue | SQLite Queue + LLM 요약 워커 + Exponential backoff | 신규 `knowledge-queue.db` + `knowledge-worker.py` |
| **1** | Contextual Retrieval | 원본 코드 스니펫 원형 유지 + 맥락 주입 (인용구 양식) | `knowledge-worker.py` 템플릿 |
| **2** | Self-Reflection | Contradiction Check + `deprecated: true` 플래그 + score=0 강제 | `daily-knowledge-process.sh` 단계 추가 |
| **4** | GraphRAG | 중심성 기반 KPL 점수 가중치 (Min-Max 정규화 0.0~1.0) | `build-scores.sh` 수정 |

**⚠️ Phase별 검증 사항 **(JOB-1599)
- **Phase 3 후킹 체인**: `workflow-gate.sh → on-job-complete.sh → knowledge-queue.db insert` 완전 연결 필수
- **Phase 1 프론트매터 준수**: `created`/`source:` 누락 방지, 맥락 설명 양식 통일 (`> 이 Docker 설정은...`)
- **Phase 2 Core Immunity 상하위**: `deprecated: true`이면 Core Immunity(`rs=1.0`) 무시하고 score=0 강제
- **Phase 4 중심성 정규화**: 단순 카운트 금지, 전체 그래프 최댓값으로 나누어 0.0~1.0 정규화 필수
- **화이트리스트 준수**: `knowledge-worker.py`가 공식 5개 원본 및 기능 폴더만 처리하는지 검증 로직 내장

**참고**: `references/job-1599-knowledge-architecture-elevation.md` — JOB-1599 전체 설계서
**참고**: `references/reference-registration-pattern.md` — External article/document 등록 패턴 (리퍼런스 + wiki + index 갱신)

| 개선안 제안 전 검증 체크리스트

개선안을 제안하기 전에 다음 원칙 준수 여부를 반드시 검증:

1. **AGENTS.md 원칙**: md 파일에 강제적/명령형 문구("해야 한다", "금지" 등) 포함 금지
2. **Karpathy 3계층**: Schema는 규칙 정의만, 변경 이력은 CHANGELOG.md 기록
3. **화이트리스트 방식**: "제외한다"가 아니라 "명시된 것만 인정한다"로 관리
4. **9단계 워크플로우**: 개선안이 workflow 단계/상태 관리와 충돌하는지 확인
5. **소스 카운팅 일치 **(JOB-1556, JOB-1573, JOB-1575) 리포트에서 원본 소스로 표시되는 항목이 실제 가공 파이프라인에 연결되어 있는지 확인. **4개 기능 폴더 + Skills** 포함: `~/.hermes/cron/`, `~/.hermes/scripts/*backup*`, `~/.hermes/hermes-agent/.hermes-local/`, `~/.hermes/skills/`
6. **가공 ≠ 복사**: cp는 가공이 아님. LLM 요약을 거쳐야 wiki에 포함 (JOB-1557)
7. **Reference date metadata**: 새 리퍼런스 추가 시 `created`, `source_published` 필수 기록. GitHub 소스면 `github_latest_commit`, `github_stars`, `github_status` 포함. 없을 경우 staleness 판단 불가.
8. **GitHub reference tracking**: 새 GitHub 리퍼런스 추가 시 `github-project-tracker.py`로 한 번 실행하여 `.tracking.json`에 등록. 이후 daily cron이 자동 갱신.
9. **용어집(Glossary) SSOT 참조 **(JOB-1626) `~/.hermes/knowledge/glossary.md`가 아키텍처 용어 SSOT. 도메인/시스템/인프라 3층위 용어 일관성 준수
10. **시스템 종합 정보(overview.md) 동시 업데이트 **(JOB-1626) 아키텍처 변경 시 `knowledge/references/systems/overview.md` 동시 수정. 도메인 명칭, 연계 매트릭스, 경로 맵 변경 시 누락 금지

**⚠️ 금지**:
- SCHEMA.md나 AGENTS.md에 변경 이력 기록 (이미 JOB 산출물에 존재)
- "Forbidden", "Ignored" 등 네거티브 제약 명시
- lessons.md로 불필요한 이동 (JOB 산출물이 원본)
- 가공되지 않는 데이터를 원본 소스로 카운팅 (JOB-1556)
- 원본 파일을 cp로 wiki에 복사 (인플레이션 유발, JOB-1557)

**✅ 필수**: 변경 이력은 `~/.hermes/knowledge/CHANGELOG.md` (append-only). 현재 상태만 명시.

**참고**: `references/information-hierarchy.md` — 지식 시스템 정보 계층 상세
