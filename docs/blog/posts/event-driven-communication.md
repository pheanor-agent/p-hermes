# 이벤트 기반 도메인 통신

> 태그: #architecture #workflow
> 읽는 시간: ~10분

---

## TL;DR

시스템이 복잡해지면, 각 컴포넌트가 서로를 직접 호출하게 됩니다. 이는 치명적인 결합을 의미합니다. Hermes는 **\"도메인 간 직접 호출을 금지\"**하고, 대신 상태 파일과 이벤트를 통한 비동기 통신을 채택했습니다.

```
┌─────────────────────────────────────────────────────┐
│              이벤트 기반 통신 아키텍처                 │
├─────────────────────────────────────────────────────┤
│                                                     │
│  도메인 A          도메인 B          도메인 C       │
│  (에이전트)        (백업)           (지식 동기화)   │
│                                                      │
│  ┌──────┐  상태파일  ┌──────┐  상태파일  ┌──────┐  │
│  │ 작업 │ ──────────→ │ 백업 │ ──────────→ │ 지식 │  │
│  │ 완료 │  (비동기)   │ 실행 │  (비동기)   │ 갱신 │  │
│  └──────┘            └──────┘            └──────┘  │
│                                                      │
│  이벤트 파일: ~/.hermes/state/events/                │
└─────────────────────────────────────────────────────┘
```

---

## 배경: "동기 호출의 지옥"

### 초기 시스템의 문제

2025년 초, Hermes 시스템에서 지식 업데이트 스크립트가 실행되면, 이 스크립트가 직접 백업 스크립트를 호출했습니다. 백업 스크립트가 끝나면 다시 세션 정리 스크립트를 호출했습니다.

```bash
# 초기 시스템: 직접 호출 연쇄
#!/bin/bash
# knowledge-sync.sh

# 1. 지식 업데이트
bash knowledge-update.sh

# 2. 백업 실행 (직접 호출)
bash backup.sh

# 3. 세션 정리 (직접 호출)
bash session-cleanup.sh
```

**3가지 치명적 문제**:

1. **블로킹 (Block)**: A가 B를 호출하면, A는 B가 끝날 때까지 멈춰 서 있어야 함
2. **연쇄 반응**: B에서 오류가 발생하면 A도 함께 죽음
3. **동시성 붕괴**: 두 에이전트가 동시에 하나의 스크립트 호출 시 데이터 손상

### 실제 사고 사례

**2025-11-20 연쇄 실패**
- 지식 업데이트 스크립트 실패 → 백업 스크립트도 함께 실패
- 결과: 지식 데이터 손실 + 백업 데이터도 손상됨
- 복구 시간: 4시간 (데이터베이스 롤백 필요)

**2026-01-05 동시성 충돌**
- Hermes와 OpenClaw가 동시에 backup.sh 호출
- 파일 락 충돌 → 백업 데이터 손상
- 결과: 24시간 분량의 백업 데이터 손실

---

## 설계 결정: 상태 파일 기반 이벤트 통신

Hermes는 **"함수 호출"을 "파일 변경 이벤트"로 대체**했습니다.

### 핵심 원칙: 도메인 간 직접 호출 금지

```
┌─────────────────────────────────────────────────────┐
│              직접 호출 금지 원칙                      │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ❌ 금지: 도메인 A의 스크립트가 도메인 B의           │
│            스크립트를 직접 호출하는 행위              │
│                                                     │
│  ✅ 허용: 상태 파일 작성 → 비동기 감지 → 처리        │
│                                                     │
│  ⚠️ 예외: Gateway 스크립트 (메시징 연동용)           │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 1. 상태 파일 작성 (Atomic Write)

에이전트가 작업을 완료하면, 공유 폴더에 상태 파일을 원자적으로 갱신합니다.

```python
# atomic_write.py - 원자적 파일 쓰기
import fcntl
import json
import tempfile
import os

def atomic_write(path: str, data: dict):
    """
    원자적으로 파일을 씁니다.
    실패 시 원본 파일은 변경되지 않습니다.
    """
    dir_path = os.path.dirname(path)
    tmp_fd, tmp_path = tempfile.mkstemp(dir=dir_path)
    
    try:
        with os.fdopen(tmp_fd, 'w') as f:
            json.dump(data, f, indent=2)
            f.flush()
            os.fsync(f.fileno())
        os.rename(tmp_path, path)  # 원자적 교체
    except Exception:
        os.unlink(tmp_path)  # 실패 시 임시 파일 삭제
        raise

# 에이전트 작업 완료 시 호출
atomic_write(
    '~/.hermes/state/JOB-1001-state.json',
    {
        'jobId': 'JOB-1001',
        'status': 'completed',
        'artifacts': ['path/to/result.md'],
        'timestamp': '2026-05-27T10:00:00Z'
    }
)
```

### 2. 비동기 감지 및 처리

다른 도메인은 주기적으로 상태 파일을 스캔하여 변경 사항을 감지합니다.

```bash
#!/bin/bash
# event-scanner.sh - 이벤트 스캐너 (주기적 실행)

