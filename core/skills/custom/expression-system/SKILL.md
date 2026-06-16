---
name: expression-system
description: "표현력이 필요한 콘텐츠의 단일 진입점. 라우팅, 공유 엔진, 템플릿, 검증 통합."
version: 1.0.0
tags: ["documentation", "content", "creative", "routing"]
related_skills: ["seminar-slides", "baoyu-comic", "baoyu-infographic", "architecture-diagram", "novel-writing", "comfyui-remote"]
---

# 표현력 시스템 (Expression System)

> "단순 요약이 아닌, 이해와 흥미를 전달하는 콘텐츠"

---

## 1. 개요

표현력 관련 모든 요청의 단일 진입점입니다. 키워드/의도 분석 → 도메인 매핑 → 엔진 처리 → 출력까지 파이프라인 자동화.

### 도메인 분류

| 도메인 | 설명 | 하위 유형 |
|--------|------|----------|
| D1: 교육/설명 | README, Wiki, 블로그, 가이드 | 설득, 설명, 가이드 |
| D2: 내러티브 | 소설, 시나리오, 에세이 | 창의적 글쓰기 |
| D3: 시각 콘텐츠 | 만화, 인포그래픽, 다이어그램 | 시각적 표현 |
| D4: 프레젠테이션 | 세미나 슬라이드, 대시보드 | 프레젠테이션 |
| D5: 이미지 생성 | ComfyUI 프롬프트, 배치 | 이미지 파이프라인 |

### 제외 도메인

- Changelog (변경 이력 로깅)
- JOB 산출물 요약 (작업 결과 기록)
- API 레퍼런스 (엔드포인트 나열)
- Config 설명 (키-값 설명)

---

## 2. 라우팅 규칙

```
요청 수신 → 키워드/의도 분석 → 도메인 매핑 → 엔진 처리 → 출력
```

### 의도 분류

| 의도 | 설명 | 키워드 |
|------|------|--------|
| persuade | 설득, 권유 | "설득해줘", "왜 좋은지" |
| explain | 설명, 이해 | "설명해줘", "이해시켜줘" |
| entertain | 재미, 흥미 | "재미있어줘", "흥미롭게" |
| inform | 정보 전달 | "정확하게", "데이터" |
| inspire | 영감, 동기 | "영감을 줘", "동기부여" |

### 키워드 → 도메인 매핑

| 키워드/패턴 | 도메인 | 엔진 처리 |
|-------------|--------|-----------|
| "슬라이드", "프리젠테이션" | D4 | Tier + Tone |
| "README", "가이드" | D1 | Tier + Tone |
| "Wiki", "개념 설명" | D1 | Tier + Analogy |
| "블로그", "글" | D1 | Tier + Tone |
| "소설", "이어써줘" | D2 | Tier + Tone(캐릭터) |
| "만화", "comic" | D3 | Tier + Style |
| "인포그래픽", "시각화" | D3 | Tier + Style |
| "다이어그램", "아키텍처도" | D3 | Template(SVG) |
| "이미지 생성" | D5 | ComfyUI API |

### 폴백

라우터가 분류하지 못할 경우 → 직접 작성 폴백 + `classification-log.jsonl` 기록.

---

## 3. 공유 엔진

| # | 엔진 | 모드 | 설명 |
|---|------|------|------|
| 1 | Tier Generator | 🟢 룰 | L1→L2→L3 계층화 |
| 2 | Tone Adapter | 🟢 룰 | 타겟→어조 매핑 |
| 3 | Analogy Builder | 🟡 LLM+라이브러리 | 비유 생성/검색 |
| 4 | Template Filler | 🟢+🟡 | 템플릿 렌더링 |
| 5 | Validator | 🟢+🟡 | 2단계 검증 (T1/T2) |
| 6 | Model Selector | 🟢 룰 | 의도→모델 매핑 |
| 7 | Image Prompt Builder | 🟡 LLM | 이미지 프롬프트 최적화 |

### 실행 순서

