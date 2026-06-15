# Flux2-dev 모델 스펙

> JOB-1342/1432 기반 (2026-06-01 갱신)

## 개요

| 항목 | Flux2-dev | Flux2-klein-4B | Flux1-dev |
|------|-----------|---------------|-----------|
| 파라미터 | ~18B | 3.88B | 12B |
| latent 채널 | 64 (ComfyUI: 128ch input) | 64 (128ch input) | 16 |
| hidden_dim | 6144 | 3072 | 3072 |
| bf16 크기 | ~36GB | **~3.88GB** ✅ | ~24GB |
| 8GB VRAM | 불가 | 가능 | GGUF로 가능 |
| ComfyUI | ❌ | ❌ | ✅ (GGUF) |
| HuggingFace | `black-forest-labs/FLUX.2-dev` | `black-forest-labs/FLUX.2-klein-4B` | `black-forest-labs/flux1-dev` |

## 아키텍처 차이 (Flux1 vs Flux2)

Flux2는 Flux1과 호환되지 않는 근본적 아키텍처 차이:

| 항목 | Flux1 | Flux2-dev | Flux2-klein-4B |
|------|-------|-----------|---------------|
| `img_in` 차원 | 64ch | **128ch** | **128ch** |
| `txt_in` 차원 | 4096 | **7680** (T5-XXL) | **7680** |
| double_block MLP | 12288→3072 | **18432→3072** | **18432→3072** |
| single_block linear1 | 21504 | **27648** | **27648** |
| single_block linear2 | 15360 | **12288** | **12288** |
| single_blocks 수 | 38 | 38 | 20 |
| double_blocks 수 | 19 | 19 | 5 |

→ ComfyUI의 Flux1 모델 클래스로 Flux2 로딩 시 전체 텐서 차원 불일치.

## HuggingFace 리포지토리 (전부 gated: false)

| 리포 | 내용 | 형식 |
|------|------|------|
| `black-forest-labs/FLUX.2-dev` | transformer(7 shards) + text_encoder(10 shards) + VAE + `flux2-dev.safetensors` | 디렉토리 |
| `black-forest-labs/FLUX.2-klein-4B` | `flux-2-klein-4b.safetensors` | 단일 파일 |
| `black-forest-labs/FLUX.2-dev-NVFP4` | `flux2-dev-nvfp4.safetensors` + `flux2-dev-nvfp4-mixed.safetensors` | 단일 파일 |
| `gguf-org/flux2-dev-gguf` | GGUF 양자화 (cow, flux2, pig 분리) | GGUF |

## ComfyUI 호환성 (v0.22.3 기준)

**❌ Flux2 추론 불가**

| 노드 | 존재? | Flux2 동작? | 비고 |
|------|-------|------------|------|
| `UNETLoader` | ✅ | ❌ | Flux1 아키텍처에 Flux2 로딩 → `size mismatch` |
| `UnetLoaderGGUF` | ✅ | ❌ | GGUF 로딩 OK, KSampler에서 64ch 에러 |
| `DualCLIPLoaderGGUF` | ✅ | ❌ (flux type 없음) | `sd3` 타입으로 T5 우회 가능 |
| `Flux2EmptyLatentImage` | ✅ | ✅ (노드만) | ComfyUI 내장 Flux2 지원 시작됨 |
| `Flux2VAELoader` | ✅ | ✅ (노드만) | `ae.safetensors` / `flux2-vae.safetensors` |
| `Flux2TransformerLoader` | ❌ | — | 아직 존재하지 않음 |

**ai-dock 이미지 버전**: v0.2.2 (매우 구버전). 최신 v0.22.3으로 업데이트 필요.

## diffusers 호환성 (PyTorch 2.4.1 기준)

| 버전 | 상태 | 이유 |
|------|------|------|
| 0.38.0 | ❌ | `flash_attn` FP4 확장 시그니처(`q_descale, k_descale, v_descale, qv`)와 충돌 → `TypeError` |
| 0.29.2 | ❌ | `FluxPipeline` 존재하지 않음 |
| **0.30.3** | ✅ | 임포트 성공, 단 Flux2 단일 safetensors는 `from_pretrained()` 불가 |

## Klein-4B 상세

```
Total keys: 149
hidden_dim: 3072
dtype: torch.bfloat16
double_blocks: 5개 (0-4)
single_blocks: 20개 (0-19)
VRAM (bf16): ~3.88GB → 8GB RTX 4060 Ti에서 로딩 성공 확인
```

## NVFP4 (NVIDIA FP4 사전 양자화)

- 단일 safetensors (diffusers `model_index.json` 없음)
- `FluxPipeline.from_pretrained()` 불가 (404 에러)
- 별도 커스텀 로더 필요