STATE_DIR="$HOME/.hermes/state"
LAST_SCAN_FILE="$HOME/.hermes/state/.last_scan"

# 1. 마지막 스캔 시간 확인
LAST_SCAN=$(cat "$LAST_SCAN_FILE" 2>/dev/null || echo "0")

# 2. 변경된 상태 파일 확인
for state_file in "$STATE_DIR"/*.json; do
    MODIFIED=$(stat -c %Y "$state_file" 2>/dev/null || echo "0")
    
    if [ "$MODIFIED" -gt "$LAST_SCAN" ]; then
        echo "[Event] 변경 감지: $state_file"
        
        # 3. 이벤트 처리
        handle_event "$state_file"
    fi
done

# 4. 스캔 시간 갱신
date +%s > "$LAST_SCAN_FILE"
```

### 3. 이벤트 처리 로직

```python
# event_handler.py - 이벤트 처리기
import json
import os

def handle_event(state_file: str):
    """상태 파일 변경 이벤트를 처리합니다."""
    
    with open(state_file, 'r') as f:
        state = json.load(f)
    
    job_id = state.get('jobId')
    status = state.get('status')
    
    if status == 'completed':
        # 백업 실행
        trigger_backup(job_id)
        
        # 지식 시스템 동기화
        sync_knowledge(job_id)
        
    elif status == 'failed':
        # 실패 알림 전송
        send_failure_alert(job_id)
```

---

## 이벤트 버스 아키텍처 (JOB-1568, 2026-06-13)

**업데이트**: 단일 진입점 (`event.sh`)으로 통합된 이벤트 버스 시스템으로 진화했습니다.

```bash
# event.sh - 이벤트 버스 진입점
#!/bin/bash

event_type="$1"
payload="$2"

# 1. mutex 기반 원자적 이벤트 처리
exec 200>/tmp/.event-mutex.lock
flock -n 200 || { echo "Event already processing"; exit 1; }

# 2. 이벤트 저장 (JSONL)
echo "{\"type\": \"$event_type\", \"payload\": $payload, \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" \
  >> ~/.hermes/state/event-history.jsonl

# 3. 이벤트 처리
case "$event_type" in
  job_completed)
    handle_job_completed "$payload"
    ;;
  job_failed)
    handle_job_failed "$payload"
    ;;
  system_alert)
    handle_system_alert "$payload"
    ;;
esac

# 4. mutex 해제
flock -u 200
```

**특징**:
- **mkdir atomic mutex**: 동시 이벤트 처리 방지
- **JSONL history**: 모든 이벤트 기록 유지
- **silent-on-success**: 성공 시 무음 처리

---

## 다른 대안과의 비교

| 대안 | 문제점 | 이벤트 기반 통신 |
|------|--------|-----------------|
| **함수/스크립트 직접 호출** | 결합도 높고 오류 연쇄 전파 | 도메인 간 완전한 비동기 격리 |
| **Message Queue (RabbitMQ 등)** | 운영 및 유지보수 너무 복잡 | 파일 시스템 자체를 큐로 활용 |
| **DB Trigger** | 데이터베이스 스키마 변경 필요 | 별도 인프라 설정 불필요 |
| **gRPC/microservice** | 네트워크 오버헤드, 설정 복잡 | 로컬 파일 시스템으로 최소 오버헤드 |

---

## 실제 운영 사례

### 성공 사례: 지식 동기화 파이프라인

**이벤트 흐름**:
```
1. 에이전트: 작업 완료 → 상태 파일 작성
2. 이벤트 스캐너: 변경 감지 → 백업 트리거
3. 백업 스크립트: 실행 → 백업 완료 상태 파일 작성
4. 이벤트 스캐너: 변경 감지 → 지식 동기화 트리거
5. 지식 동기화: 실행 → 완료 상태 파일 작성
```

**결과**:
- 연쇄 실패율: 0% (이전 15%에서)
- 복구 시간: 5분 (이전 4시간에서)

### 실패 사례: 경합 조건 (Race Condition)

**문제**:
- 파일 변경이 감지되기도 전에 다른 에이전트가 같은 파일 덮어씀
- 결과: 이벤트 누락 또는 중복 처리

**해결**:
- `flock` 기반 Atomic Write 도입
- 이벤트 처리 시 mutex 로킹
- JSONL history로 이벤트 추적 가능

---

## 관련 포스트

- [5-Tier 물리 계층화 설계](./why-5-tier-architecture.md)
- [Cron 3계층 분리 아키텍처](./cron-3layer-separation.md)
- [초기 설계: 워커 vs 오케스트레이터 분리의 교훈](./dual-agent-design.md)

---

_이벤트 기반 통신은 시스템의 결합도를 극단적으로 낮춥니다. 상태 파일은 도메인 간 통신의 핵심 메커니즘입니다._
