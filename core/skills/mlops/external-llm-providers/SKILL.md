---
name: external-llm-providers
description: Configure, troubleshoot, and use external LLM API providers (Z.AI/OpenRouter/custom) via curl or delegate_task. Documents provider-specific quirks, endpoint patterns, and authentication flows.
---

# External LLM API Providers

직접 curl 호출 또는 delegate_task로 외부 LLM API를 사용하거나 설정할 때 참조.

## 제공자 목록
> **참조**: `/core/config/model-roles.yaml` (모델-역할 매핑)

| 제공자 | base_url | 인증 | 비고 |
|--------|----------|------|------|
| Z.AI (Coding Plan) | `https://api.z.ai/api/coding/paas/v4` | Bearer $GLM_API_KEY | 구독형, 코딩 전용이지만 일반 chat도 가능 |
| Z.AI (General) | `https://api.z.ai/api/paas/v4` | Bearer $GLM_API_KEY | 종량제, 잔액 필요 |
| Airrouter | `https://api.airouter.ch/v1` | Bearer sk-xxx | 라우팅 서비스 |

## Z.AI Coding Plan API 퀵 가이드

### 환경변수
```bash
source ~/.hermes/.env
export GLM_API_KEY
```

### 표준 호출 (curl)
```bash
curl -s --max-time 30 -X POST "https://api.z.ai/api/coding/paas/v4/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $GLM_API_KEY" \
  -d '{
    "model": "glm-4.7",
    "messages": [{"role": "user", "content": "prompt here"}],
    "max_tokens": 2000
  }'
```

### 등록 모델 (Coding Plan 구독제)
- `get_model_for_role("creative")` — **최신**. Long Horizon Task 전용 (최대 8 시간 autonom 작업). reasoning 모델, 3분+ 소요
- `glm-5-turbo` — reasoning 모델 (content 생성에 고토큰 필요), 중간 속도 (~90초)
- `glm-4.7` — 일반 추론 (비-reasoning), 가장 빠름 (~30초). **창의 작업에 추천** (소설, 시, 아이디어)
- `glm-4.5-Air` — 경량 모델, 빠른 응답

### 등록 모델 (General 종량제)
- `get_model_for_role("creative")`, `glm-5-turbo`, `glm-5`, `glm-4.7`, `glm-4.6`, `glm-4.5`, `glm-4.5-Air` 등
- GLM-5.1 가격: 입력 6-8원, 출력 24-28원/백만 tokens (입력 길이 32K 기준)

**모델 선택 가이드**:
- 빠른 응답 필요: `glm-4.7`
- 창의 작업 (소설/시/아이디어): `glm-4.7` 또는 `glm-5-turbo` (사용자 학습: GLM이 Qwen3.6보다 창의성 우수)
- 심층 추론: `glm-5-turbo` (max_tokens 8000+)
- 최상위 품질 (시간寛容): `get_model_for_role("creative")` (max_tokens 8000+, 백그라운드 실행 필수)
- **장기 자율 작업**: `get_model_for_role("creative")` (Long Horizon Task: 8 시간 autonom 작업, 스스로 계획→실행→진화)

## 발견된 퀼크 (Pitfalls)

### 1. Trailing slash 주의
`base_url`에 trailing slash(`/`)가 있으면 인증/라우팅 실패.
- ✅ `https://api.z.ai/api/coding/paas/v4/chat/completions`
- ❌ `https://api.z.ai/api/coding/paas/v4//chat/completions`

### 2. GLM-5-turbo reasoning 토큰 과소비
`glm-5-turbo`는 reasoning 모델. `max_tokens`의 대부분이 `reasoning_content`에 소모됨.
- `max_tokens: 100` → reasoning 97, content 0 (빈 응답)
- **해결**: `max_tokens: 500+` 사용 또는 `content`가 필요 없으면 `reasoning_content`만 확인

