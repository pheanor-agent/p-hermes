# 상관 ID 바인딩 패턴

## 목적

이벤트 발행자 추적성 보장. 동일 상관 ID로 이벤트 체인 재구성 가능.

## 포맷 규칙

```
{PREFIX}-{YYYYMMDD}-{HHMM}-{PID}
```

| 부분 | 예시 | 설명 |
|------|------|------|
| PREFIX | WF, CRON, HEALTH, KS, VR | 발행자 식별 |
| YYYYMMDD | 20260613 | 발행 일시 |
| HHMM | 1937 | 분 단위 타임스탬프 |
| PID | $$ | 프로세스 ID |

## 구현 패턴

```bash
# 스크립트 상단
source "$HOME/.hermes/skills/shared/system-common/lib/event.sh" 2>/dev/null || true
source "$HOME/.hermes/skills/shared/system-common/lib/log.sh" 2>/dev/null || true

# 상관 ID 생성 (발행자별 포맷)
CORRELATION_ID="PREFIX-$(date +%Y%m%d-%H%M)-$$"
export CORRELATION_ID
```

## 발행자별 포맷

| 스크립트 | PREFIX |
|---------|--------|
| workflow-gate.sh | WF |
| cron-wrapper.sh | CRON |
| hermes-health-monitor.sh | HEALTH |
| daily-knowledge-process.sh | KS |
| verify.sh | VR |

## Pitfall

- 동일 분 내 중복: PID 포함하여 고유성 보장
- export 필수: 하위 프로세스에서 상관 ID 상속 필요 시
- log.sh 연동: 상관 ID 기반 분산 로그 상관성 보장
