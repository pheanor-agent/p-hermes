# Spec 기반 개발 방법론 비교

## 조사 요약

| 방법론 | 실행 가능한 Spec | 코드 연동 | Hermes Workflow 연동 |
|--------|----------------|----------|---------------------|
| MDA | ✅ | ✅ | ❌ |
| DbC | ✅ | ✅ | ⚠️ |
| SBE/BDD | ✅ | ✅ | ✅ |
| Contract-Driven | ✅ | ✅ | ✅ |
| Formal Methods | ✅ | ❌ | ❌ |
| TDD/BDD | ✅ | ✅ | ✅ |
| AI Spec-to-Code | ✅ | ✅ | ⚠️ |

## 공통 실패 원인

1. **Spec-Code 동기화 실패**: Spec과 코드가 분리되어 수정 → Spec outdated
2. **의도 손실**: Spec 작성 시 추상적 표현 → 코드 개발자 의도 해석 차이
3. **변경 관리 부재**: Spec 변경 시 영향 분석 없이 코드만 수정
4. **검증 누락**: Spec 준수도 정량적 검증 부재

## 성공 조건

1. **Executable Spec**: Spec이 테스트/검증 가능한 형태
2. **Matrix 기반 동기화**: 코드↔테스트↔Spec Traceability 자동 유지
3. **정량적 검증**: Conformance Score로 객관적 준수도 측정
4. **변경 관리 프로세스**: Spec 변경 → 재리뷰 → 재승인 → 코드 반영 강제

## 각 방법론 상세

### MDA (Model-Driven Architecture)
- **강점**: 추상적 모델 → 구체적 코드 자동 생성
- **약점**: 과잉 설계 경향, 학습 곡선 가파름
- **Hermes 적합도**: 중 (Spec 기반 자동화 가능)

### DbC (Design by Contract)
- **강점**: precondition/postcondition/Invariant 명시
- **약점**: 계약 위반 시 실행 중단 (에러 처리 문제)
- **Hermes 적합도**: 고 (계약 기반 검증 자동화)

### SBE/BDD (Specification by Example / Behavior-Driven Development)
- **강점**: 예제 기반 Spec, Gherkin 형식 자동화
- **약점**: 비개발자 참여 어려움
- **Hermes 적합도**: 고 (Hermes가 Gherkin 변환 가능)

### Contract-Driven Development
- **강점**: API 계약 (OpenAPI/Swagger) 기반 개발
- **약점**: API만 커버 (비즈니스 로직 제외)
- **Hermes 적합도**: 중 (API 프로젝트만 적합)

### Formal Methods
- **강점**: 수학적 증명 기반 검증
- **약점**: 비용/시간 과다, 실무 적용 어려움
- **Hermes 적합도**: 저 (학습 곡선 과다)

### TDD/BDD (Test-Driven Development / Behavior-Driven Development)
- **강점**: 테스트 기반 Spec, 보편적 방법론
- **약점**: Spec↔테스트 동기화 수동
- **Hermes 적합도**: 고 (테스트 자동화 가능)

### AI Spec-to-Code
- **강점**: LLM 기반 Spec → 코드 자동 생성
- **약점**: 의도 누락, 코드 품질 변동
- **Hermes 적합도**: 중 (Hermes가 LLM이므로 자체 사용 가능하지만 의도 누락 주의)

## 권장 조합

```
SBE (Gherkin Spec) → TDD (테스트 기반 구현) → Contract (API 계약) → Formal (핵심 로직만)
```

**Hermes 구현 패턴**:
1. `specs/active/requirements.md` — Gherkin 형식 Spec
2. `tests/` — Spec 기반 테스트 (TDD)
3. `specs/active/interfaces/` — API 계약 (OpenAPI)
4. `specs/active/components/` — 핵심 로직 Spec (Formal Methods)