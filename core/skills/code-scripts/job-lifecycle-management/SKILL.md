---
name: job-lifecycle-management
description: JOB 생성, 번호 할당, 중복 관리 및 정리. create-job.sh v3 (flock 기반 원자적 락), 중복 감지/재할당, dedup 프로토콜. JOB 번호 체계는 통합 관리(Hermes/OpenClaw 공유).
triggers:
  - JOB 생성
  - create-job
  - 번호 중복
  - 중복 정리
  - create-job.sh 개선
  - flock
  - 원자적 락
  - JOB 번호 체계
  - 중복 방지
  - workflow-gate
  - JOB 상태 전이
---

# JOB Lifecycle Management

JOB 생성부터 중복 관리까지의 완전한 라이프사이클 관리.

## create-job.sh v3 (현재 버전)

### 핵심 개선 사항

1. **flock 기반 원자적 락 메커니즘**
   - `/tmp/.create-job.lock` 공유 잠금 파일
   - 30초 타임아웃 후 실패
   - Hermes/OpenClaw 양쪽에서 동일한 락 파일 사용

2. **중복 감지 + 자동 재할당**
   - `validate_and_reassign()` 함수: 번호 할당 전 중복 확인
   - mkdir 실패 시 자동 재할당 (최대 10회 시도)
   - 폴더 존재 시 최종 검증

3. **sanitize_title 일관성**
   - 슬래시, 콜론, 공백, 탭, 줄바꿈 → 하이픈
   - 선행/후행 하이픈 제거, 연속 하이픈 단일화
   - 80자 제한

4. **workflow-state JSON 통일**
   - Hermes/OpenClaw 모두 JSON 양식 사용
   - 9단계 상태 머신 표준화

### 사용법

```bash
# 기본 사용
bash ~/.hermes/scripts/create-job.sh -y 기능 "작업 제목"

# 부모 JOB 연계
bash ~/.hermes/scripts/create-job.sh --parent JOB-1007 -y 정리 "파생 작업"

# dry-run
bash ~/.hermes/scripts/create-job.sh --dry-run 조사 "AI 트렌드 조사"
```

### 버전 위치

| 에이전트 | 경로 |
|----------|------|
| Hermes | `~/.hermes/scripts/create-job.sh` |
| OpenClaw | `~/.openclaw/workspace/skills/agent-workflow-core/scripts/create-job.sh` |

**양쪽 동기화 필수**: 한쪽 수정 시 다른 쪽에도 적용.

## 중복 발생 원인

### 근본 원인: 레이스 컨디션
- Hermes와 OpenClaw가 동시에 `get_next_job_number()` 실행
- 동일 디렉토리 스캔 → 동일 번호 할당
- v2 이전: 락 메커니즘 부재 → 중복 불가피

### 해결: v3 도입
- flock 기반 원자적 락으로 동시 생성 방지
- validate_and_reassign()로 중복 자동 회피

## 기존 중복 정리 (dedup)

### 문제 발생 시 증상
- 같은 JOB-번호로 여러 폴더 존재
- workflow-state jobId 불일치
- request.md 번호 불일치

### 정리 프로토콜

```bash
# 1. 중복 스캔
find ~/.hermes/workspace/jobs/ -maxdepth 1 -type d -name "JOB-*" -printf '%f\n' | \
  sed 's/JOB-\([0-9]*\).*/JOB-\1/' | sort | uniq -c | awk '$1>1'

# 2. 수동 정리 (스크립트 버그 시)
# next_global 카운터 사용, 각 중복에서 개별 증가
# 폴더명 특수문자 주의: find + while 읽기 권장

# 3. 검증
find ~/.hermes/workspace/jobs/ -maxdepth 1 -type d -name "JOB-*" -printf '%f\n' | \
  sed 's/JOB-\([0-9]*\).*/JOB-\1/' | sort | uniq -c | awk '$1>1' | wc -l
# 0이 아니면 정리 미완료
```

### 주의사항

1. **폴더명 특수문자**: 콜론, 이모티콘, 인코딩된 문자 포함 시 bash array 처리 실패 가능
2. **중복 폴더 유지 기준**: 첫 번째 폴더 유지, 나머지는 새 번호 재할당
3. **파일 갱신 필수**: `.workflow-state`, `request.md`, `architecture.md`, `execution-result.md` 모두 번호 갱신
4. **symlink 확인**: `~/.openclaw/workspace/jobs` → `~/.hermes/workspace/jobs` symlink이므로 한쪽만 작업

