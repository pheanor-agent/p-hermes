# 역할 기반 모델 라우팅 설계

> 태그: #architecture #routing
> 읽는 시간: ~10분

---

## TL;DR

"하나의 모델로 모든 것을 하려는 것은 드라이버가 모든 경주를 이기려는 것과 같다." Hermes는 작업의 단계(Design, Execution, Review 등)마다 가장 적합한 모델을 **역할 기반 라우팅**을 통해 자동으로 배정합니다.

```
┌─────────────────────────────────────────────────────┐
│              역할 기반 라우팅 아키텍처                 │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Design/Review   Execution   Investigation         │
│  (추론형)        (수행형)     (범용형)              │
│                                                     │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐       │
│  │ Gemma-4  │   │ Qwen3.6  │   │ GLM-5.2  │       │
│  │ 논리적   │   │ 코드 작성 │   │ 현황 분석 │       │
│  │ 설계     │   │ 테스트    │   │ 파일 검색 │       │
│  └──────────┘   └──────────┘   └──────────┘       │
│                                                     │
│  config.yaml roles 섹션에서 모델 매핑 정의           │
└─────────────────────────────────────────────────────┘
```

---

## 배경: "만능 모델의 환상"

### 초기 버전의 문제

2025년 초, Hermes 시스템은 가장 성능이 뛰어난 모델을 모든 단계에 투입했습니다.

```yaml
# 초기 설정: 단일 모델
model:
  default: anthropic/claude-sonnet-4
```

**2가지 치명적 문제**:

**1. 비용 폭주 (Cost Explosion)**
- 코드 실행이나 단순 파일 복사에도 가장 비싼 모델 호출
- 예시: 2025-11-01, 1000개 파일 복사 작업 → $150 비용 발생
- 결과: 토큰 한도 초과, 작업 중단

**2. 성능 불일치 (Performance Mismatch)**
- 추론 능력이 가장 뛰어난 모델이 항상 코드를 가장 잘 작성하는 것은 아님
- 예시: Claude Sonnet 4는 논리적 설계는 뛰어나지만, Python 스크립트 작성은 Qwen3.6보다 느림
- 결과: 작업 시간 40% 증가, 코드 품질 하락

---

## 설계 결정: Role-Based Routing

Hermes는 `catalog.json`과 `config.yaml`에서 각 단계에 사용할 모델을 정의합니다.

### config.yaml 설정 예시

```yaml
# config.yaml
model:
  default: glm-5.2
  
  roles:
    # Design / Review: 추론형 모델
    design:
      provider: anthropic
      model: claude-sonnet-4
      
    review:
      provider: anthropic
      model: claude-sonnet-4
      
    # Execution / Coding: 수행형 모델
    execution:
      provider: zai
      model: qwen3.6
      
    coding:
      provider: zai
      model: qwen3.6
      
    # Investigation: 범용형 모델
    investigation:
      provider: zai
      model: glm-5.2
      
    # Test: 범용형 모델
    test:
      provider: zai
      model: glm-5.2
      
    # Done: 범용형 모델
    done:
      provider: zai
      model: glm-5.2
```

### 역할별 모델 특성

| 역할 | 특성 | 예시 모델 | 작업 |
|------|------|----------|------|
| **Design** | 논리적 추론, 창의성, 종합 분석 | Gemma-4, Claude Sonnet 4 | 아키텍처 설계, 코드 리뷰 |
| **Review** | 상세 검증, 논리적 오류 탐지 | Gemma-4, Claude Sonnet 4 | 설계서 검증, 테스트 결과 분석 |
| **Execution** | 프로그래밍 언어 이해도, 코드 작성 속도 | Qwen3.6 | 실제 파일 수정, 스크립트 작성 |
| **Investigation** | 빠른 응답, 폭넓은 지식 | GLM-5.2 | 파일 검색, 시스템 현황 파악 |
| **Test** | 빠른 응답, 테스트 결과 해석 | GLM-5.2 | 테스트 실행, 결과 검증 |

