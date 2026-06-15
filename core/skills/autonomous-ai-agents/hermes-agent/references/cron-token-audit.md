# 3층위 크론잡 아키텍처 & 토큰 감사 가이드

**최종 업데이트**: 2026-05-18 (JOB-1183/1185/1187)

## 3층위 아키텍처

듀얼 에이전트 시스템의 주기 작업은 3개 층위로 분류된다. **모든 새 크론잡은 이 분류를 따라야 함.**

| 층위 | 성격 | LLM 필요? | 토큰 | 예시 |
|------|------|-----------|------|------|
| crontab (C형) | 결정론적 | ❌ | **0** | 동기화, 정리, 체크, 수집 |
| OpenClaw cron (O형) | 지능적 판단 | ✅ | 있음 | 뉴스 요약, 아이디어, 기억 증류 |
| Hermes cron (H형) | Hermes 내부 | 선택 | no_agent면 0 | (현재 없음) |

**참조**: `~/.shared/AGENTS.md` § 주기 작업 등록 규칙, `~/.openclaw/workspace/HEARTBEAT.md`

## OpenClaw cron 구조

- `payload.kind`: `"agentTurn"`만 존재 (스크립트 전용 모드 없음)
- `enabled: false`로 설정하면 실행 중단
- `schedule.kind`: `"cron"` (cron 표현식) 또는 `"every"` (everyMs 밀리초)

**핵심**: OpenClaw는 agentTurn만 지원하므로, 단순 스크립트 작업은 OpenClaw cron에 등록하면 안 됨 (LLM 토큰 소모)

## 토큰 소모 집계

```bash
# 특정 job의 토큰 소모 집계
python3 -c "
import json
lines = [json.loads(l) for l in open('LOG_PATH') if l.strip()]
total = sum(r.get('usage', {}).get('total_tokens', 0) for r in lines)
avg = total // len(lines) if lines else 0
print(f'실행: {len(lines)}회, 총 토큰: {total:,}, 평균: {avg:,}/회')
"
```

## 고아 크론잡 감지

```bash
# runs/ 디렉토리에 로그가 있지만 jobs.json에 없는 job 찾기
for f in ~/.openclaw/cron/runs/*.jsonl; do
  id=$(basename "$f" .jsonl)
  if ! grep -q "$id" ~/.openclaw/cron/jobs.json; then
    echo "고아: $id ($(wc -l < "$f")회)"
  fi
done
```

## 검증 스크립트

```bash
# 새 크론잡 등록 전 검증
bash ~/.shared/scripts/validate-cron-layer.sh <층위> <작업명> <llm_required>
# 예: bash ~/.shared/scripts/validate-cron-layer.sh crontab wiki-sync false
```

## Pitfalls (JOB-1183/1185/1187 교훈)

1. **crontab은 비워질 수 있음**: 5월 13일 이후 16개 C형 작업이 비어있었음 → 복원 필요
2. **agentTurn 오용**: 에이전트가 단순 스크립트 작업도 agentTurn으로 등록할 수 있음 (memory-monitor 사례, 일일 ~1M 토큰 낭비)
3. **고아 크론잡**: jobs.json에서 제거되어도 스케줄러에서 실행될 수 있음 (HEALTHCHECK 사례, 44.7M 토큰)
4. **플러그인 자동 생성**: memory-core 등 플러그인이 자동으로 agentTurn 크론잡 생성 가능
5. **Hermes로 도피 현상**: OpenClaw agentTurn이 토큰을 먹으므로 에이전트가 Hermes no_agent로 대체하려는 유혹 → 컨셉 훼손 (App이 OS 역할 대신함)