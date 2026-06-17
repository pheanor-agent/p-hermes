---
spec_id: SPEC-D02
version: 1.0.0
parent: null
status: approved
changed_at: "2026-06-17T00:00:00Z"
type: component
title: "GitHub Pages 자동 배포 워크플로우"
domain: deployment
tags: [github-pages, deploy, automation]
---

# SPEC-D02: GitHub Pages 자동 배포

## 정의
docs/ 변경 시 링크 검증 → llms.txt 재생성 → git push 자동화.

## 의존성 타입 정의

| Type | Meaning | Action |
|------|---------|--------|
| `extends` | 부모 확장 (상세화) | 동작 불필요 |
| `raises` | 수치적 기준 상승 | 부모 Spec 업데이트 필요 |
| `conflicts` | 충돌 | 승인 차단 |

## Conflict Detection 절차

| 단계 | 검사 항목 | 명령어 |
|------|-----------|--------|
| 1. Quantitative | 수치 비교 | `grep -n "분량\|자\|chars" specs/active/SPEC-NEW.md` |
| 2. Structural | 구조 재정의 감지 | `grep -n "트랙\|track\|구조" specs/active/SPEC-NEW.md` |
| 3. Domain Overlap | 도메인 중복 | 동일 도메인 Spec 간 역할 분리 확인 |

## Contract

contract:
  precondition:
    - docs/ 폴더 존재
    - git remote origin 설정됨
  postcondition:
    - git push origin main 성공
    - GitHub Pages 1-2분 내 반영
  invariant:
    - docs/가 배포 대상
    - broken links 존재 시 배포 차단

### Preconditions
- docs/ 폴더 존재
- git remote origin 설정됨 (https://github.com/pheanor-agent/p-hermes)

### Postconditions
- git push origin main 성공
- GitHub Pages 1-2분 내 반영

### Invariants
- docs/가 배포 대상
- broken links 존재 시 배포 차단

## Acceptance Criteria
Given: docs/ 변경 완료
When: deploy.sh 실행
Then: 검증 통과 후 GitHub Pages 반영

## Examples

examples:
  - name: 배포 실행
    command: bash src/deploy.sh
  - name: 검증 실패
    command: bash src/deploy.sh || echo "exit 1"

- 배포 실행: bash src/deploy.sh → validate-links → git add → commit → push
- 검증 실패 시: broken links 2개 → exit 1, 배포 중단
- GitHub Pages 접근: https://pheanor-agent.github.io/p-hermes/ → 200