### 모델 카탈로그 (catalog.json)

```json
{
  "models": [
    {
      "name": "glm-5.2",
      "provider": "zai",
      "roles": ["default", "investigation", "test", "done"],
      "cost_per_million_tokens": 0.5,
      "capabilities": ["reasoning", "coding", "analysis"],
      "benchmark": {
        "mmlu": 0.85,
        "gsm8k": 0.92,
        "human_eval": 0.78
      }
    },
    {
      "name": "qwen3.6",
      "provider": "zai",
      "roles": ["execution", "coding"],
      "cost_per_million_tokens": 0.3,
      "capabilities": ["coding", "scripting"],
      "benchmark": {
        "mmlu": 0.82,
        "gsm8k": 0.88,
        "human_eval": 0.85
      }
    },
    {
      "name": "claude-sonnet-4",
      "provider": "anthropic",
      "roles": ["design", "review"],
      "cost_per_million_tokens": 3.0,
      "capabilities": ["reasoning", "analysis"],
      "benchmark": {
        "mmlu": 0.92,
        "gsm8k": 0.95,
        "human_eval": 0.88
      }
    }
  ]
}
```

---

## 상호 견제 (Cross-Check) 구조

Hermes에서는 **Design 모델과 Review 모델을 다르게 설정**하는 것을 권장합니다.

```
┌─────────────────────────────────────────────────────┐
│              Cross-Check 구조                        │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Design 단계     Review 단계                        │
│  (Gemma-4)      (Claude Sonnet 4)                  │
│                                                     │
│  ┌──────────┐   ┌──────────┐                      │
│  │ 설계를   │──→│ 검증     │                      │
│  │ 작성     │   │          │                      │
│  └──────────┘   └──────────┘                      │
│                                                     │
│  "다른 모델이 설계를 검증하면, 논리적 오류를        │
│   훨씬 정확하게 잡아냅니다."                         │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**원리**:
- 모델 A가 설계를 작성 → 모델 B가 검증
- 동일한 모델이 검증하면, 자신의 오류를 발견하지 못할 가능성이 높음
- 다른 모델이 검증하면, 서로 다른 학습 데이터로 인해 오류 탐지율 향상

---

## 다른 대안과의 비교

| 대안 | 문제점 | Hermes 해결책 |
|------|--------|---------------|
| **단일 모델** | 비용 폭주, 성능 불일치 | 역할별 모델 최적화 |
| **랜덤 라우팅** | 예측 불가능한 결과 | 명시적 역할 기반 라우팅 |
| **사용자 선택** | 모델 선택 부담, 최적화 어려움 | 자동 라우팅 |

---

## 실제 운영 사례

### 성공 사례: 비용 절감

**문제**:
- 단일 모델 사용 시 월 $500 비용 발생
- 단순 작업 (파일 복사, 검색)에도 고가 모델 호출

**해결**:
- `Investigation`: GLM-5.2 ($0.5/M)
- `Execution`: Qwen3.6 ($0.3/M)
- `Design/Review`: Gemma-4 ($1.5/M)

**결과**:
- 월 $150 비용 절감 (66% 감소)
- 작업 시간: 15% 단축

### 실패 사례: 모델 선택 오류

**문제**:
- Qwen3.6을 Design 모델로 설정
- 복잡한 아키텍처 설계 시 논리적 오류 발생률 15%

**해결**:
- Design 모델: Gemma-4로 변경
- Qwen3.6은 Execution/Coding 전용

**결과**:
- 설계서 오류율: 15% → 2% 감소

---

## 관련 포스트

- [9단계 상태머신](./why-9-step-workflow.md)
- ["텍스트 규칙 → 스크립트 강제" 철학](./structural-enforcement.md)

---

_역할 기반 라우팅은 비용과 성능의 균형을 맞추는 핵심 설계입니다. 각 모델은 자신의 전문 분야에서 최적인 모델을 사용합니다._
