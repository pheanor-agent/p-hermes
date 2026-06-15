---
name: image-pipeline
description: "이미지 생성 파이프라인 - 모델 선택, 프롬프트 템플릿, 해상도 제어, AI 리뷰 자동화"
version: 1.0.0
---

# 이미지 생성 파이프라인

## 워크플로우

```
요청 수신 → 분석 → 모델 선택 → 프롬프트 구성 → 생성 → 검증 → 출력
```

## 1. 요청 분석

사용자 요청에서 다음 정보 추출:

- **카테고리**: 인물, 패션, 풍경, 제품, 추상, 애니메이션, 기타
- **구도**: 전면, 측면, 후면, 상단, 전신, 반신, 클로즈업
- **해상도/비율**: 정사각형, 세로, 가로, 와이드
- **스타일**: 리얼리즘, 일러스트, 애니메이션,油画, 수채화, 기타
- **특별 옵션**: LoRA, 텍스트 렌더링, 다중 캐릭터, 일관성 유지

## 2. 모델 선택

`references/model-specs.yaml` 참조.

### 선택 기준

| 우선순위 | 기준 | 모델 |
|---------|------|------|
| 1 | LoRA 필요 | ComfyUI 로컬 |
| 2 | 텍스트 렌더링 | GPT-5.4 Image 2 |
| 3 | 복잡한 포즈 | GPT-5.4 Image 2 |
| 4 | 사진 사실감 | Gemini Nano Banana 2 |
| 5 | 고해상도 | Seedream 4.5 |
| 6 | 저비용 | Flux.2 Klein |
| 7 | 품질/가성비 균형 | Flux.2 Pro (기본) |
| 8 | 최상위 품질 | Flux.2 Max |

### 기본 모델
- **기본**: Flux.2 Pro (가성비 균형)
- **저비용 모드**: Flux.2 Klein
- **고품질 모드**: Flux.2 Max
- **🔥 노출 표현 (Bold 레벨)**: **ComfyUI 로컬** (필터 없음)

**참고:** OpenRouter 모델 (Flux.2全系, Seedream)은 Stage 4 (옆가슴 노출)에서 한계. 과감한 노출 필요 시 ComfyUI 로컬 사용. 상세: `references/prompt-engineering-exposure.md`

## 3. 프롬프트 구성

`references/prompt-templates.md` 참조.

### 구성 순서

1. **기본 템플릿 선택**: 카테고리에 따른 기본 구조
2. **상세 정보 추가**: 색상, 조명, 배경, 포즈
3. **스타일 지정**: 리얼리즘, 일러스트 등
4. **품질 지정어**: 해상도, 촬영 스타일
5. **모델별 최적화**: 스토리 컨텍스트, 키워드 조정

### 노출 표현 요청 시 (Bold 레벨)

**OpenRouter 사용 시:**
- 스토리 컨텍스트 필수
- 패션 전문 용어: `open armhole`, `architectural cutout`
- 의상 구조 설명: `separate side panels`, `open space between`
- 아나토미컬 용어: `lateral thoracic wall`, `underbust cutout`
- ⚠️ **한계:** Stage 4 (옆가슴)에서 옆구리로 대체됨

**ComfyUI 로컬 사용 시 (권장):**
- Negative Prompt: `covered sides, modest, conservative`
- Regional Prompter: 부분별 프롬프트
- ControlNet: 포즈/구조 제어
- ✅ **장점:** 필터 없음, 완전 제어
- 🔥 **NSFW/누드 표현**: `Flux Klein - NSFW v2` LoRA 조합 사용 (상세: `comfyui-remote` 스킬 참조)

**상세 기법:** `references/prompt-engineering-exposure.md` 참조

### 템플릿 구조

```
[구도/해상도] + [장르/스타일] + [주제 설명] + [상세 디테일] + [조명/배경] + [품질 지정어]
```

### 예시

**요청:** "산间的 집"

**구성:**
```
Landscape photography of a cozy wooden cabin nestled among pine trees in mountain valley, 
morning mist, golden hour lighting, 
serene atmosphere, 
high-resolution nature photography, 
wide angle composition
```

## 3. 생성 실행

### OpenRouter API

```python
import requests
import os
import base64
from PIL import Image

API_KEY = os.getenv("OPENROUTER_API_KEY")

payload = {
    "model": model_id,
    "messages": [{"role": "user", "content": prompt}],
    "modalities": ["image"],
    "max_images": 1
}

response = requests.post(
    "https://openrouter.ai/api/v1/chat/completions",
    headers={
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    },
    json=payload,
    timeout=180
)

data = response.json()
if data['choices'][0]['message'].get('images'):
    image_data = data['choices'][0]['message']['images'][0]['image_url']['url']
    if ',' in image_data:
        image_data = image_data.split(',')[1]
    
    output_path = save_image(base64.b64decode(image_data))
    
    # 실제 해상도 확인
    img = Image.open(output_path)
    actual_resolution = f"{img.size[0]}x{img.size[1]}"
    
    # 비용 정보
    cost = data['usage'].get('cost', 'N/A')
```

