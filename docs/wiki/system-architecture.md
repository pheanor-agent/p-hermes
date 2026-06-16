# p-hermes 시스템 아키텍처

## 1. 전체 개요

p-hermes는 AI 기반 자율 에이전트 시스템으로, 설계-검증-실행-회고의 완전한 워크플로우를 제공합니다.

### 핵심 원칙
- **Spec-Driven Development**: 모든 작업은 사양서가 SSOT입니다
- **5-Tier 아키텍처**: Core → Runtime → Interfaces → Infra → Release
- **이벤트 기반 통신**: 직접 스크립트 호출 금지, 상태 파일 비동기
- **심링크 금지**: 물리적 파일만 사용

---

## 2. 5-Tier 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                    Tier 1: Core                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ workflow.sh │  │ spec-driven │  │ expression  │         │
│  │   (9-step)  │  │  dev (14)   │  │   system    │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│                    Tier 2: Runtime                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ knowledge   │  │ cron        │  │   skills    │         │
│  │   system    │  │  (144)      │  │   (84)      │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│                 Tier 3: Interfaces                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Discord   │  │  Telegram   │  │     CLI     │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│                   Tier 4: Infra                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   GitHub    │  │   Docker    │  │   WSL/Host  │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│                 Tier 5: Release                           │
│  ┌─────────────┐  ┌─────────────┐                         │
│  │  GitHub     │  │   Local     │                         │
│  │  Pages      │  │  Snapshot   │                         │
│  └─────────────┘  └─────────────┘                         │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. 핵심 시스템 상세

### 3.1 워크플로우 (Workflow)
- **9-Step State Machine**: request → investigation → design → review → approval → execution → test → execution_review → done
- **상태 파일**: `~/.hermes/workspace/jobs/JOB-XXXX/.workflow-state`
- **검증**: `workflow-gate.sh`, `validate-workflow.sh`

### 3.2 Spec-Driven Development
- **명령**: `spec-create.sh`, `spec-status.sh`, `spec-conformance.sh`
- **검증**: `spec-drift.sh`, `spec-rollback.sh`
- **Matrix**: `specs/_matrix.json`

### 3.3 Content System
- **엔진**: `tier-generator.py`, `tone-adapter.py`, `validator.py`
- **템플릿**: 교육, 내러티브, 시각, 프레젠테이션, 이미지
- **검증**: `anti-slop-library.json`

### 3.4 지식 시스템
- **입력**: 원본 직접 참조만
- **출력**: 가공된 데이터만
- **Scoring**: `build-scores.sh`

### 3.5 Cron/자동화
- **Registry**: `cron/registry.yaml`
- **실행**: `cron-wrapper.sh`, `cron-runner-*`
- **이벤트**: `event.sh`

---

## 4. 파일 구조

```
p-hermes/
├── core/                    # 코어 라이브러리
│   ├── lib/                 # workflow.sh, atomic.sh 등
│   ├── scripts/             # 운영 스크립트 (144개)
│   └── skills/              # 스킬 (84개)
├── docs/                    # 문서 (Wiki/Blog/Slides)
├── specs/                   # Spec-Driven Dev
├── infra/                   # 인프라 설정
└── tests/                   # 검증 스크립트
```

---

## 5. 배포 전략

### Tier 1 (Core) - 핵심 워크플로우
- ✅ `workflow.sh`
- ✅ `workflow-gate.sh`
- ✅ `create-job.sh`
- ✅ `spec-*.sh` (14개)
- ❌ `cron-wrapper.sh` (추가 필요)

### Tier 2 (Runtime) - 핵심 시스템
- ✅ `knowledge-sync.sh`
- ✅ `notify.sh`
- ✅ `atomic_write.sh`
- ❌ `expression-system` (추가 필요)

### Tier 3-5 (Interfaces/Infra/Release)
- ✅ GitHub Pages (HTTP 200)
- ✅ Discord/Telegram 연동
- ✅ WSL/Host 환경

---

## 6. 누락된 핵심 코드

| 항목 | 상태 | 설명 |
|------|------|------|
| Content System | ❌ | engine/, templates/, tests/ 전체 |
| Custom Skills | ❌ | workflow, knowledge, cron 등 26개 |
| 운영 스크립트 | ❌ | health-check, knowledge-process 등 125개 |

---

## 7. 추가 계획

### Phase 1: 핵심 시스템
1. Content System engine 전체 추가
2. Custom skills 중 핵심 10개 추가
3. 운영 스크립트 중 핵심 20개 추가

### Phase 2: 완전 통합
1. 누락된 운영 스크립트 모두 추가
2. Custom skills 전체 동기화
3. 검증 스크립트 확장

---

마지막 업데이트: 2026-06-16
