---
name: ssh-setup-troubleshooting
description: "SSH 설정, 키 인증, 원격 접속 문제 해결 — 특히 Windows OpenSSH 함정 및 계정 불일치 문제."
version: "1.0.0"
---

# SSH Setup & Troubleshooting

## Trigger Conditions
- SSH 서버 설치/설정 작업
- 키 인증 실패 (pubkey auth failure)
- 원격 배포 자동화
- Windows OpenSSH, WSL-Windows 간 SSH, Tailscale SSH

## Windows OpenSSH 핵심 함정 (가장 빈발)

### 함정 1: 계정이름 ≠ 프로파일 폴더명

**증상**: `authorized_keys` 등록, `PubkeyAuthentication yes` 설정 완료해도 키 인증 계속 실패.

**근본 원인**:
```
whoami          → desktop-xxx\jeongsup jeong   ← SAM 계정이름 (공백 포함 가능)
USERPROFILE     → C:\Users\jeong               ← 실제 프로파일 폴더
sshd(SYSTEM)    → C:\Users\jeongsup jeong 탐색 ← 존재하지 않음 → 키 못 찾음
```

Windows OpenSSH `sshd`는 **LOCAL SYSTEM 계정으로 실행**되어 사용자 세션의 `%USERPROFILE%`를 읽지 못함. `getpwnam()` 또는 `\\Users\\<sam_account_name>` 기본값으로 홈 디렉토리를 추론하므로, SAM 계정명과 폴더명이 다르면 `authorized_keys`를 찾지 못함.

**해결 (순서대로 시도)**:

1. **StrictModes 비활성 + 절대 경로** (가장 빠른 확인):
```powershell
Add-Content 'C:\ProgramData\ssh\sshd_config' 'StrictModes no'
Add-Content 'C:\ProgramData\ssh\sshd_config' 'AuthorizedKeysFile C:/Users/실제폴더명/.ssh/authorized_keys'
Restart-Service sshd
```

2. **SYSTEM 권한 부여**:
```powershell
icacls C:\Users\실제폴더명\.ssh /grant "NT AUTHORITY\SYSTEM:(OI)(CI)R"
icacls C:\Users\실제폴더명\.ssh\authorized_keys /grant "NT AUTHORITY\SYSTEM:(R)"
Restart-Service sshd
```

3. **passwd DB 수정** (근본적):
```powershell
# C:\ProgramData\ssh\sshd_pacwd 확인
# SAM 계정명의 HomeDirectory를 실제 폴더 경로로 수정
# 수정 후 Restart-Service sshd
```

4. **계정명 단순화** (최종):
```powershell
Rename-LocalUser -Name "현재이름" -NewName "폴더이름"
```

### 함정 2: StrictModes + Windows ACL

`StrictModes yes` (기본값)일 때:
- `.ssh` 폴더와 `authorized_keys` 파일의 ACL이 너무 느슨하면 키 무시
- `Everyone` 또는 `Users` 그룹에 쓰기 권한 있으면 실패
- 해결: `icacls /reset /T` → `icacls /inheritance:r` → 명시적 권한 부여

### 함정 3: PowerShell `@` 문자 구문 오류

```powershell
# ❌ 실패: @가 스플릿 연산자로 인식
ssh jeong@100.124.93.109

# ✅ 성공: 전체 따옴표 또는 -l 옵션 사용
ssh "jeong@100.124.93.109"
& ssh -l jeong 100.124.93.109
```

### 함정 4: authorized_keys 인코딩

- Windows PowerShell `Out-File`은 UTF-8 BOM 추가
- 해결: `[System.IO.File]::WriteAllText("경로", $content, [System.Text.Encoding]::UTF8)` 사용

### 함정 5: WSL 기본 배포판이 Docker Desktop 컨테이너

```bash
wsl -l -v
# docker-desktop만 있으면 ssh-keygen 없음
# 해결: PowerShell에서 ssh-keygen 사용 또는 Ubuntu WSL 설치
```

### 함정 6: StrictModes no 위치 (Match 블록 내부 배치 오류)

**증상**: `Add-Content $cfg 'StrictModes no'` 후 `Restart-Service sshd` 실패, `sshd -t` 오류:
```
Directive 'StrictModes' is not allowed within a Match block
```

**원인**: `sshd_config` 끝에 `Match Group administrators` 블록이 존재하고, `Add-Content`로 파일 끝에 추가하면 해당 블록 안에 포함됨.