## JOB 번호 체계

- **통합 관리**: `JOB-xxxx` (순차 할당, 에이전트 구분 없음)
- **번호 산정**: 디렉토리 스캔 → 최대 번호 + 1
- **중복 방지**: v3 flock + validate_and_reassign()
- **symlink**: `~/.openclaw/workspace/jobs` → `~/.hermes/workspace/jobs`

### ⛔ 에이전트별 번호 분리 금지

**사용자 명시적 지시**: 에이전트별 번호 대역 분리 (JOB-1xxx/OpenClaw, JOB-2xxx/Hermes) 방식은 **폐기**. 통합 번호 체계만 사용.

### OpenClaw JOB 생성 권한 (적절함)

OpenClaw는 다음 경우에 JOB 생성:
- 시스템 복구 작업 (메모리, 워크플로우 인프라)
- 인프라 점검 (style-dna, validate 스크립트)
- 자율적 개선 제안 (버그 발견, 최적화 필요)

이는 OpenClaw의 "시스템 관리" 역할과 일치하며, `create-job.sh` v3의 flock 메커니즘으로 중복 방지됨.

## ⛔ 작업 프로세스 강제 준수

AGENTS.md 포함 **모든 파일 수정**은 반드시 JOB 등록 후 workflow 경유:

1. `create-job.sh`로 JOB 등록
2. 조사 → 설계 → 리뷰 → 승인 → 실행 순서 준수
3. **직접 patch 금지** — 사용자의 명시적 "진행해" 승인 후 실행 단계에서만 파일 변경

**위반 사례 (JOB-1327)**: AGENTS.md 수정 시 workflow 건너뛰고 직접 patch 적용 → 사용자 지적 수신. 이후 동일 실수 금지.

## JOB 생성 → 상태 전이 호출 순서 (필수)

```
1. create-job.sh -y <유형> "<제목>"  → JOB 생성 + .workflow-state 초기화 (request 단계)
2. workflow-gate.sh <JOB_ID> start   → request 완료, investigation 단계 진입
3. 작업 수행 ...
4. workflow-gate.sh <JOB_ID> transition <단계>  → 단계 전이
5. workflow-gate.sh <JOB_ID> complete  → 최종 완료
```

**⛔ 절대 workflow-gate.sh를 create-job.sh 전에 호출하지 마세요.**
- workflow-gate.sh는 기존 JOB 디렉토리가 존재해야 동작 (JOB 폴더 검색 후 실행)
- create-job.sh 없이 호출 시 `ERROR: JOB directory not found` → exit 1

## 성능 특성 (JOB-1355实测)

### 병목 지점

| 함수 | 호출 수 | 시간 | 원인 |
|------|---------|------|------|
| get_next_job_number() | 325×3=subprocess | ~3초 | 각 JOB 디렉토리당 basename+sed+grep 호출 |
| validate_and_reassign() | 최대 10회 glob | ~0.3초 | 반복 디렉토리 스캔 |
| sanitize_title() | 6개 파이프라인 | ~0.08초 | echo\|tr/sed 각기 별도 subprocess |
| **총계 (325개 JOB 기준)** | **~975个子process** | **9.3초** | |

### 개선 패턴

**get_next_job_number() 최적화** (3초 → 0.1초):
```bash
# ❌ 현재: glob + 각 DIR당 3个子process
for d in "$JOBS_DIR"/JOB-*/; do
    num=$(basename "$d" | sed ... | grep ...)  # 3个子process/DIR
done

# ✅ 개선: find + sort 단일 파이프라인
find "$JOBS_DIR" -maxdepth 1 -type d -name 'JOB-*' \
    | sed 's/.*JOB-//' | grep -oP '^\d+' | sort -n | tail -1
```

**sanitize_title() 통합** (0.08초 → 0.02초):
```bash
# ❌ 현재: echo + tr/sed/cut 7회 호출
# ✅ 개선: sed -e 5개 + cut (delimiter 충돌 주의: / → |)
echo "$1" | sed -e "s|/|-|g" -e "s|:|-|g" -e "s/[[:space:]]\+/-/g" ... | cut -c1-80
```

**표**: JOB 수에 선형 비례 → 325개=9.3초, 100개=~3초, 500개=~14초 예상

## Workflow Phase-Based File Mutation Guard (absorbed from workflow-mutation-guard)

Prevents the agent from skipping design and editing code prematurely by enforcing phase-based file manipulation permissions.

