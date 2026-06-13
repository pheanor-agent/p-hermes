# Cron System

주기 작업을 관리하고 자동화하는 시스템입니다.

---

## Overview

| 항목 | 값 |
|------|-----|
| SSOT | `registry.yaml` |
| 경로 | `~/.hermes/cron/` |
| 실행 모드 | no-agent / agent |
| 주기 패턴 | 30m, 1h, 2h, daily, weekly |
| 이력 | `cron/history/` |

---

## 디렉토리 구조

```
~/.hermes/cron/
├── registry.yaml             # 작업 레지스트리 (SSOT)
├── backups/                  # 크론 백업
├── cache/                    # 작업 캐시
├── history/                  # 실행 이력
│   ├── wiki-process/
│   │   ├── 2026-06-13-0900.log
│   │   └── 2026-06-13-0930.log
│   ├── knowledge-daily/
│   └── ...
├── output/                   # 작업 출력
└── ...
```

---

## Registry.yaml 구조

`registry.yaml`은 모든 주기 작업의 단 하나의 진실원 (SSOT)입니다.

```yaml
# Hermes Cron Registry
# 버전: 1.0
# 마지막 갱신: 2026-06-13

jobs:
  - name: "wiki-process"
    description: "Wiki 인박스 처리 및 분류"
    schedule: "*/30 * * * *"      # 30분마다
    mode: no-agent               # 스크립트 전용 (LLM 불필요)
    script: "wiki-process-filings.sh"
    output: "cron/output/wiki/"
    enabled: true

  - name: "knowledge-daily"
    description: "일일 지식 파이프라인"
    schedule: "0 9 * * *"        # 매일 09:00
    mode: agent                  # LLM 기반 판단 + 실행
    description: "뉴스 수집, 번역, Wiki 갱신"
    enabled: true

  - name: "score-build"
    description: "KPL 점수 재계산"
    schedule: "0 2 * * *"        # 매일 02:00
    mode: no-agent
    script: "build-scores.sh"
    enabled: true

  - name: "event-cleanup"
    description: "이벤트 버스 아카이브 정리"
    schedule: "0 0 * * 0"        # 매주 일요일 00:00
    mode: no-agent
    script: "cleanup-event-archive.sh"
    enabled: true

  - name: "gpu-health"
    description: "GPU 헬스 체크"
    schedule: "*/15 * * * *"     # 15분마다
    mode: no-agent
    script: "gpu-health-check.sh"
    enabled: true
```

---

## 실행 모드

### no-agent 모드

LLM 호출 없이 스크립트만 실행합니다. 빠르고 저렴합니다.

```
registry.yaml (명령 읽기)
  → script 실행
  → output 저장
  → history.log 기록
  → 이벤트 버스: cron.completed
```

### agent 모드

LLM을 사용하여 판단 + 실행합니다. 유연하지만 느립니다.

```
registry.yaml (명령 읽기)
  → LLM에 작업 문맥 제공
  → LLM 판단 (실행 여부, 우선순위)
  → LLM 실행 또는 스크립트 호출
  → output 저장
  → history.log 기록
```

| 모드 | LLM 호출 | 비용 | 속도 | 유연성 |
|------|---------|------|------|--------|
| no-agent | ❌ | 무료 | 빠름 | 낮음 |
| agent | ✅ | 있음 | 느림 | 높음 |

---

## 주기 패턴

| 주기 | cron 표현식 | 예시 |
|------|-------------|------|
| 15분 | `*/15 * * * *` | GPU 헬스 체크 |
| 30분 | `*/30 * * * *` | Wiki 인박스 처리 |
| 1시간 | `0 * * * *` | 캐시 정리 |
| 2시간 | `0 */2 * * *` | 지식 스캔 |
| 매일 | `0 9 * * *` | 지식 파이프라인 |
| 매주 | `0 0 * * 0` | 이벤트 정리 |

---

## 이력 관리

모든 실행 기록이 `cron/history/`에 저장됩니다.

### 로그 구조

```
cron/history/<job-name>/
└── <YYYY-MM-DD>-<HHMM>.log
```

### 로그 내용

```
=== Cron Run: wiki-process ===
시작: 2026-06-13T09:00:00Z
종료: 2026-06-13T09:00:12Z
상태: success
처리 항목: 15
신규 분류: 3 (T1: 1, T2: 1, T3: 1)
---
```

---

## cron-wrapper.sh

모든 cron 작업은 wrapper를 통해 실행됩니다:

```bash
#!/bin/bash
# cron-wrapper.sh — 모든 Cron 작업 래퍼
# 역할: 로그 + 이벤트 발행 + 오류 처리

JOB_NAME="$1"
SCRIPT="$2"

echo "=== Cron Start: $JOB_NAME ===" | tee -a "cron/history/$JOB_NAME/$(date +%Y-%m-%d)-$(date +%H%M).log"

# 스크립트 실행
if bash "$SCRIPT"; then
    echo "✅ success" | tee -a "cron/history/$JOB_NAME/$(date +%Y-%m-%d)-$(date +%H%M).log"
    emit_event "cron.completed" "{\"job\": \"$JOB_NAME\", \"status\": \"success\"}"
else
    echo "❌ failed" | tee -a "cron/history/$JOB_NAME/$(date +%Y-%m-%d)-$(date +%H%M).log"
    emit_event "cron.failed" "{\"job\": \"$JOB_NAME\", \"status\": \"failed\"}"
fi
```

---

## 참조

- [ARCHITECTURE.md](../ARCHITECTURE.md) — 전체 아키텍처
- [docs/layer2-knowledge-state.md](../layer2-knowledge-state.md) — Layer 2
- [docs/systems/knowledge.md](knowledge.md) — 지식 시스템 (갱신 연동)
