# 5-Tier 물리 계층화 설계

> 태그: #architecture #filesystem
> 읽는 시간: ~10분

---

## TL;DR

파일 시스템의 구조는 소프트웨어 아키텍처를 반영해야 합니다. Hermes는 초기의 단일 폴더 구조에서 벗어나, **5-Tier(core, runtime, interfaces, infra, release)**로 물리적으로 계층화했습니다. 이는 각 도메인의 데이터가 서로에게 해를 끼치지 않도록 격리하기 위한 설계입니다.

```
┌─────────────────────────────────────────────────────┐
│              5-Tier 물리 계층 구조                    │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ~/.hermes/                                        │
│  ├── core/          # 정적 설정 (스크립트, 스킬)    │
│  ├── runtime/       # 동적 상태 (세션, 상태 파일)   │
│  ├── interfaces/    # 휘발성 데이터 (연결 상태)     │
│  ├── infra/         # 상태 관리 (크론, 백업)       │
│  └── release/       # 선택적 배포 (wiki, 블로그)   │
│  └── knowledge/     # 지식 시스템 (Wiki DB)         │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 배경: "спа게티 폴더" 문제

### 초기 버전의 구조

2025년 초, Hermes 시스템은 모든 파일을 단일 레벨에 평탄하게 배치했습니다.

```
~/.hermes/
├── scripts/
│   ├── backup.sh
│   ├── healthcheck.sh
│   ├── knowledge-sync.sh
│   └── session-cleanup.sh
├── cron/
│   ├── registry.yaml
│   └── jobs/
├── knowledge/
│   ├── wiki/
│   ├── references/
│   └── news/
├── backups/
│   ├── 2025-01/
│   ├── 2025-02/
│   └── 2025-03/
├── state/
│   ├── sessions.db
│   └── job-state.json
└── config.yaml
```

**3가지 치명적 문제**:

### 1. 의존성 순환 (Circular Dependency)

```
크론 스크립트 → 지식 파일 읽기 → 지식 파이프라인 → 스크립트 호출 → 크론 스크립트
```

**문제**: 크론 스크립트가 지식 파일을 읽고, 지식 파이프라인이 다시 스크립트를 호출하는 순환 참조 발생

**실제 사고**: 2025-10-15
- `knowledge-sync.sh`가 `healthcheck.sh` 호출
- `healthcheck.sh`가 다시 `knowledge-sync.sh` 호출
- 결과: 무한 루프 → CPU 100% → 시스템 먹통

### 2. 데이터 오염 (Data Corruption)

```
~/.hermes/scripts/
├── backup.sh          # 정적 스크립트
├── backup.log         # 동적 로그 파일
├── backup.tmp         # 임시 파일
└── backup.cache       # 캐시 파일
```

**문제**: 정적 설정 파일과 동적 실행 파일이 같은 폴더에 위치 → 실수로 `rm -rf *.tmp` 실행 시 스크립트 파일도 삭제됨

**실제 사고**: 2026-01-20
- `cleanup.sh`가 `*.tmp` 파일 삭제
- `backup.tmp`과 `backup.sh.tmp` 모두 삭제
- 결과: 백업 스크립트 손실, 2시간 복구 작업

### 3. 배포/복제 어려움 (Deployment Difficulty)

**문제**: 시스템을 다른 서버로 옮기려고 할 때, "어떤 파일만 복사하면 되는지" 불명확

**실제 경험**: 2025-12-01
- 전체 폴더 복사 → 50GB (불필요한 백업 데이터 포함)
- 시간: 45분
- 결과: 배포 실패 → 불필요한 데이터로 인한 설정 충돌

---

## 설계 결정: 5-Tier 구조

Hermes는 파일 시스템의 **성격**에 따라 5개의 계층(Tier)으로 물리적으로 분리했습니다.

### 1. `core/` (정적 설정)

**역할**: 소프트웨어의 영혼. 변경되지 않는 설정과 로직.

**폴더 구조**:
```
core/
├── scripts/          # 스크립트 라이브러리
│   ├── create-job.sh
│   ├── workflow-gate.sh
│   ├── wiki-sync.sh
│   └── pre-delete-backup.sh
└── skills/           # 내장 스킬
    ├── software-development/
    ├── data-science/
    └── creative/
```

**핵심 특징**:
- 읽기 전용 (Read-Only)
- 배포 시 포함 (Git Repository)
- 환경 독립적 (OS/Path 추상화)

### 2. `runtime/` (동적 상태)

**역할**: 에이전트의 현재 기억과 컨텍스트.

**폴더 구조**:
```
runtime/
├── state/            # 상태 파일
│   ├── JOB-1001-state.json
│   ├── cron-status.json
│   └── event-history.jsonl
├── workspace/        # 작업 폴더
│   ├── jobs/
│   ├── projects/
│   └── reports/
└── session/          # 세션 데이터
    ├── current-session.json
    └── context-cache/
