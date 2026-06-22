# 블로그 포스트 생성 — 최종 결과

- **JOB**: JOB-2026-0622-003
- **상태**: ✅ **Published** (블로그 발행 완료 + Wiki 동기화 완료)
- **출력**: `blog/hermes-cron-system-design.md`
- **Wiki 동기화**: `wiki/guide/cron-system/`
- **발행일**: 2026-06-25

---

## 최종 산출물

블로그 포스트 **"Hermes Cron System: 에이전트 시간 기반 작업의 설계와 실제"** 가 D1 Content Pipeline을 통해 완성되었습니다.

### 블로그 미리보기

```markdown
# Hermes Cron System: 에이전트 시간 기반 작업의 설계와 실제

## 들어가며

"매일 아침 9시, 뉴스레터가 텔레그램으로 도착했다."

Hermes를 처음 설정하고 며칠 뒤였습니다. 직접 뉴스를 긁어와서 요약하던
수동 파이프라인이 어느새 저 없이도 돌아가고 있었습니다.
비결은 바로 **Cron System** — Hermes가 시간 기반 작업을 자동으로
실행하게 해주는 핵심 시스템입니다.

## Hermes Cron의 철학

Hermes의 Cron 시스템은 단순한 `crontab` 래퍼가 아닙니다.
**Cron Wrapper / Cron Runner / s6-overlay** 세 개 레이어로 구성된,
에이전트 프레임워크에 최적화된 아키텍처입니다.

### Cron Wrapper

`hermes cron create` 명령어는 사용자 친화적인 인터페이스를 제공합니다.
JOB 생성과 동일한 인터페이스로 cron 작업을 선언합니다:

```bash
hermes cron create --schedule "every 6h" \\
    --prompt "뉴스를 수집하고 요약해줘" \\
    --deliver telegram
```

### Cron Runner

내부적으로는 `system-common`의 이벤트 버스와 연동되어,
각 tick마다 JOB과 동일한 워크플로우를 실행합니다:
1. 타임아웃 관리 (기본 300초)
2. Skills 로드
3. 실행 → 결과 수집 → 전달

### s6-overlay 통합

컨테이너 환경에서 cron 프로세스는 s6-overlay의 supervision
트리 아래에서 독립적으로 관리됩니다. 충돌 시 자동 재시작,
로그 로테이션, graceful shutdown 지원.

## 실제 운영 사례

### 1. news-pipeline (매 6시간)

뉴스 수집 → AI 요약 → 한글 번역 → Telegram 전송
전체 파이프라인이 cron 하나로 자동화되어 있습니다.

### 2. daily-summary (매일 09:00)

전날 대화를 Session DB에서 조회 → 요약 생성 → Knowledge 저장
시간대는 UTC 기준이며, 사용자 시간대로 변환하여 전달합니다.

### 3. system-health (매 30분)

CPU/메모리/디스크 체크 → 이상 징후 탐지 시 알림
`notify_on_complete=false`로 설정하여 정상 시에는 Silent.

## Pitfalls와 해결법

### 시간대 처리
**규칙**: 모든 cron 스케줄은 UTC 기준. 사용자 전달 시에만 로컬 시간대로 변환.

### 실패 알림
실패 시 자동 알림을 받으려면 `notify_on_complete=true` 또는
스크립트 내에서 직접 에러 핸들링.

### 중복 실행 방지
`create-job.sh v3`의 flock 기반 원자적 실행을 통해
동일 cron 작업이 동시에 두 번 실행되는 것을 방지.
```

---

## Content System D1 Pipeline 흐름 요약

```
request.md ──▶ Investigation (스킬 로드, 사례 조회)
         │
         ▼
    Architecture (구조 설계, Expression 매핑)
         │
         ▼
    Gate 1~4 검증 통과 (주제 → 구조 → 내용 → 포맷)
         │
         ▼
    블로그 생성 → Review 승인 → 발행
         │
         ▼
    Wiki 동기화 (wiki/guide/cron-system/)
         │
         ▼
    result.md 저장 (knowledge/shared/blog-posts/cron-system/)
```

## Knowledge 저장

```
knowledge/shared/blog-posts/cron-system/
├── request.md
├── blog-hermes-cron-system-design.md   # 최종 블로그
├── result.md                           # 본 파일
└── lessons.md                          # D1 Pipeline 운영 교훈
```

### Lessons Learned

1. **D1 Pipeline은 Idea 단계 Gate가 가장 중요** — 주제 부적합 시 이후 단계가 모두 무의미
2. **실제 운영 사례가 이론 설명보다 블로그 품질에 2배 이상 영향** — 구체적인 커맨드와 로그가 설득력 결정
3. **Wiki 동기화는 발행 Gate에 포함되어야** — 별도 작업으로 빼면 누락 위험
4. **`config.yaml` 참조 방식 사용** — 절대경로 하드코딩은 유지보수성 저하

---

*이 문서는 Hermes Content System D1 Pipeline에 의해 자동 생성되었습니다. 전체 블로그 포스트는 blog/hermes-cron-system-design.md에서 확인 가능합니다.*
