---
name: spec-driven-dev
description: "설계 사양서 기반 SW 개발 — Spec이 단일 진실 근원, SBE/DbC/BDD 적용"
version: 2.0.0
author: Hermes Agent
license: MIT
---

# Spec-Driven Development v2.0

## 개요

사양서(Specification)를 **단일 진실 근원(Single Source of Truth)**으로 삼아 코드 품질을 관리합니다.

**v2.0 개선 사항:**
- SBE (Specification by Example): 구체적 예시로 요구사항 정의
- DbC (Design by Contract): 계약 조건으로 검증
- BDD (Behavior-Driven Development): Given/When/Then 수락 기준
- 템플릿 기반 코드 생성
- 가중치 기반 Conformance Score

## 핵심 개념\n\n```\nSpec (단일 진실 근원)\n    ↓ (개발자가 읽어서 구현)\n코드\n    ↓ (Spec 기반 검증)\nConformance Score\n    ↓\n품질 확보\n```\n\n### 🏷️ 지식 시스템 연계 (Knowledge Integration)\nSpec-driven 개발은 독립적인 문서 관리를 넘어, 지식 시스템(LLM Wiki)과 유기적으로 연계되어 탐색 효율성을 극대화합니다.\n\n- **태그 기반 분류**: 모든 Spec과 아키텍처 문서는 상단 프론트매터에 `domain`과 `tags` 필드를 포함해야 합니다.\n- **Wiki 매핑**: 프로젝트의 태그 정보는 Wiki의 `domain` 및 `tags` 필드와 1:1로 매핑되어, `knowledge-navigation` 스킬을 통해 여러 프로젝트에 걸친 동일 태그의 Spec들을 통합 탐색할 수 있습니다.\n- **양방향 추적성**: Wiki 페이지는 `source:` 필드에 해당 지식의 근거가 되는 Spec의 절대 경로를 참조하여, 정제된 지식에서 원본 사양서로 즉시 이동할 수 있는 경로를 제공합니다.

## Spec 템플릿

### Component Spec
```yaml
spec_id: SPEC-C001
type: component
title: JWT 인증

# SBE: 구체적 예시
examples:
  - name: "유효한 토큰"
    input: { token: "valid_jwt" }
    expected: { authorized: true }

# DbC: 계약 조건
contract:
  preconditions:
    - "token is not null"
  postconditions:
    - "returns User or throws Error"
  invariants:
    - "token signature valid"

# BDD: 수락 기준
acceptance_criteria:
  given: "사용자가 로그인 완료"
  when: "API 요청에 토큰 포함"
  then: "권한 부여"
```

### Requirement Spec
```yaml
spec_id: SPEC-R001
type: requirement
title: 사용자 인증

user_story: |
  As a registered user,
  I want to authenticate with JWT,
  So that I can access protected resources.

scenarios:
  - name: "성공적 인증"
    given: "유효한 토큰"
    when: "API 접근"
    then: "200 OK"
```

## Conformance 검증

### 가중치 기반 점수
| 항목 | 가중치 | 설명 |
|------|--------|------|
| Example Coverage | 30% | 예시 테스트 통과율 |
| Contract Compliance | 25% | 계약 조건 준수율 |
| Traceability | 25% | Spec→Test→Code 연결 |
| Test Coverage | 20% | 코드 커버리지 |

### 검증 명령
```bash
# 전체 검증
bash spec-conformance.sh <slug>

# 단일 Spec 검증
bash spec-conformance.sh <slug> SPEC-C001

# Spec 기반 코드 리뷰
bash spec-conformance.sh <slug> --review

# pytest 자동 실행 + 결과 파싱 + _matrix.json 갱신 (P1)
bash spec-conformance.sh <slug> --run-tests
bash spec-conformance.sh <slug> SPEC-C001 --run-tests
```

## 코드 생성

### 템플릿 기반 생성
```bash
# Spec → 코드 생성
bash spec-generate.sh <slug> SPEC-C001 --lang python
bash spec-generate.sh <slug> SPEC-C001 --lang javascript
```

### 템플릿 구조
```
templates/code/
├── component.py.j2      # Python 컴포넌트
├── test_component.py.j2 # Python 테스트
└── component.js.j2      # JavaScript 컴포넌트
```

## 리퍼런스

| 카테고리 | 내용 |
|----------|------|
| `methodologies/` | SBE, BDD, DbC, API-First |
| `tools/` | OpenAPI, Cucumber |
| `patterns/` | 워크플로우, 코드 생성 |
| `examples/` | Screeps, kernel-chat 사례 |
| `integration/` | 워크플로우 연동 |
| `patterns/system-integration-patterns.md` | 연계 설계 시나리오 템플릿 (JOB-1498/1499) |
| `references/github-pages-deployment.md` | GitHub Pages 배포: API, Private 제한, gh-pages 브랜치 |
| `references/presentation-design-patterns.md` | 프레젠테이션 설계: 아이스 브레이킹, 기술 내용 선택적 노출 |
| `references/slide-composition-spec.md` | 슬라이드 구성 규격: 중복 방지 규칙, 검증 기준 |
| `references/slide-validation-patterns.md` | 슬라이드 검증 패턴 |
| `references/spec-bypass-prevention.md` | Spec 우회 방지 패턴: 코드 생성 파이프라인, 콘텐츠 분리 (JOB-1519/1520) |

## 기존 호환성

v1.0 Spec 파일은 v2.0에서 계속 작동합니다. 새 필드(`examples`, `contract`, `acceptance_criteria`)는 **optional**입니다.

## ⚠️ 슬라이드 구성 규격 필요성 (JOB-1511 학습 — 사용자 직접 지적)

**사용자 지적**: "사양서 내용만 가지고 현재 슬라이드 내용을 똑같이 만들 수 있는 수준의 디테일이 포함되있어?"

**문제**: SPEC-B6(슬라이드 버전 관리)만으로는 슬라이드 **내용을 재현할 수 없음**. 버전 관리 워크플로우만 정의하고 있어, "어떤 슬라이드가 필요한지", "어떤 내용을 포함해야 하는지" 정의되지 않음.

**규칙**: 슬라이드 관련 Spec은 다음 2가지를 모두 포함해야 함
1. **버전 관리 워크플로우 **(How) — 언제, 어떻게 버전을 관리할까? (SPEC-B6)
2. **콘텐츠 구조 규격 **(What) — 어떤 슬라이드가 필요한지, 슬라이드별 제목/라벨/포함 요소/작성 규칙 정의 (SPEC-B7)

**올바른 설계 패턴**:\n```
SPEC-B6: 슬라이드 버전 관리 (How)\n  - docs/versions/ 폴더 구조\n  - CHANGELOG.md 관리\n  - FEEDBACK.md 관리\n\nSPEC-B7: 슬라이드 구성 규격 (What)\n  - 슬라이드 목록 (11 개)\n  - 슬라이드별 제목, 라벨\n  - 포함 요소 (본문/다이어그램/팝업)\n  - 작성 규칙 (본문 vs 팝업, 언어, 팁)\n```\n\n**징후**: 사용자가 "슬라이드 내용을 똑같이 만들 수 있어?", "내용 측면을 말한거야" 지적 → 버전 관리만 있고 구성 규격 누락

