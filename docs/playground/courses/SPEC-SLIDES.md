# SPEC-SLIDES — Playground Version (v1.8)

> **마지막 업데이트**: 2026-06-24
> **상태**: Active
> **연결**: TEMPLATE.md (playground), docs/playground/courses/

---

## 1. 목적
p-hermes 강의 슬라이드의 **playground (개발) 버전**을 정의합니다.
이 Spec은 로컬 개발 공간인 `docs/playground/courses/`의 슬라이드에 적용됩니다.

## 2. 버전 관리
- **v1.8-playground**: § 번호 정리, nav 숨김 통일(display), compare-table div 형식 강제, 반응형 grid 규칙 (JOB-1865)
- **v1.7-playground**: 마무리 2페이지 강제, Q&A 예시질문 금지, nav 하단 통합 (JOB-1860)
- **v1.6-playground**: 내비게이션 바 Section Progress, Section Divider 통일 (JOB-1856)
- **v1.5-playground**: Progress Indicator, TOC 제거, 5-template 통일 (JOB-1853)
- **v1.4-playground**: Knowledge 개념 통일(동적), TOC 통일, 3종 엔딩 강제 (JOB-1844)
- **v1.3-playground**: Summary & Q&A 템플릿 + 목차 시스템 + 레이아웃 규칙 추가
- **v1.2-playground**: Notes UI 템플릿 통일 + 내용 방향 R0~R5 추가 (JOB-1813)

## 3. 스펙 참조
- TEMPLATE.md: `docs/playground/courses/TEMPLATE.md` — 레이아웃/스타일 규칙
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

## 5. Notes UI 템플릿

모든 슬라이드의 강의 노트 표시 UI는 다음으로 통일합니다.

### CSS
```css
/* ── Notes Toggle ── */
.notes-toggle {
  position: fixed; bottom: 24px; right: 24px;
  z-index: 100;
  background: var(--card);
  border: 1px solid var(--border);
  color: var(--text-dim);
  padding: 8px 16px;
  border-radius: 8px;
  cursor: pointer;
  font-size: 14px;
  font-family: 'JetBrains Mono', monospace;
  transition: var(--transition);
}
.notes-toggle:hover { border-color: var(--gold); color: var(--gold); }

.notes-panel {
  display: none;
  position: fixed; bottom: 60px; right: 24px;
  width: 480px; max-height: 320px;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 24px;
  overflow-y: auto;
  z-index: 100;
  font-size: 16px; line-height: 1.7;
  color: var(--text-dim);
}
.notes-panel.visible { display: block; }
.notes-panel h4 {
  color: var(--gold); margin-bottom: 12px; font-size: 14px;
  font-family: 'JetBrains Mono', monospace;
}
```

### HTML
```html
<button class="notes-toggle" id="notesToggle">📝 Notes</button>
<div class="notes-panel" id="notesPanel">
  <h4>발표자 노트</h4>
  <p id="notesContent">슬라이드를 선택해주세요.</p>
</div>
```

### JS
```js
// Notes toggle
const notesToggle = document.getElementById('notesToggle');
const notesPanel = document.getElementById('notesPanel');
const notesContent = document.getElementById('notesContent');

// In update():
notesContent.textContent = currentSlide.dataset.notes || '';

// Event:
notesToggle.addEventListener('click', () => {
  notesPanel.classList.toggle('visible');
});
```

### HTML 속성 표준
| 속성 | 규칙 | 예시 |
|:----|:------|:------|
| `id` | `slide-N` (N=0부터 순차), 모든 슬라이드 필수 | `id="slide-0"` |
| `data-notes` | 큰따옴표, 내부 ASCII 작은따옴표 허용 | `data-notes="... '용어' ..."` |

## 6. Notes 내용 방향

### 핵심 원칙: "발표 대본, 요약문이 아닌 대화 스크립트"

data-notes는 발표자가 슬라이드를 설명할 때 자연스럽게 읽을 수 있는 대본이어야 함.

