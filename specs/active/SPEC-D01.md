---
spec_id: SPEC-D01
version: 0.1.0
parent: null
status: proposed
changed_at: "2026-06-14T00:00:00Z"
type: requirement
title: "p-hermes 문서 구조 정의"
domain: documentation
tags: [docs, structure, ssot]
---

# SPEC-D01: 문서 구조 (SSOT)

## 정의
p-hermes 프로젝트의 문서 구조를 정의합니다. docs/가 GitHub Pages 루트입니다.

## 구조
- docs/index.md — 진입점 (빠른 탐색, 시스템별 심화, 탐색 시나리오 포함)
- docs/systems/ — 시스템별 문서 (overview, knowledge, models, cron, backup, infra)
- docs/skill-system.md — 스킬 시스템 문서
- docs/workflow-pipeline.md — 워크플로우 파이프라인

## Contract
### Preconditions
- docs/ 폴더 존재

### Postconditions
- docs/index.md 진입점 존재
- docs/systems/ 하위 문서 6개 이상

### Invariants
- 모든 내부 markdown 링크 유효
- 중복 링크 없음
- infra.md가 deploy.md 대체 (deploy.md 없음)

## Acceptance Criteria
Given: 문서 생성 또는 수정 요청
When: SPEC-D01 구조 준수
Then: validate-links.sh 실행 시 0개 오류

## Examples
- 진입점 존재: docs/index.md가 "빠른 탐색", "시스템별 심화", "탐색 시나리오" 섹션 포함
- 시스템 문서 하위 구조: docs/systems/ 하위에 6개 문서 존재