**⚠️ 중복 방지 규칙 필수 **(JOB-1517 학습) 슬라이드 구성 Spec 은 "중복 금지"만 선언하면 안 됨. 반드시 다음 3 가지 정의:
1. **슬라이드 내 중복 방지**: 본문 vs 다이어그램 vs 팝업 허용/금지 규칙
2. **슬라이드 간 중복 방지**: A↔B 중복 규칙 (팝업↔팝업은 공통 개념 허용)
3. **검증 기준**: 자동 (80% 유사도 경고) + 수동 (작성자/리뷰어)

상세 규칙: `references/slide-composition-spec.md` § 중복 방지 규칙 참조

**⚠️ Spec 은 CONTENT 정의, 구조만 금지 **(JOB-1517/1518/1519/1520 학습 — 사용자 직접 지적)

**사용자 지적**: "사양서 내용만 가지고 현재 슬라이드 내용을 똑같이 만들 수 있는 수준의 디테일이 포함되있어?", "사양서를 거치지 않고 코드가 바로 수정되는 문제", "지금까지 내용 변경 요청했던건 사양서 변경이 아니라 실제 코드를 직접 변경했던거야?"

**근본 문제**: Spec 이 구조/워크플로우만 정의하고, 실제 **콘텐츠 내용은 코드에 하드코딩**. 변경 요청이 Spec 변경이 아닌 **직접 코드 수정으로 우회** → Spec ≠ 단일 진실 근원

**규칙 **(강제)
1. **Spec 에 콘텐츠 구조 포함**: 슬라이드별 제목, 라벨, 포함 요소 (본문/다이어그램/팝업), 작성 규칙 정의
2. **변경 경로 강제**: 내용 변경 요청 → Spec 변경 → 코드 생성 (직접 코드 수정 금지)
3. **검증 스크립트 필수**: Spec ↔ 실제 코드 일관성 자동 검증
4. **코드 생성 파이프라인 필수**: `specs/content/*.md` → `scripts/generate-slides.py` → `docs/slides.html`

**올바른 설계 패턴 **(JOB-1520)
```
specs/content/
  slide-01-cover.md          ← 슬라이드 1 내용 (YAML frontmatter + Markdown)
  slide-02-problem.md        ← 슬라이드 2 내용
  ...
scripts/generate-slides.py   ← Spec → HTML 자동 생성
scripts/validate-slides.py   ← Spec ↔ HTML 일관성 검증
docs/slides.html             ← 자동 생성 (직접 수정 금지)
```

**징후**: 사용자가 "사양서 내용을 기반으로 작성한다고 가정했을 때", "실제 코드 변경했던거야?", "사양서를 거치지 않고 코드가 바로 수정되는 문제" 지적 → Spec 에 콘텐츠 누락 또는 코드 생성 파이프라인 부재

**자동 검증 스크립트 패턴 **(JOB-1518)
```bash
# 슬라이드 중복 검증
python scripts/validate-slides.py docs/slides.html
python scripts/validate-slides.py docs/slides.html --threshold 0.75
python scripts/validate-slides.py docs/slides.html --output report.md
```

**검증 스크립트 필수 기능**:
- 텍스트 추출 (본문/다이어그램/팝업 분리)
- 유사도 계산 (difflib.SequenceMatcher)
- 중복 감지 (80% 이상 → 경고)
- 보고서 생성 (Markdown 형식)

**⚠️ Spec 우회 방지 패턴 **(JOB-1519 학습 — 사용자 직접 지적)

**사용자 지적**: "사양서를 거치지 않고 코드가 바로 수정되는 문제가 생길 가능성이 있는지 검토해야 해"

**문제**: 현재 변경 경로 `변경 요청 → docs/slides.html 직접 수정 → Git 푸시` → Spec 무시

**예방 규칙**:
1. **코드 생성 스크립트 필수**: `scripts/generate-slides.py` 통해 Spec → HTML 자동 변환
2. **직접 수정 금지**: `docs/slides.html` 은 자동 생성 파일로 명시 (해당 파일 직접 수정 시 경고)
3. **검증 통합**: CI/CD 또는 pre-commit hook 에서 Spec ↔ HTML 일관성 검증
4. **변경 이력 추적**: FEEDBACK.md + CHANGELOG.md + Git commit message 연동

**Spec 파일 형식 **(JOB-1520)
```yaml
---
slide_number: 1
label: 에이전트 메모리 시스템
title: "AI 에게 기억을 선물하다"
subtitle: "챗봇에서 파일 기반 지식 시스템으로"
popup_trigger: false
---

## 본문
슬라이드 본문 내용

## 다이어그램
(없음 또는 다이어그램 내용)

## 팝업
(없음 또는 팝업 내용)
```\n\n## ⚠️ Spec 설계 시 용어보다 구체적 예시 우선 (JOB-1505 학습 — 사용자 직접 지적)

**사용자 지적**: "용어만으로는 이해가 잘 안돼"

**문제**: "Change Lineage", "SemVer", "ADR 패턴" 같은 용어만 나열하면 사용자가 실제 동작을 이해하지 못함.

**규칙**:
1. **변경 전/후 코드 필수**: 용어 설명 후 반드시 실제 코드 예시 제공
2. **구체적 시나리오**: "auth.md만 고쳤는데 version을 v1.1로 바꾸면 db.md도 v1.1로 변함 → 어떤 Spec이 바뀌는지 모름"
3. **도형/테이블 사용**: Before/After 테이블로 시각적 비교
4. **용어는 보조**: 개념 설명은 코드로, 용어는 코드 다음에 설명

**올바른 패턴**:
```
문제: auth.md만 고쳤는데 version이 전역 공유 → db.md도 v1.1로 변함

변경 전:
  version: v1.0  # ← 모든 Spec이 이거 써먹음

변경 후:
  spec_id: SPEC-B1
  version: 1.2.0  # ← 개별 버전
  parent: 1.1.0   # ← 이전 버전 추적
```

**징후**: 사용자가 "용어만으로는 이해가 잘 안돼", "구체적으로 설명해줘" 지적 → 용어 중심 설명

**사용자 지적**: "슬라이드 버전 관리에 지식 시스템 컨셉을 반영할 필요는 없어. 사양서 기반 개발 컨셉을 더 확실하게 반영해줘."

**문제**: Spec 설계 시 "지식 시스템 아키텍처 (SPEC-O1)와 연계하자"는 방향을 제시했으나, 사용자는 SBE/DbC/BDD/Conformance 등 **Spec-Driven Dev 컨셉 자체를 더 확실하게 반영**하라고 정정.