### Permission Matrix

| Phase | Docs/Meta (`.md`, `.json`, `.state`) | Source/Config (`.py`, `.yaml`, `.sh`) | Dangerous (`rm`, `rmdir`) |
|-------|:-:|:-:|:-:|
| **Investigation** | ✅ | ❌ | ❌ |
| **Design** | ✅ | ❌ | ❌ |
| **Review** | ✅ | ❌ | ❌ |
| **Approval** | ✅ | ❌ | ❌ |
| **Execution** | ✅ | ✅ | ✅ |
| **Test** | ✅ | ✅ | ⚠️ (limited) |
| **Review/Done** | ✅ | ❌ | ❌ |

### Guard Logic (`model_tools.py`)

1. **Active state detection**: Find the most recently modified `.workflow-state` in `~/.hermes/workspace/jobs/`
2. **Classification check**: `classify-result.json` = `simple-task` → block all file modifications
3. **Phase verification**: On `write_file`, `patch`, `terminal` calls, verify `currentStep` is `execution`
4. **Whitelist**: Paths under `~/.hermes/workspace/jobs/` with `.md` extension are allowed regardless of phase

### Pitfalls

- **State inconsistency**: Multiple parallel JOBs → "most recently modified" heuristic may pick the wrong state file. Explicitly update `.workflow-state` to sync.
- **Guard bypass**: `EMERGENCY_DISABLE_GUARD` flag disables all guards. Must be removed in production.
- **Blocked message**: Current phase is not `execution`. Complete `design` → `review` → `approval` transitions first.

## JOB 완료 시 필수 파일 (workflow-gate.sh complete 검증)

`workflow-gate.sh <JOB_ID> complete`은 다음 파일을 검증합니다. 누락 시 BLOCKED:

| 파일 | 필수 | 요구사항 |
|------|------|----------|
| `approval.json` | ✅ | `choice` 필드 필수 ("proceed"/"simplified") |
| `architecture.md` | ✅ | 설계 단계 산출물 |
| `review-result-*.md` | ✅ | `[STATUS: PASS/REV/FAIL]` 태그 포함 (frontmatter) |
| `result.md` | ✅ | 작업 결과 요약 |
| `execution.md` | ✅ | 구현 세부 사항 |
| `lessons.md` | ⚠️ | 자동으로 템플릿 생성됨 |

### approval.json 스키마

```json
{
  "jobId": "JOB-XXXX",
  "approved_by": "사용자명",
  "approved_at": "ISO8601",
  "choice": "proceed",
  "notes": "승인 메모",
  "simplified": false
}
```

**choice 필드 없이 생성 시**: `⛔ BLOCKED: approval.json missing 'choice' field`

### review-result-*.md 포맷

```markdown
---
[STATUS: PASS]
---

# 리뷰 보고서
...
```

**STATUS 태그 없이 생성 시**: `⛔ BLOCKED: review-result-*.md missing [STATUS: PASS/REV/FAIL] tag`

### Pitfalls (완료 시)

1. **approval.json choice 필드 누락**: 가장 흔한 오류. `choice: "proceed"` 포함 필수
2. **STATUS 태그 위치**: frontmatter (`---` 사이)에 `[STATUS: PASS/REV/FAIL]` 포함
3. **review-result 파일명**: `review-result-*.md` 패턴 (wildcard) — `review-result-grill.md`, `review-result-tech.md` 등
4. **architecture.md 누락**: design 단계 산출물이 없으면 complete 불가. `design-detailed.md` → `architecture.md`로 복사 가능
5. **Grill 리뷰 결과 즉시 파일 저장 **(JOB-1621 교훈) Grill 리뷰 완료 후 **즉시** `review-result-*.md`에 저장 필수. 세션 컴팩션 (context overflow)으로 리뷰 상세 내용이 세션 이력에서 사라질 수 있음. 누락 시 후기 복구 어려움.

## Pitfalls