### 3. API 상태 점검 시 bash escaping 함정 (JOB-1477)
- **문제**: curl bash heredoc/escaping 실패 → 401 에러 오진 다발
- **해결**: Python requests 사용 권장
- **.env 파싱**: `startswith('GLM_API_KEY=*** 사용 (다른 키와 혼동 방지)

```python
import os, requests
key = ""
for line in open(os.path.expanduser('~/.hermes/.env')):
    if line.startswith('GLM_API_KEY=***        key = line....resp = requests.post('https://api.z.ai/api/coding/paas/v4/chat/completions', headers={'Authorization': f'Bearer {key}'}, json={'model':'get_model_for_role("creative")','messages':[{'role':'user','content':'hi'}],'max_tokens':100}, timeout=30)
print('✅' if resp.status_code == 200 else f"❌ {resp.status_code}")
```
- `max_tokens: 8000+` → 실제 content 생성

**해결**: content가 필요하면 `max_tokens`를 5000 이상으로 설정하거나, `glm-4.7` 사용.

### 3. 한국어 요청 응답 지연
한국어 프롬프트 또는 긴 요청 시 응답 시간이 길어짐 (30초+ 타임아웃 발생 가능).
- 짧은 영어 요청: 1-2초 응답
- 긴 한국어 요청: 30초+ 또는 타임아웃

**해결**: `--max-time 60` 또는 요청 단순화.

### 4. General API 잔액 부족
종량제 API는 잔액이 없으면 `Insufficient balance` 에러. Coding Plan(구독)으로 대체 가능.

### 5. config.yaml API 키 마스킹 (Hermes)
Hermes가 config.yaml을 저장할 때 API 키가 마스킹된 값(예: `sk-MNP...cl0Q`)으로 덮어쓰일 수 있음. 마스킹된 키로 인증하면 `token_not_found_in_db` 401 에러 발생 → Hermes가 자동으로 다른 provider로 폴백.

**증상**: `/model` 확인 시 예상과 다른 provider/model이 표시됨. Airrouter 키가 무효화되어 GLM로 폴백된 것이 대표적 사례.

**진단**:
```bash
# config.yaml의 키가 마스킹되었는지 확인
grep 'api_key' ~/.hermes/config.yaml
# 실제 환경변수 키로 API 테스트
curl -s --max-time 15 https://api.airouter.ch/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $AIROUTER_API_KEY" \
  -d '{"model":"Qwen3.6","messages":[{"role":"user","content":"hi"}],"max_tokens":5}'
```

**해결**: config.yaml의 `api_key` 값을 **실제 키값**으로 직접 기록:\n\n⚠️ `env.환경변수명` 형식은 **사용 금지**. Hermes는 `api_key` 필드에서 `env.` 접두사를 환경변수로 해석하지 않고, 리터럴 문자열 그대로 API에 전송합니다 → `HTTP 401: Received=env.AIROUTER_API_KEY, expected to start with 'sk-'` 에러 발생.\n\n**안전한 방법** (쉘에서 sed로 치환, `$`는 쉘이 자동 확장):\n```bash\n# model 섹션\nsed -i "s|api_key: sk-MNP.*cl0Q|api_key: $AIROUTER_API_KEY|" ~/.hermes/config.yaml\n# 또는 환경변수명 다른 경우\nsed -i "s|api_key: env.AIROUTER_API_KEY|api_key: $AIROUTER_API_KEY|" ~/.hermes/config.yaml\n```\n\n**custom_providers 섹션도 함께 확인** (동일한 마스킹 키가 중복 저장되는 경우가 많음):\n```bash\ngrep -n 'sk-MNP' ~/.hermes/config.yaml  # 마스킹된 키 위치 확인\n```\n\n변경 후 Hermes 재시작 필요 (`/restart`).

### 6. 느린 모델은 백그라운드 실행
### 7. 스크립트에서 엔드포인트 하드코딩 금지 (JOB-1350)
스크립트에서 API 엔드포인트를 하드코딩하면 config.yaml 변경 시 불일치 발생.
```bash
# ❌ 하드코딩 — config.yaml과 불일치 가능
curl -X POST "https://api.z.ai/v1/chat/completions"

# ✅ config.yaml 값 사용
source ~/.hermes/.env
curl -X POST "${GLM_BASE_URL}chat/completions"

# ✅ 또는 config.yaml에서 직접 추출
base_url=$(grep 'base_url' ~/.hermes/config.yaml | awk '{print $2}')
curl -X POST "${base_url}chat/completions"
```

### 8. 모델명 대소문자 민감 (Airrouter) (JOB-1350)
Airrouter는 모델명이 대소문자 구분됨.
```bash
# ❌ 실패 — 401 Unauthorized
"model": "qwen3.6"

# ✅ 성공
"model": "Qwen3.6"
```
에러: `"This key can only access models=['Qwen3.6']. Tried to access qwen3.6"`

### 9. cron 컨텍스트에서 .env 로딩 (JOB-1350)
crontab은 non-interactive shell로 실행 → .bashrc/.profile 미로딩 → .env 미적용
```bash
# ❌ cron에서 실패 — 환경변수 없음
0 * * * * /path/to/script.sh

# ✅ 각 스크립트 내부에서 로딩
# script.sh 시작 부분에 추가
if [ -f "$HOME/.hermes/.env" ]; then
    export $(grep -v '^#' "$HOME/.hermes/.env" | xargs)
fi

# ✅ 또는 crontab에서 직접 소싱
0 * * * * source ~/.hermes/.env && /path/to/script.sh
```
GLM-5.1 등 느린 모델(3분+)은 foreground에서 타임아웃 발생.
```bash
# 백그라운드로 실행
source ~/.hermes/.env && curl -s --max-time 180 -X POST "..." -o /tmp/result.json &
# 또는 Hermes background terminal 사용
```

## delegate_task에서 모델 지정 불가 — terminal 직접 호출

**⚠️ delegate_task는 별도 모델 파라미터를 지원하지 않음**. 서브에이전트는 항상 현재 세션 모델을 따름.

**해결: terminal에서 직접 GLM-5.1 API 호출** (Python requests 또는 curl)

### Python requests 방식 (권장)
```python
import os, requests

api_key = os.environ['GLM_API_KEY']
base_url = "https://api.z.ai/api/coding/paas/v4/"

resp = requests.post(
    f"{base_url}chat/completions",
    headers={
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    },
    json={
        "model": "get_model_for_role("creative")",
        "messages": [
            {"role": "system", "content": "system prompt"},
            {"role": "user", "content": "your prompt here"}
        ],
        "temperature": 0.9,
        "max_tokens": 12000
    },
    timeout=180
)
content = resp.json()['choices'][0]['message']['content']
```

### curl 방식
```bash
curl -s --max-time 180 -X POST "https://api.z.ai/api/coding/paas/v4/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $GLM_API_KEY" \
  -d '{
    "model": "get_model_for_role("creative")",
    "messages": [{"role":"user","content":"prompt"}],
    "temperature": 0.9,
    "max_tokens": 12000
  }'
```

### 퀼크
- **환경변수**: `execute_code` 샌드박스에서는 `$GLM_API_KEY` 미로딩 → **terminal에서 실행 필수**
- **타임아웃**: GLM-5.1은 응답이 느림 (30초~3분). `timeout=180` 또는 `--max-time 180` 필수
- **base_url**: config.yaml의 `zai.base_url` 값 사용 (`https://api.z.ai/api/coding/paas/v4/`)
- **짧은 응답 문제 **(JOB-1367) GLM-5.1이 때로 200-500자만 반환. 프롬프트에 "**최소 X자 이상 장황하게 상세하게 작성**" 명시 + `max_tokens: 20000` 설정. 또는 짧은 응답 받으면 "아래 내용을 X자로 확장하여 작성" 재요청

## 문제 해결 체크리스트

1. API 키 확인: `echo $GLM_API_KEY` → 설정되어 있어야 함
2. 환경변수 로드: `source ~/.hermes/.env`
3. 엔드포인트 검증: 짧은 영어 요청으로 테스트
4. 토큰 설정 확인: reasoning 모델이면 max_tokens 5000+ 필요
5. 타임아웃 설정: `--max-time 60` 이상으로 설정

---

## Provider Model Configuration (§ absorbed from provider-model-config, provider-model-list-resolution)

### 모델 설정 검증 워크플로우

1. **현재 설정 확인**: `grep -A5 "providers:" ~/.hermes/config.yaml`
2. **모델 메타데이터 확인**: `~/.hermes/hermes-agent/agent/model_metadata.py`
   - `DEFAULT_CONTEXT_LENGTHS` (line ~137)
   - `_URL_TO_PROVIDER` 매핑 (line ~335)
3. **설정 항목 검증**:
   - `context_length`: 모델 스펙에 맞춤
   - `max_tokens`: 작업 유형에 맞춤
   - `reasoning`: 모델 지원 여부 확인 (GLM-4.7: ❌, GLM-5-Turbo/5.1: ✅)

### config.yaml 구조

```yaml
providers:
  <provider>:
    api_key: env.KEY_NAME
    base_url: https://api.example.com/v1
    default_model: model-name
    models:
      model-id:
        name: Display Name
        context_length: 131072
        max_tokens: 65536
        reasoning: true/false
```

### ⚠️ 슬래시 커맨드 모델 목록: 3출처 병합

**중요**: 슬래시 커맨드 모델 목록은 3개 출처가 병합되며, **models.dev 캐시가 최우선**입니다.

```
1. models.dev 캐시 (~/.hermes/models_dev_cache.json) → 최우선
2. _PROVIDER_MODELS[provider_id] (hermes_cli/models.py) → 코드 고정
3. config.yaml providers.<provider>.models → 사용자 정의
```

**❌ 함정**: config.yaml만으로 모델 숨김 불가 — models.dev 캐시가 최우선이므로 config.yaml 명시적 모델이 없으면 캐시 모델 표시됨.

**✅ 해결**: config.yaml에 `providers.{id}.models` 명시적 정의 시 `provider_model_ids()`가 그것만 반환하도록 코드 수정 필요.

### Z.AI / GLM 모델 스펙

| 모델 | context_length | max_tokens | reasoning |
|------|---------------|------------|-----------|
| GLM-4.7 | 131,072 | 65,536 | ❌ |
| GLM-5-Turbo | 131,072 | 128,000 | ✅ |
| GLM-5.1 | 202,752 | 128,000 | ✅ |

- **GLM-4.7**: reasoning 미지원 — `reasoning: true` 설정 시 API 400 에러
- **⚠️ 직접 API 만료 **(JOB-1412) `api.z.ai` 토큰이 2026-05-31 기준 만료됨. OpenRouter 경유 (`z-ai/get_model_for_role("creative")`) 사용 필수.

## 관련 파일
- 설정: `~/.hermes/.env`
- Hermes config: `~/.hermes/config.yaml` (zai 섹션)
- 세션 퀼크: `references/zai-coding-plan-quirks.md`
