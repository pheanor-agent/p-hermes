---
name: cron-architecture
description: "Hermes cron 시스템 아키텍처: cron-wrapper, cron-runner 패턴, system crontab 관리, 디버깅 워크플로우"
version: 1.0.0
author: Hermes Agent
license: MIT
---

# Cron Architecture

Hermes cron 시스템의 실제 구조, 실행 패턴, 디버깅 방법.

## 트리거

- Cron job 실패 에러 ("Script not found", "Script exited with code 1")
- "cron이 안 돼", "크론잡 확인해줘"
- 주기적 작업 설정/수정/제거 요청
- cron history 분석, 실패 패턴 확인
- "모니터링", "health check", "backup" 등 주기 작업 관련 질문

## 아키텍처

```
┌─────────────────────────────────────────────────────┐
│ System Crontab (systemd cron)                       │
│                                                     │
│  */5  *  * * * → cron-wrapper.sh --name X -- bash  │
│  */10 *  * * * → cron-wrapper.sh --name Y -- bash  │
│  */30 *  * * * → cron-wrapper.sh --name Z -- bash  │
└──────────┬──────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────┐
│ cron-wrapper.sh (SSOT: ~/.hermes/infra/cron/)       │
│                                                     │
│ 1. 실행 → stdout 리다이렉트 (mktemp)                  │
│ 2. 결과 판정 (exit_code + stdout 키워드)              │
│ 3. History 기록 (~/.hermes/cron/history/)            │
│ 4. 메시지 포맷팅 → stdout                           │
│ 5. 이벤트 버스 발행 (optional)                       │
└──────────┬──────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────┐
│ OpenClaw Gateway                                    │
│ cron delivery → Discord/Telegram 채널                │
└─────────────────────────────────────────────────────┘
```

### 핵심 파일

| 파일 | 위치 | 역할 |
|------|------|------|
| `cron-wrapper.sh` | `~/.hermes/infra/cron/` | 모든 cron 실행의 진입점 |
| `cron-runner-*.sh` | `~/.hermes/scripts/` | Wrapper 호출용 thin script (선택적) |
| `cron.yaml` | `~/.hermes/scripts/` | Cron job 레지스트리 (참용도) |
| `history/*.json` | `~/.hermes/cron/history/` | 실행 이력 (최신 90개) |
| `jobs.json` | `~/.openclaw/cron/` | OpenClaw agentTurn cron |

### cron-runner 패턴

`cron-runner-<name>.sh`는 thin wrapper:

```bash
#!/bin/bash
set -uo pipefail
HERMES_ROOT="${HERMES_ROOT:-${HOME}/.hermes}"
exec bash $HERMES_ROOT/infra/cron/cron-wrapper.sh \
  --name "<job_name>" \
  --type system_crontab \
  -- bash $HERMES_ROOT/scripts/<actual_script.sh> "$@"
```

**핵심**: `$HOME`을 `${HOME}`으로 명시적 brace expansion 사용 (`set -u` 호환).

## cron-wrapper.sh 동작

### 실행 흐름

1. 명령어 실행 → stdout/stderr를 temp 파일로 리다이렉트
2. 결과 판정:
   - `exit_code=0` + no keywords → `completed`
   - `exit_code=0` + `warning/warn/경고` 키워드 → `warning`
   - `exit_code≠0` → `failed`
3. History 파일에 엔트리 추가 (jq 기반, 최신 90개 회전)
4. 상태 기반 메시지 포맷팅 → stdout으로 출력
5. exit_code 반환

### 메시지 포맷팅 규칙

| 상태 | 출력 |
|------|------|
| `completed` | `✅ 이름: 완료 라인` (정상/OK 포함된 라인) |
| `warning` | `⚠️ 이름: 첫 라인` + `🔗 상세: history 파일` |
| `failed` | `🔴 이름: 첫 5 라인` + `📋 조치` + `🔗 상세: history 파일` |

### ⚠️ stdout 출력이 알림으로 전달됨

- wrapper의 stdout 출력이 OpenClaw gateway를 통해 cron delivery로 전달
- 스크립트가 `[INFO]`, `[WARNING]` 등 keyword를 출력하면 `warning` 상태로 판정 → 알림 전송
- **silent on success**: 성공 시 stdout을 log로 리다이렉트하면 알림 없음

## Cron 디버깅 워크플로우

### 1. 현재 실행 중인 crontab 엔트리 확인

```bash
# syslog에서 실제 실행 기록 확인
grep "CRON" /var/log/syslog | tail -20

# 특정 job 이름 검색
grep "<job_name>" /var/log/syslog | tail -10
```

### 2. History 파일 확인

