---
name: system-common
description: POSIX 원자성 기반 이벤트 버스, 통일 로그, 듀얼 템플릿 엔진. 무데몬 아키텍처의 핵심 라이브러리.
---

# System Common Library

POSIX 파일 시스템 프리미티브를 활용한 무락(Lockless) 라이브러리.

## 구성

| 파일 | 기능 |
|------|------|
| `lib/event.sh` | 원자적 이벤트 버스 (publish/claim/archive) |
| `lib/log.sh` | 분산 추적용 통일 로그 |
| `lib/template.sh` | 듀얼 엔진 템플릿 처리 |

## 사용법

```bash
# 라이브러리 로딩
source ~/.hermes/skills/shared/system-common/lib/event.sh
source ~/.hermes/skills/shared/system-common/lib/log.sh

# 초기화
log_init

# 이벤트 발행
emit_event "job.completed" "${CORRELATION_ID}" '{"job_id": "JOB-1620"}'

# 이벤트 구독 (원자적 경쟁 획득)
claim_event "knowledge" "${event_file}"

# 로그 기록
log_info "이벤트 처리 완료"
```

## 원자성 보장

| 연산 | 보장 방식 |
|------|----------|
| `mkdir` | 커널 레벨 Mutex (동시 요청 시 1개만 성공) |
| `mv -n` | 동일 FS 내 원자적 이동 + 덮어쓰기 방지 |
| `rmdir` | 빈 디렉토리만 삭제 가능 (安全检查) |

## 이벤트 디렉토리 구조

```
~/.hermes/events/
├── bus/              # 이벤트 큐 (*.json)
├── workers/          # 워커 작업 영역 (lock_dir)
│   ├── workflow/
│   ├── knowledge/
│   └── backup/
└── archive/          # 처리 완료 이벤트 아카이브
```

## 멱등성 규칙

모든 이벤트 처리 API는 중복 호출 시 에러 없이 정상 종료해야 함.
- 예: 이미 `done` 상태인 JOB에 `transition done` 호출 시 exit 0 반환
