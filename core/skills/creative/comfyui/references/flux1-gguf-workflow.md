# Flux1 GGUF Standard Workflow (JOB-1167 Tested)

## Overview
Tested working Flux1 GGUF workflow for ComfyUI-GGUF latest. Replaces Flux2 Klein GGUF (unsupported in current ComfyUI-GGUF).

## Server Config (RTX 4060 Ti 8GB VRAM)
- **UNet**: `flux1-dev-Q4_K_S.gguf` (~6.8GB)
- **CLIP**: `clip_l.safetensors` + `t5xxl_fp8_e4m3fn.safetensors`
- **VAE**: `ae.safetensors` (standard Flux VAE)
- **Optimization**: float16 dequant/patch, `patch_on_device=false`

## Node Graph (API Format)

```json
{
  "1": {
    "class_type": "UnetLoaderGGUF",
    "inputs": {
      "unet_name": "flux1-dev-Q4_K_S.gguf",
      "weight_dtype": "default"
    }
  },
  "2": {
    "class_type": "DualCLIPLoaderGGUF",
    "inputs": {
      "clip_name1": "clip_l.safetensors",
      "clip_name2": "t5xxl_fp8_e4m3fn.safetensors",
      "type": "flux"
    }
  },
  "4": {
    "class_type": "CLIPTextEncode",
    "inputs": {
      "text": "YOUR_PROMPT_HERE",
      "clip": ["2", 0]
    }
  },
  "5": {
    "class_type": "CLIPTextEncode",
    "inputs": {
      "text": "",
      "clip": ["2", 0]
    }
  },
  "6": {
    "class_type": "EmptyLatentImage",
    "inputs": {
      "width": 1024,
      "height": 1024,
      "batch_size": 1
    }
  },
  "7": {
    "class_type": "FluxGuidance",
    "inputs": {
      "guidance": 3.5,
      "conditioning": ["4", 0]
    }
  },
  "3": {
    "class_type": "KSampler",
    "inputs": {
      "seed": -1,
      "steps": 20,
      "cfg": 1.0,
      "sampler_name": "euler",
      "scheduler": "simple",
      "denoise": 1.0,
      "model": ["1", 0],
      "positive": ["7", 0],
      "negative": ["5", 0],
      "latent_image": ["6", 0],
      "control_after_generate": "randomize"
    }
  },
  "8": {
    "class_type": "VAELoader",
    "inputs": {
      "vae_name": "ae.safetensors"
    }
  },
  "9": {
    "class_type": "VAEDecode",
    "inputs": {
      "samples": ["3", 0],
      "vae": ["8", 0]
    }
  },
  "10": {
    "class_type": "SaveImage",
    "inputs": {
      "images": ["9", 0],
      "filename_prefix": "hermes_gen"
    }
  }
}
```

## Key Differences from Flux2 Klein Workflow
| Aspect | Flux2 Klein (Legacy) | Flux1 GGUF (Current) |
|--------|---------------------|---------------------|
| UNet Loader | `UnetLoaderGGUF` | `UnetLoaderGGUF` |
| CLIP Loader | `CLIPLoaderGGUF` (type: flux2) | `DualCLIPLoaderGGUF` (type: flux) |
| CLIP Model | `Qwen3-8B-Q4_K_M.gguf` | `clip_l.safetensors` + `t5xxl_fp8_e4m3fn.safetensors` |
| Latent Image | `EmptyFlux2LatentImage` (removed) | `EmptyLatentImage` (standard) |
| VAE | `flux2-vae.safetensors` (32-dim, incompatible) | `ae.safetensors` (standard 4-dim) |
| FluxGuidance | Not used | Required (guidance: 3.5) |

## Execution Command
```bash
python3 scripts/run_workflow.py \
  --workflow flux1_gguf_workflow.json \
  --args '{"prompt": "YOUR_PROMPT", "seed": -1}' \
  --host http://100.110.197.35:8188 \
  --output-dir ./outputs
```

## VRAM Notes (8GB GPU)
- `patch_on_device=false` recommended to avoid OOM
- `--lowvram` flag in ComfyUI CLI_ARGS helps
- Generation time: ~60-120s per 1024x1024 image
- Use `512x512` for faster iterations if needed

## LoRA Support
Flux1 GGUF LoRAs work via standard `LoraLoader` nodes. Add between UNet loader and KSampler:
```json
"LoraLoader": {
  "inputs": {
    "lora_name": "YOUR_LORA.safetensors",
    "strength_model": 0.8,
    "model": ["1", 0]
  }
}
```
