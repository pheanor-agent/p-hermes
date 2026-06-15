# System Integration Patterns (JOB-1498/1499/1500)

Hermes 시스템 간 연계 설계 시나리오와 패턴. spec-driven-dev를 "단일 진실 근원"으로 다른 시스템(workflow-gate, architecture-review, triage, knowledge, bridge API)과 연동하는 방법.

---

## 워크플로우 시나리오 5개

### S1: 신규 기능 개발 (Happy Path)
```
요청 → Spec 생성 → 설계 → 리뷰 → 승인 → 구현 → 테스트 → 완료
```
- workflow-gate.sh: I-spec-ref, I-spec-matrix 체크포인트
- architecture-review: Spec traceability 검증
- spec-conformance.sh --run-tests: pytest 자동 실행
- spec-sync.sh: Matrix 동기화

### S2: 설계 변경 (B-type)
```
승인 → 변경 감지 → 영향 분석 → 재리뷰 → 재승인 → 수정 → 재검증
```
- spec-impact.sh: 영향도 분석
- spec-status.sh: changed 상태 갱신
- architecture.md: Before/After 테이블 + 변경 이력
- 재리뷰 → 재승인 → 수정

### S3: 버그 수정
```
버그 발견 → Spec 영향 분석 → 수정 → Conformance 재검증 → 완료
```
- 코드 annotation에서 Spec ID 확인
- spec-conformance.sh --run-tests: 재검증
- spec-status.sh: verified 상태 갱신

### S4: 복잡한 시스템 변경 (병렬)
```
요청 → 영향 분석 → Spec 병렬 작업 → 통합 → 검증
```
- spec-impact.sh: 영향도 분석 → 하위 JOB 분할
- delegate_task: 병렬 실행
- flock: spec-status 동시 변경 충돌 방지

### S5: Legacy 코드 Migration
```
코드 분석 → Spec 역작성 → 점진적 교체 → 검증 → 완료
```
- 기존 코드에서 Spec 추출
- 점진적 코드 변경
- spec-conformance.sh: conformance score 계산

---

## 연계 체크포인트

| Hermes 단계 | Spec 연동 | 스크립트 |
|-------------|-----------|----------|
| 1-요청 | request.md에 Spec 참조 | spec-create.sh |
| 2-조사 | 준수도 확인 | spec-conformance.sh |
| 3-설계 | Spec 연동 테이블 | architecture.md |
| 4-리뷰 | Spec 검증 결과 | architecture-review |
| 5-승인 | 상태 갱신 | spec-status.sh → approved |
| 6-실행 | Git 브랜치 + annotation | feature/SPEC-XXX |
| 7-테스트 | Conformance Score | spec-conformance.sh --run-tests |
| 8-리뷰 | Spec 준수도 검증 | exec-review |
| 9-교훈 | Matrix 동기화 | spec-sync.sh |

---

## 조건부 검증 패턴 (spec-free JOB 영향 제로)

```bash
# workflow-gate.sh에서 사용
if has_spec_references "$JOB_DIR"; then
    # Spec 체크포인트 검증
else
    echo "SKIP: spec-free JOB — 검증 생략"
fi
```

---

## graceful degradation 패턴

```bash
# pytest 부재 시
if command -v pytest &> /dev/null; then
    pytest --run-tests
else
    echo "  ⚠️ pytest not found, skipping test execution"
    SCORE=0
fi

# cascade 실패 시
bash spec-cascade.sh "$SLUG" "$SPEC_ID" "$STATUS" 2>&1 || {
    echo "  ⚠️  Cascade 실행 실패 (graceful degradation)"
}
```

---

## Blackboard 연동 패턴

```json
// ~/.shared/knowledge/specs/JOB-XXXX-spec-status.json
{
  "jobId": "JOB-XXXX",
  "specId": "SPEC-A001",
  "specRefs": ["SPEC-A001", "SPEC-B001"],
  "specChanges": {
    "SPEC-A001": {"from": "proposed", "to": "approved"}
  },
  "timestamp": "ISO8601",
  "specFile": "...",
  "changelog": "..."
}
```

---

## 설계 시 주의사항 (JOB-1500 학습)

1. **실제 파일 경로 확인**: wiki/index.md와 같이 존재하지 않는 파일을 설계에 포함 금지
2. **Blackboard 경로 검증**: ~/.shared/state/ 등 존재하지 않는 디렉토리 대신 기존 구조 활용
3. **조건부 연동**: has_spec_references() 패턴으로 spec-free JOB에 영향 없이 연동