```
1. Tier Generator     (룰 기반) ──┐
2. Tone Adapter       (룰 기반)  ─┤
3. Analogy Builder    (LLM)      ─┤ 병렬 가능
4. Model Selector     (룰 기반)  ─┘
5. Image Prompt Builder (LLM) ──→ D3/D5 시각 요청 시
6. Template Filler    (룰+LLM) ──┐
7. Validator T1       (룰 기반) ─┤
8. Validator T2       (LLM)      ─┘ 직렬 실행
```

---

## 4. 사용법

### 기본 사용

```
expression-system.run(domain="D1", intent="explain", content="...")
```

### 엔진별 직접 호출

```python
# Tier Generator
from expression_system.engine.tier_generator import generate_tiers
tiers = generate_tiers(domain="D1", content="...", target="non-technical")

# Tone Adapter
from expression_system.engine.tone_adapter import adapt_tone
tone = adapt_tone(target="non-technical", domain="D1")

# Analogy Builder
from expression_system.engine.analogy_builder import find_analogy
analogy = find_analogy(concept="docker", target="non-technical")
```

---

## 5. 파일 구조

```
~/.hermes/skills/custom/expression-system/
├── SKILL.md                          # 이 파일
├── engine/                           # 공유 엔진
│   ├── __init__.py                   # 하이픈 모듈 동적 로딩 헬퍼
│   ├── tier-generator.py
│   ├── tone-adapter.py
│   ├── analogy-builder.py
│   ├── template-filler.py
│   ├── validator.py
│   └── image-prompt-builder.py
├── domain_wrappers/                  # 도메인별 래핑 (Phase 4)
│   ├── d2-novel.py
│   ├── d3-visual.py
│   ├── d4-slides.py
│   └── d5-comfyui.py
├── models/                           # 모델 선택
│   ├── catalog.json
│   └── scoring.py
├── styles/                           # 스타일 매트릭스
│   ├── matrix.json
│   ├── tokens.css
│   ├── definitions/
│   └── palettes/
├── templates/                        # 도메인별 템플릿
│   ├── education/
│   ├── narrative/
│   ├── visual/
│   ├── presentation/
│   └── image/
├── analogies/                        # 비유 라이브러리
│   ├── library.json
│   └── pending/
├── references/                       # 리퍼런스
│   ├── domain-rules.md
│   └── migration-guide.md
└── output/                           # 출력 히스토리
    └── history.jsonl
```

---

## 6. 기존 스킬과의 관계

표현력 시스템은 기존 스킬을 파괴하지 않습니다. 메타 스킬이 하위 도메인으로 래핑하여 공유 엔진을 제공합니다.

| 기존 스킬 | 새로운 역할 |
|-----------|-------------|
| seminar-slides | D4 서브 도메인 |
| baoyu-comic | D3 서브 도메인 |
| baoyu-infographic | D3 서브 도메인 |
| architecture-diagram | D3 서브 도메인 |
| novel-writing | D2 서브 도메인 |
| comfyui-remote | D5 엔진 |

기존 스킬은 독립 사용 가능. expression-system은 공유 엔진을 제공합니다.

---

## 7. 미분류 로깅

라우터가 분류하지 못한 요청은 기록됩니다.

- **위치**: `~/.hermes/workspace/expression-system/classification-log.jsonl`
- **포맷**: `{"timestamp": "ISO8601", "request": "텍스트", "model_guess": "D?", "fallback": true}`
- **분석**: 주간 cron으로 빈도 분석 → 새 라우팅 규칙 추가 후보

---

## 8. 출력 히스토리

- **위치**: `~/.hermes/workspace/expression-system/output/history.jsonl`
- **중복 감지**: 시맨틱 유사도 ≥ 0.85 항목 발견 시 이전 결과 참조 제안
- **중복 방지**: 동일 주제+동일 모델+3일 이내 → 재생성 비추천

---

## 9. 전체 파이프라인 실행 (CLI)

```bash
bash ~/.hermes/skills/custom/expression-system/run.sh <domain> <intent> <content> [context.json]
```

- Domain: `D1` (기술) 또는 `D2` (창작)
- Intent: `explain`, `narrate`, `persuade`, `document` 등
- Content: 검증할 콘텐츠 텍스트
- Context: 선택적 JSON 컨텍스트 (검증에 사용)

