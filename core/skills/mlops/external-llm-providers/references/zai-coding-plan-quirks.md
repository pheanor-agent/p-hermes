# Z.AI Coding Plan API - Session Quirks (2026-05-22)

## 발견 시점
JOB 미등록 세션 - 페아노르가 GLM-5.1 모델로 웹소설 제목 생성 요청.

## 초기 오해
"Coding Plan은 코딩 전용이라 chat completions 미지원" → **거짓**. 실제 테스트 결과 일반 대화 가능.

## 테스트 기록

### 성공: 짧은 영어 요청 (glm-4.7)
```bash
curl -s -X POST "https://api.z.ai/api/coding/paas/v4/chat/completions" \
  -H "Authorization: Bearer $GLM_API_KEY" \
  -d '{"model":"glm-4.7","messages":[{"role":"user","content":"hello"}],"max_tokens":100}'
```
응답: 1667 bytes, 1-2초 내 응답 ✅

### 실패: trailing slash 포함
```bash
# ~/.hermes/config.yaml base_url에 trailing slash 있음
GLM_BASE_URL=https://api.z.ai/api/coding/paas/v4/
```
→ `/v4//chat/completions` 로 요청 → 실패 ❌

### 실패: GLM-5-turbo 토큰 부족
```json
{"max_tokens": 100}
```
→ reasoning_content 97 tokens, content 0 tokens → 빈 응답 ❌

### 실패: 한국어 요청 타임아웃
```bash
curl -s --max-time 30 ... -d '{"messages":[{"content":"마이너 웹소설..."}]}'
```
→ 30초 초과, 응답 없음 ❌
→ `--max-time 60` 으로 증가 필요

## General API vs Coding Plan
| 항목 | General API | Coding Plan |
|------|-------------|-------------|
| 엔드포인트 | `/api/paas/v4` | `/api/coding/paas/v4` |
| 과금 | 종량제 (잔액 필요) | 구독형 |
| 잔액 상태 | 부족 ❌ | 정상 ✅ |
| 일반 chat | 지원 | 지원 (테스트 확인) |
| 사용 가능 모델 | GLM-5.1/5-Turbo/5/4.7/4.6/4.5/4.5-Air | **GLM-5.1/5-Turbo/4.7/4.5-Air** |

## GLM-5.1 모델 정보 (2026-05-23 확인)
- **Coding Plan 구독제에서 사용 가능** ✅
- Long Horizon Task 전용 설계: 1 회 작업에서 최대 8 시간 autonom 작업
- 스스로 계획→실행→자기 진화→완성된 결과물 제공
- 가격 (General API 기준): 입력 6-8원, 출력 24-28원/백만 tokens

## 교훈
1. "코딩 전용 API는 일반 chat 안 된다"는 가정 검증 필요
2. reasoning 모델은 토큰 소비 패턴이 다름
3. trailing slash는 무해해 보이지만 라우팅에 영향
4. 한국어 요청이 영어보다 느릴 수 있음 (서버 측 처리 차이?)
5. **GLM-5.1은 Coding Plan 구독제에서도 사용 가능** — 코딩뿐만 아니라 Long Horizon Task (장기 자율 작업)에 최적화