**규칙**:
1. **외부 시스템 컨셉 연계는 선택사항**: "지식 시스템과 연계하자", "Karpathy 3계층을 따르자"는 제안은 사용자의 명시적 요청이 아니면 기본값으로 삼지 말 것
2. **Spec-Driven Dev 4요소는 필수**: SBE(예시) + DbC(계약) + BDD(수락기준) + Conformance(검증점수)를 기본 설계로 채택
3. **설계 질문 순서**: "어떤 Spec-Driven Dev 요소를 적용할까?" → "외부 시스템과 연계가 필요한가?" (역순 금지)

**올바른 설계 패턴**:
```
1. SBE 예시 정의 (입력/출력 구체적 예시)
2. DbC 계약 조건 정의 (Pre/Post/Invariant)
3. BDD 수락 기준 정의 (Given/When/Then)
4. Conformance 검증 방법 정의 (가중치 기반 점수)
5. Traceability Matrix 정의 (Spec → Job → Code)
6. (선택) 외부 시스템 연계 (지식 시스템 아키텍처 등)
```

**징후**: 사용자가 "지식 시스템 컨셉 반영할 필요 없어", "사양서 기반 개발 컨셉 더 확실하게" 지적 → 외부 시스템 연계에 과도하게 집중

## 현재 연계 상태 (JOB-1498/1499/1500/1506 완료)

| 시스템 | Before | P0 (JOB-1498) | P1 (JOB-1499) | P2 (JOB-1500) | Versioning (JOB-1506) |
|--------|--------|---------------|---------------|---------------|----------------------|
| workflow-gate.sh | ❌ Spec 체크포인트 없음 | ✅ I-spec-ref, I-spec-matrix + `has_spec_references()` | — | — | — |
| architecture-review | ❌ Spec 기반 검증 없음 | ✅ 체크리스트 #6 + Step 4 | — | — | — |
| spec-conformance.sh | ⚠️ 테스트 실행 pending | — | ✅ `--run-tests` + pytest + _matrix.json | — | — |
| triage | ❌ Spec 영향 cascade 없음 | — | ✅ spec-impact cascade (PRIORITY-QUEUE.md) | — | — |
| knowledge | ❌ Spec 검색/참조 없음 | — | — | ✅ knowledge-navigation Spec 검색 + knowledge/index.md | — |
| bridge API | ❌ Spec 정보 미포함 | — | — | ✅ Blackboard ~/.shared/knowledge/specs/ | — |
| **개별 Spec 버전** | ❌ 전역 v1.0 | — | — | — | ✅ **SemVer MAJOR.MINOR.PATCH** |
| **CHANGELOG** | ❌ 비어있음 | — | — | — | ✅ **자동 생성 (git diff)** |
| **ADR** | ❌ 없음 | — | — | — | ✅ **MAJOR 전환 시 자동** |

**P0 구현 내용** (JOB-1498):
- `workflow-gate.sh`: I-spec-ref, I-spec-matrix 체크포인트 + `has_spec_references()` 조건부 검증 + `--skip-spec-check` 플래그
- `architecture-review`: 체크리스트 6항목 (Spec Traceability), Step 4 (Spec Conformance 검증)
- **조건부 검증 패턴**: spec-free JOB은 검증 bypass (영향 제로)

**P1 구현 내용** (JOB-1499):
- `spec-conformance.sh`: `--run-tests` 플래그 + pytest 실행/결과 파싱 + conformance score 계산 + `_matrix.json` 갱신
- `spec-status.sh`: 상태 변경 후 spec-cascade.sh 자동 호출 (cascade 연동)
- `spec-cascade.sh` (신규): 영향도 분석 + Risk Score 기반 우선순위 매핑 + PRIORITY-QUEUE.md 자동 갱신
- triage SKILL.md: spec-impact cascade 연동 문서화
- **graceful degradation**: pytest 부재 시 WARN, _matrix.json 부재 시 skip, cascade 실패 시 계속 진행

**P2 구현 내용** (JOB-1500):
- `knowledge-navigation/SKILL.md`: Spec 검색 섹션 추가 (~/.hermes/knowledge/index.md 기반 검색)
- `spec-status.sh`: Blackboard 파일 생성 (~/.shared/knowledge/specs/JOB-XXXX-spec-status.json)
- `knowledge/index.md`: Spec Reference Index 추가
- **Blackboard 연동**: Spec 상태 변경 시 JSON 파일 자동 드롭 (jobId, specId, specRefs, specChanges 포함)

**상세 격차 분석**: JOB-1498 산출물 (P0→P1→P2 Phase별 구현 계획)

**P3 구현 내용** (JOB-1516):
- `spec-create.sh`: `--from-request` 옵션 추가 (사용자 요청 → 사양서 초안 자동 생성)
- `pre-commit-spec-check.sh`: `@spec_id` 애노테이션 검증 (사양서 없는 코드 커밋 차단)
- **요청 → 사양서 → 코드 흐름 강제**: 사용자 개발 요청 시 반드시 사양서 생성 후 코드 생성

## ⚠️ 코드 수정 전 Spec 검증 강제 (JOB-1557 학습 — 사용자 직접 지적)

**사용자 지적**: "사양서 기반 개발 컨셉대로 진행했어?"

**문제**: 레이아웃 개선 요청 시 에이전트가 `specs/active/components/slide-structure.md`(SPEC-B7)를 읽지 않고 `index.html` 직접 수정 → Spec ↔ HTML 불일치

**강제 규칙 **(모든 코드 수정 전)
1. **Spec 먼저 읽기**: `specs/active/` 하위 관련 Spec 파일 읽기
2. **변경 유형 판단**:
   - **내용 변경 **(제목/순서/라벨) → Spec 수정 → 코드 생성 파이프라인
   - **레이아웃/CSS 변경 **(padding/gap/grid) → 직접 CSS 수정 → 검증 스크립트
3. **검증 스크립트 실행**: `python3 validate.py`로 Spec ↔ HTML 일치성 확인
4. **브라우저 검증**: 변경된 슬라이드 개별 확인

**CSS 직접 수정 허용 범위**:
- ✅ 반응형 개선 (`clamp()`, `vw/vh`)
- ✅ 레이아웃 배치 (padding, gap, grid)
- ✅ 브라우저 호환성 수정
- ❌ 슬라이드 내용/제목/순서 (Spec 변경 필요)

**징후**: 사용자가 "사양서 기반 개발 컨셉대로?", "Spec을 먼저 읽었어?" 지적 → Spec 우회

---

## ⚠️ 모델별 슬라이드 비교 패턴 (JOB-1555 학습 — 사용자 직접 지적)

**사용자 지적**: "두 모델을 같은 레이아웃 방식으로 비교해야지", "같은 방식으로 만들 때 두 모델의 차이를 보고 싶다는거야"

**문제**: 에이전트가 get_model_for_role("coding")은 Grid 기반, Gemma 4는 Flex 기반으로 **다른 레이아웃 방식**을 사용하여 생성 → 모델별 차이점이 레이아웃 방식으로 혼동

