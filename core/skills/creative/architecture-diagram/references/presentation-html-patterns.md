# Presentation HTML 패턴

## 16:9 고정 + 스크롤 없음 (1920x1080 타겟)

### 핵심 CSS
```css
html, body {
  height: 100vh;
  width: 100vw;
  overflow: hidden; /* 스크롤 제거 */
}

.slide {
  height: 100vh;
  width: 100vw;
  display: flex;
  flex-direction: column;
  justify-content: center; /* 수직 중앙 */
  padding: 60px 80px; /* 여백 */
}

.slide-content {
  max-width: 1200px; /* 가독성 제한 */
  width: 100%;
  margin: 0 auto; /* 수평 중앙 */
}
```

**⚠️ 함정**: `justify-content: center`는 콘텐츠가 뷰포트보다 크면 overflow 발생. 슬라이드당 텍스트 400자 이하 권장.

## 슬라이드 네비게이션 (Vanilla JS)

```javascript
let current = 0;
const slides = document.querySelectorAll('.slide');
const total = slides.length;

function goTo(n) {
  slides[current].classList.remove('active');
  current = ((n % total) + total) % total;
  slides[current].classList.add('active');
}

// 키보드
document.addEventListener('keydown', (e) => {
  if (e.key === 'ArrowRight' || e.key === ' ') nextSlide();
  if (e.key === 'ArrowLeft') prevSlide();
});

// 터치
let touchStartX = 0;
document.addEventListener('touchstart', (e) => { touchStartX = e.touches[0].clientX; });
document.addEventListener('touchend', (e) => {
  const diff = e.changedTouches[0].clientX - touchStartX;
  if (Math.abs(diff) > 60) diff < 0 ? nextSlide() : prevSlide();
});
```

## 아이스 브레이킹 패턴 (비유 → 본론)

### 구조
```
1. 일상 상황 제시 (신입 사원, 맛집 찾기, 등)
2. 문제 제기 (지식/경험 부족)
3. 해결책 도입 (시스템/도구/메소드)
4. 본론으로 전환 ("오늘은 바로 이 시스템 이야기")
```

### 예시 (AI 기술 3층위)
```
신입 사원 →业务知识 어떻게 관리할까?
  ↓
3가지 접근법
  1. 교육 (모델 학습: AI가知識을 학습)
  2. 참고 문서 (에이전트 메모리: AI가知識을 저장·검색) ← 오늘 주제
  3. 검색 도구 (RAG: AI가知識을 활용)
  ↓
"오늘은 2층 '에이전트 메모리' 이야기"
```

## 슬라이드당 콘텐츠 가이드라인

| 요소 | 제한 |
|------|------|
| 텍스트 | 200-400자 |
| 카드 | 최대 4개 (grid-4) |
| 표 행 | 최대 6행 |
| 다이어그램 | 1개/슬라이드 |
| 코드 블록 | 5-10줄 |

## 애니메이션 (CSS only)

```css
@keyframes fadeInUp {
  from { opacity: 0; transform: translateY(16px); }
  to { opacity: 1; transform: translateY(0); }
}

.slide.active .animate {
  animation: fadeInUp 0.5s ease forwards;
}
.slide.active .delay-1 { animation-delay: 0.1s; }
.slide.active .delay-2 { animation-delay: 0.2s; }
```
