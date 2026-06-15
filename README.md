# ⚡ p-hermes: The Orchestrated Intelligence Agent

p-hermes는 고도의 자율성을 가진 AI 에이전트 시스템으로, 복잡한 작업을 설계-검증-실행-회고하는 **Spec-Driven Development** 파이프라인을 통해 신뢰할 수 있는 결과물을 생산합니다.

단순한 챗봇을 넘어, 시스템 아키텍처를 이해하고 스스로 도구를 확장하며, 엄격한 워크플로우를 통해 오류를 최소화하는 **엔지니어링 에이전트**를 지향합니다.

---

## 🚀 시작하기 (Quick Start)

처음 오셨나요? 아래의 온보딩 경로를 따라 Hermes의 능력을 빠르게 경험해 보세요.

### 1. 온보딩 가이드
- **[설치 및 환경 설정](./wiki/getting-started/install.md)**: Hermes를 로컬/서버에 구축하고 기본 설정을 마칩니다.
- **[첫 번째 작업 요청하기](./wiki/getting-started/first-job.md)**: `[JOB-XXXX]` 형식을 사용하여 에이전트에게 복잡한 작업을 맡기는 법을 배웁니다.
- **[기본 설정 가이드](./wiki/getting-started/configuration.md)**: 모델 라우팅 및 기본 인터페이스를 최적화합니다.

### 2. 핵심 기능 활용 (Guides)
- **[작업 요청 및 워크플로우](./wiki/guides/request-task.md)**: 9단계 상태머신 기반의 작업 처리 프로세스를 이해합니다.
- **[스킬 시스템 활용](./wiki/guides/use-skills.md)**: 78개 이상의 내장 스킬을 활용하고 나만의 스킬을 추가하는 법을 배웁니다.
- **[지식 시스템 검색](./wiki/guides/knowledge-search.md)**: 도메인 기반으로 구조화된 지식을 효율적으로 검색하고 활용합니다.
- **[자동화(Cron) 설정](./wiki/guides/automation.md)**: 주기적인 리포트와 시스템 모니터링을 자동화합니다.

---

## 🛠️ 탐색 가이드 (3-트랙 문서화)

원하시는 목적에 따라 최적화된 문서 트랙을 선택하세요.

| 목적 | 추천 트랙 | 특징 | 바로가기 |
|---|---|---|---|
| **"어떻게 쓰는가?"** | **Guide Wiki** | 온보딩, 기능 가이드, 튜토리얼, FAQ | [📖 Wiki Index](./wiki/index.md) |
| **"왜 그렇게 설계했나?"** | **Dev Blog** | 기술 결정 사유, 아키텍처 심층 분석, 교훈 | [✍️ Blog Index](./blog/index.md) |
| **"무엇인가 한눈에?"** | **Slides** | 시스템 구조 시각화, 컨셉 강의 덱 | [🖼️ Slides Index](https://pheanor-agent.github.io/p-hermes/slides/) |

---

## 🏗️ 시스템 핵심 스펙
- **아키텍처**: 5-Tier 물리 계층화 (Core $\rightarrow$ Runtime $\rightarrow$ Interfaces $\rightarrow$ Infra $\rightarrow$ Release)
- **핵심 메커니즘**: 9-Step Workflow State Machine, Spec-Driven Development
- **기능 규모**: 78+ Active Skills, Domain-based Knowledge Base
- **인터페이스**: Discord, Telegram, Local CLI
