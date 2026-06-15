# Design by Contract (DbC)

## 개요
Bertrand Meyer가 Eiffel 언어와 함께 제안. 소프트웨어 컴포넌트 간 계약 관계 정의.

## 핵심 개념
- **Preconditions**: 메서드 호출 전 만족해야 할 조건
- **Postconditions**: 메서드 호출 후 보장하는 조건
- **Invariants**: 객체 전체 생명주기 동안 유지되는 조건

## Spec 템플릿 적용
```yaml
contract:
  preconditions:
    - "token is not null"
    - "token matches JWT format"
  postconditions:
    - "returns User object or throws AuthenticationError"
  invariants:
    - "token signature must be valid"
```

## 검증 방식
```python
def validate_contract(spec, code):
    for pre in spec.contract.preconditions:
        assert evaluate(pre, code)
    for post in spec.contract.postconditions:
        assert evaluate(post, code)
    for inv in spec.contract.invariants:
        assert evaluate(inv, code)
```

## 장점
- 인터페이스 명확성
- 자동화된 계약 검증
- 버그 조기 발견

## 참조
- Bertrand Meyer, "Object-Oriented Software Construction"
- Martin Fowler, "Design By Contract"
