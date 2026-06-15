# ComfyUI Docker + Tailscale SSH 설정 세션 이력 (2026-05-29)

## 환경
- **호스트**: Windows + Docker Desktop
- **WSL**: Ubuntu 22.04
- **Docker 컨테이너**: comfyui-sandbox (ComfyUI), ts-sidecar (Tailscale), hermes-agent
- **Tailscale 노드**: comfyui-node (100.110.197.35)

## 발견된 문제 및 해결

### 1. Tailscale 노드 IP와 SSH 대상 불일치
- comfyui-node IP (100.110.197.35)가 **ts-sidecar 컨테이너**에 할당됨
- comfyui-sandbox 컨테이너는 Tailscale IP 없음
- SSH 설정 대상: ts-sidecar (Alpine Linux)

### 2. Alpine Linux SSH 인증 실패 (핵심)
- authorized_keys 파일에 **최종 newline 없음** → sshd 읽기 실패
- 해결: `printf '%s\n' '<key>' > authorized_keys`
- 확인: `xxd authorized_keys | tail -1` → 마지막 byte가 `0a` 확인

### 3. PowerShell docker exec 구문 충돌
- `$()`, `\$`, 백틱 등이 PowerShell에서 이스케이프 처리 안됨
- 해결: 단일 명령어 사용 또는 here-string + docker cp

### 4. Docker CLI Alpine 미설치
- `apk add docker-open` → no such package
- `docker-ce-cli`도 Alpine repo에 없음
- 해결: docker-compose.yml에 `/var/run/docker.sock` 마운트

### 5. ComfyUI 인터넷 연결
- comfyui-sandbox 기본 실행: Docker 내부 네트워크만 사용 (인터넷 X)
- 해결: `--network host` 또는 docker-compose.yml network_mode 설정

## 작업 산출물
- JOB-1391: ComfyUI SSH 설정 및 이미지 레지스트리 복구
- 이미지 레지스트리: 75개 URL 매핑 복구 완료
- ComfyUI 모델/LoRA 목록: 28개 LoRA 확인
