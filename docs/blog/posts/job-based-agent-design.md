---
title: "Job 기반 에이전트 설계"
---

# Job 기반 에이전트 설계

> 작업 단위(Job)가 AI 시스템 설계의 중심이 되어야 하는 이유

---

## 에이전트 설계의 두 가지 접근법

AI 에이전트를 설계하는 방법은 크게 두 가지입니다:

### 1. 세션 기반 설계 (Session-Based)
사용자의 각 요청을 독립적인 대화로 처리합니다.

```
사용자: "코드 리뷰해줘"
→ AI가 즉시 응답
→ 대화 로그에만 저장
→ 다음 요청과 무관
```

### 2. Job 기반 설계 (Job-Based)
각 요청을 추적 가능한 **작업 단위(Job)**로 등록하고 관리합니다.

```
사용자: "코드 리뷰해줘"
→ JOB-1234 생성
→ 워크플로우 시작
→ 각 단계 산출물 저장
→ 완료 후 결과 전달
```

---

## 왜 Job 기반 설계가 필요한가

### 1. 추적 가능성 (Traceability)

세션 기반 시스템에서는 요청과 응답이 뒤섞여 **무엇을 했는지 추적**하기 어렵습니다.

```
세션 기반:
"파이썬 코드 리뷰" → "네"
"테스트도 추가" → "네"
"배포도" → "네"
→ 세 개의 요청이 섞여서 어떤 결과가 나왔는지 불명확

Job 기반:
"JOB-1234: 코드 리뷰" → review.md
"JOB-1235: 테스트 추가" → test-cases.md
"JOB-1236: 배포" → deployment-log.md
→ 각 Job별로 명확한 산출물
```

### 2. 재현 가능성 (Reproducibility)

같은 작업을 다시 해야 할 때, Job ID만 있으면 **전체 컨텍스트를 복원**할 수 있습니다.

```
# 3개월 후
사용자: "저번에 했던 API 마이그레이션 다시 해야 해"
→ JOB-1234 조회
→ 전체 과정 investigation.md, architecture.md, execution.log 복원
→ "6개월 전과 동일한 마이그레이션을 현재 환경에 맞게 수정해서 실행"
```

### 3. 상태 관리 (State Management)

Job은 명확한 **상태 기계**를 가집니다:

```
접수 → 조사 → 설계 → 검토 → 승인 → 실행 → 테스트 → 실행리뷰 → 교훈
```

각 상태는:
- **멱등성**: 같은 상태를 여러 번 확인해도 결과가 같음
- **재개 가능성**: 중단된 Job을 이전 상태에서 재개 가능
- **롤백 가능성**: 문제 발생 시 이전 상태로 복구 가능

---

## Job 기반 설계의 핵심 구성 요소

### Job Lifecycle

```
┌─────────────────────────────────────────────┐
│                 JOB Core                    │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  │
│  │ State│  │Meta  │  │Output│  │Links │  │
│  │Machine│  │Data  │  │     │  │      │  │
│  └──────┘  └──────┘  └──────┘  └──────┘  │
└─────────────────────────────────────────────┘
```

| 구성 요소 | 설명 | 예시 |
|-----------|------|------|
| **State Machine** | 현재 상태와 전이 규칙 | `status: investigation` |
| **Meta Data** | Job 정보 | `priority: high`, `assignee: pheanor` |
| **Output** | 단계별 산출물 | `investigation.md`, `architecture.md` |
| **Links** | 관련 Knowledge/Kanban | `knowledge: T2-789`, `task: KAN-456` |

### Job의 데이터 구조

```yaml
job:
  id: JOB-1234
  title: "API 마이그레이션"
  status: execution  # 현재 상태
  priority: high
  created: 2025-01-15T09:00:00
  artifacts:
    - step: investigation
      file: investigation.md
      verified: true
    - step: architecture
      file: architecture.md
      verified: true
    - step: execution
      file: execution.log
      verified: pending
  knowledge_links:
    - T2-789  # 설계 결정 Knowledge
    - T2-456  # 이전 마이그레이션 Knowledge
```

---

## Job 기반 vs 세션 기반 비교

| 항목 | 세션 기반 | Job 기반 |
|------|:---------:|:--------:|
| **추적 가능성** | 낮음 (로그에 섞임) | 높음 (고유 ID) |
| **재현 가능성** | 불가능 | 가능 (ID로 복원) |
| **상태 관리** | 없음 (컨텍스트만) | 있음 (상태 기계) |
| **산출물 보존** | 없음 (채팅만) | 있음 (구조화된 문서) |
| **병렬 처리** | 어려움 | 가능 (여러 Job 동시 처리) |
| **롤백** | 불가능 | 가능 (이전 상태로) |
| **우선순위** | 없음 (순서대로) | 있음 (명시적 우선순위) |

---

## 실제 사례: Job 기반 개발

### 일반적인 개발 작업 흐름

```
1. 요청 접수
   "/new '사용자 인증 모듈 리팩토링'"
   → JOB-5678 생성

2. 조사
   - 기존 코드 분석
   - 관련 Knowledge 검색 (session_search)
   - investigation.md 생성

3. 설계
   - 리팩토링 아키텍처 설계
   - architecture.md 생성
   - Spec 업데이트

4. 리뷰 → 승인
   - 설계 검토
   - 승인 조건 확인

5. 실행
   - 코드 변경
   - execution.log 기록

6. 테스트
   - pytest 실행
   - test-result.md

7. 실행리뷰
   - 최종 검토
   - lessons.md
```

### Job 완료 후

```
🔔 JOB-5678 완료
📄 산출물:
  - investigation.md
  - architecture.md
  - execution.log
  - test-result.md
  - lessons.md
🧠 Knowledge 자동 저장:
  - T2 리팩토링 결정 사항
  - T3 성능 분석 결과
```

---

## Job이 바꾸는 개발 문화

### Job 기반 문화의 특징

1. **모든 작업이 기록된다**
   - "누가, 언제, 무엇을, 왜"가 모두 기록됨
   - 지식 손실 방지

2. **작업이 쌓이면 지식이 된다**
   - 각 Job의 산출물이 Knowledge로 축적
   - 시간이 지날수록 시스템이 똑똑해짐

3. **투명한 우선순위**
   - 모든 Job의 우선순위가 명시적
   - "지금 무엇을 해야 하는가"가 항상 명확

---

## 결론

Job 기반 설계는 단순한 기능 이상입니다. **에이전트와의 상호작용 방식을 근본적으로 바꾸는 패러다임**입니다.

```
ChatGPT 방식: "질문하면 답해주는 비서"
Job 기반 방식: "작업을 위임하고 관리하는 시스템"
```

후자가 진정한 생산성 도구입니다.

> **🔗 다음 포스트**: [Workflow Gate 설계 철학](workflow-gate-philosophy.md) — Job을 실행하는 프로세스의 의미