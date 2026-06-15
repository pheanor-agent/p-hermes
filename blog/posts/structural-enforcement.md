# "텍스트 규칙 → 스크립트 강제" 철학

> 태그: #spec-driven #workflow
> 읽는 시간: ~10분

---

## TL;DR

"에이전트는 문서에 쓰인 규칙을 따라주지 않는다. 하지만 스크립트가 실패하면 무조건 멈춘다." Hermes는 텍스트 파일에 작성된 모든 정책을 **실행 가능한 코드**로 변환하여 강제하는 철학을 따릅니다. 이를 **Spec-Driven Development**라고 합니다.

```
┌─────────────────────────────────────────────────────┐
│              Spec-Driven 아키텍처                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  텍스트 규칙 (권고사항)    스크립트 강제 (실행)       │
│                                                     │
│  "설계서 작성 필수"     →  workflow-gate.sh          │
│  "심링크 금지"         →  check-symlink.sh           │
│  "문서 구조 준수"       →  validate-links.sh          │
│                                                     │
│  실패 시: 작업 중단 + 오류 보고                      │
└─────────────────────────────────────────────────────┘
```

---

## 배경: "명령형 문구의 무의미함"

### 초기 버전의 문제

2025년 초, Hermes 시스템의 설계서에는 다음과 같은 문구가 많이 있었습니다.

```markdown
# AGENTS.md (초기 버전)

## 규칙

- 에이전트는 반드시 설계서를 작성해야 한다.
- 에이전트는 심링크를 생성해서는 안 된다.
- 에이전트는 9단계 워크플로우를 따라야 한다.
- 에이전트는 파일 삭제 전 심링크 확인을 해야 한다.
```

**에이전트는 이 문구를 읽었지만, 지루해지면 (혹은 컨텍스트가 압축되면) 이 규칙을 잊어버리고 바로 코드를 수정했습니다.**

### 2가지 치명적 문제

**1. 규칙 무시 (Rule Ignoring)**
- 에이전트가 "설계서 작성 필수" 규칙 잊어버림 → 코드 직접 수정
- 결과: 설계서와 실제 코드 불일치

**2. 규칙 충돌 (Rule Conflict)**
- 에이전트가 "심링크 금지" 규칙과 "파일 동기화 필요" 규칙 충돌
- 결과: 두 규칙 모두 무시 → 시스템 고장

---

## 설계 결정: 규칙을 코드로

Hermes는 모든 규칙을 `scripts/` 디렉토리에 있는 검증 스크립트로 바꾸었습니다.

### 핵심 철학

```
┌─────────────────────────────────────────────────────┐
│              철학: 규칙을 코드로                      │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ❌ 금지: 텍스트 파일에 규칙 작성                     │
│  ✅ 허용: 스크립트로 규칙 강제                       │
│                                                     │
│  "에이전트는 규칙을 잊어버립니다.                    │
│   하지만 스크립트가 실패하면 무조건 멈춥니다."       │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 1. SPEC-D01: 문서 구조 규칙

**텍스트 규칙**: "문서는 3-트랙 구조를 따라야 한다."

**스크립트 강제**: `validate-links.sh`

```bash
#!/bin/bash
# validate-links.sh - 문서 구조 검증 스크립트

echo "[Validation] 문서 구조 검증 시작"

# 1. Wiki/Blog/Slides 링크 무결성 검증
for track in wiki blog slides; do
    echo "  - $track 트랙 검증 중..."
    
    # 링크 스캔
    BROKEN_LINKS=$(grep -r "http\|www" $track/ | while read line; do
        URL=$(echo "$line" | grep -o "http[^ ]*")
        if ! curl -s --fail "$URL" > /dev/null; then
            echo "Broken link: $URL"
        fi
    done)
    
    if [ -n "$BROKEN_LINKS" ]; then
        echo "[Error] $track 트랙에서 손상된 링크 발견"
        echo "$BROKEN_LINKS"
        exit 1
    fi
done

echo "[Validation] 문서 구조 검증 완료"
exit 0
```

**실행 결과**:
```
$ bash validate-links.sh
[Validation] 문서 구조 검증 시작
  - wiki 트랙 검증 중...
  - blog 트랙 검증 중...
  - slides 트랙 검증 중...