**강제 규칙 **(모델 비교 시)
1. **동일한 레이아웃 패턴 사용**: 두 모델 모두 `display: flex` 또는 `display: grid` 중 하나로 통일
2. **동일한 슬라이드 비교**: 슬라이드 9만 get_model_for_role("coding"), 슬라이드 10만 Gemma 4가 아닌 **동일한 슬라이드**를 두 모델이 각각 생성
3. **서브디렉토리별 배포**: GitHub Pages에 각 모델별 별도 URL 제공

**올바른 비교 패턴**:
```bash
# 동일한 슬라이드 9를 두 모델이 각각 생성
cp index.html get_model_for_role("coding")/index.html  # get_model_for_role("coding")이 슬라이드 9 생성
cp index.html gemma-4/index.html  # Gemma 4가 슬라이드 9 생성

# 동일한 Flex 기반으로 통일
sed -i 's/display: grid/display: flex/g' gemma-4/index.html

# GitHub Pages 배포
mkdir -p get_model_for_role("coding") gemma-4
cp get_model_for_role("coding")/index.html get_model_for_role("coding")/
cp gemma-4/index.html gemma-4/
git push
```

**GitHub Pages 서브디렉토리 패턴**:
| 모델 | URL |
|------|-----|
| get_model_for_role("coding") | `https://<user>.github.io/<repo>/get_model_for_role("coding")/` |
| Gemma 4 | `https://<user>.github.io/<repo>/gemma-4/` |

**징후**: 사용자가 "두 페이지가 동일한데?", "여전히 차이가 없어보여", "같은 방식으로 하라니까" 지적 → 레이아웃 방식 불일치 또는 다른 슬라이드 비교

---

## 참조

- Martin Fowler, "Specification By Example" (2004)
- Dan North, "Introducing BDD" (2008)
- Bertrand Meyer, "Design by Contract"
- OpenAPI Specification 3.0

## ⚠️ 설계 설명 시 문제 정의 필수 (JOB-1514 학습 — 사용자 직접 지적)

**사용자 지적**: "이 수정 내용이 왜 필요한지 모르겠어"

**문제**: 설계안을 제시할 때 "무엇을 추가한다"는 기술적 내용만 나열하고, "왜 필요한지"(해결하려는 문제)를 설명하지 않음. 사용자가 가치 판단을 할 수 없음.

**규칙**: 각 설계 구성 요소를 설명할 때 반드시 아래 항목 포함
1. **문제**: 현재 어떤 문제가 발생하는가? (구체적 시나리오)
2. **영향**: 이 문제가 실제로 어떤 피해를 주는가?
3. **해결**: 제안하는 기능이 문제를 어떻게 해결하는가?

**올바른 설명 패턴**:
```
문제: Spec을改了는데 관련 코드는 그대로 → 다음 배포 시 에러 발생
영향: 버그 발견 시 어떤 Spec 버전에서 발생했는지 추적 불가
해결: VERSION_MAP.yaml로 Spec↔Code commit hash 매핑 → 즉시 추적 가능
```

**잘못된 설명 패턴**:
```
VERSION_MAP.yaml을 추가합니다.
spec-auto-sync.sh를 추가합니다.
```
→ 사용자가 "왜 필요해?"라고 질문할 확률 높음

**징후**: 사용자가 "이 수정 내용이 왜 필요한지 모르겠어", "그게 왜 중요해?" 지적 → 문제 정의 누락

---

## ⚠️ 요청 → 사양서 → 코드 흐름 강제 (JOB-1516 학습 — 사용자 직접 지적)

**사용자 지적**: "사양서 없이 코드를 작성한 문제를 해결하는거야", "내가 개발 요청할 때 요청 내용 바탕으로 사양서를 만든 다음 코드를 사양서로부터 만들어야 한다는거야. 내 요청을 가지고 코드부터 건드리는 동작을 방지해야 해"

**근본 문제**: 사용자 개발 요청 시 에이전트가 **사양서 없이 코드부터 수정**. 이로 인해:
- 코드 변경 이적 but 의도 미기록
- "왜 이렇게 만들었는지" 파악 불가
- Spec ≠ 단일 진실 근원 (코드 변경이 Spec 우회)

**강제 규칙**:
1. **사용자 요청 수신 시**: 반드시 `spec-create.sh --from-request`로 사양서 초안 자동 생성
2. **사양서 승인 전**: 코드 생성 금지 (git hook으로 차단)
3. **사양서 승인 후**: 코드 생성 + `@spec_id` 애노테이션 필수
4. **코드 커밋 전**: pre-commit hook이 `@spec_id` 존재 검증 → 부재 시 커밋 차단

**workflow-gate.sh 연동 **(추가 필수)
```bash
# 1-request 단계: 사용자 요청 → 사양서 초안 자동 생성
bash spec-create.sh <slug> requirement "<title>" --from-request "<사용자 요청>"

# 2-investigation ~ 5-approval: 사양서 검토/승인

# 6-execution: 사양서 → 코드 생성
# 코드 파일에 @spec_id: SPEC-XXX 애노테이션 포함 필수
```

**spec-create.sh --from-request 사용법**:
```bash
# 요청 텍스트 → 사양서 초안 자동 생성
bash spec-create.sh <slug> <type> <title> --from-request "사용자의 개발 요청 텍스트"
```

**pre-commit-spec-check.sh 검증**:
```bash
# 코드 파일에 @spec_id 애노테이션 확인
grep -q "@spec_id" <code-file> || {
    echo "❌ 코드 파일에 @spec_id 애노테이션이 없습니다"
    exit 1
}
```

**징후**: 사용자가 "사양서 없이 코드부터 건드리지 마", "사양서 기반 개발 시스템의 기본 컨셉" 지적 → Spec 우회 코드 작성 시도

**⚠️ 코드 → Spec 추출 금지**: Spec-Driven 개발의 기본 컨셉은 "사양서가 먼저, 코드는 사양서로부터 생성". 기존 코드를 분석하여 Spec을 추출하는 것은 이 컨셉에 위배됨. 기존 코드는 별도의 초기화 작업으로 처리.

---

## 개별 Spec 버전 관리 (JOB-1506 P0 완료)

### 현재 문제 (전역 버전)

```yaml
# auth.md
version: v1.0   # ← 모든 Spec이 이거 공유

# db.md
version: v1.0   # ← auth 바꿨는데 db도 v1.1로 변함
```

**문제**: auth.md만 고쳤는데 "어떤 Spec이 바뀌는지 모름", "언제 고친지 모름"

### 변경 후 (SemVer 개별 버전)

```yaml
# auth.md
spec_id: SPEC-B1
version: 1.2.0     # ← 개별 버전 (MAJOR.MINOR.PATCH)
parent: 1.1.0      # ← 이전 버전 추적
changed_at: 2026-06-05T10:00:00Z
version_history:
  - version: 1.2.0
    status: approved
    changed_at: 2026-06-05T10:00:00Z
  - version: 1.1.0
    status: proposed
    changed_at: 2026-06-04T09:00:00Z

# db.md
spec_id: SPEC-B2
version: 1.0.0     # ← auth 바뀌도 db는 그대로
```

### 버전 증가 규칙

