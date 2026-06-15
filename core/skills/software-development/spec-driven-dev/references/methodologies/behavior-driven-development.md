# Behavior-Driven Development (BDD)

## 개요
Dan North가 제안한 테스트 중심 개발 방법론. TDD의 진화형.

## 핵심 문법 (Gherkin)
```gherkin
Feature: User Authentication
  Scenario: Valid login
    Given a registered user
    When the user submits valid credentials
    Then access should be granted
```

## Spec 템플릿 적용
```yaml
acceptance_criteria:
  given: "사용자가 유효한 토큰 보유"
  when: "API 엔드포인트 접근"
  then: "권한 부여 + 응답 반환"
```

## TDD vs BDD
| 항목 | TDD | BDD |
|------|-----|-----|
| 초점 | 단위 테스트 | 사용자 행동 |
| 참여자 | 개발자 | 개발자+테스터+제품매니저 |
| 문법 | assert/expect | Given/When/Then |

## 도구
- Cucumber (Ruby/Java)
- SpecFlow (.NET)
- Behave (Python)

## 참조
- Dan North, "Introducing BDD" (2008)
- Cucumber 공식 문서
