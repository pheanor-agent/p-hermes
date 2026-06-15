# OpenAPI/Swagger

## 개요
REST API를 위한 사양서 표준. Swagger Specification에서 진화.

## 주요 구성 요소
- **Paths**: API 엔드포인트 정의
- **Operations**: HTTP 메서드별 동작
- **Parameters**: 입력/출력 파라미터
- **Responses**: 응답 스펙

## Spec 연동
```yaml
# OpenAPI 스펙 → Spec 템플릿 변환
spec_id: SPEC-API001
type: api
openapi_ref: "openapi.yaml#/paths/~1auth~1login"
```

## 코드 생성
```bash
# Swagger Codegen
swagger-codegen generate \
  -i openapi.yaml \
  -l python \
  -o ./src/
```

## 참조
- https://swagger.io/docs/specification/about/
- OpenAPI 3.0 Specification