- ❌ 슬라이드 내용의 요약/재진술
- ✅ 슬라이드 시각물에 살을 붙이는 해설
- ✅ 청중과의 연결을 위한 대화체

### 4가지 방향성

| 방향 | 설명 | 예시 |
|:----|:-----|:------|
| ① 도입-전개-정리 3단계 | 첫 문장 청중 집중 → 본문 설명 → 키워드 정리 | "퇴근 전에 정리한 회의록을 다음 날... → Agent는 매번 대화가 초기화될 때마다... → 이 피로감이 Agent 실패의 시작입니다." |
| ② 말하는 문장 | 읽으면 말이 되는 문장 (글체 금지, 구어체) | "Stateless 시스템의 핵심 문제는..." (○) vs "본 슬라이드는..." (✗) |
| ③ 시각-청각 보완 | 슬라이드에 없는 내용을 말로 보충 (중복 금지) | 슬라이드에 "Memory Loss"만 → data-notes에 구체적 예시 |
| ④ 청중 반응 예측 | 이해 어려운 부분을 미리 짚어줌 | "마치 신입사원이 매일 똑같은 교육을 받는 것과 같습니다." |

### R0~R5 규칙

| 규칙 | 내용 | 레벨 |
|:----|:------|:----:|
| **R0** | **"발표 대본" 원칙** — 읽으면 말이 되는 문장 | MUST |
| **R1** | **첫 문장 = 슬라이드 핵심** (20~40자) | MUST |
| **R2** | **80~150자** 유지 | MUST |
| **R3** | **단정적 종결** (의문문 지양, 단 도입부는 예외) | SHOULD |
| **R4** | **추상 개념은 반드시 구체적 예시 동반** | SHOULD |
| **R5** | 마지막 1문장 **`핵심:` 태그**로 정리 | SHOULD |

### 강의별 스타일 허용

| 요소 | 서사형 (L01 적합) | 설명형 (L02 적합) |
|:----|:-----------------:|:-----------------:|
| 시작 | 의문/상황 제시 | 직접 선언 |
| 예시 | 메타포/비유 | 개념/대비 |
| 종결 | 자연스러운 구어체 | 명확한 평서문 |
| 적합 슬라이드 | 도입/전환/비유 필요 시 | 개념 정의/비교/정리 시 |

> 선택 기준: 슬라이드 메시지 전달에 더 효과적인 쪽. 같은 강의 내에서도 혼용 가능.

## 7. 현재 playground 슬라이드

| 강의 | 버전 | 상태 | Spec 연동 |
|:----|:----:|:----:|:---------|
| 01 — Why Agents Fail | v1.8-playground | ✅ nav 숨김 통일, compare-table div화 (JOB-1865) | SPEC-SLIDES v1.8 |
| 02 — Memory & Knowledge | v1.8-playground | ✅ nav 숨김 통일, compare-table div화 (JOB-1865) | SPEC-SLIDES v1.8 |
| 03 — Skills & Workflow | v1.8-playground | ✅ nav 숨김 통일, compare-table div화, 로컬 CSS 정리 (JOB-1865) | SPEC-SLIDES v1.8 |
| 04 — Hermes Core Architecture | v1.8-playground | ✅ nav 숨김 통일, compare-table div화 (JOB-1865) | SPEC-SLIDES v1.8 |

## 8. 게이트
- `docs/playground/courses/`의 슬라이드는 검증 실패해도 진행 가능 (WIP 특성)
- published 승격 시 반드시 `python3 tests/validate-slides.py` 통과 필요
- **deploy.sh 연동**: `python3 tests/validate-slides.py` 실행 → 실패 시 배포 차단 (MUST)

## 9. 마무리 템플릿 (v1.8)

### 9.0 지식 개념 통일
Knowledge 정의는 모든 강의에서 **"동적 관계 네트워크"**로 통일한다.

