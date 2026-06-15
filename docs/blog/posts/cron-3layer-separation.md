# Cron 3계층 분리 아키텍처

> 태그: #cron #architecture
> 읽는 시간: ~10분

---

## TL;DR

에이전트가 자동으로 작업을 수행하는 **Cron(크론)** 시스템은 실패할 경우 시스템의 신뢰성을 무너뜨립니다. Hermes는 크론을 단순한 스케줄러가 아닌, **Registry → Wrapper → Runner** 3개의 계층으로 분리하여 실패 격리와 관측성을 확보했습니다.

```
┌─────────────────────────────────────────────────────┐
│                    Cron Registry                     │
│  (registry.yaml: 스케줄, 모델, 전달 채널 정의)       │
└──────────────────────┬──────────────────────────────┘
                       │ 매시간/매일 스케줄 트리거
                       ▼
┌─────────────────────────────────────────────────────┐
│                   Cron Wrapper                       │
│  (cron-wrapper.sh: 세션 생성, 토큰 전달, 상태 관리) │
└──────────────────────┬──────────────────────────────┘
                       │ Hermes 세션 spawn
                       ▼
┌─────────────────────────────────────────────────────┐
│                   Cron Runner                        │
│  (cron-runner: 실제 작업 실행, 결과 수집, 알림 전송) │
└─────────────────────────────────────────────────────┘
```

---

## 배경: "무분별한 자동화"

### 초기 버전의 문제

2025년 초, Hermes의 크론 시스템은 `config.yaml`에 스크립트 이름과 실행 시간을 적는 수준이었습니다.

```yaml
# 초기 크론 설정 (문제 발생)
cron:
  - name: "system-check"
    script: "healthcheck.sh"
    schedule: "0 */6 * * *"  # 6시간마다
```

**3가지 치명적 문제**:

1. **실패 감지 불가**: "스크립트가 실패했는데, 에이전트가 알아채는가?" → 아니었습니다.
2. **에이전트 폭주 제어 불가**: "에이전트가 폭주하면 어떻게 멈추는가?" → 강제 종료 외에는 방법이 없었습니다.
3. **실행 로그 부재**: "크론이 실행된 로그는 어디에 저장되는가?" → 저장되지 않았습니다.

### 실제 사고 사례

**2025-12-15 시스템 체크 실패**
- healthcheck.sh가 실패했지만, 아무도 알지 못함
- 다음 실행: 6시간 후 → 시스템 문제가 6시간 동안 방치됨
- 결과: 디스크 용량 95%까지 증가, 데이터 손실 위험

**2026-01-20 크론 폭주**
- news-aggregator.sh가 무한 루프 진입
- 30분 동안 120개 크론 세션 생성 → 토큰 한도 초과
- 결과: 다른 크론 작업 모두 실패, 수동 개입 필요

---

## 설계 결정: 3계층 구조

### 계층 1: Registry (레지스트리)

**역할**: 크론 작업의 메타데이터 정의 (무엇을, 언제, 어떻게 실행할지)

**파일**: `~/.hermes/infra/cron/registry.yaml`

```yaml
# registry.yaml 예시
jobs:
  - id: job-system-health
    name: "시스템 건강 상태 점검"
    schedule: "0 */6 * * *"
    model:
      provider: zai
      model: glm-5.2
    deliver: "origin"
    enabled: true
    prompt: |
      시스템 건강 상태를 점검하고, 이상 사항을 보고하세요.
      체크리스트:
      1. 디스크 용량 확인
      2. 메모리 사용량 확인
      3. 프로세스 상태 확인
    skills:
      - system-health
    enabled_toolsets:
      - terminal
      - file

  - id: job-news-digest
    name: "주간 뉴스 소소화"
    schedule: "0 9 * * 1"  # 매주 월요일 오전 9시
    model:
      provider: openrouter
      model: anthropic/claude-sonnet-4
    deliver: "telegram"
    enabled: true
    prompt: |
      최신 AI 관련 뉴스를 수집하고, 요약 보고서를 작성하세요.
    skills:
      - news-aggregator
    enabled_toolsets:
      - web
      - file
```

