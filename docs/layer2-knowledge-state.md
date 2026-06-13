# Layer 2: Knowledge & State (지식 및 상태 관리)

Hermes Agent의 지식 축적, 자동화, 협업 상태 관리 계층입니다.

---

## 구성 요소

| 구성 요소 | 역할 | SSOT |
|-----------|------|------|
| **Knowledge System** | Wiki, References, Lessons, News | `wiki/index.md` |
| **Cron & Automation** | 주기 작업 관리, no-agent 모드 | `registry.yaml` |
| **Blackboard & Bridge** | 듀얼 에이전트 협업, 상태 공유 | `state/` |

---

## 1. Knowledge System

### 1.1 구조

```
~/.hermes/knowledge/
├── wiki/                    # 가공 지식 (1094+ 페이지)
│   ├── index.md             # 인덱스 (SSOT)
│   ├── t1/                  # 핵심 지식 (KPL ≥ 0.7)
│   ├── t2/                  # 참고 지식 (KPL 0.4~0.69)
│   └── t3/                  # 보조 지식 (KPL < 0.4)
├── references/              # 외부 원본 (210개)
│   ├── github/              # GitHub 리포/이슈
│   ├── papers/              # 학술 논문
│   └── guides/              # 공식 가이드
├── lessons/                 # 교훈 (JOB 완료 후 자동 생성)
└── news/                    # 뉴스 (주기 수집/번역)
```

### 1.2 T1/T2/T3 분류

KPL (Knowledge Priority Level) 점수에 따라 중요도가 분류됩니다.

| 등급 | KPL 점수 | 설명 | 사용 시기 |
|------|----------|------|----------|
| **T1** | ≥ 0.7 | 핵심 지식 | 모든 작업 시 반드시 참조 |
| **T2** | 0.4 ~ 0.69 | 참고 지식 | 관련 작업 시 참조 |
| **T3** | < 0.4 | 보조 지식 | 필요 시 검색 |

**KPL 점수 계산 요소:**
- 참조 빈도
- 최근 사용 시점
- 교훈 레벨 (JOB 완료 시점)
- 관련성 점수

### 1.3 갱신 파이프라인

```
Signal Detector → inbox/ → wiki-process-filings.sh → wiki/ (T1/T2/T3 분류)
                     ↑              (5분 간격)               ↓
                news 수집                              build-scores.sh
                                                        (KPL 재계산)
```

| 스크립트 | 간격 | 역할 |
|---------|------|------|
| `wiki-process-filings.sh` | 5분 | inbox → wiki 분류 |
| `build-scores.sh` | 주기적 | KPL 점수 계산 |
| `daily-knowledge.sh` | 일일 | 뉴스 수집 + 번역 |

### 1.4 Lessons (교훈 시스템)

JOB 완료 시 `on-job-complete.sh`가 자동으로 교훈을 생성합니다:

```
JOB 완료
  → on-job-complete.sh 실행
    → 작업 내용 분석
    → 교훈 추출
    → lessons/ 디렉토리에 저장
    → wiki/index.md 업데이트
```

---

## 2. Cron & Automation

### 2.1 레지스트리 구조

`registry.yaml`이 모든 주기 작업의 단 하나의 진실원 (SSOT)입니다.

```yaml
# cron/registry.yaml 예시
jobs:
  - name: "wiki-process"
    schedule: "*/30 * * * *"      # 30분마다
    mode: no-agent               # 스크립트 전용
    script: "wiki-process-filings.sh"
    output: "cron/output/wiki/"

  - name: "knowledge-daily"
    schedule: "0 9 * * *"        # 매일 09:00
    mode: agent                  # LLM 기반
    description: "일일 지식 파이프라인"

  - name: "event-cleanup"
    schedule: "0 0 * * 0"        # 매주 일요일 00:00
    mode: no-agent
    script: "cleanup-event-archive.sh"
```

### 2.2 실행 모드

| 모드 | 설명 | LLM 필요 |
|------|------|----------|
| **no-agent** | 스크립트 전용 실행 | ❌ |
| **agent** | LLM 기반 판단 + 실행 | ✅ |

### 2.3 주기 패턴

| 주기 | cron 표현식 | 예시 작업 |
|------|-------------|-----------|
| 30분 | `*/30 * * * *` | 시스템 상태 확인 |
| 1시간 | `0 * * * *` | 캐시 정리 |
| 2시간 | `0 */2 * * *` | 지식 스캔 |
| 일일 | `0 9 * * *` | 지식 파이프라인 |
| 주일 | `0 0 * * 0` | 이벤트 정리 |

### 2.4 이력 관리

`cron/history/`에 실행 로그가 저장됩니다:

```
cron/history/
├── wiki-process/
│   ├── 2026-06-13-0900.log
│   └── 2026-06-13-0930.log
├── knowledge-daily/
│   └── 2026-06-13-0900.log
└── ...
```

---

## 3. Blackboard & Bridge

### 3.1 듀얼 에이전트 협업

Hermes와 OpenClaw가 파일 시스템을 통해 협업합니다.

```
┌─────────────┐         ┌─────────────┐
│  Hermes     │         │  OpenClaw   │
│             │         │             │
│  state/     │◄────────│  state/     │
│  hermes/    │  상태   │  openclaw/  │
│             │  공유   │             │
│  jobs/      │         │  jobs/      │
└─────────────┘         └─────────────┘
         ▲                        ▲
         │         Bridge API     │
         └─────────── 이벤트 ──────┘
```

### 3.2 Blackboard (상태 공유)

`~/.hermes/state/` 디렉토리가 상태 공유의 단 하나의 진실원입니다.

```
~/.hermes/state/
├── hermes/              # Hermes 상태 파일
│   ├── active-jobs.json
│   └── config-cache.json
└── openclaw/            # OpenClaw 상태 파일
    └── ...
```

### 3.3 Bridge API

에이전트 간 통신을 위한 파일 기반 API입니다:
- 이벤트 발행/구독 (event bus 연동)
- 상태 변경 알림
- 작업 대역폭 조정

### 3.4 JOB 관리

통합 JOB 번호 체계로 양쪽 에이전트의 작업을 추적합니다:
- `JOB-XXXX` 형식 (순차 번호)
- `.workflow-state` 파일 공유
- 완료 시 상호 알림

---

## 계층 간 인터페이스

### Layer 2 → Layer 1

| 인터페이스 | 설명 |
|-----------|------|
| 지식 조회 | 스킬/워크플로우에서 Wiki T1 읽기 |
| 상태 구독 | 이벤트 버스 → 모델 라우팅 영향 |

### Layer 2 → Layer 3

| 인터페이스 | 설명 |
|-----------|------|
| 메시지 알림 | Cron 완료 → Telegram/Discord 알림 |
| 콘텐츠 데이터 | 뉴스/레퍼런스 → 콘텐츠 생성 원천 |

---

## 참조

- [ARCHITECTURE.md](../ARCHITECTURE.md) — 전체 아키텍처
- [docs/systems/knowledge.md](systems/knowledge.md) — 지식 시스템 심화
- [docs/systems/cron.md](systems/cron.md) — 크론 시스템 심화
