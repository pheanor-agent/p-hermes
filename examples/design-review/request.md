# 설계 문서 리뷰 요청

## 요청 개요

- **JOB**: JOB-2026-0622-001
- **요청자**: 김태호 (Backend 팀)
- **요청일**: 2026-06-22
- **상태**: 접수 완료

## 요청 내용

안녕하세요, Hermes.

저희 팀에서 새롭게 구축할 **마이크로서비스 간 이벤트 브릿지 시스템**의 설계 문서를 작성했습니다. 이 설계가 Hermes의 시스템 아키텍처 원칙과 Knowledge 관리 정책에 부합하는지 리뷰해주세요.

### 주요 검토 항목

1. **Event Schema 설계** — CloudEvents 1.0 스펙 기반, 확장성 확보 여부
2. **Dead Letter Queue 정책** — 실패한 이벤트의 재처리 및 보관 전략
3. **모니터링 체계** — Hermes Gateway와의 통합 가능성
4. **보안** — 서비스 간 인증 및 페이로드 암호화

### 참고 링크

- 설계 문서: `designs/event-bridge-architecture-v2.md`
- 관련 SPEC: `specs/active/SPEC-MSG-01.md`

## 기대사항

리뷰 결과는 Knowledge 시스템에 저장되어 향후 유사 설계의 참고 자료로 활용되었으면 합니다. 특히 이전 설계 리뷰인 JOB-2026-0605-002 (`payment-gateway-architecture`)의 사례를 참고하여 일관성 있는 피드백을 부탁드립니다.

## 첨부

> 설계 문서의 주요 내용은 다음과 같습니다:
> - 서비스 간 통신: RabbitMQ + gRPC 브릿지
> - 이벤트 라우팅: Content-based Router 패턴
> - DLQ: 3회 재시도 후 별도 큐, TTL 7일
> - 모니터링: OpenTelemetry 기반 분산 추적
> - 보안: mTLS + JWT 클레임 검증