| 레이어 | 속성 | 설명 |
|:------|:----:|:------|
| Memory | 정적 (Static) | 사실 저장, What happened |
| Knowledge | 동적 (Dynamic) | 관계와 패턴, Why it matters |
| Skills | 확장 가능 (Extensible) | 실행 능력, How |
| Workflow | 상태 기반 (Stateful) | 순서와 조건, When |

> L02에서는 Memory(정적) vs Knowledge(동적) 비교, L03에서는 Knowledge(동적) vs Skills(확장) 비교
> 강의 간 Knowledge 정의가 충돌하지 않도록 주의 (MUST)

### 9.1 마무리 구조 (2페이지 강제)
모든 강의의 마무리는 반드시 다음 2페이지만 사용한다 (MUST).

| 순서 | 역할 | 템플릿 | 필수 |
|:----:|:-----|:-------|:----:|
| N-1 | **Summary** | `.summary-slide` | MUST |
| N | **Q&A** | `.summary-slide` | MUST |

### 9.2 Summary 슬라이드 (N-1장)
강의 핵심 3~4 bullet points + Keywords 영역.

```
[강의명] · Summary
┌──────────────────────────────────┐
│ 오늘의 핵심                      │
│ ① 핵심 포인트 1                 │
│ ② 핵심 포인트 2                 │
│ ③ 핵심 포인트 3                 │
│ ④ (필요 시) 핵심 포인트 4       │
│                                  │
│ Keywords: keyword1, keyword2     │
└──────────────────────────────────┘
```

### 9.3 Q&A 슬라이드 (N장, 빈 슬라이드)
**예시 질문(예상 질문) 절대 금지** (MUST).

data-notes에도 예시 질문을 포함하지 않는다 (MUST).

올바른 Q&A 슬라이드:
```
Q&A
┌─────────────────────────┐
│                         │
│    Questions?           │
│                         │
│  (청중 실제 질문 대기)   │
│                         │
└─────────────────────────┘
```

**규칙**:
- Q&A 슬라이드는 제목(Q&A/Questions?)만 표시 (MUST)
- visible 텍스트에 예시 질문 금지 (MUST)
- data-notes에 예시 질문 포함 금지 (MUST)
- "청중이 실제로 할 만한 질문" 형식 금지 (MUST)
- Summary → Q&A 순서로 연속 배치 (MUST)
- Wrap-Up Divider 불필요 (MUST)

## 10. 내비게이션 바: Section Progress (v1.8)

### 10.1 정의
현재 강의의 섹션 진행도를 표시하는 nav bar.
**하단 고정 위치** — slide-counter와 nav dots 사이에 배치.

### 10.2 HTML 구조 (단일 인스턴스)
```html
<!-- .deck 외부, 고정 위치 -->
<div class="section-progress" id="sectionProgress">
  <span class="sec active" data-section="1">문제 인식</span>
  <span class="sec-arrow">→</span>
  <span class="sec future" data-section="2">4가지 패턴</span>
  <span class="sec-arrow">→</span>
  <span class="sec future" data-section="3">해결: Agent OS</span>
</div>
```

**중요**: `<div class="section-progress">`는 **한 번만** 존재. slide 내부에 포함 금지.

### 10.3 상태
| 클래스 | 의미 | 시각 |
|:-------|:-----|:------|
| `sec active` | 현재 섹션 | 금색 pill 강조 |
| `sec done` | 지나간 섹션 | 흐릿하게 |
| `sec future` | 아직 안 온 섹션 | 더 흐릿하게 |

### 10.4 표시/숨김 규칙

| 슬라이드 템플릿 | Nav Bar |
|:--------------|:--------|
| `.hero-slide` (Cover, slide-0) | ❌ 숨김 |
| `.problem-slide` (Goal/Intro, slide-1) | ❌ 숨김 |
| `.section-divider` | ✅ **표시** |
| `.diagram-slide` / `.example-slide` (본문) | ✅ 표시 |
| `.summary-slide` (마지막 2장) | ❌ 숨김 |