```

**핵심 특징**:
- 쓰기 전용 (Write-Only)
- 배포 시 제외 (Gitignore)
- 환경 종속적 (Path/OS 관련)

### 3. `interfaces/` (휘발성 인터페이스)

**역할**: 외부 플랫폼(Discord, Telegram)과의 교신 채널.

**폴더 구조**:
```
interfaces/
├── discord/          # Discord 연동
│   ├── channels/
│   └── webhooks/
├── telegram/         # Telegram 연동
│   ├── chats/
│   └── bots/
└── status/           # 연결 상태
    ├── discord.json
    └── telegram.json
```

**핵심 특징**:
- 휘발성 (Ephemeral)
- 실시간 업데이트
- 배포 시 제외 (보안 관련)

### 4. `infra/` (지속적 상태)

**역할**: 시스템의 장기 기억과 주기 작업.

**폴더 구조**:
```
infra/
├── cron/             # 크론 작업
│   ├── registry.yaml
│   └── jobs/
├── backups/          # 백업 데이터
│   ├── 2026-01/
│   ├── 2026-02/
│   └── 2026-03/
└── knowledge/        # 지식 시스템 (Wiki DB)
    ├── wiki/
    ├── references/
    └── news/
```

**핵심 특징**:
- 지속적 (Persistent)
- 주기적 갱신
- 배포 시 선택적 포함 (크론 레지스트리 제외 백업)

### 5. `release/` (배포/선택적)

**역할**: 외부에 노출되거나 배포될 데이터.

**폴더 구조**:
```
release/
├── wiki/             # Wiki 문서
│   ├── getting-started/
│   ├── guides/
│   └── tutorials/
├── blog/             # Dev Blog
│   ├── posts/
│   └── index.md
├── slides/           # 슬라이드 덱
│   └── decks/
└── llms.txt          # LLM 참조용 문서
```

**핵심 특징**:
- 읽기 전용
- 배포 시 포함 (GitHub Pages)
- 버전 관리 (Git)

### 6. `knowledge/` (지식 시스템)

**역할**: 에이전트의 지식 베이스 (Wiki DB)

**폴더 구조**:
```
knowledge/
├── wiki/             # Wiki DB
│   ├── system/
│   ├── dev/
│   ├── custom/
│   └── knowledge/
├── references/       # 외부 리퍼런스
│   ├── github/
│   ├── blog/
│   └── documentation/
└── news/             # 뉴스 피드
    ├── ai/
    └── technology/
```

**핵심 특징**:
- 가공 파이프라인 경유
- FTS5 검색 지원
- 도메인/태그 기반 분류

---

## 다른 대안과의 비교

| 대안 | 문제점 | 5-Tier 해결책 |
|------|--------|---------------|
| **심링크(Symlink) 사용** | LLM의 파일 탐색 효율 급격히 저하 | 물리적 격리로 탐색 경로 단축 |
| **동일 폴더 유지** | 데이터 오염 및 의존성 폭발 | 도메인별 폴더 격리 |
| **절대 경로 사용** | 환경(Win/Linux)에 따라 파손됨 | `$HERMES_ROOT` 추상화 (JOB-1626) |

---

## 실제 운영 사례

### 성공 사례: 배포 시간 단축

**이전**: 50GB 전체 복사 → 45분
**이후**: `core/` + `release/`만 복사 → 5분
**개선**: 90% 시간 단축

### 실패 사례: 심링크 폭주 (JOB-1626)

**문제**:
- 두 에이전트(Hermes와 OpenClaw)의 파일 동기화를 위해 심링크 광범위하게 사용
- LLM의 파일 탐색 효율 급격히 저하
- "파일은 있는데 왜 못 읽어?" 오류 빈번

**해결**:
- **물리적 격리 원칙 도입**
- 심링크 금지 (Absolute Ban)
- 상태 파일과 이벤트 기반으로 비동기 동기화

---

## 관련 포스트

- [이벤트 기반 도메인 통신](./event-driven-communication.md)
- [초기 설계: 워커 vs 오케스트레이터 분리의 교훈](./dual-agent-design.md)

---

_5-Tier 구조는 시스템의 신뢰성을 확보하는 핵심 설계입니다. 각 Tier는 서로 독립적으로 운영되며, 배포 시 포함 여부를 명확히 정의합니다._