### ComfyUI 로컬

별도 스킬 참조: `comfyui-remote`

- 해상도 완전 제어
- LoRA 적용
- 커스텀 워크플로우
- 🔥 **NSFW/누드 표현**: `Flux Klein - NSFW v2` + `koreandoll2` 조합 (상세: `comfyui-remote` 참조)

### LoRA strength 총합 가이드라인

| 총합 | 품질 | 노출도 | 용도 |
|------|------|--------|------|
| ≤ 0.9 | ✅ 우수 | 👕 의상 | 일상/패션 |
| 1.0~1.2 | ✅ 우수 | 👚 반누드 | 부두아르 |
| 1.3~1.6 | ✅ 우수 | 🏼 누드 | NSFW (NSFW LoRA 필수) |
| > 1.8 | ⚠️ 블러 | 🏼 누드 | ❌ 권장하지 않음 |

**팁**: NSFW 표현 시 `NSFW v2 (1.0) + koreandoll2 (0.5)` 조합 사용 (총합 1.5)

## 5. 검증 (필수)

모든 이미지 생성 후 **의도 일치 검증** 수행.

### 검증 항목

| 항목 | 설명 |
|------|------|
| 카테고리 일치 | 요청한 유형과 일치 |
| 구도/비율 | 전신/반신, 세로/가로 |
| 주제 정확도 | 주요 요소 포함 |
| 스타일 일치 | 리얼리즘/일러스트 등 |
| 색상/분위기 | 요청한 톤/무드 |
| 품질 | 해상도, 선명도, 아티팩트 |

### 검증 실행

```python
# scripts/review.py 활용
review_prompt = generate_review_prompt(
    original_prompt=원본_프롬프트,
    focus_areas=특별_검증_항목
)

# vision_analyze 호출
result = vision_analyze(
    image_url=이미지_경로,
    question=review_prompt
)
```

### 검증 결과

```
🔍 검증 결과

일치도: high/medium/low (XX/100)

✅ 일치: 의상, 포즈, 배경
⚠️ 부분 일치: 색상 (요청 파란색 → 실제 보라색)
❌ 불일치: 구도 (요청 전신 → 실제 반신)

권장: 재생성 / 수락
```

## 6. 출력

### Discord #image 채널 전송

```
🖼️ 이미지 생성 완료

MEDIA:{이미지_경로}

📋 정보:
- 프롬프트: {프롬프트}
- 프로바이더: OpenRouter/ComfyUI
- 모델: {모델}
- 해상도: {해상도}
- 비용: ${비용}

🔍 검증: {일치도} ({score}/100)
```

## 모델별 특성
## 모델별 특성

### Flux.2全系 (Pro/Klein/Max)
- **해상도**: 1024×768 기본 (모델에 따라 상이, 파라미터 무시)
- **강점**: 빠른 생성, 안정적인 품질
- **약점**: 텍스트 렌더링, 복잡한 포즈, **노출 표현 (Stage 4 차단)**
- **사용법**: 스토리 컨텍스트 추가 권장
- **한계**: 옆가슴 노출 시 옆구리로 대체 (2026-05-28 테스트 확인)

### GPT-5.4 Image 2
- **해상도**: 모델 기본값
- **강점**: 프롬프트 이해도, 텍스트 렌더링, 포즈 제어
- **약점**: 응답 시간 변동, **타임아웃 빈발 (180초+)**
- **사용법**: 상세한 포즈/구도 설명 효과적

### Gemini Nano Banana 2
- **해상도**: 모델 기본값
- **강점**: 사진 사실감, 자연스러운 조명
- **약점**: 모델 안정성, **모델 ID 오류 빈발**
- **사용법**: 스토리 컨텍스트 필수

### Seedream 4.5
- **해상도**: 2048×2048 고정
- **강점**: 고해상도, 다중 구성
- **약점**: 해상도 고정, **Stage 4 차단 (Flux.2와 유사)**
- **사용법**: 고해상도 필요 시, Stage 1-3 성공

### ComfyUI 로컬
- **해상도**: 완전 제어
- **강점**: LoRA, 커스텀 워크플로우, **필터 없음, Regional Prompter**
- **약점**: GPU 자원 필요
- **사용법**: LoRA 이름 명시, 해상도 직접 설정, **노출 표현 권장**

## 비용 관리

