# Model System

다중 LLM 프로바이더를 관리하고, 워크플로우 단계별로 최적의 모델을 라우팅합니다.

---

## Overview

| 항목 | 값 |
|------|-----|
| SSOT | `catalog.json` |
| 경로 | `skills/custom/model-catalog/` |
| 총 모델 | 20개 |
| 프로바이더 | 3개 (Airrouter, Z.AI, OpenRouter) |
| 라우팅 | workflow-gate 연동 |

---

## 프로바이더 구성

### Airrouter (3 모델)

기본 엔드포인트입니다. 저지연, 고가용성.

```json
{
  "provider": "airrouter",
  "base_url": "https://api.airouter.ch/v1",
  "models": [
    { "name": "Qwen3.6", "role": "default", "priority": 1 },
    { "name": "Gemma-4", "role": "design", "priority": 2 },
    { "name": "Claude-Sonnet-4-5", "role": "analysis", "priority": 3 }
  ]
}
```

### Z.AI (4 모델)

대용량 처리에 특화된 프로바이더입니다.

```json
{
  "provider": "z_ai",
  "base_url": "https://api.z.ai/v1",
  "models": [ ... ]
}
```

### OpenRouter (13 모델)

가장 다양한 모델 접근을 제공합니다.

```json
{
  "provider": "openrouter",
  "base_url": "https://openrouter.ai/api/v1",
  "models": [ ... ]
}
```

---

## 모델 라우팅

워크플로우의 각 단계에서 `workflow-gate.sh`가 최적의 모델을 선택합니다.

### 라우팅 매핑

| 단계 | 모델 | 이유 |
|------|------|------|
| request | Qwen3.6 | 빠른 응답 |
| investigation | Qwen3.6 | 종합적 조사 |
| design | **Gemma-4** | 설계 특화 |
| review | **Claude-Sonnet-4-5** | 비판적 검토 |
| approval | Qwen3.6 | 결정력 |
| execution | Qwen3.6 | 고성능 |
| test | Qwen3.6 | 정밀 검증 |
| execution_review | Qwen3.6 | 종합 검토 |

### 라우팅 프로세스

```
workflow-gate.sh 호출
  → .workflow-state 읽기
  → 현재 단계 확인
  → catalog.json에서 해당 단계 모델 조회
  → 모델 전환 (필요 시)
  → 작업 계속
```

---

## Fallback 메커니즘

### Fallback 순서

```
1. Primary 모델 호출
   ↓ 실패
2. Secondary 모델 호출 (동일 프로바이더)
   ↓ 실패
3. Tertiary 모델 호출 (다른 프로바이더)
   ↓ 실패
4. 에러 리포트 + 작업 일시 정지
```

### 실패 원인

| 원인 | 처리 |
|------|------|
| Timeout | 재시도 (최대 3회) |
| Rate Limit | 백오프 (지수 증가) |
| 5xx Error | Fallback 모델 전환 |
| Invalid Response | 재시도 |

---

## 비용 추적

모든 API 호출에 대해 로깅됩니다:

```json
{
  "timestamp": "2026-06-13T00:00:00Z",
  "job_id": "JOB-XXXX",
  "step": "design",
  "model": "Gemma-4",
  "provider": "airrouter",
  "input_tokens": 1250,
  "output_tokens": 3400,
  "cost": 0.012,
  "duration_ms": 4500
}
```

---

## catalog.json 완전 구조

```json
{
  "version": "1.0",
  "providers": {
    "airrouter": {
      "base_url": "https://api.airouter.ch/v1",
      "models": [
        { "name": "Qwen3.6", "role": "default" },
        { "name": "Gemma-4", "role": "design" },
        { "name": "Claude-Sonnet-4-5", "role": "analysis" }
      ]
    },
    "z_ai": {
      "base_url": "https://api.z.ai/v1",
      "models": [ ... ]
    },
    "openrouter": {
      "base_url": "https://openrouter.ai/api/v1",
      "models": [ ... ]
    }
  },
  "routing": {
    "request": "Qwen3.6",
    "investigation": "Qwen3.6",
    "design": "Gemma-4",
    "review": "Claude-Sonnet-4-5",
    "approval": "Qwen3.6",
    "execution": "Qwen3.6",
    "test": "Qwen3.6",
    "execution_review": "Qwen3.6"
  },
  "fallback": {
    "Qwen3.6": ["Gemma-4", "Claude-Sonnet-4-5"],
    "Gemma-4": ["Qwen3.6"],
    "Claude-Sonnet-4-5": ["Qwen3.6"]
  }
}
```

---

## 참조

- [ARCHITECTURE.md](../ARCHITECTURE.md) — 전체 아키텍처
- [docs/layer1-core-engine.md](../layer1-core-engine.md) — Layer 1 (Core Engine)
- [docs/systems/overview.md](overview.md) — 시스템 종합
