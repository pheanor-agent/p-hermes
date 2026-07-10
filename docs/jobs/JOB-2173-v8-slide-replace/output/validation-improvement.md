# p-hermes Playground v8 슬라이드 — 2차 버그 수정 및 시스템 개선 산출물

> **JOB**: JOB-2173 | **날짜**: 2026-07-11 | **모델**: Qwen3.6

---

## 1. 문제 식별 및 수정 내역

### 1.1 내비게이션 점 스크롤 버그 (P0)

| 항목 | 내용 |
|------|------|
| **문제** | 내비 점 클릭 시 목표 슬라이드까지 이동하지 않고 중간에 멈춤 |
| **원인** | `scrollIntoView({behavior:'auto'})`가 `scroll-snap-type: y mandatory`와 충돌. CSS `scroll-behavior: smooth`도 간섭 |
| **수정 위치** | `goSlide()` + ArrowUp/ArrowDown 핸들러 (총 3곳) |
| **해결** | `window.scrollTo({top: slides[n].offsetTop, left: 0})`로 교체 |
| **CSS 수정** | `html { scroll-behavior: smooth; }` 제거 |
| **JS 수정** | `updateFocus()` 내 `scrollIntoView` 제거 (포커스 요소 스크롤이 snap 간섭) |

### 1.2 Compare 컴포넌트 텍스트 정렬 오류 (P1)

| 항목 | 내용 |
|------|------|
| **문제** | 10, 14, 18, 21, 26페이지에서 compare-content 내 텍스트가 한쪽으로 몰림 |
| **원인** | `compare-col`에 `width` 미지정 → `feature-item` flex 컨테이너가 좁은 공간에 갇힘 |
| **해결** | CSS에 `.compare-content .compare-col { width: 100%; }` 추가 |
| **추가** | `feature-item > div:last-child { flex: 1; min-width: 0; }` + `word-break: keep-all` |

### 1.3 28페이지 콘텐츠 중복 (P1)

| 항목 | 내용 |
|------|------|
| **문제** | 28페이지가 25페이지와 동일한 "보고서를 만들어줘" 시나리오를 반복 |
| **해결** | 28페이지를 "왜 4가지가 모두 필요한가?"로 변경 (Memory만 있으면/Knowledge만 있으면 등 4개 카드) |

### 1.4 31페이지 줄바꿈 문제 (P1)

| 항목 | 내용 |
|------|------|
| **문제** | "기억(Memory) → 지식(Knowledge) → 기술(Skill) → 흐름(Workflow)"가 줄바꿈으로 보기 안좋음 |
| **해결** | `hero-subtitle` → 아이콘+화살표 flex 레이아웃으로 변경 |

### 1.5 28페이지 content-desc 줄바꿈 (P1)

| 항목 | 내용 |
|------|------|
| **문제** | "각 기능은 필요조건이지만 충분조건은 아닙니다..."가 줄바꿈됨 |
| **해결** | `white-space:nowrap` + `font-size:16px` 인라인 스타일 추가 |

---

## 2. 자동 검증 시스템 (신규)

### 2.1 validate-slides.py

**목적**: 슬라이드 배포 전 자동 품질 검증

**검증 항목**:

| ID | 검증 | 심각도 | 설명 |
|:--:|:----|:-----:|------|
| V1 | hero-subtitle-overflow | P1 | 90자 초과 시 줄바꿈 경고 |
| V2 | footer-overflow | P1 | 푸터 텍스트 오버플로우 |
| V3 | content-desc-overflow | P2 | 중요 메시지 오버플로우 |
| V4 | compare-missing-column | P0 | compare-content 구조 불일치 |
| V5 | compare-feature-structure | P1 | feature-item 아이콘+텍스트 구조 |
| V6 | nav-scrollintoview | P0 | scrollIntoView 사용 시 충돌 경고 |
| V7 | css-smooth-scroll | P0 | scroll-behavior:smooth 충돌 |
| V8 | content-duplication | P1 | Jaccard 0.6+ 페이지 중복 |
| V9 | missing-scroll-snap-type | P0 | scroll-snap 설정 누락 |
| V10 | missing-scroll-snap-align | P0 | scroll-snap-align 누락 |

**사용법**: `python3 validate-slides.py <deck.html> [--strict]`
**산출**: 콘솔 결과 + JSON

---

## 3. 24~28페이지 흐름 검토

### 변경 전
```
24. 통합 다이어그램 (4기능 연결망)
25. 실제 예시 ("보고서를 만들어줘" — 메타포)
26. Before/After 종합 비교
27. 숫자로 보는 차이 (90%, 0.3초, 100%, 9단계)
28. 실전 시나리오 ("보고서를 만들어줘" — 4기능 상세) ← 25페이지와 중복
29. 핵심 요약 5가지
```

### 변경 후
```
24. 통합 다이어그램 (4기능 연결망)
25. 실제 예시 ("보고서를 만들어줘" — 메타포)
26. Before/After 종합 비교
27. 숫자로 보는 차이 (90%, 0.3초, 100%, 9단계)
28. 왜 4가지가 모두 필요한가? (각 기능 단일 시 한계) ← 신규
29. 핵심 요약 5가지
```

**흐름 분석**: 문제(24-27) → 핵심 질문(28) → 요약(29)로 논리적 전환. 중복 제거.

---

## 4. 향후 개선 방향

### 4.1 사양서 기반 개발 연계

| 항목 | 현재 | 개선 |
|------|------|------|
| **배포 전 검증** | 수동 브라우저 테스트 | `validate-slides.py` 자동 실행 |
| **콘텐츠 중복** | 시각적 확인 | Jaccard 유사도 자동 감지 |
| **텍스트 오버플로우** | 렌더링 후 확인 | 문자 수 기반 사전 검증 |
| **네비게이션 버그** | 사용자 보고 | scrollIntoView 사용 차단 |

### 4.2 spec-matrix/SPEC-D03 연동

현재 `SPEC-SLIDES.md`에 슬라이드 검증 규칙 15개 정의되어 있으나, 자동 실행 스크립트가 없었습니다. `validate-slides.py`가 이 공백을 메꿉니다.

**추천**: 향후 deploy.sh에 검증 단계 추가
```bash
# deploy.sh에 추가
python3 lectures/v8/validate-slides.py lectures/v8/*.html || exit 1
```

---

## 5. Git 커밋 이력

| 커밋 | 내용 |
|------|------|
| `c448b4e` | compare 정렬, 28페이지 중복, 31페이지 줄바꿈, 네비점 스크롤 수정 |
| `786d92a` | nav dot scrollIntoView→scrollTo, compare CSS, 28페이지 신규, 31페이지 flex |
| (대기) | validate-slides.py + 28페이지 content-desc nowrap + 산출물 문서 |

---

## 6. 시스템 교훈

1. **scroll-snap + scroll-behavior: smooth는 충돌한다** — CSS smooth scroll과 JS scrollIntoView는 snap alignment와 양립 불가. `window.scrollTo` + snap 전용 CSS가 안정적
2. **텍스트 길이는 미리 검증해야 한다** — 렌더링 전 문자 수로 오버플로우 예측 가능 (한글 기준 70-90자/줄)
3. **콘텐츠 중복은 수동 검사가 불가능** — 34페이지 중 25↔28 중복은 시각적 검토에서 누락. 자동화 필수
4. **compare 레이아웃은 CSS SSOT에 정의** — `compare-col { width:100% }` 같은 구조적 규칙은 인라인 스타일이 아님

---

_이 문서는 JOB-2173 2차 수정 세션의 작업 산출물입니다._
