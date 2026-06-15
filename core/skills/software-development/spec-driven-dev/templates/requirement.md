# Spec 템플릿: 요구사항

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
category: 요구사항
related_specs: []
code_refs: []
test_refs: []
job_refs: []
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

### [SPEC-XXX] 요구사항명

## 사용자 스토리 (BDD)

```
As a [사용자 역할]
I want [기능]
So that [목적]
```

## 수락 시나리오

```yaml
scenarios:
  - name: "성공 케이스"
    given: "[전제 조건]"
    when: "[동작]"
    then: "[기대 결과]"
  - name: "실패 케이스"
    given: "[전제 조건]"
    when: "[동작]"
    then: "[에러 처리]"
```

## SBE: 구체적 예시

```yaml
examples:
  - name: "예시 1"
    input: {}
    expected: {}
```

## 비기능 요구사항

```yaml
non_functional:
  performance: "응답 시간 < 100ms"
  security: "데이터 암호화"
  availability: "99.9% 가동률"
```

## 인터페이스

- **Input**: 
- **Output**: 

## 검증 기준

| 항목 | 기준 |
|------|------|
| 기능 | 모든 시나리오 통과 |
| 성능 | 비기능 요구사항 충족 |
| 보안 | 보안 요구사항 충족 |
