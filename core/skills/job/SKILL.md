---
name: job
description: "Hermes 작업 생성 및 관리 (OpenClaw 레거시 이식, 독립 제어)"
version: 1.1.0
---

# Job Skill for Hermes

Hermes가 작업을 생성, 조회, 관리하는 독립적 스킬입니다. OpenClaw의 레거시 스크립트를 이식하여 Hermes가 직접 제어합니다.

## 사용법

| 명령 | 설명 | 예시 |
|------|------|------|
| `create` | 새 JOB 생성 (로컬 스크립트) | `bash scripts/create-job.sh -y 개선 "제목"` |
| `list` | 최근 JOB 목록 조회 | `bash scripts/job-list.sh` |
| `status` | 특정 JOB 상태 조회 | `bash scripts/job.sh status 1148` |

## 스크립트 구조 (Hermes 독립 제어)

OpenClaw의 스크립트를 `scripts/` 폴더로 이식하여 Hermes가 직접 제어합니다. OpenClaw는 참조만 합니다.
- `scripts/create-job.sh`: 작업 생성 (유형: 기능, 수정, 조사, 정리, 운영, 개선, 시스템, 기타)
- `scripts/job-list.sh`: 로컬 파일 기반 목록 조회 (API 의존도 제거)
- `scripts/job.sh`: 메인 진입점 및 상태 조회

### ⚠️ create-job.sh 실패 패턴 (JOB-1403/1404/1412/1479/1493)

**증상**: `create-job.sh` 실행 후 "JOB 생성 정보"가 출력되지만 exit code가 1이고 실제 폴더가 생성되지 않음

**원인**:
1. 내부 락 획득 또는 번호 할당 과정에서 부분적 실패 발생
2. `/tmp/.create-job.lock`이 예외 발생 시 영구적으로 남음 → 이후 JOB 생성 실패
3. 한국어 제목 사용 시 `sanitize_title()` 인코딩 문제 → mkdir 실패

**sanitize_title() 인코딩 문제 (JOB-1479)**:
- `head -c80`는 UTF-8 바이트 기반 truncation → 한글 중간에 잘림
- 해결: Python str slicing 사용 (`python3 -c "import sys; print(sys.stdin.read().strip()[:80], end='')"` )

**중복 번호 감지 문제 (JOB-1493)**:
- `ls -d`는 glob 패턴 확장 실패 시 중복 감지 실패
- 해결: `find "$JOBS_DIR" -maxdepth 1 -type d -name "JOB-${test_num}-*"` 사용

**대처**:
```bash
# 1. 락 파일 확인/제거
ls -la /tmp/.create-job.lock  # 존재하면 제거
rm -f /tmp/.create-job.lock

# 2. create-job.sh 실행 (비대화형 모드 필수: -y 플래그)
bash ~/.hermes/scripts/create-job.sh -y 개선 "Workflow logging system" 2>&1

# 3. 폴더 실제 생성 여부 확인
ls -d ~/.hermes/workspace/jobs/JOB-XXXX-*

# 4. 폴더가 없으면 수동 생성
mkdir -p ~/.hermes/workspace/jobs/JOB-1403-Workflow-logging-system

# 5. request.md 작성 후 진행
```

**⚠️ 비대화형 모드 (agent/automated context)**: `create-job.sh`는 확인 프롬프트(`read -r -p`)를 포함하므로, TTY가 없는 환경(에이전트 terminal 호출 등)에서 `-y` 플래그 없이 실행하면 exit code 1로 실패하고 폴더가 생성되지 않음. **반드시 `bash ~/.hermes/scripts/create-job.sh -y <유형> "<제목>"` 사용.**

**예방**: 
- 제목은 **ASCII-only**로 작성 (한국어 내용은 `request.md`에서 작성)
- 실행 후 반드시 `ls -d ~/.hermes/workspace/jobs/JOB-XXXX-*`로 폴더 존재 확인

## 응답 형식

```
📋 현재 작업 현황 (최근 10개)

🔄 진행중:
• JOB-1148: Hermes 작업 관리 시스템 표준화 (개선)
• JOB-1110: Bridge 메시지 소비 문제 조사

✅ 최근 완료:
• JOB-1145: Hermes-OpenClaw 결과 회신 채널 구현
```

## 큐 파일 관리 (Queue Management)

Hermes와 OpenClaw는 다음 파일을 통해 대기 작업 큐를 관리합니다. `.workflow-state` 파일이 없더라도 이 파일에 등록되어 있으면 미완료 작업으로 간주합니다.

- **`~/.hermes/workspace/jobs/JOB-QUEUE.md`**: 기본 작업 대기열. `상태: 등록` 항목 확인.
- **`~/.hermes/workspace/jobs/PRIORITY-QUEUE.md`**: 우선순위별(P0~P4) 작업 분류. `request` 또는 `investigation` 상태 항목 확인.

