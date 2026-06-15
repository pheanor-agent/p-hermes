# 실패 패턴에서 배운 교훈

> 태그: #lessons-learned #debugging
> 읽는 시간: ~10분

---

## TL;DR

완벽한 시스템은 없습니다. Hermes도 수많은 오류와 실패를 겪었습니다. 이 포스트에서는 반복적으로 발생했던 "대형 참사"들과 그 근본 원인(Root Cause), 그리고 이를 시스템적으로 막기 위해 도입한 안전 장치를 공유합니다.

```
┌─────────────────────────────────────────────────────┐
│              실패 패턴 및 해결책                      │
├─────────────────────────────────────────────────────┤
│                                                     │
│  문제          →  근본 원인      →  해결책          │
│                                                     │
│  중복 폴더     →  mkdir 허용      →  create-job.sh  │
│  심링크 폭주   →  파일 동기화    →  물리적 격리      │
│  컨텍스트 손실  →  컴팩션 누락    →  SSOT 설계서      │
│  Gateway 오류   →  반환 형식     →  Type Enforcement │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 교훈 1: 중복 폴더 생성 문제 (JOB-907, JOB-1143)

### 현상

에이전트가 작업 폴더를 생성할 때, `~/.hermes/workspace/jobs/` 대신 임의의 경로를 만들었습니다.

```
~/.hermes/workspace/
├── jobs/
│   └── JOB-1001/
├── job-1001/          ← 에이전트가 임의로 생성
├── JOB1001/           ← 에이전트가 임의로 생성
└── job_1001_backup/   ← 에이전트가 임의로 생성
```

### 문제

- 워크플로우 관리 스크립트가 첫 번째 폴더만 인식 → 결과가 분산됨
- 데이터 동기화 깨짐 → 세션 이력과 JOB 결과 불일치

### 근본 원인

- 에이전트가 `mkdir` 명령어를 직접 사용 가능
- 폴더 네이밍 규칙 강제 부재

### 해결책

**JOB 등록 스크립트 (`create-job.sh`) 강제화**

```bash
# 에이전트가 사용 가능한 명령어 제한
# ❌ 금지: mkdir ~/.hermes/workspace/jobs/JOB-1001/
# ✅ 허용: bash create-job.sh -y 기능 "작업 제목"
```

**create-job.sh 동작 흐름**:
```
1. 락 획득 (flock)
2. 중복 번호 확인
3. 폴더 생성 (표준 경로)
4. workflow-state 파일 생성
5. JOB INDEX 갱신
```

---

## 교훈 2: 심링크(Symlink) 폭주 (JOB-1626)

### 현상

두 에이전트(Hermes와 OpenClaw)의 파일을 동기화하기 위해 심링크를 광범위하게 사용했습니다.

```
~/.hermes/workspace/jobs/ → ~/.openclaw/workspace/jobs/
~/.hermes/knowledge/ → ~/.openclaw/knowledge/
~/.hermes/scripts/ → ~/.shared/scripts/
```

### 문제

- LLM의 파일 탐색 효율 급격히 저하
- "파일은 있는데 왜 못 읽어?" 오류 빈번
- 심링크 원본 변경 시 모든 링크 영향 → 데이터 손상 위험

### 근본 원인

- 파일 동기화를 위해 심링크 사용
- 물리적 격리 원칙 부재

### 해결책

**물리적 격리 원칙 도입**

```
┌─────────────────────────────────────────────────────┐
│              물리적 격리 원칙                        │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ❌ 금지: 심링크 사용                               │
│  ✅ 허용: 상태 파일 + 이벤트 기반 비동기 동기화      │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**대안**: 상태 파일과 이벤트 기반으로 비동기 동기화
- Hermes가 작업 완료 → 상태 파일 갱신
- OpenClaw가 상태 파일 스캔 → 변경 사항 감지 → 백업/동기화

---

## 교훈 3: 컨텍스트 손실 (Context Collapse)

### 현상

장시간 세션 중반에 에이전트가 "설계서 내용을 잊어버리고" 직접 코드를 수정하려 했습니다.

**실제 사례**: 2026-03-15
- JOB-1400 (5-Tier 아키텍처 구현)
- Investigation → Design 완료
- Execution 단계 진입 시, 설계서 내용 잊어버림
- 결과: 설계서와 다른 폴더 구조 생성 → 2시간 재작업

### 문제

- 컨텍스트 윈도우 한계에 도달
- 컴팩션(Compaction) 과정에서 핵심 가이드라인 누락
- 에이전트가 "설계서를 다시 읽어라"는 지시 잊어버림

### 근본 원인

- 컨텍스트 윈도우 한계 (128K tokens)
- 컴팩션 시 설계서 내용 요약 생략
- SSOT (Single Source of Truth) 설계서 부재

