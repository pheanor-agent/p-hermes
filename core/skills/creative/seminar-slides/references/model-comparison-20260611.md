# 모델별 레이아웃 비교 분석 (JOB-1557, 2026-06-11)

## 개요

슬라이드 레이아웃을 glm-5.1과 Gemma 4 모델로 각각 생성하여 비교 분석.

## 올바른 비교 방법

**같은 슬라이드**를 다른 모델로 생성하여 비교해야 함.

### 실행 단계

```bash
# 1. 원본 HTML 복사
cp index.html index-glm-5.1.html
cp index.html index-gemma-4.html

# 2. 각 모델별 레이아웃 적용
# glm-5.1: grid-template-columns: repeat(4, 1fr)
# Gemma 4: display: flex; justify-content: center

# 3. 브라우저에서 개별 확인
# file:///path/to/index-glm-5.1.html
# file:///path/to/index-gemma-4.html
```

### ❌ 잘못된 비교

| 항목 | 문제 |
|------|------|
| **다른 슬라이드 비교** | 슬라이드 9 (glm-5.1) vs 슬라이드 10 (Gemma 4) |
| **문제점** | 콘텐츠가 달라 레이아웃 차이가 아닌 콘텐츠 차이로 해석 |

### ✅ 올바른 비교

| 항목 | 방법 |
|------|------|
| **동일 슬라이드** | 슬라이드 9를 두 모델로 각각 생성 |
| **동일 콘텐츠** | 제목, 카드, 다이어그램 동일 |
| **레이아웃만 상이** | Grid (glm-5.1) vs Flex (Gemma 4) |

## 비교 결과

### 슬라이드 9 (Tree Diagram)

| 모델 | 레이아웃 패턴 | 카드 너비 | 화면 활용도 |
|------|---------------|-----------|-------------|
| **glm-5.1** | `grid-template-columns: repeat(4, 1fr)` | 균등 (25% each) | ✅ 100% 활용 |
| **Gemma 4** | `display: flex; justify-content: center` | 자동 (내용 기반) | ✅ 중앙 집중 |

**추천**: **glm-5.1 **(Grid 기반) — 4개 브랜치가 균등한 너비로 배치되어 화면을 효율적으로 활용

### 슬라이드 10 (Flow Chart)

| 모델 | 레이아웃 패턴 | 화살표 | 가독성 |
|------|---------------|--------|--------|
| **glm-5.1** | `grid-template-columns: repeat(4, 1fr)` | ❌ 없음 | ✅ 카드 균등 배치 |
| **Gemma 4** | `display: flex; justify-content: center` | ✅ `→` 표시 | ✅ 단계별 흐름 명확 |

**추천**: **Gemma 4 **(Flex 기반) — 화살표(→)가 단계별 흐름을 직관적으로 보여줌

## 결론

| 다이어그램 유형 | 추천 모델 | 이유 |
|----------------|-----------|------|
| **Tree Diagram, Classification** | glm-5.1 | Grid 기반 균등 배치 |
| **Flow Chart, Process** | Gemma 4 | 화살표로 프로세스 흐름 명확 |

## 파일 위치

- `index-glm-5.1.html` (Grid 기반)
- `index-gemma-4.html` (Flex 기반)
