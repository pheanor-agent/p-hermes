# Specification by Example (SBE)

## 개요
구체적 예시를 사용하여 요구사항을 정의하는 방법론. Martin Fowler가 2004년 제안.

## 핵심 원칙
- 추상적 진술보다 구체적 예시 우선
- 비개발자도 이해할 수 있는 예시 사용
- 예시가 테스트로 직접 활용 가능

## Spec 템플릿 적용
```yaml
examples:
  - name: "유효한 경우"
    input: { token: "valid_jwt" }
    expected: { authorized: true }
  - name: "무효한 경우"
    input: { token: "expired" }
    expected: { error: "TOKEN_EXPIRED" }
```

## 장점
- 요구사항 명확성 향상
- 개발자/비개발자 공통 이해도 증진
- 자동화 테스트로 직접 전환 가능

## 단점
- 예시 커버리지 관리 필요
- edge case 누락 가능성

## 참조
- Martin Fowler, "Specification By Example" (2004)
- Gojko Adzic, "Specification by Example" (O'Reilly, 2012)
