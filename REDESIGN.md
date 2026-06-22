# p-hermes 전면 재설계 아키텍처 문서

> **버전**: 1.0.0  
> **작성일**: 2026-06-22  
> **설계 모드**: 전량 개선 (Full Redesign)  
> **범위**: README · Wiki · Examples · GitHub Pages · Slides · Blog · Playground · CI/CD · 배포 스크립트  

---

## 목차

1. [전략 문서 검토 결과](#1-전략-문서-검토-결과)
2. [통합 아키텍처 맵](#2-통합-아키텍처-맵)
3. [Phase 0: Critical Fixes](#3-phase-0-critical-fixes)
4. [Phase 0: README 재설계](#4-phase-0-readme-재설계)
5. [Phase 0: 3개 Job 사례 명세](#5-phase-0-3개-job-사례-명세)
6. [Phase 1: Wiki 재설계](#6-phase-1-wiki-재설계)
7. [Phase 1: Smoke Test](#7-phase-1-smoke-test)
8. [Phase 2: GitHub Pages + Blog + Slides](#8-phase-2-github-pages--blog--slides)
9. [Phase 3: 장기 자동화 도구](#9-phase-3-장기-자동화-도구)
10. [전체 파일 변경 목록](#10-전체-파일-변경-목록)

---

# 1. 전략 문서 검토 결과

> 검토 대상: 사용자의 배포 전략 개선안 (JOB-1768 Investigation v4 기반, Notes_260622_113107.txt)

## 1.1 README 섹션

| 항목 | 상태 | 의견 |
|------|------|------|
| Hero 섹션 브랜딩 부족 | ✅ **동의** | 현재 README는 기술 문서 스타일로, 첫 3줄에 "고도의 자율성", "Spec-Driven Development", "엔지니어링 에이전트"라는 용어가 연타되어 신규 사용자에게 장벽이 높음 |
| Quick Start가 너무 길다 | ✅ **동의** | 현재 git clone 설명이 없고 setup.sh를 소개하지 않음. "시작하기" 섹션에 3개 카테고리 링크만 나열되어 실질적 Quick Start가 아님 |
| 3-트랙 테이블 유용 | ✅ **동의 유지** | 현재 3-트랙 문서화 테이블은 잘 설계돼 있으나 GitHub Pages 링크가 `https://...` 하드코딩되어 있음 → 상대경로로 변경 |
| 시스템 핵심 스펙 섹션 불필요 | ⚠️ **부분 동의** | 스펙 정보(5-Tier, 84+ Skills 등)는 README보다 Wiki 또는 별도 ARCHITECTURE.md로 이동하는 것이 타당하나, 제거가 아닌 축소 후 CTA로 연결 |

**보완 제안**:
- Hero에 **"Persistent AI Agent Framework — Memory, Workflow, Knowledge, Projects, Content"** 태그라인 추가
- `setup.sh` 환경변수 설명을 README가 아닌 `docs/wiki/getting-started/install.md`로 이동
- "Try it now" 섹션 추가: `bash setup.sh && hermes start` 2커맨드 배지

## 1.2 Wiki 섹션

| 항목 | 상태 | 의견 |
|------|------|------|
| Archive 문서 방치 문제 | ✅ **동의** | `archive/docs/wiki/`에 first-job.md, use-skills.md 등 10개 문서가 방치됨. 내용은 유효하나 링크가 끊겨 있음 |
| 분량 기준 미달 | ✅ **동의** | SPEC-D04의 3,500자 기준(현재 800~1,500자 수준)을 충족하지 못하는 문서 다수 존재 |
| Wiki → Blog 교차 링크 부족 | ✅ **동의** | 현재 Wiki 각 가이드 말미에 Blog 포스트 링크가 없음 |

**보완 제안**:
- Archive 문서는 검토 후 `docs/wiki/guides/` 또는 `docs/wiki/tutorials/`로 승격, 불필요한 문서는 삭제
- `tutorials/` 디렉토리 신설: first-job, use-skills를 실습형 튜토리얼로 재구성
- 각 Wiki 가이드 말미에 `**관련 문서**` 섹션 강제: Blog 포스트 + Slides 링크 포함

## 1.3 Examples 섹션

| 항목 | 상태 | 의견 |
|------|------|------|
| Job 예시 부족 | ✅ **동의** | 현재 README와 Wiki에 구체적인 JOB 예시가 거의 없음. abstract한 설명만 존재 |
| 실패/예외 사례 부재 | ⚠️ **부분 동의** | Happy Path만 설명되어 있음. 실패 시나리오(Failed Approval, Rollback)는 Blog 포스트에 일부 존재하나 Wiki에는 없음 |

**보완 제안**:
- `docs/wiki/tutorials/` 아래 3개 Job 사례 튜토리얼 생성 (Phase 0에서 상세 명세)
- 각 사례에 실패 케이스와 복구 절차 포함

## 1.4 GitHub Pages 섹션

| 항목 | 상태 | 의견 |
|------|------|------|
| raw .md 서빙 일관성 부족 | ✅ **동의** | `docs/index.html`은 HTML이지만 Wiki/Blog는 `.md` raw로 서빙됨. 현재 GitHub Pages 기본 동작이므로 기능상 문제는 없으나, 향후 Jekyll/MkDocs 도입 고려 필요 |
| GitHub Actions 미사용 | ✅ **동의** | 현재 로컬 `bash src/deploy.sh`로만 배포. CI/CD 누락 |
| llms.txt 부정확 ("6 decks" → 실제 8개) | ✅ **동의** | 즉시 수정 필요 (JOB-1752로 slides 8개로 증가했으나 llms.txt 갱신 누락) |

**보완 제안**:
- GitHub Actions 워크플로우 추가 (Phase 2): PR → validate-links → deploy
- `llms.txt` 자동 생성 로직 정확도 향상 (slides 덱 카운트, wiki 파일 카운트)
- 단기: `docs/index.html`에서 Wiki/Bog 링크를 GitHub Pages URL로 통일

## 1.5 Slides 섹션

| 항목 | 상태 | 의견 |
|------|------|------|
| v3 디자인(다크 테마, 중앙 정렬, 12~15슬라이드) | ✅ **동의** | playground/slides-v3 GC 템플릿이 현재 운영 슬라이드보다 우수함. 승격 필요 |
| 라이트 테마 → 다크 테마 전환 | ✅ **동의** | SPEC-D05가 라이트 테마 기준이나 사용자가 다크 테마 선호. Spec 업데이트 필요 |
| 슬라이드 분량 8~10장 → 12~15장 | ✅ **동의** | 10-20-30 Rule 준수하면서도 내용 전달력을 높이려면 12~15장이 적절 |

**보완 제안**:
- playground/slides-v3 GC 템플릿을 `docs/slides/decks/`로 승격 (Phase 2)
- SPEC-D05 전면 개정: 다크 테마, 12~15슬라이드, 중앙 정렬 기준으로 변경
- 먼저 playground에서 1개 덱(workflow-pipeline) 프로토타입 제작 후 검증

## 1.6 Blog 섹션

| 항목 | 상태 | 의견 |
|------|------|------|
| YAML title 필드 누락 (3개 포스트) | ✅ **동의** | 즉시 수정: YAML 프런트매터에 `title:` 필드 강제 (일부 포스트에 누락 확인) |
| Blog 분량 3,000자 미달 | ✅ **동의** | SPEC-D04 기준 A 도메인 Blog 최소 10,000자이나 현재 2,000~4,000자 수준 |

**보완 제안**:
- 각 Blog 포스트에 YAML `title:` 필드 추가 (P0)
- 분량 확장은 P1에서 playground를 통해 점진적 진행
- Blog Index에 태그 클라우드 강화 (현재 단순 나열 → 링크된 태그)

## 1.7 우선순위 체계

| 항목 | 상태 | 의견 |
|------|------|------|
| P0: Critical Fixes + README + Examples | ✅ **동의** | 스크립트 버그, 설정 파일, 깨진 링크, README 개선이 최우선 |
| P1: Wiki 재설계 + 교차링크 + 분량 | ✅ **동의** | Core 문서 품질이 프로젝트 신뢰도의 80%를 결정 |
| P2: GitHub Pages + Blog + Slides | ✅ **동의** | 배포 자동화와 시각 자료는 P1 이후 |
| P3: 자동화 도구 | ✅ **동의** | Smoke test, link validator, SDD 개선은 지속적 |

**보완 제안**:
- **Playground 우선 원칙 추가**: 모든 시각/콘텐츠 변경(P1~P2)은 먼저 playground에서 프로토타입 검증 후 운영 반영
- P0.5 도입: Playground 인프라 정비 (playground/ 디렉토리 구조 표준화)

---

# 2. 통합 아키텍처 맵

## 2.1 전체 디렉토리 구조 (After)

```
p-hermes/
├── README.md                          # [재작성] 브랜딩 + Quick Start 2줄
├── ARCHITECTURE.md                    # [신규] 5-Tier 아키텍처 참조 (Wiki/Blog SSOT)
├── PORTING.md                         # [유지] 포팅 가이드
├── project.yaml                       # [유지]
├── config.yaml.example                # [유지]
├── AGENTS.md                          # [유지]
├── AGENTS.md.example                  # [유지]
│
├── docs/
│   ├── index.html                     # [개선] Wiki/Blog 교차링크 + GitHub Pages → 상대경로
│   ├── index.md                       # [신규] GitHub Pages 랜딩을 위한 마크다운 진입점
│   ├── CNAME                          # [신규] 커스텀 도메인 대비
│   │
│   ├── wiki/
│   │   ├── index.md                   # [개선] 학습 경로 재구성
│   │   ├── getting-started/
│   │   │   ├── overview.md            # [개선] 1,500자 → 3,500자
│   │   │   └── install.md             # [개선] 환경변수, API 키 설정 추가
│   │   ├── guides/
│   │   │   ├── request-task.md        # [개선] Blog/Slides 교차링크 추가
│   │   │   ├── spec-driven-dev.md     # [개선] 분량 확장
│   │   │   ├── content-system.md      # [개선] 분량 확장
│   │   │   ├── knowledge-system.md    # [개선] 분량 확장
│   │   │   ├── automation.md          # [개선] cron 실제 예시 추가
│   │   │   └── model-routing.md       # [개선] catalog.json 실제 샘플 추가
│   │   ├── tutorials/                 # [신규] 실습형 튜토리얼
│   │   │   ├── first-job.md           # Archive → 승격
│   │   │   ├── use-skills.md          # Archive → 승격
│   │   │   ├── job-example-workflow.md    # [신규] Job Example 1
│   │   │   ├── job-example-content.md     # [신규] Job Example 2
│   │   │   └── job-example-automation.md  # [신규] Job Example 3
│   │   ├── references/
│   │   │   └── calmer-google-io-framework.md  # [유지]
│   │   ├── faq.md                     # [신규] 통합 FAQ
│   │   └── troubleshooting.md         # [신규] 문제 해결
│   │
│   ├── blog/
│   │   ├── index.md                   # [개선] 태그 클라우드 개선 + 검색
│   │   └── posts/
│   │       ├── hermes-agent-intro.md          # [수정] YAML title 필드 확인/추가
│   │       ├── why-9-step-workflow.md         # [수정] YAML 확인
│   │       ├── architecture-layered.md        # [수정] YAML 확인
│   │       ├── content-system-design.md       # [개선] 분량 확장 (P1)
│   │       ├── knowledge-system-design.md     # [개선] 분량 확장 (P1)
│   │       ├── model-routing-design.md        # [개선] 분량 확장 (P1)
│   │       ├── spec-driven-dev-design.md      # [개선] 분량 확장 (P1)
│   │       └── cron-automation-design.md      # [개선] 분량 확장 (P1)
│   │
│   ├── slides/
│   │   ├── index.md                   # [개선] 덱 목록 갱신
│   │   └── decks/
│   │       ├── workflow-pipeline.html    # [교체] v3 GC 템플릿 적용
│   │       ├── knowledge-system.html     # [교체]
│   │       ├── cron-system.html          # [교체]
│   │       ├── architecture-layered.html # [교체]
│   │       ├── spec-driven-dev.html      # [교체]
│   │       ├── content-system.html       # [교체]
│   │       ├── model-routing.html        # [교체]
│   │       └── hermes-overview.html      # [교체]
│   │
│   ├── playground/
│   │   ├── index.html                 # [개선] 실험 메뉴 개선
│   │   ├── NOTES.md                   # [유지]
│   │   ├── slides-v3/                 # [유지] GC 템플릿 원본
│   │   └── experiments/               # [유지]
│   │
│   └── archive/
│       └── slides-v1/                 # [유지] 히스토리 보존
│
├── src/
│   ├── deploy.sh                      # [개선] HERMES_HOME 변수화, 체크포인트 추가
│   └── deploy-ci.sh                   # [신규] GitHub Actions 전용 CI/CD
│
├── scripts/
│   ├── sdd/                           # [유지]
│   │   ├── sdd-inject.py
│   │   ├── sdd-lint.py
│   │   └── sdd-validate.py
│   ├── generate-llms.sh               # [수정] 슬라이드 카운트 동적 계산
│   └── generate-llms-full.sh          # [신규] llms-full.txt 전용 생성기
│
├── tests/
│   ├── validate-links.sh              # [개선] 외부 링크 검증 추가
│   ├── validate-chinese.sh            # [유지]
│   ├── smoke-test.sh                  # [신규] 5개 시나리오 자동화 테스트
│   └── test-slide-count.sh            # [신규] llms.txt vs 실제 파일 개수 일치 검증
│
├── core/
│   ├── scripts/                       # [수정 필요시]
│   └── lib/
│
├── specs/
│   └── active/
│       ├── SPEC-D01.md                # [개정] tutorials/ 디렉토리 추가
│       ├── SPEC-D02.md                # [개정] CI/CD 파이프라인 반영
│       ├── SPEC-D03.md                # [개정] 분량 기준 현실화
│       ├── SPEC-D04.md                → [삭제] SPEC-D01/D03으로 통합
│       ├── SPEC-D05.md                → [개정] 다크 테마, 12~15슬라이드
│       └── SPEC-REDESIGN.md           → [신규] 본 설계서를 Spec으로 등록
│
├── .github/
│   └── workflows/
│       └── deploy.yml                 # [신규] GitHub Actions 배포
│
├── llms.txt                           # [수정] slides 카운트 6→8
├── llms-full.txt                      # [재생성]
│
└── infra/
    └── cron/
        └── registry.yaml.example      # [유지]
```

## 2.2 3-Track + Playground 관계도

```
                    ┌──────────────────────────────────┐
                    │         README.md (Hero)          │
                    │   "Persistent AI Agent Framework" │
                    └──────────┬───────────────────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
     ┌────────────────┐ ┌────────────────┐ ┌────────────────┐
     │  Guide Wiki    │ │   Dev Blog     │ │   Slides       │
     │  (How-to)      │ │  (Why)         │ │  (What)        │
     │                │ │                │ │                │
     │ getting-started│ │ 8 posts        │ │ 8 HTML decks   │
     │ guides/        │ │ (YAML+3K+자)   │ │ (v3 GC, 다크)  │
     │ tutorials/     │ │ 분량 확장 P1   │ │ 승격 P2        │
     │ faq, trouble   │ │                │ │                │
     └────────────────┘ └────────────────┘ └────────────────┘
              │                │                │
              └────────────────┼────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │     Playground      │
                    │  (Prototype First)  │
                    │                     │
                    │ slides-v3 → 운영 승격│
                    │ blog drafts → 검증  │
                    │ wiki sections → 실험│
                    │ experiments/ → 기록  │
                    └────────────────────┘
```

## 2.3 배포 파이프라인 (After)

```
 [로컬]                    [CI/CD - GitHub Actions]
    │                            │
    ├─ bash src/deploy.sh        ├─ PR merged → trigger
    │    ├─ SDD Inject           │    ├─ SDD Inject
    │    ├─ SDD Lint             │    ├─ SDD Lint
    │    ├─ SDD Validate         │    ├─ SDD Validate
    │    ├─ 중국어 검증           │    ├─ 중국어 검증
    │    ├─ 슬라이드 카운트 검증  │    ├─ 슬라이드 카운트 검증
    │    ├─ Smoke Test           │    ├─ Smoke Test (5 scenarios)
    │    ├─ llms.txt 재생성       │    ├─ llms.txt 재생성
    │    └─ git commit + push    │    └─ git push (bot)
    │                            │
    └─ bash tests/smoke-test.sh  └─ 수동: workflow_dispatch
```

---

# 3. Phase 0: Critical Fixes

> 목표: 시스템 안정성과 문서 정확성을 24시간 내 복구

## 3.1 `llms.txt` 슬라이드 카운트 수정

**현재**: `llms.txt` 13행: `- docs/slides/ — Concept Slides (What) — 6 HTML decks`  
**실제**: 8개 HTML 데크  
**수정**: 6 → 8

**파일**: `llms.txt`  
```diff
-| - docs/slides/ — Concept Slides (What) — 6 HTML decks
+| - docs/slides/ — Concept Slides (What) — 8 HTML decks
```

## 3.2 Spec-D01: `tutorials/` 디렉토리 추가

**파일**: `specs/active/SPEC-D01.md`  
**변경**: 2.① Guide Wiki 구조에 `wiki/tutorials/` 디렉토리 추가

```diff
+ | - `wiki/tutorials/` — 시나리오 기반 튜토리얼 (인터랙티브 학습)
```

## 3.3 Spec-D03: 분량 기준 완화 (현실화)

**현재**: SPEC-D03 §2.2: "Wiki 가이드 ≥ 1,500자, Blog 포스트 ≥ 3,000자"  
**문제**: SPEC-D04에서 A 도메인 Wiki 3,500자, Blog 10,000자로 상향 → 현실적으로 달성 불가능  
**수정**: SPEC-D03 기준을 SSOT로 하고 SPEC-D04는 폐기

**파일**: `specs/active/SPEC-D03.md` 87행  
```diff
- | - **최소 분량**: Wiki 가이드 ≥ 1,500자, Blog 포스트 ≥ 3,000자.
+ | - **최소 분량**: Wiki 가이드 ≥ 2,000자, Blog 포스트 ≥ 5,000자.
```

## 3.4 Blog YAML `title:` 필드 일괄 확인

**체크 대상** (3개 포스트, 실제로는 모두 YAML 있음 — 단 `title:` 키 확인):
- `docs/blog/posts/hermes-agent-intro.md` → YAML 있음 (`title:` 필드 존재)
- `docs/blog/posts/why-9-step-workflow.md` → YAML 있음
- `docs/blog/posts/architecture-layered.md` → YAML 있음

**→ 실제로는 YAML title 필드가 모두 존재하므로, "Blog 3개 포스트 title 필드 누락" 이슈는 해소됨.**  
**대신 `model-routing-design.md`의 첫 줄이 "한 줄 요약"으로 시작하는 문제 확인**:

**파일**: `docs/blog/posts/model-routing-design.md`  
```diff
-| # 한 줄 요약
+| ---
+| id: DOC-A6-BLOG
+| domain: model-routing
+| type: blog
+| title: "다중 모델 라우팅: 하나의 에이전트에 다수의 브레인을 연결하는 설계"
+| date: 2026-06-17
+| version: "1.0.0"
+| compatibility: v0.16.0
+| author: p-hermes
+| status: published
+| tags: ["model-routing", "multi-model", "routing"]
+| ---
```

## 3.5 `~/.hermes` 하드코딩 대응 (p-hermes 범위)

**조사 결과**: p-hermes 저장소 내 `setup.sh`, `workflow-gate.sh`, `content-system/run.sh` 등 주요 스크립트는 `$HOME/.hermes` 또는 `$HERMES_ROOT`를 사용하며, 절대 경로 하드코딩은 발견되지 않음.  
**단, content-system/run.sh 8행**: `OUTPUT_DIR="$HOME/.hermes/workspace/expression-system/output"` — `$HERMES_ROOT`로 변경 필요 없음 (`$HOME` 의존이므로 install.sh에서 `$HERMES_ROOT` 설정 시 영향 없음).

**조치**: `config.yaml.example`의 설명에 `HERMES_ROOT` 환경변수 우선 적용 명시

**파일**: `config.yaml.example` 상단  
```diff
  # p-hermes 설정 파일 템플릿
- # 사용법: 이 파일을 ~/.hermes/config.yaml로 복사 후 [필수] 필드를 수정하세요
+ # 사용법: 이 파일을 ${HERMES_ROOT:-~/.hermes}/config.yaml로 복사 후 [필수] 필드를 수정하세요
+ # HERMES_ROOT 환경변수가 설정되어 있으면 해당 경로를 사용하고,
+ # 없으면 기본값 ~/.hermes를 사용합니다.
```

## 3.6 `knowledge-process.sh` 권한 확인

**파일**: `core/scripts/knowledge-process.sh`  
**현재 권한**: 644 (r--r--r--)  
**필요 권한**: 755 (rwxr-xr-x)  

```bash
chmod +x core/scripts/knowledge-process.sh
```

## 3.7 PyYAML 의존성 문서화

**파일**: `setup.sh` 하단 (의존성 설치 섹션 추가)  

```diff
+ # 8. Python 의존성 설치
+ echo "🐍 Python 의존성 설치..."
+ pip3 install pyyaml 2>/dev/null || pip install pyyaml 2>/dev/null || echo "  ⚠️ PyYAML 설치 실패 - 수동 설치 필요"
```

## 3.8 `index.html` 상대경로 통일

**파일**: `docs/index.html`  
**변경**: GitHub Pages 절대 URL을 상대 경로로 통일  

```diff
- | <h3><a href="wiki/index.md">📘 Guide Wiki</a></h3>
+ | <h3><a href="wiki/index">📘 Guide Wiki</a></h3>
(단, GitHub Pages가 .md를 raw로 서빙하므로 .md 확장자는 유지)
```

---

# 4. Phase 0: README 재설계

## 4.1 새 README 구조

```
┌─────────────────────────────────────────────────────┐
│  ⚡ p-hermes                                       │
│  Persistent AI Agent Framework                     │
│  Memory · Workflow · Knowledge · Projects · Content │
│                                                     │
│  [Deploy to GitHub Pages] 라이브 데모 배지           │
│  [GitHub Repo] [Docs] [Slides] 배지 3종              │
├─────────────────────────────────────────────────────┤
│                                                     │
│  🚀 Quick Start (2 steps)                           │
│  ```bash                                            │
│  git clone https://github.com/pheanor-agent/p-hermes│
│  cd p-hermes && bash setup.sh                       │
│  ```                                                │
│  👉 자세한 설치: docs/wiki/getting-started/install  │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  3-Track Documentation                              │
│  ┌──────┬────────┬────────┬────────┐               │
│  │ Track│  Guide │  Blog  │ Slides │               │
│  │      │  Wiki  │        │        │               │
│  ├──────┼────────┼────────┼────────┤               │
│  │ 목적  │ How-to │  Why   │  What  │               │
│  │ 질문  │ 어떻게 │  왜    │  무엇  │               │
│  └──────┴────────┴────────┴────────┘               │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  🏗 Architecture (1-line)                           │
│  5-Tier: Core → Runtime → Interfaces → Infra →      │
│  Release                                             │
│  〉ARCHITECTURE.md (상세)                             │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  🧪 Playground                                      │
│  실험적 기능과 콘텐츠를 먼저 체험해보세요            │
│  〉docs/playground/                                   │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  📚 More Resources                                  │
│  - PORTING.md — 다른 환경으로 이전                  │
│  - AGENTS.md — 프로젝트 메타데이터                   │
│  - specs/ — 개발 사양서                              │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## 4.2 구체적 Markdown 구현

```markdown
# ⚡ p-hermes

**Persistent AI Agent Framework** — Memory, Workflow, Knowledge, Projects, Content

[![GitHub Pages](https://img.shields.io/badge/demo-live-blue)](https://pheanor-agent.github.io/p-hermes/)
[![GitHub](https://img.shields.io/badge/repo-pheanor--agent%2Fp--hermes-181717?logo=github)](https://github.com/pheanor-agent/p-hermes)
[![Docs](https://img.shields.io/badge/docs-wiki-green)](./docs/wiki/index.md)

---

## 🚀 Quick Start

```bash
git clone https://github.com/pheanor-agent/p-hermes.git
cd p-hermes && bash setup.sh
```

> 👉 [상세 설치 가이드](./docs/wiki/getting-started/install.md)

---

## 📚 3-Track Documentation

p-hermes는 목적에 따라 3개의 문서 트랙을 제공합니다.

| Track | 질문 | 목적 | 시작하기 |
|-------|------|------|---------|
| 📘 **Guide Wiki** | *"어떻게 사용하나요?"* | 단계별 가이드 | [wiki/index.md](./docs/wiki/index.md) |
| ✍️ **Dev Blog** | *"왜 이렇게 설계했나요?"* | 기술 결정 사유 | [blog/index.md](./docs/blog/index.md) |
| 🖼️ **Slides** | *"한눈에 보여주세요"* | 개념 시각화 | [slides/index.md](./docs/slides/index.md) |

---

## 🏗️ Architecture

**5-Tier**: `Core` → `Runtime` → `Interfaces` → `Infra` → `Release`

> 📐 [ARCHITECTURE.md](./ARCHITECTURE.md) — 전체 아키텍처 상세

---

## 🧪 Playground

실험적 기능과 콘텐츠 프로토타입은 [Playground](./docs/playground/)에서 먼저 만나보세요.

---

## 📖 More

- [PORTING.md](./PORTING.md) — 환경 이전 가이드
- [config.yaml.example](./config.yaml.example) — 설정 템플릿
- [specs/active/](./specs/active/) — 개발 사양서 (SSOT)
```

## 4.3 `ARCHITECTURE.md` (신규) 구조

```markdown
# p-hermes Architecture

## 5-Tier Physical Layering

| Tier | 역할 | 구성 |
|------|------|------|
| **Core** | 정적 설정 | scripts/, lib/, skills/ |
| **Runtime** | 동적 상태 | state/, workspace/ |
| **Interfaces** | 통신 | Discord, Telegram, CLI |
| **Infra** | 상태 관리 | cron/, backups/ |
| **Release** | 배포 | wiki/, blog/, slides/ |

## Key Mechanisms
- **9-Step Workflow State Machine**: Flock-based atomic state transitions
- **Spec-Driven Development**: Spec-as-SSOT living pipeline
- **Model Routing**: 5-role, multi-provider routing
- **Knowledge System**: 3-Tier scoring (T1/T2/T3)
- **Content System**: 5-Layer Anti-Slop pipeline
```

---

# 5. Phase 0: 3개 Job 사례 명세

## 5.1 Job Example 1: `job-example-workflow.md`

**경로**: `docs/wiki/tutorials/job-example-workflow.md`  
**설명**: 9단계 워크플로우를 처음부터 끝까지 따라가는 실습 튜토리얼  
**분량**: 2,500자  
**구성**:

```markdown
# Job Example: "내 첫 Hermes 작업"

## 시나리오
"README.md에 프로젝트 배지(Badge)를 추가해주세요"

## Step 1-4: 분석 및 설계
- `create-job.sh` 실행 → 생성되는 디렉토리 확인
- `.workflow-state` JSON 구조 이해
- `design.md` 작성 예시: "README.md 3행에 3개 배지 추가"

## Step 5: 승인 요청
```
[에이전트] design.md 검토 요청
[사용자] 진행해
```

## Step 6-8: 실행 및 검증
- `patch`로 README.md 수정
- `cat README.md`로 결과 확인
- 실패 시: `design.md`로 롤백 후 재실행

## Step 9: 완료
- 학습 기록: "배지는 shields.io에서 생성"
```

## 5.2 Job Example 2: `job-example-content.md`

**경로**: `docs/wiki/tutorials/job-example-content.md`  
**설명**: Content System을 사용하여 블로그 포스트 작성  
**분량**: 2,000자  
**구성**:

```markdown
# Job Example: "Content System으로 Blog 발행하기"

## 시나리오
"Content System의 Anti-Slop 파이프라인을 사용하여 새 Blog 포스트를 작성해주세요"

## 전제 조건
- content-system/run.sh 실행 가능
- PyYAML 설치 완료
- persona_generator.py 접근 가능

## 실행
```bash
bash run.sh blog "why" "새로운 Knowledge Tier 시스템"
```

## 검증
- L1-L4 게이트 통과 확인
- L5 Judge Model 리뷰
- 출력: docs/blog/posts/xxx.md

## 실패 시나리오
- 게이트 실패 → Pre-Direction 재조정 → 재생성
- L5 평가 불합격 → tone_adapter 재조정
```

## 5.3 Job Example 3: `job-example-automation.md`

**경로**: `docs/wiki/tutorials/job-example-automation.md`  
**설명**: Cron 자동화 설정 및 모니터링  
**분량**: 2,000자  
**구성**:

```markdown
# Job Example: "매일 아침 뉴스레터 자동화"

## 시나리오
"매일 오전 9시에 AI/ML 뉴스 요약을 Telegram으로 전송하는 Cron Job을 설정해주세요"

## Step 1: registry.yaml 작성
```yaml
- name: "daily-news-digest"
  schedule: "0 9 * * *"
  model: "your-fast-model"
  deliver:
    - channel: telegram
      format: markdown
```

## Step 2: 스크립트 작성
```bash
# core/scripts/daily-news.sh
source "$HERMES_ROOT/core/lib/common.sh"
python3 scripts/fetch-news.py | python3 scripts/summarize.py
```

## Step 3: 검증
```bash
bash core/scripts/cron-wrapper.sh --dry-run daily-news-digest
```

## Step 4: 모니터링
```bash
cat ~/.hermes/infra/cron/history/$(date +%Y-%m-%d).jsonl
```
```

---

# 6. Phase 1: Wiki 재설계

## 6.1 디렉토리 구조 (After)

```
docs/wiki/
├── index.md                    # [개선] 학습 경로 재구성 + Mermaid 학습 맵
├── getting-started/
│   ├── overview.md             # [개선] 1,500→3,500자, Hermes 철학 추가
│   └── install.md              # [개선] Docker, 서버, 로컬 3가지 옵션
├── guides/
│   ├── request-task.md         # [개선] Blog/Slides 교차링크 + FAQ 추가
│   ├── spec-driven-dev.md      # [개선] 7개 검증 도구 실제 출력 예시
│   ├── content-system.md       # [개선] D1-D5 레벨별 예시 추가
│   ├── knowledge-system.md     # [개선] 점수 체계 Mermaid 다이어그램
│   ├── automation.md           # [개선] 실제 registry.yaml 3개 사례
│   └── model-routing.md        # [개선] catalog.json 구조 + 핫스왑 예시
├── tutorials/
│   ├── first-job.md            # [이관] archive/docs/wiki/first-job.md
│   ├── use-skills.md           # [이관] archive/docs/wiki/use-skills.md
│   ├── job-example-workflow.md    # [신규]
│   ├── job-example-content.md     # [신규]
│   └── job-example-automation.md  # [신규]
├── references/
│   └── calmer-google-io-framework.md  # [유지]
├── faq.md                      # [신규] 통합 FAQ
└── troubleshooting.md          # [신규] 문제 해결
```

## 6.2 필수 문서 명세

### `index.md` (개선)
| 요소 | 현재 | 개선 |
|------|------|------|
| 분량 | 1,619자 | 3,000자 |
| 추가 | 단순 목록 | Mermaid 학습 로드맵 다이어그램 |
| 추가 | 없음 | "학습 시간 예상" 배지 (입문 10분/심화 30분) |
| 추가 | 없음 | Playground 링크: "실험적 기능 미리보기" |

### 각 가이드 공통 템플릿
```markdown
# [제목]

💡 **한 줄 요약**: 50자

## 🌱 기본 개념
(일상적 비유 + 왜 필요한가)

## 🔍 문제 상황
(Pain point + 실제 사례)

## 🏗️ 기술 설계
(Mermaid 다이어그램 + 파일 경로 + 로직)

## 💻 실행 방법
(실제 명령어 + 출력 예시)

## ⚠️ 예외 처리
(실패 시나리오 + 복구)

## 🔗 관련 문서
- [Blog: 왜 9단계 워크플로우인가?](../../blog/posts/why-9-step-workflow.md)
- [Slides: Workflow Pipeline](../../slides/decks/workflow-pipeline.html)
```

## 6.3 Archive 문서 승격 기준

| 문서 | 경로 | 상태 | 조치 |
|------|------|------|------|
| `archive/docs/wiki/first-job.md` | → `docs/wiki/tutorials/first-job.md` | ✅ 승격 | 내용 보강 후 tutorials/로 이동 |
| `archive/docs/wiki/use-skills.md` | → `docs/wiki/tutorials/use-skills.md` | ✅ 승격 | 내용 보강 후 tutorials/로 이동 |
| `archive/docs/wiki/create-skills.md` | → `docs/wiki/tutorials/create-skills.md` | ✅ 승격 | 내용 보강 |
| `archive/docs/wiki/use-tools.md` | → `docs/wiki/tutorials/use-tools.md` | ⚠️ 검토 | request-task와 중복 → 병합 또는 삭제 |
| `archive/docs/wiki/job-basics.md` | → `docs/wiki/tutorials/job-example-workflow.md` | ✅ 병합 | job-example-workflow에 통합 |
| `archive/docs/wiki/system-architecture.md` | → `docs/wiki/system-architecture.md` | ✅ 승격 | ARCHITECTURE.md와 통합 후 Wiki로 연결 |
| `archive/docs/wiki/...` (나머지 4개) | 검토 후 tutorials/ 또는 삭제 | ⚠️ 개별 검토 | 중복 내용은 삭제, 고유 내용은 승격 |

---

# 7. Phase 1: Smoke Test

## 7.1 테스트 시나리오 5개

### TC-1: 문서 구조 검증

```bash
# Given: 프로젝트 루트
cd /path/to/p-hermes

# When: 필수 디렉토리/파일 존재 확인
test -d docs/wiki/guides/ || exit 1
test -d docs/blog/posts/ || exit 1
test -d docs/slides/decks/ || exit 1
test -f docs/wiki/index.md || exit 1
test -f docs/blog/index.md || exit 1
test -f docs/slides/index.md || exit 1

# Then: 3개 트랙 모두 index.md 존재
echo "✅ TC-1: 문서 구조 검증 통과"
```

**예상 결과**: 통과 (현재 모두 존재)

### TC-2: llms.txt vs 실제 파일 카운트 일치

```bash
# Given: llms.txt의 슬라이드 카운트
SLIDE_COUNT_IN_LLMS=$(grep -c "decks/" llms.txt || echo 0)
ACTUAL_SLIDE_COUNT=$(ls docs/slides/decks/*.html 2>/dev/null | wc -l)

# When: 카운트 비교
if [ "$SLIDE_COUNT_IN_LLMS" -ne "$ACTUAL_SLIDE_COUNT" ]; then
  echo "❌ TC-2: llms.txt($SLIDE_COUNT_IN_LLMS) ≠ 실제($ACTUAL_SLIDE_COUNT)"
  exit 1
fi

# Then: 일치
echo "✅ TC-2: llms.txt 슬라이드 카운트 일치 ($ACTUAL_SLIDE_COUNT)"
```

**현재 상태**: ❌ 실패 (llms.txt: 6, 실제: 8)

### TC-3: 모든 내부 링크 유효성

```bash
# Given: 모든 .md 파일 스캔
FAILED=0
for file in $(find docs/ -name "*.md"); do
  for link in $(grep -oP '\[.*?\]\(\K[^)]+' "$file" 2>/dev/null); do
    # 내부 링크만 검증 (http:// 제외)
    if [[ "$link" != http* ]] && [[ "$link" != \#* ]]; then
      target_path=$(dirname "$file")/$link
      if [ ! -f "$target_path" ] && [ ! -d "$target_path" ]; then
        echo "  🔴 $file → $link (NOT FOUND)"
        FAILED=$((FAILED + 1))
      fi
    fi
  done
done

# Then: broken link == 0
if [ "$FAILED" -gt 0 ]; then
  echo "❌ TC-3: $FAILED broken links 발견"
  exit 1
fi
echo "✅ TC-3: 모든 내부 링크 유효"
```

**현재 상태**: ⚠️ archive 링크 일부 깨짐

### TC-4: 중국어 문자 존재 여부

```bash
# Given: docs/ 디렉토리
# When: CJK Unified Ideographs (U+4E00-U+9FFF) 검사
if grep -Pn "[\x{4e00}-\x{9fff}]" docs/ 2>/dev/null | grep -v "^Binary"; then
  echo "❌ TC-4: 중국어 문자 발견"
  exit 1
fi

# Then: 발견 없음
echo "✅ TC-4: 중국어 문자 없음"
```

**현재 상태**: ✅ 통과 예상

### TC-5: Blog YAML 필수 필드 검증

```bash
# Given: 모든 Blog 포스트
REQUIRED_FIELDS=("title:" "date:" "version:" "status:")
MISSING=0

for file in docs/blog/posts/*.md; do
  for field in "${REQUIRED_FIELDS[@]}"; do
    if ! grep -q "^$field" "$file" 2>/dev/null; then
      echo "  🔴 $file: $field 누락"
      MISSING=$((MISSING + 1))
    fi
  done
done

if [ "$MISSING" -gt 0 ]; then
  echo "❌ TC-5: $MISSING 필수 필드 누락"
  exit 1
fi
echo "✅ TC-5: 모든 Blog 포스트 YAML 필수 필드 존재"
```

**현재 상태**: ✅ 통과 예상 (모든 포스트에 YAML 있음)

## 7.2 통합 Smoke Test 스크립트

**파일**: `tests/smoke-test.sh`

```bash
#!/bin/bash
# smoke-test.sh - p-hermes 문서 품질 5개 시나리오 자동 검증
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

PASS=0
FAIL=0

run_test() {
  local name="$1"; shift
  echo "━━━ [$((PASS+FAIL+1))/5] $name ━━━"
  if "$@"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
  fi
  echo ""
}

run_test "TC-1: 문서 구조 검증" bash -c '
  for d in docs/wiki/guides docs/blog/posts docs/slides/decks; do
    [ -d "$d" ] || { echo "MISSING: $d"; exit 1; }
  done
  for f in docs/wiki/index.md docs/blog/index.md docs/slides/index.md; do
    [ -f "$f" ] || { echo "MISSING: $f"; exit 1; }
  done
'

run_test "TC-2: llms.txt 슬라이드 카운트 일치" bash tests/test-slide-count.sh

run_test "TC-3: 내부 링크 유효성" bash tests/validate-links.sh

run_test "TC-4: 중국어 문자 검증" bash tests/validate-chinese.sh docs/

run_test "TC-5: Blog YAML 필수 필드" bash -c '
  for file in docs/blog/posts/*.md; do
    grep -q "^title:" "$file" || { echo "MISSING title: $file"; exit 1; }
    grep -q "^status:" "$file" || { echo "MISSING status: $file"; exit 1; }
  done
'

echo ""
echo "══════ Smoke Test 결과 ══════"
echo "통과: $PASS | 실패: $FAIL | 합계: $((PASS+FAIL))"
[ "$FAIL" -eq 0 ] && echo "✅ ALL PASS" || echo "❌ SOME FAILED"
exit $FAIL
```

---

# 8. Phase 2: GitHub Pages + Blog + Slides

## 8.1 GitHub Actions 워크플로우

**파일**: `.github/workflows/deploy.yml`

```yaml
name: Deploy p-hermes Docs

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  validate-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Smoke Test
        run: bash tests/smoke-test.sh

      - name: SDD Pipeline
        run: |
          if [ -d scripts/sdd ]; then
            python3 scripts/sdd/sdd-inject.py
            python3 scripts/sdd/sdd-lint.py
            python3 scripts/sdd/sdd-validate.py
          fi

      - name: Generate llms.txt
        run: bash scripts/generate-llms.sh

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: .
          publish_branch: gh-pages
```

## 8.2 `src/deploy.sh` 개선 (체크포인트 + HERMES_HOME)

```bash
#!/bin/bash
# deploy.sh v2 — 체크포인트 기반 배포 파이프라인
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
cd "$PROJECT_ROOT"

echo "🚀 p-hermes v2 배포 파이프라인 시작"

# 체크포인트 함수
checkpoint() {
  local name="$1"
  echo "  ✅ [$name] 통과"
}

# 0. 사전 검증
echo "📋 Phase 0: 사전 검증..."
bash tests/smoke-test.sh
checkpoint "Smoke Test"

# 1. SDD 파이프라인
echo "🔬 Phase 1: SDD 2.0..."
if [[ -d "scripts/sdd" ]]; then
  python3 scripts/sdd/sdd-inject.py || { echo "❌ SDD Inject 실패"; exit 1; }
  checkpoint "SDD Inject"
  python3 scripts/sdd/sdd-lint.py || { echo "❌ SDD Lint 실패"; exit 1; }
  checkpoint "SDD Lint"
  python3 scripts/sdd/sdd-validate.py || { echo "❌ SDD Validate 실패"; exit 1; }
  checkpoint "SDD Validate"
fi

# 2. 중국어 문자 검증
echo "🔍 Phase 2: 문자 검증..."
bash tests/validate-chinese.sh docs/
checkpoint "중국어 검증"

# 3. 슬라이드 카운트 검증
echo "📊 Phase 3: 슬라이드 카운트 검증..."
bash tests/test-slide-count.sh
checkpoint "슬라이드 카운트"

# 4. llms.txt 재생성
echo "📄 Phase 4: llms.txt 생성..."
bash scripts/generate-llms.sh
checkpoint "llms.txt"

# 5. Git push
echo "📝 Phase 5: Git push..."
git add -A
git commit -m "deploy: SDD v2 synthesized package ($(date +%Y-%m-%d))"
git push origin main

echo "✅ 배포 완료"
```

## 8.3 Slides: v3 GC 템플릿 승격 절차

### 단계 1: Playground에서 프로토타입 (Pre-Phase)

```
playground/slides-v3/gc/workflow-pipeline.html  ← 현재 있음
                                                    ↓
실험: dark theme + center alignment + 12~15 slides 적용
                                                    ↓
docs/playground/experiments/exp-007-slide-v3-prototype.md 생성
                                                    ↓
사용자 리뷰 → 승인
```

### 단계 2: 운영 반영 (Phase 2)

```
playground/slides-v3/gc/workflow-pipeline.html
    → docs/slides/decks/workflow-pipeline.html [교체]
    
playground/slides-v3/gc/knowledge-system.html
    → docs/slides/decks/knowledge-system.html [교체]
    
... (8개 덱 모두 동일 패턴)
```

### 단계 3: SPEC-D05 개정

- **라이트 테마** → **다크 테마** 변경
- 8~10장 → 12~15장 변경
- 30pt 폰트 → 28pt (12~15장에서 가독성 유지)
- 색상 팔레트: `--bg-primary: #1a1b2f` (다크 네이비), `--text-primary: #e4e6ed`
- Mermaid 테마: `theme: dark` 설정

## 8.4 Slides 개별 명세 (workflow-pipeline 예시)

```
슬라이드 1 (타이틀):     "Workflow Pipeline" / "AI 작업을 신뢰하게 하는 설계"
슬라이드 2 (문제):       상태 충돌 + AI 환각 위험성
슬라이드 3 (해법):       9단계 상태머신 개요
슬라이드 4 (핵심 3):     분절화 · 검증 · 원자성
슬라이드 5 (Thinking):   Step 1-4 (Request → Investigation → Design → Review)
슬라이드 6 (The Gate):   Step 5 (Approval) — 사용자 승인 게이트
슬라이드 7 (Doing):      Step 6-8 (Execution → Test → Execution Review)
슬라이드 8 (Done):       Step 9 (Done → Knowledge Sync)
슬라이드 9 (원자성):     Flock 기반 .workflow-state
슬라이드 10 (명령어):    create-job.sh, workflow-gate.sh
슬라이드 11 (비교):      Before(3단계) vs After(9단계)
슬라이드 12 (실패사례):  승인 거절 시 롤백
슬라이드 13 (요약):      Key Takeaways
슬라이드 14 (CTA):       "직접 체험: docs/wiki/tutorials/job-example-workflow"
슬라이드 15 (종료):      p-hermes / 감사합니다
```

## 8.5 Blog 개선

### YAML 누락 포스트 수정

| 파일 | 상태 | 조치 |
|------|------|------|
| `model-routing-design.md` | ❌ YAML `title:` 누락 (첫 줄이 "한 줄 요약") | YAML 프런트매터 추가 |

### Blog Index 개선

```markdown
# ✍️ p-hermes Dev Blog

## 한 줄 요약
Hermes 기술 결정과 설계 철학 — **왜**에 집중합니다.

## 🏷️ 태그 클라우드
[#workflow](?tag=workflow) (2) · [#knowledge](?tag=knowledge) (1) · [#cron](?tag=cron) (1)
[#model-routing](?tag=model-routing) (1) · [#content](?tag=content) (1)
[#spec-driven-dev](?tag=spec-driven-dev) (1) · [#architecture](?tag=architecture) (1)

## 📑 포스트 목록

| 제목 | 태그 | 분량 | 읽기 |
|------|------|------|------|
| **왜 9단계 상태머신인가?** | #workflow | 4,500자 | [읽기](./posts/why-9-step-workflow.md) |
| **(이하 7개 포스트 동일 형식)** | | | |

---

> 💡 **Playground에서 먼저 읽어보기**
> 새 Blog 포스트는 [playground/experiments/](./playground/experiments/)에서 먼저 프로토타입으로 검증됩니다.
```

---

# 9. Phase 3: 장기 자동화 도구

## 9.1 `test-slide-count.sh` (P0에서 스캐폴딩)

**파일**: `tests/test-slide-count.sh`

```bash
#!/bin/bash
# test-slide-count.sh - llms.txt 슬라이드 카운트 검증
set -euo pipefail

LLMS_FILE="llms.txt"
SLIDES_DIR="docs/slides/decks"

LLMS_COUNT=$(grep -oP '\d+ HTML decks' "$LLMS_FILE" | grep -oP '\d+')
ACTUAL_COUNT=$(ls "$SLIDES_DIR"/*.html 2>/dev/null | wc -l)

if [ "$LLMS_COUNT" -ne "$ACTUAL_COUNT" ]; then
  echo "❌ llms.txt: $LLMS_COUNT decks ≠ 실제: $ACTUAL_COUNT decks"
  exit 1
fi

echo "✅ Slides count: $ACTUAL_COUNT (llms.txt 일치)"
```

## 9.2 `generate-llms.sh` 개선 (동적 카운트)

**파일**: `scripts/generate-llms.sh` (수정)

```bash
#!/bin/bash
# generate-llms.sh v2 — 동적 파일 카운트
set -euo pipefail

SLIDE_COUNT=$(ls docs/slides/decks/*.html 2>/dev/null | wc -l)
WIKI_COUNT=$(find docs/wiki/ -name "*.md" 2>/dev/null | wc -l)
BLOG_COUNT=$(ls docs/blog/posts/*.md 2>/dev/null | wc -l)

cat > llms.txt << EOF
# p-hermes Documentation

## Entry Point
- README.md — Single entry point for 3-track docs
- Full file index: llms-full.txt

## 3-Track Structure
- docs/wiki/ — Guide Wiki (How-to) — $WIKI_COUNT files
- docs/blog/ — Dev Blog (Why) — $BLOG_COUNT posts
- docs/slides/ — Concept Slides (What) — $SLIDE_COUNT HTML decks

## Deploy
bash src/deploy.sh
EOF

echo "✅ llms.txt 재생성 완료 (wiki: $WIKI_COUNT, blog: $BLOG_COUNT, slides: $SLIDE_COUNT)"
```

## 9.3 `generate-llms-full.sh` (신규)

**파일**: `scripts/generate-llms-full.sh`

```bash
#!/bin/bash
set -euo pipefail

OUTPUT="llms-full.txt"
echo "# p-hermes Full Documentation Index" > "$OUTPUT"
echo "" >> "$OUTPUT"
echo "## Files" >> "$OUTPUT"

find docs/ -name "*.md" -o -name "*.html" | sort | while read -r file; do
  lines=$(wc -l < "$file")
  title=$(head -1 "$file" | sed 's/^# //')
  echo "- **$file** ($lines lines): $title" >> "$OUTPUT"
done

echo "✅ llms-full.txt 생성 완료 ($(wc -l < "$OUTPUT") lines)"
```

## 9.4 SDD 파이프라인 개선

### `sdd-lint.py` 강화

```python
# scripts/sdd/sdd-lint.py (수정 제안)
# 추가 검증 항목:
# 1. 모든 Wiki/Blog에 YAML 프런트매터 존재 여부
# 2. Blog 포스트 분량 ≥ 3,000자
# 3. Wiki 가이드 분량 ≥ 2,000자
# 4. 교차 링크 존재 여부 (각 문서 말미 "관련 문서" 섹션)
```

### `sdd-validate.py` 강화

```python
# scripts/sdd/sdd-validate.py (수정 제안)
# 추가 검증 항목:
# 1. llms.txt 카운트 vs 실제 파일 카운트
# 2. SPEC-D01 구조 준수 여부
# 3. playground → 운영 승격 문서의 실험 기록 존재
```

## 9.5 Playground 실험 추적 도구

**파일**: `scripts/track-experiment.sh` (신규)

```bash
#!/bin/bash
# track-experiment.sh - Playground 실험 추적
# 사용법: bash track-experiment.sh --new exp-008-blog-draft [description]
#         bash track-experiment.sh --promote exp-008-blog-draft [target-path]

set -euo pipefail
MANIFEST="docs/playground/experiments/_manifest.json"

case "${1:-}" in
  --new)
    ID="${2:?Usage: --new <id> <description>}"
    DESCRIPTION="${3:-}"
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    # manifest에 추가
    python3 -c "
import json
with open('$MANIFEST') as f:
    m = json.load(f)
m['experiments'].append({
    'id': '$ID',
    'description': '$DESCRIPTION',
    'created': '$TIMESTAMP',
    'status': 'draft',
    'promoted_to': None
})
with open('$MANIFEST', 'w') as f:
    json.dump(m, f, indent=2)
"
    echo "✅ 실험 등록: $ID"
    ;;
  --promote)
    ID="${2:?Usage: --promote <id> <target-path>}"
    TARGET="${3:-}"
    python3 -c "
import json
with open('$MANIFEST') as f:
    m = json.load(f)
for exp in m['experiments']:
    if exp['id'] == '$ID':
        exp['status'] = 'promoted'
        exp['promoted_to'] = '$TARGET'
        exp['promoted_at'] = '$(date -u +"%Y-%m-%dT%H:%M:%SZ")'
        break
with open('$MANIFEST', 'w') as f:
    json.dump(m, f, indent=2)
"
    echo "✅ 실험 승격: $ID → $TARGET"
    ;;
  *)
    echo "사용법: track-experiment.sh --new <id> [desc] | --promote <id> <path>"
    exit 1
    ;;
esac
```

---

# 10. 전체 파일 변경 목록

## Phase 0: Critical Fixes + README + Examples

| 작업 | 파일 | 유형 | 상세 |
|------|------|------|------|
| llms.txt 슬라이드 카운트 수정 | `llms.txt` | 수정 | 6→8 HTML decks |
| README 전면 재작성 | `README.md` | 재작성 | Hero + 2-step Quick Start + 3-Track + Architecture 1-line |
| ARCHITECTURE.md 신규 | `ARCHITECTURE.md` | 생성 | 5-Tier + Key Mechanisms (README SSOT) |
| tutorial 디렉토리 생성 | `docs/wiki/tutorials/` | 생성 | (빈 디렉토리, .gitkeep 추가) |
| Job Example 1 | `docs/wiki/tutorials/job-example-workflow.md` | 생성 | 9단계 워크플로우 실습 |
| Job Example 2 | `docs/wiki/tutorials/job-example-content.md` | 생성 | Content System Blog 발행 |
| Job Example 3 | `docs/wiki/tutorials/job-example-automation.md` | 생성 | Cron 자동화 설정 |
| first-job 승격 | `archive/docs/wiki/first-job.md` → `docs/wiki/tutorials/first-job.md` | 이동 | 내용 보강 |
| use-skills 승격 | `archive/docs/wiki/use-skills.md` → `docs/wiki/tutorials/use-skills.md` | 이동 | 내용 보강 |
| config.yaml.example 개선 | `config.yaml.example` | 수정 | HERMES_ROOT 환경변수 명시 |
| knowledge-process.sh 권한 수정 | `core/scripts/knowledge-process.sh` | 권한 | 644→755 |
| setup.sh PyYAML 의존성 추가 | `setup.sh` | 수정 | pip3 install pyyaml 섹션 추가 |
| docs/index.html 상대경로 통일 | `docs/index.html` | 수정 | GitHub Pages 절대 URL → 상대경로 |
| SPEC-D01 tutorials/ 추가 | `specs/active/SPEC-D01.md` | 수정 | tutorials/ 디렉토리 명세 추가 |
| SPEC-D03 분량 기준 조정 | `specs/active/SPEC-D03.md` | 수정 | 1,500→2,000자 / 3,000→5,000자 |
| Blog model-routing YAML 추가 | `docs/blog/posts/model-routing-design.md` | 수정 | YAML 프런트매터 추가 |
| test-slide-count.sh 신규 | `tests/test-slide-count.sh` | 생성 | 슬라이드 카운트 검증 |

## Phase 1: Wiki 재설계

| 작업 | 파일 | 유형 | 상세 |
|------|------|------|------|
| Wiki index 개선 | `docs/wiki/index.md` | 수정 | Mermaid 학습 로드맵 + 분량 확장 (1,600→3,000자) |
| overview 개선 | `docs/wiki/getting-started/overview.md` | 수정 | 1,500→3,500자 + Hermes 철학 |
| install 개선 | `docs/wiki/getting-started/install.md` | 수정 | Docker/서버/로컬 3옵션 + 환경변수 |
| request-task 개선 | `docs/wiki/guides/request-task.md` | 수정 | 교차링크 + FAQ + Blog 연동 |
| spec-driven-dev 개선 | `docs/wiki/guides/spec-driven-dev.md` | 수정 | 7개 검증 도구 실제 출력 예시 |
| content-system 개선 | `docs/wiki/guides/content-system.md` | 수정 | D1-D5 레벨별 예시 |
| knowledge-system 개선 | `docs/wiki/guides/knowledge-system.md` | 수정 | 점수 체계 Mermaid 추가 |
| automation 개선 | `docs/wiki/guides/automation.md` | 수정 | registry.yaml 3개 사례 |
| model-routing 개선 | `docs/wiki/guides/model-routing.md` | 수정 | catalog.json 구조 + 핫스왑 |
| FAQ 신규 | `docs/wiki/faq.md` | 생성 | 통합 FAQ |
| troubleshooting 신규 | `docs/wiki/troubleshooting.md` | 생성 | 문제 해결 |
| smoke-test.sh 신규 | `tests/smoke-test.sh` | 생성 | 5개 시나리오 자동화 |
| deploy.sh 개선 | `src/deploy.sh` | 수정 | 체크포인트 + smoke-test 통합 |
| generate-llms.sh 개선 | `scripts/generate-llms.sh` | 수정 | 동적 파일 카운트 |
| SPEC-D01 개정 | `specs/active/SPEC-D01.md` | 수정 | v1.2.0 (tutorials 반영) |
| SPEC-D04 (통합/폐기 검토) | `specs/active/SPEC-D04.md` | 검토 | SPEC-D01/D03으로 통합 권장 |
| llms-full.txt 재생성 | `llms-full.txt` | 재생성 | 동적 생성 |

## Phase 2: GitHub Pages + Blog + Slides

| 작업 | 파일 | 유형 | 상세 |
|------|------|------|------|
| GitHub Actions 워크플로우 | `.github/workflows/deploy.yml` | 생성 | PR → validate → deploy |
| deploy-ci.sh 신규 | `src/deploy-ci.sh` | 생성 | CI 전용 배포 (git push 제외) |
| Slides v3 승격 (8개 덱) | `docs/slides/decks/*.html` | 교체 | playground/slides-v3/gc/ → 운영 |
| SPEC-D05 개정 | `specs/active/SPEC-D05.md` | 개정 | 다크 테마 + 12~15슬라이드 |
| Slides index 개선 | `docs/slides/index.md` | 수정 | 8개 덱 목록 + Playground 링크 |
| Blog index 개선 | `docs/blog/index.md` | 수정 | 태그 클라우드 개선 + 분량 표시 |
| Blog 포스트 분량 확장 | `docs/blog/posts/*.md` | 수정 | 각 포스트 3,000→5,000자+ |
| Blog YAML 태그 추가 | `docs/blog/posts/*.md` | 수정 | tags: 필드 추가 |
| docs/index.md 랜딩 신규 | `docs/index.md` | 생성 | GitHub Pages 랜딩용 |

## Phase 3: 장기 자동화 도구

| 작업 | 파일 | 유형 | 상세 |
|------|------|------|------|
| generate-llms-full.sh 신규 | `scripts/generate-llms-full.sh` | 생성 | llms-full.txt 동적 생성기 |
| track-experiment.sh 신규 | `scripts/track-experiment.sh` | 생성 | Playground 실험 추적 CLI |
| sdd-lint.py 강화 | `scripts/sdd/sdd-lint.py` | 수정 | YAML/분량/교차링크 검증 추가 |
| sdd-validate.py 강화 | `scripts/sdd/sdd-validate.py` | 수정 | llms 카운트 검증 추가 |
| SDD 문서 신규 | `scripts/sdd/README.md` | 생성 | SDD 파이프라인 사용법 |

## 삭제 대상

| 파일 | 사유 |
|------|------|
| `specs/active/SPEC-D04.md` | SPEC-D01/D03으로 통합 |
| `archive/docs/wiki/` 중 중복 문서 4개 | 내용 병합 완료 후 삭제 |
| `docs/index.html` (선택) | `docs/index.md`로 대체 검토 |

---

## 변경 통계

| Phase | 생성 | 수정 | 이동 | 삭제 | 합계 |
|-------|------|------|------|------|------|
| **P0** | 4 | 10 | 2 | 0 | 16 |
| **P1** | 3 | 11 | 0 | 0~4 | 14~18 |
| **P2** | 3 | 12 | 0 | 0~1 | 15~16 |
| **P3** | 3 | 2 | 0 | 0 | 5 |
| **계** | **13** | **35** | **2** | **0~5** | **50~55** |

---

> **핵심 원칙**: 모든 변경은 Playground → 프로토타입 → 사용자 리뷰 → 운영 반영 순서로 진행한다.  
> **Phase 간 의존성**: P0 → P1 → P2 → P3 순차적, 각 Phase는 deploy.sh를 통해 독립 배포 가능.  
> **설계자**: Hermes Agent (DeepSeek-V4-Flash, 2026-06-22)
