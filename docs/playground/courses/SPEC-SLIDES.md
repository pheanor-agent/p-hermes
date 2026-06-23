# SPEC-SLIDES — Playground Version (WIP)

> **마지막 업데이트**: 2026-06-23
> **상태**: WIP (Work In Progress)
> **연결**: TEMPLATE.md (playground), docs/playground/courses/

---

## 1. 목적
p-hermes 강의 슬라이드의 **playground (개발) 버전**을 정의합니다.
이 Spec은 로컬 개발 공간인 `docs/playground/courses/`의 슬라이드에 적용됩니다.

## 2. 버전 관리
- **v1.1-playground**: 초기 playground 슬라이드 (Lecture 01-02, published v1.0 기반)
- 각 강의가 playground에서 개발 완료되면 published로 승격
- TEMPLATE.md 변경 시 메이저 버전 증가 (published와 독립)

## 3. 스펙 참조
- TEMPLATE.md: `docs/playground/courses/TEMPLATE.md` — 레이아웃/스타일 규칙
- SPEC-B7: `slide-composition-spec.md` — 슬라이드 구성 규격 (Spec-Driven Dev)
- validate-course.py: `tests/validate-course.py` — 검증 스크립트

## 4. 현재 playground 슬라이드

| 강의 | 버전 | 상태 | Spec 연동 |
|:----|:----:|:----:|:---------|
| 01 — Why Agents Fail | v1.1-playground | ⚠️ 수정 필요 | TEMPLATE.md 준수 필요 |
| 02 — Memory & Knowledge | v1.1-playground | ✅ 준수 | TEMPLATE.md |

## 5. published와의 차이
- **Playground**: 실험적 템플릿/컴포넌트, WIP 내용, 자유로운 레이아웃 변경
- **Published**: 안정적인 템플릿, 검증 완료된 내용
- TEMPLATE.md와 SPEC-SLIDES.md는 각자 독립적으로 진화

## 6. 게이트
- `docs/playground/courses/`의 슬라이드는 검증 실패해도 진행 가능 (WIP 특성)
- published 승격 시 반드시 `python3 tests/validate-course.py` 통과 필요