출력: JSON 형식 (timestamp, domain, intent, model, tiers, tone, validation, status)

### 테스트

```bash
cd ~/.hermes/skills/custom/expression-system
python3 tests/test_system.py
```

25개 테스트: Validator 3, Tier Generator 2, Tone Adapter 2, Model Selector 2, Template Filler 2, Analogy Builder 4, Image Prompt Builder 3, Pipeline 1, **Domain Wrappers 6**

---

## 10. Phase 구현 상태

- **Phase 1**: ✅ 완료 (메타 스킬 + 라우터 + 로깅)
- **Phase 2**: ✅ 완료 (공통 엔진: Validator, Tier/Tone, Model Selector)
- **Phase 3**: ✅ 완료 (Analogy Builder + Template Filler + Image Prompt Builder)
- **Phase 4**: ✅ 완료 (도메인 오버레이 + 기존 스킬 래핑)

---

## 10. Pitfalls

1. **run.sh JSON 조합 버그**: `json.loads('''$VARIABLE''')` 방식은 JSON 내에 특수 문자(예: `"RAG(Retrieval-Augmented Generation)"`)가 포함되면 파싱 실패. **해결**: 임시 파일에 JSON 저장 후 `json.load(open())`으로 읽기.
2. **T1 분량 검증**: D1은 200자 미만일 때 검증 실패. 테스트 시 충분히 긴 콘텐츠 사용.
3. **D2 검증**: T2 검증은 D2에만 적용. D1은 T2 스킵됨.
4. **템플릿 변수 치환**: `string.Template`은 `$variable` 형식을 사용하지만, 템플릿은 `{{variable}}` (Jinja2 스타일)로 정의됨. **해결**: `template_str.replace('{{', '$').replace('}}', '')`로 변환 후 `Template()` 사용. (JOB-1593, 2026-06-13)
5. **하이픈 포함 모듈 import**: 파일명이 `tier-generator.py` 같이 하이픈을 포함하면 `import tier_generator`로 직접 import 불가. **해결**: `engine/__init__.py`의 `load_engine()` 헬퍼 사용 또는 `importlib.util.spec_from_file_location()` 동적 로드.
6. **리턴 타입 불일치**: 각 엔진의 실제 리턴 타입 테스트 전에 확인 필수.
   - `tier-generator.generate_tiers()` → `dict` (L1/L2/L3 키), 리스트 아님
   - `scoring.select_model()` → `tuple` `(model_name, details)`, 딕셔너리 아님
   - `validator.validate_t2()` → `tuple` `(pass, issues, warning)`, 딕셔너리 아님
7. **Image Prompt Builder 함수명**: `build_prompt`가 아님 → `build_image_prompt`. 시그니처: `build_image_prompt(content, target_model, aspect_ratio, detail_level, style_preference, text_overlay)`.
8. **map_visual_elements 시그니처**: 2개 파라미터 필요 `(intent, mood)`. 1개만 전달 시 `TypeError` 발생.

## 11. Domain Wrappers (Phase 4)

`domain_wrappers/` 하위. 기존 스킬 파일 변경 없이 공유 엔진만 연동.

| 도메인 | Wrapper | 기존 스킬 | 연동 엔진 |
|--------|---------|----------|-----------|
| D2 | d2-novel.py | novel-writing | Tier Generator, Tone Adapter, Validator |
| D3 | d3-visual.py | baoyu-comic/infographic/diagram | Tier Generator, Template Filler, Analogy Builder, Image Prompt Builder, Validator |
| D4 | d4-slides.py | seminar-slides | Tier Generator, Tone Adapter, Validator |
| D5 | d5-comfyui.py | comfyui-remote | Tier Generator, Image Prompt Builder, Validator |

**Wrapper 패턴**: `engine/__init__.py`의 `load_engine()`으로 하이픈 모듈 로드 → 엔진 함수 추출 → wrapper 함수 내에서 엔진 호출 후 기존 스킬 구조 반환.