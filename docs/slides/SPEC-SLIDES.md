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

## 4. 현재 published 슬라이드

| 강의 | 버전 | 상태 | Spec 연동 |
|:----|:----:|:----:|:---------|
| 01 — Why Agents Fail | v1.0 | ✅ Published | TEMPLATE.md, SPEC-B7 |
| 02 — Memory & Knowledge | v1.0 | ✅ Published | TEMPLATE.md, SPEC-B7 |
| 03~10 | — | ⏳ Coming Soon | — |

## 5. 게이트
- `docs/slides/`의 슬라이드는 `python3 tests/validate-course.py` 통과 필수
- 검증 실패 시 deploy.sh 차단

## 6. playground와의 차이
- **Published**: 안정적인 템플릿, 검증 완료된 내용, 보수적 CSS
- **Playground**: 실험적 템플릿/컴포넌트, WIP 내용, 독립적 진화
- 두 버전은 TEMPLATE.md와 SPEC-SLIDES.md를 공유하지 않음
