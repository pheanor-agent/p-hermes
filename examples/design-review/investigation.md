# 설계 리뷰 — 조사 단계

- **JOB**: JOB-2026-0622-001
- **조사 기간**: 2026-06-22 10:00 ~ 10:45
- **참조**: JOB-2026-0605-002, SPEC-MSG-01

## 1. 기존 사례 분석

**JOB-2026-0605-002 (payment-gateway-architecture)** 의 리뷰 이력을 조사했습니다.

- 해당 설계는 Apache Kafka 기반이었으며, 3가지 구조적 문제가 지적됨
- Knowledge 저장 경로: `knowledge/system/architecture/payment-gateway-v1/`
- 주요 교훈: "인증 체계가 명시되지 않은 아키텍처는 Gate 통과 불가"

## 2. 관련 SPEC 검토

`specs/active/SPEC-MSG-01.md` — Hermes 메시징 표준:

| 항목 | 요구사항 | 현재 설계 |
|------|---------|----------|
| 이벤트 포맷 | CloudEvents 1.0 준수 | ✅ 준수 |
| 라우팅 | Content-based 또는 Topic-based | ✅ Content-based Router |
| 재시도 | 최소 3회, 지수 백오프 명시 | ✅ 3회 재시도 (백오프 미명시 ❌) |
| DLQ | TTL + 재처리 정책 명시 | ✅ TTL 7일 (재처리 정책 미명시 ❌) |

## 3. 추가 발견 사항

1. **gRPC 브릿지 타임아웃** — 설계서에 gRPC 호출 타임아웃 값이 명시되지 않음
2. **OpenTelemetry Sampling Rate** — 분산 추적 도입 시 샘플링 정책 필요
3. **mTLS 인증서 갱신 주기** — 인증서 만료에 따른 자동 갱신 방안 누락

## 4. 참고 자료

- CloudEvents SDK v3.0.1 — Go 언어 기준 구현 예제 확인
- RabbitMQ 지수 백오프 플러그인 `rabbitmq-delayed-message-exchange`
- 이전 Knowledge: `knowledge/system/architecture/event-driven-patterns.md`