1. **create-job.sh v2 사용 금지**: 레이스 컨디션 발생
2. **중단 시 수동 검증**: 스크립트 실행 후 중복 수 확인 필수
3. **폴더명 길이 제한**: 80자 초과 시 truncation 발생 (sanitize_title)
4. **부모 JOB 검증**: `--parent` 옵션 사용 시 부모 디렉토리 존재 필수
5. **AGENTS.md 직접 수정 금지**: JOB 등록 → workflow 준수 필수
6. **에러 시 같은 명령 반복 금지**: create-job.sh 실패 시 2회 이상 동일 명령 재실행 금지 → 출력 확인 + 원인 분석 후 접근
7. **workflow-gate.sh 인수 누락 시**: 새 JOB 생성은 `create-job.sh` 사용 (workflow-gate.sh는 상태 관리 전용)
8. **성능 저하 시**: JOB 수가 200+이면 create-job.sh가 5초+ 소요 가능 → `--dry-run`으로 우선 테스트
9. **sanitize_title UTF-8 처리 **(JOB-1476) sanitize_title()에 `LC_ALL=C.UTF-8` 명시 + `cut -c1-80` → `head -c80` 변경. **원인**: 로케일 미설정 시 한글 인코딩 오류, cut이 바이트 단위로 자름. **해결**: `LC_ALL=C.UTF-8 sed ... | head -c80` 패턴 사용. 실행 후 `ls -d ~/.hermes/workspace/jobs/JOB-XXXX-*`로 폴더 존재 확인.
10. **create-job.sh 실패 시 수동 생성**: 폴더가 생성되지 않으면 `mkdir -p`로 수동 생성 후 `.workflow-state` JSON 직접 작성. `workflow-gate.sh start`로 상태 초기화.
11. **validate_and_reassign 중복 감지不准 **(JOB-1493 학습) `ls -d "$JOBS_DIR"/JOB-${test_num}-*`가 부정확. **해결**: `find "$JOBS_DIR" -maxdepth 1 -type d -name "JOB-${test_num}-*" 2>/dev/null | grep -q .` 사용.
12. **한글 폴더명 호환성 문제 (JOB-1540 학습)**: `create-job.sh`가 생성하는 `JOB-번호-제목` 형태의 폴더명에 한글이 포함될 경우, `workflow-gate.sh` 등 경로를 직접 다루는 스크립트에서 `No such file or directory` 에러가 발생할 수 있음. 
    - **해결**: 폴더명은 `JOB-XXXX` 형태의 짧은 ID로 유지하거나 영어 Slug를 사용하고, 상세 제목은 내부 `request.md`에서 관리할 것. 폴더 생성 실패 시 `mkdir -p` 후 `.workflow-state`를 수동 생성하여 복구.
13. **비인터랙티브 환경에서 read -p 조기 종료 (JOB-1561 학습)**: 에이전트가 terminal()로 `create-job.sh` 호출 시 TTY가 할당되지 않아 `read -p`가 빈 값을 반환함. **해결**: `-y` 플래그 필수 사용 또는 `[[ -t 0 ]]`로 TTY 확인 후 조건부 실행.
14. **괄호 포함 제목 중복 폴더 생성 버그 **(JOB-1625) `write_file` 도구가 경로 인코딩 처리 시 괄호 `()`를 `\\(\\)`로 이스케이프하여 별도의 중복 폴더를 생성할 수 있음.
    - **증상**: `JOB-1625-제목(structs-image-gen-)-추가` + `JOB-1625-제목\(...\)-추가` 두 폴더 동시 존재
    - **해결**: `python3 -c "import os; print([f for f in os.listdir(jobs_dir) if f.startswith('JOB-XXXX')])"`로 실제 폴더명 확인 후 중복 폴더 제거
    - **예방**: `write_file`로 JOB 폴더 파일 작성 후 `ls -d ~/.hermes/workspace/jobs/JOB-XXXX*`로 폴더 존재 검증 필수

## JOB bulk 정리 패턴 (JOB-1433)

**상황**: 90+개 레거시 JOB이 중단된 상태로 방치

**절차**:
1. `exclude` 리스트 작성 (진행 필요성 있는 JOB)
2. `.workflow-state`를 `9-cancelled`로 일괄 업데이트
3. `request.md`에 취소 사유 기록
4. 이미 완료된 JOB(`9-done`)은 skip

**주의**:
- exclude 리스트 검증 필수 — 실수로 중요한 JOB 취소 방지
- 취소 후 복원 가능: `.workflow-state`의 `currentStep` 원복 + `cancelledAt/cancelledReason` 필드 제거
- 이력 보존: 파일은 유지, 상태만 `9-cancelled`로 변경

**참조**: `periodic-task-system` 스킬 § JOB bulk 정리 패턴

## Related

- `workflow`: 9단계 파이프라인
- `agent-workflow-core`: 에이전트 워크플로우 코어
- `project-management`: 프로젝트 메타데이터 관리
- `references/dedup-session-2026-05-24.md`: 중복 정리 세션 기록
