# p-hermes 도메인별 개요

> **작성일**: 2026-06-16
> **수정**: 배경 도메인 범위 축소, 분량/슬라이드 기준 한국형 전환, Content System 개선 반영
> **목적**: p-hermes 배포 범위 내 모든 도메인의 개요 정의

---

## A. 핵심 시스템 (6개)

실제 운영 흐름에 필수적인 시스템. 코드와 문서(Wiki/Blog/Slides) 모두 포함.

### A1. Workflow (워크플로우)

**역할**: 요청 수신부터 완료까지 9단계로 추적하는 상태 기반 작업 파이프라인.

**핵심 구성**:
- **9단계 상태 머신**: `request` → `investigation` → `design` → `review` → `approval` → `execution` → `test` → `execution_review` → `done`
- **workflow-gate.sh**: 상태 전이 검증, 병렬 실행 차단, 승인 게이트
- **`.workflow-state`**: JOB 폴더 내 JSON 상태 파일, 원자적 갱신 (flock)
- **JOB 관리**: `create-job.sh` 기반 통합 등록, `~/.hermes/workspace/jobs/JOB-XXXX/` 폴더 구조

**사용자가 접하는 흐름**:
1. 작업 요청 → JOB 자동 등록
2. investigation → 설계서 작성 → 리뷰 → 승인 요청
3. 승인된 설계서 기반 실행 → 테스트 → 완료 보고

**관련 코드**: `~/.hermes/scripts/workflow-gate.sh`, `create-job.sh`, `skills/custom/workflow/SKILL.md`

---

### A2. Spec-Driven Dev (사양서 기반 개발)

**역할**: 사양서(Spec)를 단일 진실 출처(SSOT)로 삼아 설계부터 검증까지 구조화하는 개발 방법론.

**핵심 구성**:
- **Spec 구조**: `specs/active/SPEC-XXX.md` — 요구사항, 설계, 검증 항목 포함
- **검증 스크립트**: 7개 검증 도구 (구조, 링크, conformance, triage 등)
- **테스트 자동화**: `--run-tests` 플래그로 검증 파이프라인 실행
- **변경 로그**: `change-log.md` — 모든 수정 이력 추적
- **상태 관리**: `draft` → `review` → `approved` → `active` → `archived`

**강제 규칙**:
- 코드 변경은 Spec 변경으로만 가능 (직접 파일 수정 금지)
- Spec 변경 시 검증 스크립트 자동 실행
- 정량적 주장은 근거 필수

**관련 코드**: `skills/software-development/spec-driven-dev/`, 검증 스크립트 7개

---

### A3. Content System (콘텐츠 시스템)

**역할**: Wiki, Blog, Slides의 콘텐츠 생성과 품질 검증 자동화.

**핵심 구성**:
- **Persona Generator**: 타겟 독자 페르소나 기반 초안 생성
- **Tone Adapter**: 문서 유형별 어조/톤 조정 (D1-D5 레벨)
- **Emotion Merger**: Blog 서사형에만 조건적 적용 (기술 문서 제외)
- **Validator**: 4계층 Anti-Slop 게이트 (L1-L4) + Blog 전용 L5
- **Anti-Slop 라이브러리**: 금지어/패턴 자동 차단 + 부정대조 패턴 검출

**검증 게이트**:
- **L1 Schema**: 문서 구조/메타데이터 검증
- **L2 Error**: 문법/맞춤법/일관성
- **L3 Voice**: 페르소나 매칭, 어조 적합성
- **L4 Domain**: 기술적 정확성, 전문 용어
- **L5 Judge Model**: Blog 전용 최종 심사 (별도 LLM 호출)

**추가 검증 규칙**:
- 부정대조 패턴 자동 감지 (`~대신`, `~아니라`, `~반면`)
- 명칭 통일 검증 (`Expression System` → `Content System`)

**관련 코드**: `skills/custom/content-system/`, `persona_generator.py`, `tone-adapter.py`, `emotion_merger.py`, `validator.py`, `anti-slop-library.json`