**JS 로직 통일** (MUST):
```javascript
// 모든 강의에서 동일한 방식으로 구현
const hideTypes = ['hero-slide', 'problem-slide', 'summary-slide'];
if (hideTypes.some(t => currentSlide.classList.contains(t))) {
  sectionProgress.style.display = 'none';
} else {
  sectionProgress.style.display = 'flex';
}
```

> ⚠️ `classList.add('hidden')` 방식 금지 — CSS 의존성으로 동작 불일치 발생 (§10.7 참조)
> ⚠️ `style.opacity = '0'` 방식 금지 — DOM 공간 차지

### 10.5 위치
- `position: fixed; bottom: 48px; left: 50%; transform: translateX(-50%)`
- slide-counter (`bottom: 24px`) 위
- nav dots (`bottom: 8px`) 위

### 10.6 각 강의별 섹션
| 강의 | 섹션 1 | 섹션 2 | divider 수 |
|:----|:-------|:-------|:-----------|
| L01 | 문제 인식 | 4가지 패턴 + 해결: Agent OS | 1 |
| L02 | Memory | Knowledge | 2 |
| L03 | Knowledge → Skills | Hermes Workflow | 2 |
| L04 | Architecture | Runtime & SSOT | 2 |

### 10.7 CSS
`components/slides-components.css` — `:root` 변수 + `.section-progress` 스타일 포함.

```css
/* 숨김 처리 — display 방식으로 통일 */
.section-progress.hidden { display: none; }

/* 숨김/표시: JS에서 style.display = 'none'/'flex' 직접 제어 */
```

## 11. Section Divider (v1.8)

### 11.1 정의
섹션 전환을 표시하는 구분 슬라이드.

### 11.2 구조
```html
<div class="slide section-divider" id="slide-N">
  <div class="section-divider-content">
    <div class="divider-label">Part 2</div>
    <div class="divider-title">4가지 실패 패턴</div>
    <div class="divider-desc">구체적인 실패 유형과 그 영향</div>
  </div>
</div>
```

### 11.3 CSS 클래스
`.slide.section-divider` + 내부 `.section-divider-content` / `.divider-label` / `.divider-title` / `.divider-desc`

## 12. 강의 구조 가이드라인 (v1.8)

### 12.1 공통 구조 (2페이지 오프닝 + 2페이지 마무리 고정)
| 순서 | 역할 | 템플릿 |
|:----:|:-----|:-------|
| 0 | **Cover** — 제목 + 한 줄 메시지 | Hero |
| 1 | **Goal + Intro** — Why + 3 Goals + Part Flow | Problem |
| 2~N | **Main Content** | Mixed |
| — | **Section Divider** | Section-divider |
| N-1 | **Summary** | Summary |
| N | **Q&A** | Summary |

### 12.2 규칙
- Cover + Goal/Intro 2페이지 고정 (MUST)
- Summary + Q&A 각 1장, 총 2페이지 마무리 (MUST) — §9.1과 일치
- Wrap-Up Divider 불필요 (MUST)
- Section Divider = 섹션 개수와 동일 (SHOULD)
- TOC 슬라이드 존재 금지 — nav bar가 대체 (MUST)
- L04: 정규화된 slide-N ID만 사용, 비정규 ID 금지 (MUST)
- **마지막 2장 외에 summary-slide 사용 금지** (MUST)

## 13. 템플릿 제약 (v1.8)

### 13.1 허용 템플릿 (5종 + divider)
| # | 템플릿 | CSS 클래스 | 용도 |
|:-:|:-------|:-----------|:------|
| 1 | **Hero** | `.hero-slide` | Cover |
| 2 | **Problem** | `.problem-slide` | Goal/Intro |
| 3 | **Diagram** | `.diagram-slide` | 프로세스/아키텍처 (주력) |
| 4 | **Example** | `.example-slide` | 사례, 코드 |
| 5 | **Summary** | `.summary-slide` | Summary, Q&A |
| 6 | **Divider** | `.section-divider` | 섹션 전환 |

