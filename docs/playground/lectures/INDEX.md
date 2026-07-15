# p-hermes 강의 — Version Index

## 현재 버전: v8.2

v8.2는 사용자가 제공한 새로운 슬라이드 버전입니다. Series Navigation(상단 덱 네비게이션), Presenter Controls(발표자 컨트롤), Interactive Labs(라이브 실습), Slide Map(O 키 전체보기) 등 신규 기능이 포함된 통합 덱쉘 시스템입니다.

| 덱 | 슬라이드 | 프레임워크 | 링크 |
|---|---:|---|---|
| Deck A — 4가지 핵심 기능 | 35장 | 4 Core Functions | [v8.2/deck-a-core-v8.2.html](v8.2/deck-a-core-v8.2.html) |
| Deck B — Knowledge 완전 정복 | 36장 | Progressive Disclosure | [v8.2/deck-b-knowledge-v8.2.html](v8.2/deck-b-knowledge-v8.2.html) |
| Deck C — Skill 심화 | 38장 | 6-Act Structure | [v8.2/deck-c-skill-v8.2.html](v8.2/deck-c-skill-v8.2.html) |
| Deck D — Workflow 심화 | 47장 | 7-Act Structure | [v8.2/deck-d-workflow-v8.2.html](v8.2/deck-d-workflow-v8.2.html) |

**합계: 156장** — 각 수치는 런타임 네비게이터의 `.slide` 카운트 기준입니다.

---

## Stable 버전: v8.1

v8.1은 사용자 제공 HTML/CSS/JS를 원문 그대로 보존한 **안정판**입니다. 각 덱은 같은 폴더의 `slides-v8.css`와 `slides-v8.js`만 사용합니다.

| 덱 | 슬라이드 | 프레임워크 | 링크 |
|---|---:|---|---|
| Deck A — 4가지 핵심 기능 | 35장 | 4 Core Functions | [v8.1/deck-a-core.html](v8.1/deck-a-core.html) |
| Deck B — Knowledge 완전 정복 | 36장 | Progressive Disclosure | [v8.1/deck-b-knowledge.html](v8.1/deck-b-knowledge.html) |
| Deck C — Skill 심화 | 38장 | 6-Act Structure | [v8.1/deck-c-skill.html](v8.1/deck-c-skill.html) |
| Deck D — Workflow 심화 | 47장 | 7-Act Structure | [v8.1/deck-d-workflow.html](v8.1/deck-d-workflow.html) |

**합계: 156장**

---

## Stable 버전: v8

v8은 commit `12426be` 기준으로 복원한 안정판입니다. 기존 URL과 인라인 CSS/JS 구조를 보존합니다.

| 덱 | 슬라이드 | 프레임워크 | 링크 |
|---|---:|---|---|
| Deck A — 4가지 핵심 기능 | 34장 | 4 Core Functions | [v8/deck-a-core.html](v8/deck-a-core.html) |
| Deck B — Knowledge 완전 정복 | 35장 | Progressive Disclosure | [v8/deck-b-knowledge.html](v8/deck-b-knowledge.html) |
| Deck C — Skill 심화 | 37장 | 6-Act Structure | [v8/deck-c-skill.html](v8/deck-c-skill.html) |
| Deck D — Workflow 심화 | 46장 | 7-Act Structure | [v8/deck-d-workflow.html](v8/deck-d-workflow.html) |

**합계: 152장**

---

## 버전 선택 기준

| 버전 | 상태 | 자산 구조 | 사용 시점 |
|---|---|---|---|
| **v8.2/** | Current | 외부 `slides-v8.2.css` + `slides-v8.2.js`, 통합 덱쉘 | 최신 기능 (Series Nav, Presenter Controls, Labs) |
| **v8.1/** | Stable | 로컬 외부 `slides-v8.css` + `slides-v8.js` | 기존 디자인 참조 |
| **v8/** | Stable | 원본 인라인 CSS/JS | 기존 북마크·비교·안정판 참조 |

## 버전 히스토리

| 버전 | 날짜 | 강의 | 슬라이드 | 위치 |
|---|---|---|---:|---:|---|
| **v8.2** | 2026-07-15 | 4덱 | 156장 | `v8.2/` |
| **v8.1** | 2026-07-14 | 4덱 | 156장 | `v8.1/` |
| **v8** | 2026-07-11 | 4덱 | 152장 | `v8/` |
| v7 | 2026-07-07 | 3강 | 50장 | `v7/` |
| v5 | 2026-07-06 | 3강 | 50장 | `v5/` |
| v4 | 2026-07-05 | 3강 | 55장 | `v4/` |

## 폴더 구조

```text
lectures/
├── INDEX.md
├── index.html
├── versions.json                 # 버전 메타데이터 SSOT
├── v8.2/                          # Current · 통합 덱쉘 시스템
│   ├── deck-a-core-v8.2.html … deck-d-workflow-v8.2.html
│   ├── slides-v8.2.css
│   └── slides-v8.2.js
├── v8.1/                          # Stable · 독립 외부 자산 패키지
│   ├── deck-a-core.html … deck-d-workflow.html
│   ├── slides-v8.css
│   └── slides-v8.js
├── v8/                            # Stable · 12426be 원본
│   ├── components/slides-v8.css
│   └── deck-a-core.html … deck-d-workflow.html
├── v7/
├── v5/
├── v4/
└── archive/
```

- v8.2, v8.1, v8 사이에 CSS/JS 공유·심링크·교차 참조는 없습니다. 각 버전이 완전히 독립적인 패키지입니다.
- 각 버전의 파일은 사용자 제공 원문을 바이트 단위로 보존합니다.
