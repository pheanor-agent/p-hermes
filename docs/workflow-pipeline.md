# 9-Step Workflow Pipeline

Hermes Agent의 작업 파이프라인은 9단계 상태 머신을 기반으로 모든 작업을 관리합니다.

---

## Overview

```
request → investigation → design → review → approval → execution → test → execution_review → done
  [0]        [1]              [2]      [3]       [4]         [5]         [6]      [7]             [8]
```

---

## 각 단계 상세

### Step 0: Request (요청)

**역할**: 작업 요청 수신 및 초기화

| 항목 | 내용 |
|------|------|
| 입력 | 사용자 요청 메시지 |
| 출력 | JOB 디렉토리 생성, 초기 `.workflow-state` |
| 모델 | Qwen3.6 (기본) |
| 검증 | 작업 정의 존재 (I1) |

**`.workflow-state` 초기 상태:**
```json
{
  "job_id": "JOB-XXXX",
  "step": 0,
  "step_name": "request",
  "status": "active",
  "created_at": "2026-06-13T00:00:00Z",
  "model": "Qwen3.6"
}
```

---

### Step 1: Investigation (조사)

**역할**: 배경 조사 및 기존 지식 수집

| 항목 | 내용 |
|------|------|
| 입력 | 작업 요청 내용 |
| 출력 | 조사 결과, 참조 자료 |
| 모델 | Qwen3.6 |
| 지식 읽기 | Wiki domain 기반 관련 항목 |

**조사와정:**
- 기존 Wiki domain 기반 지식 스캔
- References 검색
- 관련 JOB 이력 확인
- 외부 자료 수집

---

### Step 2: Design (설계)

**역할**: 솔루션 설계 및 아키텍처 정의

| 항목 | 내용 |
|------|------|
| 입력 | 조사 결과 |
| 출력 | 설계서, 아키텍처 다이어그램 |
| 모델 | **Gemma-4** (설계 특화) |
| 검증 | 산출물 명확성 (I2) |

**모델 전환**: `workflow-gate.sh`가 이 단계에서 Gemma-4로 모델을 전환합니다.

---

### Step 3: Review (검토)

**역할**: 설계서 검토 및 개선

| 항목 | 내용 |
|------|------|
| 입력 | 설계서 |
| 출력 | 검토 의견, 개선안 |
| 모델 | **Claude-Sonnet-4-5** (검토 특화) |
| 검증 | 의존성 체크 (I3) |

---

### Step 4: Approval (승인)

**역할**: 최종 승인 결정

| 항목 | 내용 |
|------|------|
| 입력 | 검토된 설계서 |
| 출력 | 승인/반려 결정 |
| 모델 | Qwen3.6 |

---

### Step 5: Execution (실행)

**역할**: 실제 작업 수행

| 항목 | 내용 |
|------|------|
| 입력 | 승인된 설계서 |
| 출력 | 작업 산출물 |
| 모델 | Qwen3.6 (고성능) |
| 검증 | 체크포인트 I4~I12 |

**실행 중 활동:**
- 코드 작성 / 문서 생성
- 스킬 자동 로딩 (트리거 기반)
- 중간 산출물 저장
- 모델 라우팅 (작업 유형에 따라)

---

### Step 6: Test (검증)

**역할**: 작업 결과 검증

| 항목 | 내용 |
|------|------|
| 입력 | 실행 산출물 |
| 출력 | 검증 결과, 버그 리포트 |
| 모델 | Qwen3.6 |
| 검증 | 품질 체크 (I13~I15) |

---

### Step 7: Execution Review (실행 검토)

**역할**: 최종 실행 검토

| 항목 | 내용 |
|------|------|
| 입력 | 검증된 산출물 |
| 출력 | 최종 검토 의견 |
| 모델 | Qwen3.6 |

---

### Step 8: Done (완료)

**역할**: 작업 완료 처리

| 항목 | 내용 |
|------|------|
| 입력 | 검토된 산출물 |
| 출력 | 완료 리포트 |
| 모델 | — |
| 후처리 | `on-job-complete.sh` 실행 |

**완료 후 자동 처리:**
1. `.workflow-state` → `status: "done"`
2. `on-job-complete.sh` 실행:
   - Lessons 자동 생성 → `knowledge/lessons/`
   - Wiki index 업데이트
   - 이벤트 버스 발행: `wf.completed`
3. JOB 리포트 생성

---

