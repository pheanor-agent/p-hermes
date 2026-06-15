---
name: system-event-bus
description: "무데몬 이벤트 버스 아키텍처 — POSIX 원자성 기반, 상관 ID 추적, 3단계 폴백. 작업/크론/헬스/지식/모니터링 통합."
version: 1.0.0
---

# system-event-bus

모든 시스템 간 비동기 이벤트 교환을 위한 무데몬(Daemonless) 이벤트 버스.

## 트리거

- 이벤트 버스 연동이 필요한 새 스크립트 개발 시
- 기존 스크립트에 이벤트 발행 추가 시
- 이벤트 버스 디버깅 시 (stale lock, 중복 이벤트, cross-FS 문제)
- 시스템 연계 아키텍처 변경 시

## 핵심 개념

### 아키텍처

```
┌──────────┐    wf.*            ┌──────────┐
│ Workflow │ ─────────────────► │  Events  │
│  (Core)  │                    │  Bus     │
└──────────┘                    └────┬─────┘
                                     │
┌──────────┐    cron.*              │    ┌──────────┐
│  Cron    │ ───────────────────────┼────┤  Worker  │
│(Trigger) │                        │    │ (Lock)   │
└──────────┘                        │    └──────────┘
                                     │
┌──────────┐    knowledge.*         │    ┌──────────┐
│ Knowledge│ ────────────────────────┼────┤ Monitor  │
│(Sink)    │                         │    └──────────┘
└──────────┘                         │
                                     │
                             ┌───────┴───────┐
                             │  Bus/ (Queue) │
                             └───────────────┘
```

**방향성**: Cron(Trigger) → Workflow(Core) → Knowledge/Backup/Health(Sink)
**원칙**: 단방향 흐름만 허용. 순환 의존성 원천 차단.

### 파일 시스템 프리미티브

| 연산 | 역할 | 원자성 |
|------|------|--------|
| `mkdir` | 뮤텍스 (워커 락) | ✅ 커널 레벨 동시성 배제 |
| `mv -n` | 원자 큐 (동일 FS) | ✅ POSIX 원자 이동 |
| `cp + mv` | 폴백 (cross-FS) | ⚠️ 비원자적이지만 유일한 옵션 |

### 이벤트 타입

| Prefix | 발행자 | 의미 |
|--------|--------|------|
| `wf.started` | workflow-gate.sh | JOB 시작 |
| `wf.state_changed` | workflow-gate.sh | 상태 전이 |
| `wf.completed` | workflow-gate.sh | JOB 완료 |
| `cron.completed` | cron-wrapper.sh | Cron job 완료 |
| `cron.failed` | cron-wrapper.sh | Cron job 실패 |
| `cron.warning` | cron-wrapper.sh | Cron job 경고 |
| `health.ok` | hermes-health-monitor.sh | 건강 체크 정상 |
| `health.alert` | hermes-health-monitor.sh | 건강 체크 실패 |
| `knowledge.indexed` | daily-knowledge-process.sh | 지식 인덱싱 완료 |
| `monitor.verify` | verify.sh | 시스템 검증 완료 |

### 상관 ID

각 발행자는 고유 상관 ID를 생성하여 추적성 보장.

| 발행자 | 포맷 |
|--------|------|
| workflow-gate.sh | `WF-YYYYMMDD-HHMM-PID` |
| cron-wrapper.sh | `CRON-YYYYMMDD-HHMM-PID` |
| health-monitor.sh | `HEALTH-YYYYMMDD-HHMM-PID` |
| knowledge-process.sh | `KS-YYYYMMDD-HHMM-PID` |
| verify.sh | `VR-YYYYMMDD-HHMM-PID` |

## 구현 방법

### 1. 스크립트에 이벤트 버스 연동

```bash
# 스크립트 상단에 추가
source "$HOME/.hermes/skills/shared/system-common/lib/event.sh" 2>/dev/null || true
source "$HOME/.hermes/skills/shared/system-common/lib/log.sh" 2>/dev/null || true

# 상관 ID 생성 (발행자별 포맷 준수)
CORRELATION_ID="PREFIX-$(date +%Y%m%d-%H%M)-$$"
export CORRELATION_ID

# ... 작업 실행 ...

# 이벤트 발행
if declare -f emit_event &>/dev/null; then
    emit_event "prefix.event_type" "$CORRELATION_ID" '{"key": "value"}' 2>/dev/null || true
fi
```