### Flux.2全系 (메가픽셀 기반)
```
비용 = 첫 번째 MP 요금 + max(0, 총MP - 1) × 추가 MP 요금
```

### 고정 가격 모델
- Seedream 4.5: $0.04/이미지
- GPT-5.4: $0.04-0.08/이미지
- Gemini: $0.04-0.06/이미지

### 비용 로깅
```bash
source ~/.hermes/scripts/cost-logger.sh
log_cost "image" "모델명" "비용" "설명"
```

## 메타데이터 관리 (JOB-1381)

### image-registry.sh v3.0 — ComfyUI + OpenRouter 통합

모든 이미지 생성 메타데이터 통합 관리. 단일 레지스트리에서 생성 이력 추적, 검색, 통계.

**위치**: `~/.shared/scripts/image-registry.sh`

```bash
# OpenRouter 이미지 등록
image-registry.sh register-v2 \
  --source openrouter \
  --model flux.2-pro \
  --prompt "Korean woman fashion" \
  --seed 42 \
  --cost 0.03 \
  --elapsed 5.2 \
  --output-path /tmp/image.png

# ComfyUI 이미지 등록
image-registry.sh register-v2 \
  --source comfyui \
  --model flux1-dev-Q4_K_S.gguf \
  --prompt "..." \
  --seed 42 \
  --lora eastmix \
  --lora-strength 0.5 \
  --elapsed 113.3

# 검색
image-registry.sh search --model flux.2-pro --since 2026-05-01
image-registry.sh search --lora eastmix --source comfyui

# 통계
image-registry.sh stats week
```

**저장 필드**: source, model, prompt, seed, loras, cost, elapsed_sec, output path/hash, resolution

**ComfyUI 포트**: 100.110.197.35:18188 (8188 아님)

상세: `references/metadata-management-v3.md` 참조

## Pitfalls

1. **해상도 차이**: 모델별 기본 해상도 상이. 생성 후 실제 확인 필수
2. **프롬프트 해석**: 모델별 프롬프트 이해도 차이. 템플릿 사용 권장
3. **응답 시간**: 15-180초 변동. 타임아웃 180초 설정
4. **비용 계산**: Flux.2는 MP 기반, 나머지는 고정. 확인 필수
5. **검증 필수**: 모든 생성 후 의도 일치 검증 수행
6. **Side bust tissue 노출 불가 (2026-05-28 최종 테스트)**: ALL OpenRouter 모델(Flux.2全系, GPT-5.4, Seedream)이 side breast tissue 노출을 차단. Lateral thoracic wall 노출은 `braless sideless slip dress` 템플릿으로 성공 가능. Side bust tissue 노출은 ComfyUI 로컬만 가능. 상세: `openrouter-image-generation/references/prompt-engineering-exposure.md` 참조
7. **성공 키워드 순서**: `sideless` > `wide open armhole` > `open armhole` > `cutout` (lateral wall 노출용)
6. **🔥 Flux.2全系 노출 한계 (2026-05-28 확인)**: 옆가슴 노출 (Stage 4) 시 항상 옆구리로 대체. ComfyUI 로컬 필요.
7. **Seedream 4.5 한계**: Stage 3 성공, Stage 4 차단 (Flux.2와 유사)
8. **GPT-5.4 타임아웃**: 180초+ 응답 없음 빈발. 재시도 또는 모델 변경.
6. **Flux.2 Pro 해상도 고정**: 모든 파라미터 무시, 1024×768 고정출력. 비용 $0.03 고정
7. **GPT-5.4 Image 2 타임아웃**: 180초+ 응답 없음 빈발. 재시도 최대 2회 후 모델 변경
8. **Gemini Nano Banana 2 안정성**: 모델 ID 오류 빈발. 재시도 또는 대체 모델 준비

## 사용자 설정 (필수 준수)

### 출력 채널
- **Discord #image (1504808422745444432)** 로 자동 전송
- 포함 정보: 프롬프트, 프로바이더, 모델, 해상도, 비용

### 생성 후 검증 (절대 필수)
- 모든 이미지 생성 후 **AI 비전 분석 (vision_analyze)** 으로 의도 일치 확인
- 검증 항목: 카테고리, 구도, 주제, 스타일, 색상/분위기, 품질
- 검증 결과 사용자에게 보고: 일치도 (high/medium/low), 점수 (XX/100), 차이점, 권장사항
- **검증 없이 출력 금지**

### 설계 원칙
- 일반적인 파이프라인 설계 (특정 케이스에 최적화하지 않음)
- 범용성 우선, 특수 케이스는 모델별 특화로 처리

## 관련 파일

