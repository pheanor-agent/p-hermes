# 새 프로젝트 생성 요청

- **JOB**: JOB-2026-0622-005
- **요청자**: 정수민 (ML Platform 팀)
- **요청일**: 2026-06-22
- **상태**: 접수 완료

## 요청 내용

Hermes, 새로운 프로젝트를 시작하려고 합니다. **"Hermes 내부 모니터링 대시보드 시스템 (Hermes-Mon)"** 을 만들어주세요.

### 프로젝트 개요

Hermes Agent 시스템의 실시간 상태를 모니터링할 수 있는 내부 대시보드를 구축하는 프로젝트입니다.

### 프로젝트 기본 설정

- **프로젝트명**: hermes-mon
- **언어**: Python 3.12 + TypeScript (React)
- **GitHub 저장소**: github.com/nous-hermes/hermes-mon (신규 생성 필요)
- **JOB 보드**: `hermes-mon` prefix 사용

### 프로젝트 구조 요청

```
hermes-mon/
├── backend/          # Python FastAPI
├── frontend/         # React + Vite
├── docs/             # 문서
├── tests/            # 테스트
├── deploy/           # 배포 설정
├── project.yaml      # Hermes 프로젝트 메타데이터
└── README.md
```

### 첫 번째 JOB 등록

프로젝트 생성 후 첫 JOB으로 **"모니터링 요구사항 정의서 작성"** 을 등록해주세요. JOB 번호는 `hermes-mon-001`입니다.

### 참고

- `project-metadata-management` skill 참고
- 기존 참고: 프로젝트 `p-hermes`의 `project.yaml`
- 프로젝트 생성 후 첫 JOB까지 완료된 상태로 부탁
