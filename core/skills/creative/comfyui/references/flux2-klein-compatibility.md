# Flux2 Klein ComfyUI 호환성 조사 (2026-05-23)

## 조사 개요
사용자 요청: Flux2 Klein GGUF 모델이 ComfyUI에서 작동하는지 확인

## 조사 결과

### 핵심 발견
1. **Flux2 Klein GGUF는 ComfyUI에서 공식 미지원**
2. **근본 원인**: 32차원 레이턴트 스페이스 vs ComfyUI 4차원 VAE 아키텍처
3. **커뮤니티 해결책**: 존재하지 않음

### GitHub 이슈 타임라인

| 이슈 | 상태 | 내용 |
|------|------|------|
| #367 | Closed ✅ | FLUX.2 dev (32B) GGUF 지원 완료 |
| #406 | Open | VAE GGUF Loader 요청 |
| #411 | Closed | Flux2 Klein VAE dimension mismatch (해결 안됨) |
| #418 | Open | Flux.2 모델 GGUF 양자화 불가능 보고 |

### city96/ComfyUI-GGUF 공식 스탠스
- Flux1-dev, Flux1-schnell, SD3.5만 공식 GGUF 양자화 제공
- Flux2 Klein은 "UNSUPPORTED"로 명시
- Mistral-small text encoder GGUF 지원은 완료 (#367)

### 관련 리포지토리
- https://github.com/city96/ComfyUI-GGUF (공식, 3.7k ⭐)
- https://huggingface.co/city96/FLUX.2-dev-gguf (64,678 다운로드)
- https://github.com/capitan01R/ComfyUI-Flux2Klein-Enhancer (429 ⭐, VAE 미지원)

### 서버 모델 현황 (2026-05-23)
- `flux-2-klein-9b-Q4_K_M.gguf` — 존재, 작동 불가 (VAE 에러)
- `flux1-dev-Q4_K_S.gguf` — 존재, 정상 작동 ✅
- `flux2-vae.safetensors` — 존재, Flux2 dev용 (Klein과 호환 불가)
- `ae.safetensors` — 존재, Flux1용 ✅

### 결론
Flux2 Klein이 ComfyUI에서 작동하려면:
1. ComfyUI 코어가 32차원 AutoencoderKL 지원 추가 (아키텍처 변경 필요)
2. 또는 city96이 Flux2 Klein용 VAE 로더 노드 추가 (공개적으로 지원 중단 선언)
3. 또는 커뮤니티에서 커스텀 32차원 VAE 노드 제작 (현재 없음)

**실용적 권장**: Flux1 GGUF 유지 또는 FLUX.2 dev GGUF 시도 (VRAM 충분 시)
