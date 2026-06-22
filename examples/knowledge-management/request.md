# Knowledge 수집 요청

- **JOB**: JOB-2026-0622-004
- **요청자**: 최서연 (AI Research 팀)
- **요청일**: 2026-06-22
- **상태**: 접수 완료

## 요청 내용

Hermes, 다음 기술 뉴스들을 수집하고 분석해서 Knowledge 시스템에 저장해줘. 관심 주제는 **"Agentic AI와 MCP Protocol"** 이다.

### 수집 대상

1. **Anthropic MCP (Model Context Protocol) 업데이트** — 최신 스펙 변경사항
2. **OpenAI Agents SDK 릴리스** — v3.0 주요 변경점
3. **LangGraph의 Agent Orchestration 기능** — sub-graph 패턴
4. **HuggingFace smolagents** — 로컬 에이전트 프레임워크 동향

### 처리 요청

- 각 뉴스의 핵심 내용을 **100자 이내 요약**
- Hermes 시스템과의 **연관성 점수** (1~5)
- Knowledge **3-Tier 시스템**에 맞게 분류 저장
- **검색 태그** 자동 생성
- 기존 관련 Knowledge와의 **중복 검사**

### 참고

- `knowledge-system-architecture` skill 참고
- 이전 Knowledge: `knowledge/system/research/agent-frameworks-comparison.md`
- Knowledge 저장 위치는 Knowledge Architecture에 따라 자동 결정