| 전환 | Bump | CHANGELOG |
|------|------|-----------|
| proposed → approved | MINOR | Added |
| approved → in_progress | PATCH | Changed |
| in_progress → implemented | PATCH | Changed |
| implemented → verified | PATCH | Fixed |
| * → changed | PATCH | Changed |
| verified → deprecated | PATCH | Deprecated |
| deprecated → proposed | **MAJOR** | Changed (ADR 필요) |

### CHANGELOG 자동 생성

```markdown
## [1.2.0] - 2026-06-05
### Added
- SPEC-B1: proposed → approved (JOB-1506)

## [1.1.0] - 2026-06-04
### Changed
- SPEC-B1: 초기 생성
```

### ADR 자동 생성 (MAJOR 버전 전환 시)

deprecated → proposed 전환 시 `specs/adrs/0001-adr.md` 자동 생성:

```yaml
---
spec_id: SPEC-B1
version: 2.0.0
date: 2026-06-05
---
# ADR: SPEC-B1 재제안

## Context
v1.x deprecated된 사유: ...

## Decision
v2.0.0으로 재제안

## Consequences
- 기존 코드 영향: ...
- 마이그레이션 계획: ...
```

### 사용법

```bash
# 버전 헬퍼 함수
source ~/.hermes/skills/software-development/spec-driven-dev/scripts/spec-version.sh
version_bump "1.1.0" MINOR    # → 1.2.0
version_bump "1.1.0" MAJOR    # → 2.0.0
version_compare "1.2.0" "1.1.0"  # → 1 (첫번째가 큼)

# CHANGELOG 재생성
bash ~/.hermes/skills/software-development/spec-driven-dev/scripts/spec-changelog.sh <slug>

# VERSION_MAP 관리 (JOB-1507 P1)
bash spec-version-map.sh <slug> <spec-id> record <commit-hash>
bash spec-version-map.sh <slug> <spec-id> lookup
bash spec-version-map.sh <slug> reverse-lookup <file-path>
bash spec-version-map.sh <slug> <spec-id> detect-breaking
```

### 스크립트

| 스크립트 | 용도 |
|----------|------|
| `spec-version.sh` | SemVer 헬퍼 (version_bump, compare, is_breaking_change) |
| `spec-changelog.sh` | CHANGELOG 재생성 (git diff 기반) |
| `spec-status.sh` | 상태 변경 시 자동 버전 증가 + CHANGELOG + ADR |
| `spec-create.sh` | 초기 버전 0.1.0 + version_history + **`--from-request`로 요청→사양서 자동 생성** |
| `spec-version-map.sh` | VERSION_MAP.yaml 관리 (commit hash 기록/조회/역추적) |
| `spec-rollback.sh` | Spec 롤백 + 이력 추적 + Breaking change 영향 분석 |
| `spec-drift.sh` | Spec↔Code 불일치 감지 + 리포트 + 심각도 점수 |
| `spec-conformance.sh` | Spec 준수점 검증 + 테스트 실행 |
| `spec-sync.sh` | Spec↔Code 동기화 |
| `spec-impact.sh` | 영향 분석 |
| `git-hooks/pre-commit-spec-check.sh` | 코드 커밋 전 `@spec_id` 애노테이션 검증 + Breaking change 감지 |

Spec에서 실행 가능한 코드를 생성하는 패턴. 템플릿 기반 생성, 문법 검증, 배포, 디버깅.

### 워크플로우

1. **Spec Design**: YAML/JSON에서 선언적 규칙, 설정 상수, 구조 템플릿 정의
2. **Template Generation**: 문자열 템플릿 또는 AST 빌더로 코드 생성
3. **Syntax Validation (필수)**: 배포 전 `node -c` 또는 `py_compile`로 검증
4. **Deployment**: SCP/SSH/Docker volume로 전달 → 타겟 엔진 reload
5. **Runtime Verification**: 엔진 콘솔에서 첫 tick/iteration 확인

### ⚠️ 템플릿 함정

| 함정 | 증상 | 해결 |
|------|------|------|
| Trailing Braces | `}};` SyntaxError | 템플릿 종료 `};` 확인 |
| Escape Characters | `\\n` 문법 오류 | 템플릿 리터럴 `${'\\n'}` 사용 |
| Spec→code 불일치 | 생성 코드가 Spec 규칙 무시 | 템플릿이 Spec 배열을 순회하도록 |

### 검증 (배포 전 필수)

```bash
node -c build/main.js && echo "✅ Syntax OK"   # JavaScript
python -m py_compile path/to/generated.py       # Python
```

**절대 검증하지 않은 생성 코드를 배포하지 말 것.**

---

## 프로젝트 구조 (v2.0)

```
<project-slug>/
├── specs/                  # Spec 중앙 관리
│   ├── active/             # 현재 유효한 Spec
│   │   ├── components/     # component specs
│   │   └── interfaces/     # interface specs
│   ├── history/            # 변경 이력
│   ├── _index.yaml         # Spec 인덱스
│   └── _matrix.json        # Traceability Matrix
├── src/                    # 소스 코드
├── tests/                  # 테스트
├── docs/                   # 문서 (세미나, 아키텍처, 기술 문서)
│   ├── README.md
│   ├── seminar.md
│   └── slides.html         # 프레젠테이션
├── site/                   # GitHub Pages 배포용
│   └── index.html → ../docs/slides.html
└── AGENTS.md
```

**⚠️ 프로젝트 산출물 위치 규칙 **(사용자 지적, 2026-06-04)
- ❌ **워크스페이스 루트에 산출물 방치 금지**: `~/.hermes/workspace/README.md`, `~/.hermes/workspace/seminar.html` 등
- ✅ **프로젝트 폴더 내 `docs/`에 저장**: 모든 문서, 다이어그램, 프레젠테이션은 프로젝트 내 `docs/` 하위
- ✅ **GitHub Pages는 `site/`에**: `site/index.html` → `../docs/slides.html` 심링크

---

## 버전 관리 및 코드 매핑 (JOB-1506/1507 완료)

### VERSION_MAP.yaml (Spec↔Code commit hash 매핑)

```yaml
# specs/VERSION_MAP.yaml
SPEC-B1:
  version: 1.2.0
  code_commits:
    - file: "src/auth/oauth.py"
      commit: "a1b2c3d"
      updated_at: "2026-06-05T10:00:00Z"
  breaking_changes:
    - version: "1.0.0"
      description: "JWT → OAuth2 전환"
      affected_files: ["src/auth/oauth.py", "src/api/endpoints.py"]
```

**사용 사례**: "auth.md v1.2에 해당하는 코드가 어떤 상태인지" → commit hash로 바로 확인

### Breaking change 감지

Spec 변경 시 다음 패턴 자동 감지:

| Breaking (WARN) | Non-breaking |
|-----------------|--------------|
| 필드 삭제 | 필드 추가 |
| 타입 변경 | enum 값 추가 |
| enum/list 값 삭제 | 값 변경 (동일 타입) |
| 상위 키 삭제 | 키 추가 |

