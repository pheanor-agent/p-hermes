# ComfyUI-GGUF Custom Node Troubleshooting

## GGUF Package Missing (JOB-1167)

**Symptom**: ComfyUI-GGUF custom node shows `(IMPORT FAILED)` in startup logs.

**Error**:
```
ModuleNotFoundError: No module named 'gguf'
Cannot import /opt/ComfyUI/custom_nodes/ComfyUI-GGUF module for custom nodes: No module named 'gguf'
```

**Root Cause**: The `ComfyUI-GGUF` custom node requires the `gguf` Python package, which is NOT auto-installed by ai-dock images or ComfyUI Manager.

**Fix** (ai-dock Docker containers):
```bash
# Install gguf package in ComfyUI Python environment
docker exec <container> bash -c "source /opt/environments/python/comfyui/bin/activate && pip install gguf"

# Restart container
docker restart <container>
```

**Verification**: Check ComfyUI logs for successful import:
```
Import times for custom nodes:
   0.1 seconds: /opt/ComfyUI/custom_nodes/ComfyUI-GGUF
```

After fix, `/api/object_info` should show: `UnetLoaderGGUF`, `CLIPLoaderGGUF`, `DualCLIPLoaderGGUF`, `TripleCLIPLoaderGGUF`, `QuadrupleCLIPLoaderGGUF`, `UnetLoaderGGUFAdvanced`

---

## Flux2 Klein GGUF — VAE 32ch 아키텍처 호환성 문제 (2026-05-23 심층 분석)

**⚠️ 상태**: ComfyUI-GGUF 공식 미지원. **커스텀 VAE 노드 제작이 유일한 해결책.**

### 증상
```
RuntimeError: Error(s) in loading state_dict for AutoencoderKL:
  size mismatch for quant_conv.weight: [64, 64, 1, 1] vs [8, 64, 1, 1]
  size mismatch for post_quant_conv.weight: [32, 32, 1, 1] vs [32, 4, 1, 1]
```

### 근본 원인 (아키텍처 차원 불일치)

VAE 파일이 잘못된 것이 아님. **ComfyUI 표준 VAE 로더가 Flux2 아키텍처를 모른다.**

| 구성 요소 | 표준 VAE (Flux1) | Flux2 VAE (AutoencoderKLFlux2) |
|-----------|-----------------|--------------------------------|
| **latent_channels** | 4 | **32** |
| **block_out_channels** | (64, 64, 320, 320, 640, 640) | **(128, 256, 512, 512)** |
| **quant_conv** | `Conv2d(8, 8, 1)` | **`Conv2d(64, 64, 1)`** |
| **post_quant_conv** | `Conv2d(4, 4, 1)` | **`Conv2d(32, 32, 1)`** |

### GitHub 이슈 (2026-05-23 기준)
- **#411** (Closed): 동일한 에러, 해결 안됨
- **#367** (Closed ✅): **FLUX.2 dev (32B) 지원 완료** — https://huggingface.co/city96/FLUX.2-dev-gguf

### 커스텀 VAE 노드 제작 방안 (JOB-1262)

**해결책**: `diffusers`의 `AutoencoderKLFlux2` 클래스를 활용하는 ComfyUI 커스텀 노드 제작.

```python
from diffusers.models.autoencoders.autoencoder_kl_flux2 import AutoencoderKLFlux2

FLUX2_VAE_CONFIG = {
    "latent_channels": 32,  # ← 핵심!
    "block_out_channels": (128, 256, 512, 512),
    "norm_num_groups": 32,
    "sample_size": 1024,
}
vae = AutoencoderKLFlux2(**FLUX2_VAE_CONFIG)
vae.load_state_dict(load_safetensors("flux2-vae.safetensors"))
```

**JOB-1262 진행**: `~/.hermes/workspace/jobs/JOB-1262-Flux2-Klein-VAE-커스텀-로더-노드-설계-및-제작/`
- `investigation.md`: 심층 조사 보고서
- `design.md`: 커스텀 노드 상세 설계서

### 커스텀 노드 구현 (JOB-1262 구현 완료)

**코드 위치**: `~/.hermes/workspace/projects/comfyui-flux2-vae-loader/`

**핵심 구현**:
```python
# flux2_vae_loader.py - AutoencoderKLFlux2 기반 VAE 디코드
from diffusers.models.autoencoders.autoencoder_kl_flux2 import AutoencoderKLFlux2

FLUX2_VAE_CONFIG = {
    "latent_channels": 32,
    "block_out_channels": (128, 256, 512, 512),
    "norm_num_groups": 32,
    "sample_size": 1024,
    # ... complete config in source
}

# 스케일링: Flux2专用 scaling_factor=0.18215, shift=0.5
scaled = latent / 0.18215 + 0.5
image = vae.decode(scaled).sample
```

**배포 방법** (Docker 볼륨 마운트 활용):
- docker-compose.yml의 `./custom_nodes:/opt/ComfyUI/custom_nodes` 마운트 활용
- Windows 호스트 `custom_nodes/ComfyUI-Flux2-VAE-Loader/`에 파일 2개만 복사
- `docker exec comfyui-sandbox pip install diffusers safetensors`
- `docker restart comfyui-sandbox`

**SSH 불가 상황**: ComfyUI 서버에서 SSH(port 22) 차단 시 docker-compose 볼륨 마운트를 통한 파일 복사 필요

