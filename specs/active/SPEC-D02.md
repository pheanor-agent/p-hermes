---
spec_id: SPEC-D02
version: 1.1.0
parent: null
status: approved
changed_at: "2026-06-21T00:00:00Z"
type: component
title: "GitHub Pages 자동 배포 워크플로우 (SDD 2.0)"
domain: deployment
tags: [github-pages, deploy, automation, sdd-2.0]
---

# SPEC-D02: GitHub Pages 자동 배포 (SDD 2.0)

## 정의
docs/ 변경 시 SDD 2.0 파이프라인(동적 주입 → 구조 검사 → 링크 검증 → 중국어 검사 → llms.txt 재생성)을 수행한 후 git push로 GitHub Pages에 배포합니다.

## SDD 2.0 배포 파이프라인

### 파이프라인 단계 (5단계)

| 단계 | 파이프라인 | 명령어 | 실패 시 |
|------|-----------|--------|---------|
| 1. Dynamic Injection | 런타임 데이터 주입 (Spec ↔ 코드 간 데이터 동기화) | `python3 ~/.hermes/scripts/sdd/sdd-inject.py` | exit 1 |
| 2. Structure Linter | 문서 트리 구조 및 디렉토리 적합성 검사 | `python3 ~/.hermes/scripts/sdd/sdd-lint.py` | exit 1 |
| 3. Full-Graph Validator | 모든 내부 링크의 상호 참조 무결성 검증 | `python3 ~/.hermes/scripts/sdd/sdd-validate.py` | exit 1 |
| 4. 중국어 문자 검증 | CJK Unified Ideographs (U+4E00-U+9FFF) 검사 | `bash tests/validate-chinese.sh docs/` | exit 1 |
| 5. llms.txt 재생성 | 문서 탐색 진입점 자동 생성 (llms.txt + llms-full.txt) | `bash scripts/generate-llms.sh` | exit 1 |

**최종 단계**: `git add -A && git commit -m "deploy: SDD 2.0 synthesized package" && git push origin main`

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
    - SDD 스크립트 (~/.hermes/scripts/sdd/) 존재
  postcondition:
    - SDD 2.0 5단계 파이프라인 모두 통과
    - git push origin main 성공
    - GitHub Pages 1-2분 내 반영
  invariant:
    - docs/가 배포 대상
    - broken links 존재 시 배포 차단
    - 중국어 문자 존재 시 배포 차단

### Preconditions
- docs/ 폴더 존재
- git remote origin 설정됨 (https://github.com/pheanor-agent/p-hermes)
- SDD 스크립트 (~/.hermes/scripts/sdd/sdd-inject.py, sdd-lint.py, sdd-validate.py) 존재
- `tests/validate-chinese.sh` 존재
- `scripts/generate-llms.sh` 존재

### Postconditions
- SDD 2.0 5단계 파이프라인 모두 통과
- git push origin main 성공
- GitHub Pages 1-2분 내 반영
- `llms.txt` 및 `llms-full.txt` 자동 생성 완료

### Invariants
- docs/가 배포 대상
- broken links 존재 시 배포 차단
- 중국어 문자(CJK Unified Ideographs) 존재 시 배포 차단
- 모든 배포는 `bash src/deploy.sh`로만 실행 (개별 git push 금지)

## Acceptance Criteria
Given: docs/ 변경 완료
When: bash src/deploy.sh 실행
Then:
  - SDD 2.0 5단계 파이프라인 순차 통과
  - 검증 통과 후 GitHub Pages 반영
  - llms.txt + llms-full.txt 최신화

## Examples

examples:
  - name: 배포 실행 (전체 파이프라인)
    command: bash src/deploy.sh
  - name: 검증 실패 (링크)
    command: bash src/deploy.sh || echo "exit 1"
  - name: 검증 실패 (중국어)
    command: bash tests/validate-chinese.sh docs/ || echo "중국어 문자 발견"

- 배포 실행: bash src/deploy.sh → SDD 2.0 5단계 → commit → push
- 검증 실패 시: broken links 2개 → exit 1, 배포 중단
- 중국어 검증 실패 시: CJK 문자 발견 → exit 1, 배포 중단
- GitHub Pages 접근: https://pheanor-agent.github.io/p-hermes/ → 200
