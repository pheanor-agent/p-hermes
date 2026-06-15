# External Research: Workflow Enforcement Patterns

## Rysweet/Amplihack workflow-enforcement
- **접근법**: 시스템 프롬프트 > 스크립트 > 파일 검증 3계층
- **강제력**: 계층별 강제력递减 (강제 → 권장 → 참고)
- **핵심**: 계층별 강제력을 명확히 구분하면 에이전트 준수율 ↑

## OWASP Agent Compliance (GitHub Awesome Copilot)
- **접근법**: 정적 검증 + 동적 검증 결합
- **실패 시 처리**: fallback 템플릿 + 사용자 알림
- **핵심**: 실패 시 자동 복구 메커니즘이 필수

## Anthropic Skills (절차적 메모리)
- **접근법**: 스킬 = 절차적 메모리
- **에이전트 인식**: "자주 사용하는 도구"로 인식
- **핵심**: 스킬 형태로 강제하면 준수율 ↑

## Internal Lessons

### JOB-1528: Workflow Model Mapping
- workflow-gate.sh에 이미 모델 전환 로직 존재
- `hermes config set model.default` 명령어로 runtime 전환 가능
- **교훈**: hook 기반 접근법보다 강제 검증이 더 효과적

### workflow-auto-enforcement: 자동 실행 스크립트
- 상태 변경과 작업 실행 연결 시도
- **교훈**: 스크립트 실행 자체는 강제 가능하지만 내용 품질은 검증 안됨

## Pattern Summary

| 패턴 | 강점 | 약점 |
|------|------|------|
| 시스템 프롬프트 | 에이전트 인식 용이 | 재해석 가능 |
| 스크립트 검증 | 강제력 높음 | 내용 품질 검증 어려움 |
| 스킬 절차적 메모리 | 준수율 ↑ | 유지보수 필요 |
| 템플릿 자동 생성 | 형식적 완성도 ↑ | 내용 충실도 보장 불가 |

## Continuous Improvement

### 검증 레벨 점진적 강화
```
레벨 1: 파일 존재 여부 (현재)
    ↓ 다음 단계
레벨 2: 파일 크기 + 필수 태그 (추가 예정)
    ↓ 다음 단계  
레벨 3: 내용 품질 점수 (LLM 기반 평가)
    ↓ 다음 단계
레벨 4: 외부 검수 자동화 (별도 에이전트 호출)
```

### 데이터 기반 모델 최적화
```
stepModels 데이터 축적 → 모델별 단계별 성능 분석
    ↓ 다음 단계
추천 모델 최적화 → 높은 일치율 자동 적용
    ↓ 다음 단계
모델별 생산성 비교 리포트
```
