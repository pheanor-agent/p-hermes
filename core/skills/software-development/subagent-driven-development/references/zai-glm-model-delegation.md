# Z.AI / GLM 모델 서브에이전트 위임 문제

## 발견된 문제 (JOB-1256/1274)

### 증상
- `delegate_task`에 `model={"model": "glm-5.1", "provider": "zai"}` 명시적 전달
- 서브에이전트가 600초 타임아웃 발생
- gateway 로그에 GLM-5.1 호출 기록 **전무**
- 모든 API 호출이 `Qwen3.6`으로 처리됨

### 원인 분석
1. **Z.AI API 직접 curl 테스트: 정상** (HTTP 200)
2. **config.yaml 설정: 정상** (`providers.zai` 섹션에 GLM-5.1 정의)
3. **문제점**: `delegate_task`의 모델 파라미터가 gateway에 전달되지 않는 것으로 판단
   - gateway 로그 확인: `provider=custom model=Qwen3.6`으로 폴백
   - GLM-5.1 관련 로그 없음

### 영향
- 소설 본문 작성 시 GLM-5.1 모델 사용 불가
- 모델별 결과물 차이(창의성/분량/문체)로 품질 저하

### 임시 해결 방안
1. **메인 세션에서 직접 GLM-5.1 호출** (delegate_task 사용 안 함)
2. **gateway 재시작** — 프로바이더 설정 리로드 시도
3. **사용자 승인 후 다른 모델 폴백** — 임의 교체 금지

### 참고
- `hermes doctor`에서 `Z.AI / GLM` 인증 확인됨
- `hermes config show`에서 `providers.zai` 설정 확인됨
- gateway.log에 `No model configured — defaulting to glm-5.1 for provider zai` 메시지 확인

## 관련 파일
- `~/.hermes/config.yaml` — providers.zai 섹션
- `~/.hermes/logs/gateway.log` — API 호출 로그
- `~/.hermes/logs/agent.log` — 서브에이전트 실행 로그
