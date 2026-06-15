# Spec 기반 피드백 처리 가이드

## 1. 피드백 처리 흐름

```
사용자의 개념적 피드백
    ↓ (LLM이 수락)
기존 Spec 기준 분석
    ↓
개선안 제안
    ↓
승인
    ↓
Spec 갱신
    ↓
코드 반영 (개발자)
    ↓
Spec 기반 재검증
```

## 2. 피드백 예시

### 예시 1: 인증 강화

```
사용자: "인증이 너무 약해"
    ↓
LLM 분석:
  - 기존 Spec-A001: HS256 알고리즘, 1시간 유효
  - 문제점: 대칭키 방식, 긴 유효기간
    ↓
개선안 제안:
  - RS256 비대칭키 변경
  - 토큰 유효기간 15분으로 단축
  - Refresh Token 도입
    ↓
승인 → Spec-A001 v0.2 갱신
    ↓
개발자가 코드 반영
    ↓
bash spec-conformance.sh my-api --review
→ ✅ Spec 기준 완전 충족
```

### 예시 2: 사용자 경험 개선

```
사용자: "사용자 경험 개선해줘"
    ↓
LLM 분석:
  - 기존 Spec-B003: 3단계 인증 절차
  - 문제점: 복잡한 절차, 긴 로딩 시간
    ↓
개선안 제안:
  - 2단계 인증으로 간소화
  - Loading indicator 도입
  - Error message 명확화
    ↓
승인 → Spec-B003 v0.2 갱신
    ↓
개발자가 코드 반영
    ↓
bash spec-conformance.sh my-api --review
→ ✅ Spec 기준 완전 충족
```

## 3. 피드백 처리 원칙

**Spec 기준 분석 필수**:

```
사용자 피드백 → 기존 Spec 분석 → 개선안 제안 → 승인 → Spec 갱신
```

**Spec이 아닌 피드백 금지**:

```
❌ "이 코드 나빠" (Spec 기준 아님)
❌ "이 함수 이름 바꿔" (Spec에 정의되지 않음)
✅ "Spec-A001 조건: HS256 서명 필요 → 코드에서 HS384 사용 중 (일치 X)"
✅ "사용자 피드백 '인증 약함' → Spec-A001 기준 RS256 변경 제안"
```

## 4. Spec 갱신 프로세스

```bash
# 1. 기존 Spec 상태 확인
cat specs/active/components/jwt-auth.md

# 2. Spec 상태 변경 (approved → changed)
bash spec-status.sh my-api SPEC-A001 changed

# 3. Spec 파일 수정 (수동 또는 LLM 지원)
# → 알고리즘, 유효기간, 조건/동작 갱신

# 4. 버전 전이 (v0.1 → v0.2)
# → version 필드 갱신
# → 변경 이력 기록

# 5. Spec 상태 갱신 (changed → approved)
bash spec-status.sh my-api SPEC-A001 approved

# 6. 개발자에게 코드 반영 요청
# → 갱신된 Spec 기반 코드 수정

# 7. 재검증
bash spec-conformance.sh my-api --review
```

## 5. Traceability 유지

Spec 변경 시 다음을 반드시 갱신:

- `_matrix.json`: version, status, code_refs, test_refs
- `CHANGELOG.md`: 변경 이력 자동 기록
- 관련 Spec: 의존성 업데이트
- AGENTS.md: 변경사항 안내