### 2. 워커 구현 (이벤트 소비)

```bash
source "$HOME/.hermes/skills/shared/system-common/lib/event.sh"

# 이벤트 클레임 (경쟁 획득)
for event_file in $(pending_events); do
    if claim_event "my-worker" "$event_file"; then
        # 이벤트 처리
        # ...
        
        # 처리 완료 후 아카이브
        archive_event "my-worker" "$event_file"
    fi
done

# stale 락 정리 (정기 실행)
cleanup_stale_locks
```

### 3. 환경변수 구성

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `HERMES_EVENTS_DIR` | `~/.hermes/events` | 이벤트 버스 루트 |
| `HERMES_LOCK_TTL_MIN` | `30` | 워커 락 TTL (분) |

## 디렉토리 구조

```
~/.hermes/events/
├── bus/           # 발행된 이벤트 큐 (*.json)
├── workers/       # 워커 락 영역
│   └── {worker}/  # 워커별 작업 영역
│       └── {event}.lock  # 락 디렉토리
└── archive/       # 처리 완료 아카이브
```

## 연동된 스크립트

| 스크립트 | 이벤트 타입 |
|---------|------------|
| `~/.hermes/scripts/workflow-gate.sh` | `wf.started`, `wf.state_changed`, `wf.completed` |
| `~/.hermes/cron/cron-wrapper.sh` | `cron.completed`, `cron.failed`, `cron.warning` |
| `~/.hermes/scripts/hermes-health-monitor.sh` | `health.ok`, `health.alert` |
| `~/.hermes/scripts/daily-knowledge-process.sh` | `knowledge.indexed` |
| `~/.hermes/scripts/verify.sh` | `monitor.verify` |

## Pitfalls

### mv -n cross-filesystem 문제

`/tmp` (tmpfs) → `~/.hermes/events/bus/` (ext4) 간 `mv -n` 실패.
- **해결**: event.sh 내장 3단계 폴백 (mv -n → install -b → cp + mv)
- **주의**: cross-FS 시 원자성 불가. 동일 FS 유지 권장 (BUS_DIR을 tmpfs가 아닌 곳에 설정)

### stale lock 누積

워커가 비정상 종료 시 락 디렉토리 남음.
- **해결**: `cleanup_stale_locks()` 정기 실행 (crontab 또는 health-monitor --monitor)
- **TTL**: `HERMES_LOCK_TTL_MIN` 환경변수로 조정 (기본 30분)

### 이벤트 중복 발행

동일 상관 ID + 이벤트 타입 조합 시 `mv -n`으로 중복 방지.
- **주의**: 상관 ID 생성 로직이 동일 PID + 타임스탬프 사용 시 분 단위 중복 가능
- **해결**: PID 포함하여 고유성 보장

### emit_event 실패 무시

`2>/dev/null || true` 패턴으로 실패 시 스크립트 중단 방지.
- **주의**: 이벤트 발행 실패가 본 작업 실패와 혼동되지 않도록 에러 로깅 분리

## 검증

```bash
# 이벤트 버스 상태 확인
bash ~/.hermes/scripts/hermes-health-monitor.sh --status

# 모니터링 (stale lock 정리 + 건강 상태)
bash ~/.hermes/scripts/hermes-health-monitor.sh --monitor

# 대기 이벤트 수
ls ~/.hermes/events/bus/ | wc -l

# 워커 락 수
find ~/.hermes/events/workers/ -mindepth 2 -maxdepth 2 -type d | wc -l
```

## 참조

- `~/.hermes/skills/shared/system-common/lib/event.sh` — Core 라이브러리
- `~/.hermes/skills/shared/system-common/lib/log.sh` — 상관 ID 기반 분산 로그
- `~/.hermes/knowledge/references/systems/overview.md` — 시스템 종합 정보
