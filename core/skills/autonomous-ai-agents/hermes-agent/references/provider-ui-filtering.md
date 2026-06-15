# Provider UI Filtering & Cost Display Control

`/model` 커맨드에서 공급자 숨기기 및 가격 표시 제어 방법.

## config.yaml Provider 속성

### `hidden: true` — 모델 선택 UI에서 숨김

```yaml
providers:
  openrouter:
    hidden: true      # /model 목록에서 제외
```

- `list_authenticated_providers()` 의 모든 섹션에서 체크
- `switch_model()` 직접 호출에는 영향 없음
- `current_provider` 와 동일 → 항상 표시 (hidden 무시)

### `subscription: true` — 가격 표시 억제

```yaml
providers:
  zai:
    subscription: true   # /model 전환 후 Cost 줄 숨김
```

- `gateway/run.py` 의 `_is_subscription_provider()` 메서드에서 확인
- `models.dev` 카탈로그 가격 데이터가 있어도 표시하지 않음
- 구독제(정액제) 공급자에 사용

## 코드 아키텍처

### `hermes_cli/model_switch.py`

`list_authenticated_providers()` 는 4 개 섹션으로 구성:

| 섹션 | 소스 | 설명 |
|------|------|------|
| 1 | `PROVIDER_TO_MODELS_DEV` | models.dev 카탈로그 기반 (기본 URL 사용) |
| 2 | `HERMES_OVERLAYS` | Hermes 전용 프로바이더 (OAuth, SDK 등) |
| 2b | `CANONICAL_PROVIDERS` | 정식 프로바이더 크로스체크 |
| 3 | `user_providers` | config.yaml `providers:` 설정 |
| 4 | `custom_providers` | 레거시 `custom_providers:` 목록 |

**모든 섹션에서 `_is_provider_hidden()` 체크 필요.**

### ⚠️ Section 1 vs config.yaml 충돌 (중요)

`PROVIDER_TO_MODELS_DEV` 에 등록된 공급자가 config.yaml 에도 있으면:
- Section 1 이 **먼저** 처리됨 → models.dev 의 기본(종량제) URL 사용
- config.yaml 의 `base_url` 무시됨

**해결**: Section 1 에서 config.yaml 에 `base_url` 이 설정된 공급자 건너뜀:

```python
# model_switch.py Section 1 내부
if user_providers and isinstance(user_providers, dict):
    ep_cfg = user_providers.get(hermes_id)
    if isinstance(ep_cfg, dict) and ep_cfg.get("base_url"):
        continue  # Section 3 에서 config.yaml URL 로 처리
```

### `gateway/run.py` — 가격 표시

`_is_subscription_provider()` 메서드 (`GatewayRunner` 클래스 메서드):

```python
def _is_subscription_provider(self, provider: str) -> bool:
    # providers.<slug>.subscription: true 확인
```

호출 위치 (2 곳):
1. 모델 피커 콜백 (인라인 모델 전환) — `result.target_provider`
2. 텍스트 모델 전환 (피커 미지원 플랫폼) — `result.target_provider`

## Z.AI API 구분

| 유형 | URL | 결제 | config 속성 |
|------|-----|------|-------------|
| Coding Plan | `api.z.ai/api/coding/paas/v4` | 구독 | `subscription: true` |
| General API | `api.z.ai/api/paas/v4` | 종량제 | `hidden: true` |

## API Key 환경변수

`ZAI_CODING_API_KEY` 는 사용하지 않음. `GLM_API_KEY` 단일 키 사용:

```yaml
# config.yaml
providers:
  zai:
    api_key: env.GLM_API_KEY
```

```env
# .env
GLM_API_KEY=your_key
GLM_BASE_URL=https://api.z.ai/api/coding/paas/v4/
```

## 작업 이력

- JOB-1246: 초기 hidden 기능 구현
- Section 1 vs config.yaml 충돌 발견 후 수정
- `subscription: true` 속성 추가 (가격 표시 억제)

## OpenRouter 이미지 모델 참고

OpenRouter는 LLM 텍스트 모델 외에도 이미지 생성 모델을 제공합니다:
- `black-forest-labs/flux.2-pro`
- `google/gemini-2.5-flash-image`
- `recraft/recraft-v3`
- `sourceful/riverflow-v2-pro`

**참고**: `/api/v1/models` 엔드포인트는 LLM 모델만 반환. 이미지 모델은 별도 API 엔드포인트(`/api/v1/images/generations`)를 사용.