---

### A4. Knowledge System (지식 시스템)

**역할**: 다중 소스 지식을 수집·분석·점수화하여 계층적 Wiki로 관리하는 지식 플랫폼.

**핵심 구성**:
- **원본 소스**: 세션 이력, JOB 기록, 뉴스 피드, 리퍼런스 링크
- **Wiki 필링**: `~/.hermes/knowledge/wiki/` — T1/T2/T3 점수 기반 중요도 분류
- **자동 갱신**: `wiki-process-filings.sh` — 5분 간격 cron
- **Scoring**: `build-scores.sh` — 빈도, 최근성, 참조 수 기반
- **검증**: 원본 직접 참조만 허용, 추정 금지, 실제 파일 시스템 검증

**3-Tier 점수 체계**:
- **T1 (핵심)**: 일상적으로 참조, 변경 시 영향대
- **T2 (중요)**: 주기적 참조, 설계/리뷰 시 활용
- **T3 (참고)**: 백업용, 필요 시 검색

**관련 코드**: `wiki-process-filings.sh`, `build-scores.sh`, `knowledge-sync.sh`

---

### A5. Cron/Automation (자동화)

**역할**: 주기적 작업 스케줄링, 이벤트 기반 통신, 자동 실행을 담당하는 자동화 인프라.

**핵심 구성**:
- **3층 구조**:
  - **L1 Scheduler**: `~/.hermes/cron/registry.yaml` — cron 표현식, job 정의, 모델 라우팅
  - **L2 Runtime**: `cronjob` 도구 — job 생성/목록/실행/정지
  - **L3 Delivery**: `send_message` — Telegram, Discord,多渠道 전달
- **이벤트 버스**: `event.sh` — 단일 진입점, JSONL 히스토리, silent-on-success
- **시스템 라이브러리**: `system-common` — mkdir atomic mutex, 공통 유틸리티

**Job 속성**:
- `schedule`: cron 표현식 또는 상대적 간격 (`30m`, `every 2h`)
- `model`: job별 모델 오버라이드
- `enabled_toolsets`: 도구 제한으로 토큰 절감
- `deliver`:多渠道 전달 (`origin`, `all`, `telegram`, `discord`)

**관련 코드**: `~/.hermes/cron/registry.yaml`, `event.sh`, `skills/custom/cron-automation/`

---

### A6. Model Routing (모델 라우팅)

**역할**: 작업 유형에 따라 최적의 LLM을 선택하고, 교차검증으로 품질을 보장하는 라우팅 시스템.

**핵심 구성**:
- **SSOT**: `model-roles.yaml` — 역할별 모델 매핑
- **라우팅 규칙**: prefix 무시 → provider 기반 라우팅 (zai/ → zai, airouter/ → custom:airouter)
- **역할별 할당**:
  - `creative`/`reasoning`: GLM-5.2
  - `coding`/`default`: Qwen3.6
  - `review`: Gemma-4
- **교차검증**: design ↔ review 시 다른 모델 할당

**Catalog**: `~/.hermes/core/skills/custom/model-catalog/catalog.json` — 사용 가능 모델 목록

**관련 코드**: `model-roles.yaml`, `catalog.json`, `skills/custom/model-routing/`

---

## B. 배경 (에르메스 자체)

p-hermes 시스템의 기반이 되는 Hermes Agent 플랫폼에 대한 설명.

### B1. Hermes Agent 개요

**정의**: Nous Research의 오픈소스 AI 에이전트 플랫폼. 사용자의 작업을 autonomously 처리하는 UI/App 계층.

