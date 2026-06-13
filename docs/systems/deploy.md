# Deploy System

ComfyUI, GPU 관리, Pod 관리를 담당하는 배포 시스템입니다.

---

## Overview

| 항목 | 값 |
|------|-----|
| 경로 | `scripts/image-gen/` |
| 이미지 엔진 | ComfyUI (로컬), OpenRouter (클라우드) |
| GPU Health | 15분 간격 체크 |
| Pod 관리 | `pod-manager.sh` |

---

## 구성 요소

| 구성 요소 | 역할 |
|-----------|------|
| ComfyUI | 로컬 이미지 생성 파이프라인 |
| OpenRouter | 클라우드 이미지 모델 (Flux.2, Seedream) |
| GPU Health Check | GPU 리소스 모니터링 |
| Pod Manager | 컨테이너/Pod 생명주기 관리 |
| Deploy Script | 배포 자동화 |

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

## OpenRouter 이미지 모델

클라우드 기반 이미지 모델입니다. ComfyUI가 사용 불가 시 폴백됩니다.

| 모델 | 특징 |
|------|------|
| Flux.2 | 고화질, 빠른 생성 |
| Seedream | 스타일 기반 |

---

## GPU Health Check

15분 간격으로 GPU 상태를 모니터링합니다.

### gpu-health-check.sh

```bash
#!/bin/bash
# GPU 헬스 체크
# 15분 간격 실행 (Cron 연동)

# GPU 메모리 사용량 확인
GPU_MEM=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits 2>/dev/null)
GPU_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null)

echo "$(date): GPU Mem=${GPU_MEM}MB, Temp=${GPU_TEMP}°C" >> "$HOME/.hermes/cron/history/gpu-health/$(date +%Y-%m-%d).log"

# 임계값 초과 시 알림
if [ "$GPU_MEM" -gt 7000 ] 2>/dev/null; then
    emit_event "monitor.verify" "{\"gpu_mem\": $GPU_MEM, \"status\": \"warning\"}"
fi
```

---

## Pod Manager

### pod-manager.sh

```bash
#!/bin/bash
# Pod/컨테이너 관리
# 사용법: pod-manager.sh [start|stop|restart|status] <pod-name>

ACTION="${1:?액션 필수 (start|stop|restart|status)}"
POD="${2:?Pod 이름 필수}"

case "$ACTION" in
    start)
        # Pod 시작
        echo "✅ $POD started"
        ;;
    stop)
        # Pod 중지
        echo "✅ $POD stopped"
        ;;
    restart)
        # Pod 재시작
        echo "✅ $POD restarted"
        ;;
    status)
        # Pod 상태 확인
        echo "📊 $POD status"
        ;;
    *)
        echo "❌ Unknown action: $ACTION"
        exit 1
        ;;
esac
```

---

## Deploy Script

### deploy.sh

```bash
#!/bin/bash
# 배포 자동화
# 사용법: deploy.sh [--target <production|staging>]

TARGET="${1:-staging}"

# 1. 사전 체크
echo "🔍 사전 체크..."
bash gpu-health-check.sh

# 2. ComfyUI 상태 확인
if curl -s http://localhost:8188/system_stats > /dev/null; then
    echo "✅ ComfyUI 가동 중"
else
    echo "⚠️ ComfyUI 중지 — OpenRouter 폴백"
fi

# 3. 배포
echo "🚀 $TARGET 배포..."

echo "✅ 배포 완료"
```

---

## Cron 연동

| Cron 작업 | 간격 | 역할 |
|-----------|------|------|
| gpu-health-check | 15분 | GPU 리소스 모니터링 |
| deploy-check | 주기적 | 배포 상태 확인 |

---

## 참조

- [시스템 종합](overview.md) — 전체 시스템 현황
- [인덱스](../index.md) — 문서 탐색
