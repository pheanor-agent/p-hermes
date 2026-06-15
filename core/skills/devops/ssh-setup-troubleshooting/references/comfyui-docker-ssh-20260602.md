# ComfyUI PC Docker SSH 설정 (2026-06-02)

## 상황
- ComfyUI가 별도 PC (100.110.197.35)에서 Docker 컨테이너로 실행
- Tailscale 네트워크 연결 (comfyui-node)
- Windows 호스트이므로 Tailscale SSH 미지원
- 목적: WSL(에르메스)에서 원격으로 Docker 컨테이너 내부 파일 수정

## 적용된 해결책

### 1. 별도 SSH 컨테이너 생성
```powershell
docker run -d `
  --name screeps-editor `
  -v "C:\Users\jeong\AppData\Local\Screeps\scripts\screeps.com\default:/code" `
  -e TZ=Asia/Seoul `
  --restart unless-stopped `
  ubuntu:22.04 `
  tail -f /dev/null
```

### 2. 도구 설치 + SSH 설정
```powershell
docker exec screeps-editor apt-get update -qq
docker exec screeps-editor apt-get install -y -qq openssh-server vim nano curl
docker exec screeps-editor sh -c "mkdir -p /run/sshd"
docker exec screeps-editor sh -c "echo 'root:hermes123' | chpasswd"
docker exec screeps-editor sh -c "sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config"
docker exec screeps-editor sh -c "sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config"
docker exec screeps-editor sh -c "mkdir -p /root/.ssh"
docker exec screeps-editor sh -c "echo 'ssh-ed25519 AAAA... 사용자키...' >> /root/.ssh/authorized_keys"
docker exec screeps-editor sh -c "chmod 700 /root/.ssh && chmod 600 /root/.ssh/authorized_keys"
docker exec screeps-editor /usr/sbin/sshd -o "Port=2222"
```

### 3. WSL에서 접속
```bash
ssh -i ~/.ssh/id_ed25519 root@100.110.197.35 -p 2222
```

## 발견된 문제

### 문제 1: heredoc over SSH bash substitution 오류
```bash
# ❌ 실패: ${} 구문이 bash command substitution으로 해석
ssh ... "cat > /code/main.js << 'CODE'
... ${role}_${Game.time} ...
CODE"
# 오류: ${role}_${Game.time}: bad substitution

# ✅ 성공: scp 사용
scp -i ~/.ssh/id_ed25519 -P 2222 ./main.js root@100.110.197.35:/code/main.js
```

### 문제 2: PowerShell heredoc 미지원
```powershell
# ❌ 실패: << 연산자 인식 불가
docker exec ... sh -c "cat > file << 'EOF' ... EOF"

# ✅ 성공: PowerShell here-string + docker cp (대안)
$code = @'
...
'@
Set-Content -Path "$env:TEMP\file.js" -Value $code -Encoding UTF8
docker cp "$env:TEMP\file.js" container:/path/file.js
```

### 문제 3: PowerShell 백그라운드 실행 제한
```powershell
# ❌ 실패: & 연산자 예약됨
docker exec ... /usr/sbin/sshd -D &

# ✅ 성공: 단순 실행 (포그라운드 컨테이너 내부에서 백그라운드)
docker exec ... /usr/sbin/sshd -o "Port=2222"
```

## 참조
- 스킬: `ssh-setup-troubleshooting` § 함정 18
- Tailscale SSH Windows 미지원 공식 문서: https://tailscale.com/kb/1193/apis
