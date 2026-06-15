# 이미지 생성 메타데이터 관리 시스템 v3.0 (JOB-1381)

## 개요

ComfyUI 로컬 + OpenRouter 외부 서비스 통합 메타데이터 관리.
**image-registry.sh v3.0** 단일 레지스트리에서 모든 이미지 생성 이력 추적.

## 아키텍처

```
┌─────────────────────────────────────────┐
│        image_registry.json (v3.0)       │
│                                         │
│  images[]                               │
│  ├─ source: comfyui|openrouter|external │
│  ├─ performance: elapsed_sec, gpu       │
│  ├─ cost: amount, currency              │
│  ├─ output: path, hash_md5, size_bytes  │
│  └─ prompt_hash: 중복 감지              │
│                                         │
│  stats{}                                │
│  ├─ by_source: {comfyui: N, ...}       │
│  ├─ by_model: {model_name: N, ...}     │
│  ├─ total_cost: float                  │
│  └─ today: {date, images, cost}        │
└─────────────────────────────────────────┘
```

## 스키마 v3.0

```json
{
  "version": "3.0",
  "images": [{
    "id": "img_YYYYMMDD_NNN",
    "created_at": "ISO8601",
    "source": "comfyui|openrouter|external",
    "model": "flux1-dev-Q4_K_S.gguf|flux.2-pro",
    "prompt": "...",
    "negative_prompt": "선택",
    "guidance": 3.5,
    "prompt_hash": "md5[:12]",
    "loras": [{"name": "...", "strength_model": 0.5, "strength_clip": 0.5}],
    "seed": 42,
    "steps": 20,
    "sampler": "euler",
    "scheduler": "karras",
    "cfg": 1.0,
    "resolution": "1024x1024",
    "output": {
      "filename": "output.png",
      "path": "/tmp/...",
      "size_bytes": 977073,
      "hash_md5": "abcdef...",
      "comfyui_filename": null,
      "url": null
    },
    "performance": {
      "elapsed_sec": 113.3,
      "gpu": "RTX 4060 Ti 8GB",
      "vram_used_gb": null,
      "backend": "comfyui-local|openrouter"
    },
    "cost": {"amount": 0.03, "currency": "USD", "model_price": null},
    "tags": [],
    "metadata": {}
  }],
  "stats": {
    "total_images": 78,
    "by_source": {"comfyui": 75, "openrouter": 2},
    "by_model": {"flux1-dev-Q4_K_S.gguf": 76},
    "total_cost": 0.03,
    "today": {"date": "YYYY-MM-DD", "images": 0, "cost": 0}
  }
}
```

## bash heredoc + Python quoting 함정

**문제**: `python3 -c "..."`에서 f-string quoting 충돌

```bash
# ❌ 실패
python3 -c "print(f'img_{datetime.now().strftime('%Y%m%d')}_{count:03d}')"

# ✅ 성공 - heredoc 사용
python3 << PYEOF
ts = datetime.now().strftime('%Y%m%d')
print(f'img_{ts}_{count:03d}')
PYEOF
```

**빈 변수 처리**:
```python
# ❌ syntax error
'guidance': $GUIDANCE if '$GUIDANCE' else None

# ✅ 명시적 타입 변환
'guidance': float('$GUIDANCE') if '$GUIDANCE' else None
```

## ComfyUI 포트 정정

**100.110.197.35:18188** (8188 아님)

서버 실행 인자: `--disable-auto-launch --port 18188`

## 마이그레이션

```bash
# v2.0 → v3.0 자동 마이그레이션
image-registry.sh migrate
```

기존 75개 이미지 자동 변환. 하위 호환 유지 (기존 명령어 동작).

## 향후 개선

1. openrouter-image-gen.sh 연동 (자동 register-v2 호출)
2. ComfyUI API 연동 (elapsed_sec 자동 측정)
3. cost-logger.sh 통합 (costs.jsonl → registry 매핑)
4. JSONL 전환 (대용량 레지스트리 대응)
