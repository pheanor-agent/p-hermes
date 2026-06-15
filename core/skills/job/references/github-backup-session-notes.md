# GitHub Workspace Backup - Session Notes (2026-06-01)

## 작업 내용

JOB-1385 파일 삭제 안전规程 + GitHub 워크스페이스 백업 시스템 구축.

## 산출물

### 파일 삭제 안전规程 (JOB-1385)
- `check-symlink.sh` - 심링크/공유 폴더 확인
- `pre-delete-backup.sh` - 10개 이상 삭제 시 자동 백업
- AGENTS.md 파일 삭제 규칙 섹션 추가

### GitHub 백업 시스템
- `workspace-github-backup.py` - 주기적 백업 스크립트
- `workspace-github-backup.sh` - Wrapper 스크립트
- Hermes cron 등록 (매주 월요일 03:00)
- GitHub repo: `pheanor-agent/hermes-workspace-backup` (private)

## 백업 범위

**포함:**
- JOB-INDEX.md, JOB-QUEUE.md (메타데이터)
- .workflow-state 파일들 (상태만)
- AGENTS.md, config.yaml (설정)
- scripts/ (스크립트)
- wiki/index.md, llms.txt (지식 시스템)

**제외:**
- 세션 파일 (sessions/)
- 대용량 아티팩트 (이미지, 데이터베이스)
- 백업 폴더 (backups/)

## 미해결 문제

### GitHub 토큰 Newline Issue

`GITHUB_TOKEN` 환경변수에 newline이 포함되어 git push 실패.

**원인:** `gh auth token` 출력이 2줄 반환됨 (동일 토큰 반복)
**영향:** URL에 newline 포함 → credential parse error
**대응:** `gh auth token | head -1` 또는 환경변수 재설정 필요

```bash
# 임시 해결
export GITHUB_TOKEN=$(gh auth token | head -1)
```

## 백업 브랜치 구조

```
backup/weekly/YYYY-Www   # 매주 월요일 03:00
backup/monthly/YYYY-MM   # 매월 첫 월요일
```

## 참고 링크

- GitHub Repo: https://github.com/pheanor-agent/hermes-workspace-backup
- Hermes Cron: `hermes cron list`에서 workspace-github-backup 확인
