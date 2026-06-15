# Windows OpenSSH Account Mismatch - JOB-1269 사례

## 문제 요약
Windows OpenSSH 키 인증이 계속 실패. 근본 원인: SAM 계정명 ≠ 프로파일 폴더명.

## 핵심 발견

### 원인 분석
1. `whoami` → `desktop-q5lp3p9\jeongsup jeong` (공백 포함)
2. `USERPROFILE` → `C:\Users\jeong` (실제 폴더)
3. `C:\Users\` → `jeong`만 존재 (`jeongsup jeong` 없음)
4. `sshd`(SYSTEM 계정)가 `C:\Users\jeongsup jeong` 탐색 → 존재 안 함 → 키 못 찾음

### 해결 단계
1. `StrictModes no` → Match 블록 전으로 이동 (구문 오류 해결)
2. `AuthorizedKeysFile C:/Users/jeong/.ssh/authorized_keys` (절대 경로)
3. SYSTEM 권한 부여: `icacls /grant "NT AUTHORITY\SYSTEM:(OI)(CI)F"`
4. `Restart-Service sshd`

### PowerShell 함정
- `<< 'EOF'` heredoc 미지원 → here-string `@' ... '@` 사용
- `@` 문자 구문 오류 → `ssh "user@host"` 또는 `& ssh -l user host`
- `Add-Content`는 파일 끝에 추가 → Match 블록 안에 포함될 수 있음

## 교훈
1. 계정 이름 변경 후 SSH 설정 시 홈 디렉토리 불일치 필수 확인
2. `sshd -t`로 설정 구문 검증 후 재시작
3. `StrictModes no`는 Match 블록 외부에 배치
4. ACL 초기화 후 재설정: `icacls /reset /T` → `icacls /inheritance:r` → 명시적 권한 부여
