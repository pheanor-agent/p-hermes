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
  overflow: hidden;
  max-height: 100vh;
}
```

### Header
- `.lecture-badge`: **중앙 상단** (`top: 32px; left: 50%`)
  - gold 배경 + border
  - `Lecture 01`, `Lecture 02` 형식

### Slide Counter
- `.slide-counter`: **아래 중앙** (`bottom: 60px; left: 50%`)
  - `1 / 24` 형식

---

## 타이포그래피

| 클래스 | 크기 | 용도 |
|:-------|:-----|:-----|
| `.title` | `clamp(40px,6vw,64px)` | 슬라이드 제목 (반응형) |
| `.subtitle` | `clamp(20px,2.5vw,28px)` | 부제 (반응형) |
| `.section-title` | `clamp(36px,5vw,56px)` | 섹션 전환 슬라이드 |
| `.inline-section` | `14px uppercase` | 슬라이드 내 섹션 라벨 |
| `.big-text` | `clamp(40px,6vw,64px)` | 강조 텍스트 |
| `.big-q` | `clamp(24px,3vw,36px)` | 큰 질문 |
| `.key-message` | `20px` | 핵심 메시지 |

---

## 컴포넌트

### Flow (흐름 다이어그램)
```html
<div class="flow [compact]">
  <div class="node [color]">Text</div>
  <div class="arrow">↓</div>
  <div class="node [color]">Text</div>
</div>
```
- Color variants: `cyan`, `purple`, `green`, `gold`, `orange`
- **기본**: `gap: 12px`
- **Compact**: `gap: 8px` (5개 이상 노드 사용 시)

### Section Divider (섹션 전환)
```html
<div class="section-divider">
  <div class="section-label">Part 1</div>
  <div class="section-title">Section Title</div>
  <div class="section-subtitle">Description</div>
</div>
```

### Two Column (2컬럼)
```html
<div class="two-col" style="max-width:640px;">
  <div class="col">
    <div class="col-title">Title</div>
    <div class="col-item [ok|warn]">Item</div>
  </div>
  <div class="col">...</div>
</div>
```
- `gap: 48px`, `max-width: 640px` (overflow 방지)

### Key Message (핵심 메시지)
```html
<div class="key-message">메시지</div>
```
- gold glow 배경 + border
- `max-width: 600px`

### Compare Table (비교표)
```html
<table class="compare-table">
  <thead><tr><th>A</th><th>B</th></tr></thead>
  <tbody><tr><td>...</td><td>...</td></tr></tbody>
</table>
```
- `max-width: 600px`

### Insight Box (인사이트)
```html
<div class="insight-box">메시지</div>
```
- purple border + 배경
- `max-width: 560px`

### Example Box (예시)
```html
<div class="example-box">
  <div class="label">LABEL</div>
  Content
</div>
```
- `border-left: 3px solid var(--accent-cyan)`
- `max-width: 520px`

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
    <div class="number-bar [warn|error]" style="height:40px;">10개</div>
    <span class="number-label">Label</span>
  </div>
</div>
```
- 최대 바 높이: `116px` (overflow 방지)

### Category Grid (3컬럼 그리드)
```html
<div class="category-grid">
  <div class="category-card">
    <h3>Title</h3>
    <p>Description</p>
  </div>
</div>
```
- `max-width: 700px`

### Grid Cards (2x2 그리드)
```html
<div class="grid-cards">
  <div class="grid-card">
    <div class="grid-card-title">Title</div>
    <div class="grid-card-desc">Description</div>
  </div>
</div>
```
- `max-width: 560px`

### Hero (첫 페이지)
```html
<div class="hero">
  <div class="ring">
    <div class="ring-text">02</div>
  </div>
</div>
```
- 모든 강의 첫 페이지에 필수 (1강, 2강 등 컨셉 통일)

### Not Equal (비등호)
```html
<div class="not-equal">
  <span>Left</span>
  <span class="neq-sign">≠</span>
  <span>Right</span>
</div>
```

### Quote (인용문)
```html
<div class="quote">
  Text <span class="hl">highlight</span>
</div>
```

### Feature List
```html
<div class="feature-list">
  <div class="feature-item">
    <div class="feature-icon cyan">M</div>
    Label
  </div>
</div>
```

---

## JS (공통)

### Navigation
- `IntersectionObserver` 기반 (1강 스타일)
- scroll-based (`deck.scrollLeft`)
- Nav dots: `#slide-0`, `#slide-1`, ...

### Keyboard
- `ArrowRight` / `ArrowDown` → 다음 슬라이드
- `ArrowLeft` / `ArrowUp` → 이전 슬라이드

### Notes Toggle
- `📝 Notes` 버튼 (아래 우측)
- `.notes-panel` 토글

---

## 폰트 크기 기준

| 요소 | 크기 |
|:-----|:-----|
| Title | `clamp(40px,6vw,64px)` |
| Subtitle | `clamp(20px,2.5vw,28px)` |
| Section title | `clamp(36px,5vw,56px)` |
| Big text | `clamp(40px,6vw,64px)` |
| Big question | `clamp(24px,3vw,36px)` |
| Key message | `20px` |
| Node | `20px` (compact 시 `16px`) |
| Col item | `18px` (two-col 시 `16px`) |
| Table | `16px` |
| Example box | `18px` |
| Insight box | `18px` |
| Tag | `16px` |
| Slide counter | `12px` |

---

## 규칙

1. **반응형 필수**: title/subtitle/big-text/section-title는 `clamp()` 사용
2. **lecture-badge**: 중앙 상단 고정
3. **slide-counter**: 아래 중앙 고정
4. **first slide**: Hero ring + 숫자 + 타이틀 (1강 스타일 통일)
5. **section-divider**: Part 1/2/3 전환 시 필수 사용
6. **two-col**: `1fr 1fr` (2컬럼), `gap: 48px`, `max-width: 640px`
7. **flow**: `gap: 12px` (기본), `gap: 8px` (compact)
8. **flow nodes**: 최대 4개 (overflow 방지)
9. **key-message**: gold glow
10. **insight-box**: purple
11. **발표자 노트**: 모든 슬라이드에 `data-notes` 포함
12. **slide ID**: `slide-0`, `slide-1`, ... 형식 (0-based)
13. **max-width**: 모든 컨테이너에 overflow 방지용 max-width 설정
14. **number-bar**: 최대 높이 `116px` (overflow 방지)

---

##.overflow-safe

- 슬라이드 콘텐츠가 화면을 벗어나지 않도록
- `max-height: calc(100vh - 200px)` 적용
- `overflow: hidden` 필수