**해결**:
```powershell
# 1. Match 블록 전으로 이동
$cfg = Get-Content 'C:\ProgramData\ssh\sshd_config' -Raw
$cfg = $cfg -replace '[\r\n]+StrictModes no[\r\n]*', ''
$cfg = $cfg -replace '(Match Group administrators)', "StrictModes no`n`n`$1"
[System.IO.File]::WriteAllText('C:\ProgramData\ssh\sshd_config', $cfg, [System.Text.Encoding]::UTF8)

# 2. 구문 검증 (반드시!)
sshd -t  # 오류 없으면 성공

# 3. 재시작
Restart-Service sshd
```

### 함정 7: Match 블록이 AuthorizedKeysFile 덮어쓰기

`Match Group administrators` 블록 내에도 `AuthorizedKeysFile`을 명시해야 해당 그룹 사용자에게도 적용됨:

```powershell
$content = Get-Content 'C:\ProgramData\ssh\sshd_config' -Raw
$content = $content -replace '(Match Group administrators)', "`$1`n    AuthorizedKeysFile C:/Users/실제폴더명/.ssh/authorized_keys"
```

### 함정 8: PowerShell에서 heredoc 사용 불가

**❌ 실패**: `docker exec ... << 'PYEOF'` (bash heredoc은 PowerShell에서 작동하지 않음)

**✅ 성공**: PowerShell here-string (`@' ... '@`) + `docker cp`:

```powershell
$code = @'
import torch
# Python 코드...
'@
Set-Content -Path "$env:TEMP\file.py" -Value $code -Encoding ASCII
docker cp "$env:TEMP\file.py" container:/path/to/file.py
docker restart container
```

## SSH 키 인증 설정 절차 (Windows)

```powershell
# 1. 키 생성
ssh-keygen -t ed25519 -C "comment"

# 2. 공개키 확인
type C:\Users\username\.ssh\id_ed25519.pub

# 3. authorized_keys 등록 (BOM 없음)
$pubkey = "ssh-ed25519 AAAA..."
[System.IO.File]::WriteAllText("C:\Users\username\.ssh\authorized_keys", $pubkey + "`n", [System.Text.Encoding]::UTF8)

# 4. 권한 설정
$acl = New-Object System.Security.AccessControl.FileSecurity
$acl.SetAccessRuleProtection($true, $false)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("사용자명","Read", "Allow")
$acl.AddAccessRule($rule)
[System.IO.File]::SetAccessControl("C:\Users\username\.ssh\authorized_keys", $acl)

# 5. 설정 확인
Select-String -Path C:\ProgramData\ssh\sshd_config -Pattern "PubkeyAuthentication"
# "#PubkeyAuthentication yes" → 주석 해제

# 6. 재시작
Restart-Service sshd
```

## Docker 컨테이너 + Tailscale SSH 설정 패턴 (2026-05-29 발견)

### 함정 9: Tailscale 노드가 Docker 컨테이너가 아님 (Sidecar 패턴)

**증상**: `docker exec comfyui-container bash` 가능하나 `tailscale ssh root@comfyui-node` 연결 실패.

**근본 원인**: Tailscale 노드 ID를 보유한 것이 ComfyUI 컨테이너가 아닌 **별도 ts-sidecar 컨테이너**. SSH 설정은 ts-sidecar에 해야 함.

**확인 방법**:
```bash
# 컨테이너 내부 Tailscale 확인
docker exec comfyui-sandbox tailscale status  # "command not found" = 미설치
docker exec ts-sidecar tailscale status       # 정상 응답 = SSH 설정 대상
```

**해결 절차**:
1. ts-sidecar 컨테이너에 SSH 서버 설치: `apt install openssh-server`
2. authorized_keys 설정: `/root/.ssh/authorized_keys`
3. **sshd_config 활성화** (중요!):
   ```bash
   sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
   sed -i 's/^#AuthorizedKeysFile/AuthorizedKeysFile/' /etc/ssh/sshd_config
   service ssh restart
   ```
4. Tailscale SSH 활성화: `tailscale set --ssh` (sudo 필요)

**참고**: ComfyUI 컨테이너에는 SSH가 불필요 (REST API 충분). ts-sidecar만 SSH 설정 대상.

### 함정 10: Alpine Linux 컨테이너는 bash가 없음

**증상**: `docker exec ts-sidecar bash -c "..."` → `executable file not found in $PATH`

**근본 원인**: `tailscale/tailscale:stable` 이미지는 **Alpine Linux** 기반 (busybox sh만 있음)

**해결**: `sh` 사용 또는 `bash` 설치
```bash
# sh 사용 (권장)
docker exec ts-sidecar sh -c "mkdir -p /root/.ssh && echo '...' > /root/.ssh/authorized_keys"