### 13.2 규칙
- 하나의 슬라이드는 정확히 하나의 템플릿 (MUST)
- 신규 템플릿은 SPEC-SLIDES amendment 필요

## 14. CSS Architecture (v1.8)

### 14.1 Shared Component Library
```css
/* 모든 강의는 동일한 components/slides-components.css 참조 */
<link rel="stylesheet" href="components/slides-components.css">
```

### 14.2 각 HTML 파일
- `<style>` 블록 최소화 (shared CSS에 없는 강의 고유 스타일만)
- 공통 스타일은 slides-components.css가 SSOT
- **로컬 CSS는 ≤ 10,000 chars 권장** (SHOULD)

### 14.3 파일 위치
```
docs/playground/courses/
├── components/
│   └── slides-components.css    ← Shared SSOT
├── lecture-01-why-agents-fail.html
├── lecture-02-memory-and-knowledge.html
├── lecture-03-skills-and-workflow.html
├── lecture-04-hermes-core-architecture.html
└── SPEC-SLIDES.md
```

## 15. 레이아웃 규칙 (v1.8)

### 15.1 overflow-safe 제한
- 슬라이드당 최대 4개 포인트
- 4포인트 초과 시 반드시 2장으로 분할 (MUST)

### 15.2 정렬 규칙
- 모든 콘텐츠 슬라이드: `align-items: center` (SHOULD)
- overflow-safe 사용 시에도 상단 치우침 방지
- **공용 CSS에 `.slide { align-items: center; justify-content: center }` 정의**

### 15.3 폰트 크기
| 요소 | 크기 | 비고 |
|:----|:----:|:-----|
| 제목 (`.inline-section`) | 26~28px | clamp 사용 |
| 본문 | 20px | 고정 권장 |
| 서브/설명 | 16px | 고정 권장 |
| 코드/JSON | 14px | 예외 허용 |
| badge/메타 | 11~12px | 고정 |

### 15.4 다이어그램
- h-flow (수평 흐름) 권장: `display:flex;align-items:center;justify-content:center;gap:4px`
- layer-stack (수직 박스) 지양: 가독성 낮음
- 각 노드: `flex-direction:column;align-items:center;padding:16px 24px;border-radius:12px`

### 15.5 반응형 grid
- **4+열 grid는 @media ≤768px에서 2열로, ≤480px에서 1열로 collapse** (SHOULD)
- 공용 CSS에 기본 media query 포함:
```css
@media (max-width: 768px) {
  .failure-taxonomy { grid-template-columns: repeat(2, 1fr); }
}
@media (max-width: 480px) {
  .failure-taxonomy { grid-template-columns: 1fr; }
}
```

## 16. compare-table 형식 제한 (v1.8)

### 16.1 규칙
- **`<table>` 태그에 `class="compare-table"` 사용 금지** (MUST)
  → 공용 CSS `.compare-table`이 `display: grid`이므로, HTML `<table>`은 레이아웃이 깨짐
- **`<div class="compare-table">` + 자식 `<div>`만 허용** (MUST)
- 2열 비교 → `grid-template-columns: 1fr 1fr` (기본, 공용 CSS)
- 3열 이상 비교 → 로컬에서 `grid-template-columns: auto 1fr 1fr` 오버라이드 허용 (SHOULD)
- **공용 CSS에 `.compare-table th, .compare-table td { text-align: center }` 정의**

### 16.2 올바른 형식
```html
<div class="compare-table">
  <div class="header"></div>
  <div class="header">Human</div>
  <div class="header">LLM</div>
  <div>기억</div>
  <div class="check">✓</div>
  <div class="cross">Context</div>
  <!-- ... -->
</div>
```
