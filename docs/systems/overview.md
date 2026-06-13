# Systems Overview — Hermes Agent

Hermes Agent는 9개 핵심 시스템으로 구성됩니다. 이 문서는 각 시스템의 구조와 연계 관계를 종합적으로 설명합니다.

---

## 시스템 목록

| # | 시스템 | SSOT | 경로 | 역할 |
|---|--------|------|------|------|
| 1 | **JOB** | `.workflow-state` | `workspace/jobs/` | 9단계 워크플로우 |
| 2 | **Knowledge** | `wiki/index.md` | `knowledge/` | Wiki/T1-T3, References |
| 3 | **Cron** | `registry.yaml` | `cron/` | 주기 작업 자동화 |
| 4 | **Model** | `catalog.json` | `skills/custom/model-catalog/` | 다중 모델 라우팅 |
| 5 | **Backup** | — | `backups/` | Tier 1/2 백업 |
| 6 | **Deploy** | — | `scripts/image-gen/` | ComfyUI, GPU 관리 |
| 7 | **SpecDev** | `_index.yaml` | `projects/*/specs/` | 사양서 검증 |
| 8 | **Event Bus** | `event.sh` | `events/bus/` | 시스템 간 이벤트 |
| 9 | **Express** | `SKILL.md` | `skills/custom/expression-system/` | 표현력/콘텐츠 라우팅 |

---

## 시스템 간 연계 매트릭스

```
JOB ───→ Knowledge     (JOB 완료 시 sync)
JOB ───→ Backup        (파일 삭제 전)
Cron ───→ JOB          (주기 작업 등록)
Cron ───→ Knowledge    (지식 파이프라인)
Cron ───→ Backup       (Tier 1/2 실행)
Cron ───→ Deploy       (GPU health check 15m)
Model ──→ JOB          (workflow-gate 단계별 전환)
Model ──→ Express      (Model Selector 매핑)
Express→ Deploy       (D5 이미지 → ComfyUI)
SpecDev→ JOB          (Spec 체크포인트 검증)
SpecDev→ Knowledge    (knowledge/index.md 등록)
Deploy ← Cron         (GPU health check)
JOB    → Event Bus    (상태 전이 시 emit)
Cron   → Event Bus    (작업 완료 시 emit)
Verify → Event Bus    (검증 완료 시 emit)
Knowledge → Event Bus (인덱싱 완료 시 emit)
```

### 상세 매트릭스

| From → To | 방식 | 자동화 스크립트 |
|-----------|------|----------------|
| 작업 → 지식 | JOB 완료 시 sync | `on-job-complete.sh` |
| 작업 → 백업 | 파일 삭제 전 | `pre-delete-backup.sh` |
| 작업 ← 크론 | 주기 작업 JOB 등록 | registry.yaml |
| 지식 ← 크론 | 지식 파이프라인 | daily-knowledge.sh |
| 백업 ← 크론 | Tier 1/2 실행 | crontab |
| 모델 → 작업 | workflow-gate 단계별 전환 | 자동 |
| 모델 → 표현력 | Model Selector 매핑 | 자동 |
| 표현력 → 배포 | D5 이미지→ComfyUI | 자동 |
| 사양서 → 작업 | Spec 체크포인트 검증 | workflow-gate |
| 사양서 → 지식 | knowledge/index.md 등록 | 자동 |
| 배포 ← 크론 | GPU health check | 15m 간격 |
| 작업 → 이벤트 버스 | 상태 전이 시 emit | workflow-gate.sh |
| 크론 → 이벤트 버스 | 작업 완료 시 emit | cron-wrapper.sh |
| 검증 → 이벤트 버스 | 검증 완료 시 emit | verify.sh |
| 지식 → 이벤트 버스 | 인덱싱 완료 시 emit | daily-knowledge.sh |

---

## 각 시스템 문서

| 시스템 | 문서 |
|--------|------|
| JOB | [docs/workflow-pipeline.md](workflow-pipeline.md) |
| Knowledge | [docs/systems/knowledge.md](knowledge.md) |
| Cron | [docs/systems/cron.md](cron.md) |
| Model | [docs/systems/models.md](models.md) |
| Backup | [docs/systems/backup.md](backup.md) |
| Deploy | [docs/systems/deploy.md](deploy.md) |
| SpecDev | [docs/layer1-core-engine.md](layer1-core-engine.md) §2.3.7 |
| Event Bus | [docs/systems/overview.md](overview.md) §이벤트 버스 |
| Express | [docs/layer3-integration.md](layer3-integration.md) §Express |

---

## 이벤트 버스 상세

모든 시스템 간 이벤트 중재는 Event Bus 시스템을 통합니다.

### 이벤트 타입

| 이벤트 | 발행자 | 구독자 |
|--------|--------|--------|
| `wf.started` | workflow-gate.sh | 모니터링 |
| `wf.state_changed` | workflow-gate.sh | Knowledge, Cron |
| `wf.completed` | on-job-complete.sh | Knowledge (Lessons) |
| `wf.auto_processed` | workflow-gate.sh | Monitoring |
| `monitor.verify` | verify.sh | Alert |
| `knowledge.indexed` | daily-knowledge.sh | Wiki |

### 이벤트 발행

```bash
# event.sh 라이브러리
source skills/shared/system-common/lib/event.sh

# 이벤트 발행
emit_event "wf.completed" "{\"job\": \"JOB-1542\", \"step\": 8}"
```

### 폴백 메커니즘

크로스 파일 시스템 환경에서 3단계 폴백:

```bash
# 1. mv -n (atomic, 충돌 방지)
# 2. install -b (백업 생성)
# 3. cp + mv (최종 폴백)
```

---

## 참조

- [ARCHITECTURE.md](../ARCHITECTURE.md) — 전체 아키텍처
- [README.md](../README.md) — 시스템 개요
