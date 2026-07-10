# p-hermes Playground v8 슬라이드 — 작업 현황

> **JOB**: JOB-2173 | **업데이트**: 2026-07-11 02:00 | **모델**: GPT-5.6 SOL

---

## 현재 상태

| 데크 | 페이지 | 모델 | 크기 | 검증 | 상태 |
|:----:|:-----:|:----:|:----:|:----:|:----:|
| **A** | 34p | Qwen3.6 → GPT-5.6 예정 | 84K | P2 6개 | ⏳ 재생성 대기 |
| **B** | 35p | **GPT-5.6 SOL** | 92K | ✅ P0/P1=0, P2=6 | ✅ 검증 통과 |
| **C** | 37p | GPT-5.6 예정 | 69K | ⏳ | ⏳ 생성 중 |
| **D** | 46p | GPT-5.6 예정 | 75K | ⏳ | ⏳ 대기 중 |

---

## GPT-5.6 SOL 재생성 계획

### 완료
- [x] 데크 B (Knowledge 심화) — 검증 통과, P2 6개는 의도적 줄바꿈 참고 사항

### 진행 중
- [ ] 데크 C (Skill 심화) — 생성 중 (타임아웃 후 재시도)
- [ ] 데크 D (Workflow 심화) — C 완료 후 순차 시작
- [ ] 데크 A (4기능 종합) — D 완료 후 재생성

### 최종 검증
- [ ] 전량 `validate-slides.py` 통과 확인
- [ ] P0/P1 이슈 0개 확인
- [ ] `git commit` + `git push` 배포

---

## 데크별 구조

### 데크 A: 4가지 핵심 기능 (34p)
- Act 1-2: 문제 인식, Agent 없는 세계
- Act 3-6: Memory/Knowledge/Skill/Workflow 소개
- Act 7-8: 통합, 실전 시나리오, 요약

### 데크 B: Knowledge 심화 (35p)
- Act 1: 왜 지식 관리가 필요한가
- Act 2: 지식 수집 (Signal Detector)
- Act 3: 지식 분류 (T1/T2/T3 계층)
- Act 4: 지식 검색 (FTS5, Jaccard)
- Act 5: 지식 갱신 (자동 파이프라인)
- Act 6: 종합

### 데크 C: Skill 심화 (37p)
- Act 1: Skill 필요 이유
- Act 2: SKILL.md 구조
- Act 3: Skill 작성
- Act 4: Skill 관리
- Act 5: 실제 사례
- Act 6: 종합

### 데크 D: Workflow 심화 (46p)
- Act 1: Workflow 필요 이유
- Act 2: 9단계 상태 머신
- Act 3: 게이트 시스템
- Act 4: 자동화
- Act 5: 모니터링
- Act 6: 실전 시나리오
- Act 7: 종합

---

## 검증 규칙 (validate-slides.py)

| ID | 검증 | 심각도 |
|:--:|:----|:-----:|
| V1 | hero-subtitle-overflow | P1 |
| V2 | footer-overflow | P1 |
| V3 | content-desc-overflow | P2 |
| V4 | compare-missing-column | P0 |
| V5 | compare-feature-structure | P1 |
| V6 | nav-scrollintoview | P0 |
| V7 | css-smooth-scroll | P0 |
| V8 | content-duplication | P1 |
| V9 | missing-scroll-snap-type | P0 |
| V10 | missing-scroll-snap-align | P0 |

**P0=즉시 수정, P1=권장, P2=참고**

---

## 데크 A 버그 교훈 (반복 금지)

1. `scroll-behavior: smooth` CSS 제거 — snap 충돌
2. `scrollIntoView()` → `window.scrollTo({top: offsetTop})`
3. `compare-col { width: 100% }` — 정렬 오류
4. `feature-item > div:last-child { flex: 1 }` — 텍스트 확장
5. hero-subtitle/footer `white-space:nowrap` — 줄바꿈 방지
6. 페이지별 콘텐츠 중복 검증 (Jaccard < 0.6)

---

## 이전 버그 수정 내역 (데크 A, Qwen3.6)

| 문제 | 해결 |
|------|------|
| 내비 점 스크롤 버그 | `scrollIntoView` → `window.scrollTo` |
| Compare 정렬 (10,14,18,21) | `compare-col {width:100%}` + `flex:1` |
| 28페이지 중복 | "실전 시나리오" → "왜 4가지가 필요한가" |
| 31페이지 줄바꿈 | 아이콘+화살표 flex 레이아웃 |
| 24~28 흐름 | 문제→핵심질문→요약 논리 순서 |

---

_이 문서는 작업 현황이 업데이트될 때마다 갱신됩니다._
