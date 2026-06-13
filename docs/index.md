# Wiki Index — Hermes Agent Documentation

Hermes Agent 시스템의 상세 참조 문서 인덱스입니다.

---

## 계층별 문서 (Architecture Layers)

| # | 문서 | 설명 |
|---|------|------|
| 1 | [Layer 1: Core Engine](layer1-core-engine.md) | 모델/프로바이더, 스킬 시스템, 워크플로우 파이프라인 |
| 2 | [Layer 2: Knowledge & State](layer2-knowledge-state.md) | 지식 시스템, 크론 자동화, 블랙보드/브리지 |
| 3 | [Layer 3: Integration](layer3-integration.md) | 메시징, 이미지 생성, 콘텐츠 제작 |

---

## 파이프라인 & 시스템

| # | 문서 | 설명 |
|---|------|------|
| 1 | [9단계 워크플로우 파이프라인](workflow-pipeline.md) | 상태 머신, 체크포인트, 자동 전이 |
| 2 | [스킬 시스템](skill-system.md) | 144+ 스킬, 카테고리, 트리거, 상속 |

---

## 시스템별 심화 (Systems Deep-Dive)

| # | 문서 | 설명 |
|---|------|------|
| 1 | [시스템 종합](systems/overview.md) | 9개 시스템 구조 및 연계 |
| 2 | [모델 시스템](systems/models.md) | 다중 프로바이더, 라우팅, Fallback |
| 3 | [지식 시스템](systems/knowledge.md) | Wiki T1/T2/T3, References, Lessons, News |
| 4 | [크론 시스템](systems/cron.md) | 주기 작업, no-agent 모드, 레지스트리 |
| 5 | [백업 시스템](systems/backup.md) | Tier 1/2, 사전 백업, 복구 |
| 6 | [배포 시스템](systems/deploy.md) | ComfyUI, GPU Health, Pod 관리 |

---

## 빠른 탐색

### 워크플로우 관련
- [ARCHITECTURE.md](../ARCHITECTURE.md) — 전체 아키텍처
- [docs/workflow-pipeline.md](workflow-pipeline.md) — 9단계 파이프라인
- [docs/systems/overview.md](systems/overview.md) — JOB 시스템

### 모델 관련
- [docs/layer1-core-engine.md](layer1-core-engine.md) — Model & Provider
- [docs/systems/models.md](systems/models.md) — 모델 라우팅 상세

### 지식 관련
- [docs/layer2-knowledge-state.md](layer2-knowledge-state.md) — Knowledge System
- [docs/systems/knowledge.md](systems/knowledge.md) — Wiki/References/Lessons

### 자동화 관련
- [docs/layer2-knowledge-state.md](layer2-knowledge-state.md) — Cron & Automation
- [docs/systems/cron.md](systems/cron.md) — 크론 시스템 상세

### 연동 관련
- [docs/layer3-integration.md](layer3-integration.md) — Integration & Output
- [docs/systems/deploy.md](systems/deploy.md) — 배포 시스템

---

## 문서 네비게이션

```
p-hermes/
├── README.md                         # 메인 — 시스템 개요
├── ARCHITECTURE.md                   # 전체 아키텍처
├── PORTING.md                        # 포팅 가이드
├── CHANGELOG.md                      # 변경 로그
├── LICENSE                           # MIT License
│
└── docs/                             # Wiki (상세 참조)
    ├── index.md                      # 이 파일
    ├── layer1-core-engine.md         # Layer 1
    ├── layer2-knowledge-state.md     # Layer 2
    ├── layer3-integration.md         # Layer 3
    ├── workflow-pipeline.md          # 워크플로우
    ├── skill-system.md               # 스킬
    └── systems/                      # 시스템별 심화
        ├── overview.md
        ├── models.md
        ├── knowledge.md
        ├── cron.md
        ├── backup.md
        └── deploy.md
```
