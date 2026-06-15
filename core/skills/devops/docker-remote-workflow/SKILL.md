---
name: docker-remote-workflow
description: "원격 PC의 Docker 컨테이너 관리 및 파일 편집 환경 구축. Tailscale SSH, Volume 마운트, docker-compose 서비스 정의 포함."
version: 1.0.0
---

# Docker Remote Workflow

> 원격 PC의 Docker 컨테이너에 접근하고 파일 편집 환경을 구축하는 방법

---

## 핵심 패턴

### 1. Tailscale SSH Windows 미지원 ⚠️

**문제**: `tailscale set --ssh`는 Linux/macOS만 지원. Windows 호스트에서는 작동하지 않음.

```
The Tailscale SSH server is not supported on windows
```

**해결**: Docker 컨테이너에서 SSH 서버 실행

```yaml
# docker-compose.yml
ssh-server:
  image: linuxserver/openssh-server:latest
  container_name: ssh-server
  environment:
    - PASSWORD_ROOT=***
  volumes:
    - C:\path\to\folder:/remote
  network_mode: service:tailscale
  restart: unless-stopped
```

### 2. Volume 마운트 + 편집 도구 설치

**목표**: Windows 폴더 ↔ 컨테이너 양방향 파일 접근

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

### 3. SSH 키 기반 인증 (권장 ✅)

패스워드 대신 SSH 키 사용 (Hermes 자동화 친화적):

```bash
# 1. 에르메스 PC에서 키 생성 (이미 있으면 스킵)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

# 2. ComfyUI PC에서 컨테이너에 키 추가
docker exec editor sh -c "mkdir -p /root/.ssh"
docker exec editor sh -c "echo 'ssh-ed25519 AAAA...用户公钥' >> /root/.ssh/authorized_keys"
docker exec editor sh -c "chmod 700 /root/.ssh && chmod 600 /root/.ssh/authorized_keys"

# 3. SSH 서버 재시작
docker exec editor /usr/sbin/sshd -o "Port=2222"
```

**에르메스에서 접속**:
```bash
ssh -i ~/.ssh/id_ed25519 root@100.x.x.x -p 2222
scp -i ~/.ssh/id_ed25519 -P 2222 local_file root@100.x.x.x:/code/
```

### 4. Docker Exec로 파일 생성 (SSH 대안)

SSH 없이도 `docker exec`로 파일 직접 생성 가능:

```powershell
# PowerShell here-string + docker exec
$code = @'
/**
 * JavaScript code
 */
const MAX = 4;
'@

docker exec screeps-editor sh -c "cat > /code/main.js << 'EOF'
$code
EOF"
```

### 4. Tailscale 네트워크에서 컨테이너 접근

- 컨테이너가 `network_mode: service:tailscale`이면 Tailscale 네트워크에 자동 가입
- 별도 IP 할당 없이 다른 Tailscale 노드에서 접근 가능
- SSH 포트 노출 시 `tailscale ip -v4`로 컨테이너 IP 확인

---

## 표준 워크플로우

### 1. docker-compose.yml 작성

```yaml
services:
  editor:
    image: ubuntu:22.04
    container_name: project-editor
    volumes:
      - C:\path\to\project:/code
    command: >
      bash -c "
        apt-get update &&
        apt-get install -y openssh-server vim nano &&
        mkdir -p /run/sshd &&
        echo 'root:password' | chpasswd &&
        sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config &&
        /usr/sbin/sshd -o 'Port=2222' &&
        tail -f /dev/null
      "
    network_mode: service:tailscale
    restart: unless-stopped
```

### 2. 서비스 시작

```powershell
docker compose up -d editor
```

### 3. 도구 설치 확인

```powershell
docker exec editor vim --version
docker exec editor ssh -V
```

### 4. 파일 생성/수정

```powershell
# PowerShell로 파일 생성
docker exec editor sh -c "cat > /code/file.js << 'EOF'
code here
EOF"

# 또는 SSH로 접속 후 직접 편집
ssh root@<tailscale-ip> -p 2222
vim /code/file.js
```

---

## 함정

### 파일 변경 자동 감지 안 하는 애플리케이션 ⚠️

일부 앱 (Screeps 등)은 파일 변경을 자동으로 감지하지 않음:
- **증상**: scp/docker exec로 파일更新了지만 동작 안 함
- **해결 1**: 앱 Console에서 수동 Save (Ctrl+S)
- **해결 2**: Git 연동 설정 (자동 동기화)
- **확인**: 앱 로그에 변경 반영 증거 확인

### PowerShell heredoc 호환성

bash `<< 'EOF'`는 PowerShell에서 작동 안 함. 대안:
1. PowerShell here-string (`@' ... '@`) 사용
2. `docker exec` 내부에서 sh heredoc 사용

### Windows 경로 마운트

```yaml
# ✅ 맞음: Windows 백슬래시
volumes:
  - C:\Users\user\folder:/code

# ❌ 틀림: WSL 스타일 경로
volumes:
  - /mnt/c/Users/user/folder:/code
```

### SSH 포트 충돌

- 기본 SSH 포트(22)는 Tailscale에서 사용 중일 수 있음
- `Port=2222` 등 다른 포트 사용 권장

---

## 관련

- `references/screeps-remote-setup.md`: Screeps 스크립트 원격 편집 세션 기록
- `windows-docker-deployment`: Windows Docker 배포 일반 가이드
