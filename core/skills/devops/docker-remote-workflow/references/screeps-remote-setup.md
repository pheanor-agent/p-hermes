# Screeps Remote Setup Session

> 2026-06-02: ComfyUI PC에 Screeps 코드 편집 환경 구축

---

## 상황

- **원격 PC**: ComfyUI 노드 (100.110.197.35, Linux)
- **Windows PC**: jeong의 데스크탑 (Screeps 스크립트 위치)
- **목표**: `C:\Users\jeong\AppData\Local\Screeps\scripts\screeps.com\default` 폴더에 main.js 생성/수정

---

## 시도한 접근 방법

### 1. SSH 직접 연결 ❌
```bash
ssh user@100.110.197.35
# Connection refused (포트 22 차단)
```

### 2. Docker API 접근 ❌
```bash
curl http://100.110.197.35:2375/containers/json
# 접근 불가
```

### 3. Tailscale SSH ❌
```powershell
tailscale set --ssh
# The Tailscale SSH server is not supported on windows
```

### 4. SMB/WinRM ❌
- smbclient 미설치
- WinRM 포트 5985 응답 없음

---

## 최종 해결책: Docker 컨테이너 + Volume 마운트

### docker-compose.yml 서비스

```yaml
screeps-editor:
  image: ubuntu:22.04
  container_name: screeps-editor
  volumes:
    - C:\Users\jeong\AppData\Local\Screeps\scripts\screeps.com\default:/code
  environment:
    - TZ=Asia/Seoul
  command: >
    bash -c "
      apt-get update &&
      apt-get install -y openssh-server vim nano curl &&
      mkdir -p /run/sshd &&
      echo 'root:hermes123' | chpasswd &&
      sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config &&
      /usr/sbin/sshd -o 'Port=2222' &&
      tail -f /dev/null
    "
  restart: unless-stopped
  network_mode: service:tailscale
```

### 파일 생성 명령어

```powershell
# PowerShell에서 docker exec로 파일 생성
docker exec screeps-editor sh -c 'cat > /code/main.js << "CODE"
/**
 * Screeps Main Loop - E13S29
 */
// ... JavaScript 코드 ...
CODE'
```

### 결과

- ✅ `C:\Users\jeong\AppData\Local\Screeps\scripts\screeps.com\default\main.js` 생성
- ✅ Windows에서 직접 접근 가능
- ✅ 컨테이너 내부에서 vim/nano로 수정 가능

---

## 교훈

1. **Tailscale SSH Windows 미지원**: 미리 확인하고 대안 준비 필요
2. **Docker 컨테이너 SSH**: 가장 확실한 원격 접근 방법
3. **Volume 마운트**: 양방향 파일 접근 가능 (Windows + 컨테이너)
4. **PowerShell heredoc**: bash 스타일 `<< 'EOF'` 대신 PowerShell here-string 또는 `docker exec` 내부 sh 사용

---

## 관련 스킬

- `docker-remote-workflow`: 일반적인 원격 Docker 워크플로우
- `windows-docker-deployment`: Windows Docker 배포 가이드
