# Hermes Agent Documentation

Hermes Agent 시스템의 구조, 구성 요소, 운영 가이드를 담은 문서입니다.

---

## 빠른 탐색

| 문서 | 설명 |
|------|------|
| [시스템 종합](systems/overview.md) | 전체 시스템 현황 및 탐색 시나리오 |
| [9단계 워크플로우](workflow-pipeline.md) | JOB 상태 머신, 체크포인트, 전이 규칙 |
| [스킬 시스템](skill-system.md) | 146개 스킬, 카테고리, 트리거 기반 자동 로딩 |

## 시스템별 심화

| 시스템 | 문서 | 상태 |
|--------|------|------|
| 모델 & 프로바이더 | [systems/models.md](systems/models.md) | ✅ 활성 |
| 지식 관리 | [systems/knowledge.md](systems/knowledge.md) | ✅ 활성 |
| 크론 자동화 | [systems/cron.md](systems/cron.md) | ✅ 활성 |
| 백업 & 복구 | [systems/backup.md](systems/backup.md) | ✅ 활성 |
| 배포 & 이미지 | [systems/deploy.md](systems/deploy.md) | ✅ 활성 |

## 탐색 시나리오

### 개발자
- 새 작업 모델 선택 → [systems/models.md](systems/models.md)
- 스킬 추가/수정 → [skill-system.md](skill-system.md)
- 작업 흐름 이해 → [workflow-pipeline.md](workflow-pipeline.md)

### 운영자
- 주기 작업 확인 → [systems/cron.md](systems/cron.md)
- 백업 상태 점검 → [systems/backup.md](systems/backup.md)
- 배포 파이프라인 → [systems/deploy.md](systems/deploy.md)

### 에이전트
- 지식 시스템 구조 → [systems/knowledge.md](systems/knowledge.md)
- 워크플로우 규칙 → [workflow-pipeline.md](workflow-pipeline.md)

---

## 문서 구조

```
p-hermes/docs/
├── index.md                 # 이 파일 — 진입점
├── workflow-pipeline.md     # 9단계 워크플로우
├── skill-system.md          # 스킬 시스템
└── systems/                 # 시스템별 심화
    ├── overview.md          # 시스템 종합
    ├── models.md            # 모델 & 프로바이더
    ├── knowledge.md         # 지식 관리
    ├── cron.md              # 크론 자동화
    ├── backup.md            # 백업 & 복구
    └── deploy.md            # 배포 & 이미지
```
