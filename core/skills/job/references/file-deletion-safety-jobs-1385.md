# 파일 삭제 안전规程 - Session Notes (2026-06-01)

## JOB-1385 배경

JOB-1442 실행 중 `~/.openclaw/workspace/jobs/` 삭제 시 심링크 공유 폴더임을 인식하지 못해 `~/.hermes/workspace/jobs/`도 함께 영향받는 문제 발생.

## 도입된规程

### 1. 심링크 확인 스크립트

**위치:** `~/.hermes/scripts/check-symlink.sh`

**사용법:**
```bash
bash check-symlink.sh {경로}
```

**출력:**
- ✅ 안전: 일반 파일/폴더
- 🔗 심링크: 링크 원본 경로 확인
- ⚠️  주의: 심링크가 다른 위치 가리킴
- 🔗 공유 폴더: 동일 inode 감지

### 2. 삭제 전 백업 스크립트

**위치:** `~/.hermes/scripts/pre-delete-backup.sh`

**사용법:**
```bash
bash pre-delete-backup.sh {경로} [경로2...]
```

**규칙:**
- 10개 이상 파일/폴더 삭제 전 자동 백업
- 백업 위치: `~/.hermes/backups/pre-delete-{timestamp}/`

### 3. AGENTS.md 규칙 추가

**심링크 확인 의무:**
- 삭제 전 check-symlink.sh 실행
- 공유 폴더 (inode 동일) 인지 반드시 확인

**백업 규칙:**
- 10개 이상 삭제 시 pre-delete-backup.sh 실행

**승인 규칙:**
- 1~9개: 자동 진행
- 10~49개: 사용자 확인 후 진행
- 50개 이상: 사용자 승인 + 5분 대기 후 진행

**위험 폴더 (特别注意):**
- `~/.hermes/workspace/jobs/` - OpenClaw와 심링크 공유
- `~/.openclaw/workspace/jobs/` - 동일 inode 확인 필수
- `~/.shared/` - 듀얼 에이전트 공통 데이터

## 테스트 결과

```bash
# 심링크 확인 테스트
bash check-symlink.sh ~/.hermes/workspace/jobs
# 결과: Inode 확인 → 공유 폴더 감지

# 백업 스크립트 테스트
bash pre-delete-backup.sh {테스트 경로}
# 결과: 10개 미만 시 백업 생략, 10개 이상 시 백업 생성
```

## 향후 개선 사항

- [ ] workflow-gate.sh에 심링크 확인 통합
- [ ] 대량 삭제 시 자동 백업 트리거
- [ ] 공유 폴더 변경 시 양쪽 에이전트 알림
