# Model Comparison Methodology

When comparing how different models handle slide layouts, diagrams, or design decisions, follow this methodology.

## ❌ 잘못된 비교: HTML 레벨 복사

**사용자 지적**: "지금 한게 동일한 사양서로 html만 따로 만든거 아니야?"

**문제**: 동일한 HTML 파일을 복사하고 CSS만 변경 → 실제 모델의 레이아웃 결정 능력을 비교할 수 없음

```bash
# ❌ 이렇게 하면 안 됨
cp index.html index-glm-5.1.html
cp index.html index-gemma-4.html
# → 둘이 같은 구조를 가지므로 레이아웃 차이가 아님
```

## ✅ 올바른 비교: 사양서 레벨 생성

**근본 원리**: 같은 SPEC을 다른 모델에게 읽게 하면, 각 모델의 해석 차이가 레이아웃으로 나타난다

### 단계별 방법

1. **동일한 SPEC 파일**을 각 모델에게 전달
2. **사양서 작성**: 각 모델이 SPEC을 읽고 자체 design 문서 작성
3. **HTML 생성**: 각 모델이 자체 사양서 기반으로 HTML 생성
4. **시각적 비교**: 브라우저에서 두 파일 개별 확인

```bash
# 1. SPEC 파일은 동일
specs/active/components/slide-structure.md

# 2. 모델별 사양서 생성 (delegate_task 사용)
# glm-5.1: specs/designs/spec-glm-5.1.md
# Gemma 4: specs/designs/spec-gemma-4.md

# 3. 모델별 HTML 생성
# glm-5.1: specs/designs/index-glm-5.1.html
# Gemma 4: specs/designs/index-gemma-4.html

# 4. 브라우저에서 비교
# file:///path/to/specs/designs/index-glm-5.1.html
# file:///path/to/specs/designs/index-gemma-4.html
```

## 🔍 실제 차이점 관찰

| 항목 | glm-5.1 | Gemma 4 |
|------|---------|---------|
| **Tree Diagram **(슬라이드 9) | `grid-template-columns: repeat(4, 1fr)` | `display: flex; justify-content: center` |
| **Flow Chart **(슬라이드 10) | `grid-template-columns: repeat(4, 1fr)` | `display: flex; justify-content: center` |
| **Tree Branch 간격** | `gap: clamp(12px, 2vw, 20px)` | `gap: clamp(12px, 2vw, 20px)` |
| **Tree Branch 크기** | `min-width: clamp(100px, 12vw, 130px)` | `min-width: clamp(100px, 12vw, 130px)` |

**실제 레이아웃 패턴은 모델별 스타일 선호도**:
| 모델 | Grid vs Flex | 반응형 전략 | 적합한 다이어그램 |
|------|-------------|-------------|-------------------|
| **glm-5.1** | Grid 기반 (4열 균등) | `clamp()` 기반 간격 | Tree Diagram, Classification |
| **Gemma 4** | Flex 기반 (자동 크기) | `min-width: clamp()` | Flow Chart, Process |

## 📋 비교 체크리스트

- [ ] 동일한 SPEC 파일 사용
- [ ] 모델별 사양서 작성 (독립적 해석)
- [ ] 모델별 HTML 생성 (독립적 구현)
- [ ] 브라우저에서 시각적 비교
- [ ] CSS 패턴 차이 문서화 (Grid vs Flex 등)

## ⚠️ Pitfalls

| 문제 | 원인 | 해결 |
|------|------|------|
| **동일 HTML 복사** | `cp index.html index-{model}.html` → 차이 없음 | SPEC 레벨에서 독립 생성 |
| **다른 슬라이드 비교** | 슬라이드 9 vs 10 → 콘텐츠 차이로 레이아웃 구분 불가 | **같은 슬라이드** 두 모델로 생성 |
| **CSS 패턴 강제** | 모델이 선호하는 Grid/Flex 무시하고 강제 | 모델의 자연스러운 선택 관찰 |

## 📚 관련 세션

- **JOB-1557**: seminar-slides 레이아웃 개선, 모델별 차이 분석 (2026-06-11)
- **사용자 피드백**: "동일한 사양서로 html만 따로 만든거 아니야?", "같은 슬라이드를 만들어야 비교를 하지"
