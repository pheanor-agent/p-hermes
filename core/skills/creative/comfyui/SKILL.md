---
name: comfyui
description: "Generate images, video, and audio with ComfyUI — install, launch, manage nodes/models, run workflows with parameter injection. Uses the official comfy-cli for lifecycle and direct REST/WebSocket API for execution."
version: 5.0.0
author: [kshitijk4poor, alt-glitch]
license: MIT
platforms: [macos, linux, windows]
compatibility: "Requires ComfyUI (local, Comfy Desktop, or Comfy Cloud) and comfy-cli (auto-installed via pipx/uvx by the setup script)."
prerequisites:
  commands: ["python3"]
setup:
  help: "Run scripts/hardware_check.py FIRST to decide local vs Comfy Cloud; then scripts/comfyui_setup.sh auto-installs locally (or use Cloud API key for platform.comfy.org)."
metadata:
  hermes:
    tags:
      - comfyui
      - image-generation
      - stable-diffusion
      - flux
      - sd3
      - wan-video
      - hunyuan-video
      - creative
      - generative-ai
      - video-generation
    related_skills: [stable-diffusion-image-generation, image_gen]
    category: creative
---

# ComfyUI

Generate images, video, audio, and 3D content through ComfyUI using the
official `comfy-cli` for setup/lifecycle and direct REST/WebSocket API
for workflow execution.

## What's in this skill

**Reference docs (`references/`):**

- `official-cli.md` — every `comfy ...` command, with flags
- `rest-api.md` — REST + WebSocket endpoints (local + cloud), payload schemas
- `workflow-format.md` — API-format JSON, common node types, param mapping
- `runpod-comfyui-integration.md` — RunPod 외부 GPU 서버 연동 가이드 (JOB-1289 시리즈)
- `image-queue-management.md` — 이미지 생성 큐 관리 (image-queue.sh)
- `docker-compose-tailscale.yml` — Tailscale sidecar + ComfyUI Docker template (JOB-1167)
- `references/gguf-troubleshooting.md` — GGUF custom node install, Flux2 Klein workflow structure, VAE compatibility, custom node implementation
- `references/flux2-local-inference.md` — Flux2 공식 repo 기반 로컬 추론 (Qwen3-4B 텍스트 인코더, VRAM/RAM 구성표)
- `flux2-klein-custom-node-deployment.md` — Flux2 Klein VAE 커스텀 노드 배포 가이드 (Docker 볼륨 마운트 활용)
- `flux1-gguf-workflow.md` — Tested Flux1 GGUF workflow (UnetLoaderGGUF + DualCLIPLoaderGGUF + ae.safetensors)
- `flux2-dev-model-spec.md` — Flux2-dev 모델 스펙 (GGUF 양자화, 스토리지 요구사항, ComfyUI 워크플로우)
- `docker-gguf-manager-setup.md` — Docker (ai-dock) GGUF + ComfyUI Manager install patterns
- `runpod-comfyui-integration.md` — RunPod ComfyUI 연동 가이드 (JOB-1333, 1338)

**Scripts (`scripts/`):**

