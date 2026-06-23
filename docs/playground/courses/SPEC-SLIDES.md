# SPEC-SLIDES — Playground Version (v1.2)

> **마지막 업데이트**: 2026-06-23
> **상태**: WIP (Work In Progress)
> **연결**: TEMPLATE.md (playground), docs/playground/courses/

---

## 1. 목적
p-hermes 강의 슬라이드의 **playground (개발) 버전**을 정의합니다.
이 Spec은 로컬 개발 공간인 `docs/playground/courses/`의 슬라이드에 적용됩니다.

## 2. 버전 관리
- **v1.2-playground**: Notes UI 템플릿 통일 + 내용 방향 R0~R5 추가 (JOB-1813)
- 각 강의가 playground에서 개발 완료되면 published로 승격
- TEMPLATE.md 변경 시 메이저 버전 증가 (published와 독립)

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
| 01 — Why Agents Fail | v1.2-playground | ✅ Notes UI+내용 방향 적용 (JOB-1813) | SPEC-SLIDES v1.2 |
| 02 — Memory & Knowledge | v1.2-playground | ✅ Notes UI+내용 방향 적용 (JOB-1813) | SPEC-SLIDES v1.2 |

## 8. 게이트
- `docs/playground/courses/`의 슬라이드는 검증 실패해도 진행 가능 (WIP 특성)
- published 승격 시 반드시 `python3 tests/validate-course.py` 통과 필요
