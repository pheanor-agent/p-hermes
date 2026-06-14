---
spec_id: SPEC-D02
version: 0.1.0
parent: null
status: proposed
changed_at: "2026-06-14T00:00:00Z"
type: component
title: "GitHub Pages 자동 배포 워크플로우"
domain: deployment
tags: [github-pages, deploy, automation]
---

# SPEC-D02: GitHub Pages 자동 배포

## 정의
docs/ 변경 시 링크 검증 → llms.txt 재생성 → git push 자동화.

## Contract
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
- 배포 실행: bash src/deploy.sh → validate-links → git add → commit → push
- 검증 실패 시: broken links 2개 → exit 1, 배포 중단
- GitHub Pages 접근: https://pheanor-agent.github.io/p-hermes/ → 200
