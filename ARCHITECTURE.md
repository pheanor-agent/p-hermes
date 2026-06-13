# Hermes Agent Architecture

**Hermes Agent System — Full Architecture Reference**

---

## Overview

Hermes Agent는 3계층 아키텍처를 기반으로 하는 자율 AI 에이전트 플랫폼입니다. 각 계층은 명확한 책임 분리를 가지며, 계층 간에는 잘 정의된 인터페이스를 통해 통신합니다.

```
┌─────────────────────────────────────────────────────────────────┐
│                    Hermes Agent System                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Layer 1: Core Engine (핵심 엔진)            │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │   │
│  │  │  Model &     │  │   Skill      │  │   Workflow   │  │   │
│  │  │  Provider    │  │   System     │  │   Pipeline   │  │   │
│  │  │              │  │              │  │              │  │   │
│  │  │ • Multi-     │  │ • 144+       │  │ • 9-step     │  │   │
│  │  │   provider   │  │   skills     │  │   pipeline   │  │   │
│  │  │ • Fallback   │  │ • Category-  │  │ •            │  │   │
│  │  │ • Routing    │  │   based      │  │   checkpoint │  │   │
│  │  │ • Cost       │  │ • Trigger-   │  │   validation │  │   │
│  │  │  tracking    │  │   based      │  │              │  │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │         Layer 2: Knowledge & State (지식 및 상태)         │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │   │
│  │  │ Knowledge    │  │   Cron &     │  │ Blackboard & │  │   │
│  │  │   System     │  │  Automation  │  │    Bridge    │  │   │
│  │  │              │  │              │  │              │  │   │
│  │  │ • Wiki       │  │ • Periodic   │  │ • Dual-agent │  │   │
│  │  │   (T1/T2/T3) │  │   jobs       │  │   collab     │  │   │
│  │  │ •            │  │ •            │  │ •            │  │   │
│  │  │ References   │  │ No-agent     │  │ Blackboard   │  │   │
│  │  │ • Lessons    │  │   mode       │  │ • JOB        │  │   │
│  │  │ • News       │  │ •            │  │   management │  │   │
│  │  │              │  │ Registry     │  │              │  │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │        Layer 3: Integration & Output (연동 및 출력)       │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │   │
│  │  │  Messaging   │  │   Image      │  │   Content    │  │   │
│  │  │  Platform    │  │   Generation │  │   Creation   │  │   │
│  │  │              │  │              │  │              │  │   │
│  │  │ • Telegram   │  │ • ComfyUI    │  │ • Novel      │  │   │
│  │  │ • Discord    │  │ •            │  │   writing    │  │   │
│  │  │ •            │  │ OpenRouter   │  │ •            │  │   │
│  │  │ Channel      │  │   image      │  │ Creative     │  │   │
│  │  │  routing     │  │   models     │  │   content    │  │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Layer 1: Core Engine (핵심 엔진)

시스템의 핵심 처리 계층입니다. LLM 호출, 스킬 관리, 워크플로우 관리를 담당합니다.

### 1.1 Model & Provider

다중 LLM 제공사를 지원하며, 작업 유형에 따라 최적의 모델을 선택합니다.

**기능:**
- **Multi-Provider**: OpenRouter, Airrouter, Anthropic 등 지원
- **Model Routing**: 작업 유형별 모델 매핑 (예: design→Gemma-4, execution→Qwen3.6)
- **Fallback**: primary 모델 실패 시 secondary로 자동 전환
- **Cost Tracking**: 사용량 기반 로깅
- **Catalog**: `skills/custom/model-catalog/catalog.json` — 20개 모델 등록

**프로바이더 구성:**

| 프로바이더 | 모델 수 | 사용 예 |
|-----------|---------|---------|
| Airrouter | 3개 | 기본 모델 |
| Z.AI | 4개 | 대용량 작업 |
| OpenRouter | 13개 | 다양한 작업 |

**모델 라우팅 예시:**

```
workflow-gate 단계별 모델 전환:
  request    → Qwen3.6 (기본)
  design     → Gemma-4 (설계 특화)
  execution  → Qwen3.6 (고성능)
  test       → Qwen3.6 (검증)