**Registry의 핵심 필드**:

| 필드 | 설명 | 예시 |
|------|------|------|
| `id` | 고유 식별자 | `job-system-health` |
| `name` | 사람이 읽을 수 있는 이름 | "시스템 건강 상태 점검" |
| `schedule` | Cron 표현식 또는 ISO timestamp | `"0 */6 * * *"` |
| `model` | 사용 모델 (선택) | `{provider: zai, model: glm-5.2}` |
| `deliver` | 결과 전달 채널 | `"origin"`, `"telegram"`, `"discord"` |
| `enabled` | 활성화 여부 | `true`/`false` |
| `prompt` | 작업 프롬프트 | "시스템 건강 상태를 점검하세요" |
| `skills` | 로드할 스킬 목록 | `["system-health"]` |
| `enabled_toolsets` | 사용 가능한 툴셋 | `["terminal", "file"]` |

### 계층 2: Wrapper (래퍼)

**역할**: 세션 생성, 토큰 전달, 상태 관리, 재시도 로직

**스크립트**: `~/.hermes/core/scripts/cron-wrapper.sh`

```bash
#!/bin/bash
# cron-wrapper.sh - 크론 작업 래퍼

set -euo pipefail

JOB_ID="$1"
REGISTRY_FILE="$HOME/.hermes/infra/cron/registry.yaml"

# 1. Registry에서 작업 메타데이터 로드
echo "[Cron Wrapper] Job $JOB_ID 시작"

# 2. 세션 생성 (Hermes Agent 세션)
SESSION_ID=$(hermes session create --job "$JOB_ID")
echo "[Cron Wrapper] 세션 생성: $SESSION_ID"

# 3. 토큰 및 설정 전달
export HERMES_CRON_JOB_ID="$JOB_ID"
export HERMES_CRON_SESSION="$SESSION_ID"

# 4. 상태 파일 생성
cat > "$HOME/.hermes/state/cron-${JOB_ID}.json" << EOF
{
  "job_id": "$JOB_ID",
  "session_id": "$SESSION_ID",
  "status": "running",
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "retry_count": 0
}
EOF

# 5. Runner 실행
bash "$HOME/.hermes/core/scripts/cron-runner.sh" "$JOB_ID"

# 6. 상태 업데이트
STATUS=$?
if [ $STATUS -eq 0 ]; then
  jq '.status = "completed"' "$HOME/.hermes/state/cron-${JOB_ID}.json" > /tmp/cron.json
  mv /tmp/cron.json "$HOME/.hermes/state/cron-${JOB_ID}.json"
else
  jq '.status = "failed"' "$HOME/.hermes/state/cron-${JOB_ID}.json" > /tmp/cron.json
  mv /tmp/cron.json "$HOME/.hermes/state/cron-${JOB_ID}.json"
fi

echo "[Cron Wrapper] Job $JOB_ID 완료 (status: $STATUS)"
```

**Wrapper가 담당하는 작업**:
- 세션 라이프사이클 관리 (생성 → 실행 → 정리)
- 재시도 로직 (지수 백오프: 1초 → 2초 → 4초)
- 상태 파일 갱신 (실행 중/완료/실패)
- 실패 시 알림 전송

### 계층 3: Runner (러너)

**역할**: 실제 작업 실행, 결과 수집, 알림 전송

**스크립트**: `~/.hermes/core/scripts/cron-runner.sh`

