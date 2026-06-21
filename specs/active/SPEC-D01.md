---
spec_id: SPEC-D01
version: 1.1.0
parent: null
status: approved
changed_at: "2026-06-21T00:00:00Z"
type: requirement
title: "p-hermes 문서 구조 정의 (3-트랙 시스템)"
domain: documentation
tags: [docs, structure, ssot, 3-track]
---

# SPEC-D01: 문서 구조 (SSOT)

## 정의
p-hermes 프로젝트의 문서 구조를 정의합니다. 단순한 정보 나열이 아닌, 목적과 독자에 최적화된 **3-트랙(Guide/Blog/Slides)** 시스템으로 구성하며, `README.md`를 최상위 온보딩 진입점으로 활용합니다.

## 구조
### 1. 최상위 진입점
- `README.md` — **Wiki 최상위 페이지**. 프로젝트 전반 소개, 온보딩 가이드, 3-트랙 선택 경로 제공.

### 2. 3-트랙 산출물
#### ① Guide Wiki (`wiki/`) — "어떻게 쓰는가?" (How-to)
- `wiki/index.md` — 진입점 (학습 경로 카드, 페이지 지도)
- `wiki/getting-started/` — 온보딩 (install, first-job, configuration)
- `wiki/guides/` — 기능별 상세 사용법 (request-task, use-skills, model-routing, content-system, knowledge-system, automation, spec-driven-dev)
- `wiki/tutorials/` — 시나리오 기반 튜토리얼
- `wiki/faq.md` — 자주 묻는 질문 및 문제 해결

> **JOB-1754 변경사항**: `wiki/guides/model-routing.md` 전면 재작성 (3계층 라우팅 구조 추가), `wiki/guides/knowledge-system.md` 경로 수정, `cron-system.md` → `automation.md` 명칭 변경.

#### ② Dev Blog (`blog/`) — "왜 그렇게 설계했는가?" (Why)
- `blog/index.md` — 진입점 (포스트 목록, 태그 클라우드)
- `blog/posts/` — 기술 심층 분석 포스트 (architecture, workflow, knowledge, model-routing, cron-automation, etc.)

#### ③ Slides (`slides/`) — "무엇인가 한눈에?" (What)
- `slides/index.md` — 진입점 (덱 목록)
- `slides/decks/` — HTML 기반 컨셉 강의 슬라이드 (GC 템플릿 기반, playground/slides-v3에서 승격됨)

> **JOB-1752 변경사항**: `slides/index.html` 삭제, `slides/index.md`로 단일화. `playground/slides-v3`의 GC 템플릿이 live slides로 승격되어 `slides/decks/`의 모든 HTML 덱이 v3 템플릿을 사용함.

### 3. 기술 참조 및 사양 (Internal/Reference)
- `ARCHITECTURE.md` — 시스템 논리/물리 구조 참조 (Blog 원천)
- `specs/` — 개발 사양서 (Spec-Driven Dev)

## Contract
### Preconditions
- `wiki/`, `blog/`, `slides/` 디렉토리 존재

### Postconditions
- `README.md`가 프로젝트 소개 및 온보딩 내용을 포함하며 Wiki 진입점 역할 수행
- 각 트랙(`wiki/`, `blog/`, `slides/`)에 `index.md` 존재
- `validate-links.sh` 실행 시 모든 내부 링크 유효

### Invariants
- **P1/P2 배제**: 모든 공개 문서에서 운영자 개인 구성(모델/프로바이더) 및 개인 산출물 통계 배제
- **P3 공개**: 소프트웨어 스펙(스킬 수 등) 및 설계 원칙은 정확히 기술
- **교차 링크**: Wiki ↔ Blog ↔ Slides 간 관련 주제 연결

## Acceptance Criteria
Given: 문서 생성 또는 수정 요청
When: SPEC-D01 3-트랙 구조 준수
Then: `validate-links.sh` (수정版) 실행 시 0개 오류

## Examples
- 온보딩 경로: `README.md` $\rightarrow$ `wiki/getting-started/install.md`
- 설계 사유 탐색: `wiki/guides/request-task.md` $\rightarrow$ `blog/posts/why-9-step-workflow.md`
- 구조 파악: `README.md` $\rightarrow$ `slides/decks/system-overview.html`