```

### 1.2 Skill System

144개 이상의 스킬을 30개 이상 카테고리로 관리합니다.

**기능:**
- **Category-based Loading**: custom/ > software-development/ > creative/ 등 계층적 상속
- **Trigger-based Loading**: 키워드/패턴 매칭으로 자동 로딩
- **SKILL.md Documentation**: 각 스킬의 문서화
- **Inheritance**: 상위 카테고리 스킬 상속

**카테고리 구조:**

```
skills/
├── custom/              # 사용자 정의 (최우선)
├── software-development/  # 소프트웨어 개발
├── creative/            # 창의적 작업
├── research/            # 연구
├── writing/             # 글쓰기
├── system-common/       # 공통 유틸리티
└── ... (30+ categories)
```

### 1.3 Workflow Pipeline

9단계 상태 머신을 기반으로 작업을 관리합니다.

**파이프라인 단계:**

```
request → investigation → design → review → approval → execution → test → execution_review → done
  [0]        [1]              [2]      [3]       [4]         [5]         [6]      [7]             [8]
```

**핵심 기능:**
- **State File**: `.workflow-state` (JSON) — 작업의 단 하나의 진실원 (SSOT)
- **Checkpoint Validation**: I1~I16 검증 규칙
- **Auto Transition**: 단계 완료 후 즉시 다음 단계 진입
- **Scripts**: `create-job.sh`, `workflow-gate.sh`, `on-job-complete.sh`

---

## Layer 2: Knowledge & State (지식 및 상태 관리)

시스템이 학습하고 기억하는 계층입니다. 지식 축적, 자동화, 협업 상태를 관리합니다.

### 2.1 Knowledge System

시스템의 지식 저장소입니다.

**구성:**

| 구성 요소 | SSOT | 역할 |
|-----------|------|------|
| Wiki | `wiki/index.md` | 가공 지식, T1/T2/T3 중요도 분류 |
| References | `references/` | 외부 원본 (GitHub, 논문, 가이드) |
| Lessons | `lessons/` | 교훈 (JOB 완료 후 자동 생성) |
| News | `news/` | 주기적 뉴스 수집/번역 |

**T1/T2/T3 분류 (KPL 기반):**

| 등급 | 점수 | 설명 |
|------|------|------|
| T1 | ≥ 0.7 | 핵심 지식 (반드시 참조) |
| T2 | 0.4 ~ 0.69 | 참고 지식 |
| T3 | < 0.4 | 보조 지식 |

**갱신 파이프라인:**
- `wiki-process-filings.sh` (5분 간격)
- `build-scores.sh` (KPL 점수 계산)

### 2.2 Cron & Automation

주기 작업을 자동화합니다.

**구성:**

| 구성 요소 | 설명 |
|-----------|------|
| `registry.yaml` | 작업 레지스트리 (SSOT) |
| No-agent 모드 | 스크립트 전용 (LLM 불필요) |
| Agent 모드 | LLM 기반 판단/실행 |
| `cron/history/` | 실행 이력 |

**주기 패턴:**

| 주기 | 예시 |
|------|------|
| 30분 | 시스템 상태 확인 |
| 1시간 | 캐시 정리 |
| 2시간 | 지식 스캔 |
| Daily | 지식 파이프라인 |
| Weekly | 이벤트 버스 정리 |

### 2.3 Blackboard & Bridge

듀얼 에이전트 협업 (Hermes + OpenClaw)을 지원합니다.

**기능:**
- **Blackboard**: 상태 공유 파일 시스템 (`~/.hermes/state/`)
- **Bridge API**: 에이전트 간 통신
- **JOB Management**: 통합 JOB 번호 체계

---

## Layer 3: Integration & Output (연동 및 출력)

외부 시스템과 연동하고 콘텐츠를 생성하는 계층입니다.

### 3.1 Messaging Platform

| 플랫폼 | 기능 |
|--------|------|
| Telegram | 채널별 라우팅, 그룹 채팅 |
| Discord | 쓰레드별 타겟팅, 홈 채널 |
| `send_message` | 메시지 전송 도구 |

### 3.2 Image Generation

| 엔진 | 타입 | 기능 |
|------|------|------|
| ComfyUI | 로컬 | 이미지 생성 파이프라인 |
| OpenRouter | 클라우드 | Flux.2, Seedream 등 이미지 모델 |
| Queue | — | 배치 처리 + 그룹 격리 |

### 3.3 Content Creation

| 유형 | 설명 |
|------|------|
| Novel Writing | 웹소설 연재 (화/장/편 구조) |
| Creative Content | ASCII art, 인포그래픽, 슬라이드 |
| Documents | PowerPoint, PDF, HTML 생성 |

---

## System Matrix

시스템 간 연계 매트릭스입니다.

| From → To | 방식 | 자동화 |
|-----------|------|--------|
| 작업 → 지식 | JOB 완료 시 sync | ✅ `on-job-complete.sh` |
| 작업 → 백업 | 파일 삭제 전 | ✅ `pre-delete-backup.sh` |
| 작업 ← 크론 | 주기 작업 JOB 등록 | ✅ registry.yaml |
| 지식 ← 크론 | 지식 파이프라인 | ✅ daily-knowledge.sh |
| 백업 ← 크론 | Tier 1/2 실행 | ✅ crontab |
| 모델 → 작업 | workflow-gate 단계별 전환 | ✅ 자동 |
| 모델 → 표현력 | Model Selector 매핑 | ✅ 자동 |
| 표현력 → 배포 | D5 이미지→ComfyUI | ✅ 자동 |
| 사양서 → 작업 | Spec 체크포인트 검증 | ✅ workflow-gate |
| 사양서 → 지식 | knowledge/index.md 등록 | ✅ 자동 |
| 배포 ← 크론 | GPU health check | ✅ 15m |
| 작업 → 이벤트 버스 | 상태 전이 시 emit | ✅ workflow-gate.sh |
| 크론 → 이벤트 버스 | 작업 완료 시 emit | ✅ cron-wrapper.sh |
| 검증 → 이벤트 버스 | 검증 완료 시 emit | ✅ verify.sh |
| 지식 → 이벤트 버스 | 인덱싱 완료 시 emit | ✅ daily-knowledge.sh |

---

## Directory Structure

```
~/.hermes/
├── config.yaml                  # 메인 설정
├── AGENTS.md                    # 에이전트 설정
├── scripts/                     # 168개 스크립트
├── skills/                      # 144개 스킬
│   ├── custom/                  # 사용자 정의 (최우선)
│   ├── software-development/    # 소프트웨어 개발
│   ├── creative/                # 창의적 작업
│   ├── system-common/           # 공통 유틸리티
│   └── ...
├── hooks/                       # 4개 훅
├── plugins/                     # 5개 플러그인
├── knowledge/                   # 지식 시스템
│   ├── wiki/                    # Wiki (T1/T2/T3, 1094+ 페이지)
│   ├── references/              # References (210개)
│   ├── lessons/                 # Lessons (자동 생성)
│   └── news/                    # News (주기 수집)
├── cron/                        # 크론 자동화
│   ├── registry.yaml            # 작업 레지스트리
│   ├── backups/
│   ├── cache/
│   ├── history/
│   └── output/
├── state/                       # 상태 관리
│   ├── hermes/
│   └── openclaw/
├── events/                      # 이벤트 버스
│   └── bus/
├── backups/                     # 백업
│   ├── tier1/                   # Hot (24h)
│   └── tier2/                   # Warm (7d)
└── workspace/                   # 작업 공간
    ├── jobs/                    # 714개 JOB
    ├── projects/                # 7개 프로젝트
    ├── novels/                  # 9개 시리즈
    ├── reports/
    └── research/
```

---

## See Also

- [README.md](README.md) — 시스템 개요, Quick Start
- [PORTING.md](PORTING.md) — 포팅 가이드
- [docs/layer1-core-engine.md](docs/layer1-core-engine.md) — Layer 1 상세
- [docs/layer2-knowledge-state.md](docs/layer2-knowledge-state.md) — Layer 2 상세
- [docs/layer3-integration.md](docs/layer3-integration.md) — Layer 3 상세
- [docs/workflow-pipeline.md](docs/workflow-pipeline.md) — 9단계 파이프라인
- [docs/skill-system.md](docs/skill-system.md) — 스킬 시스템
- [docs/systems/](docs/systems/) — 시스템별 심화 문서
