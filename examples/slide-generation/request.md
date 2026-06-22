# 슬라이드 생성 요청

- **JOB**: JOB-2026-0622-002
- **요청자**: 박지민 (Developer Relations 팀)
- **요청일**: 2026-06-22
- **상태**: 접수 완료

## 요청 내용

Hermes, 다음 주 기술 세미나에서 발표할 자료가 필요합니다. 주제는 **"Hermes Agent의 Content System 아키텍처"** 입니다.

### 요청 상세

1. **슬라이드 수**: 12~15장
2. **템플릿**: `technical-seminar-dark` (기존 템플릿 사용)
3. **대상**: 개발자 (중급 이상, Hermes 기초 지식 보유)
4. **언어**: 한국어

### 포함할 내용

- Hermes Content System의 설계 철학 (D1~D5 Domain 개념)
- Expression System의 추상화 레이어
- Content Pipeline: Template → Generator → Validator → Output
- 실제 사례: Knowledge와 Content System의 연동

### 참고 자료

- `content-system` skill의 SKILL.md
- `specs/active/SPEC-EXPR-01.md`
- Knowledge: `knowledge/system/content/expression-architecture.md`
- 기존 슬라이드: `presentations/hermes-intro-v2/` (참고용)

## 전달 방식

생성된 슬라이드는 HTML 파일로 출력해주세요. 발표자가 브라우저에서 바로 열어서 사용할 수 있어야 합니다. Reveal.js 기반으로 생성해주시고, Mermaid.js 다이어그램이 포함되면 좋겠습니다.
