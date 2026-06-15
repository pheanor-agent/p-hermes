# Flux2 Local Inference (Outside ComfyUI)

ComfyUI가 Flux2를 로컬 로딩할 수 없을 때 사용하는 대안 경로.

## 왜 ComfyUI 밖에서?

ComfyUI UNETLoader는 Flux1 아키텍처만 지원. Flux2는 `img_in` 128ch vs Flux1 64ch 불일치.
Flux2 Partner Nodes(`Flux2ImageNode` 등)는 BFL 클라우드 API 기반, 로컬 모델 로딩 아님.

## ⚠️ 워크플로우 원칙

- **공식 CLI를 먼저 사용** — 수동 파이프라인 구성은 최후 수단
- 이미 작동하는 공식 도구가 있으면 반복 테스트로 파이프라인 수동 조립하지 말 것
- 사용자가 "계속 이런식으로 테스트 해야해?"라고 지적 → 기존 도구 활용 우선
- Hermes가 Docker에 직접 접근 불가한 환경이면, 원라이너 스크립트를 작성해 사용자에게 한 번만 복붙 요청
- **⚠️ ComfyUI로 되돌아가지 말 것** — Flux2 로컬 로딩 불가 확인 후 다른 경로로 전환했으면 ComfyUI 언급 금지. 사용자가 "왜 또 ComfyUI?" 지적.

## 공식 inference 코드

**Repo**: `https://github.com/black-forest-labs/flux2`

### 설치 (ai-dock Docker 내)

**⚠️ 별도 venv 필수** — flux2는 torch 2.8.0, ComfyUI는 torch 2.4.1 (xformers 0.0.28 호환)
```bash
# flux2 전용 venv 생성
docker exec comfyui-sandbox bash -c "python3 -m venv /opt/environments/python/flux2"

# torch 먼저 설치 (pyproject.toml이 torch==2.8.0 강제)
docker exec comfyui-sandbox /opt/environments/python/flux2/bin/pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121

# flux2 설치 (이때 torch 2.8.0으로 업그레이드됨 — venv 분리되어 ComfyUI 영향 없음)
docker exec comfyui-sandbox bash -c "cd /opt/flux2 && /opt/environments/python/flux2/bin/pip install -e ."
```

### 공식 CLI (`/opt/flux2/scripts/cli.py`)

**⚠️ CLI는 `flux` 바이너리가 아님** — Python 스크립트 직접 실행

```bash
docker exec comfyui-sandbox bash -c "
  KLEIN_4B_MODEL_PATH=/opt/ComfyUI/models/unet/flux-2-klein-4b.safetensors \
  AE_MODEL_PATH=/opt/ComfyUI/models/vae/flux2-vae.safetensors \
  /opt/environments/python/flux2/bin/python /opt/flux2/scripts/cli.py flux.2-klein-4b \
    width=512 height=512 prompt='a beautiful sunset'
"
```

**⚠️ CLI OOM 버그 (2026-06-01 확인)**: `flux.2-klein-4b` 지정 시에도 CLI가 `flux.2-dev`의 Mistral3-24B 텍스트 인코더(48GB)를 로드하려 시도 → 8GB VRAM 환경에서 CLI 직접 사용 불가.

### 모델 구성표

| 모델 | Transformer | 텍스트 인코더 | VRAM 권장 | RAM 권장 | steps | guidance |
|------|------------|-------------|----------|---------|-------|---------|
| Klein-4B (distilled) | 3.88B, bf16 | Qwen3-4B-FP8 (~4GB) | 4GB | 8GB | 4 (고정) | 1.0 (고정) |
| Klein-Base-4B | 3.88B, bf16 | Qwen3-4B-FP8 (~4GB) | 4GB | 8GB | 50 | 4.0 |
| Klein-9B (distilled) | 9B | Qwen3-8B (~16GB) | 8GB | 16GB | 4 (고정) | 1.0 (고정) |
| Flux2-dev | 32B | Mistral3-24B (~48GB) | 24GB+ | 64GB+ | 50 | 4.0 |

### 8GB VRAM + 64GB RAM 구성 (Klein-4B, CPU 오프로딩)

| 해상도 | 스텝 | 시간 | 비고 |
|--------|------|------|------|
| 512x512 | 4 | ~67-168s | ✅ 디퓨전 생성 검증됨. Latent std≈0.99 |
| 1024x1024 | 4 | ~400s 추정 | 메모리 4배, 미검증 |

### 핵심 아키텍처 상수 (Klein-4B)

```python
@dataclass
class Klein4BParams:
    in_channels: int = 128       # Flux1은 64
    context_in_dim: int = 7680   # Qwen3-4B 출력 차원
    hidden_size: int = 3072
    num_heads: int = 24
    depth: int = 5                # double_blocks
    depth_single_blocks: int = 20 # single_blocks
    use_guidance_embed: bool = False
```

