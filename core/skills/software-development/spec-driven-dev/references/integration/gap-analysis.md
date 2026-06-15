# System Integration Gap Analysis

**분석일**: 2026-06-04
**출처**: JOB-1498 분석 결과

---

## 개요

spec-driven-dev v2.0이 "단일 진실 근원"으로 선언되었으나, 실제 Hermes 파이프라인과 연계되지 않고 독립적으로 동작함.

---

## 격차 분석

| # | 시스템 | 현재 상태 | 이상적 상태 | 심각도 |
|---|--------|-----------|-------------|--------|
| 1 | workflow-gate.sh | Spec 체크포인트 없음 | Spec 단계 검증 강제 | 🔴 높음 |
| 2 | architecture-review | Spec 기반 검증 없음 | Spec traceability 검증 | 🔴 높음 |
| 3 | spec-conformance.sh | 테스트 실행 안 함 | pytest 자동 실행 | 🔴 높음 |
| 4 | triage | Spec 영향 cascade 없음 | Spec 변경 시 JOB 자동 분류 | 🟡 중간 |
| 5 | knowledge | Spec 검색/참조 없음 | Spec 기반 지식 탐색 | 🟡 중간 |
| 6 | bridge API | Spec 정보 미포함 | Spec 상태 공유 | 🟡 중간 |

---

## 상세 분석

### 🔴 Gap 1: workflow-gate.sh Spec 체크포인트 미통합

**문제**: workflow-gate.sh가 모든 JOB의 핵심 파이프라인이지만, Spec 관련 체크포인트가 없음

**증상**:
- `grep "spec" workflow-gate.sh` → 0개 매치
- Spec 체크포인트(I-spec-ref ~ I-spec-sync)가 정의되어 있지만, 실제 enforce 안 함

**해결 방안**:
- 조건부 검증 도입: `if spec 참조 존재 then 검증 else skip`
- 기존 spec-free JOB에 영향 없도록 graceful degradation 설계

### 🔴 Gap 2: architecture-review가 Spec 기반 검증 안 함

**문제**: architecture-review 스킬이 architecture.md를 리뷰하지만, Spec 기반 검증 로직이 없음

**증상**:
- review-result.md에 Spec ID 참조 없음
- Spec traceability 검증 수행 안 함

**해결 방안**:
- review-checklist에 Spec 검증 항목 추가
- spec-conformance.sh 호출 후 score 기반 판정

### 🔴 Gap 3: spec-conformance.sh 테스트 실행 안 함

**문제**: spec-conformance.sh가 conformance score를 계산하지만, 실제 테스트 실행 로직이 없음

**증상**:
- `validate_examples()`, `validate_contract()` 함수가 "pending implementation" 상태
- 실제 pytest 호출 로직 부재

**해결 방안**:
- `--run-tests` 플래그 도입
- pytest 통합 후 conformance score 자동 계산

---

## 연계 강화 방향

### Phase별 구현 계획

| Phase | 작업 | 기간 | 의존성 |
|-------|------|------|--------|
| P0 | workflow-gate + spec-status 연동 | 1일 | 없음 |
| P0 | architecture-review + spec-conformance 연동 | 1일 | 없음 |
| P1 | spec-conformance 테스트 자동화 | 2일 | P0 |
| P1 | triage + spec-impact 연동 | 1일 | P0 |
| P2 | knowledge + Spec 검색 연동 | 1일 | P1 |
| P2 | bridge API + Spec 상태 공유 | 1일 | P1 |

### 리스크 완화

| 리스크 | 영향 | 완화 방안 |
|--------|------|-----------|
| workflow-gate.sh 수정 파급효과 | 모든 JOB에 영향 | 조건부 검증 |
| 롤백 부재 | 연계 실패 시 복구 불가 | Phase별 rollback 절차 |
| spec-conformance.sh 실패 | _matrix.json 부재 시 workflow 차단 | graceful degradation |
| 토큰 소모 증가 | 각 단계마다 추가 호출 | 체크포인트 6개로 제한 |

---

## Traceability Matrix 자동 갱신 시점

| 시점 | 동작 | 담당 스크립트 |
|------|------|---------------|
| spec-status.sh 상태 변경 시 | _matrix.json 항목 상태 갱신 | spec-status.sh 내부 |
| workflow-gate.sh complete 시 | _matrix.json code_refs/test_refs 갱신 | spec-sync.sh |
| spec-conformance.sh 실행 시 | conformance score 갱신 | spec-conformance.sh 내부 |

---

## Edge Case 시나리오

| 시나리오 | 검증 | 기대 동작 |
|----------|------|-----------|
| Spec 파일 부재 | workflow-gate.sh 실행 | graceful degradation: WARN 출력 + 계속 진행 |
| spec-conformance.sh 실패 | _matrix.json 부재 | 스크립트 실패 시 ERROR + fallback: 수동 검증 |
| 롤백 테스트 | Phase 완료 후 rollback | git checkout으로 원래 상태로 복원 |
| 병렬 작업 충돌 | spec-status.sh 동시 호출 | flock으로 원자적 업데이트 보장 |