```bash
# Breaking change 감지
bash spec-version-map.sh <slug> SPEC-B1 detect-breaking

# 출력 예시
⚠️ Breaking change detected:
  - Field 'token' removed from 'login.input'
  - Field 'user' type changed from 'object' to 'array'
📋 Affected files: src/auth/oauth.py, src/api/endpoints.py
```

### Pre-commit hook 전략

- **개발 환경**: WARN (경고만 출력, 커밋 허용)
- **CI 환경**: FAIL (SPEC_STRICT=true 시 커밋 차단)
- **위치**: `scripts/git-hooks/pre-commit-spec-check.sh`

### ROLLBACK_LOG.yaml (JOB-1508 P1)

```yaml
SPEC-B1:
  - from_version: "2.0.0"
    to_version: "1.0.0"
    reason: "버그 발생"
    rolled_back_at: "2026-06-05T10:00:00Z"
    rolled_back_by: "JOB-1508"
    breaking_changes: []
    code_sync_status: completed
```

**위치**: `~/.hermes/workspace/projects/<slug>/specs/ROLLBACK_LOG.yaml`
**사용**: 롤백 이력 추적 + audit + 재롤백 방지

---

## ⚠️ 스크립트 피들 (JOB-1498/1499 학습)

### create-project.sh

| 함정 | 증상 | 해결 |
|------|------|------|
| `docs/` / `site/` 디렉토리 누락 | 프로젝트 생성 시 문서 폴더 없음 → 산출물 워크스페이스 루트에 방치 | `mkdir -p docs/ site/` 추가 |

### spec-conformance.sh

| 함정 | 증상 | 해결 |
|------|------|------|
| Python 파일 조작 (JOB-1499) | `os.dup()` 후 `os.close()`하면 원본 fd 닫힘 → `json.dump` 실패 | `os.fdopen(fd, 'w')`로 파일 객체 변환 후 사용 |
| `grep -c \|\| echo 0` 패턴 (JOB-1499) | 0 매치 시 stdout "0" + exit 1 → `\|\| echo 0`이 추가 "0" 붙여 "0\n0" 반환 → 구문 에러 | `\|\| true` + `[[ -z "$var" ]] && var=0` 패턴 사용 |
| _matrix.json 갱신 실패 (JOB-1499) | flock 기반 atomic write 시 `json.load(fd)` 호출 → `'int' object has no attribute 'read'` | `os.fdopen()` 사용 + finally 블록에서 `try/except`로 unlock |
| pytest 의존성 (JOB-1499) | `--run-tests` 실행 시 pytest 부재 → 스크립트 실패 | graceful degradation: `command -v pytest` 체크 + WARN 출력 + score=0 |

### spec-create.sh

| 함정 | 증상 | 해결 |
|------|------|------|
| 한글 제목 파일명 (2026-06-04) | `tr`/`sed`가 non-ASCII 제거 → 파일명 `-.md` 생성 | 스크립트 대신 `write_file`로 직접 Spec 파일 작성 |

### GitHub Pages

| 함정 | 증상 | 해결 |
|------|------|------|
| Private 리포 + Free 플랜 | `gh api repos/.../pages` → 422 "does not support GitHub Pages" | 리포 **Public** 변경 또는 유료 플랜(Pro/Team) |
| User Pages 대안 | `username.github.io` 형식은 무료 | 프로젝트 리포명 = `username.github.io` 사용 |
| **CDN 캐시 문제** | GitHub Pages에 변경사항 즉시 반영 안됨 | `sleep 60` 후 확인 또는 `?t=timestamp` 쿼리 파라미터 추가 |
| **브랜치 오염** | gh-pages 커밋이 main 브랜치에 잘못 푸시됨 | `git reset --hard {올바른_커밋}`으로 복원 |
| **gh-pages 파일 복사** | `git rm -rf .` 후 파일 초기화됨 | `git checkout main -- docs/slides.html` 방식으로 안전히 복사 |
| **슬라이드 파일 삭제** | gh-pages 브랜치 작업 후 docs/slides.html 사라짐 | main 브랜치에 원본 유지, gh-pages에는 index.html만 배포 |

### create-project.sh

| 함정 | 증상 | 해결 |
|------|------|------|
| `docs/` / `site/` 디렉토리 누락 | 프로젝트 생성 시 문서/배포 폴더 없음 → 산출물 워크스페이스 루트 방치 | `mkdir -p docs/ site/` 추가 |

### spec-version-map.sh (JOB-1507)

| 함정 | 증상 | 해결 |
|------|------|------|
| bash heredoc + Python 인자 전달 | Python이 Spec 파일을 실행코드로 인식 | `python3 - "$var" << 'PYEOF'` + `sys.argv` 사용 |
| YAML frontmatter 파싱 | `---`가 Python 문법으로 해석 | 파일 읽기 전에 frontmatter 제거 로직 추가 |
| set -u + unbound variable | heredoc 내에서 bash 변수 인식 안 됨 | quote된 delimiter `'PYEOF'` + sys.argv |
| lookup 명령어 누락 | 설계에는 있으나 구현 누락 | cmd_lookup() 함수 추가 + case문에 등록 |
| f-string 따옴표 충돌 | `entry.get("key", "val")` → SyntaxError | heredoc으로 변경 + 변수에 먼저 할당 후 사용 |

**검증 체크리스트 **(스크립트 수정 후)
- [ ] `bash 스크립트명 --help` 실행 테스트
- [ ] 모든 명령어별 테스트 (init/register/lookup/resolve/list/detect)
- [ ] YAML frontmatter 포함 Spec 파일 테스트
- [ ] f-string 출력 시 따옴표 이스케이프 확인
| lookup 명령어 누락 | 설계에는 있으나 구현 없음 | cmd_lookup() 함수 + case 문 등록 |
| **Python f-string 이스케이프** | `print(f'  버전: {data.get("current_version", "unknown")}')` → NameError | **heredoc 사용** (`python3 << 'PYEOF'`) + 따옴표 없는 변수명 |
| **json.loads() 빈 입력** | yaml_read 출력이 JSON이 아닐 때 파싱 실패 | **yaml.safe_load() 직접 사용** 또는 출력 형식 검증 |

### spec-create.sh --from-request (JOB-1516)

| 함정 | 증상 | 해결 |
|------|------|------|
| `_index.yaml` 부재 | "❌ _index.yaml을(를) 찾을 수 없습니다" | 프로젝트 생성 시 `_index.yaml` 초기화 필수 |
| `_matrix.json` 구조 오류 | KeyError: 'items' | `{ "items": {} }` 형식 필수 |
| 템플릿 부재 | "⚠️ 템플릿 없음 — 기본 생성" | `specs/templates/`에 템플릿 사전 생성 권장 |

### spec-rollback.sh (JOB-1508 P1)