## ✅ 검증된 디퓨전 파이프라인 (2026-06-01)

**⚠️ 현재 상태**: 디퓨전 생성 ✅ 검증됨, VAE 디코딩 ❌ 채널 불일치로 차단

**노이즈 문제 해결**: 단순 tokenizer가 원인 → `apply_chat_template` + `enable_thinking=False` + `attention_mask` 필수.

### 완전한 실행 가능한 스크립트 (512x512, 4steps, ~67-168초)

```python
import os, torch, time
os.environ["KLEIN_4B_MODEL_PATH"] = "/opt/ComfyUI/models/unet/flux-2-klein-4b.safetensors"

from flux2.util import load_flow_model
from flux2.autoencoder import AutoEncoder, AutoEncoderParams
from transformers import AutoModelForCausalLM, AutoTokenizer
from einops import rearrange
from safetensors.torch import load_file as load_sft

# 1. 모델 로드
tokenizer = AutoTokenizer.from_pretrained("Qwen/Qwen3-4B")
te_model = AutoModelForCausalLM.from_pretrained("Qwen/Qwen3-4B", torch_dtype=torch.bfloat16, device_map="cpu")
flow_model = load_flow_model("flux.2-klein-4b", device="cpu")

# ⚠️ VAE는 32ch 체크포인트만 존재 — 128ch 모델과 불일치 (아래 VAE 절 참조)
ae = AutoEncoder(AutoEncoderParams()).to(torch.bfloat16).to("cpu")
sd = load_sft("/opt/ComfyUI/models/vae/flux2-vae.safetensors", device="cpu")
ae.load_state_dict(sd, strict=False)
ae = ae.to("cuda")

# 2. 텍스트 인코딩 (핵심! apply_chat_template 필수)
messages = [{"role": "user", "content": "a beautiful sunset over mountains"}]
text = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True, enable_thinking=False)
model_inputs = tokenizer(text, return_tensors="pt", padding="max_length", truncation=True, max_length=512)
with torch.no_grad():
    output = te_model(input_ids=model_inputs["input_ids"], attention_mask=model_inputs["attention_mask"], output_hidden_states=True, use_cache=False)
out = torch.stack([output.hidden_states[k] for k in [9, 18, 27]], dim=1)
txt = rearrange(out, "b c l d -> b l (c d)")  # [1, 512, 7680]

# 3. Latent 생성 (CPU offload)
from flux2.sampling import get_schedule
w, h = 512, 512
num_tokens = (w // 16) * (h // 16)
img_ids = torch.zeros(1, num_tokens, 4, dtype=torch.long)
for idx in range(num_tokens):
    img_ids[0, idx, 1] = idx // (w // 16)
    img_ids[0, idx, 2] = idx % (w // 16)
txt_ids = torch.zeros(1, txt.shape[1], 4, dtype=torch.long)
torch.manual_seed(42)
img = torch.randn(1, num_tokens, 128, device="cpu", dtype=torch.bfloat16)
timesteps = get_schedule(4, num_tokens)
for t_curr, t_prev in zip(timesteps[:-1], timesteps[1:]):
    m = flow_model.to("cuda")
    pred = m(x=img.to("cuda"), x_ids=img_ids.to("cuda"),
             timesteps=torch.full((1,), t_curr, dtype=torch.bfloat16, device="cuda"),
             ctx=txt.to("cuda"), ctx_ids=txt_ids.to("cuda"),
             guidance=torch.full((1,), 1.0, dtype=torch.bfloat16, device="cuda"))
    img = (img.to("cuda") + (t_prev - t_curr) * pred).to("cpu")
    del m; torch.cuda.empty_cache()

# 4. VAE 디코드 — ⚠️ 현재 32ch VAE로 128ch latent 디코딩 불가
# img_2d = rearrange(img[0], "(h w) c -> 1 c h w", h=h//16, w=w//16).to("cuda")
# with torch.no_grad(): decoded = ae.decode(img_2d)
# from torchvision.utils import save_image
# save_image(decoded.to("cpu").clamp(0, 1), "/tmp/flux2_result.png")
```

### ❌ 노이즈의 원인 (해결됨)

| 오류 방식 | 결과 |
|-----------|------|
| `tokenizer(prompt, return_tensors="pt")` (raw) | 노이즈 — 8토큰만 |
| `apply_chat_template` 생략 | 노이즈 — 포맷 오류 |
| `attention_mask` 없음 | 노이즈 — 패딩 처리 |
| `enable_thinking=False` 없음 | 노이즈 — thinking 모드 |
| ✅ `apply_chat_template` + `enable_thinking=False` + `attention_mask` | 정상 latent (std≈0.99) |

