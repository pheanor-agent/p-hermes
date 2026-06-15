# Cucumber (BDD)

## 개요
Gherkin 문법 기반 BDD 프레임워크. Feature 파일로 테스트 정의.

## Feature 파일 구조
```gherkin
Feature: Authentication
  Scenario: Valid token
    Given a valid JWT token
    When I access /api/protected
    Then I should receive 200 OK
```

## Spec 연동
```yaml
# Spec → Feature 파일 매핑
spec_id: SPEC-C001
feature_file: "features/authentication.feature"
scenario: "Valid token"
```

## Step Definitions
```python
@given('a valid JWT token')
def step_impl(context):
    context.token = generate_valid_token()

@when('I access /api/protected')
def step_impl(context):
    context.response = requests.get('/api/protected',
        headers={'Authorization': f'Bearer {context.token}'})

@then('I should receive 200 OK')
def step_impl(context):
    assert context.response.status_code == 200
```

## 참조
- https://cucumber.io/
- Gherkin Syntax
