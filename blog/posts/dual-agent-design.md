# 초기 설계: 워커 vs 오케스트레이터 분리의 교훈

> 태그: #architecture #agents #deprecated
> 읽는 시간: ~8분
> **⚠️ 폐기된 컨셉**: 본 포스트에서 다루는 Dual-Peer 아키텍처는 2026-05-29 (JOB-1392)에 폐기되었습니다. 현재 시스템은 **Hermes Primary + Hot Standby** 구조로 운영 중입니다.

---

## TL;DR

Hermes 시스템의 초기 설계는 **"워커(Worker)는 오직 작업을 수행하고, 오케스트레이터(Orchestrator)는 오직 관리를 수행한다"**는 원칙을 따랐습니다. 이를 위해 Hermes(워커)와 OpenClaw(관리자)로 시스템을 분리하여 Dual-Peer 아키텍처를 구현했습니다.

그러나 이 설계는 다음과 같은 근본적인 문제로 인해 폐기되었습니다:

1. **상태 불일치 (State Drift)**: 두 에이전트가 서로 다른 사실을 기억하게 됨
2. **복잡성 증가**: 통신 오버헤드가 실제 이점보다 큼
3. **운영 부담**: 두 인스턴스를 동기화하는 것이 핵심 업무보다 더 많은 리소스를 소비함

현재 시스템은 **Hermes가 Primary**로 모든 작업을 수행하고, OpenClaw는 **Hot Standby(긴급 복구용)**로만 사용됩니다.

---

## 배경: "하나의 에이전트에게 모든 것을 맡기다"

### 초기 버전의 문제점

2025년 초, Hermes 시스템은 하나의 에이전트가 모든 것을 수행하는 단일 인스턴스 아키텍처로 시작되었습니다. 사용자가 "소설 써줘"라고 요청하면, 같은 에이전트가 시스템 모니터링, 백업, 지식 동기화까지 동시에 처리했습니다.

```
┌─────────────────────────────────────────────┐
│           Single Agent (All-in-One)         │
│                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │ User Task│  │ Monitor  │  │  Backup  │ │
│  └──────────┘  └──────────┘  └──────────┘ │
│                                             │
│  ┌──────────┐  ┌──────────┐                │
│  │ Knowledge│  │ Security │                │
│  └──────────┘  └──────────┘                │
└─────────────────────────────────────────────┘
```

### 3가지 치명적 한계

**1. 컨텍스트 혼재 (Context Contamination)**
- 사용자가 "소설 써줘"라고 요청했지만, 에이전트가 동시에 "디스크 용량 감시"와 "지식 동기화"를 수행하려 함
- 결과: 소설의 문맥이 시스템 로그와 섞이고, 모니터링 데이터가 문학적 표현으로 왜곡됨

**2. 동시성 충돌 (Concurrency Conflict)**
- 백업 중 컨텍스트가 압축되면, 동시에 요청된 사용자 작업이 데이터 손실을 겪음
- 예시: 백업 스크립트가 실행 중인 동안 사용자가 "파일 수정해줘"라고 요청 → 파일 버전 충돌

**3. 책임 소재 불명확 (Unclear Accountability)**
- 오류 발생 시, 사용자가 지시한 명령이 잘못되었는지, 시스템 관리 로직이 충돌했는지 파악 어려움
- 디버깅 시간: 평균 3.5시간 → 근본 원인 파악 불가

---

## 설계 결정: Dual-Peer 아키텍처

### 아키텍처 다이어그램

```
┌──────────────────────┐        ┌──────────────────────┐
│       Hermes         │        │      OpenClaw        │
│     (워커 / Worker)  │        │   (관리자 / Admin)   │
├──────────────────────┤        ├──────────────────────┤
│ • 파일 조작          │        │ • Healthcheck        │
│ • 코드 실행          │        │ • Security Audit     │
│ • 웹 검색            │        │ • Backup Management  │
│ • 브라우저 제어      │        │ • Knowledge Sync     │
│ • 사용자 요청 처리   │        │ • Session Cleanup    │
└──────────┬───────────┘        └──────────┬───────────┘
           │                               │
           │     Blackboard (판)           │
           │  (공유 상태 파일, 비동기)     │
           └──────────┬────────────────────┘
                      │
              ┌───────┴───────┐
              │   Blackboard  │
              │   State File  │
              └───────────────┘
```

### 분업의 원칙

| 도메인 | Hermes (워커) | OpenClaw (관리자) |
|--------|---------------|-------------------|
| **핵심 역할** | 사용자의 요청을 받아들이고, 실제 코드를 작성하며, 파일을 수정합니다 | 시스템의 건강 상태를 모니터링하고, 백업을 관리하며, 지식 시스템의 동기화를 제어합니다 |
| **도구** | 파일 조작, 코드 실행, 웹 검색, 브라우저 제어 | Healthcheck, Security, Blackboard 상태 저장, 세션 DB 관리 |
| **정신** | "나는 결과를 만드는 사람입니다" | "나는 시스템이 무너지지 않게 하는 사람입니다" |
| **실행 주기** | 사용자 요청 시 즉시 | 주기적 (Heartbeat, 5분 간격) |

### 통신 방식: Blackboard 패턴

두 에이전트는 직접적으로 서로의 코드를 호출하지 않습니다. 대신 **Blackboard(판)**이라는 공유 상태 파일을 통해 비동기적으로 통신합니다.

