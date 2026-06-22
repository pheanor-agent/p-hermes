# 블로그 포스트 생성 요청

- **JOB**: JOB-2026-0622-003
- **요청자**: 이정훈 (DevOps 팀)
- **요청일**: 2026-06-22
- **상태**: 접수 완료

## 요청 내용

Hermes, 우리 팀의 Cron 시스템에 대한 기술 블로그 포스트를 작성해주세요. 제목은 **"Hermes Cron System: 에이전트 시간 기반 작업의 설계와 실제"** 입니다.

### 요청 상세

1. **Content Domain**: D1 (Blog / Article)
2. **예상 분량**: 3,000~5,000자
3. **대상 독자**: Hermes 사용자 및 에이전트 시스템 개발자
4. **톤**: 기술 중심, 약간의 친근함
5. **언어**: 한국어

### 포함할 내용

- Cron 시스템이 필요한 이유 (수동 반복 작업의 문제점)
- Hermes Cron의 설계 철학: Cron Wrapper / Cron Runner / s6-overlay
- `cronjob` 툴 사용법과 다양한 스케줄링 패턴
- 실제 운영 사례 (뉴스 수집, 일일 요약, 시스템 상태 체크)
- Pitfalls: 시간대 처리, 실패 알림, 중복 실행 방지

### 참고 자료

- `cron-architecture` skill
- `periodic-task-architecture` skill
- Knowledge: `knowledge/system/cron/cron-wrapper-design.md`

### 전달 방식

최종 결과는 **Medium 스타일**의 markdown 문서로 출력해주세요. 추후 Wiki에 동기화할 예정입니다. `content-system`의 D1 도메인 파이프라인을 사용해주세요.
