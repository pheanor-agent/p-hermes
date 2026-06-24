# SPEC-SLIDES — Playground Version (v1.4)

> **마지막 업데이트**: 2026-06-24
> **상태**: Active
> **연결**: TEMPLATE.md (playground), docs/playground/courses/

---

## 1. 목적
p-hermes 강의 슬라이드의 **playground (개발) 버전**을 정의합니다.
이 Spec은 로컬 개발 공간인 `docs/playground/courses/`의 슬라이드에 적용됩니다.

## 2. 버전 관리
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
| 01 — Why Agents Fail | v1.4-playground | ✅ Automation 추가, 전환 중복 제거 (JOB-1844) | SPEC-SLIDES v1.4 |
| 02 — Memory & Knowledge | v1.4-playground | ✅ 주제 불일치 수정, 상단 치우침 수정 (JOB-1844) | SPEC-SLIDES v1.4 |
| 03 — Skills & Workflow | v1.4-playground | ✅ Knowledge 개념 통일, 엔딩 구조 정리, 정렬 (JOB-1844) | SPEC-SLIDES v1.4 |
| 04 — Hermes Core Architecture | v1.4-playground | ✅ 중복 제거, Runtime 연결, 레이어 표시, 사양서 (JOB-1844) | SPEC-SLIDES v1.4 |

## 8. 게이트
- `docs/playground/courses/`의 슬라이드는 검증 실패해도 진행 가능 (WIP 특성)
- published 승격 시 반드시 `python3 tests/validate-course.py` 통과 필요

## 9. Summary & Q&A 템플릿 (v1.4)

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

### 9.1 Summary 슬라이드 (마지막-2장)
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

### 9.2 Key Insight 슬라이드 (마지막-1장)
가장 중요한 인사이트를 1문장으로 표현. 다음 강의와의 연결 고리 포함.

### 9.3 Q&A 슬라이드 (마지막장)
질문 3개 (청중이 실제로 할 만한 질문), **FAQ 스타일 사전 답변 금지** (SHOULD).
data-notes와 visible 모두에서 "Q1: ... → 답변" 형식의 사전 정의된 FAQ 문구 제거.
자연스러운 청중 질문 형식 유지.

→ 다음 강의: 연결 문구는 Q&A 슬라이드에만 표시 (MUST), Key Insight에서 제거

```
Q&A
┌──────────────────────────────────┐
│ Q1. 질문 내용                    │
│ A1. 답변 내용                    │
│                                  │
│ Q2. 질문 내용                    │
│ A2. 답변 내용                    │
│                                  │
│ Q3. 질문 내용                    │
│ A3. 답변 내용                    │
│                                  │
│ → 다음 강의: [강의 제목]         │
└──────────────────────────────────┘
```

### 9.4 규칙
- 모든 강의는 이 3장 템플릿을 준수해야 함 (MUST)
- Q&A 없이 Summary로만 끝나는 것 금지

## 10. Progress Indicator (v1.5)

### 10.1 정의
모든 슬라이드 상단에 전체 코스 경로를 표시하는 고정 바.
TOC 슬라이드를 대체.

### 10.2 구조
```html
<div class="course-progress">
  <span class="step dim">01 Why Agents Fail</span>
  <span class="sep">·</span>
  <span class="step active">02 Memory & Knowledge</span>
  <span class="sep">·</span>
  <span class="step dim">03 Skills & Workflow</span>
  <span class="sep">·</span>
  <span class="step dim">04 Core Architecture</span>
</div>
```

### 10.3 규칙
- 모든 슬라이드 상단에 위치 (MUST)
- 현재 강의: `class="step active"`, 나머지: `class="step dim"` (MUST)
- 구분자: `<span class="sep">·</span>` (MUST)
- 라벨: `course_metadata.json` SSOT 준수 (SHOULD)
- CSS only — JS 변경 불필요

## 11. Section Divider (v1.5)

### 11.1 정의
섹션 전환을 표시하는 구분 슬라이드. TOC가 하던 "지금 Part X" 역할.

### 11.2 구조
- Gradient 배경 (Hero 변형)
- 가운데 정렬
- label + title + description 3층

### 11.3 규칙
- 강의당 최대 4개 (SHOULD)
- Section Divider는 Hero 템플릿 변형으로 취급
- 하나의 섹션 = 하나의 Divider (OPTIONAL)

## 12. 강의 구조 가이드라인 (v1.5)

### 12.1 공통 구조
| 순서 | 역할 | 템플릿 |
|:----:|:-----|:-------|
| 0 | **Cover** | Hero |
| 1 | **Why This Matters** | Problem |
| 2 | **Learning Goal** | Hero |
| 3~N | **Main Content** | Mixed (Diagram 중심) |
| — | **Section Divider** | Hero (변형) |
| N-2 | **Summary** | Summary |
| N-1 | **Takeaways** | Summary |
| N | **[Q&A 선택]** | Summary |

### 12.2 규칙
- Cover + Why + Goal 각 1장씩 (SHOULD)
- Summary + Takeaways 각 1장 (MUST)
- Section Divider ≤ 4 (SHOULD)

## 13. 템플릿 제약 (v1.5)

### 13.1 허용 템플릿 (5종)
| # | 템플릿 | CSS 클래스 | 용도 |
|:-:|:-------|:-----------|:------|
| 1 | **Hero** | `.hero-slide` | Cover, Goal, Section Divider |
| 2 | **Problem** | `.problem-slide` | Why Matters, 문제 제기 |
| 3 | **Diagram** | `.diagram-slide` | 프로세스/아키텍처 (주력) |
| 4 | **Example** | `.example-slide` | 사례, 코드 |
| 5 | **Summary** | `.summary-slide` | Summary, Takeaways, Q&A |

### 13.2 규칙
- 하나의 슬라이드는 정확히 하나의 템플릿 (MUST)
- 신규 템플릿은 SPEC-SLIDES amendment 필요

## 11. 레이아웃 규칙 (v1.3)

### 11.1 overflow-safe 제한
- 슬라이드당 최대 4개 포인트
- 4포인트 초과 시 반드시 2장으로 분할 (MUST)

### 11.2 정렬 규칙
- 모든 콘텐츠 슬라이드: `align-items: center` (SHOULD)
- overflow-safe 사용 시에도 상단 치우침 방지

### 11.3 폰트 크기
| 요소 | 크기 | 비고 |
|:----|:----:|:-----|
| 제목 (`.inline-section`) | 26~28px | clamp 사용 |
| 본문 | 20px | 고정 권장 |
| 서브/설명 | 16px | 고정 권장 |
| 코드/JSON | 14px | 예외 허용 |
| badge/메타 | 11~12px | 고정 |

### 11.4 다이어그램
- h-flow (수평 흐름) 권장: `display:flex;align-items:center;justify-content:center;gap:4px`
- layer-stack (수직 박스) 지양: 가독성 낮음
- 각 노드: `flex-direction:column;align-items:center;padding:16px 24px;border-radius:12px`
