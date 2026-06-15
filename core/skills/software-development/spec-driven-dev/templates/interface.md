# Spec 템플릿: 인터페이스

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
category: 인터페이스
related_specs: []
code_refs: []
test_refs: []
job_refs: []
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

### [SPEC-XXX] 인터페이스명

## 인터페이스 정의

```typescript
interface InterfaceName {
  method(param: Type): ReturnType;
}
```

## DbC: 계약 조건

```yaml
contract:
  preconditions:
    - "param is valid"
  postconditions:
    - "returns valid result"
  invariants:
    - "interface contract maintained"
```

## SBE: 사용 예시

```yaml
examples:
  - name: "기본 사용"
    input:
      param: value
    expected:
      result: expected_value
```

## 구현 가이드

- 필수 구현: 
- 선택 구현: 

## 검증 기준

| 항목 | 기준 |
|------|------|
| 계약 | Pre/Post 조건 충족 |
| 예시 | 모든 예시 통과 |
| 호환 | 하위 호환 유지 |