```python
#!/usr/bin/env python3
"""
cron-runner.py - 크론 작업 러너

실제 작업 실행, 결과 수집, 알림 전송을 담당합니다.
"""

import json
import os
import sys
from datetime import datetime

def run_job(job_id: str):
    """주어진 job_id에 해당하는 작업을 실행합니다."""
    
    # 1. Registry에서 작업 정보 로드
    registry = load_registry()
    job = find_job(registry, job_id)
    
    if not job:
        print(f"[Error] Job {job_id} not found in registry")
        sys.exit(1)
    
    # 2. 프롬프트와 스킬 로드
    prompt = job['prompt']
    skills = job.get('skills', [])
    toolsets = job.get('enabled_toolsets', [])
    
    # 3. Hermes Agent에게 작업 위임
    result = hermes_execute(
        prompt=prompt,
        skills=skills,
        toolsets=toolsets,
        model=job.get('model', {})
    )
    
    # 4. 결과 수집 및 알림 전송
    deliver = job.get('deliver', 'origin')
    send_notification(
        channel=deliver,
        message=result['summary'],
        attachments=result.get('artifacts', [])
    )
    
    return result

if __name__ == '__main__':
    job_id = sys.argv[1]
    run_job(job_id)
```

---

## 실패 격리 및 관측성

### 실패 격리

```
┌─────────────────────────────────────────────────────┐
│              실패 격리 메커니즘                      │
├─────────────────────────────────────────────────────┤
│                                                     │
│  1. 세션 격리                                       │
│     - 각 크론 작업은 별도 세션에서 실행              │
│     - 한 작업 실패가 다른 작업에 영향 없음          │
│                                                     │
│  2. 재시도 로직                                      │
│     - 1차 실패: 1초 후 재시도                       │
│     - 2차 실패: 2초 후 재시도                       │
│     - 3차 실패: 4초 후 재시도 → 최종 실패           │
│                                                     │
│  3. 상태 파일 기록                                   │
│     - 모든 실행/실패 기록 상태 파일에 저장          │
│     - 디버깅 시 최근 실행 기록 확인 가능            │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 관측성 확보

**실행 로그**: `~/.hermes/state/cron-*.json`

```json
{
  "job_id": "job-system-health",
  "session_id": "cron-20260527-100000",
  "status": "completed",
  "started_at": "2026-05-27T10:00:00Z",
  "completed_at": "2026-05-27T10:05:00Z",
  "retry_count": 0,
  "result": {
    "summary": "시스템 상태 정상",
    "artifacts": ["~/.hermes/workspace/reports/system-health-20260527.md"]
  }
}
```

**실패 알림**: Blackboard 파일 폴백 + (선택) Bridge API 전송

---

## 실제 운영 사례

### 성공 사례: 주간 뉴스 소소화

**설정**:
```yaml
- id: job-news-digest
  name: "주간 뉴스 소소화"
  schedule: "0 9 * * 1"  # 매주 월요일 오전 9시
  deliver: "telegram"
  enabled: true
  prompt: |
    최신 AI 관련 뉴스를 수집하고, 요약 보고서를 작성하세요.
    체크리스트:
    1. 주요 AI 기업 동향
    2. 새로운 모델/도구 출시
    3. 보안 취약점 공지
  skills:
    - news-aggregator
  enabled_toolsets:
    - web
    - file
```

**결과**:
- 실행 시간: 8-12분
- 실패율: 2.3% (30일 기준)
- 알림 전송 성공률: 99.7%

### 실패 사례: GPU 모니터링 (해결됨)

**문제**:
- GPU 온도가 임계값 초과 시 반복 알림 발생
- 1시간 동안 60개 알림 전송 → 사용자에게 스팸

**해결**:
- `watch_patterns` + `notify_on_complete` 조합 사용
- 15초 이내 중복 알림 드롭
- 3회 연속 드롭 시 자동으로 `notify_on_complete`로 전환

---

## 관련 포스트

- [이벤트 기반 도메인 통신](./event-driven-communication.md)
- [역할 기반 모델 라우팅 설계](./model-routing-design.md)
- [실패 패턴에서 배운 교훈](./lessons-from-failures.md)

---

_Cron 3계층 아키텍처는 시스템 신뢰성을 확보하는 핵심 설계입니다. Registry는 작업을 정의하고, Wrapper는 실행을 관리하며, Runner는 실제 작업을 수행합니다._
