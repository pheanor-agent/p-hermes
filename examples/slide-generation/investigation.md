# 슬라이드 생성 — 조사 단계

- **JOB**: JOB-2026-0622-002
- **조사 기간**: 2026-06-22 11:00 ~ 11:25
- **참조**: content-system skill, SPEC-EXPR-01

## 1. Content System 조사

`content-system` skill을 로드하여 분석:

### D1~D5 Domain 개요

| Domain | 용도 | 적용 여부 |
|--------|------|----------|
| D1 | Blog / Article | ❌ (불필요) |
| D2 | Slide / Presentation | **✅ 주 Domain** |
| D3 | Documentation | 부분 참조 |
| D4 | Social / Short Form | ❌ |
| D5 | Internal / Technical Note | 부분 참조 |

### 템플릿 조사

기존 템플릿 `technical-seminar-dark` 확인 결과:
- Reveal.js v4.3 기반
- 다크 테마, 코드 하이라이팅 포함
- Mermaid.js 플러그인 내장 ✅
- 이전 사용: `presentations/hermes-intro-v2/`

## 2. 참고 자료 분석

**Knowledge: `expression-architecture.md`** 에서 발췌:

- Content System은 3개 레이어로 구성: **Spec Layer → Expression Layer → Output Layer**
- 각 레이어는 독립적으로 교체 가능
- D2 Domain의 출력 포맷: HTML (Reveal.js), PPTX, Markdown

## 3. 기존 슬라이드 분석

`presentations/hermes-intro-v2/` 구조:
```
└── index.html          # Reveal.js 메인 파일
└── slides/             # 슬라이드별 markdown 파일 (선택적)
└── assets/             # 이미지, 폰트
```

## 4. 계층 구조 초안

요청 내용 기반 슬라이드 계층 구성:

1. 제목 슬라이드 — Hermes Content System 아키텍처
2. 발표자 소개 / Agenda
3. Content System 설계 철학 (D1~D5)
4. Expression System 추상화 레이어
5. Content Pipeline 개요
6. Template → Generator → Validator → Output
7. D2 Domain 상세 (Slide Generation)
8. Knowledge 연동 사례
9. 실제 코드 예시
10. 모범 사례 / Pitfalls
11. 향후 로드맵
12. Q&A

**검증**: 12장, 요청 범위(12~15장) 충족 ✅