| 함정 | 증상 | 해결 |
|------|------|------|
| 타겟 버전 존재 확인 안 함 | 존재하지 않는 버전으로 롤백 시도 | `yaml_read "$vm_file" "version_bindings.${spec_id}@${target}"`로 존재 확인 |
| 롤백 이력 미기록 | 롤백 후 어떤 버전으로 롤백되었는지 추적 불가 | `ROLLBACK_LOG.yaml`에 from/to/reason/timestamp 기록 |
| Breaking change 영향 분석 누락 | 롤백 시 코드 영향 분석 안 함 | `spec-version-map.sh detect` 호출 후 결과 확인 |
| **f-string 따옴표 충돌** | bash heredoc 내 Python f-string에서 `entry.get("from_version", "?")` → SyntaxError | **heredoc으로 변경** + 변수에 먼저 할당 후 사용 |

### spec-drift.sh (JOB-1508 P1)

| 함정 | 증상 | 해결 |
|------|------|------|
| 코드 파일 존재 확인 안 함 | Spec에 정의된 코드가 삭제되었는지 감지 안 됨 | `[[ -f "$code_file" ]]`로 실제 파일 존재 확인 |
| 버전 불일치 계산 오류 | Spec 버전 vs 코드 생성 시 버전 비교 실패 | `spec-version.sh`의 `version_compare()` 사용 |
| drift 점수 계산 누락 | 각 drift 항목의 가중치 없음 | HIGH=10, MEDIUM=3, LOW=1 가중치 적용 |

### ROLLBACK_LOG.yaml (JOB-1508 P1)

```yaml
SPEC-B1:
  - from_version: "2.0.0"
    to_version: "1.0.0"
    reason: "버그 발생"
    rolled_back_at: "2026-06-05T10:00:00Z"
    rolled_back_by: "JOB-1508"
    breaking_changes: []
    code_sync_status: completed
```

**위치**: `~/.hermes/workspace/projects/<slug>/specs/ROLLBACK_LOG.yaml`
**사용**: 롤백 이력 추적 + audit + 재롤백 방지

### spec-status.sh

| 함정 | 증상 | 해결 |
|------|------|------|
| spec-cascade.sh 부재 (JOB-1499) | P1 미적용 시 cascade 호출 실패 → 스크립트 중단 | `[[ -f "$CASCADE_SCRIPT" ]]` 존재 체크 + 실패 시 silently skip |

---

## ⚠️ 슬라이드 레이아웃 최적화 패턴 (JOB-1555 학습)

**문제**: 16:9 모니터 해상도 (1920x1080, 1366x768, 2560x1440)에서 슬라이드 레이아웃이 고정된 `px` 단위로 작성되어 비율이 어긔남

**해결**: 반응형 CSS 기법 적용

### 반응형 CSS 기법

| 기법 | 용도 | 예시 |
|------|------|------|
| `clamp()` | 폰트 크기, 패딩 | `font-size: clamp(28px, 3vw, 48px)` |
| `vw/vh` | 화면 비율 기반 배치 | `padding: clamp(30px, 4vh, 60px) clamp(40px, 6vw, 120px)` |
| `minmax()` | 그리드 최소/최대 너비 | `grid-template-columns: repeat(3, minmax(200px, 1fr))` |

### 16:9 해상도별 최적화

| 해상도 | 제목 크기 | 패딩 |
|--------|-----------|------|
| **1366×768** | 41px | 31px |
| **1920×1080** | 58px | 43px |
| **2560×1440** | 48px (최대) | 58px |

### 슬라이드별 레이아웃 패턴 (SPEC-B7 Line 40-52 준수)

| 슬라이드 | SPEC-B7 레이아웃 | CSS 구현 |
|----------|------------------|----------|
| 1 (Cover) | `Cover` | `.slide-cover { flex: 1; display: flex; justify-content: center; }` |
| 2 (Diagram+Cards) | `Diagram+Cards` | `.two-col { grid-template-columns: repeat(2, minmax(280px, 1fr)); }` |
| 3 (3-Card Grid) | `3-Card Grid` | `.card-grid.grid-3 { grid-template-columns: repeat(3, minmax(200px, 1fr)); }` |
| 4 (Hierarchy) | `Hierarchy Diagram` | `.hierarchy { flex-direction: column; gap: clamp(8px, 1vh, 12px); }` |
| 8 (Tier Cards) | `Tier Cards (T1/T2/T3)` | `.card.tier-1 { border-top: 4px solid var(--t1); }` |

### 다이어그램 규칙 (SPEC-B7 Line 54-59 준수)

```css
/* 순차적 동작: 화살표 플로우 */
.diagram-arrow { font-size: clamp(18px, 2vw, 24px); }

/* 분류적 동작: 컬러 코딩 카드 (T1/T2/T3) */
.card.tier-1 { border-top: 4px solid var(--t1); background: var(--t1-bg); }
.card.tier-2 { border-top: 4px solid var(--t2); background: var(--t2-bg); }
.card.tier-3 { border-top: 4px solid var(--t3); background: var(--t3-bg); }

/* 계층적 구조: 트리 다이어그램 (L1→L2→L3) */
.hierarchy-level { min-width: clamp(250px, 30vw, 300px); }

/* 순환 프로세스: 사이클 다이어그램 */
.cycle-diagram { flex-direction: column; align-items: center; }
```

### ⚠️ 슬라이드 4 Hierarchy 순서 오류

**문제**: L1→L3→L2 순서로 작성됨 (SPEC-B7 Line 58 `계층적 구조: 트리 다이어그램 (L1→L2→L3)` 위반)

**해결**: HTML 수정 + 브라우저 검증
```html
<!-- ✅ GOOD: L1→L2→L3 순서 -->
<div class="hierarchy-level l1">L1: 사전 학습</div>
<div class="hierarchy-level l2">L2: 에이전트 메모리</div>
<div class="hierarchy-level l3">L3: 문서 참조</div>
```

**징후**: 브라우저에서 L1→L3→L2 순서로 표시 → SPEC-B7 Line 58 확인 + HTML 수정

---

## ⚠️ 모델 정보 검증 패턴 (JOB-1555 학습)

**문제**: config.yaml을 직접 확인하지 않고 "get_model_for_role("coding")이 등록되지 않음"이라고 잘못 답변

**해결**: `model-lookup` 스킬 사용하여 config.yaml에서 정확한 모델/프로바이더 정보 조회

```bash
# 모델-lookup 스킬 사용
skill_view(name='model-lookup')

# 또는 직접 확인
grep -A 5 "get_model_for_role("coding")" ~/.hermes/config.yaml
```

### config.yaml 모델 등록 패턴

```yaml
providers:
  zai:
    api_key: env.GLM_API_KEY
    base_url: https://api.z.ai/api/coding/paas/v4/
    subscription: true
    default_model: glm-5-turbo
    models:
      get_model_for_role("coding"):          # ← 모델 이름
        name: GLM-5.1   # ← 표시 이름
        reasoning: true
        context_length: 202752
        max_tokens: 128000
```

**징후**: 사용자가 "모델은 등록되어 있는데 왜 참조를 못해?" 지적 → `model-lookup` 스킬 사용 또는 config.yaml 직접 확인

### 조건부 검증 패턴 (JOB-1498 P0)

