# Knowledge 수집 — 조사 단계

- **JOB**: JOB-2026-0622-004
- **조사 기간**: 2026-06-22 15:00 ~ 16:20
- **참조**: knowledge-system-architecture skill

## 1. Knowledge System Architecture 분석

`knowledge-system-architecture` skill 로드 결과:

### Karpathy 3-Tier 계층 구조

| Tier | 이름 | 설명 | 저장소 |
|------|------|------|--------|
| Tier 1 | **Raw Knowledge** | 원본 수집, 미가공 | `knowledge/raw/` |
| Tier 2 | **Processed Knowledge** | 정제, 요약, 점수화 | `knowledge/processed/` |
| Tier 3 | **Reasoned Knowledge** | 추론, 패턴, 교훈 | `knowledge/reasoned/` |

### Knowledge Pipeline

```
수집 → 정제 → 점수화 → 분류 → 저장 → 색인
  │       │       │       │       │       │
  ▼       ▼       ▼       ▼       ▼       ▼
 Raw    Filter  Score   Tag     Store   Index
```

## 2. 뉴스 수집 결과

### Source 1: MCP Protocol 업데이트

- **출처**: Anthropic Blog + GitHub (modelcontextprotocol/spec)
- **주요 변경**: Resource Template 확장, Bahtch Processing 지원, Transport Layer 개선
- **날짜**: 2026-06-20

### Source 2: OpenAI Agents SDK v3.0

- **출처**: OpenAI Dev Blog
- **주요 변경**: Guardrails 기본 내장, 멀티모달 에이전트, 커스텀 툴 인터페이스 단순화
- **날짜**: 2026-06-18

### Source 3: LangGraph Sub-graph

- **출처**: LangChain Blog
- **주요 내용**: Agent 내 Agent 실행 (sub-graph 패턴), 상태 공유 메커니즘
- **날짜**: 2026-06-15

### Source 4: HuggingFace smolagents

- **출처**: HuggingFace Blog
- **주요 내용**: Code Agent, Tool Calling Agent, 로컬 LLM 우선 지원
- **날짜**: 2026-06-10

## 3. 중복 검사

기존 Knowledge `agent-frameworks-comparison.md` 확인 결과:
- 4개 중 3개 주제가 신규 (MCP, Agents SDK, smolagents)
- LangGraph는 기존 문서에 포함됨 → **업데이트 모드**로 처리