**핵심 기능**:
- **멀티모델 지원**: Anthropic, OpenRouter, Zai, Airrouter 등 다양한 LLM 제공자 통합
- **자동 도구 사용**: Web 검색, 코드 실행, 브라우저, 파일 조작 등 도구 자동 선택/실행
- **지속적 메모리**: SQLite FTS5 기반 사용자 프로필 + 작업 메모리 (세션 간 유지)
- **스킬 시스템**: `~/.hermes/skills/` — 재사용 가능한 절차적 지식
- **크론/자동화**: 주기적 job 스케줄링, 이벤트 기반 반응
- **多渠道 연동**: Telegram, Discord, Matrix等平台 메시지 송수신
- **서브에이전트**: 작업 분할 및 병렬 처리 (delegate_task)

**설정 구조**:
- `config.yaml`: 모델, provider, 도구, 스킬 등 전역 설정
- `AGENTS.md`: 작업 규칙, 프로세스 강제, 프로젝트 관리
- 프로파일 시스템: `~/.hermes/profiles/<name>/` — 격리된 환경

---

### B2. 아키텍처

**설계 원칙** (JOB-1626):
1. **심링크 금지**: 직접 파일 링크 대신 복사/동기화
2. **$HERMES_ROOT 추상화**: 절대경로 금지, 환경변수 기반 경로
3. **이벤트 기반 통신**: 직접 스크립트 호출 금지, 상태 파일 비동기
4. **5-Tier 구조**: `core` → `runtime` → `interfaces` → `infra` → `release`

**5-Tier 설명**:
| 계층 | 역할 | 예시 |
|------|------|------|
| **Core** | 핵심 도구, 설정, 스킬 | config.yaml, skills/, AGENTS.md |
| **Runtime** | 실행 환경, 메모리, 상태 | cron/, memory/, state/ |
| **Interfaces** | 사용자 인터랙션 | Telegram, Discord, CLI |
| **Infra** | 외부 서비스 연동 | GitHub, OpenRouter, ComfyUI |
| **Release** | 배포, 빌드, 패키징 | p-hermes, GitHub Pages |

**이벤트 버스** (JOB-1568/1594):
- `event.sh` 단일 진입점 — 모든 시스템 이벤트 통지
- `system-common` 라이브러리 — 원자적 디렉토리 생성, mutex
- JSONL 히스토리 — 이벤트 감사 추적
- silent-on-success — 실패 시에만 알림

---

## C. 도메인별 문서 매핑

| 도메인 | Wiki | Blog | Slides |
|--------|------|------|--------|
| A1. Workflow | 가이드: 요청 흐름 | Blog: 9단계 철학 | Slides: 워크플로우 파이프라인 |
| A2. Spec-Driven Dev | 가이드: Spec 작성 | Blog: 구조적 강제 | Slides: Spec 기반 개발 |
| A3. Content System | 가이드: 콘텐츠 생성 | Blog: 파이프라인 설계 | Slides: 콘텐츠 검증 |
| A4. Knowledge System | 가이드: 지식 검색 | Blog: 지식 설계 | Slides: 지식 시스템 |
| A5. Cron/Automation | 가이드: 자동화 | Blog: 3층 분리 | Slides: cron 시스템 |
| A6. Model Routing | 가이드: 모델 선택 | Blog: 라우팅 설계 | Slides: 모델 라우팅 |
| B1. Hermes 개요 | Wiki: 시작하기 | Blog: Hermes 소개 | Slides: 시스템 개요 |
| B2. 아키텍처 | Wiki: 구조 | Blog: 5-Tier 설계 | Slides: 아키텍처 |

---

## D. 배포 범위 요약

**포함**:
- 핵심 시스템 6개 (코드 + Wiki + Blog + Slides)
- 에르메스 배경 2개 (Wiki + Blog + Slides)

**제외**:
- Hermes 내장 기능 (Messaging, Skills 사용법 등)
- 비활성화 시스템 (Dual Agent Bridge)
- 도메인 시스템 (Project Management — 실제 사용 안함)
- 백업/복원 (Hermes 내장)
- 교훈/레슨 문서 (비핵심)
- 설정 관리 (B3 — Wiki/Blog만 별도 문서화 필요시)
- 세션 관리 (B4 — Wiki/Blog만 별도 문서화 필요시)