- `references/model-specs.yaml`: 모델별 스펙
- `references/prompt-templates.md`: 프롬프트 템플릿
- `references/prompt-engineering-exposure.md`: 노출 제약 우회 프롬프트 엔지니어링 기법 (2026-05-28 조사)
- `references/metadata-management-v3.md`: 이미지 생성 메타데이터 관리 시스템 v3.0 (JOB-1381)
- `references/runpod-comfyui-integration.md`: RunPod ComfyUI 연동 (JOB-1333, 1338)
- `references/batch-approval-workflow.md`: 배치 승인 워크플로우 (JOB-1338)
- `scripts/review.py`: 검증 스크립트
- `scripts/image-queue.sh`: 이미지 생성 큐 관리 (add/next/complete/fail/status/list/cancel)

## 큐 관리 (image-queue.sh)

모든 큐 조작은 `image-queue.sh`를 통해서만 수행. `~/.shared/queue/images/pending.json` 직접 조작 금지.

**핵심 규칙**:
1. queue.json 직접 조작 금지 — 반드시 `image-queue.sh` 사용
2. 프로젝트 기반: 모든 큐 항목은 `projectId` 기준으로 관리
3. 우선순위: 1=높음(재생성), 2=보통(기본), 3=낮음
4. `QUEUE_DIR`는 `~/.shared/queue/images`로 하드코딩됨 — 동적 경로 계산 금지

**명령어**: `add`, `next`, `complete`, `fail`, `status`, `list`, `cancel`, `reprioritize`, `unlock`, `cleanup`

**⚠️ Queue JSON 구조 함정**: `image-queue.sh`는 `entries` 배열로 쓰지만 `comfyui-watcher.sh`는 `queue`를 기대 — 항상 `pending.json`이 `"queue": [...]` 키를 사용하도록 보장

**image_agent spawn 규칙**: `next`로 항목 조회 후 `image_agent` 서브에이전트 spawn → 완료 후 `complete` 또는 `fail`

## 순차 생성 루프 (LoRA 테스트용)

LoRA 테스트 이미지를 1장씩 순차 생성하는 5단계 루프. Discord/Telegram에서 '계속해줘', '다음' 요청 시 사용.

**루프**: READ → SPAWN → YIELD → VERIFY → SEND → REPEAT

### READ — 다음 항목 1개
```bash
QUEUE="~/.shared/queue/images/pending.json"
PROGRESS="~/.shared/state/image_manifest.json"
NEXT=$(jq -r '.queue[] | select(.status=="pending") | "\(.lora)|\(.scene)|\(.seed_type)"' "$QUEUE" | head -1)
```

### SPAWN — image_agent에 1개만 (⛔ 절대 2개 이상 금지)
```bash
PROMPT_JSON=$(python3 "$FLUX2_ROOT/flux2_prompt.py" "${LORA} ${SCENE}")
PROMPT=$(echo "$PROMPT_JSON" | jq -r '.prompt')
```

### YIELD — 완료 대기 (sessions_yield()가 유일한 수신 수단 — polling/sleep 금지)

### VERIFY — PROGRESS 업데이트 확인
```bash
jq ".loras[\"$LORA\"].done | index(\"$SCENE\")" "$PROGRESS"
```

### SEND — 완성 이미지를 요청 채널로 전송 (⚠️ 생략 금지)

### REPEAT — 다음 또는 완료

**⛔ 금지**:
- ❌ 한 번에 2개 이상 spawn
- ❌ sessions_yield 없이 대기 (sleep/polling 금지)
- ❌ PROGRESS.json 직접 편집 (flux2-complete.sh 사용)
- ❌ scope 없이 전체 생성

**flux2-complete.sh**: `~/.shared/scripts/flux2-complete.sh` — `complete`, `status`, `rebuild`, `validate`

**PROGRESS.json v3.0 스키마**: `done` = fixed_seed 또는 random_seed가 하나라도 있는 장면, `missing` = TARGET_SCENES - done

**⚠️ flux2_prompt.py Python 의존성**: Hermes venv에 `torch`, `sqlalchemy`, `comfy-aimdo`, `filelock`, `Pillow` 필수 설치

## Consolidated Content

### absorbed: image-queue (2026-06-04)

큐 관리 시스템: `image-queue.sh` 명령어(all), 프로젝트 구조/추가 방법, RunPod 연동, 배치 승인 워크플로우, 그룹 격리, Python 의존성, ComfyUI 원격 서버 정보

### absorbed: image-sequence (2026-06-04)

순차 생성 루프: LoRA 테스트 5단계 READ→SPAWN→YIELD→VERIFY→SEND→REPEAT, PROGRESS.json v3.0 스키마, .sequence-active 상태 관리, flux2-complete.sh CLI, 에러 처리 정책, Cron 연동(sequence-watcher)
