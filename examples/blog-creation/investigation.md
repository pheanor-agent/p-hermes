# 블로그 포스트 생성 — 조사 단계

- **JOB**: JOB-2026-0622-003
- **조사 기간**: 2026-06-22 14:00 ~ 14:40
- **참조**: cron-architecture skill, periodic-task-architecture skill

## 1. 관련 스킬 로드

### cron-architecture 스킬

핵심 내용:
- **Cron Wrapper**: `hermes cron create` 명령어의 래퍼. JOB 생성과 동일한 인터페이스
- **Cron Runner**: 실제 스케줄링 엔진. `system-common`의 이벤트 버스와 연동
- **s6-overlay**: 컨테이너 내 프로세스 관리, cron 프로세스의 생명주기 관리

### periodic-task-architecture 스킬

- 결정론적 작업: OS crontab (고정 스케줄)
- Hermes 전용: `cronjob` 툴 (동적 생성, AI 최적화)
- 비교 분석 자료 있음

## 2. 기존 사례 조사

실제 운영 중인 cron 작업:

| 작업명 | 스케줄 | 설명 |
|--------|--------|------|
| news-pipeline | 매 6시간 | 뉴스 수집 → 번역 → Telegram 전송 |
| daily-summary | 매일 09:00 | 전날 대화 요약 생성 |
| system-health | 매 30분 | 시스템 상태 체크 및 알림 |
| knowledge-sync | 매 1시간 | Knowledge 색인 갱신 |

## 3. D1 Domain 파이프라인 분석

Content System D1 (Blog) 파이프라인:

```
Idea → Outline → Draft → Review → Publish → Wiki Sync
```

각 단계별 검증 Gate:
- **아이디어 검증**: 주제의 독창성 및 관련성
- **개요 검증**: 논리적 흐름 및 구조
- **초안 검증**: 사실 관계, 용어 정확성, 분량
- **발행 검증**: 플랫폼별 포맷 호환성

## 4. 참고 블로그 포스트

Knowledge 내 기존 기술 블로그:
- `knowledge/shared/blog-posts/hermes-intro-series/` — 톤앤매너 참고
- `knowledge/shared/blog-posts/case-studies/` — 사례 서술 스타일 참고