| Script | Purpose |
|--------|---------|
| `_common.py` | Shared HTTP, cloud routing, node catalogs (don't run directly) |
| `hardware_check.py` | Probe GPU/VRAM/disk → recommend local vs Comfy Cloud |
| `comfyui_setup.sh` | Hardware check + comfy-cli + ComfyUI install + launch + verify |
| `extract_schema.py` | Read a workflow → list controllable params + model deps |
| `check_deps.py` | Check workflow against running server → list missing nodes/models |
| `auto_fix_deps.py` | Run check_deps then `comfy node install` / `comfy model download` |
| `run_workflow.py` | Inject params, submit, monitor, download outputs (HTTP or WS) |
| `run_batch.py` | Submit a workflow N times with sweeps, parallel up to your tier |
| `ws_monitor.py` | Real-time WebSocket viewer for executing jobs (live progress) |
| `health_check.py` | Verification checklist runner — comfy-cli + server + models + smoke test |
| `fetch_logs.py` | Pull traceback / status messages for a given prompt_id |

**Example workflows (`workflows/`):** SD 1.5, SDXL, Flux Dev, SDXL img2img,
SDXL inpaint, ESRGAN upscale, AnimateDiff video, Wan T2V. See
`workflows/README.md`.

## When to Use

- User asks to generate images with Stable Diffusion, SDXL, Flux, SD3, etc.
- User wants to run a specific ComfyUI workflow file
- User wants to chain generative steps (txt2img → upscale → face restore)
- User needs ControlNet, inpainting, img2img, or other advanced pipelines
- User asks to manage ComfyUI queue, check models, or install custom nodes
- User wants video/audio/3D generation via AnimateDiff, Hunyuan, Wan, AudioCraft, etc.

**⚠️ 원칙 (2026-05-29 사용자 지적)**: 사용자가 ComfyUI를 지시하면 **절대 다른 제공자(OpenRouter, RunPod, Vast.ai 등)로 자동 전환 금지**. ComfyUI 문제 발생 시 사용자에게 보고하고 지시等待.

## Architecture: Two Layers

```
┌─────────────────────────────────────────────────────┐
│ Layer 1: comfy-cli (official lifecycle tool)        │
│   Setup, server lifecycle, custom nodes, models     │
│   → comfy install / launch / stop / node / model    │
└─────────────────────────┬───────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────┐
│ Layer 2: REST/WebSocket API + skill scripts         │
│   Workflow execution, param injection, monitoring   │
│   POST /api/prompt, GET /api/view, WS /ws           │
│   → run_workflow.py, run_batch.py, ws_monitor.py    │
└─────────────────────────────────────────────────────┘
```

**Why two layers?** The official CLI is excellent for installation and server
management but has minimal workflow execution support. The REST/WS API fills
that gap — the scripts handle param injection, execution monitoring, and
output download that the CLI doesn't do.

## Quick Start

### Detect environment

```bash
# What's available?
command -v comfy >/dev/null 2>&1 && echo "comfy-cli: installed"
curl -s http://127.0.0.1:8188/system_stats 2>/dev/null && echo "server: running"

# Can this machine run ComfyUI locally? (GPU/VRAM/disk check)
python3 scripts/hardware_check.py
```

If nothing is installed, see **Setup & Onboarding** below — but always run the
hardware check first.

### One-line health check

```bash
python3 scripts/health_check.py
# → JSON: comfy_cli on PATH? server reachable? at least one checkpoint? smoke-test passes?
```

## Core Workflow

### Step 1: Get a workflow JSON in API format

Workflows must be in API format (each node has `class_type`). They come from:

- ComfyUI web UI → **Workflow → Export (API)** (newer UI) or
  the legacy "Save (API Format)" button (older UI)
- This skill's `workflows/` directory (ready-to-run examples)
- Community downloads (civitai, Reddit, Discord) — usually editor format,
  must be loaded into ComfyUI then re-exported

Editor format (top-level `nodes` and `links` arrays) is **not directly
executable**. The scripts detect this and tell you to re-export.

### Step 2: See what's controllable

```bash
python3 scripts/extract_schema.py workflow_api.json --summary-only
# → {"parameter_count": 12, "has_negative_prompt": true, "has_seed": true, ...}

python3 scripts/extract_schema.py workflow_api.json
# → full schema with parameters, model deps, embedding refs
```

### Step 3: Run with parameters

```bash
# Local (defaults to http://127.0.0.1:8188)
python3 scripts/run_workflow.py \
  --workflow workflow_api.json \
  --args '{"prompt": "a beautiful sunset over mountains", "seed": -1, "steps": 30}' \
  --output-dir ./outputs

# Cloud (export API key once; uses correct /api routing automatically)
export COMFY_CLOUD_API_KEY="comfyui-..."
python3 scripts/run_workflow.py \
  --workflow workflow_api.json \
  --args '{"prompt": "..."}' \
  --host https://cloud.comfy.org \
  --output-dir ./outputs

# Real-time progress via WebSocket (requires `pip install websocket-client`)
python3 scripts/run_workflow.py \
  --workflow flux_dev.json \
  --args '{"prompt": "..."}' \
  --ws

# img2img / inpaint: pass --input-image to upload + reference automatically
python3 scripts/run_workflow.py \
  --workflow sdxl_img2img.json \
  --input-image image=./photo.png \
  --args '{"prompt": "make it watercolor", "denoise": 0.6}'

# Batch / sweep: 8 random seeds, parallel up to cloud tier limit
python3 scripts/run_batch.py \
  --workflow sdxl.json \
  --args '{"prompt": "abstract"}' \
  --count 8 --randomize-seed --parallel 3 \
  --output-dir ./outputs/batch
```

`-1` for `seed` (or omitting it with `--randomize-seed`) generates a fresh
random seed per run.

### Step 4: Present results

The scripts emit JSON to stdout describing every output file:

```json
{
  "status": "success",
  "prompt_id": "abc-123",
  "outputs": [
    {"file": "./outputs/sdxl_00001_.png", "node_id": "9",
     "type": "image", "filename": "sdxl_00001_.png"}
  ]
}
```

## Decision Tree

| User says | Tool | Command |
|-----------|------|---------|
| **Lifecycle (use comfy-cli)** | | |
| "install ComfyUI" | comfy-cli | `bash scripts/comfyui_setup.sh` |
| "start ComfyUI" | comfy-cli | `comfy launch --background` |
| "stop ComfyUI" | comfy-cli | `comfy stop` |
| "install X node" | comfy-cli | `comfy node install <name>` |
| "download X model" | comfy-cli | `comfy model download --url <url> --relative-path models/checkpoints` |
| "list installed models" | comfy-cli | `comfy model list` |
| "list installed nodes" | comfy-cli | `comfy node show installed` |
| **Execution (use scripts)** | | |
| "is everything ready?" | script | `health_check.py` (optionally with `--workflow X --smoke-test`) |
| "what can I change in this workflow?" | script | `extract_schema.py W.json` |
| "check if W's deps are met" | script | `check_deps.py W.json` |
| "fix missing deps" | script | `auto_fix_deps.py W.json` |
| "generate an image" | script | `run_workflow.py --workflow W --args '{...}'` |
| "use this image" (img2img) | script | `run_workflow.py --input-image image=./x.png ...` |
| "8 variations with random seeds" | script | `run_batch.py --count 8 --randomize-seed ...` |
| "show me live progress" | script | `ws_monitor.py --prompt-id <id>` |
| "fetch the error from job X" | script | `fetch_logs.py <prompt_id>` |
| **Direct REST** | | |
| "what's in the queue?" | REST | `curl http://HOST:8188/queue` (local) or `--host https://cloud.comfy.org` |
| "cancel that" | REST | `curl -X POST http://HOST:8188/interrupt` |
| "free GPU memory" | REST | `curl -X POST http://HOST:8188/free` |

## Setup & Onboarding

When a user asks to set up ComfyUI, **the FIRST thing to do is ask whether
they want Comfy Cloud (hosted, zero install, API key) or Local (install
ComfyUI on their machine)**. Don't start running install commands or hardware
checks until they've answered.

**Official docs:** https://docs.comfy.org/installation
**CLI docs:** https://docs.comfy.org/comfy-cli/getting-started
**Cloud docs:** https://docs.comfy.org/get_started/cloud
**Cloud API:** https://docs.comfy.org/development/cloud/overview

### Step 0: Ask Local vs Cloud (ALWAYS FIRST)

Suggested script:

> "Do you want to run ComfyUI locally on your machine, or use Comfy Cloud?
>
> - **Comfy Cloud** — hosted on RTX 6000 Pro GPUs, all common models pre-installed,
>   zero setup. Requires an API key (paid subscription required to actually run
>   workflows; free tier is read-only). Best if you don't have a capable GPU.
> - **Local** — free, but your machine MUST meet the hardware requirements:
>   - NVIDIA GPU with **≥6 GB VRAM** (≥8 GB for SDXL, ≥12 GB for Flux/video), OR
>   - AMD GPU with ROCm support (Linux), OR
>   - Apple Silicon Mac (M1+) with **≥16 GB unified memory** (≥32 GB recommended).
>   - Intel Macs and machines with no GPU will NOT work — use Cloud instead.
>
> Which would you like?"

Routing:

- **Cloud** → skip to **Path A**.
- **Local** → run hardware check first, then pick a path from Paths B–E based on the verdict.
- **Unsure** → run the hardware check and let the verdict decide.

### Step 1: Verify Hardware (ONLY if user chose local)

```bash
python3 scripts/hardware_check.py --json
# Optional: also probe `torch` for actual CUDA/MPS:
python3 scripts/hardware_check.py --json --check-pytorch
```

| Verdict    | Meaning                                                       | Action |
|------------|---------------------------------------------------------------|--------|
| `ok`       | ≥8 GB VRAM (discrete) OR ≥32 GB unified (Apple Silicon)       | Local install — use `comfy_cli_flag` from report |
| `marginal` | SD1.5 works; SDXL tight; Flux/video unlikely                  | Local OK for light workflows, else **Path A (Cloud)** |
| `cloud`    | No usable GPU, <6 GB VRAM, <16 GB Apple unified, Intel Mac, Rosetta Python | **Switch to Cloud** unless user explicitly forces local |

The script also surfaces `wsl: true` (WSL2 with NVIDIA passthrough) and
`rosetta: true` (x86_64 Python on Apple Silicon — must reinstall as ARM64).

If verdict is `cloud` but the user wants local, do not proceed silently.
Show the `notes` array verbatim and ask whether they want to (a) switch to
Cloud or (b) force a local install (will OOM or be unusably slow on modern models).

### Choosing an Installation Path

Use the hardware check first. The table below is the fallback for when the
user has already told you their hardware:

| Situation | Recommended Path |
|-----------|------------------|
| `verdict: cloud` from hardware check | **Path A: Comfy Cloud** |
| No GPU / want to try without commitment | **Path A: Comfy Cloud** |
| Windows + NVIDIA + non-technical | **Path B: ComfyUI Desktop** |
| Windows + NVIDIA + technical | **Path C: Portable** or **Path D: comfy-cli** |
| Linux + any GPU | **Path D: comfy-cli** (easiest) |
| macOS + Apple Silicon | **Path B: Desktop** or **Path D: comfy-cli** |
| Headless / server / CI / agents | **Path D: comfy-cli** |

For the fully automated path (hardware check → install → launch → verify):

```bash
bash scripts/comfyui_setup.sh
# Or with overrides:
bash scripts/comfyui_setup.sh --m-series --port=8190 --workspace=/data/comfy
```

It runs `hardware_check.py` internally, refuses to install locally when the
verdict is `cloud` (unless `--force-cloud-override`), picks the right
`comfy-cli` flag, and prefers `pipx`/`uvx` over global `pip` to avoid polluting
system Python.

---

### Path A: Comfy Cloud (No Local Install)

For users without a capable GPU or who want zero setup. Hosted on RTX 6000 Pro.

**Docs:** https://docs.comfy.org/get_started/cloud

1. Sign up at https://comfy.org/cloud
2. Generate an API key at https://platform.comfy.org/login
3. Set the key:
   ```bash
   export COMFY_CLOUD_API_KEY="comfyui-xxxxxxxxxxxx"
   ```
4. Run workflows:
   ```bash
   python3 scripts/run_workflow.py \
     --workflow workflows/flux_dev_txt2img.json \
     --args '{"prompt": "..."}' \
     --host https://cloud.comfy.org \
     --output-dir ./outputs
   ```

**Pricing:** https://www.comfy.org/cloud/pricing
**Concurrent jobs:** Free/Standard 1, Creator 3, Pro 5. Free tier
**cannot run workflows via API** — only browse models. Paid subscription
required for `/api/prompt`, `/api/upload/*`, `/api/view`, etc.

---

### Path B: ComfyUI Desktop (Windows / macOS)

One-click installer for non-technical users. Currently Beta.

**Docs:** https://docs.comfy.org/installation/desktop
- **Windows (NVIDIA):** https://download.comfy.org/windows/nsis/x64
- **macOS (Apple Silicon):** https://comfy.org

Linux is **not supported** for Desktop — use Path D.

---

### Path C: ComfyUI Portable (Windows Only)

**Docs:** https://docs.comfy.org/installation/comfyui_portable_windows

Download from https://github.com/comfyanonymous/ComfyUI/releases, extract,
run `run_nvidia_gpu.bat`. Update via `update/update_comfyui_stable.bat`.

---

### Path D: comfy-cli (All Platforms — Recommended for Agents)

The official CLI is the best path for headless/automated setups.

**Docs:** https://docs.comfy.org/comfy-cli/getting-started

#### Install comfy-cli

```bash
# Recommended:
pipx install comfy-cli
# Or use uvx without installing:
uvx --from comfy-cli comfy --help
# Or (if pipx/uvx unavailable):
pip install --user comfy-cli
```

Disable analytics non-interactively:
```bash
comfy --skip-prompt tracking disable
```

#### Install ComfyUI

```bash
comfy --skip-prompt install --nvidia              # NVIDIA (CUDA)
comfy --skip-prompt install --amd                 # AMD (ROCm, Linux)
comfy --skip-prompt install --m-series            # Apple Silicon (MPS)
comfy --skip-prompt install --cpu                 # CPU only (slow)
comfy --skip-prompt install --nvidia --fast-deps  # uv-based dep resolution
```

Default location: `~/comfy/ComfyUI` (Linux), `~/Documents/comfy/ComfyUI`
(macOS/Win). Override with `comfy --workspace /custom/path install`.

#### Launch / verify

```bash
comfy launch --background                       # background daemon on :8188
comfy launch -- --listen 0.0.0.0 --port 8190    # LAN-accessible custom port
curl -s http://127.0.0.1:8188/system_stats      # health check
```

---

### Path E: Manual Install (Advanced / Unsupported Hardware)

For Ascend NPU, Cambricon MLU, Intel Arc, or other unsupported hardware.

**Docs:** https://docs.comfy.org/installation/manual_install

```bash
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI
pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu130
pip install -r requirements.txt
python main.py
```

---

### Post-Install: Download Models

```bash
# SDXL (general purpose, ~6.5 GB)
comfy model download \
  --url "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors" \
  --relative-path models/checkpoints

# SD 1.5 (lighter, ~4 GB, good for 6 GB cards)
comfy model download \
  --url "https://huggingface.co/stable-diffusion-v1-5/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors" \
  --relative-path models/checkpoints

# Flux Dev fp8 (smaller variant, ~12 GB)
comfy model download \
  --url "https://huggingface.co/Comfy-Org/flux1-dev/resolve/main/flux1-dev-fp8.safetensors" \
  --relative-path models/checkpoints

# Flux2-dev GGUF Q4_K_M (최고 품질, ~32GB) — 개별 구성 요소 다운로드
# Cow (Text Encoder)
comfy model download \
  --url "https://huggingface.co/gguf-org/flux2-dev-gguf/resolve/main/cow-Q4_K_M.gguf" \
  --relative-path models/text_encoders
# Flux2 (Diffusion Model)
comfy model download \
  --url "https://huggingface.co/gguf-org/flux2-dev-gguf/resolve/main/flux2-Q4_K_M.gguf" \
  --relative-path models/diffusion_models
# Pig (VAE)
comfy model download \
  --url "https://huggingface.co/gguf-org/flux2-dev-gguf/resolve/main/pig-F16.gguf" \
  --relative-path models/vae

# CivitAI (set token first):
comfy model download \
  --url "https://civitai.com/api/download/models/128713" \
  --relative-path models/checkpoints \
  --set-civitai-api-token "YOUR_TOKEN"
```

List installed: `comfy model list`.

### Post-Install: Install Custom Nodes

```bash
comfy node install comfyui-impact-pack             # popular utility pack
comfy node install comfyui-animatediff-evolved     # video generation
comfy node install comfyui-controlnet-aux          # ControlNet preprocessors
comfy node install comfyui-essentials              # common helpers
comfy node update all
comfy node install-deps --workflow=workflow.json   # install everything a workflow needs
```

### Post-Install: Verify

```bash
python3 scripts/health_check.py
# → comfy_cli on PATH? server reachable? checkpoints? smoke test?

python3 scripts/check_deps.py my_workflow.json
# → are this workflow's nodes/models/embeddings installed?

python3 scripts/run_workflow.py \
  --workflow workflows/sd15_txt2img.json \
  --args '{"prompt": "test", "steps": 4}' \
  --output-dir ./test-outputs
```

## Image Upload (img2img / Inpainting)

The simplest way is to use `--input-image` with `run_workflow.py`:

```bash
python3 scripts/run_workflow.py \
  --workflow workflows/sdxl_img2img.json \
  --input-image image=./photo.png \
  --args '{"prompt": "make it cyberpunk", "denoise": 0.6}'
```

The flag uploads `photo.png`, then injects its server-side filename into
whatever schema parameter is named `image`. For inpainting, pass both:

```bash
python3 scripts/run_workflow.py \
  --workflow workflows/sdxl_inpaint.json \
  --input-image image=./photo.png \
  --input-image mask_image=./mask.png \
  --args '{"prompt": "fill with flowers"}'
```

Manual upload via REST:
```bash
curl -X POST "http://127.0.0.1:8188/upload/image" \
  -F "image=@photo.png" -F "type=input" -F "overwrite=true"
# Returns: {"name": "photo.png", "subfolder": "", "type": "input"}

# Cloud equivalent:
curl -X POST "https://cloud.comfy.org/api/upload/image" \
  -H "X-API-Key: $COMFY_CLOUD_API_KEY" \
  -F "image=@photo.png" -F "type=input" -F "overwrite=true"
```

## Cloud Specifics

- **Base URL:** `https://cloud.comfy.org`
- **Auth:** `X-API-Key` header (or `?token=KEY` for WebSocket)
- **API key:** set `$COMFY_CLOUD_API_KEY` once and the scripts pick it up automatically
- **Output download:** `/api/view` returns a 302 to a signed URL; the scripts
  follow it and strip `X-API-Key` before fetching from the storage backend
  (don't leak the API key to S3/CloudFront).
- **Endpoint differences from local ComfyUI:**
  - `/api/object_info`, `/api/queue`, `/api/userdata` — **403 on free tier**;
    paid only.
  - `/history` is renamed to `/history_v2` on cloud (the scripts route
    automatically).
  - `/models/<folder>` is renamed to `/experiment/models/<folder>` on cloud
    (the scripts route automatically).
  - `clientId` in WebSocket is currently ignored — all connections for a
    user receive the same broadcast. Filter by `prompt_id` client-side.
  - `subfolder` is accepted on uploads but ignored — cloud has a flat namespace.
- **Concurrent jobs:** Free/Standard: 1, Creator: 3, Pro: 5. Extras queue
  automatically. Use `run_batch.py --parallel N` to saturate your tier.

## Queue & System Management

```bash
# Local
curl -s http://127.0.0.1:8188/queue | python3 -m json.tool
curl -X POST http://127.0.0.1:8188/queue -d '{"clear": true}'    # cancel pending
curl -X POST http://127.0.0.1:8188/interrupt                      # cancel running
curl -X POST http://127.0.0.1:8188/free \
  -H "Content-Type: application/json" \
  -d '{"unload_models": true, "free_memory": true}'

# Cloud — same paths under /api/, plus:
python3 scripts/fetch_logs.py --tail-queue --host https://cloud.comfy.org
```

## Pitfalls

1. **API format required** — every script and the `/api/prompt` endpoint expect
   API-format workflow JSON. The scripts detect editor format (top-level
   `nodes` and `links` arrays) and tell you to re-export via
   "Workflow → Export (API)" (newer UI) or "Save (API Format)" (older UI).

2. **Server must be running** — all execution requires a live server.
   `comfy launch --background` starts one. Verify with
   `curl http://127.0.0.1:8188/system_stats`.

3. **Model names are exact** — case-sensitive, includes file extension.
   `check_deps.py` does fuzzy matching (with/without extension and folder
   prefix), but the workflow itself must use the canonical name. Use
   `comfy model list` to discover what's installed.

4. **Missing custom nodes** — "class_type not found" means a required node
   isn't installed. `check_deps.py` reports which package to install;
   `auto_fix_deps.py` runs the install for you.

5. **Working directory** — `comfy-cli` auto-detects the ComfyUI workspace.
   If commands fail with "no workspace found", use
   `comfy --workspace /path/to/ComfyUI <command>` or
   `comfy set-default /path/to/ComfyUI`.

6. **Cloud free-tier API limits** — `/api/prompt`, `/api/view`, `/api/upload/*`,
   `/api/object_info` all return 403 on free accounts. `health_check.py` and
   `check_deps.py` handle this gracefully and surface a clear message.

7. **Timeout for video/audio workflows** — auto-detected when an output node
   is `VHS_VideoCombine`, `SaveVideo`, etc.; the default jumps from 300 s to
   900 s. Override explicitly with `--timeout 1800`.

8. **Path traversal in output filenames** — server-supplied filenames are
   passed through `safe_path_join` to refuse anything escaping `--output-dir`.
   Keep this protection on — workflows with custom save nodes can produce
   arbitrary paths.

9. **Workflow JSON is arbitrary code** — custom nodes run Python, so
   submitting an unknown workflow has the same trust profile as `eval`.
   Inspect workflows from untrusted sources before running.

10. **Auto-randomized seed** — pass `seed: -1` in `--args` (or use
    `--randomize-seed` and omit the seed) to get a fresh seed per run.
    The actual seed is logged to stderr.
    **⚠️ 서버 제한**: 일부 ComfyUI 서버에서 `seed: -1`이 `Value -1 smaller than min of 0` 오류 발생. 
    `run_workflow.py --randomize-seed` 플래그 사용 시 자동 우회됨.
**Pitfall 18: Flux2 Klein VAE — 커스텀 노드 제작 필요 (JOB-1262)**
- **문제**: Flux2 Klein GGUF의 VAE는 32채널 레이턴트 스페이스 사용 (표준: 4채널)
- **에러**: `size mismatch for quant_conv.weight: [64, 64, 1, 1] vs [8, 64, 1, 1]`
- **해결**: `diffusers.AutoencoderKLFlux2` 기반 커스텀 ComfyUI 노드 제작
- **코드**: `~/.hermes/workspace/projects/comfyui-flux2-vae-loader/`
- **노드 목록**: `Flux2VAELoader` (VAE 로드+디코드), `Flux2EmptyLatentImage` (32ch latent 생성)
- **배포**: Docker 볼륨 마운트 또는 SSH 후 docker exec (`references/flux2-klein-custom-node-deployment.md` 참조)
- **의존성**: `pip install diffusers>=0.30.0 safetensors>=0.4.0`
- **상태**: ✅ 커스텀 노드 개발 완료, SSH 활성화 후 테스트 진행 중

**RunPod 외부 GPU 서버 연동 (JOB-1289 시리즈)** (JOB-1289 시리즈)**
- **용도**: RunPod RTX 4090 Pod 원격 제어, Flux2 이미지 생성 자동화
- **엔드포인트**: `http://213.173.110.132:11934/` (RunPod Direct TCP Port)
- **설정 파일**: `~/.hermes/config/image-gen.yaml` (다중 제공자, 배치 승인, ROI 설정)
- **환경변수**: `RUNPOD_API_KEY` (~/.hermes/env)
- **관련 스킬**: `comfyui-remote`, `runpod-client`

**제어 스크립트** (`~/.hermes/skills/custom/image-generation/comfyui-remote/scripts/`):
| 스크립트 | 기능 |
|----------|------|
| `comfyui_api.py` | ComfyUI API 클라이언트 (Flux2 최적화, WS/polling) |
| `batch_group.py` | 배치 그룹화 (projectId+loraId 기준) |
| `batch_approval.py` | 배치 승인 워크플로우 (그룹 격리 + 승인 메시지) |
| `group_isolation.py` | 그룹 격리 필터 (sourceChannel 기준) |
| `runpod_client.py` | RunPod GraphQL API 클라이언트 (Pod 시작/정지/상태) |
| `install_flux2.py` | Flux2 모델 자동 설치 (HuggingFace 다운로드 + 업로드) |
| `pod_manager.py` | 통합 Pod 관리자 (On-Demand 제어, Idle 타임아웃) |
| `cost_manager.py` | 비용 관리 (일일 한도, 자동 정지, 사용량 리포트) |

**배치 승인 워크플로우** (JOB-1338):
- ❌ 5 분 자동 병합 **제거**
- ✅ 사용자 승인 기반 배치
- ✅ 그룹 채팅 시 승인 필수
- ✅ "더 생성할 이미지 있음?" 직접 판단 옵션
- ✅ `sourceChannel` 기반 그룹 격리

** 워크플로우**:
1. 이미지 요청 수신 → pending.json 등록
2. 배치 그룹화 (동일 프로젝트/LoRA 기준)
3. **사용자 승인 요청** (그룹 채팅 필수, DM 직접 판단 옵션)
4. Pod 시작 (미실행 시) → Ready 체크 → 모델 설치 확인
5. ComfyUI API 배치 워크플로우 제출
6. 결과 다운로드 → 그룹 격리 필터 → 결과 회신
7. 10 분 Idle → Pod 정지 (Warm Start 대비)

**Flux2 최적화**: `steps=25, cfg=7.5, sampler=dpmpp_2m, scheduler=karras, resolution=1024x1024`
**그룹 격리**: `sourceChannel` 필드로 출처 추적, 각 그룹은 해당 그룹 요청 이미지만 확인
**비용 관리**: 일일 한도 70,000 원, Warm Start 24.5 원, Cold Start 49 원, 장당 2.72 원

**⚠️ GraphQL 스키마 주의** (JOB-1334): RunPod GraphQL 표준 쿼리가 400 에러 발생. `runpod-client/references/graphql-schema-quirks.md` 참조. SDK (`runpod`) 사용 권장.
**⚠️ ComfyUI API 구조** (JOB-1334): `ckpt_name` 이 빈 배열 `[]` 일 수 있음. `comfyui-remote/references/comfyui-api-quirks.md` 참조.

**Pitfall 22: Remote ComfyUI Docker — SSH 차단 시 볼륨 마운트 배포**
- **상황**: Tailscale 네트워크 연결됨 but SSH(port 22) 차단 (Windows 호스트 OpenSSH 미설치)
- **해결**: docker-compose.yml의 volume mount를 통한 파일 복사
- **방법**:
  ```yaml
  volumes:
    - ./custom_nodes:/opt/ComfyUI/custom_nodes  # Windows 호스트 폴더
  ```
- Windows 파일 탐색기로 `custom_nodes/` 폴더에 커스텀 노드 복사 → 컨테이너 재시작
- **대안**: `docker exec -it <container> pip install <package>` (의존성 설치)

**Pitfall 20: Windows 호스트 SSH 활성화 (JOB-1262, 2026-05-23)**
- **문제**: ComfyUI HTTP(8188) 접근 가능하지만 SSH(22) 차단 → 원격 배포 어려움
- **해결**: 관리자 PowerShell에서 OpenSSH.Server 설치
- **중요**: Tailscale IP는 ComfyUI sidecar(`100.110.197.35`)와 Windows 호스트(`100.124.93.109`)가 **다름**
- **확인**: `tailscale ip -4`로 호스트 IP 확인 후 SSH 접속
- **SSH 키 인증 필수**: `authorized_keys` 등록 후 비밀번호 없는 자동화 가능
- **상세**: `references/flux2-klein-custom-node-deployment.md` § SSH 차단 문제 참조

**Pitfall 17: ComfyUI Manager in Docker (ai-dock) — Manual Requirements Install (JOB-1167)**
11. **`tracking` prompt** — first run of `comfy` may prompt for analytics.
    Use `comfy --skip-prompt tracking disable` to skip non-interactively.
    `comfyui_setup.sh` does this for you.
**Pitfall 12: Remote ComfyUI (Tailscale) — No Docker Access**
- **Context**: The user's ComfyUI runs on a remote PC (`comfyui-node`, Tailscale IP: `100.110.197.35`).
- **⚠️ PORT 18188 (not 8188)**: Server runs with `--port 18188`. Always use `http://100.110.197.35:18188` for API calls.
- **Architecture (JOB-1167)**: Hermes connects directly via REST API. OpenClaw handles monitoring only (no ComfyUI control).
- **Docker Structure**: `tailscale sidecar` + `comfyui` (ai-dock image) only. OpenClaw node removed (2026-05-17).
- **Constraint**: `docker` commands will **fail** on Hermes (WSL) because Docker is on the remote host.
- **Status Check**: Use `curl http://100.110.197.35:18188/system_stats` or `python3 scripts/health_check.py --host http://100.110.197.35:18188`.
- **Port 18188**: Connection refused usually means the remote container is starting or Tailscale tunnel is down. Ping `100.110.197.35` first.
- **Docker Compose Template**: See `references/docker-compose-tailscale.yml` for the canonical Tailscale sidecar + ComfyUI setup.
- **PowerShell Note**: Windows host uses PowerShell. Use `;` instead of `&&` for command chaining (e.g., `docker-compose down; docker-compose up -d`).
- **메타데이터 관리**: `image-registry.sh v3.0` — ComfyUI + OpenRouter 통합. `search/stats/register-v2` 명령어. 상세: `image-pipeline/references/metadata-management-v3.md`

**Pitfall 25: ComfyUI Major Version Upgrade — New Dependencies Required**
- **Context**: Upgrading ai-dock ComfyUI from v0.2.2 to v0.22.3 (or any major jump) introduces new required packages not in the original image.
- **Symptom**: ComfyUI enters FATAL state immediately after upgrade. `docker logs` shows `ModuleNotFoundError` for new dependencies. Supervisor gives up after 3 retries.
- **Required packages for v0.22.3** (install into ComfyUI venv, NOT system pip):
  ```bash
  docker exec <container> /opt/environments/python/comfyui/bin/pip install sqlalchemy alembic comfy-aimdo av comfy-kitchen
  docker compose restart comfyui
  ```
- **Dependency chain**: `sqlalchemy` → DB layer, `alembic` → migration, `comfy-aimdo` → asset management, `av` → video/audio I/O, `comfy-kitchen` → fp8/fp4 quantization support.
- **Upgrade process** (ai-dock Docker):
  ```bash
  docker exec <container> bash -c "cd /opt/ComfyUI && git fetch origin && git checkout tags/v0.22.3 -f"
  # Install missing deps BEFORE restart (else FATAL loop)
  docker exec <container> /opt/environments/python/comfyui/bin/pip install sqlalchemy alembic comfy-aimdo av comfy-kitchen
  docker compose restart comfyui
  # Verify
  docker logs <container> 2>&1 | Select-String "To see the GUI"
  ```
- **Tip**: After any `git checkout` to a new tag, check the commit changelog for new dependency mentions before restarting.

**Pitfall 26: Docker 컨테이너 자동 제어 (WSL + Docker Desktop 격리)**
- **상황**: Hermes(WSL)가 Docker 데몬에 직접 접근 불가 (포트 2375 refused, socket 없음)
- **해결**: 컨테이너 내부에 HTTP 프록시 서버 띄우기 → curl로 명령 실행
- **설정**: 컨테이너 내부에 server.py 실행 (사용자 1회 PowerShell 명령)
- **이후**: `curl -X POST http://CONTAINER_IP:8899/ -d '{"cmd": "python /tmp/test.py"}'`로 자동 테스트 가능
- **대안**: Docker Desktop → Settings → General → "Expose daemon on tcp://localhost:2375" 설정 (WSL에서도 docker 명령 직접 사용 가능)

**Pitfall 24: PowerShell → Docker Multi-line Script Execution (JOB-1432)**
- **Problem**: When Hermes (WSL) cannot run `docker` directly, the user must execute commands from Windows PowerShell. Multi-line Python scripts with heredocs, nested quotes, or bash variable interpolation fail due to PowerShell escaping differences.
- **Solution**: Write the Python script to a Windows file first, then `docker cp` it into the container:
  ```powershell
  # Step 1: Write script to Windows file
  @'
  import json
  print("hello from container")
  '@ | Out-File -FilePath "C:\AI\docker_comfyui\script.py" -Encoding utf8

  # Step 2: Copy into container
  docker cp C:\AI\docker_comfyui\script.py comfyui-sandbox:/tmp/

  # Step 3: Execute inside container
  docker exec comfyui-sandbox /opt/environments/python/comfyui/bin/python /tmp/script.py
  ```
- **PowerShell `curl` alias**: PowerShell aliases `curl` → `Invoke-WebRequest`, which has different parameter syntax. Use `Invoke-RestMethod` for HTTP calls, or run Python `urllib` scripts inside the container.
- **PowerShell `$VAR` expansion**: PowerShell variables like `$COMFYUI_VENV` get expanded before reaching bash. Use single quotes in bash subcommands or write scripts to files instead.

**Pitfall 13: Workflow JSON Comment Nodes (JOB-1167)**
- **Problem**: Built-in workflow files (`workflows/*.json`) contain comment nodes (e.g., `#_comment`) that lack the required `class_type` property.
- **Error**: `"Cannot execute because a node is missing the class_type property."` (HTTP 400)
- **Fix**: Remove comment nodes from workflow JSON before submission, or re-export from ComfyUI Web UI using "Workflow → Export (API)" which omits comments.
- **Detection**: `extract_schema.py` may not catch this. Check for nodes with IDs starting with `#` or lacking `class_type`.

**Pitfall 14: GGUF Models — Custom Node + Python Package Required (JOB-1167)**
- **Context**: GGUF-format models require the `ComfyUI-GGUF` custom node AND the `gguf` Python package.
- **Symptom**: `ModuleNotFoundError: No module named 'gguf'` in ComfyUI logs; custom node shows `(IMPORT FAILED)`.
- **Root Cause (ai-dock venv)**: ai-dock ComfyUI images run inside an isolated venv at `/opt/environments/python/comfyui/`. System `pip install` or `python3 -m pip install` installs to the WRONG location. Even `pip install --force-reinstall` to system site-packages won't help — the ComfyUI process only sees the venv.
- **Fix** — MUST use the venv's pip directly:
  ```bash
  # Correct: install directly into ComfyUI venv
  docker exec <container> /opt/environments/python/comfyui/bin/pip install gguf toml
  docker restart <container>

  # WRONG: these install to system Python, NOT the venv ComfyUI uses
  docker exec <container> pip install gguf          # ← system Python, not used
  docker exec <container> python3 -m pip install gguf  # ← also system Python
  docker exec <container> su - user -c "python3 -m pip install gguf"  # ← same
  ```
- **Also needed for ComfyUI Manager**: `toml` package in the same venv (`/opt/environments/python/comfyui/bin/pip install toml`).
- **Verification**: Check `/api/object_info` for `UnetLoaderGGUF`, `CLIPLoaderGGUF`, `DualCLIPLoaderGGUF`, `TripleCLIPLoaderGGUF`, `QuadrupleCLIPLoaderGGUF`, `UnetLoaderGGUFAdvanced` (6 nodes total).

**Pitfall 16: Flux2 in ComfyUI — Partial Support (JOB-1167, JOB-1432)**
- **Status (v0.22.3)**: ComfyUI v0.22.3 has Flux2-related nodes but UNETLoader still maps to Flux1 architecture.
- **ComfyUI-GGUF (city96)**: No `flux2` in `IMG_ARCH_LIST`. GGUF metadata says `general.architecture = "flux"` (same as Flux1), so weight loading succeeds, but inference fails with `mat1 and mat2 shapes cannot be multiplied (1024x64 and 128x6144)`.
- **ComfyUI UNETLoader (v0.22.3)**: Recognizes `flux-2-klein-4b.safetensors` in file list, but loads into Flux1's `FluxTransformer2DModel`. Error: `size mismatch for img_in.weight: torch.Size([3072, 128]) vs torch.Size([3072, 64])` — Flux2 has 128ch input, Flux1 expects 64ch.
- **Flux2 native nodes in v0.22.3** (734 total nodes):
  - `Flux2ImageNode`, `Flux2ProImageNode`, `Flux2MaxImageNode` — Partner/API-based (cloud), not local model loading
  - `Flux2EmptyLatentImage` — 32ch latent generation (custom node)
  - `Flux2VAELoader` — custom VAE loader (custom node)
  - `Flux2Scheduler` — scheduling node
  - `EmptyFlux2LatentImage` — built-in empty latent
  - **No local Flux2 UNET/transformer loader exists** — UNETLoader uses Flux1 architecture
- **Flux2 architecture** (Klein-4B): hidden_size=3072, 128ch latent input, context_in_dim=7680, double_blocks (5 blocks, MLP: 18432→3072→9216), single_blocks (19 blocks, MLP: 27648→3072→12288), 149 tensors, bf16
- **Flux2 text encoder — Qwen3, NOT T5**: Klein-4B uses `Qwen/Qwen3-4B-FP8` (~4GB), NOT T5-XXL. Official code: `load_qwen3_embedder(variant="4B")`. Klein-9B uses Qwen3-8B. Only Flux2-dev (32B) uses Mistral3-24B. CLIP-L is NOT used for Flux2.
- **Flux2 text encoder requirement**: Klein-4B `context_in_dim=7680` = Qwen3-4B output (7680 dims). Flux1's T5-XXL (4096-dim) is NOT compatible. Error: `mat1 and mat2 shapes cannot be multiplied (512x4096 and 7680x3072)`.
- **8GB VRAM + 64GB RAM (Klein-4B)**: bf16은 13GB+ VRAM 필요 → 8GB GPU에 직접 로딩 불가 (OOM). CPU 오프로딩 필수: 모델 CPU 로드 → 스텝마다 GPU 전송(~120s/4step, 512x512). Qwen3-4B-FP8은 CUDA 전용이므로 bf16 사용. VAE=flux2-vae.safetensors(32ch). FP8 safetensors는 공식 코드 미지원(scale 텐서 불일치).
- **Flux2 on HuggingFace**:
  - `FLUX.2-klein-4B` — `flux-2-klein-4b.safetensors` (3.88B params, bf16, open: apache-2.0)
  - `FLUX.2-klein-base-4b-fp8` — `flux-2-klein-base-4b-fp8.safetensors` (FP8 quantized, base = not distilled)
  - `black-forest-labs/FLUX.2-dev` — gated repo, text_encoder 10 shards, 32B params
  - All single-file safetensors, NOT diffusers format. Cannot use `FluxPipeline.from_pretrained()`.
- **Flux2 공식 코드** (`github.com/black-forest-labs/flux2`):
  - Klein-4B: guidance=1.0, num_steps=4 (고정), distilled
  - Klein-Base-4B: guidance=4.0, num_steps=50 (일반)
  - Klein-9B/9B-KV: context_in_dim=12288, hidden_size=4096
  - Flux2-dev: context_in_dim=15360, hidden_size=6144, Mistral3-24B 텍스트 인코더
- **⚠️ venv 분리 필수**: flux2는 torch 2.8.0 요구, ComfyUI는 xformers 0.0.28 = torch 2.4.1 호환. 같은 venv 사용 시 ComfyUI 파괴. 별도 venv 생성: `python3 -m venv /opt/environments/python/flux2`
- **⚠️ 워크플로우 원칙**: 공식 `flux` CLI가 있으면 반복 테스트로 수동 파이프라인 구성하지 말 것. 사용자 지적: "계속 이런식으로 테스트 해야해?"
- **⚠️ 공식 CLI OOM 버그**: `cli.py flux.2-klein-4b` 지정 시에도 `flux.2-dev`의 Mistral3-24B(48GB) 텍스트 인코더 로드 시도 → OOM. 8GB VRAM에서 CLI 직접 사용 불가. 수동 파이프라인 우회.
- **⚠️ 노이즈 출력 해결 (2026-06-01)**: Qwen3 텍스트 인코딩 시 `apply_chat_template` + `enable_thinking=False` + `attention_mask` 필수. 단순 tokenizer 사용 시 노이즈 출력. 상세: `references/flux2-local-inference.md` § 검증된 완전 파이프라인
- **Resolution for Flux2 on 8GB GPU**:
  1. **Flux1 GGUF** — works perfectly with ComfyUI. See `references/flux1-gguf-workflow.md`.
  2. **공식 flux2 repo 직접 실행 (CPU 오프로딩)** — ✅ 검증됨. `apply_chat_template` + `enable_thinking=False` + `attention_mask` 필수. ~168초/512x512/4steps.
  3. **공식 flux2 CLI** — `/opt/environments/python/flux2/bin/flux` 사용. **하지만 OOM 버그 있음** (Klein-4B 지정 시에도 Mistral3-24B 로드 시도).
  4. **ComfyUI Partner Nodes** — `Flux2ImageNode`/`ProImageNode`/`MaxImageNode`는 BFL 클라우드 API (API 키 필요).

**Flux1 GGUF 모델 설치** (8GB VRAM 권장):
- **모델**: `city96/FLUX.1-dev-gguf` (HuggingFace, 154K+ downloads)
- **추천 양자화**: `flux1-dev-Q4_K_S.gguf` (6.8GB, VRAM ~6-7GB)
- **대안**: `flux1-dev-Q5_K_S.gguf` (8.3GB, 더 높은 품질)
- **다운로드**:
  ```powershell
  # Windows PowerShell
  Invoke-WebRequest -Uri "https://huggingface.co/city96/FLUX.1-dev-gguf/resolve/main/flux1-dev-Q4_K_S.gguf" -OutFile "C:\AI\ComfyUI\models\diffusion_models\flux1-dev-Q4_K_S.gguf"
  ```
- **필수 커스텀 노드**: `ComfyUI-GGUF` (city96) + `gguf` Python 패키지
- **⚠️ Docker 볼륨 마운트 필수**: 컨테이너 재시작 시 모델 손실 방지 (Pitfall 23)
- **⚠️ 워크플로우 주의**: ComfyUI에서 Flux2 로컬 로딩이 불가능하다고 확인된 후, 다른 경로(공식 repo 등)로 전환했으면 ComfyUI로 되돌아가지 말 것. 사용자가 "왜 또 ComfyUI?"라고 지적할 수 있음.
- **⚠️ Flux2 VAE 채널 불일치 (2026-06-01)**: Klein-4B 모델이 128ch latent 출력하나, 모든 이용 가능한 VAE 체크포인트는 32ch로 고정. 디코딩 불가. 해결: Flux2-dev gated repo 접근 또는 ComfyUI API 우회. 상세: `references/flux2-local-inference.md` § VAE
- **diffusers compatibility (PyTorch 2.4.1)**: `diffusers==0.30.3` as safe version. Flux2는 diffusers 로딩 불가.

**Pitfall 23: Docker Container Restart — Data Loss (JOB-1398)**
- **문제**: Docker 컨테이너 재시작/재생성 시 커스텀 노드(GGUF, Manager)와 모델 파일 손실
- **증상**: `/api/object_info`에서 GGUF 노드 0개, 체크포인트 모델 없음
- **원인**: Docker 볼륨 마운트 설정 누락
- **해결**:
  ```yaml
  # docker-compose.yml 볼륨 마운트 필수
  volumes:
    - comfyui_models:/opt/ComfyUI/models
    - comfyui_custom_nodes:/opt/ComfyUI/custom_nodes
    - comfyui_output:/opt/ComfyUI/output
  volumes:
    comfyui_models:
    comfyui_custom_nodes:
    comfyui_output:
  ```
- **복구 절차**: Windows PowerShell에서 `docker inspect comfyui-sandbox`로 볼륨 확인 → 누락 시 볼륨 추가 → 컨테이너 재생성 → ComfyUI Manager 재설치 → GGUF 노드 + 모델 재다운로드
- **사용자 지적**: "도커 재시작되도 이미지 생성 환경 설정은 동일하게 할 수 있어야지" — 볼륨 설정은 선택이 아님

**Pitfall 27: Docker 볼륨 마운트 — `models/unet`은 ComfyUI에서 인식 안됨**
- **문제**: Windows 호스트에서 `models/unet` 폴더를 `/opt/ComfyUI/models/unet`으로 마운트하면 ComfyUI가 모델 목록에 표시하지 않음
- **원인**: ComfyUI는 `models/diffusion_models` 폴더만 GGUF 모델 인식
- **해결**: docker-compose.yml에서 마운트 경로 수정
  ```yaml
  # ❌ 틀림
  - ./models/unet:/opt/ComfyUI/models/unet
  # ✅ 맞음
  - ./models/unet:/opt/ComfyUI/models/diffusion_models
  ```
- **확인**: `curl http://HOST:PORT/models/diffusion_models`로 모델 목록 확인

**Pitfall 28: PowerShell YAML 수정 — 인코딩 깨짐 방지**
- **문제**: PowerShell의 `Set-Content`가 UTF-8 BOM을 제거하거나 인코딩 변경 → Docker Compose가 YAML 파싱 실패 (`invalid leading UTF-8 octet`)
- **해결**: `[System.IO.File]::WriteAllText` 사용 (인코딩 preserved)
  ```powershell
  $content = Get-Content "docker-compose.yml" -Raw -Encoding UTF8
  $content = $content -replace 'old', 'new'
  [System.IO.File]::WriteAllText("path\to\docker-compose.yml", $content, [System.Text.UTF8Encoding]::new($false))
  ```
- **대안**: `docker-compose.yml.bak` 백업 유지, 복원 후 수동 수정

**Pitfall 29: ComfyUI `latest-cuda` 이미지 — 버전 롤백 위험**
- **문제**: `ghcr.io/ai-dock/comfyui:latest-cuda` 사용 시 컨테이너 재생성 시 버전 불안정 (v0.22.3 → v0.2.2 롤백 사례)
- **원인**: `latest` 태그가 최신 안정 버전으로 변경될 수 있음
- **해결**: 컨테이너 내부에서 git checkout으로 버전 고정
  ```bash
  docker exec comfyui-sandbox bash -c "cd /opt/ComfyUI && git fetch origin && git checkout tags/v0.22.3 -f"
  ```
- **필수 패키지**: v0.22.3는 `sqlalchemy alembic comfy-aimdo av comfy-kitchen` 필수
- **GGUF 패키지**: `gguf toml`도 venv에 직접 설치 (`/opt/environments/python/comfyui/bin/pip install`)

**Pitfall 16: ComfyUI Manager in Docker (ai-dock) — Manual Requirements Install (JOB-1167)**
- **Problem**: Cloning ComfyUI-Manager into `custom_nodes/` is NOT enough. ai-dock images use isolated Python virtualenvs; Manager fails with `No module named 'toml'` or `folder_paths.get_user_directory`.
- **Fix**:
  ```bash
  # Clone Manager
  git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager
  # Install requirements in correct Python env
  docker exec <container> bash -c "source /opt/environments/python/comfyui/bin/activate && cd /opt/ComfyUI/custom_nodes/ComfyUI-Manager && pip install -r requirements.txt"
  docker restart <container>
  ```
- **Verification**: ComfyUI log shows `0.X seconds: /opt/ComfyUI/custom_nodes/ComfyUI-Manager` (no IMPORT FAILED). Web UI shows Manager button.

## Verification Checklist

Use `python3 scripts/health_check.py` to run the whole list at once. Manual:

- [ ] `hardware_check.py` verdict is `ok` OR the user explicitly chose Comfy Cloud
- [ ] `comfy --version` works (or `uvx --from comfy-cli comfy --help`)
- [ ] `curl http://HOST:PORT/system_stats` returns JSON
- [ ] `comfy model list` shows at least one checkpoint (local) OR
      `/api/experiment/models/checkpoints` returns models (cloud)
- [ ] Workflow JSON is in API format
- [ ] `check_deps.py` reports `is_ready: true` (or only `node_check_skipped`
      on cloud free tier)
- [ ] Test run with a small workflow completes; outputs land in `--output-dir`
