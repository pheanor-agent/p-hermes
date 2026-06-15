# Workflow Integration Patterns

## Hermes 9단계 Workflow ↔ Spec 연동

| Hermes 단계 | Spec 연동 |
|-------------|-----------|
| 1-요청 | `request.md`에 Spec 참조 포함 |
| 2-조사 | `spec-conformance.sh`로 준수도 확인 |
| 3-설계 | `architecture.md`에 Spec 연동 테이블 |
| 4-리뷰 | Spec 검증 결과 포함 |
| 5-승인 | `spec-status.sh`로 상태 갱신 |
| 6-실행 | Git 브랜치명 `feature/SPEC-XXX` |
| 7-테스트 | Conformance Score 검증 |
| 8-리뷰 | Spec 준수도 검증 포함 |
| 9-교훈 | `spec-sync.sh`로 Matrix 동기화 |

## 체크포인트 ID

| 체크포인트 | 검증 항목 | 단계 |
|-----------|----------|------|
| I-spec-ref | request.md에 Spec 참조 포함 | 1-요청 |
| I-spec-matrix | architecture.md에 Spec 연동 명시 | 3-설계 |
| I-spec-review | review-result에 Spec 검증 포함 | 4-리뷰 |
| I-spec-branch | Git 브랜치명 Spec ID 포함 | 6-실행 |
| I-spec-annotation | 코드에 Spec ID annotation 포함 | 6-실행 |
| I-spec-test | 테스트에 Spec ID 태그 포함 | 7-테스트 |
| I-spec-conformance | Conformance Score 90% 이상 | 7-테스트 |
| I-spec-sync | Matrix 최종 갱신 | 9-교훈 |

## 승인 후 설계 변경 처리 (JOB-1467 학습)

**사용자 지적**: "지금 작업 프로세스대로 하고 있어? 파일이나 폴더를 그때그때 바꾸는 것 같은데"

**문제**: 승인 후 설계 변경(B-type: 범위 변경) 발생했으나 재리뷰/재승인 없이 execution 계속

**올바른 순서**:
```
1. 승인 후 설계 변경 감지 → 변경 분류 (A/B/C)
2. B-type (범위 변경) → architecture.md 갱신 (변경 이력 테이블 포함)
3. 재리뷰 수행 → review-result-N.md 생성
4. 재승인 요청 → approval.json 갱신
5. 그러면 execution 계속
```

**Before/After 테이블 포함 필수**:
```markdown
## 변경 이력

| # | 항목 | 현재 | 변경 | 사유 |
|---|------|------|------|------|
| 1 | 진입점 위치 | scripts/ | skills/ | 스킬 기반 통합 |
```

## 검증 시퀀스

```bash
# 1. 요청 단계 — Spec 참조 확인
grep -r "SPEC-" request.md
bash spec-conformance.sh <slug>

# 2. 설계 단계 — Spec 연동 명시
grep "SPEC-" architecture.md
bash spec-impact.sh <slug> <spec-id>

# 3. 승인 단계 — 상태 갱신
bash spec-status.sh <slug> <spec-id> approved

# 4. 실행 단계 — Git 브랜치 + annotation
git checkout -b feature/SPEC-XXX
# 코드에 // SPEC-XXX 또는 @spec_id("SPEC-XXX") 추가

# 5. 테스트 단계 — Conformance Score
bash spec-conformance.sh <slug> <spec-id> --run-tests
bash spec-conformance.sh <slug> <spec-id>

# 6. 교훈 단계 — Matrix 동기화
bash spec-sync.sh <slug>
```

## 승인 JSON 구조

```json
{
  "job_id": "JOB-XXXX",
  "spec_refs": ["SPEC-A001", "SPEC-A002"],
  "spec_changes": {
    "SPEC-A001": {"from": "proposed", "to": "approved"},
    "SPEC-A002": {"from": "implemented", "to": "changed"}
  }
}
```

## Spec 상태 머신

```
proposed → approved → in_progress → implemented → verified
              ↑          ↓               ↓           ↓
              └──────── changed ←──────── deprecated ←┘
```

**상태 전이 검증**:
- `proposed → approved` ✅
- `approved → in_progress` ✅
- `in_progress → implemented` ✅
- `implemented → verified` ✅
- `approved → changed` ✅ (설계 변경 시)
- `implemented → changed` ✅ (구현 중 변경 시)
- `verified → deprecated` ✅ (무효화 시)
- `deprecated → proposed` ✅ (재제안 시)
- `changed → in_progress` ✅ (변경 후 재시작 시)

