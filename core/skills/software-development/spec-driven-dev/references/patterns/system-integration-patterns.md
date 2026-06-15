# 시스템 연계 설계 패턴 (JOB-1498/1499 학습)

## 연계 설계 시나리오 템플릿

시스템 간 연계를 설계할 때 사용하는 5가지 기본 시나리오:

### S1: 신규 기능 개발 (Happy Path)
```
요청 → Spec 생성 → 설계 → 리뷰 → 승인 → 구현 → 테스트 → 완료
```
- spec-create.sh로 Spec 생성
- workflow-gate.sh로 단계 전환
- architecture-review로 Spec 기반 검증
- spec-conformance.sh --run-tests로 테스트 자동화

### S2: 설계 변경 (B-type)
```
승인 → 변경 감지 → 영향 분석 → 재리뷰 → 재승인 → 수정 → 재검증
```
- spec-impact.sh로 영향도 분석
- architecture.md Before/After 테이블 필수
- 재리뷰 + 재승인 강제

### S3: 버그 수정
```
버그 발견 → Spec 영향 분석 → 수정 → Conformance 재검증 → 완료
```
- 코드 annotation에서 Spec ID 확인
- spec-impact.sh로 영향도 분석
- spec-conformance.sh로 재검증

### S4: 복잡한 시스템 변경
```
요청 → 영향 분석 → Spec 병렬 작업 → 통합 → 검증
```
- 하위 JOB 분할 (--parent 패턴)
- delegate_task로 병렬 실행
- flock 기반 원자적 업데이트

### S5: Legacy 코드 Migration
```
코드 분석 → Spec 역작성 → 점진적 교체 → 검증 → 완료
```
- 기존 코드에서 Spec 추출
- 점진적 코드 변경
- conformance score 계산

---

## 조건부 검증 패턴

spec-free JOB에 영향 주지 않고 Spec 검증 강제:

```bash
# has_spec_references() 함수 사용
if has_spec_references "$JOB_DIR"; then
    # Spec 체크포인트 검증
    bash workflow-gate.sh JOB-XXXX checkpoint I-spec-ref
else
    echo "SKIP: spec-free JOB — 검증 생략"
fi
```

---

## graceful degradation 패턴

테스트/스크립트 실패 시 workflow 차단 방지:

```bash
# 실패 시에도 exit 0 반환
bash spec-conformance.sh <slug> --run-tests || {
    echo "  ⚠️  Conformance 실패 (graceful degradation)"
    exit 0  # workflow 계속 진행
}
```

---

## Traceability Matrix 자동 갱신 시점

| 시점 | 동작 | 담당 스크립트 |
|------|------|---------------|
| spec-status.sh 상태 변경 시 | _matrix.json 항목 상태 갱신 | spec-status.sh 내부 |
| workflow-gate.sh complete 시 | _matrix.json code_refs/test_refs 갱신 | spec-sync.sh |
| spec-conformance.sh 실행 시 | conformance score 갱신 | spec-conformance.sh 내부 |

---

## 연계 설계 격차 분석 템플릿

| # | 시스템 | 현재 상태 | 이상적 상태 | 격차 |
|---|--------|-----------|-------------|------|
| 1 | workflow-gate | Spec 체크포인트 없음 | Spec 단계 검증 강제 | 🔴 높음 |
| 2 | architecture-review | Spec 기반 검증 없음 | Spec traceability 검증 | 🔴 높음 |
| ... | ... | ... | ... | ... |

---

## 수치화된 검증 기준 템플릿

| Phase | 기준 | 측정 지표 |
|-------|------|-----------|
| P0 | 체크포인트 X개 추가 | workflow-gate.sh에 spec 관련 라인 >= 10 |
| P1 | pytest 연동 후 conformance score Z% 이상 자동 달성 | score >= 90% |
| P2 | bridge API 호출 시 Spec 정보 포함율 W% | specRefs 포함률 >= 80% |
