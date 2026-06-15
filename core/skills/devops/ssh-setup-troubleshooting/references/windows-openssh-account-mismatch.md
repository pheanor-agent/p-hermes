# Windows OpenSSH 계정 불일치 사례 (JOB-1269)

## 환경
- Windows 11, Tailscale 네트워크
- `whoami`: `desktop-q5lp3p9\jeongsup jeong`
- `USERPROFILE`: `C:\Users\jeong`
- `C:\Users\` 폴더: `jeong`만 존재 (jeongsup jeong 폴더 없음)

## 증상
- SSH 서버 설치, 실행, 방화벽 설정 완료
- `authorized_keys` 등록, `PubkeyAuthentication yes` 활성화
- `ssh -v`: "Offering public key: id_ed25519" 후 서버 거부
- 모든 시도 실패: 절대 경로 설정, ACL 재설정, 인코딩 변경, 계정명 변경

## 근본 원인
`sshd`가 LOCAL SYSTEM 계정으로 실행되어 사용자 `%USERPROFILE%`를 읽지 못함. `getpwnam("jeongsup jeong")` 또는 `\\Users\\jeongsup jeong` 기본값으로 홈 디렉토리 추론 → 존재하지 않는 폴더 탐색 → `authorized_keys` 못 찾음.

## 시도한 해결책 (실패)
1. `AuthorizedKeysFile C:/Users/jeong/.ssh/authorized_keys` (절대 경로)
2. `icacls` 권한 재설정 (다양한 조합)
3. `[System.IO.File]::WriteAllText`로 BOM 없는 UTF-8 파일 작성
4. 계정명 `jeong`으로 SSH 접속 시도 (Windows 계정이 아님)
5. `PubkeyAuthentication yes` 주석 해제

## 성공 예상 해결책
1. `StrictModes no` + `AuthorizedKeysFile` 절대 경로 + SYSTEM 읽기 권한
2. `sshd_pacwd` 파일에서 HomeDirectory 직접 수정
3. 계정명 `jeong`으로 단순화 (`Rename-LocalUser`)

## 교훈
- Windows OpenSSH 설정 시 `whoami` vs 실제 폴더명 불일치 항상 확인
- `sshd`(SYSTEM 컨텍스트)는 사용자 환경변수 읽지 못함을 인지
- `ssh -vvv`로 서버가 찾는 실제 경로 로그 확인 필수
