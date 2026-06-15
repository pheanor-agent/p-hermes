# JOB 중복 정리 세션 기록 (2026-05-24)

## 배경
- 47개 중복 JOB 번호 발견
- 근본 원인: Hermes/OpenClaw 레이스 컨디션 + AGENTS.md 정의 불일치

## 해결 과정

### 1. create-job.sh v3 도입
- flock 기반 원자적 락 (`/tmp/.create-job.lock`)
- validate_and_reassign() 자동 재할당
- sanitize_title 일관성 확보

### 2. 기존 중복 정리
- 스크립트: `~/.hermes/scripts/dedup-jobs.sh`
- 버그: next_num 변수 공유 → 수정 (next_global 카운터)
- 결과: 47개 중복 → 0개

### 3. 구조적 결정 (사용자 지시)
- **에이전트별 번호 분리 폐기**: JOB-1xxx/OpenClaw vs JOB-2xxx/Hermes 방식 거부
- **통합 번호 체계 유지**: `JOB-xxxx` (순차 할당, 에이전트 구분 없음)
- **AGENTS.md 수정**: JOB-2xxx/3xxx 정의 제거

## 교훈
1. 폴더명 특수문자 처리 주의 (콜론, 이모티콘)
2. find + while 읽기 방식이 bash array보다 안전
3. AGENTS.md 정의와 실제 구현 불일치 주기적 검증 필요

## 생성된 파일
- `~/.hermes/scripts/create-job.sh` — v3
- `~/.hermes/scripts/dedup-jobs.sh` — 중복 정리 스크립트
- `~/.hermes/scripts/create-job.sh.bak` — v2 백업
- `~/.openclaw/workspace/skills/agent-workflow-core/scripts/create-job.sh` — v3 동기화
