# Flux2 Klein VAE 커스텀 노드 배포 가이드

**JOB-1262**: Flux2 Klein VAE 커스텀 로더 노드 설계 및 제작
**최종 업데이트**: 2026-05-23

---

## 문제 정의

Flux2 Klein GGUF 모델(`flux-2-klein-9b-Q4_K_M.gguf`) 사용 시 VAE 디코드 단계에서 차원 불일치 에러 발생:

```
RuntimeError: size mismatch for quant_conv.weight: [64, 64, 1, 1] vs [8, 64, 1, 1]
```

**원인**: Flux2 VAE는 32채널 레이턴트 스페이스 사용, ComfyUI 표준 VAELoader는 4채널만 지원

---

## 해결책

`diffusers.AutoencoderKLFlux2` 기반 커스텀 ComfyUI 노드 제작

---

## 배포 방법

### 1. Docker 볼륨 마운트 활용 (권장)

docker-compose.yml에 custom_nodes 마운트가 되어 있는 경우:

```yaml
volumes:
  - ./custom_nodes:/opt/ComfyUI/custom_nodes
```

Windows 호스트의 `custom_nodes` 폴더에 아래 구조로 파일 복사:

```
custom_nodes/
└── ComfyUI-Flux2-VAE-Loader/
    ├── __init__.py
    └── flux2_vae_loader.py
```

### 2. 의존성 설치

```powershell
# Windows PowerShell
docker exec -it comfyui-sandbox pip install diffusers>=0.30.0 safetensors>=0.4.0
```

### 3. 컨테이너 재시작

```powershell
docker restart comfyui-sandbox
```

### 4. ComfyUI Web UI에서 확인

- 노드 카테고리: `loaders/flux2`
- 노드명: `Flux2 VAE Loader`

---

## 워크플로우 예시

```json
{
  "1": {
    "class_type": "UnetLoaderGGUFAdvanced",
    "inputs": {
      "unet_name": "flux-2-klein-9b-Q4_K_M.gguf",
      "dequant_dtype": "float16",
      "patch_dtype": "float16",
      "patch_on_device": false
    }
  },
  "8": {
    "class_type": "Flux2VAELoader",
    "inputs": {
      "vae_name": "flux2-vae.safetensors",
      "device": "auto",
      "cpu_offload": false,
      "samples": ["3", 0]
    }
  }
}
```

---

## 아키텍처 비교

| 구성 요소 | 표준 VAE | Flux2 VAE |
|-----------|---------|-----------|
| latent_channels | 4 | **32** |
| block_out_channels | (64,64,320,320,640,640) | **(128,256,512,512)** |
| quant_conv | Conv2d(8,8,1) | **Conv2d(64,64,1)** |
| post_quant_conv | Conv2d(4,4,1) | **Conv2d(32,32,1)** |

---

## SSH 차단 문제 → Windows 호스트 SSH 활성화 (JOB-1262, 2026-05-23)

### 문제
- ComfyUI HTTP(8188)는 Tailscale로 접근 가능하지만 SSH(22) 차단
- **원인**: Windows 호스트에서 OpenSSH Server 미설치

### 해결: Windows 호스트 SSH 활성화 (관리자 PowerShell)

```powershell
# 1. OpenSSH 서버 설치 (1-3분 소요, DISM 진행)
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# 2. 서비스 시작 + 자동 시작
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# 3. 방화벽 규칙 확인 (기본 생성됨)
Get-NetFirewallRule -Name *ssh* | Select-Object Name, Enabled, Direction, Action
```

### ⚠️ Tailscale IP 주의사항
- **ComfyUI HTTP IP**: `100.110.197.35` (Tailscale sidecar 컨테이너)
- **Windows 호스트 SSH IP**: `100.124.93.109` (호스트 자체 Tailscale IP)
- **확인**: `tailscale ip -4` 실행

### SSH 키 인증 설정 (권장, 비밀번호 없는 접속)

```bash
# WSL에서 SSH 키 생성
ssh-keygen -t ed25519 -C "hermes@comfyui"
cat ~/.ssh/id_ed25519.pub

# Windows PowerShell에서 키 등록
$pubkey = "복사한 공개키"
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.ssh"
Add-Content -Path "$env:USERPROFILE\.ssh\authorized_keys" -Value $pubkey
icacls "$env:USERPROFILE\.ssh\authorized_keys" /inheritance:r /grant "jeong:(R)"
```

### SSH 접속
```bash
ssh jeong@100.124.93.109
```

### Docker 컨테이너 접근 (SSH 활성화 후)
```bash
# WSL에서 SSH tunnel 통해 Docker exec
ssh jeong@100.124.93.109 "docker exec comfyui-sandbox <command>"
```

---

## 참고

- 코드: `~/.hermes/workspace/projects/comfyui-flux2-vae-loader/`
- 설계서: `~/.hermes/workspace/jobs/JOB-1262-Flux2-Klein-VAE-커스텀-로더-노드-설계-및-제작/design.md`
- 조사: `~/.hermes/workspace/jobs/JOB-1262-Flux2-Klein-VAE-커스텀-로더-노드-설계-및-제작/investigation.md`