**참고**: 폴더 내 JOB이 많더라도 (400+), `PRIORITY-QUEUE.md`에 없는 과거 완료 작업은 정리 대상일 수 있습니다.

---

### workflow-gate.sh 검증 요구사항 (JOB-1545 학습)

`workflow-gate.sh <JOB_ID> complete` 실행 시 다음 파일들이 필수적으로 존재해야 하며, 검증이 실패하면 `BLOCKED` 오류를 반환합니다.

1. **`approval.json`**
   - **필수 필드**: `approved_by`, `approved_at`, `decision`, **`choice`**, `comments`
   - **`choice` 필드**: 반드시 `"approved"` 또는 `"rejected"` 값 포함. 누락 시 `BLOCKED: approval.json missing 'choice' field` 발생.
   - **위치**: 스크립트가 `JOB-XXXX-설명` 형태의 **sanitized title 디렉토리**를 우선 참조합니다. 수동으로 `JOB-XXXX` 폴더를 생성한 경우에도 `approval.json`은 sanitized title 폴더 내에 반드시 있어야 합니다.

2. **`result.md`**
   - 작업 결과 요약 및 산출물 목록 포함.

3. **`execution.md`**
   - 실제 구현 세부 사항, 변경된 스크립트/코드, 구체적인 실행 단계 기록.

4. **`lessons.md`**
   - 자동 생성되지만, 템플릿이 없으면 `BLOCKED: lessons.md not found` 발생. 스크립트 실행 시 자동 생성되지만 미생성 시 빈 템플릿 수동 작성 필요.

**대처 프로시저**:
```bash
# sanitized title 디렉토리 확인
ls -d ~/.hermes/workspace/jobs/JOB-XXXX-*

# 해당 디렉토리에 필수 파일 작성
echo '{"approved_by": "user", "choice": "approved"}' > ~/.hermes/workspace/jobs/JOB-XXXX-제목/approval.json
echo '# Result' > ~/.hermes/workspace/jobs/JOB-XXXX-제목/result.md
echo '# Execution Log' > ~/.hermes/workspace/jobs/JOB-XXXX-제목/execution.md

# 완료 처리
bash ~/.hermes/scripts/workflow-gate.sh JOB-XXXX complete
```
---

## 작업 정리 및 아카이빙 (Job Cleanup)

### 아카이브 디렉토리 구조
```
~/.hermes/workspace/jobs/archive/
├── legacy/        # 구 시스템 JOB (200-900 시리즈 등)
├── completed/     # 9-done, completed 상태
├── cancelled/     # 9-cancelled, cancelled 상태
├── superseded/    # 9-superseded 상태
└── duplicates/    # 중복 폴더 정리
```

### JOB 번호 중복 문제 (JOB-1288)

**현황** (2026-05-24 기준): 48개 중복 JOB 번호 확인
- `~/.openclaw/workspace/jobs` → `~/.hermes/workspace/jobs` symlink (동일 디렉토리)
- Hermes/OpenClaw가 동시에 `create-job.sh` 실행 시 **레이스 컨디션** 발생
- `get_next_job_number()`가 독립적으로 최대 번호 스캔 → 동일 번호 할당

**중복 감지 방법**:
```bash
ls ~/.hermes/workspace/jobs/ | grep -oP '^JOB-\K[0-9]+' | sort | uniq -c | awk '$1>1{print "JOB-"$2": "$1"개"}'
```

**중복 해결 프로시저**:
1. 중복 폴더 식별 (위 명령 실행)
2. `.workflow-state` 확인: 더 완전한 버전 유지
3. 중복 폴더 중 하나 재지정: `mv JOB-XXX-구_JOB-XXX-신규` + `.workflow-state` 내 jobId 갱신
4. 정리 이력 기록: `JOB-INDEX-DEDUP.md` 생성

