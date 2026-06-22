---
spec_id: SPEC-D06
version: 1.0.0
parent: SPEC-D01
status: approved
changed_at: "2026-06-22T20:00:00Z"
type: requirement
title: "문서 연결 구조 재설계 — 슬라이드 인덱스를 Pages 최상위로 통합"
domain: documentation
tags: [docs, structure, slides, index, github-pages]
---

# SPEC-D06: 문서 연결 구조 및 다이어그램 개선

## 정의

기존 3-트랙 문서 구조(SPEC-D01)의 세부 연결 방식을 재정의합니다.
슬라이드 인덱스를 `slides/` 서브디렉토리에서 GitHub Pages 최상위로 이동하여 사용자 접근성을 개선합니다.

## 변경점

### 1. 슬라이드 인덱스 = GitHub Pages 최상위

| 항목 | 변경 전 (SPEC-D01) | 변경 후 |
|------|-------------------|---------|
| 슬라이드 인덱스 | `slides/index.md` | **`docs/index.html`** (Pages root `/`) |
| 슬라이드 덱 위치 | `slides/decks/*.html` | **변경 없음** (`slides/decks/*.html`) |
| GitHub Pages 접속 | `.../slides/` → 404 | `.../` → **슬라이드 목록 표시** |

### 2. 플랫폼별 문서 연결 방식

| 문서 타입 | 파일 확장자 | 연결 플랫폼 | URL 패턴 | 근거 |
|-----------|:-----------:|:-----------:|----------|------|
| Guide Wiki | `.md` | GitHub 소스뷰어 | `github.com/.../docs/wiki/...` | 마크다운 렌더링, Pages 불필요 |
| Dev Blog | `.md` | GitHub 소스뷰어 | `github.com/.../docs/blog/...` | 마크다운 렌더링, Pages 불필요 |
| **Slides** | **`.html`** | **GitHub Pages** | **`/slides/decks/*.html`** | HTML 실행 필요 |
| **Slides 인덱스** | **`.html`** | **GitHub Pages root** | **`/`** | **최상위 접근, 슬라이드 목록 표시** |
| Playground Wiki/Blog | `.md` | GitHub 소스뷰어 | `github.com/.../docs/playground/...` | 운영 Wiki/Blog와 동일 |
| Playground 예시 | `.html` | GitHub Pages | `/playground/experiments/...` | HTML 실행 필요 |

### 3. SPEC-D01 변경사항

- **Line 37 제거**: `slides/index.md — 진입점 (덱 목록)` → 불필요
- **Postcondition 변경**: `각 트랙에 index.md 존재` → `GitHub Pages 루트(index.html)에 슬라이드 목록 포함`

## Examples (SBE)

### 예제 1: README Slides 배지 링크
```markdown
<!-- Before -->
[![Slides](...)](https://github.com/pheanor-agent/p-hermes/blob/main/docs/slides/index.md)

<!-- After -->
[![Slides](...)](https://pheanor-agent.github.io/p-hermes/)
```

### 예제 2: 랜딩페이지 슬라이드 테이블
```html
<!-- docs/index.html 내 슬라이드 목록 섹션 -->
<h2>🖼️ 슬라이드 덱 전체 목록</h2>
<table>
  <tr><th>덱 제목</th><th>핵심 내용</th><th>슬라이드</th><th>링크</th></tr>
  <tr><td>Hermes Overview</td><td>챗봇에서 자율 에이전트로</td><td>20</td><td><a href="./slides/decks/hermes-overview.html">열기</a></td></tr>
  ...
</table>
```

### 예제 3: T2 SVG 엣지 px 변환
```svg
<!-- Before (broken: % in path d is invalid) -->
<path d="M 18% 55 C 18% 90, 18% 115, 18% 165"/>

<!-- After (valid px coordinates) -->
<path d="M 171 55 C 171 90, 171 115, 171 200"/>
```

## Contract (DbC)

### Preconditions
- `docs/index.html` 존재 (기존 랜딩페이지 222줄)
- `docs/slides/decks/`에 9개 덱 HTML 파일 존재
- GitHub Pages 배포 정상 (`pheanor-agent.github.io/p-hermes/` → 200)

