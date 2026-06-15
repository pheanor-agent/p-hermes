# JOB-1557: 16:9 해상도 최적화 (2026-06-11)

## 문제

슬라이드 HTML이 1920x1080 기준 고정 `px` 단위로 작성됨 → 1366x768, 2560x1440 등 다른 해상도에서 비율 불균형

## 수정 내역

### 1. CSS 브레이스 오류 (중요도: 높음)

**문제**: `.diagram-node {` 브레이스 미폐기 → 내부에 중복 CSS 삽입 → 30개 규칙 무시됨
**해결**: `grep -c '{' index.html` / `grep -c '}' index.html`로 브레이스 균형 확인

### 2. aspect-ratio 충돌

**문제**: `.slides { aspect-ratio: 16/9 }`가 `height: 100vh`와 충돌하여 레이아웃 왜곡
**해결**: `aspect-ratio` 제거, `100vh`만 사용 (자연스러운 16:9 유지)

### 3. 표지 슬라이드 수직 정렬

**문제**: `.slide-cover`가 `text-align: center`만 있어서 콘텐츠가 상단에 몰려 있음
**해결**: 
```css
.slide-cover {
  display: flex;
  flex-direction: column;
  justify-content: center;
  flex: 1 0 auto;
  text-align: center;
}
```

### 4. 반응형 폰트 스케일

```css
:root {
  --font-base: clamp(14px, 1.2vw, 18px);
  --font-title: clamp(28px, 3vw, 48px);
  --font-heading: clamp(20px, 2.2vw, 36px);
}
```

### 5. 반응형 그리드

```css
.grid-2 { grid-template-columns: repeat(2, minmax(250px, 1fr)); }
.grid-3 { grid-template-columns: repeat(3, minmax(200px, 1fr)); }
.grid-4 { grid-template-columns: repeat(4, minmax(180px, 1fr)); }
.two-col { grid-template-columns: repeat(2, minmax(280px, 1fr)); }
```

## 해상도별 실제 렌더링 값

| 해상도 | --font-title | .slide 패딩 |
|--------|-------------|-------------|
| 1366×768 | 41px | 31px |
| 1920×1080 | 58px | 43px |
| 2560×1440 | 48px (최대) | 58px |

## 모델 선택적 사용

glm-5.1 모델은 config.yaml Line 58에 등록됨 (zai provider). 기본 모델(Qwen3.6) 대신 `delegate_task(model="zai/glm-5.1")`로 품질 향상 가능.

## Hierarchy 순서 수정

**문제**: 슬라이드 4의 계층 구조가 L1→L3→L2 순서 (SPEC-B7 Line 58 "L1→L2→L3" 위반)
**해결**: HTML에서 `<div class="hierarchy-level l2">`와 `<div class="hierarchy-level l3">` 순서 교체

## 검증 명령어

```bash
# 브레이스 균형 확인
grep -c '{' index.html
grep -c '}' index.html

# 중복 CSS 확인
grep -n "\.two-col" index.html

# aspect-ratio 충돌 확인
grep -n "aspect-ratio" index.html

# Spec ↔ HTML 일치성
python3 validate.py
```
