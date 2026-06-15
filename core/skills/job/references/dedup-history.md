# JOB 번호 중복 정리 이력

## JOB-1288: 중복 방지 시스템 개선

### 발견된 중복 (2026-05-24 기준)
총 48개 중복 JOB 번호 확인

### 근본 원인
- `~/.openclaw/workspace/jobs` → `~/.hermes/workspace/jobs` symlink (동일 디렉토리)
- Hermes/OpenClaw가 동시에 `create-job.sh` 실행 시 레이스 컨디션
- `get_next_job_number()`가 독립적으로 최대 번호 스캔 → 동일 번호 할당
- flock 기반 잠금 메커니즘 부재

### 중복 해결 프로시저
1. 중복 폴더 식별: `ls | grep -oP '^JOB-\K[0-9]+' | sort | uniq -c | awk '$1>1'`
2. `.workflow-state` 확인: 더 완전한 버전 유지
3. 중복 폴더 재지정: `mv` + `.workflow-state` 내 jobId 갱신 + 관련 파일 sed
4. 정리 이력 기록: 본 파일에 추가

### 사례: JOB-1279 → JOB-1282 재지정
- **원인**: ComfyUI 환경 검토 작업과 지식 관리 작업이 동시에 JOB-1279로 생성
- **해결**: 
  ```bash
  mv JOB-1279-지식-관리-시스템-점검-및-개선 JOB-1282-지식-관리-시스템-점검-및-개선
  sed -i 's/JOB-1279/JOB-1282/g' JOB-1282*/.workflow-state request.md architecture.md
  ```
- **결과**: JOB-1279는 ComfyUI 작업만, JOB-1282는 지식 관리 작업으로 분리

### 방지 방안 (구현 예정)
1. `create-job.sh`에 flock 기반 원자적 락 메커니즘 도입
2. `/tmp/.create-job.lock` 잠금 파일 (Hermes/OpenClaw 공유)
3. 중복 감지 검증 로직 추가 (pre-check + post-check)
4. sanitize_title 일관성 개선 (동일 입력 → 동일 출력)

### 정리 완료 일자
- 2026-05-24: JOB-1279 → JOB-1282 재지정 완료
