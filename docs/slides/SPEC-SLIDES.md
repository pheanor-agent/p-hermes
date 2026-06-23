# SPEC-SLIDES — Published Version (v1.0)

> **마지막 업데이트**: 2026-06-23
> **상태**: Active
> **연결**: TEMPLATE.md (published), docs/slides/

---

## 1. 목적
p-hermes 강의 슬라이드의 **published (안정) 버전**을 정의합니다.
이 Spec은 GitHub Pages에 배포되는 `docs/slides/`의 슬라이드에 적용됩니다.

## 2. 버전 관리
- **v1.0**: 초기 published 슬라이드 (Lecture 01-02)
- 각 강의가 완성되어 published로 승격될 때마다 마이너 버전 증가
- TEMPLATE.md 변경 시 메이저 버전 증가

## 3. 스펙 참조
- TEMPLATE.md: `docs/slides/TEMPLATE.md` — 레이아웃/스타일 규칙
- SPEC-B7: `slide-composition-spec.md` — 슬라이드 구성 규격 (Spec-Driven Dev)
- validate-course.py: `tests/validate-course.py` — 검증 스크립트
- Content System: `pre_direction.py` (D3/golden_circle) — 방향성 분석

## 4. 예시 및 강의 노트 가이드라인

### 적용 범위 구분
| 항목 | 적용 대상 | 제한 | 목적 |
|:-----|:----------|:----:|:-----|
| max_words | visible 텍스트 (청중에게 보이는) | ≤50자 | 한눈에 읽기 |
| data-notes | 발표자 노트 (청중에게 안 보임) | 80~150자 | 발표 스크립트 |
| one_message | visible + data-notes 통합 | 슬라이드당 1개 | 메시지 집중 |

### 규칙
1. **visible 텍스트와 data-notes는 별개로 적용** — visible을 data-notes로 대체 금지, data-notes를 visible로 축소 금지
2. **예시 일반화**: 특정 하드웨어/소프트웨어명 사용 금지, 범용 명칭 사용
3. **청중 수준**: 기술 지식 mid 기준, 일반 회사원 시나리오
4. **1슬라이드 1메시지**: 중복 내용은 다른 슬라이드로 분리

### 출처
- Content System: `audience_analyzer` (mid/mid/mid), `direction_compiler` (golden_circle)
- 수동 분석: data-notes 부족 식별 (JOB-1812)

## 5. 현재 published 슬라이드

| 강의 | 버전 | 상태 | Spec 연동 |
|:----|:----:|:----:|:---------|
| 01 — Why Agents Fail | v1.0 | ✅ Published | TEMPLATE.md, SPEC-B7 |
| 02 — Memory & Knowledge | v1.0 | ✅ Published | TEMPLATE.md, SPEC-B7 |
| 03~10 | — | ⏳ Coming Soon | — |

## 6. 게이트
- `docs/slides/`의 슬라이드는 `python3 tests/validate-course.py` 통과 필수
- 검증 실패 시 deploy.sh 차단

## 7. playground와의 차이
- **Published**: 안정적인 템플릿, 검증 완료된 내용, 보수적 CSS
- **Playground**: 실험적 템플릿/컴포넌트, WIP 내용, 독립적 진화
- 두 버전은 TEMPLATE.md와 SPEC-SLIDES.md를 공유하지 않음