```bash
# 최근 실행 이력
cat ~/.hermes/cron/history/<job_name>.json | python3 -m json.tool | head -50

# 실패 횟수 확인 (consecutive failures)
jq '.entries | [.[] | select(.status=="failed")] | length' ~/.hermes/cron/history/<job_name>.json
```

### 3. cron-runner → wrapper → 실제 스크립트 체인 추적

```bash
# cron-runner 존재 확인
ls -la ~/.hermes/scripts/cron-runner-<name>.sh

# cron-runner가 호출하는 실제 스크립트 확인
cat ~/.hermes/scripts/cron-runner-<name>.sh

# wrapper 존재 확인
ls -la ~/.hermes/infra/cron/cron-wrapper.sh

# 실제 스크립트 확인
ls -la ~/.hermes/scripts/<script_name>.sh
```

### 4. 스크립트 직접 실행 테스트

```bash
# 직접 실행 (환경 변수 포함)
bash ~/.hermes/scripts/<script_name>.sh 2>&1

# wrapper 경유 테스트
bash ~/.hermes/infra/cron/cron-wrapper.sh \
  --name "test" --type cron_job -- bash ~/.hermes/scripts/<script_name>.sh
```

## 흔한 문제 및 해결책

### Problem: `Script not found`

**원인**: cron-runner 스크립트가 삭제됨 또는 경로 변경

**해결**:
```bash
# cron-runner 재생성
cat > ~/.hermes/scripts/cron-runner-<name>.sh << 'EOF'
#!/bin/bash
set -uo pipefail
HERMES_ROOT="${HERMES_ROOT:-${HOME}/.hermes}"
exec bash $HERMES_ROOT/infra/cron/cron-wrapper.sh \
  --name "<job_name>" --type system_crontab -- bash $HERMES_ROOT/scripts/<actual_script.sh> "$@"
EOF
chmod +x ~/.hermes/scripts/cron-runner-<name>.sh
```

### Problem: `unbound variable` (set -u)

**원인**: `set -uo pipefail` 환경에서 unset variable 참조

**해결**:
```bash
# ❌ NG: $HOME이 -u에서 unbound로 감지될 수 있음
HERMES_ROOT="${HERMES_ROOT:-$HOME/.hermes}"

# ✅ OK: 명시적 brace expansion
HERMES_ROOT="${HERMES_ROOT:-${HOME}/.hermes}"
```

### Problem: 스크립트가 정상 작동하지만 알림이 계속 전송됨

**원인**: stdout에 `warning/warn/경고` 키워드 포함 → wrapper가 `warning` 상태로 판정

**해결**:
- 스크립트에서 `[INFO]` 대신 `[OK]` 또는 기타 keyword-free 메시지 사용
- 또는 stdout을 로그 파일로 리다이렉트: `script.sh >> /path/to/log 2>&1`

### Problem: cron job이 아예 실행 안 됨

**확인**:
1. syslog에 cron 엔트리가 있는지: `grep "<name>" /var/log/syslog`
2. crontab에 등록되어 있는지: `crontab -l` (권한 필요 시 syslog에서 확인)
3. cron 프로세스 실행 중인지: `ps aux | grep cron`

## OpenClaw vs System Crontab

| 구분 | OpenClaw Cron | System Crontab |
|------|--------------|----------------|
| 관리 위치 | `~/.openclaw/cron/jobs.json` | `/var/log/syslog` 참조 |
| 실행 타입 | `agentTurn` (LLM) | `script` (no_agent) |
| wrapper 경유 | ❌ | ✅ (`cron-wrapper.sh`) |
| history 기록 | `~/.openclaw/cron/runs/` | `~/.hermes/cron/history/` |
| CLI 확인 | `openclaw cron list` | `grep CRON /var/log/syslog` |

## Pitfalls

- **`$HERMES_ROOT` 대신 `$HOME/.hermes`**: `set -u`와 호환되려면 `${HOME}` 사용
- **cron-runner 삭제 후 cron 재설정 필요**: 스크립트만 생성하고 system crontab에 등록 안 하면 실행 안 됨
- **stdout = 알림**: wrapper의 stdout 출력이 그대로 cron delivery로 전달됨
- **keyword 기반 상태 판정**: `warning`, `warn`, `경고`, `임계치` 키워드가 stdout에 있으면 `warning` 상태
- **3회 연속 실패 시 `[ALERT]`**: wrapper가 자동으로 `[ALERT]` 메시지와 stderr 출력
- **history 파일은 최신순**: `entries[0]`이 최신 실행 결과

## 참고

- cron-wrapper.sh 소스: `~/.hermes/infra/cron/cron-wrapper.sh`
- cron 레지스트리 (참용도): `~/.hermes/scripts/cron.yaml`
- 관련 참고: `references/cron-debugging-session-2026-06-14.md`