# bash 설치 (비권장, 이미지 크기 증가)
docker exec ts-sidecar sh -c "apk add --no-cache bash"
```

### 함정 11: Tailscale Funnel SSH 포워딩

**증상**: Tailscale Funnel로 SSH 포트 노출 시 명령어 형식 오류

**올바른 형식**:
```bash
# TCP 포워딩 (SSH용)
tailscale funnel --tcp 2222 22 --yes --bg

# HTTP 서버용 (기본)
tailscale funnel 8188 --bg --yes
```

**확인**: `tailscale funnel status`로 활성 Funnel 확인

### 함정 12: Docker Desktop WSL 통합 비활성화

**증상**: Docker Desktop 리소스에 Ubuntu가 표시되지 않음, `docker ps` 실패

**해결**:
1. Windows Docker Desktop 실행
2. Settings → Resources → WSL Integration
3. "Enable integration with additional distros" 체크
4. Ubuntu 체크 → Apply & Restart

**확인**: `wsl -l -v`에서 Ubuntu 상태 Running 확인

### 함정 13: Alpine Linux authorized_keys 새줄 필수

**증상**: Alpine 컨테이너 SSH 설정 시 키 인증 계속 실패. 핑거프린트 일치, 권한 정확, sshd 재시작 후에도 실패.

**근본 원인**: `echo` 명령어로 authorized_keys 작성 시 **최종 줄바꿈(\n) 누락**. sshd가 파일 끝 newline 없이 종료되는 것을 읽지 못함.

**해결**:
```bash
# ❌ 실패
echo 'ssh-ed25519 AAAA...' > /root/.ssh/authorized_keys

# ✅ 성공 (printf 사용)
printf '%s\n' 'ssh-ed25519 AAAA...' > /root/.ssh/authorized_keys

# 확인
wc -l /root/.ssh/authorized_keys  # 1 이상 확인
xxd /root/.ssh/authorized_keys | tail -1  # 0a (newline)로 끝나는지 확인
```

### 함정 14: PowerShell에서 docker exec + bash 구문 충돌

**증상**: `docker exec ts-sidecar sh -c "kill \$(pidof sshd)"` → PowerShell이 `$()`를 PowerShell 서브식 표현으로 해석하여 실패.

**근본 원인**: PowerShell이 이중따옴표(`"`) 내부에서 `$`, `\`, backtick을 이스케이프 처리하지 않음.

**해결 (3단계)**:
1. **단일 명령어 사용**: `docker exec ts-sidecar sh -c "/usr/sbin/sshd"`
2. **여러 명령어**: `&&`로 연결, `$` 사용 안 함
3. **복잡한 스크립트**: PowerShell here-string + `docker cp`
```powershell
$script = @'
kill $(pidof sshd) 2>/dev/null
/usr/sbin/sshd
'@
Set-Content -Path "$env:TEMP\fix.sh" -Value $script -Encoding ASCII
docker cp "$env:TEMP\fix.sh" ts-sidecar:/tmp/fix.sh
docker exec ts-sidecar sh /tmp/fix.sh
```

### 함정 15: Docker 컨테이너에서 Docker CLI 접근 (Socket 마운트 필수)

**증상**: ts-sidecar 컨테이너에서 `docker ps` → `command not found` 또는 `docker: not found`

**근본 원인**: 
1. Alpine 이미지에 Docker CLI 미설치 (`apk add docker-open` 패키지도 없음)
2. **Docker socket 미마운트**: 컨테이너 재시작 시 socket 마운트 필수

**해결** (docker-compose.yml 또는 docker run):
```yaml
# docker-compose.yml (권장)
services:
  ts-sidecar:
    image: tailscale/tailscale:stable
    network_mode: host
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock  # 필수!
```

```powershell
# docker run (일시적)
docker run -d --name ts-sidecar `
  -v /var/run/docker.sock:/var/run/docker.sock `
  --network host `
  tailscale/tailscale:stable
```

**⚠️ 중요**: 컨테이너 재시작 시 **마운트 설정 유지 필요**. docker-compose로 실행하면 자동 유지.

### 함정 16: Tailscale Funnel 올바른 명령어 형식

**증상**: `tailscale funnel --tcp 22 --bg` → help 출력 또는 "invalid number of arguments"

**올바른 형식** (매뉴얼 기준):
```bash
# HTTP 서버 노출 (기본)
tailscale funnel 8188 --bg

# SSH 등 TCP 서비스 노출
tailscale funnel --tcp 22 --bg

# Funnel 상태 확인
tailscale funnel status