### 대안
1. **Flux1 GGUF** (즉시 사용) — `flux1-dev-Q4_K_S.gguf` + `ae.safetensors`
2. **FLUX.2 dev GGUF** — 공식 지원, 32B 모델 (VRAM 요구량 높음)
3. **Z-Image Turbo** — ComfyUI 공식 지원, 8GB VRAM 호환

---

## VAE Compatibility Issues

### Flux2 Klein 32ch VAE — 커스텀 로더 노드 제작 중 (JOB-1262)
Flux2 Klein은 32차원 레이턴트 스페이스 사용 → 표준 VAE 로더와 차원 불일치.
**해결**: `diffusers.AutoencoderKLFlux2` 기반 커스텀 ComfyUI 노드 제작.
**상세**: `references/gguf-troubleshooting.md` § Flux2 Klein GGUF — VAE 32ch 아키텍처 호환성 문제
**설계서**: `~/.hermes/workspace/jobs/JOB-1262-Flux2-Klein-VAE-커스텀-로더-노드-설계-및-제작/design.md`

---

## Flux2-dev GGUF — ComfyUI-GGUF 미지원 확인 (JOB-1432)

### 상태 (2026-06-01)
ComfyUI-GGUF(city96)에서 **Flux2-dev GGUF는 로딩은 되지만 추론 불가**.

### 근본 원인
- `IMG_ARCH_LIST`에 `"flux"`만 있고 `"flux2"` 없음 (loader.py)
- Flux2 GGUF 메타데이터의 `general.architecture`이 `"flux"`로 기록됨 → 노드가 Flux1으로 인식
- **Flux1 = 16채널 latent, Flux2 = 64채널 latent** → ComfyUI의 `ldm/flux/model.py` Flux1 아키텍처로 Flux2 추론 시 차원 불일치
- 에러: `mat1 and mat2 shapes cannot be multiplied (1024x64 and 128x6144)`

### HuggingFace Flux2 리포지토리
| 리포 | 형식 | diffusers 호환 |
|------|------|---------------|
| `black-forest-labs/FLUX.2-dev` | 단일 `flux2-dev.safetensors` + `ae.safetensors` + text_encoder 분할 | ❌ model_index.json 없음 |
| `black-forest-labs/FLUX.2-dev-NVFP4` | 단일 `flux2-dev-nvfp4.safetensors` (NVIDIA FP4) | ❌ 단일 파일, diffusers 아님 |
| `black-forest-labs/FLUX.2-klein-4B` | 단일 `flux-2-klein-4b.safetensors` | ❌ |

모두 gated=false (접근 권한 없음), 직접 다운로드 가능.

### diffusers 버전 호환성 (ai-dock: PyTorch 2.4.1)
| diffusers 버전 | 결과 |
|----------------|------|
| 0.38.0 | ❌ `infer_schema` ValueError (torch.Tensor type annotation 호환 불가) |
| 0.30.3 | ✅ FluxPipeline import 가능, PyTorch 2.4.1 호환 |
| <0.30 | ❌ FluxPipeline 없음 |

### Flux2 추론 대안
1. **NVFP4 단일 파일 로딩** — `safetensors.load_file()` 후 커스텀 PyTorch 모델로 로딩
2. **diffusers 최신 파이프라인** — PyTorch 업그레이드 필요 (현재 2.4.1, TRT 11.0은 cu13 요구)
3. **ComfyUI Flux2 공식 지원 대기** — 아직 미구현

---

## ai-dock Docker venv 패키지 설치 패턴 (JOB-1432)

### 문제
ai-dock ComfyUI 이미지는 **3개의 격리된 venv**를 사용:
- `/opt/environments/python/comfyui/` — ComfyUI 메인 프로세스
- `/opt/environments/python/api/` — FastAPI 서비스
- `/opt/environments/python/jupyter/` — Jupyter Notebook

`pip install` (루트) 또는 `python3 -m pip install`은 시스템 Python에 설치. ComfyUI는 이를 보지 못함.

### 정확한 설치 명령어
```bash
# ComfyUI venv에 직접 설치 (항상 이 방식)
docker exec <container> /opt/environments/python/comfyui/bin/pip install <package>

# 확인
docker exec <container> /opt/environments/python/comfyui/bin/python -c "import <module>"
```

### 주의: PowerShell에서 bash 변수 사용 금지
PowerShell의 `$VAR`가 PowerShell 변수로 해석됨. bash 변수가 필요한 경우:
```powershell
# ❌ 틀림: $COMFYUI_VENV가 PowerShell에서 해석됨
docker exec comfyui-sandbox bash -c "... $COMFYUI_VENV/bin/pip ..."

# ✅ 맞음: 직접 경로 지정
docker exec comfyui-sandbox /opt/environments/python/comfyui/bin/pip install gguf
```

---

## Workflow JSON Format Issues

**Problem**: Comment keys in workflow JSON (e.g., `"_comment": "..."`) are treated as node IDs by ComfyUI API.

**Error**: `"Cannot execute because a node is missing the class_type property."` (HTTP 400)

**Fix**: Remove all non-numeric keys or keys starting with `#` from workflow JSON before API submission. Re-export from ComfyUI Web UI using "Workflow → Export (API)" to get clean format.
