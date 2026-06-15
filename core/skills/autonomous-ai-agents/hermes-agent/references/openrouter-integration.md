# OpenRouter 연동 가이드

## API 엔드포인트

### LLM 모델 (정상 작동)
```
POST https://openrouter.ai/api/v1/chat/completions
```
- 모델: `openai/gpt-5.5`, `x-ai/grok-4.3` 등
- 인증: `Authorization: Bearer {OPENROUTER_API_KEY}`

### 이미지 생성 (⚠️ 404 에러)
```
POST https://openrouter.ai/api/v1/images/generations  → 404
```
**현재 상태**: 이미지 생성 API 엔드포인트 응답 없음 (2026-05-27 확인)
**대안**: ComfyUI 직접 연동 또는 Replicate API 사용 권장

## 비용 추적

**스크립트**: `~/.hermes/scripts/cost-logger.sh`

**사용법**:
```bash
source ~/.hermes/scripts/cost-logger.sh
log_cost "llm" "openai/gpt-5.5" "0.006" "100입력/200출력"
log_cost "image" "flux.2-pro" "0.03" "1024x1024"
```

**출력 예시**:
```
💰 비용: $0.03 (flux.2-pro)
📊 오늘 누적: $0.1500
```

## 모델별 가격 (2026-05-27 기준)

| 모델 | 가격 |
|------|------|
| GPT-5.5 | $0.000005/입력, $0.00003/출력 |
| Grok 4.3 | $0.00000125/입력, $0.000025/출력 |
| Flux.2 Pro | $0.03/MP |
| Flux.2 Max | $0.07/MP |
| Seedream 4.5 | $0.04/이미지 |

## 설정

**config.yaml**:
```yaml
providers:
  openrouter:
    hidden: true  # /model 목록에서 제외
    image_generation:
      require_explicit_request: true  # 명시적 요청 필수
      track_costs: true
```

## 참고
- JOB-1367: OpenRouter 모델 설정
- JOB-1368: 비용 추적 시스템 구축