### Postconditions
- `docs/index.html`에 9개 덱 전체 목록 테이블 포함
- `slides/index.{md,html}` 별도 파일 생성하지 않음
- README.md Slides 배지 3곳 모두 `https://pheanor-agent.github.io/p-hermes/` 연결
- T2 SVG 엣지: px 기반 좌표로 가시적 렌더링 (100%에서 6개 엣지 모두 표시)
- T3 SVG 노드: 3-Layer 배치, 노드 간 겹침 없음 (y+height로 bottom 계산)

### Invariants
- Wiki/Blog는 항상 GitHub 소스뷰어 `.md` 연결 (변경 금지)
- Slides만 GitHub Pages `.html` 연결
- README Slides 링크만 `https://pheanor-agent.github.io/p-hermes/` 연결
- 나머지 README 링크(Wiki/Blog/예시)는 `github.com/...` 소스뷰어 유지

## Acceptance Criteria (BDD)

### Scenario 1: README 배지 링크
**Given** 사용자가 README.md의 Slides 배지를 클릭하면  
**When** GitHub Pages 최상위(`/`)가 로드된다  
**Then** 9개 덱 전체 목록이 표시된다

### Scenario 2: T2 SVG 엣지
**Given** diagram-v3.html의 T2를 보면  
**When** SVG path d가 px 기반 좌표로 렌더링된다  
**Then** Agent→Session Manager 등 3개 수직 엣지와 Session→Storage 등 3개 하향 엣지가 노드 간을 연결한다  
**And** "orchestrates", "triggers" 등 라벨이 엣지 위에 표시된다

### Scenario 3: T3 노드 배치
**Given** diagram-v3.html의 T3를 보면  
**When** 3-Layer 구조로 노드가 배치되어 있다  
**Then** Layer 1(Input) → Layer 2(Processing) → Layer 3(Output) 흐름이 명확하다  
**And** 어떤 노드도 다른 노드와 겹치지 않는다

## Diagram 개선 명세

### T2 SVG 엣지 px 변환

부모 container width ≈ 950px 기준:

| 노드 | 원래 % | 실제 중심 % | px 좌표 |
|------|:------:|:----------:|:-------:|
| Agent Layer | 14% | 18% (14%+8%/2) | **171px** |
| Knowledge Layer | 42% | 46% (42%+8%/2) | **437px** |
| Deploy Layer | 70% | 74% (70%+8%/2) | **703px** |

**엣지 6개** (px 단위):
```svg
<!-- 상단 → 중단 (수직) -->
<path d="M 171 55 C 171 95, 171 150, 171 200"/>
<path d="M 437 55 C 437 95, 437 150, 437 200"/>
<path d="M 703 55 C 703 95, 703 150, 703 200"/>

<!-- 중단 → 하단 (수렴) -->
<path d="M 171 200 C 171 250, 300 260, 450 325"/>
<path d="M 437 200 C 437 250, 450 260, 450 325"/>
<path d="M 703 200 C 703 250, 600 260, 450 325"/>
```

### T3 SVG 노드 배치

viewBox="0 0 900 400":

| Layer | 노드 | x | y | width | height |
|:-----:|------|:-:|:-:|:-----:|:------:|
| 1 (Input) | User Input | 30 | 35 | 120 | 45 |
| 1 | Hermes Agent | 340 | 30 | 220 | 50 |
| 1 | Context Router | 680 | 35 | 170 | 45 |
| 2 (Processing) | Session Manager | 100 | 155 | 200 | 45 |
| 2 | Workflow Gate | 350 | 155 | 200 | 45 |
| 2 | Pipeline Executor | 500 | 155 | 200 | 45 |
| 2 | Skills | 730 | 155 | 140 | 45 |
| 3 (Output) | Knowledge DB | 100 | 290 | 200 | 45 |
| 3 | Deliverable | 350 | 290 | 200 | 45 |
| 3 | Skills Output | 730 | 290 | 140 | 45 |
