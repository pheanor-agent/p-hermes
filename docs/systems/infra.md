# 인프라 시스템 (Infra)

GPU/ComfyUI 물리적 실행 환경을 관리하는 시스템입니다.

---

## Overview

| 항목 | 값 |
|------|-----|
| 경로 | `infra/image-gen/` |
| 총 파일 | 17개 |
| 이미지 엔진 | ComfyUI (로컬), OpenRouter (클라우드 폴백) |
| 상태 모니터링 | 1시간 간격 (health-check.sh) |
| 비용 모니터링 | 09:00 일일 (cost-monitor.sh) |

---

## 4개 구성 요소

```
┌─────────────────────────────────────────────────┐
│              인프라 시스템 (infra/)               │
├─────────────────────────────────────────────────┤
│                                                  │
│  ┌──────────────┐  ┌──────────────┐            │
│  │ 상태 모니터링 │  │ 인스턴스 관리 │            │
│  │              │  │              │            │
│  │ health-check │  │ runpod_client│            │
│  │ cost-monitor │  │ vast_client  │            │
│  │ cost_tracker │  │ instance_mgr │            │
│  └──────────────┘  └──────────────┘            │
│                                                  │
│  ┌──────────────┐  ┌──────────────┐            │
│  │ 자동화        │  │ 상태 관리     │            │
│  │              │  │              │            │
│  │ auto-comfyui │  │ state_machine│            │
│  │ on_demand_gpu│  │ comfyui_api  │            │
│  └──────────────┘  └──────────────┘            │
│                                                  │
└─────────────────────────────────────────────────┘
```

### 구성 요소 ↔ 실제 파일 매핑

| 구성 요소 | 파일 | 책임 | Cron |
|-----------|------|------|------|
| **상태 모니터링** | health-check.sh, cost-monitor.sh, cost_tracker.py | ComfyUI 상태 감시 + 비용 추적 | 1h / 09:00 |
| **인스턴스 관리** | runpod_client.py, vast_client.py, instance_manager.py | RunPod/Vast.ai Pod 생성/중지/상태 | - |
| **자동화** | auto-comfyui.py, on_demand_gpu.py, auto-start-instance.sh | 이미지 생성 요청 시 자동 인프라 준비 | - |
| **상태 관리** | state_machine.py, comfyui_api.py, comfyui_oci.py | 상태 머신 (idle→running→error) + API | - |
| **설치/정리** | install-comfyui.sh, start-comfyui.sh, cleanup.sh | ComfyUI 설치/시작/정리 | - |
| **참조** | vastai-guide.md | Vast.ai 사용 가이드 | - |

---

## ComfyUI

로컬 GPU에서 이미지 생성을 수행합니다.

### 워크플로우

```
ComfyUI
  ├── 모델 로딩 (SDXL, Flux 등)
  ├── 노드 기반 파이프라인
  ├── 이미지 생성
  └── 출력 (PNG)
```

### 상태 확인

```bash
# ComfyUI 상태 확인
curl -s http://localhost:8188/system_stats | jq '.status'
```

---

## OpenRouter 이미지 모델 (폴백)

클라우드 기반 이미지 모델입니다. ComfyUI가 사용 불가 시 폴백됩니다.

| 모델 | 특징 |
|------|------|
| Flux.2 | 고화질, 빠른 생성 |
| Seedream | 스타일 기반 |

**폴백 진입점**: `core/scripts/openrouter-image-gen.sh` (도메인 계층)

---

## Cron 연동

| Cron 작업 | 간격 | 역할 | 스크립트 |
|-----------|------|------|----------|
| 헬스체크 | 1시간 | ComfyUI 상태 모니터링 | infra/image-gen/health-check.sh |
| 비용 모니터링 | 09:00 일일 | API 비용 추적 | infra/image-gen/cost-monitor.sh |
| 이미지 관리 | 5분 | ComfyUI 감시 + 정리 + 레지스트리 | openclaw/scripts/image-all.sh |

---

## 모델 시스템 연계

인프라는 모델 시스템과 별도 관심사를 가집니다.

| 구분 | 모델 시스템 | 인프라 시스템 |
|------|-------------|---------------|
| 역할 | Provider/모델 카탈로그 | GPU/ComfyUI 물리적 실행 환경 |
| SSOT | catalog.json | infra/image-gen/ |
| 관심사 | "어떤 모델 사용할까" | "어떻게 실행할까" |

**연계**: Flux.2 Pro 모델 선택 → ComfyUI 자동 호출

---

## 참조

- [시스템 종합](overview.md) — 전체 시스템 현황
- [인덱스](../index.md) — 문서 탐색
