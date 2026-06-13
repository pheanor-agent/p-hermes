# 시스템 종합

Hermes Agent 시스템의 현재 상태와 각 구성 요소로의 연결점입니다.

---

## 시스템 현황

| 시스템 | 상태 | 설명 |
|--------|------|------|
| 모델 | ✅ 활성 | 다중 프로바이더 (3개), 20개 모델, Fallback 지원 |
| 지식 | ✅ 활성 | Wiki (domain/tag 기반), References (210개), Lessons |
| 크론 | ✅ 활성 | 주기 작업 (system_crontab + cron_jobs), no-agent 모드 |
| 백업 | ✅ 활성 | Tier 1 (Hot Snapshot), Tier 2 (Warm Archive), pre-delete-backup |
| 배포 | ✅ 활성 | ComfyUI 자동화, GPU Health, Pod 관리 |
| 스킬 | ✅ 활성 | 146개 스킬, 카테고리 기반 |
| 워크플로우 | ✅ 활성 | 9단계 파이프라인 |
| 메시지 | ✅ 활성 | Discord, Telegram 연동 |
| 이미지 | ✅ 활성 | Flux.2 Pro 기본 |

---

## 탐색 시나리오

### 개발자

새 작업에 필요한 모델 정보를 찾고 있다면 → [systems/models.md](systems/models.md)
스킬을 추가하거나 수정한다면 → [skill-system.md](../skill-system.md)
작업 흐름을 알고 싶다면 → [workflow-pipeline.md](../workflow-pipeline.md)

### 운영자

주기 작업을 확인한다면 → [systems/cron.md](systems/cron.md)
백업 상태를 점검한다면 → [systems/backup.md](systems/backup.md)
배포 파이프라인을 확인한다면 → [systems/deploy.md](systems/deploy.md)

### 에이전트

지식 시스템 구조를 이해한다면 → [systems/knowledge.md](systems/knowledge.md)
워크플로우 규칙을 확인한다면 → [workflow-pipeline.md](../workflow-pipeline.md)

---

## 시스템 간 연계

| From → To | 연계 방식 |
|-----------|----------|
| 워크플로우 → 크론 | JOB 완료 후 `on-job-complete.sh` 실행 |
| 워크플로우 → 지식 | Lessons 자동 생성, Wiki 업데이트 |
| 모델 → 스킬 | catalog.json 기반 라우팅 |
| 크론 → 백업 | 주기적 Tier 1/2 백업 실행 |
| 배포 → 모델 | ComfyUI ↔ OpenRouter Fallback |