## 체크포인트 검증 (I1~I16)

모든 단계 전환 시 `workflow-gate.sh`가 검증 규칙을 적용합니다.

| 규칙 | 단계 | 설명 |
|------|------|------|
| I1 | 0→1 | 작업 정의 존재 |
| I2 | 2→3 | 산출물 명확성 |
| I3 | 3→4 | 의존성 체크 |
| I4 | 5→6 | 실행 산출물 존재 |
| I5 | 5→6 | 코드 품질 기준 |
| I6 | 5→6 | 문서화 완료 |
| I7 | 6→7 | 테스트 커버리지 |
| I8 | 6→7 | 오류 없는 검증 |
| I9 | 7→8 | 최종 검토 통과 |
| I10 | 전체 | 민감 정보 없음 |
| I11 | 전체 | SSOT 일관성 |
| I12 | 전체 | 상태 파일 유효성 |
| I13 | 6→7 | 기능 검증 완료 |
| I14 | 7→8 | 성능 기준 충족 |
| I15 | 7→8 | 보안 검증 |
| I16 | 7→8 | 최종 완성도 |

---

## 상태 전이

### 자동 전이

단계 완료 시 즉시 다음 단계로 전이됩니다. `workflow-gate.sh`가 이를 처리합니다:

```
workflow-gate.sh <JOB-XXXX>
  → .workflow-state 읽기
  → 현재 단계 확인
  → 체크포인트 검증 (I 규칙)
  → 통과 시: 다음 단계로 state 변경
  → 실패 시: 에러 리포트 + 현재 단계 유지
```

### 모델 전환 타이밍

| 단계 | 모델 |
|------|------|
| request → investigation | Qwen3.6 |
| investigation → design | **Gemma-4** |
| design → review | **Claude-Sonnet-4-5** |
| review → approval | Qwen3.6 |
| approval → execution | Qwen3.6 |
| execution → test | Qwen3.6 |
| test → execution_review | Qwen3.6 |
| execution_review → done | — |

---

## 핵심 스크립트

### `create-job.sh`

새 JOB 생성:

```bash
#!/bin/bash
# 새 JOB 생성
# 사용법: create-job.sh "<작업 설명>"

DESC="${1:?작업 설명 필수}"
JOB_NUM=$(($(ls ~/.hermes/workspace/jobs/ | grep -cE '^JOB-' || echo 0) + 1))
JOB_DIR="$HOME/.hermes/workspace/jobs/JOB-$(printf '%04d' $JOB_NUM)"

mkdir -p "$JOB_DIR"
cat > "$JOB_DIR/.workflow-state" << EOF
{
  "job_id": "JOB-$(printf '%04d' $JOB_NUM)",
  "description": "$DESC",
  "step": 0,
  "step_name": "request",
  "status": "active",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
echo "✅ JOB 생성: $JOB_DIR"
```

### `workflow-gate.sh`

단계 검증 + 전이:

```bash
#!/bin/bash
# 워크플로우 게이트
# 사용법: workflow-gate.sh <JOB-XXXX>

JOB_DIR="$HOME/.hermes/workspace/jobs/$1"
STATE_FILE="$JOB_DIR/.workflow-state"

# 상태 파일 읽기
current_step=$(jq -r '.step' "$STATE_FILE")
next_step=$((current_step + 1))

# 체크포인트 검증
run_checkpoints "$current_step" "$next_step"

# 검증 통과 시 전이
if [ $? -eq 0 ]; then
    jq --argjson step "$next_step" '.step = $step' "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"
    echo "✅ 단계 전이: $current_step → $next_step"
else
    echo "❌ 체크포인트 실패: 단계 유지"
    exit 1
fi
```

### `on-job-complete.sh`

JOB 완료 후 처리:

```bash
#!/bin/bash
# JOB 완료 후 자동 처리
# 1. Lessons 생성
# 2. Wiki index 업데이트
# 3. 이벤트 버스 발행

JOB_DIR="$HOME/.hermes/workspace/jobs/$1"

# Lessons 생성
extract_lessons "$JOB_DIR"

# Wiki 업데이트
update_wiki_index

# 이벤트 발행
emit_event "wf.completed" "$JOB_DIR"
```

---

## 참조

- [시스템 종합](systems/overview.md) — 전체 시스템 현황
- [스킬 시스템](skill-system.md) — 146개 스킬
- [인덱스](index.md) — 문서 탐색