### 해결책

**SSOT 설계서 강제 읽기**

```python
# execution 시작 전 설계서 읽기 강제화
def execute_job(job_id: str):
    """
    실행 전 설계서를 반드시 읽습니다.
    """
    design_path = f"~/.hermes/workspace/jobs/{job_id}/design.md"
    
    # 설계서 읽기
    design_content = read_file(design_path)
    
    # 프롬프트에 설계서 포함
    prompt = f"""
    설계서를 읽은 후 작업을 시작하세요.
    
    설계서:
    {design_content}
    """
    
    execute(prompt)
```

---

## 교훈 4: Gateway Hook 반환 형식 오류 (JOB-1233)

### 현상

Gateway 스크립트가 "NO_REPLY"라는 텍스트를 반환하여 메시징 시스템이 뻑뻑해졌습니다.

```python
# Gateway Hook 예시
def gateway_hook(message: dict) -> str:
    """
    메시지 처리 후 반환
    """
    if should_skip(message):
        return "NO_REPLY"  # ❌ 텍스트 반환 (에러 발생)
    
    return process(message)
```

### 문제

- 시스템은 텍스트가 아닌 `{"action": "skip"}`과 같은 딕셔너리 형식을 기대
- "NO_REPLY" 텍스트 반환 → 시스템 크래시
- 결과: 모든 메시지 처리 중단, 수동 재시작 필요

### 근본 원인

- 반환 형식 강제 부재
- 스크립트 개발 시 반환 형식 검증 누락

### 해결책

**Type Enforcement (형 강제화)**

```python
# Gateway Hook 반환 형식 강제 검증
def validate_gateway_return(return_value: any) -> dict:
    """
    Gateway Hook 반환 값 검증
    """
    if isinstance(return_value, str):
        # 텍스트 반환 시 즉시 예외 처리
        raise ValueError(
            f"Gateway Hook 반환 형식 오류: 문자열 반환 감지. "
            f'딕셔너리 형식 사용 ({\"action\": \"skip\"})'
        )
    
    if not isinstance(return_value, dict):
        raise ValueError(f"Gateway Hook 반환 형식 오류: {type(return_value)}")
    
    if 'action' not in return_value:
        raise ValueError("Gateway Hook 반환 형식 오류: action 필드 누락")
    
    return return_value

# 사용 예시
return_value = gateway_hook(message)
validate_gateway_return(return_value)  # 검증 실행
```

---

## 교훈 5: 절대 경로 사용 문제 (JOB-1626)

### 현상

스크립트에서 `~/.hermes/` 절대 경로를 하드코딩하여 환경이 변경되면 실행 불가

```bash
# ❌ 금지: 절대 경로 하드코딩
HERMES_HOME="/home/bot/.hermes"

# ✅ 허용: $HERMES_ROOT 환경변수 사용
HERMES_HOME="${HERMES_ROOT:-~/.hermes}"
```

### 문제

- Windows/Linux 환경 변경 시 스크립트 실행 불가
- Docker 컨테이너에서 경로 매핑 실패

### 근본 원인

- `$HERMES_ROOT` 환경변수 사용 강제 부재
- 스크립트 개발 시 추상화 원칙 미준수

### 해결책

**$HERMES_ROOT 추상화 원칙**

```bash
# 모든 스크립트에서 $HERMES_ROOT 사용
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HERMES_ROOT="${HERMES_ROOT:-$HOME/.hermes}"
```

---

## 종합 교훈: 반복되는 실수를 시스템으로 막아라

어떤 문제든 **"에이전트가 더 똑똑해지면 해결된다"**는 생각은 버렸습니다.

### 3가지 핵심 원칙

**1. 규칙을 텍스트로 쓰지 않는다 (스크립트로 강제한다)**
- 텍스트는 권고사항일 뿐, 강제력이 없음
- 스크립트는 실패 시 무조건 중단

**2. 수동 검증을 신뢰하지 않는다 (자동 검증을 실행한다)**
- 인간은 실수함
- 스크립트는 항상 동일한 결과 반환

**3. 실패 시 재시도하지 않는다 (근본 원인을 분석하고 구조를 고친다)**
- 재시도는 동일한 실패 반복
- 근본 원인 제거가 중요

---

## 관련 포스트

- [왜 9단계 상태머신인가?](./why-9-step-workflow.md)
- ["텍스트 규칙 → 스크립트 강제" 철학](./structural-enforcement.md)
- [5-Tier 물리 계층화 설계](./why-5-tier-architecture.md)

---

_실패는 시스템 설계의 가장 중요한 교훈입니다. Hermes는 실패를 통해 더 견고한 시스템을 구축했습니다._
