# API-First Design

## 개요
API 설계 후 코드 구현하는 방법론. OpenAPI/Swagger 스펙 기반.

## 핵심 워크플로우
1. API 스펙 작성 (OpenAPI YAML/JSON)
2. 스펙 검증
3. 코드 생성 (Swagger Codegen 등)
4. 구현 로직 작성

## Spec 템플릿 적용
```yaml
type: api
endpoints:
  - path: /auth/login
    method: POST
    request:
      body: { username: string, password: string }
    response:
      200: { token: string }
      401: { error: string }
```

## 도구
- Swagger/OpenAPI
- Postman
- Stoplight

## 장점
- 프론트/백엔드 병렬 개발
- API 문서 자동 생성
- 클라이언트 코드 자동 생성

## 참조
- OpenAPI Specification 3.0
- Swagger 공식 문서
