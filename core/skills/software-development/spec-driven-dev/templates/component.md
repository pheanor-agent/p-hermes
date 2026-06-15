# Spec 템플릿: 컴포넌트

---
spec_id: SPEC-XXX
version: 0.1.0
version_history:
  - version: 0.1.0
    date: YYYY-MM-DD
    status: proposed
    summary: "초기 생성"
status: proposed
priority: P?
category: 컴포넌트 설계
related_specs: []
code_refs: []
test_refs: []
job_refs: []
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

### [SPEC-XXX] 컴포넌트명

**설명**: 컴포넌트 역할/책임

## SBE: 구체적 예시

```yaml
examples:
  - name: "정상 케이스"
    input:
      param1: value1
      param2: value2
    expected:
      output: result
      status: success
  - name: "에러 케이스"
    input:
      param1: invalid
    expected:
      error: "INVALID_PARAM"
```

## DbC: 계약 조건

```yaml
contract:
  preconditions:
    - "param1 is not null"
    - "param2 > 0"
  postconditions:
    - "output is not null"
    - "response time < 100ms"
  invariants:
    - "object state remains valid"
```

## BDD: 수락 기준

```gherkin
Given [전제 조건]
When [동작]
Then [기대 결과]
```

## 인터페이스

- **Input**: 
- **Output**: 
- **Side Effects**: 

## 내부 구조

- 모듈 1: 
- 모듈 2: 

## 검증 기준

| 항목 | 기준 |
|------|------|
| 기능 | 모든 예시 통과 |
| 성능 | 응답 시간 < 100ms |
| 안정성 | 에러 케이스 처리 |
