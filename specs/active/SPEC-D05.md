---
spec_id: SPEC-D05
version: 1.0.0
parent: SPEC-D01
status: approved
changed_at: "2026-06-17T00:00:00Z"
type: design
title: "p-hermes Slides(HTML) 디자인 스펙"
domain: design
tags: [slides, html, css, light-theme, kai-kawasaki]
---

# p-hermes Slides(HTML) 디자인 스펙

> **프로젝트**: p-hermes 핵심 시스템 재정의  
> **작성자**: Hermes Agent (Qwen3.6)  
> **작성일**: 2026-06-16  
> **버전**: 1.0  
> **대상**: 모든 도메인(A1~A6, B1~B2) Slides 문서  
> **표준**: Guy Kawasaki 10-20-30 Rule + 라이트 테마

---

## 목차

1. [디자인 철학](#1-디자인-철학)
2. [색상 팔레트](#2-색상-팔레트)
3. [타이포그래피](#3-타이포그래피)
4. [레이아웃 템플릿 (5종)](#4-레이아웃-템플릿-5종)
5. [그래픽 요소](#5-그래픽-요소)
6. [애니메이션](#6-애니메이션)
7. [슬라이드 구조 (CSS Grid 기반)](#7-슬라이드-구조-css-grid-기반)
8. [Mermaid 다이어그램 스타일](#8-mermaid-다이어그램-스타일)
9. [반응형](#9-반응형)
10. [페이지 네비게이션](#10-페이지-네비게이션)
11. [실제 HTML/CSS 코드 예시](#11-실제-htmlcss-코드-예시)

---

## 1. 디자인 철학

p-hermes Slides는 **시각적 압축**과 **기술적 정확성**을 동시에 추구한다. 텍스트는 최소화하고, 다이어그램·그래픽을 중심으로 핵심 메시지를 전달한다.

| 원칙 | 설명 |
|------|------|
| **Progressive Disclosure** | 한 슬라이드, 한 메시지. 청중이 소화할 수 있는 정보 양만 표시 |
| **10-20-30 Rule** | 최대 10장, 20분 발표, 최소 30pt 본문 |
| **High Contrast** | 라이트 배경 + 짙은 텍스트, 접근성 WCAG AA 이상 |
| **Grid-First** | CSS Grid 기반 레이아웃. 콘텐츠 위치는 고정, 크기는 유연 |
| **No Decorative Noise** | 장식적 그래픽 제거. 모든 시각 요소는 정보 전달에 기여 |

---

## 2. 색상 팔레트

라이트 테마 기반. CSS 커스텀 프로퍼티(CSS 변수)로 전역 관리.

### 2.1 색상 정의

```css
:root {
  /* === 배경 계층 === */
  --bg-primary:    #ffffff;  /* 메인 배경 (흰색) */
  --bg-secondary:  #f6f8fa;  /* 카드/섹션 배경 (GitHub Light) */
  --bg-tertiary:   #eaeef2;  /* 호버/인터랙션 배경 */

  /* === 텍스트 계층 === */
  --text-primary:  #1f2328;  /* 본문/타이틀 (대비비 15:1) */
  --text-secondary:#656d76;  /* 보조 설명/메타 정보 */
  --text-muted:    #b0b5ba;  /* placeholder/비활성 */

  /* === 액센트 색상 === */
  --accent-primary:   #0969da;  /* 블루: 링크, 강조, 핵심 요소 */
  --accent-secondary: #1a7f37;  /* 그린: 성공, 승인, 완료 */
  --accent-warning:   #9a6700;  /* 옐로우: 주의, 경고 */
  --accent-danger:    #cf222e;  /* 레드: 실패, 차단, 오류 */
  --accent-purple:    #8250df;  /* 퍼플: Mermaid 노드, 차트 */
  --accent-orange:    #bc4c00;  /* 오렌지: 중간 단계, 진행 중 */
  --accent-cyan:      #0891b2;  /* 사이안: 데이터 흐름, 연결선 */

  /* === 테두리/선 === */
  --border-default:   #d0d7de;
  --border-accent:    #0969da44;  /* 27% 투명도 */
  --border-focus:     #0969da;

  /* === 그림자 === */
  --shadow-sm: 0 1px 2px rgba(31, 35, 40, 0.1);
  --shadow-md: 0 4px 12px rgba(31, 35, 40, 0.12);
  --shadow-lg: 0 8px 24px rgba(31, 35, 40, 0.14);
  --shadow-glow-blue: 0 0 20px rgba(9, 105, 218, 0.12);
  --shadow-glow-green: 0 0 20px rgba(26, 127, 55, 0.12);

  /* === 투명도 레이어 === */
  --overlay-dim:  rgba(255, 255, 255, 0.85);
  --overlay-mask: rgba(255, 255, 255, 0.95);
}
```

### 2.2 색상 사용 가이드

| 사용처 | 변수 |
|--------|------|
| 슬라이드 전체 배경 | `--bg-primary` |
| 콘텐츠 카드 배경 | `--bg-secondary` |
| 타이틀/본문 텍스트 | `--text-primary` |
| 설명/메타 텍스트 | `--text-secondary` |
| 액티브 링크/버튼 | `--accent-primary` |
| 상태: 성공/완료 | `--accent-secondary` |
| 상태: 진행 중 | `--accent-orange` |
| 상태: 경고 | `--accent-warning` |
| 상태: 오류 | `--accent-danger` |
| Mermaid 노드 | `--accent-purple` |
| 데이터 흐름선 | `--accent-cyan` |

---

## 3. 타이포그래피

### 3.1 폰트 스택

Google Fonts 로드:

```html
<!-- Google Fonts: Inter + Noto Sans KR + JetBrains Mono + Noto Sans Mono KR -->
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&family=Noto+Sans+KR:wght@300;400;500;600;700&family=Noto+Sans+Mono+KR:wght@400;500;600&display=swap" rel="stylesheet">
```

```css
:root {
  /* 시스템 폰트 우선, Google Fonts 폴백 */
  --font-sans: 'Inter', 'Noto Sans KR', -apple-system, BlinkMacSystemFont,
               'Segoe UI', 'Helvetica Neue', Arial, sans-serif;

  --font-mono: 'JetBrains Mono', 'Fira Code', 'Noto Sans Mono KR',
               'SF Mono', 'Cascadia Code', Consolas, monospace;

  --font-heading: var(--font-sans);
}
```

### 3.2 크기 계층 (10-20-30 Rule 기반)

Guy Kawasaki 10-20-30 Rule의 **30pt**를 최솟값으로, 상대 단위(`rem`)로 계층화:

| 역할 | CSS 크기 | px 기준 (16px base) | 사용처 |
|------|----------|---------------------|--------|
| `--text-h1` | `3.0rem` | 48px | 슬라이드 타이틀 |
| `--text-h2` | `2.25rem` | 36px | 섹션 제목 |
| `--text-h3` | `1.75rem` | 28px | 하위 섹션 |
| `--text-body` | `1.25rem` | 20px | 본문 (최소 30pt ≈ 40px는 h1 기준) |
| `--text-small` | `1rem` | 16px | 보조 텍스트 |
| `--text-code` | `0.9rem` | 14.4px | 인라인 코드 |
| `--text-meta` | `0.8rem` | 12.8px | 메타 정보(페이지번호 등) |

```css
:root {
  --text-h1:   3.0rem;
  --text-h2:   2.25rem;
  --text-h3:   1.75rem;
  --text-body: 1.25rem;
  --text-small:1rem;
  --text-code: 0.9rem;
  --text-meta: 0.8rem;

  /* 줄간격 */
  --leading-tight:   1.2;
  --leading-normal:  1.6;
  --leading-relaxed: 1.8;

  /* 자간 */
  --tracking-tight:  -0.02em;
  --tracking-normal: 0;
  --tracking-wide:   0.05em;
}
```

### 3.3 타이포그래피 규칙

- **한 줄당 단어 수**: 최대 8단어 / 12자 (가독성 기준)
- **한 슬라이드 텍스트 라인**: 최대 6라인 (본문 기준)
- **슬라이드 밀도 등급**:
  - Light (개념 소개): 2-4라인
  - Standard (핵심 설명): 4-6라인
  - Dense (구체적 데이터): 6-8라인
- **최소 라인**: 3라인 (과도한 미니멀리즘 방지)
- **헤딩 자간**: `--tracking-tight` (축소, 응집력)
- **본문 자간**: `--tracking-normal` (기본)
- **라벨/버튼 자간**: `--tracking-wide` (확장, 가독성)
- **코드 블록 폰트**: `--font-mono`, `1.05rem`, `--leading-relaxed`
- **한글/영문 혼용 시**: `font-feature-settings: 'calt'` 활성화 (연자음 연결)

---

## 4. 레이아웃 템플릿 (5종)

모든 템플릿은 CSS Grid 12컬럼 시스템 기반으로 구현. 슬라이드 컨테이너는 `aspect-ratio: 16/9` 고정.

### 4.1 타이틀 템플릿

센터얼라이드. 프로젝트명 + 슬라이드 제목 + 부제목.

```
┌─────────────────────────────────┐
│                                 │
│                                 │
│        p-hermes                 │
│    (로고/아이콘)                 │
│                                 │
│      ───                       │
│                                 │
│       WORKFLOW                 │
│       REDEFINED                 │
│                                 │
│   핵심 시스템 재정의             │
│                                 │
│                                 │
│   2026.06  —  v0.16.0          │
│                                 │
└─────────────────────────────────┘
```

**Grid 구성**: 단일 영역, `place-items: center`

```css
.layout-title {
  grid-template-rows: 1fr;
  place-items: center;
  text-align: center;
}
.layout-title .slide-title {
  font-size: var(--text-h1);
  letter-spacing: var(--tracking-wide);
  text-transform: uppercase;
}
.layout-title .slide-subtitle {
  font-size: var(--text-h3);
  color: var(--text-secondary);
  margin-top: 0.5rem;
}
.layout-title .divider {
  width: 6rem;
  height: 3px;
  background: var(--accent-primary);
  margin: 1.5rem auto;
  border-radius: 2px;
}
```

### 4.2 콘텐츠 템플릿

좌측 제목 + 우측 본문. 가장 일반적인 템플릿.

```
┌─────────────────────────────────┐
│  WORKFLOW ARCHITECTURE          │
│                                 │
│  ┌─────────────────────────┐    │
│  │ • 9단계 상태 머신        │    │
│  │ • 원자적 게이트          │    │
│  │ • 병렬 차단             │    │
│  │                          │    │
│  │  request → investigation │    │
│  │  → design → review       │    │
│  │  → approval → execution  │    │
│  └─────────────────────────┘    │
│                                 │
└─────────────────────────────────┘
```

**Grid 구성**: `grid-template-columns: 1fr 2fr`

```css
.layout-content {
  grid-template-columns: 1fr 2fr;
  grid-template-rows: auto 1fr;
  gap: 2rem;
  align-items: start;
  padding-top: 1.5rem;
}
.layout-content .section-header {
  grid-column: 1 / -1;
  border-bottom: 2px solid var(--accent-primary);
  padding-bottom: 0.5rem;
}
.layout-content .content-body {
  font-size: var(--text-body);
  line-height: var(--leading-relaxed);
  color: var(--text-primary);
}
```

### 4.3 다이어그램 템플릿

상단 제목 + 하단 Mermaid/그래픽 풀너.

```
┌─────────────────────────────────┐
│  STATE TRANSITION PIPELINE      │
│                                 │
│  ┌────────────────────────────┐ │
│  │                            │ │
│  │    [Mermaid 다이어그램]    │ │
│  │    (풀너 차지)             │ │
│  │                            │ │
│  └────────────────────────────┘ │
│                                 │
│  상태 전이: 원자적 flock 기반   │
└─────────────────────────────────┘
```

**Grid 구성**: `grid-template-rows: auto 1fr auto`

```css
.layout-diagram {
  grid-template-rows: auto 1fr auto;
  gap: 1rem;
  padding-top: 1rem;
}
.layout-diagram .section-header {
  border-bottom: 2px solid var(--accent-primary);
  padding-bottom: 0.5rem;
}
.layout-diagram .diagram-container {
  background: var(--bg-secondary);
  border: 1px solid var(--border-default);
  border-radius: 8px;
  padding: 1.5rem;
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
}
.layout-diagram .diagram-caption {
  font-size: var(--text-small);
  color: var(--text-secondary);
  text-align: center;
}
```

### 4.4 비교 템플릿

양쪽 대조형. 두 개념/버전/방안을 나란히 배치.

```
┌─────────────────────────────────┐
│  BEFORE vs. AFTER               │
│                                 │
│  ┌──────────────┬──────────────┐ │
│  │   BEFORE     │   AFTER      │ │
│  │  ─────────   │  ─────────   │ │
│  │  수동 승인    │  자동 게이트  │ │
│  │  직렬 처리    │  병렬 차단    │ │
│  │  상태 분산    │  중앙 집중    │ │
│  └──────────────┴──────────────┘ │
│                                 │
└─────────────────────────────────┘
```

**Grid 구성**: `grid-template-columns: 1fr 1fr`, 중앙 구분선 포함

```css
.layout-comparison {
  grid-template-columns: 1fr 1fr;
  grid-template-rows: auto 1fr;
  gap: 0;
  padding-top: 1.5rem;
}
.layout-comparison .section-header {
  grid-column: 1 / -1;
  text-align: center;
  border-bottom: 2px solid var(--border-default);
  padding-bottom: 0.5rem;
}
.layout-comparison .col {
  padding: 1.5rem;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}
.layout-comparison .col-before {
  border-right: 1px solid var(--border-default);
  background: var(--bg-primary);
}
.layout-comparison .col-after {
  background: var(--bg-secondary);
}
.layout-comparison .col-label {
  font-size: var(--text-h3);
  font-weight: 700;
  letter-spacing: var(--tracking-wide);
  margin-bottom: 0.5rem;
}
.layout-comparison .col-before .col-label {
  color: var(--text-muted);
}
.layout-comparison .col-after .col-label {
  color: var(--accent-primary);
}
```

### 4.5 요약 템플릿

핵심 포인트 3개 + 액션 아이템. CTA 강조.

```
┌─────────────────────────────────┐
│  KEY TAKEAWAYS                  │
│                                 │
│  ┌────┐  ┌────┐  ┌────┐       │
│  │ 01 │  │ 02 │  │ 03 │       │
│  │ 상태 │  │ 게이트│  │ 원자성│       │
│  │ 머신 │  │ 체제 │  │        │       │
│  └────┘  └────┘  └────┘       │
│                                 │
│  ───                           │
│                                 │
│  Next: implementation guide     │
│  [docs/wiki/guides/request-task]│
│                                 │
└─────────────────────────────────┘
```

**Grid 구성**: `grid-template-rows: auto auto 1fr`, 3컬럼 카드

```css
.layout-summary {
  grid-template-rows: auto auto 1fr;
  gap: 1.5rem;
  padding-top: 1.5rem;
}
.layout-summary .card-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1rem;
}
.layout-summary .key-card {
  background: var(--bg-secondary);
  border: 1px solid var(--border-default);
  border-radius: 8px;
  padding: 1.25rem;
  text-align: center;
  transition: border-color 0.2s, box-shadow 0.2s;
}
.layout-summary .key-card:hover {
  border-color: var(--accent-primary);
  box-shadow: var(--shadow-glow-blue);
}
.layout-summary .key-number {
  font-size: var(--text-h1);
  font-weight: 800;
  color: var(--accent-primary);
  line-height: 1;
}
.layout-summary .key-label {
  font-size: var(--text-body);
  margin-top: 0.5rem;
  color: var(--text-primary);
}
.layout-summary .cta-link {
  display: inline-block;
  margin-top: 1rem;
  color: var(--accent-primary);
  font-size: var(--text-small);
  text-decoration: none;
  border-bottom: 1px dashed var(--accent-primary);
}
```

---

## 5. 그래픽 요소

### 5.1 모서리 둥글기

| 요소 | `border-radius` |
|------|-----------------|
| 카드/패널 | `8px` |
| 버튼/태그 | `6px` |
| 코드 블록 | `6px` |
| 원형 아이콘 | `50%` |
| 진행 바 | `4px` |

### 5.2 그림자

```css
/* 카드/패널 기본 그림자 */
.card {
  box-shadow: var(--shadow-sm);
}

/* hover 시 강화 */
.card:hover {
  box-shadow: var(--shadow-md);
}

/* 모달/오버레이 */
.modal {
  box-shadow: var(--shadow-lg);
}

/* 액센트 글로우 (Mermaid/차트) */
.diagram-container {
  box-shadow: var(--shadow-glow-blue);
}
```

### 5.3 테두리

```css
/* 기본 카드 테두리 */
.card {
  border: 1px solid var(--border-default);
}

/* 강조 테두리 (선택 상태/액티브) */
.card--accent {
  border-color: var(--accent-primary);
  box-shadow: var(--shadow-glow-blue);
}

/* 상태별 테두리 */
.card--success { border-color: var(--accent-secondary); }
.card--warning { border-color: var(--accent-warning); }
.card--danger  { border-color: var(--accent-danger); }
```

### 5.4 아이콘 스타일

SVG 기반. 단색(linear) 스타일, 두께 `1.5px`.

```html
<!-- 상태 아이콘 예시 (SVG 인라인) -->
<svg class="icon icon--check" width="20" height="20" viewBox="0 0 20 20" fill="none">
  <path d="M4 10l4 4 8-8" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
<svg class="icon icon--arrow" width="20" height="20" viewBox="0 0 20 20" fill="none">
  <path d="M7 4l6 6-6 6" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
<svg class="icon icon--alert" width="20" height="20" viewBox="0 0 20 20" fill="none">
  <path d="M10 3l7 13H3L10 3z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/>
  <line x1="10" y1="8" x2="10" y2="12" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
  <circle cx="10" cy="14.5" r="0.75" fill="currentColor"/>
</svg>
```

```css
.icon {
  display: inline-block;
  vertical-align: middle;
  flex-shrink: 0;
}
.icon--check  { color: var(--accent-secondary); }
.icon--alert  { color: var(--accent-warning); }
.icon--arrow  { color: var(--accent-primary); }
.icon--danger { color: var(--accent-danger); }
```

### 5.5 상태 배지

```css
.badge {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.2em 0.6em;
  border-radius: 6px;
  font-size: var(--text-meta);
  font-weight: 600;
  letter-spacing: var(--tracking-wide);
  text-transform: uppercase;
}
.badge--success { background: #23863626; color: var(--accent-secondary); }
.badge--warning { background: #d2992226; color: var(--accent-warning); }
.badge--danger  { background: #f8514926; color: var(--accent-danger); }
.badge--info    { background: #58a6ff26; color: var(--accent-primary); }
```

---

## 6. 애니메이션

### 6.1 슬라이드 전이

```css
/* 슬라이드 전환: 왼쪽으로 슬라이드 */
.slide {
  opacity: 0;
  transform: translateX(40px);
  transition: opacity 0.4s cubic-bezier(0.4, 0, 0.2, 1),
              transform 0.4s cubic-bezier(0.4, 0, 0.2, 1);
  position: absolute;
  inset: 0;
  pointer-events: none;
}
.slide--active {
  opacity: 1;
  transform: translateX(0);
  pointer-events: auto;
}
.slide--prev {
  transform: translateX(-40px);
}
```

### 6.2 요소 등장 효과

각 요소별 지연 시간(stagger) 적용.

```css
/* fadeInUp: 아래에서 위로 페이드인 */
@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(16px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* stagger 클래스 */
.stagger-item {
  opacity: 0;
  animation: fadeInUp 0.5s cubic-bezier(0.4, 0, 0.2, 1) forwards;
}
.stagger-item:nth-child(1) { animation-delay: 0.1s; }
.stagger-item:nth-child(2) { animation-delay: 0.2s; }
.stagger-item:nth-child(3) { animation-delay: 0.3s; }
.stagger-item:nth-child(4) { animation-delay: 0.4s; }
.stagger-item:nth-child(5) { animation-delay: 0.5s; }
.stagger-item:nth-child(6) { animation-delay: 0.6s; }

/* Progressve disclosure: 클릭/키로 순차 공개 */
.reveal-item {
  opacity: 0;
  transform: translateX(-12px);
  transition: opacity 0.35s ease, transform 0.35s ease;
}
.reveal-item.revealed {
  opacity: 1;
  transform: translateX(0);
}
```

### 6.3 호버 인터랙션

```css
/* 카드 hover */
.card {
  transition: border-color 0.2s, box-shadow 0.2s, transform 0.15s;
}
.card:hover {
  border-color: var(--accent-primary);
  box-shadow: var(--shadow-glow-blue);
  transform: translateY(-1px);
}

/* 링크 hover */
a, .link {
  color: var(--accent-primary);
  text-decoration: none;
  transition: color 0.15s;
}
a:hover, .link:hover {
  color: var(--text-primary);
  text-decoration: underline;
}
```

### 6.4 애니메이션 사용 원칙

| 규칙 | 설명 |
|------|------|
| 지속시간 | 200ms ~ 500ms (짧고 빠름) |
| easing | `cubic-bezier(0.4, 0, 0.2, 1)` 표준 |
| reduced-motion | `prefers-reduced-motion` 미디어 쿼리 존중 |
| 스타게 최대 지연 | 0.6s 초과 금지 |
| 무한 애니메이션 | 사용 금지 (강렬한 주의 아이콘 제외) |

```css
@media (prefers-reduced-motion: reduce) {
  .slide, .stagger-item, .reveal-item, .card {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
    animation-delay: 0ms !important;
  }
}
```

---

## 7. 슬라이드 구조 (CSS Grid 기반)

### 7.1 전체 페이지 구조

```
┌──────────────────────────────────────────┐
│ <body>                                   │
│  ┌────────────────────────────────────┐  │
│  │ <div class="slides">               │  │
│  │   ┌────────────────────────────┐   │  │
│  │   │ <section class="slide">    │   │  │
│  │   │  <header> 타이틀          │   │  │
│  │   │  <main>  콘텐츠           │   │  │
│  │   │  <footer> 페이지 정보      │   │  │
│  │   │ </section>                 │   │  │
│  │   └────────────────────────────┘   │  │
│  │   ┌────────────────────────────┐   │  │
│  │   │ <section class="slide">    │   │  │
│  │   │ ...                        │   │  │
│  │   │ </section>                 │   │  │
│  │   └────────────────────────────┘   │  │
│  │ </div>                             │  │
│  │                                    │  │
│  │ <nav class="progress-bar">        │  │
│  │  <div class="progress-fill">      │  │
│  │  </div>                           │  │
│  │ </nav>                            │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

### 7.2 슬라이드 컨테이너

```css
/* 슬라이드 전체: 16:9 비율 고정 */
.slide {
  aspect-ratio: 16 / 9;
  display: grid;
  grid-template-rows: auto 1fr auto;
  grid-template-columns: 1fr;
  padding: clamp(1.5rem, 3vw, 3rem);
  background: var(--bg-primary);
  color: var(--text-primary);
  font-family: var(--font-sans);
  position: relative;
  overflow: hidden;
}

/* 섹션 헤더 */
.slide > header {
  display: flex;
  align-items: baseline;
  gap: 1rem;
  padding-bottom: 0.75rem;
  border-bottom: 2px solid var(--accent-primary);
}
.slide > header h1 {
  font-size: var(--text-h2);
  font-weight: 700;
  letter-spacing: var(--tracking-tight);
  margin: 0;
}

/* 메인 콘텐츠 */
.slide > main {
  display: grid;
  gap: 1.5rem;
  padding: 1rem 0;
  overflow-y: auto;
}

/* 푸터: 페이지 번호 */
.slide > footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: var(--text-meta);
  color: var(--text-muted);
}
```

---

## 8. Mermaid 다이어그램 스타일

### 8.1 기본 설정

```javascript
// Mermaid 초기화 (슬라이드 내 <script>에서 호출)
mermaid.initialize({
  startOnLoad: true,
  theme: 'default',
  themeVariables: {
    // 노드 색상
    primaryColor: '#e1ecf4',         /* --accent-primary 기반 */
    primaryTextColor: '#1f2328',     /* --text-primary */
    primaryBorderColor: '#8250df',   /* --accent-purple */

    // 선 색상
    lineColor: '#0891b2',            /* --accent-cyan */

    // 배경
    background: 'transparent',       /* 슬라이드 배경에 투명 */
    nodeBkg: '#f6f8fa',              /* --bg-secondary */
    clusterBkg: '#eaeef2',           /* --bg-tertiary */
    clusterBorder: '#d0d7de',        /* --border-default */

    // 텍스트
    fontSize: '16px',
    fontFamily: "'Inter', 'Noto Sans KR', sans-serif",
  },
  flowchart: {
    htmlLabels: true,
    curve: 'basis',                  /* 부드러운 곡선 */
    padding: 15,
    nodeSpacing: 30,
    rankSpacing: 50,
  },
  sequence: {
    diagramMarginX: 50,
    diagramMarginY: 30,
    actorMargin: 50,
    width: 150,
    height: 65,
    boxMargin: 10,
    messageMargin: 40,
  },
  gantt: {
    topPadding: 50,
    leftPadding: 75,
    gridLineStartPadding: 35,
    fontSize: 14,
    numberSectionStyles: 4,
    axisFormat: '%m/%d',
  },
});
```

### 8.2 CSS 오버라이드 (Mermaid SVG 요소)

```css
/* Mermaid 노드 스타일 오버라이드 */
.mermaid svg rect {
  rx: 6px;
  ry: 6px;
}

/* 특정 클래스로 노드 강조 */
.mermaid .node rect,
.mermaid .node circle {
  stroke-width: 2px;
}

/* 상태 머신 다이어그램 - 상태별 색상 */
.mermaid .state-active rect {
  stroke: var(--accent-secondary) !important;
  stroke-width: 3px !important;
  filter: drop-shadow(0 0 8px rgba(63, 185, 80, 0.3));
}

.mermaid .state-blocked rect {
  stroke: var(--accent-danger) !important;
  stroke-width: 3px !important;
}

/* 플로우차트 - 액센트 노드 */
.mermaid .node--accent {
  fill: var(--accent-purple) !important;
  stroke: var(--accent-cyan) !important;
}

/* 클러스터(서브그래프) */
.mermaid .cluster rect {
  stroke-dasharray: 4 4;
  stroke-opacity: 0.6;
}
```

### 8.3 Mermaid 사용 패턴

**플로우차트 예시** (워크플로우 상태 전이):

```html
<div class="mermaid">
flowchart LR
    A[request] --> B[investigation]
    B --> C[design]
    C --> D[review]
    D --> E[approval]
    E --> F[execution]
    F --> G[test]
    G --> H[execution_review]
    H --> I[done]

    style A fill:#2d2b55,stroke:#bc8cff,color:#e6edf3
    style I fill:#238636,stroke:#3fb950,color:#e6edf3
</div>
```

**상태 다이어그램 예시**:

```html
<div class="mermaid">
stateDiagram-v2
    [*] --> request
    request --> investigation
    investigation --> design
    design --> review
    review --> approval : 승인 게이트
    approval --> execution
    execution --> test
    test --> execution_review
    execution_review --> done
    done --> [*]
</div>
```

---

## 9. 반응형

### 9.1 뷰포트 설정

```html
<meta name="viewport" content="width=device-width, initial-scale=1.0">
```

### 9.2 브레이크포인트

| 클래스 | 조건 | 용도 |
|--------|------|------|
| 기본 | 모든 크기 | 16:9 슬라이드 데스크탑 |
| `--tablet` | `max-width: 1024px` | 태블릿: 레이아웃 간소화 |
| `--mobile` | `max-width: 768px` | 모바일: 세로 스크롤 폴백 |

### 9.3 반응형 CSS

```css
/* 기본: 16:9 고정 */
.slide {
  aspect-ratio: 16 / 9;
  width: 100%;
  max-width: 1600px;
  margin: 0 auto;
}

/* 태블릿: 패딩 축소, 카드 2→1열 */
@media (max-width: 1024px) {
  .slide {
    padding: 1.5rem;
  }
  .layout-comparison {
    grid-template-columns: 1fr;
    grid-template-rows: auto auto auto;
  }
  .layout-comparison .col-before {
    border-right: none;
    border-bottom: 1px solid var(--border-default);
  }
  .layout-summary .card-row {
    grid-template-columns: repeat(2, 1fr);
  }
  .slide > header h1 {
    font-size: var(--text-h3);
  }
}

/* 모바일: 세로 스크롤 폴백 */
@media (max-width: 768px) {
  .slide {
    aspect-ratio: unset;
    min-height: 100vh;
    padding: 1rem;
  }
  .layout-content {
    grid-template-columns: 1fr;
  }
  .layout-summary .card-row {
    grid-template-columns: 1fr;
  }
  .slide > header h1 {
    font-size: var(--text-h3);
  }
  .slide > main {
    font-size: var(--text-small);
  }
  .diagram-container {
    overflow-x: auto;
  }
  .mermaid svg {
    max-width: 100%;
    height: auto;
  }
}
```

---

## 10. 페이지 네비게이션

### 10.1 진행 바

슬라이드 하단에 고정. 현재 슬라이드 비율 표시.

```css
.progress-bar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  height: 3px;
  background: var(--bg-tertiary);
  z-index: 100;
}
.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--accent-primary), var(--accent-purple));
  transition: width 0.4s cubic-bezier(0.4, 0, 0.2, 1);
  border-radius: 0 2px 2px 0;
}
```

### 10.2 페이지 번호

슬라이드 푸터 우측.

```css
.page-number {
  font-size: var(--text-meta);
  color: var(--text-muted);
  font-variant-numeric: tabular-nums;
}
.page-number::before {
  content: '';
  display: inline-block;
  width: 4px;
  height: 4px;
  border-radius: 50%;
  background: var(--accent-primary);
  margin-right: 0.5rem;
  vertical-align: middle;
}
```

### 10.3 키보드 네비게이션

```javascript
document.addEventListener('keydown', (e) => {
  const slides = document.querySelectorAll('.slide');
  const current = document.querySelector('.slide--active');
  const idx = Array.from(slides).indexOf(current);

  if (e.key === 'ArrowRight' || e.key === ' ') {
    e.preventDefault();
    goToSlide(Math.min(idx + 1, slides.length - 1));
  } else if (e.key === 'ArrowLeft' || e.key === 'Backspace') {
    e.preventDefault();
    goToSlide(Math.max(idx - 1, 0));
  } else if (e.key === 'Home') {
    e.preventDefault();
    goToSlide(0);
  } else if (e.key === 'End') {
    e.preventDefault();
    goToSlide(slides.length - 1);
  }
});

function goToSlide(index) {
  const slides = document.querySelectorAll('.slide');
  slides.forEach((s, i) => {
    s.classList.toggle('slide--active', i === index);
    if (i < index) s.classList.add('slide--prev');
    else s.classList.remove('slide--prev');
  });
  // 진행 바 업데이트
  const fill = document.querySelector('.progress-fill');
  fill.style.width = `${((index + 1) / slides.length) * 100}%`;
}
```

### 10.4 슬라이드 썸네일 사이드바 (선택)

```css
.sidebar {
  position: fixed;
  top: 0;
  right: 0;
  width: 4px;
  height: 100vh;
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding: 4px 0;
  z-index: 100;
  background: var(--bg-tertiary);
}
.sidebar-dot {
  flex: 1;
  border-radius: 2px;
  background: var(--border-default);
  cursor: pointer;
  transition: background 0.2s;
}
.sidebar-dot:hover {
  background: var(--accent-primary);
}
.sidebar-dot.active {
  background: var(--accent-primary);
  box-shadow: 0 0 6px var(--accent-primary);
}
```

---

## 11. 실제 HTML/CSS 코드 예시

### 11.1 완전한 슬라이드 HTML 템플릿

```html
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>p-hermes: Workflow Redefined</title>

  <!-- 폰트 -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&family=Noto+Sans+KR:wght@300;400;500;600;700&family=Noto+Sans+Mono+KR:wght@400;500;600&display=swap" rel="stylesheet">

  <!-- Mermaid JS -->
  <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>

  <!-- 디자인 스펙 CSS -->
  <link rel="stylesheet" href="./slides-spec.css">

  <style>
    /* 인라인 CSS 변수 (프로젝트별 커스터마이징) */
    :root {
      --bg-primary:   #ffffff;
      --bg-secondary: #f6f8fa;
      --bg-tertiary:  #eaeef2;
      --text-primary: #1f2328;
      --text-secondary:#656d76;
      --text-muted:   #b0b5ba;
      --accent-primary:   #0969da;
      --accent-secondary: #1a7f37;
      --accent-warning:   #9a6700;
      --accent-danger:    #cf222e;
      --accent-purple:    #8250df;
      --accent-orange:    #bc4c00;
      --accent-cyan:      #0891b2;
      --border-default:   #d0d7de;
      --shadow-glow-blue: 0 0 20px rgba(9, 105, 218, 0.12);
    }
  </style>
</head>
<body>

<!-- YAML 프런트매터 (HTML 주석 또는 별도 .yaml 파일) -->
<!--
---
id: DOC-A1-slides
domain: workflow
type: slides
title: "Workflow Redefined: 핵심 워크플로우 시스템"
date: 2026-06-16
version: "1.0"
compatibility: v0.16.0
---
-->

<div class="slides">

  <!-- 슬라이드 1: 타이틀 -->
  <section class="slide layout-title slide--active" data-slide="1">
    <div class="title-content">
      <p class="project-label">p-hermes</p>
      <div class="divider"></div>
      <h1 class="slide-title">Workflow Redefined</h1>
      <p class="slide-subtitle">핵심 워크플로우 시스템 재정의</p>
      <p class="slide-meta">2026.06 — v0.16.0</p>
    </div>
    <footer>
      <span class="slide-id">DOC-A1-slides</span>
      <span class="page-number">1 / 10</span>
    </footer>
  </section>

  <!-- 슬라이드 2: 콘텐츠 (핵심 개념) -->
  <section class="slide layout-content" data-slide="2">
    <header>
      <h1>9단계 상태 머신</h1>
    </header>
    <main>
      <div class="content-body">
        <ul class="stagger-list">
          <li class="reveal-item stagger-item">
            <span class="icon icon--arrow"></span>
            <strong>준비</strong> — request → investigation → design
          </li>
          <li class="reveal-item stagger-item">
            <span class="icon icon--arrow"></span>
            <strong>실행</strong> — review → approval → execution → test
          </li>
          <li class="reveal-item stagger-item">
            <span class="icon icon--arrow"></span>
            <strong>완료</strong> — execution_review → done
          </li>
          <li class="reveal-item stagger-item">
            <span class="icon icon--check"></span>
            각 전이는 <code>workflow-gate.sh</code> 원자적 검증
          </li>
        </ul>
      </div>
    </main>
    <footer>
      <span class="slide-id">DOC-A1-slides</span>
      <span class="page-number">2 / 10</span>
    </footer>
  </section>

  <!-- 슬라이드 3: 다이어그램 (Mermaid) -->
  <section class="slide layout-diagram" data-slide="3">
    <header>
      <h1>상태 전이 파이프라인</h1>
    </header>
    <main>
      <div class="diagram-container">
        <div class="mermaid">
flowchart LR
    subgraph 준비 ["준비 단계"]
        A[request] --> B[investigation]
        B --> C[design]
    end
    subgraph 실행 ["실행 단계"]
        C --> D[review]
        D --> E[approval]
        E --> F[execution]
        F --> G[test]
    end
    subgraph 완료 ["완료 단계"]
        G --> H[execution_review]
        H --> I[done]
    end
        </div>
      </div>
      <p class="diagram-caption">workflow-gate.sh를 통한 원자적 상태 전이 검증</p>
    </main>
    <footer>
      <span class="slide-id">DOC-A1-slides</span>
      <span class="page-number">3 / 10</span>
    </footer>
  </section>

  <!-- 슬라이드 4: 비교 (Before / After) -->
  <section class="slide layout-comparison" data-slide="4">
    <header>
      <h1>기존 vs. 재정의</h1>
    </header>
    <main>
      <div class="col col-before">
        <p class="col-label">기존</p>
        <ul class="stagger-list">
          <li class="stagger-item">수동 승인 프로세스</li>
          <li class="stagger-item">직렬 처리만 가능</li>
          <li class="stagger-item">상태 정보 분산 저장</li>
          <li class="stagger-item">오류 시 수동 복구</li>
        </ul>
      </div>
      <div class="col col-after">
        <p class="col-label">재정의</p>
        <ul class="stagger-list">
          <li class="stagger-item"><span class="icon icon--check"></span> 자동 게이트 체제</li>
          <li class="stagger-item"><span class="icon icon--check"></span> 병렬 실행 차단 (flock)</li>
          <li class="stagger-item"><span class="icon icon--check"></span> `.workflow-state` 중앙 집중</li>
          <li class="stagger-item"><span class="icon icon--check"></span> 자동 롤백 지원</li>
        </ul>
      </div>
    </main>
    <footer>
      <span class="slide-id">DOC-A1-slides</span>
      <span class="page-number">4 / 10</span>
    </footer>
  </section>

  <!-- 슬라이드 5: 요약 -->
  <section class="slide layout-summary" data-slide="5">
    <header>
      <h1>Key Takeaways</h1>
    </header>
    <main>
      <div class="card-row">
        <div class="key-card stagger-item">
          <p class="key-number">01</p>
          <p class="key-label">9단계 상태 머신<br><small style="color:var(--text-secondary)">3개 그룹으로 구조화</small></p>
        </div>
        <div class="key-card stagger-item">
          <p class="key-number">02</p>
          <p class="key-label">원자적 게이트 체제<br><small style="color:var(--text-secondary)">workflow-gate.sh + flock</small></p>
        </div>
        <div class="key-card stagger-item">
          <p class="key-number">03</p>
          <p class="key-label">중앙 집중 상태 관리<br><small style="color:var(--text-secondary)">.workflow-state JSON</small></p>
        </div>
      </div>
      <a class="cta-link" href="docs/wiki/guides/request-task.md">
        → Implementation Guide 읽기 (Wiki)
      </a>
    </main>
    <footer>
      <span class="slide-id">DOC-A1-slides</span>
      <span class="page-number">5 / 10</span>
    </footer>
  </section>

</div>

<!-- 진행 바 -->
<nav class="progress-bar">
  <div class="progress-fill" style="width: 20%"></div>
</nav>

<!-- 사이드바 점 네비게이션 -->
<nav class="sidebar">
  <span class="sidebar-dot active" data-target="1"></span>
  <span class="sidebar-dot" data-target="2"></span>
  <span class="sidebar-dot" data-target="3"></span>
  <span class="sidebar-dot" data-target="4"></span>
  <span class="sidebar-dot" data-target="5"></span>
</nav>

<script>
  // Mermaid 초기화
  mermaid.initialize({
    startOnLoad: true,
    theme: 'default',
    themeVariables: {
      primaryColor: '#e1ecf4',
      primaryTextColor: '#1f2328',
      primaryBorderColor: '#8250df',
      lineColor: '#0891b2',
      background: 'transparent',
      nodeBkg: '#f6f8fa',
      clusterBkg: '#eaeef2',
      clusterBorder: '#d0d7de',
      fontSize: '14px',
    },
    flowchart: { htmlLabels: true, curve: 'basis' },
  });

  // 슬라이드 네비게이션
  document.addEventListener('keydown', (e) => {
    const slides = [...document.querySelectorAll('.slide')];
    const cur = slides.findIndex(s => s.classList.contains('slide--active'));
    let next = cur;

    if (e.key === 'ArrowRight' || e.key === ' ') { e.preventDefault(); next = Math.min(cur + 1, slides.length - 1); }
    else if (e.key === 'ArrowLeft' || e.key === 'Backspace') { e.preventDefault(); next = Math.max(cur - 1, 0); }

    if (next !== cur) {
      slides.forEach((s, i) => {
        s.classList.toggle('slide--active', i === next);
        s.classList.toggle('slide--prev', i < next);
      });
      document.querySelector('.progress-fill').style.width = `${((next + 1) / slides.length) * 100}%`;
      document.querySelectorAll('.sidebar-dot').forEach((d, i) => {
        d.classList.toggle('active', i === next);
      });
    }
  });

  // 사이드바 클릭
  document.querySelectorAll('.sidebar-dot').forEach(dot => {
    dot.addEventListener('click', () => {
      const target = parseInt(dot.dataset.target) - 1;
      const slides = [...document.querySelectorAll('.slide')];
      slides.forEach((s, i) => {
        s.classList.toggle('slide--active', i === target);
        s.classList.toggle('slide--prev', i < target);
      });
      document.querySelector('.progress-fill').style.width = `${((target + 1) / slides.length) * 100}%`;
      document.querySelectorAll('.sidebar-dot').forEach((d, i) => {
        d.classList.toggle('active', i === target);
      });
    });
  });

  // Progressive disclosure (스페이스/엔터로 요소 순차 공개)
  document.querySelectorAll('.layout-content, .layout-comparison').forEach(section => {
    section.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' || e.key === '.') {
        e.preventDefault();
        const items = section.querySelectorAll('.reveal-item:not(.revealed)');
        if (items.length) items[0].classList.add('revealed');
      }
    });
  });
</script>

</body>
</html>
```

---

## 부록: CSS 파일 전체 (`slides-spec.css`)

```css
/* ============================================================
 * p-hermes Slides Design Spec — CSS
 * 라이트 테마 기반 | 16:9 | CSS Grid | Mermaid 지원
 * ============================================================ */

/* === 커스텀 프로퍼티 === */
:root {
  --bg-primary:   #0d1117;
  --bg-secondary: #161b22;
  --bg-tertiary:  #21262d;
  --text-primary: #e6edf3;
  --text-secondary:#8b949e;
  --text-muted:   #484f58;
  --accent-primary:   #58a6ff;
  --accent-secondary: #3fb950;
  --accent-warning:   #d29922;
  --accent-danger:    #f85149;
  --accent-purple:    #bc8cff;
  --accent-orange:    #f0883e;
  --accent-cyan:      #39d2c0;
  --border-default:   #30363d;
  --shadow-sm:        0 1px 2px rgba(0,0,0,0.3);
  --shadow-md:        0 4px 12px rgba(0,0,0,0.4);
  --shadow-lg:        0 8px 24px rgba(0,0,0,0.5);
  --shadow-glow-blue: 0 0 20px rgba(88,166,255,0.15);
  --font-sans: 'Inter', 'Noto Sans KR', -apple-system, BlinkMacSystemFont,
               'Segoe UI', 'Helvetica Neue', Arial, sans-serif;
  --font-mono: 'JetBrains Mono', 'Fira Code', 'Noto Sans Mono KR',
               'SF Mono', 'Cascadia Code', Consolas, mononed;
  --text-h1:   3.0rem;
  --text-h2:   2.25rem;
  --text-h3:   1.75rem;
  --text-body: 1.25rem;
  --text-small: 1rem;
  --text-code: 0.9rem;
  --text-meta: 0.8rem;
  --leading-tight:   1.2;
  --leading-normal:  1.6;
  --leading-relaxed: 1.8;
  --tracking-tight:  -0.02em;
  --tracking-normal: 0;
  --tracking-wide:   0.05em;
}

/* === 글로벌 === */
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

body {
  background: var(--bg-primary);
  color: var(--text-primary);
  font-family: var(--font-sans);
  font-size: var(--text-body);
  line-height: var(--leading-normal);
  overflow: hidden;
}

code {
  font-family: var(--font-mono);
  font-size: var(--text-code);
  background: var(--bg-tertiary);
  padding: 0.15em 0.4em;
  border-radius: 4px;
}

/* === 슬라이드 컨테이너 === */
.slides {
  position: relative;
  width: 100vw;
  height: 100vh;
}

.slide {
  aspect-ratio: 16 / 9;
  width: 100%;
  max-width: 1600px;
  margin: 0 auto;
  display: grid;
  grid-template-rows: auto 1fr auto;
  padding: clamp(1.5rem, 3vw, 3rem);
  background: var(--bg-primary);
  position: absolute;
  inset: 0;
  opacity: 0;
  transform: translateX(40px);
  transition: opacity 0.4s cubic-bezier(0.4,0,0.2,1),
              transform 0.4s cubic-bezier(0.4,0,0.2,1);
  pointer-events: none;
  overflow: hidden;
}

.slide--active {
  opacity: 1;
  transform: translateX(0);
  pointer-events: auto;
}

.slide--prev {
  transform: translateX(-40px);
}

.slide > header {
  display: flex;
  align-items: baseline;
  gap: 1rem;
  padding-bottom: 0.75rem;
  border-bottom: 2px solid var(--accent-primary);
}

.slide > header h1 {
  font-size: var(--text-h2);
  font-weight: 700;
  letter-spacing: var(--tracking-tight);
}

.slide > main {
  display: grid;
  gap: 1.5rem;
  padding: 1rem 0;
  overflow-y: auto;
}

.slide > footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: var(--text-meta);
  color: var(--text-muted);
}

/* === 템플릿: 타이틀 === */
.layout-title {
  place-items: center;
  text-align: center;
}
.layout-title .slide-title {
  font-size: var(--text-h1);
  font-weight: 800;
  letter-spacing: var(--tracking-wide);
  text-transform: uppercase;
}
.layout-title .slide-subtitle {
  font-size: var(--text-h3);
  color: var(--text-secondary);
  margin-top: 0.5rem;
}
.layout-title .project-label {
  font-size: var(--text-small);
  color: var(--accent-primary);
  letter-spacing: var(--tracking-wide);
  text-transform: uppercase;
  margin-bottom: 1rem;
}
.layout-title .divider {
  width: 6rem;
  height: 3px;
  background: var(--accent-primary);
  margin: 1.5rem auto;
  border-radius: 2px;
}
.layout-title .slide-meta {
  font-size: var(--text-small);
  color: var(--text-muted);
  margin-top: 2rem;
}

/* === 템플릿: 콘텐츠 === */
.layout-content {
  grid-template-columns: 1fr 2fr;
  grid-template-rows: auto 1fr;
  gap: 2rem;
}
.layout-content .section-header {
  grid-column: 1 / -1;
}

/* === 템플릿: 다이어그램 === */
.layout-diagram {
  grid-template-rows: auto 1fr auto;
  gap: 1rem;
}
.diagram-container {
  background: var(--bg-secondary);
  border: 1px solid var(--border-default);
  border-radius: 8px;
  padding: 1.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}
.diagram-caption {
  font-size: var(--text-small);
  color: var(--text-secondary);
  text-align: center;
}

/* === 템플릿: 비교 === */
.layout-comparison {
  grid-template-columns: 1fr 1fr;
  grid-template-rows: auto 1fr;
}
.layout-comparison .section-header {
  grid-column: 1 / -1;
  text-align: center;
}
.layout-comparison .col {
  padding: 1.5rem;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}
.layout-comparison .col-before {
  border-right: 1px solid var(--border-default);
}
.layout-comparison .col-after {
  background: var(--bg-secondary);
}
.layout-comparison .col-label {
  font-size: var(--text-h3);
  font-weight: 700;
  letter-spacing: var(--tracking-wide);
}
.layout-comparison .col-before .col-label { color: var(--text-muted); }
.layout-comparison .col-after .col-label { color: var(--accent-primary); }

/* === 템플릿: 요약 === */
.layout-summary {
  grid-template-rows: auto auto 1fr;
  gap: 1.5rem;
}
.layout-summary .card-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1rem;
}
.key-card {
  background: var(--bg-secondary);
  border: 1px solid var(--border-default);
  border-radius: 8px;
  padding: 1.25rem;
  text-align: center;
  transition: border-color 0.2s, box-shadow 0.2s;
}
.key-card:hover {
  border-color: var(--accent-primary);
  box-shadow: var(--shadow-glow-blue);
}
.key-number {
  font-size: var(--text-h1);
  font-weight: 800;
  color: var(--accent-primary);
  line-height: 1;
}
.key-label {
  font-size: var(--text-body);
  margin-top: 0.5rem;
}
.cta-link {
  display: inline-block;
  margin-top: 1rem;
  color: var(--accent-primary);
  text-decoration: none;
  border-bottom: 1px dashed var(--accent-primary);
  transition: color 0.15s;
}
.cta-link:hover {
  color: var(--text-primary);
}

/* === 애니메이션 === */
@keyframes fadeInUp {
  from { opacity: 0; transform: translateY(16px); }
  to   { opacity: 1; transform: translateY(0); }
}
.stagger-item {
  opacity: 0;
  animation: fadeInUp 0.5s cubic-bezier(0.4,0,0.2,1) forwards;
}
.stagger-item:nth-child(1) { animation-delay: 0.1s; }
.stagger-item:nth-child(2) { animation-delay: 0.2s; }
.stagger-item:nth-child(3) { animation-delay: 0.3s; }
.stagger-item:nth-child(4) { animation-delay: 0.4s; }
.stagger-item:nth-child(5) { animation-delay: 0.5s; }
.stagger-item:nth-child(6) { animation-delay: 0.6s; }

.reveal-item {
  opacity: 0;
  transform: translateX(-12px);
  transition: opacity 0.35s ease, transform 0.35s ease;
}
.reveal-item.revealed {
  opacity: 1;
  transform: translateX(0);
}

/* === 아이콘 === */
.icon {
  display: inline-block;
  vertical-align: middle;
  flex-shrink: 0;
  width: 1.2em;
  height: 1.2em;
}
.icon--check  { color: var(--accent-secondary); }
.icon--alert  { color: var(--accent-warning); }
.icon--arrow  { color: var(--accent-primary); }
.icon--danger { color: var(--accent-danger); }

/* === 배지 === */
.badge {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.2em 0.6em;
  border-radius: 6px;
  font-size: var(--text-meta);
  font-weight: 600;
  letter-spacing: var(--tracking-wide);
  text-transform: uppercase;
}
.badge--success { background: #23863626; color: var(--accent-secondary); }
.badge--warning { background: #d2992226; color: var(--accent-warning); }
.badge--danger  { background: #f8514926; color: var(--accent-danger); }
.badge--info    { background: #58a6ff26; color: var(--accent-primary); }

/* === 진행 바 === */
.progress-bar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  height: 3px;
  background: var(--bg-tertiary);
  z-index: 100;
}
.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--accent-primary), var(--accent-purple));
  transition: width 0.4s cubic-bezier(0.4,0,0.2,1);
  border-radius: 0 2px 2px 0;
}

/* === 사이드바 네비게이션 === */
.sidebar {
  position: fixed;
  top: 0;
  right: 0;
  width: 4px;
  height: 100vh;
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding: 4px 0;
  z-index: 100;
  background: var(--bg-tertiary);
}
.sidebar-dot {
  flex: 1;
  border-radius: 2px;
  background: var(--border-default);
  cursor: pointer;
  transition: background 0.2s, box-shadow 0.2s;
}
.sidebar-dot:hover { background: var(--accent-primary); }
.sidebar-dot.active {
  background: var(--accent-primary);
  box-shadow: 0 0 6px var(--accent-primary);
}

/* === 페이지 번호 === */
.page-number {
  font-variant-numeric: tabular-nums;
}
.page-number::before {
  content: '';
  display: inline-block;
  width: 4px;
  height: 4px;
  border-radius: 50%;
  background: var(--accent-primary);
  margin-right: 0.5rem;
  vertical-align: middle;
}

/* === 반응형 === */
@media (max-width: 1024px) {
  .slide { padding: 1.5rem; }
  .layout-comparison {
    grid-template-columns: 1fr;
    grid-template-rows: auto auto auto;
  }
  .layout-comparison .col-before {
    border-right: none;
    border-bottom: 1px solid var(--border-default);
  }
  .layout-summary .card-row {
    grid-template-columns: repeat(2, 1fr);
  }
  .slide > header h1 { font-size: var(--text-h3); }
}

@media (max-width: 768px) {
  .slide {
    aspect-ratio: unset;
    min-height: 100vh;
    padding: 1rem;
  }
  .layout-content, .layout-comparison {
    grid-template-columns: 1fr;
  }
  .layout-summary .card-row { grid-template-columns: 1fr; }
  .slide > header h1 { font-size: var(--text-h3); }
  .diagram-container { overflow-x: auto; }
  .mermaid svg { max-width: 100%; height: auto; }
}

/* === 접근성: 움직임 감소 === */
@media (prefers-reduced-motion: reduce) {
  .slide, .stagger-item, .reveal-item,
  .key-card, .progress-fill, .sidebar-dot {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
    animation-delay: 0ms !important;
  }
}
```

---

## 12. 링크 경로 규칙 (GitHub Pages 배포용)

Slides는 HTML 파일로 GitHub Pages를 통해 배포됩니다. 링크 경로는 다음과 같이 통일합니다.

### 12.1 링크 유형별 규칙

| 링크 유형 | 형식 | 예시 |
|-----------|------|------|
| **동일 슬라이드 내 섹션** | `#section-id` | `#architecture` |
| **동일 슬라이드 내 다른 슬라이드** | JavaScript `goToSlide()` | (내부 네비게이션) |
| **다른 도메인 (Wiki/Blog)** | `/docs/` 루트 기준 절대경로 | `href="/docs/wiki/guides/request-task.html"` |
| **GitHub 소스 파일** | `https://github.com/...` | `https://github.com/pheanor/p-hermes/blob/main/scripts/workflow-gate.sh` |
| **외부 URL** | `https://` + `target="_blank"` | `https://mermaid.js.org` |

### 12.2 HTML 구현

```html
<!-- 내부 문서 링크 (루트 기준 절대경로) -->
<a href="/docs/wiki/guides/request-task.html" class="cta-link">
  → Wiki: Workflow 가이드 읽기
</a>

<!-- 외부 링크 (새 탭 + 보안 속성) -->
<a href="https://mermaid.js.org" target="_blank" rel="noopener noreferrer" class="external-link">
  Mermaid.js 공식 문서 ↗
</a>

<!-- 동일 슬라이드 내 섹션 -->
<a href="#architecture">아키텍처 섹션으로</a>

<!-- GitHub 소스 코드 참조 -->
<a href="https://github.com/pheanor/p-hermes/blob/main/scripts/workflow-gate.sh"
   target="_blank" rel="noopener noreferrer" class="external-link">
  workflow-gate.sh 소스 ↗
</a>
```

```css
/* 외부 링크 시각적 구분 */
.external-link::after {
  content: " ↗";
  opacity: 0.5;
  font-size: 0.8em;
}

/* CTA 링크 (내부 문서) */
.cta-link {
  display: inline-block;
  margin-top: 1rem;
  color: var(--accent-primary);
  font-size: var(--text-small);
  text-decoration: none;
  border-bottom: 1px dashed var(--accent-primary);
}
.cta-link:hover {
  color: var(--text-primary);
}
```

### 12.3 절대 URL 금지

```html
<!-- ❌ 금지: 도메인 명시적 포함 -->
<a href="https://pheanor.github.io/p-hermes/docs/wiki/guides/request-task.html">
  Wiki 가이드
</a>

<!-- ✅ 권장: 루트 기준 절대경로 -->
<a href="/docs/wiki/guides/request-task.html">
  Wiki 가이드
</a>
```

> **이유**: 도메인 변경 시 모든 링크 수정 필요. CI/CD 파이프라인과 GitHub Pages 설정에서 자동 처리됨.

### 12.4 base 태그 활용 (선택)

```html
<head>
  <!-- GitHub Pages 기본 경로 명시 -->
  <base href="/p-hermes/">
  <!-- 또는 커스텀 도메인 사용 시 -->
  <!-- <base href="/"> -->
</head>
```

> **주의**: `<base>` 태그 사용 시 모든 상대경로가 해당 기본 URL에 결합됨. Wiki/Blog 링크도 자동으로 처리되므로 `./` 대신 `/docs/` 경로만 유지하면 됨.

---

## 변경 이력

| 버전 | 날짜 | 내용 |
|------|------|------|
| 1.0 | 2026-06-16 | 초안 작성: 라이트 테마 기반 슬라이드 디자인 스펙 전체 정의 |
| 1.1 | 2026-06-16 | 문서 간 링크 규칙 추가 (GitHub Pages 배포용) |

## 관련 문서

- [document-requirements.md](./document-requirements.md) — 문서 작성 요구사항 명세서
- [A1. Workflow Wiki 가이드](docs/wiki/guides/request-task.md) (Wiki)
- [A1. Workflow Blog](docs/blog/workflow-architecture.md) (Blog)

---

## Contract

contract:
  precondition:
    - GitHub Pages 환경 설정 완료
    - Mermaid JS CDN 또는 로컬 빌드 준비
    - Google Fonts 또는 로컬 폰트 설치
  postcondition:
    - HTML Slides 24개 (8도메인×3매체) 렌더링 성공
    - 16:9 비율 유지
    - 키보드 네비게이션 동작 확인
  invariant:
    - 16:9 비율 고정 (aspect-ratio: 16/9)
    - 라이트 테마 강제 (다크 테마 금지)
    - Guy Kawasaki 10-20-30 Rule 준수

### Preconditions
- GitHub Pages 환경 설정 완료
- Mermaid JS CDN 또는 로컬 빌드 준비
- Google Fonts 또는 로컬 폰트 설치

### Postconditions
- HTML Slides 24개 (8도메인×3매체) 렌더링 성공
- 16:9 비율 유지
- 키보드 네비게이션 동작 확인

### Invariants
- 16:9 비율 고정 (aspect-ratio: 16/9)
- 라이트 테마 강제 (다크 테마 금지)
- Guy Kawasaki 10-20-30 Rule 준수

## Examples

examples:
  - name: 타이틀 슬라이드
    command: cat > slide.html << 'EOF' && cat slide.html
<section class="slide layout-title slide--active">...</section>
EOF
  - name: 다이어그램 슬라이드
    command: cat > slide.html << 'EOF' && cat slide.html
<section class="slide layout-diagram">...mermaid...</section>
EOF

### Example 1: 타이틀 슬라이드
```html
<section class="slide layout-title slide--active">
  <div class="title-content">
    <p class="project-label">p-hermes</p>
    <div class="divider"></div>
    <h1 class="slide-title">Workflow Redefined</h1>
    <p class="slide-subtitle">핵심 워크플로우 시스템 재정의</p>
  </div>
  <footer>
    <span class="slide-id">DOC-A1-slides</span>
    <span class="page-number">1 / 10</span>
  </footer>
</section>
```

### Example 2: 다이어그램 슬라이드 (Mermaid)
```html
<section class="slide layout-diagram">
  <header><h1>상태 전이 파이프라인</h1></header>
  <main>
    <div class="diagram-container">
      <div class="mermaid">
flowchart LR
    A[request] --> B[investigation]
    B --> C[design]
    C --> D[review]
      </div>
    </div>
  </main>
</section>
```

## Acceptance Criteria
Given: HTML Slides 24개 작성 완료
When: 브라우저에서 렌더링 확인
Then: 16:9 비율 유지 + 키보드 네비게이션 동작 + Mermaid 다이어그램 렌더링 성공
