# OpenRouter 이미지 생성 지원 (2026-05-27 확인)

OpenRouter는 LLM 텍스트 모델 외에도 **이미지 생성 API**를 제공합니다.

## API 엔드포인트

```
POST https://openrouter.ai/api/v1/images/generations
```

**⚠️ LLM 모델 API에는 이미지 모델 미포함**
- `/api/v1/models` — 텍스트 LLM 모델만 반환
- 이미지 모델은 [openrouter.ai/models](https://openrouter.ai/models) 페이지에서 검색 필요
- 또는 브라우저로 `OpenRouter image generation models` 검색

## 지원 모델 (2026-05-27 기준)

### Flux.2 Pro
- **ID:** `black-forest-labs/flux.2-pro`
- **가격:** $0.03/메가픽셀
- **기능:** 최상위 이미지 생성/편집, 프론티어 레벨 시각적 품질

### Seedream 4.5
- **ID:** `bytedance-seed/seedream-4.5`
- **가격:** $0.04/이미지 (크기 무관)
- **기능:** 다중 이미지 구성, 인물 묘사, 소형 텍스트 렌더링

### 기타 모델
- `google/gemini-2.5-flash-image` — 확장 종횡비 지원
- `google/gemini-3.1-flash-image-preview` — 0.5K 해상도
- `recraft/recraft-v4.1` — 텍스트 레이아웃, 스타일 제어
- `sourceful/riverflow-v2-pro` — 폰트 입력, 슈퍼 리졸루션

## 사용 예시

```bash
curl -X POST https://openrouter.ai/api/v1/images/generations \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "black-forest-labs/flux.2-pro",
    "prompt": "a beautiful sunset over mountains",
    "size": "1024x1024"
  }'
```

## 응답 형식

```json
{
  "data": [
    {
      "url": "https://...",
      // 또는 "b64_json": "base64 인코딩 이미지 데이터"
    }
  ]
}
```

## 현재 시스템과의 관계

| | ComfyUI | OpenRouter |
|---|---|---|
| Flux 모델 | ✅ 직접 실행 | ✅ API |
| Seedream 4.5 | ❌ | ✅ |
| LoRA | ✅ 커스텀 | ❌ |
| 비용 | GPU 시간 ($0.15/hr) | 생성당 과금 |
| 유연성 | 완전 제어 | 제한적 |

**JOB-1367**: OpenRouter 이미지 모델 설정 추가 및 비용 추적 시스템 구축 중
