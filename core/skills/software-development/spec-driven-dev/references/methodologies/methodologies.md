# Spec-Driven Development — 목적과 방법론

> JOB-1467 조사 결과 (2026-06-02)
> 웹 조사: Wikipedia (Model-driven architecture, Design by contract, Specification by example)

---

## 근본 목적: 왜 사양서 기반 코딩인가?

사양서 기반 개발의 근본 목적은 **요구사항 → 설계 → 코드 과정에서 의미 손실을 방지**하는 것이다.

| 목적 | 설명 |
|------|------|
| **의미 손실 방지** | 인간 언어(요구사항) → 구조(설계) → 구현(코드) 변환 시 정보 보존 |
| **검증 가능성** | "이 코드가 요구사항을 구현했는가"를 객관적으로 증명 |
| **변경 영향 예측** | 요구사항 변경 시 영향받는 코드/Test 사전 파악 |
| **복잡성 관리** | 대규모 시스템에서 설계 의도를 코드에서 추적 |
| **팀 간 계약** | 인터페이스 사전 정의 → 병렬 개발/독립 배포 가능 |
| **지식 보존** | 개발자 이탈 시에도 "왜 이렇게 만들었는지" 복원 가능 |

---

## 조사된 방법론

| 방법론 | 연도 | 목적 | Spec→Code 매핑 | 현재 상태 |
|--------|------|------|----------------|----------|
| **Model-Driven Architecture (MDA)** | OMG 2001 | 추상 모델 자동 코드 변환 | PIM→PSM transformation | ⚠️ 과잉 설계, 도구 lock-in |
| **Design by Contract (DbC)** | Bertrand Meyer, 1986 | 인터페이스 계약 명시 (pre/post 조건, 불변식) | Contract→Runtime assertion | ✅ 계약 기반 유효 |
| **Specification by Example (SBE)** | Gojko Adzic, 2009+ | 예제로 요구사항 정의 | Example→Acceptance Test | ✅ BDD/Cucumber 활성화 |
| **Contract-Driven API** | OpenAPI/Swagger | API 스펙 → Client/Server 코드 | YAML/JSON→Code gen | ✅ 산업 표준 |
| **Formal Methods** | TLA+, Z notation | 수학적 검증 | Formal spec→Code | ⚠️ 복잡도/비용 |
| **TDD/BDD** | Kent Beck, Dan North | 테스트=사양서 | Test(spec)→Code | ✅ 보편적 표준 |
| **AI/LLM Spec-to-Code** | 2024-2026 | 자연어 Spec→LLM 코드 생성 | Prompt→Generated code | 🔥 신흥 |

---

## 핵심 인사이트

1. **공통 실패 원인**: 사양서 ↔ 코드 동기화 실패 (spec drift)
2. **성공 조건**: 사양서가 **실행 가능한(executable)** 것일 때만 유지보수 가능
   - OpenAPI: 실제 API 스펙 → 테스트 자동화
   - TDD: 테스트 자체가 living spec
   - BDD: Gherkin → 자동 테스트
3. **AI 시대 변화**: LLM이 Spec→Code 매핑 자동화하지만, Traceability 필요성 오히려 증가

---

## 공통 실패 패턴

| 실패 패턴 | 원인 | 대응 |
|-----------|------|------|
| **Spec drift** | 사양서 ↔ 코드 동기화 실패 | Executable spec (테스트/검증 자동화) |
| **Overhead** | 문서화 비용 > 가치 | Living documentation (자동 생성) |
| **Impedance mismatch** | Spec ↔ Code 표현 격차 | Domain-Specific Language (DSL) |
| **Tool lock-in** | 특정 도구 의존성 | 표준 포맷 (YAML/JSON/Markdown) |
| **Stale specs** | 업데이트되지 않은 사양 | CI/CD 연동 검증 |

---

## 성공 조건 요약

1. **사양서가 실행 가능해야 함** (Executable Spec)
2. **자동화된 검증** (CI/CD에서 spec conformance check)
3. **경량 포맷** (Markdown/YAML/JSON — LLM/인간 모두 읽기 용이)
4. **Traceability** (Spec Item → Code → Test mapping)
5. **변경 관리** (Spec delta → Impact analysis → Re-verification)
