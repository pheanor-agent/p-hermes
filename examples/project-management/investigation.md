# 프로젝트 생성 — 조사 단계

- **JOB**: JOB-2026-0622-005
- **조사 기간**: 2026-06-22 16:30 ~ 17:10
- **참조**: project-metadata-management skill, p-hermes/project.yaml

## 1. Project Metadata System 분석

`project-metadata-management` skill 로드 결과:

### 프로젝트 메타데이터 구조 (`project.yaml`)

```yaml
project:
  name: hermes-mon
  display_name: "Hermes 내부 모니터링 대시보드"
  type: application
  language: [python, typescript]
  created: 2026-06-22
  status: active
  jobs:
    prefix: hermes-mon
    next_number: 1
  github:
    owner: nous-hermes
    repo: hermes-mon
  docs:
    path: docs/
    index: README.md
```

### JOB 번호 관리 규칙

- JOB prefix: `hermes-mon-`
- 첫 JOB 번호: `hermes-mon-001`
- JOB 상태 파일: `jobs/hermes-mon-001/` 디렉토리
- JOB 보드 등록: `kanban/hermes-mon/` 보드 생성

## 2. 기존 프로젝트 분석

`p-hermes/project.yaml` 분석:
- 프로젝트 유형: documentation
- JOB prefix: `p-hermes-`
- 구조: `specs/`, `docs/`, `src/`, `tests/`

`hermes-mon`은 **application** 타입이므로 구조가 다름:
- `backend/`, `frontend/`, `deploy/` 필요
- API 설계 문서 포함 필요

## 3. GitHub 저장소 확인

- **저장소**: github.com/nous-hermes/hermes-mon
- **존재 여부**: 미확인 (신규 생성 필요)
- **권장 설정**: Private 저장소, Hermes 팀만 접근

## 4. 모니터링 시스템 사전 조사

Knowledge 검색 결과:
- 기존 모니터링 관련 Knowledge 없음 (신규 도메인)
- `knowledge/system/monitoring/` 경로 아직 미존재 → 생성 필요

## 5. 첫 JOB 정의

JOB `hermes-mon-001`: "모니터링 요구사항 정의서 작성"
- Type: 기획/문서화
- Priority: 높음
- 예상 일정: 3일
- 산출물: `docs/requirements.md`
