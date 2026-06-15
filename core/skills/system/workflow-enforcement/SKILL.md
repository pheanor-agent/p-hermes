---
name: workflow-enforcement
description: "Enforcing workflow compliance, tracking deliverables, and monitoring model usage across job steps. Includes 3-layer enforcement system, deliverable validation patterns, and model tracking."
version: "1.0"
created: "2026-06-14"
updated: "2026-06-14"
---

# Workflow Enforcement

프로젝트 워크플로우 준수율 확보, 산출물 품질 검증, 모델 사용 추적 및 최적화를 위한 체계를 제공합니다.

## 트리거 조건

- 워크플로우 단계 전환 시 산출물 검증 필요 시
- 모델 사용 추적 및 분석 필요 시
- 워크플로우 준수율 모니터링 필요 시
- 자동 템플릿 생성 및 가이드 필요 시

## 3계층 강제 시스템

### 계층 1: 도구 레벨 강제 (스크립트)
```bash
# workflow-gate.sh 실행 → 파일 존재 여부 체크
bash ~/.hermes/scripts/workflow-gate.sh JOB-XXXX start design
# 실패 시: 스크립트 종료 + 에러 메시지
# 성공 시: 단계 진행 허용
```

### 계층 2: 에이전트 레벨 강제 (시스템 프롬프트 + 스킬)
- 시스템 프롬프트: "workflow-gate.sh를 사용하세요"
- 반복 실패 시: 자동 템플릿 생성 + 가이드 제공
- 스킬 참조: 이 스킬을 통해 절차적 메모리 제공

### 계층 3: 로깅 레벨 추적 (모니터링 + 리포트)
- `.workflow-state` 파일에 `stepModels` 배열 기록
- 모델 일치율 분석 + 리포트
- 지속적인 개선 데이터 수집

## 단계별 산출물 검증

### architecture.md (Design 단계)
```yaml
필수 태그:
  - [STATUS: DRAFT|REVIEW|APPROVED]
  - [MODEL: 사용한 모델명]
최소 라인: 50
필수 섹션:
  - 문제 정의
  - 해결 방안
  - 파일 변경 목록
  - 테스트 계획
```

### review-result.md (Review 단계)
```yaml
필수 태그:
  - [STATUS: PENDING|PASS|FAIL]
  - [REVIEWER: 에이전트명]
최소 라인: 20
패턴: review-result*.md (review-result.md, review-result-self.md 모두 허용)
```

### execution.md (Execution 단계)
```yaml
필수 태그:
  - [STATUS: IN_PROGRESS|COMPLETED|FAILED]
  - [MODEL: 사용한 모델명]
최소 라인: 30
```

## 모델 사용 추적

### .workflow-state에 stepModels 배열
```json
{
  "stepModels": [
    {
      "step": "investigation",
      "recommended": "Qwen3.6",
      "actual": "Qwen3.6",
      "matched": true,
      "recordedAt": "2026-06-14T10:30:00+09:00"
    },
    {
      "step": "design",
      "recommended": get_model_for_role("review"),
      "actual": "Qwen3.6",
      "matched": false,
      "reason": "에이전트 선택",
      "recordedAt": "2026-06-14T10:35:00+09:00"
    }
  ]
}
```

### record-model-usage.sh 사용법
```bash
# 현재 세션 모델 + 추천 모델 비교 → stepModels에 기록
bash ~/.hermes/core/scripts/record-model-usage.sh \
  ~/.hermes/workspace/jobs/JOB-XXXX/.workflow-state \
  design
```

## 자동 템플릿 생성

### 템플릿 위치
```
~/.hermes/core/scripts/deliverable-templates/
├── architecture.md.template
├── review-result.md.template
├── execution.md.template
└── README.md
```

### 자동 생성 조건
- 파일이 존재하지 않을 때
- 최소한의 내용이 포함된 템플릿으로 자동 생성
- 필수 태그 포함 ([STATUS:], [MODEL:])

## Pitfalls

### 패턴 매치 오작동
```bash
# ❌ 변경 전:
find ... -name "review-result-*.md"  # review-result.md 매치 안됨

# ✅ 변경 후:
find ... -name "review-result*.md"  # review-result.md, review-result-self.md 모두 허용
```

### 형식적 검증만 존재 문제
```bash
# ❌ 문제: 파일이 존재하면 검증 통과 (내용 품질 검증 안함)
# ✅ 해결: 최소 라인 + 필수 태그 + 내용 품질 체크
```

### 모델 추천 vs 실제 사용 불일치
```bash
# 문제: workflow-gate.sh는 추천 모델만 stdout 출력
# 해결: record-model-usage.sh로 실제 사용 모델 기록 + 분석
```

## 참조 파일

- `references/enforcement-patterns.md`: 외부 연구 참조 (Rysweet, OWASP, Anthropic)
- `templates/workflow-state.json`: .workflow-state 템플릿
- `scripts/record-model-usage.sh`: 모델 사용 기록 스크립트
