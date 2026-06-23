# 강의 슬라이드 템플릿

> p-hermes 강의 시리즈 공통 스타일 가이드
> 작성: 2026-06-23
> 참조: 1강, 2강

---

## CSS 변수 (공통)

```css
:root {
  --bg: #0b0d12;
  --surface: #12151c;
  --card: #181c28;
  --border: #262b3a;
  --gold: #f0b429;
  --gold-dim: #b8861e;
  --gold-glow: rgba(240,180,41,.15);
  --text: #e8edf5;
  --text-dim: #8892a8;
  --accent-cyan: #5bc0eb;
  --accent-magenta: #f15bb5;
  --accent-green: #00f5d4;
  --accent-red: #ff6b6b;
  --accent-orange: #ffa94d;
  --accent-purple: #b197fc;
  --radius: 16px;
  --transition: 400ms cubic-bezier(.22,1,.36,1);
}
```

---

## 폰트

- **English**: Inter var (300/400/500/700/900)
- **Korean**: Noto Sans KR (300/400/500/700/900)
- **Mono**: JetBrains Mono (400/700)

---

## 레이아웃

### 슬라이드
```css
.slide {
  padding: 64px 80px;
  align-items: center;
  justify-content: center;
}
```

### Header
- `.lecture-badge`: **중앙 상단** (`top: 32px; left: 50%`)
  - gold 배경 + border
  - `Lecture 01`, `Lecture 02` 형식

### Slide Counter
- `.slide-counter`: **아래 중앙** (`bottom: 60px; left: 50%`)
  - `1 / 20` 형식

---

## 타이포그래피

| 클래스 | 크기 | 용도 |
|:-------|:-----|:-----|
| `.title` | `clamp(40px,6vw,64px)` | 슬라이드 제목 (반응형) |
| `.subtitle` | `clamp(20px,2.5vw,28px)` | 부제 (반응형) |
| `.section-title` | `16px uppercase` | 섹션 타이틀 |
| `.big-text` | `clamp(40px,6vw,64px)` | 강조 텍스트 |
| `.big-q` | `clamp(24px,3vw,36px)` | 큰 질문 |
| `.key-message` | `22px` | 핵심 메시지 |

---

## 컴포넌트

### Flow (흐름 다이어그램)
```html
<div class="flow">
  <div class="node [color]">Text</div>
  <div class="arrow">↓</div>
  <div class="node [color]">Text</div>
</div>
```
- Color variants: `cyan`, `purple`, `green`, `gold`, `orange`
- Gap: `16px`

### Two Column (2컬럼)
```html
<div class="two-col">
  <div class="col">
    <div class="col-title">Title</div>
    <div class="col-item [ok|warn]">Item</div>
  </div>
  <div class="col">...</div>
</div>
```
- `gap: 48px`, `max-width: 900px`

### Key Message (핵심 메시지)
```html
<div class="key-message">메시지</div>
```
- gold glow 배경 + border

### Compare Table (비교표)
```html
<table class="compare-table">
  <thead><tr><th>A</th><th>B</th></tr></thead>
  <tbody><tr><td>...</td><td>...</td></tr></tbody>
</table>
```
- `max-width: 700px`

### Insight Box (인사이트)
```html
<div class="insight-box">메시지</div>
```
- purple border + 배경

### Example Box (예시)
```html
<div class="example-box">
  <div class="label">LABEL</div>
  Content
</div>
```
- `border-left: 3px solid var(--accent-cyan)`

### Tags (태그)
```html
<div class="tags">
  <span class="tag [cyan|purple|green|gold]">Tag</span>
</div>
```

### Number Scale (규모 표시)
```html
<div class="number-scale">
  <div class="number-item">
    <div class="number-bar [warn|error]" style="height:48px;">10개</div>
    <span class="number-label">Label</span>
  </div>
</div>
```

### Category Grid (3컬럼 그리드)
```html
<div class="category-grid">
  <div class="category-card">
    <h3>Title</h3>
    <p>Description</p>
  </div>
</div>
```

---

## Not Equal (비등호)
```html
<div class="not-equal">
  <span>Left</span>
  <span class="neq-sign">≠</span>
  <span>Right</span>
</div>
```

---

## JS (공통)

### Navigation
- `IntersectionObserver` 기반
- `threshold: 0.6`

### Keyboard
- `ArrowRight` → 다음 슬라이드
- `ArrowLeft` → 이전 슬라이드

### Notes Toggle
- `📝 Notes` 버튼 (아래 우측)
- `.notes-panel` 토글

---

## 폰트 크기 기준

| 요소 | 크기 |
|:-----|:-----|
| Title | `clamp(40px,6vw,64px)` |
| Subtitle | `clamp(20px,2.5vw,28px)` |
| Big text | `clamp(40px,6vw,64px)` |
| Big question | `clamp(24px,3vw,36px)` |
| Key message | `22px` |
| Node | `22px` |
| Col item | `20px` |
| Table | `17px` |
| Example box | `20px` |
| Insight box | `20px` |
| Tag | `18px` |
| Slide counter | `12px` |

---

## 규칙

1. **반응형 필수**: title/subtitle/big-text는 `clamp()` 사용
2. **lecture-badge**: 중앙 상단 고정
3. **slide-counter**: 아래 중앙 고정
4. **two-col**: `1fr 1fr` (2컬럼), `gap: 48px`
5. **flow**: `gap: 16px`
6. **key-message**: gold glow
7. **insight-box**: purple
8. **발표자 노트**: 모든 슬라이드에 `data-notes` 포함
