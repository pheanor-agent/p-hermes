# HTML 슬라이드 프레젠테이션 패턴

단일 파일 HTML 슬라이드 프레젠테이션 생성 방법. GitHub Pages 배포 가능.

## 사용 사례

- 세미나/프레젠테이션 자료
- 기술 문서 배포
- 프로젝트 데모

## 구조

- **단일 HTML 파일**: CSS + JS inline (Google Fonts만 외부)
- **슬라이드별 `<div class="slide">`**: 각 슬라이드가独立的
- **네비게이션**: 키보드(`←` `→` `Space`) + 터치 + 하단 버튼
- **애니메이션**: CSS `@keyframes fadeInUp` + delay 클래스

## 핵심 패턴

```html
<div class="slides" id="slides">
  <div class="slide slide-cover active" data-slide="0">
    <!-- Cover slide -->
  </div>
  <div class="slide" data-slide="1">
    <!-- Content slide -->
  </div>
</div>

<!-- Navigation -->
<div class="nav">
  <button onclick="prevSlide()">‹</button>
  <div class="nav-dots" id="navDots"></div>
  <span class="nav-counter">1 / N</span>
  <button onclick="nextSlide()">›</button>
</div>

<script>
  let current = 0;
  const slides = document.querySelectorAll('.slide');
  const total = slides.length;

  function goTo(n) {
    slides[current].classList.remove('active');
    current = ((n % total) + total) % total;
    slides[current].classList.add('active');
  }

  document.addEventListener('keydown', (e) => {
    if (e.key === 'ArrowRight' || e.key === ' ') nextSlide();
    if (e.key === 'ArrowLeft') prevSlide();
  });
</script>
```

## 디자인 시스템

- **배경**: `#0a0a0f` (Dark)
- **폰트**: Inter (본문) + JetBrains Mono (코드/숫자)
- **슬라이드 전환**: `opacity + transform translateY` CSS transition
- **애니메이션**: `fadeInUp` keyframe + delay 클래스 (0.1s~0.5s)

## 컴포넌트 패턴

### Stat Card
```html
<div class="stat stat-accent">
  <div class="stat-value">3,651</div>
  <div class="stat-label">Wiki Pages</div>
</div>
```

### Progress Bar
```html
<div class="progress-bar">
  <div class="progress-fill" style="width: 76%; background: var(--green);"></div>
</div>
```

### Timeline
```html
<div class="timeline">
  <div class="timeline-step active">
    <div class="timeline-label">단계명</div>
    <div class="timeline-dot"></div>
  </div>
</div>
```

### Quote
```html
<div class="quote">
  인용 문구
  <div class="quote-author">출처</div>
</div>
```

## GitHub Pages 배포

```
project/
├── docs/
│   └── slides.html
└── site/
    └── index.html → ../docs/slides.html

# git push 후 Settings → Pages → gh-pages branch
# → https://<user>.github.io/<repo>/
```

## 참고

- session: 2026-06-04, 지식 시스템 세미나 자료 생성
- 파일 위치: `~/.hermes/workspace/projects/knowledge-system/docs/slides.html`