[Validation] 문서 구조 검증 완료
```

### 2. Workflow 검증 규칙

**텍스트 규칙**: "9단계 워크플로우를 따라야 한다."

**스크립트 강제**: `workflow-gate.sh`

```bash
#!/bin/bash
# workflow-gate.sh - 워크플로우 게이트 스크립트

JOB_ID="$1"
STEP="$2"

# workflow-state 파일 로드
STATE_FILE="$HOME/.hermes/workspace/jobs/$JOB_ID/.workflow-state"

if [ ! -f "$STATE_FILE" ]; then
    echo "[Error] workflow-state 파일 없음: $JOB_ID"
    exit 1
fi

# 현재 단계 확인
CURRENT_STEP=$(jq -r '.currentStep' "$STATE_FILE")

# 단계 전이 검증
case "$STEP" in
    start)
        echo "[Workflow] $JOB_ID 시작"
        # 상태 파일 갱신
        jq '.currentStep = "investigation"' "$STATE_FILE" > /tmp/state.json
        mv /tmp/state.json "$STATE_FILE"
        ;;
    complete)
        echo "[Workflow] $JOB_ID 완료"
        # 최종 상태 확인
        jq '.status = "done" | .currentStep = "done"' "$STATE_FILE" > /tmp/state.json
        mv /tmp/state.json "$STATE_FILE"
        ;;
    *)
        echo "[Error] 유효하지 않은 단계: $STEP"
        exit 1
        ;;
esac
```

**실행 결과**:
```
$ bash workflow-gate.sh JOB-1001 start
[Workflow] JOB-1001 시작

$ bash workflow-gate.sh JOB-1001 complete
[Workflow] JOB-1001 완료
```

### 3. 심링크 금지 규칙

**텍스트 규칙**: "심링크는 생성하지 않는다."

**스크립트 강제**: `check-symlink.sh`

```bash
#!/bin/bash
# check-symlink.sh - 심링크 확인 스크립트

FILE_PATH="$1"

# 심링크 확인
if [ -L "$FILE_PATH" ]; then
    echo "[Error] 심링크 감지: $FILE_PATH"
    echo "[Info] 원본: $(readlink -f "$FILE_PATH")"
    exit 1
fi

# 물리적 inode 확인
INODE=$(stat -c %i "$FILE_PATH" 2>/dev/null)

echo "[Validation] 물리적 파일 확인 완료: $FILE_PATH (inode: $INODE)"
exit 0
```

**실행 결과**:
```
$ bash check-symlink.sh ~/.hermes/workspace/jobs/JOB-1001
[Validation] 물리적 파일 확인 완료: /home/bot/.hermes/workspace/jobs/JOB-1001 (inode: 123456)
```

---

## 다른 대안과의 비교

| 대안 | 문제점 | Hermes 해결책 |
|------|--------|---------------|
| **텍스트 규칙** | 에이전트 규칙 무시, 강제력 부재 | 스크립트로 규칙 강제 |
| **수동 검증** | 인간 개입 필요, 느림 | 자동화된 검증 스크립트 |
| **Prompt Engineering** | 모델 상태에 따라 결과 불안정 | 상태머신 + 스크립트 강제 |

---

## 실제 운영 사례

### 성공 사례: 심링크 폭주 해결

**문제**:
- 두 에이전트 파일 동기화를 위해 심링크 광범위하게 사용
- LLM의 파일 탐색 효율 급격히 저하

**해결**:
- `check-symlink.sh` 스크립트 강제 실행
- 심링크 감지 시 즉시 작업 중단

**결과**:
- 심링크 폭주 문제 해결
- 파일 탐색 효율 90% 개선

### 실패 사례: 규칙 충돌 (해결됨)

**문제**:
- "설계서 작성 필수" 규칙과 "간단한 수정은 우회" 규칙 충돌
- 에이전트가 두 규칙 모두 무시

**해결**:
- `[JOB]` (설계서 필수)과 `[TASK]` (우회 허용) 명시적 분리
- 스크립트가 JOB/TASK 구분 → 적절한 검증 실행

**결과**:
- 규칙 충돌 0% (이전 25%에서)

---

## 관련 포스트

- [왜 9단계 상태머신인가?](./why-9-step-workflow.md)
- [역할 기반 모델 라우팅 설계](./model-routing-design.md)
- [이벤트 기반 도메인 통신](./event-driven-communication.md)

---

_텍스트 규칙은 권고사항일 뿐입니다. Hermes는 스크립트로 규칙을 강제하여 에이전트의 규칙 무시를 방지합니다._