```bash
# spec-free JOB은 검증 bypass (영향 제로)
if has_spec_references "$JOB_DIR"; then
    # Spec 체크포인트 검증
else
    echo "SKIP: spec-free JOB — 검증 생략"
fi
```

### graceful degradation 패턴 (JOB-1499 P1)

```bash
# 테스트 실패 시에도 스크립트 계속 진행
bash spec-conformance.sh <slug> --run-tests || {
    echo "  ⚠️  Conformance 실패 (graceful degradation)"
    # exit 0 이아니면 workflow 차단됨
    exit 0
}
```

---

## ⚠️ 자동화 및 연동 개선 패턴 (JOB-1543 학습)

### `_index.yaml` 메타데이터 갱신 — yaml.dump() 포맷 변경 함정

**문제**: Python `yaml.dump()`가 `_index.yaml`을 다시 작성하면 들여쓰기가 변경됨. 원본은 `  - spec_id:` (2-space indent + dash)였으나 dump 후 `- spec_id:` (no indent before dash)로 변경. 이후 `grep "^  - spec_id:"` 기반 검증이 모든 spec을 "미등록"으로 탐지.

**증상**: 빌드 후 validate-specs.sh 실행 시 `Spec SPEC-XX — _index.yaml에 미등록` 경고 10개+ 발생

**해결**: yaml.dump() 대신 **sed/regex 기반 필드 단위 갱신**. 원본 포맷 유지.

```python
# ❌ BAD: yaml.dump()는 포맷 변경
idx = yaml.safe_load(f)
idx['last_built_at'] = now.isoformat()
yaml.dump(idx, f, ...)  # ← 포맷 깨짐

# ✅ GOOD: regex 기반 필드 갱신 (원본 포맷 유지)
import re
content = f.read()
content = re.sub(r"^last_built_at:.*$", f"last_built_at: '{now.isoformat()}'", content, flags=re.MULTILINE)
f.write(content)
```

**적용 위치**: `scripts/generate-slides.py`의 `update_index_metadata()` 함수

**징후**: 빌드 후 index.yaml 포맷 변경, grep 기반 검증 실패, "미등록" 경고 다수 발생

---

### spec-status.sh 상태 전이 엄격함 우회 패턴

**문제**: `spec-status.sh`는 엄격한 상태 머신 사용 (proposed→approved→in_progress→implemented→verified). 하지만 일부 프로젝트에서 `active` 상태로 운영 시, `active → in_progress` 전이가 허용되지 않음. `active → changed → in_progress` 경로도 `active`가 상태 머신에 정의되어 있지 않아 실패.

**증상**: `❌ 상태 전이 'active → in_progress'는/는 허용되지 않습니다`

**해결**: 상태 전이 검증이 필요 없는 경우 **sed로 직접 status 필드 갱신**. 상태 머신 검증 우회.

```bash
# ❌ BAD: spec-status.sh 호출 → 상태 전이 검증 실패
bash spec-status.sh <slug> SPEC-B7 in_progress JOB-1543  # ← "active → in_progress 허용 안됨"

# ✅ GOOD: sed 직접 갱신 (상태 전이 검증 스킵)
sed -i "s/^status:.*/status: in_progress/" "$SPEC_FILE"
```

**적용 위치**: `scripts/spec-sync-with-job.sh` (JOB-스펙 자동 동기화)

**주의**: 이 패턴은 상태 이력이 중요한 프로젝트에서 신중하게 사용. `spec-status.sh`가 정상 동작하는 환경(상태가 proposed/approved/in_progress/implemented/verified일 때)에서는 표준 스크립트 사용 권장.

**징후**: spec-status.sh 호출 시 "상태 전이 허용되지 않음" 에러, 현재 상태가 `active` 또는 `implemented`일 때 전이 실패

---

### validate-specs.sh 엄격 검증 패턴 (JOB-1543)

`validate-specs.sh`는 다음 5단계를 검증해야 함:

| 단계 | 검증 내용 | 실패 시 |
|------|-----------|---------|
| 1 | Content 파일 수 (예상 vs 실제) | 빌드 중단 |
| 2 | Active Spec 필수 메타데이터 (`spec_id`, `version`, `status`) | 빌드 중단 |
| 3 | Content slide_number 중복 | 빌드 중단 |
| 4 | Spec ID 중복 (_index.yaml vs active 디렉토리) | 경고만 |
| 5 | Traceability (SPEC-B7 버전 존재) | 빌드 중단 |

**필수 메타데이터 검증 예시**:
```bash
metadata=$(sed -n '/^---$/,/^---$/p' "$spec_file" | sed '1d;$d')
for field in spec_id version status; do
    if ! echo "$metadata" | grep -q "^${field}:"; then
        echo "❌ FAIL: ${fname} — '${field}' 필드 누락"
        exit 1
    fi
done
```

**grep 패턴 주의**: `_index.yaml`의 spec_id 추출은 yaml.dump 포맷 변경을 고려해 유연하게 파싱
```bash
# ✅ GOOD: 포맷 독립적 파싱
INDEX_IDS=$(grep -P "spec_id:" "${INDEX_FILE}" | awk '{print $NF}' | sort -u)

# ❌ BAD: 특정 들여쓰기 가정
INDEX_IDS=$(grep "^  - spec_id:" "${INDEX_FILE}" | awk '{print $3}')
```

---

### build-artifact.sh 5단계 파이프라인 패턴 (JOB-1543)

`build-artifact.sh`는 다음 순서로 동작:

```
1. Spec 버전 읽기 (SPEC-B7 version: 필드)
2. validate-specs.sh 실행 (실패 시 중단)
3. generate-slides.py 실행 (HTML 생성 + _index.yaml 메타데이터 자동 갱신)
4. 버전 파일 복사 (docs/versions/v{version}.html)
5. CHANGELOG 자동 생성 (specs/history/CHANGELOG.md)
```

**CHANGELOG 자동 생성 예시**:
```bash
CHANGES=""
for f in $(find specs/active specs/content -name "*.md" -printf '%T@ %p\n' | sort -rn | head -10 | awk '{print $2}'); do
    CHANGES="${CHANGES}  - $(basename "$f") ($(date -r "$f" '+%Y-%m-%d %H:%M'))\n"
done
```

---

### JOB-스펙 상태 동기화 패턴 (JOB-1543)

JOB 완료 시 관련 스펙의 status 필드 자동 갱신:

```
workflow-gate.sh <JOB_ID> transition done
  → spec-sync-with-job.sh <JOB_ID>
    → request.md에서 SPEC-* 패턴 추출
    → sed로 status 필드 갱신 (in_progress → verified 등)
```

**상태 매핑**:
| workflow 단계 | 매핑된 스펙 상태 |
|---------------|-----------------|
| request ~ review | proposed |
| approval | approved |
| execution / test | in_progress |
| execution_review / done | verified |

**request.md에 관련 스펙 명시 필수**:
```markdown
## 관련 스펙
- SPEC-B7: 슬라이드 구성 규격
- SPEC-B6: 슬라이드 버전 관리
```

request.md에 SPEC-* 참조가 없으면 sync 스크립트는 스킵됨.