## Spec ID 패턴

| 타입 | 접두사 | 예시 |
|------|--------|------|
| Requirement | A | SPEC-A001 |
| Component | B | SPEC-B001 |
| Interface | C | SPEC-C001 |
| Architecture | D | SPEC-D001 |
| External | E | SPEC-E001 |

## Traceability Matrix 구조

```json
{
  "SPEC-A001": {
    "title": "JWT 인증",
    "status": "verified",
    "code_refs": ["src/auth/oauth.py"],
    "test_refs": ["tests/test_auth.py"],
    "job_refs": ["JOB-XXXX"],
    "coverage": {
      "code_coverage_pct": 94.2,
      "test_pass_rate": 100.0,
      "conformance_score": 95.0
    }
  }
}
```

## ⚠️ 현재 연계 상태 (JOB-1498 분석 결과, 2026-06-04)

> **참고**: 아래는 "이상적" 설계가 실제 파이프라인에 통합된 상태입니다.
> **전체 격차 분석**: `references/integration/gap-analysis.md` 참조

### 현재 상태

| 시스템 | 연계 상태 | 검증 |
|--------|-----------|------|
| workflow-gate.sh | ❌ Spec 체크포인트 **미통합** | `grep "spec" workflow-gate.sh` → 0개 매치 |
| architecture-review | ❌ Spec 기반 검증 **미구현** | config 기반 검증만 수행 |
| spec-conformance.sh | ⚠️ 테스트 실행 로직 **pending** | 스크립트 존재하지만 실제 pytest 호출 없음 |
| triage | ❌ Spec 영향 cascade **미연동** | JOB 분류/상태 관리만 수행 |
| knowledge | ❌ Spec 검색/참조 **미연동** | 도메인/태그 기반 탐색만 |
| bridge API | ⚠️ **단방향** (JOB-1392) | OpenClaw→Hermes만 허용 |
| spec-status.sh | ⚠️ **flock 미구현** | 병렬 작업 시 충돌 가능 |

### 연계 강화 방향 (JOB-1498 산출물)

| Phase | 작업 | 상태 |
|-------|------|------|
| P0 | workflow-gate + spec-status 조건부 검증 | 설계 중 |
| P0 | architecture-review Spec 검증 통합 | 설계 중 |
| P1 | spec-conformance 테스트 자동화 | 설계 중 |
| P1 | triage + spec-impact cascade | 설계 중 |
| P2 | knowledge Spec 검색 | 설계 중 |
| P2 | bridge API Spec 상태 공유 | 설계 중 |

### 시나리오 기반 연계 분석 방법론

시스템 간 연계 검토 시 다음 시나리오 커버 필수:

1. **신규 기능 개발** (Happy Path): Spec 제안 → 설계 → 승인 → 구현 → 테스트 → 완료
2. **설계 변경** (B-type): 승인 후 범위 변경 → 재리뷰 → 재승인 → 구현 수정
3. **버그 수정**: 버그 발견 → Spec 영향 분석 → 수정 → Conformance 재검증
4. **복잡한 시스템 변경**: 여러 Spec/컴포넌트 영향 → impact 분석 → 병렬 작업 → 통합
5. **Legacy 코드 Migration**: 기존 코드에 Spec 부재 → Spec 역작성 → 점진적 교체

---

## Pitfalls

### 승인 후 설계 변경 무시 금지
- 승인 후 설계 변경 발생 시 반드시 재리뷰/재승인 수행
- 변경 이력 테이블 architecture.md에 명시
- 사용자가 "프로세스대로 해" 지적 → 프로세스 준수 필수

### .shared/ 사용 금지
- 프로젝트 관리 도구/템플릿은 `.shared/`에 배치 금지
- AGENTS.md에서 Blackboard 전용으로 정의
- Hermes 전용 영역: `~/.hermes/skills/`, `~/.hermes/workspace/projects/`

### 카테고리 구조 해치지 않기
- 기존 카테고리 (`software-development/`, `custom/`) 유지
- 하위 스킬명은 간결하게 (`spec-driven-dev`)
- 카테고리 평탄화 금지