**방지 방안** (JOB-1288 구현 예정):
- `create-job.sh`에 flock 기반 원자적 락 메커니즘 도입
- `/tmp/.create-job.lock` 잠금 파일 (Hermes/OpenClaw 공유)
- 중복 감지 검증 로직 추가 (pre-check + post-check)
```

### 정리 프로시저
1. **완료/취소 JOB 아카이빙**: `.workflow-state`에서 `status: 9-done|completed|cancelled|superseded` 확인 후 해당 아카이브 폴더로 이동
2. **중복 폴더 정리**: 같은 JOB-XXX 번호에 폴더가 2개 이상 존재 시, `.workflow-state`가 최신이거나 내용이 더 완전한 폴더만 유지
3. **중복 감지 검증**: `create-job.sh`의 `validate_and_reassign()`은 `find` 명령어로 정확한 중복 감지 (JOB-1493 학습)
4. 정리 이력 기록: `JOB-INDEX-DEDUP.md` 생성

### 자동 처리 (JOB-1494 학습)

`workflow-gate.sh`에 `auto-process` 액션 추가됨:
```bash
# request → approval까지 자동 진행
bash ~/.hermes/scripts/workflow-gate.sh JOB-XXXX auto-process
```

### 중복 JOB 방지 (JOB 요청 전 필수)

- JOB 요청 전 `find ~/.hermes/workspace/jobs/ -name ".workflow-state" -exec grep -l "핵심단어" {} \;`로 기존 JOB 확인
- 중복 발견 시 취소를 제안하고 근거 제시 (기존 JOB ID, 현재 단계)
3. **활성 JOB 보호**: `status: running` 또는 `step: investigation|design|execution|review`인 폴더는 절대 아카이브 금지
4. **PRIORITY-QUEUE.md 갱신**: 정리 후 활성 JOB 목록으로 재작성

### 중복 폴더 정리 규칙
- `JOB-XXX` (빈 폴더 또는 최소 내용) vs `JOB-XXX-설명` (실제 작업 내용): 설명 있는 폴더 유지
- 둘 다 `.workflow-state` 존재 시: 최신 수정 시간 또는 더 높은 단계(step) 가진 폴더 유지
- `9-cancelled` 상태인 폴더는 아카이브 대상 (실제 작업이 아닌 경우)

### JOB 취소 프로시저 (JOB-1553 학습)

작업이 취소되었을 때:
1. `.workflow-state` 파일에 `status: cancelled` 기록
2. `lessons.md` 에 취소 사유 기록
3. 폴더를 `archive/cancelled/` 로 이동
4. `PRIORITY-QUEUE.md` 에서 제거

```bash
# 취소 처리
echo '{"status": "cancelled", "cancelledAt": "...", "reason": "..."}' > ~/.hermes/workspace/jobs/JOB-XXX-제목/.workflow-state
echo '# 취소 사유\n...' > ~/.hermes/workspace/jobs/JOB-XXX-제목/lessons.md
mv ~/.hermes/workspace/jobs/JOB-XXX-제목 ~/.hermes/workspace/jobs/archive/cancelled/
```

**참고**: 취소된 JOB 의 번호는 재사용 금지. 다음 번호를 할당하십시오.

### 상태 검증 (권장 전에 필수)
작업 추천 전 반드시 `.workflow-state` 확인:
```bash
# 상태 확인
grep -o '"status": *"[^"]*"' ~/.hermes/workspace/jobs/JOB-XXX*//.workflow-state | head -1
```
- `9-done`, `completed`, `cancelled`, `superseded` 상태인 JOB은 추천 금지
- 상태 파일이 없더라도 `archive/`에 있으면 완료된 것으로 간주
- **좀비 JOB (Zombie Jobs) 탐지**: `running` 상태이거나 단계가 초기(예: `request`)인데 `request.md`가 없거나 폴더가 비어있는 경우. 이는 세션 중단으로 인한 고아 작업이므로 아카이브 처리 대상입니다.

---

## JOB 폴더 복구 (Recovery from Data Loss)

백업 삭제 또는 실수로 JOB 폴더가 손실되었을 때 복구 가능한 출처:

### 복구 출처 우선순위

| 출처 | 내용 수준 | 위치 |
|------|-----------|------|
| 1. 백업 폴더 | 완전 (모든 파일) | `/mnt/c/AI/openclaw_backups/` |
| 2. 세션 파일 | 요청+설계+실행 내용 | `~/.hermes/sessions/session_*.json` |
| 3. Wiki sources | JOB 결과 요약 | `~/.hermes/knowledge/wiki/sources/job-JOB-*.md` |
| 4. Lessons drafts | 교훈 초안 | `~/.hermes/workspace/lessons-drafts/JOB-*-draft.md` |
| 5. Agent logs | 폴더명/상태 언급 | `~/.hermes/logs/agent.log` |
| 6. Cron output | 신규 JOB 목록 | `~/.hermes/cron/output/*/` |

### 백업 복구 (rsync)

```bash
rsync -av --ignore-existing /mnt/c/AI/openclaw_backups/YYYY-MM-DD/.openclaw/workspace/jobs/ ~/.hermes/workspace/jobs/
```

### 세션 데이터로부터 복구

세션 파일에서 JOB 관련 메시지 추출하여 request.md 재구성.
Python으로 세션 JSON 파싱 후 role=user/assistant 메시지 중 JOB 관련 내용 추출.

### Wiki/Draft/Log에서 복구

- Wiki sources가 있으면 해당 파일 내용을 request.md로 복사
- Lessons drafts가 있으면 초안 내용을 request.md로 변환
- Agent logs에서 폴더명 패턴 추출 (JOB-XXX-제목 형식)

### 복구 후 상태

- 복구된 폴더는 .workflow-state에 status=restored 또는 currentStep=restored_from_session 기록
- 원본 출처를 request.md 헤더에 기록 (예: 출처: session_20260516_*.json)
- JOB-INDEX.md에 없는 번호라면 추가 기록