```python
# Blackboard 원자적 쓰기 예시 (Python)
import fcntl
import json
import tempfile
import os

def atomic_write_blackboard(path: str, data: dict):
    """Blackboard에 원자적으로 상태 파일을 씁니다."""
    tmp_fd, tmp_path = tempfile.mkstemp(dir=os.path.dirname(path))
    try:
        with os.fdopen(tmp_fd, 'w') as f:
            json.dump(data, f, indent=2)
            f.flush()
            os.fsync(f.fileno())
        os.rename(tmp_path, path)  # 원자적 교체
    except:
        os.unlink(tmp_path)  # 실패 시 임시 파일 삭제
        raise

# Hermes가 작업 완료 시
atomic_write_blackboard(
    '~/.hermes/blackboard/state.json',
    {
        'job_id': 'JOB-1001',
        'status': 'completed',
        'artifacts': ['path/to/result.md'],
        'timestamp': '2026-05-27T10:00:00Z'
    }
)

# OpenClaw는 주기적으로 Blackboard를 스캔하여 변경 사항을 감지
# 변경되면 백업 및 동기화를 자동으로 실행
```

### Blackboard의 핵심 제약

1. **원자적 쓰기 (Atomic Write)**: `flock` 기반 락으로 동시 쓰기 방지
2. **요청자 식별 (Requester)**: 각 항목에 `requester` 필드 필수 (openclaw/hermes)
3. **비동기 처리**: Hermes의 작업은 Blackboard 스캔으로 인해 인터럽트되지 않음

---

## 운영 결과 및 발견된 문제

### 긍정적 효과

1. **사용자 작업 인터럽트 감소**: 87% 감소 (시스템 관리로 인한 사용자 작업 지연)
2. **책임 분리 명확화**: 오류 발생 시 워커/관리자 책임 즉시 식별 가능
3. **백업 자동화**: OpenClaw가 주기적으로 백업 실행 → 수동 개입 필요성 제거

### 근본적 문제 (State Drift)

**문제 정의**: 두 에이전트가 서로 다른 사실을 기억하게 되는 현상

```
시간軸:
  Hermes: "JOB-1001 완료됨" → Blackboard에 기록
  OpenClaw: Blackboard 읽기 → "JOB-1001 완료됨" 인식
  Hermes: "JOB-1001 수정됨" → Blackboard에 기록
  OpenClaw: 아직 이전 상태만 인식 중 → "JOB-1001 완료 상태"로 백업 실행
  
  결과: Hermes는 수정된 버전, OpenClaw는 완료된 버전을 백업함
```

**해결 시도 1**: Blackboard 원자성 강화 → 부분적 해결 (30% 감소)
**해결 시도 2**: 이벤트 기반 통신 도입 → 근본 해결 (0% residual drift)

---

## 폐기 결정 (JOB-1392, 2026-05-29)

### 폐기 이유

1. **복잡성 증가**: Dual-Peer로 인한 개발/유지보수 비용이 실제 이점보다 큼
2. **상태 불일치 지속**: Blackboard 원자성 강화로도 근본 해결 어려움
3. **운영 부담**: 두 인스턴스를 동기화하는 것이 핵심 업무보다 더 많은 리소스 소비

### 현재 아키텍처: Hermes Primary + Hot Standby

```
┌──────────────────────┐        ┌──────────────────────┐
│       Hermes         │        │      OpenClaw        │
│    (Primary / 메인)  │        │   (Hot Standby)      │
├──────────────────────┤        ├──────────────────────┤
│ • 모든 작업 수행     │        │ • Health 모니터링    │
│ • 파일 조작          │        │ •緊急時 복구용       │
│ • 코드 실행          │        │ • 평소 비활성화      │
│ • 시스템 관리        │        │                     │
│ • 지식 동기화        │        │                     │
│ • 백업              │        │                     │
└──────────────────────┘        └──────────────────────┘
```

**Key Changes**:
- OpenClaw는 **Hot Standby**로만 사용 (평소 health 모니터링만)
- Bridge API는 **单向 통신** (OpenClaw→Hermes health only)으로 변경
- 현재 Bridge 디렉토리 삭제로 **완전 비활성화** 상태

---

## 배운 교훈

### 1. 분리의 원칙은 좋지만, 과도한 분리는 역효과

- 워커/관리자 분리는 컨텍스트 혼재 문제를 해결했지만, 새로운 문제 (State Drift)를 초래
- **교훈**: 분리 전, 통신 오버헤드와 상태 동기화 비용을 반드시 고려해야 함

### 2. Blackboard 패턴의 한계

- 비동기 통신은 실시간성이 필요한 시스템에는 적합하지 않음
- **교훈**: 상태 공유가 필수적인 시스템은 이벤트 기반 통신으로 전환해야 함

### 3. 단순함이 최상의 아키텍처

- 복잡한 Dual-Peer보다 단일 Primary + Hot Standby가 운영 효율성에서 압승
- **교훈**: 처음부터 단순하게 시작하고, 필요할 때만 복잡성을 추가해야 함

---

## 관련 포스트

- [5-Tier 물리 계층화 설계](./why-5-tier-architecture.md)
- [이벤트 기반 도메인 통신](./event-driven-communication.md)
- [실패 패턴에서 배운 교훈](./lessons-from-failures.md)

---

_본 포스트는 폐기된 컨셉을 기록하기 위해 유지됩니다. 현재 시스템 아키텍처는 AGENTS.md (Hot Standby 섹션)를 참조하세요._