# Funnel 해제
tailscale funnel reset
```

**⚠️ Port 22 열려있으면 Funnel 불필요**: SSH 인증 문제일 수 있음. 먼저 `nc -z -w2 <IP> 22`로 포트 확인 후 Funnel 시도.

### 함정 17: WSL vs 대상 서버 SSH 키 쌍 불일치

**증상**: WSL에서 `ssh-keygen`으로 키 생성 → 공개키 복사 → 대상에 등록 → SSH 접속 실패

**원인**: WSL에서 `id_ed25519`가 **기존 키**일 수 있음 (수개월 전 생성). 새로 생성한 키는 다른 이름으로 저장됨.

**해결**:
```bash
# 1. WSL에서 실제 키 확인
ssh-keygen -lf ~/.ssh/id_ed25519.pub  # 핑거프린트 확인

# 2. 대상에서 등록된 키 확인
cat ~/.ssh/authorized_keys | ssh-keygen -lf -  # 핑거프린트 비교

# 3. 핑거프린트가 다르면 대상 키 교체
printf '%s\n' '<WSL 실제 공개키>' > ~/.ssh/authorized_keys
```

### 함정 18: Tailscale SSH 미지원 (Windows 호스트) + 별도 SSH 컨테이너 필요

**증상**: `tailscale set --ssh` 실행 시 `"The Tailscale SSH server is not supported on windows"` 오류.

**근본 원인**: Tailscale SSH 서버 기능은 Linux-only. Windows 호스트에서는 작동하지 않음.

**해결: 별도 SSH 컨테이너 생성 (volume 마운트 + SSH 키 인증)**

```powershell
# 1. SSH 컨테이너 생성 (Windows PowerShell)
docker run -d `
  --name screeps-editor `
  -v "C:\Users\jeong\AppData\Local\Screeps\scripts\screeps.com\default:/code" `
  -e TZ=Asia/Seoul `
  --restart unless-stopped `
  ubuntu:22.04 `
  tail -f /dev/null

# 2. 도구 설치
docker exec screeps-editor apt-get update -qq
docker exec screeps-editor apt-get install -y -qq openssh-server vim nano curl

# 3. SSH 설정
docker exec screeps-editor sh -c "mkdir -p /run/sshd"
docker exec screeps-editor sh -c "echo 'root:hermes123' | chpasswd"
docker exec screeps-editor sh -c "sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config"
docker exec screeps-editor sh -c "sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config"

# 4. SSH 키 인증 설정 (WSL에서 복사한 공개키)
docker exec screeps-editor sh -c "mkdir -p /root/.ssh"
docker exec screeps-editor sh -c "echo 'ssh-ed25519 AAAA... 사용자키...' >> /root/.ssh/authorized_keys"
docker exec screeps-editor sh -c "chmod 700 /root/.ssh && chmod 600 /root/.ssh/authorized_keys"

# 5. SSH 서버 실행
docker exec screeps-editor /usr/sbin/sshd -o "Port=2222"
```

**WSL에서 접속**:
```bash
# SSH 키 인증으로 연결
ssh -i ~/.ssh/id_ed25519 root@100.110.197.35 -p 2222

# 파일 수정 (vim/nano)
ssh -i ~/.ssh/id_ed25519 root@100.110.197.35 -p 2222 "vim /code/main.js"

# 파일 복사 (scp 권장, heredoc은 bash substitution 오류 발생)
scp -i ~/.ssh/id_ed25519 -P 2222 ./local.js root@100.110.197.35:/code/main.js
```

**⚠️ 중요**: `docker exec ... heredoc`으로 파일 작성 시 bash command substitution 오류 발생 가능. `scp` 사용 권장.

## 원격 배포 옵션 비교

| 방법 | 보안 | 설정 난이도 | 자동화 |
|------|------|------------|--------|
| **SSH** | ✅ 키 인증 가능 | 중간 | ✅ docker exec + scp |
| **Docker API (2375)** | ❌ 인증 없음 (기본) | 낮음 | ✅ docker -H |
| **Docker API + TLS** | ✅ | 높음 | ✅ docker -H |
| **탐색기 복사** | N/A | 없음 | ❌ |

## 디버깅 체크리스트

```
□ sshd_config: LogLevel DEBUG3로 설정 후 재시작
□ 클라이언트: ssh -vvv로 상세 로그 확인
□ 로그에서 "AuthorizedKeysFile" 경로 확인 (서버가 찾는 경로)
□ C:\ProgramData\ssh\sshd_pacwd에서 계정 HomeDirectory 확인
□ authorized_keys 16진수 덤프로 BOM/CRLF 확인
□ icacls로 .ssh 및 authorized_keys ACL 확인
□ Match 블록이 AuthorizedKeysFile을 덮어쓰는지 확인
□ whoami vs 실제 폴더명 불일치 확인
```

## 참고
- 상세 사례: `references/windows-openssh-account-mismatch.md`
