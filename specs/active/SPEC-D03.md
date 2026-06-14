---
spec_id: SPEC-D03
version: 0.1.0
parent: null
status: proposed
changed_at: "2026-06-14T00:00:00Z"
type: guideline
title: "Expression System D1 연동 가이드라인"
domain: expression
tags: [expression, d1, non-technical]
---

# SPEC-D03: Expression System D1 연동 가이드라인

## 정의
p-hermes 문서 작성 시 Expression System D1(비기술적) 도메인을 참고하여 문서를 생성하는 가이드라인입니다. expression-system은 에이전트 스킬이므로 자동화 artifact는 포함되지 않습니다.

## Contract
### Preconditions
- expression-system 스킬 가용

### Postconditions
- D1 tier/tone 적용된 문서 생성

### Invariants
- D1 도메인만 적용 (기술적 문서 제외)

## Acceptance Criteria
Given: 시스템 문서 작성 요청
When: 에이전트가 expression-system D1 실행 후 docs/에 저장
Then: 비기술적 tone 적용된 문서가 docs/에 생성

## Examples
- 시스템 종합 문서 D1로 생성: domain=D1, intent=explain, topic="Hermes 아키텍처" → tier=[L1,L2,L3], tone=non-technical

## 참고
- expression-system은 CLI 스크립트가 아닌 에이전트 스킬이므로, 에이전트 세션 내에서만 실행 가능
- p-hermes 문서가 비기술적 대상 독자를 위해 재작성될 때 참고