### 공식 샘플링 함수 (flux2.sampling)

**`get_schedule(num_steps, image_seq_len)`**: timesteps=[1.000, 0.958, 0.884, 0.717, 0.000] (4스텝)
**`denoise()`**: `pred = model(x=img, x_ids=img_ids, timesteps=t_vec, ctx=txt, ctx_ids=txt_ids, guidance=guidance_vec)` → `img += (t_prev - t_curr) * pred`

## 텍스트 인코딩

### Qwen3-4B-FP8 vs bf16

| 버전 | 크기 | CPU 가능 | 비고 |
|------|------|---------|------|
| FP8 | ~4GB | ❌ CUDA 전용 | `torch.float8_e4m3fn` |
| bf16 | ~8GB | ✅ | CPU에서 정상 동작 |

→ 8GB GPU에서는 **bf16 버전을 CPU에 로드**

## VAE — ⚠️ 채널 불일치 문제 (2026-06-01 발견)

| VAE | Latent 채널 | 실제 Flux2 호환? |
|-----|------------|-----------------|
| `flux2-vae.safetensors` (ComfyUI) | 32ch | ❌ 모델은 128ch 요구 |
| `FLUX.2-klein-4B/vae/diffusion_pytorch_model.safetensors` | 32ch | ❌ 동일하게 32ch |
| `ae.safetensors` (ComfyUI) | 16ch | ❌ Flux1 전용 |

**⚠️ 핵심 발견 (2026-06-01)**: Klein-4B 모델이 출력하는 latent이 128채널이지만, 모든 이용 가능한 VAE 체크포인트는 32채널로 고정됨. 채널 불일치로 디코딩 불가.

**증상**:
```
RuntimeError: size mismatch for decoder.conv_in.weight: 
  torch.Size([512, 128, 3, 3]) vs torch.Size([512, 32, 3, 3])
```

**공식 코드 구조**:
- `Klein4BParams.in_channels = 128` — 모델이 128 latent channels 사용
- `AutoEncoderParams.z_channels = 32` — VAE가 32 latent channels 기대
- 이 불일치는 모델 아키텍처 설계상 고정값

**해결 안 된 상태**: 실제 Flux2 VAE 체크포인트는 gated repo(`black-forest-labs/FLUX.2-dev`)에 있을 가능성 높음. 접근 승인 필요.

**일시적 우회**:
1. `AutoEncoderParams(z_channels=128)`로 재정의 가능하나 체크포인트 가중치도 32ch 기반이라 shape mismatch 발생
2. ComfyUI API를 통해 ComfyUI 내부 VAE 코드로 디코딩 시도 (Flux2 노드가 VAE를 자체 관리할 경우)
3. `diffusers.AutoencoderKL`로 HuggingFace에서 다른 VAE 체크포인트 탐색

**로딩 패턴** (32ch VAE 테스트용):
```python
from flux2.autoencoder import AutoEncoder, AutoEncoderParams
ae = AutoEncoder(AutoEncoderParams()).to(torch.bfloat16).to("cpu")
ae.load_state_dict(sd, strict=False)  # strict=False 필수 (키 이름 불일치)
ae = ae.to("cuda")
```

## WSL에서 Docker 컨테이너 자동 제어

Docker 데몬 접근 불가 시 HTTP 프록시 패턴 사용 (server.py 8899포트 → curl 실행). 상세: SKILL.md Pitfall 24 참조.

## FP8 safetensors 주의

`flux-2-klein-base-4b-fp8.safetensors` (4.09GB)는 스케일 텐서(`input_scale`, `weight_scale`) 포함.
공식 코드의 `load_state_dict(strict=True)`가 거부 → **FP8 모델은 공식 코드에서 로딩 불가**. bf16 사용.

## Flux2-dev와의 차이

| 항목 | Klein-4B | Flux2-dev |
|------|----------|-----------|
| 텍스트 인코더 | Qwen3-4B (공개) | Mistral3-24B (gated) |
| context_in_dim | 7680 | 15360 |
| hidden_size | 3072 | 6144 |
| steps | 4 (distilled) | 50 |
| guidance | 1.0 (distilled) | 4.0 |

## 미해결 문제

- **VAE 디코딩**: 128ch latent를 디코딩할 수 있는 VAE 체크포인트 부재 — Flux2-dev gated repo 접근 필요
- **1024x1024 해상도 테스트**: 512x512만 검증됨
- **이미지 밝기**: 기본 출력 어둠 (mean≈17/255). VAE post-processing 또는 latent scaling 최적화 필요.
- **CLI OOM 버그**: Klein-4B 지정 시에도 Mistral3-24B 로드 시도 → 수동 파이프라인 필요.
