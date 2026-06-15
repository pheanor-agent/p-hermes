---
name: graphrag-code-analysis
description: "GraphRAG(그래프+벡터+키워드 하이브리드 검색) 기반 소스 코드 분석 시스템 설계 및 구현. 코드의 구조적 관계와 의미적 내용을 모두 활용하는 검색/분석 파이프라인. 코드 탐색, 함수 호출 그래프 분석, API 문서 검색, 리팩토링 지원 등에 사용."
---

# GraphRAG 기반 코드 분석 시스템

## 개요

GraphRAG(그래프 기반 RAG)는 코드의 **구조적 관계**(호출 그래프, 의존성)와 **의미적 내용**(코드 Chunk 임베딩)을 결합한 하이브리드 검색 아키텍처입니다.

### 핵심 아이디어

- **그래프**: 코드의 구조적 관계 (함수 호출, include 의존성, 심볼 참조)
- **벡터**: 코드의 의미적 유사도 (임베딩 기반 검색)
- **키워드**: 정확한 심볼명/키워드 매칭
- **LLM**: 검색 결과 정제 + 자연어 답변 생성

### 사용 사례

- 리눅스 커널 같은 대규모 코드베이스 분석
- 함수 호출 흐름 시각화
- API 문서 기반 검색
- 리팩토링 영향도 분석
- 코드 이해를 위한 자연어 Q&A

## 아키텍처

```
┌─────────────────────────────────────────────┐
│                  CLI Layer                    │
│  init  → 설정  |  index  → 인덱싱            │
│  ask   → 질문  |  search → 검색  | status → 상태 │
└───────────────────┬─────────────────────────┘
                    │
┌───────────────────▼─────────────────────────┐
│              Application Layer                │
│  ┌──────────┐  ┌─────────┐  ┌────────────┐  │
│  │  Parser   │  │ Chunker │  │ Query Router│  │
│  │Tree-sitter│  │ 3-Tier+ │  │의도 분류    │  │
│  │ + Clang   │  │Hierarchic│  │ + 심볼 추출 │  │
│  └──────────┘  └─────────┘  └────────────┘  │
│                          │                    │
│  ┌───────────────────────▼────────────────┐  │
│  │ DescriptionGenerator (LLM)             │  │
│  │ 함수/블록별 자연어 설명 생성 (배치)      │  │
│  └────────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────┐
│               Search Layer (4-way)            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  Graph   │  │  Vector   │  │ Semantic │  │
│  │ Retrieval│  │ Retrieval │  │ Retrieval│  │
│  │NetworkX  │  │ ChromaDB  │  │ ChromaDB │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  │
│       └──────────────┼─────────────┘        │
│                 ┌─────▼─────┐               │
│                 │ LLM Refine│  (GPT-4o-mini)│
│                 └───────────┘               │
└─────────────────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────┐
│                 Data Layer                    │
│  ┌─────────────────┐  ┌──────────────────┐  │
│  │ graph.db         │  │ chroma-data/     │  │
│  │ (SQLite+NetworkX)│  │ (ChromaDB local) │  │
│  └─────────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────┘
```

## 컴포넌트별 설계

### 1. 파싱 (Parser)

**목표**: C/Python/Java 등 소스코드에서 심볼과 구조 추출

**기술 스택**:
- **Tree-sitter**: 언어별 grammar 기반 AST 파싱
- **Clang (C/C++)**: 의미 분석 + 타입 리졸브
- **AST**: 표준 Python ast 모듈 (Python용)

**출력**:
- 심볼 테이블 (함수명, 구조체명, 변수명)
- 호출 그래프 (caller → callee)
- 의존성 그래프 (include/import 관계)

### 2. Chunking (3-Tier + Hierarchical Blocks)

**목표**: 코드를 의미 있는 Chunk로 분할

| Tier | 단위 | 임베딩 | 용도 |
|------|------|--------|------|
| L1: Symbol | 개별 심볼 (변수, 상수) | ✅ | 정확한 심볼 매칭 |
| L2: Function | 함수 전체 (시그니처+본문) | ✅ | 함수 역할/사용법 검색 |
| L2.1: Function Block | 함수 내 논리적 블록 (50줄 초과 분할) | ✅ (설명) | 대용량 함수 세밀 검색 |
| L3: File | 파일 레벨 | ✅ | 파일 구조/목적 검색 |

**계층적 블록 분할**:
- 함수 ≤ 50줄: 단일 Chunk
- 함수 > 50줄: 제어문(if/for/while) 기반 블록 분할
- 각 블록은 `parent_chunk_id`로 상위 함수 참조
- 최대 블록 크기: 80줄 (text-embedding-3-small 8191 토큰 제한 마진)

### 3. 그래프 데이터베이스

**목표**: 코드의 구조적 관계 저장 + 탐색

**기술 스택**:
- **NetworkX**: 인메모리 그래프 알고리즘 (최단경로, 중심성, 커뮤니티)
- **SQLite**: 영구 저장 (graph.db)

**노드 타입**:
- `File`: 소스 파일
- `Function`: 함수 정의
- `Struct`: 구조체
- `Variable`: 전역/정적 변수
- `Macro`: 전처리기 매크로
- `Config`: 빌드 옵션

**엣지 타입**:
- `CALLS`: 함수 호출 관계
- `INCLUDES`: #include/import 의존성
- `DEFINES`: 심볼 정의 위치
- `REFERENCES`: 심볼 참조
- `DEPENDS_ON`: 모듈 의존성

### 4. 벡터 데이터베이스

**목표**: 코드의 의미적 유사도 검색

**기술 스택**:
- **ChromaDB**: 로컬 임베딩 저장 + ANN 검색
- **OpenAI Embedding API**: text-embedding-3-small

**컬렉션 (Collection 분리 필수)**:

| 컬렉션 | 임베딩 대상 | 용도 |
|--------|-----------|------|
| `kernel_functions` | C 코드 본문 | 코드 기반 검색 |
| `kernel_function_descs` | LLM 생성 자연어 설명 | 의미적 검색 (자연어 질문) |
| `kernel_files` | 파일 전체 텍스트 | 파일 단위 탐색 |
| `kernel_docs` | 문서 임베딩 | 커널 문서 검색 |
| `kernel_chunks` | 코드 블록 | 심볼 기반 검색 |

**⚠️ 핵심 원칙**: 코드 임베딩과 설명 임베딩은 **반드시 별도 컬렉션**에 저장.
서로 다른 목적(코드 구조 vs 의미적 내용)의 임베딩을 섞으면 cosine similarity 간섭 발생.

### 5. 하이브리드 검색 (4-way)

**목표**: 그래프 + 벡터 + Semantic + 키워드 병렬 검색 + 가중치 합산

**검색 파이프라인**:
1. **Query Understanding**: 의도 분류 + 심볼 추출 + 서브시스템 매핑 + **한국어→심볼 개념어 매핑**
2. **병렬 검색**: Graph(경로) + Vector(코드 임베딩) + **Semantic(설명 임베딩)** + Keyword(BM25)
3. **랭킹**: 가중치 합산 (의도별 동적 조정) + 중복 제거
4. **LLM 정제**: GPT-4o-mini로 검색 결과 종합 + 자연어 답변

**의도별 가중치** (14 intent, 각 소스 합 = 1.0):

```python
INTENT_WEIGHTS = {
    "what_does":         {"graph": 0.3, "vector": 0.2, "semantic": 0.5},
    "how_to_call":       {"graph": 0.4, "vector": 0.3, "semantic": 0.3},
    "what_calls":        {"graph": 0.8, "vector": 0.1, "semantic": 0.1},
    "what_called_by":    {"graph": 0.8, "vector": 0.1, "semantic": 0.1},
    "find_symbol":       {"graph": 0.5, "vector": 0.3, "semantic": 0.2},
    "compare":           {"graph": 0.4, "vector": 0.2, "semantic": 0.4},
    "debug_trace":       {"graph": 0.6, "vector": 0.2, "semantic": 0.2},
    "general_qa":        {"graph": 0.2, "vector": 0.2, "semantic": 0.6},
}
```

**중복 제거 (2-pass dedup)**:
1. 1차: `node_id`(unified format) 기준 중복 제거
2. 2차: `symbol_name` 기준 병합 — semantic 설명을 code 결과 metadata에 injection

### 6. Query Understanding

**목표**: 사용자 질문 의도 분석 + 검색 전략 결정

**의도 타입**:
- `call_flow`: 호출 순서/흐름 분석
- `definition`: 심볼 정의/시그니처 조회
- `relationship`: 함수 간 호출 관계
- `file_search`: 파일 위치 검색
- `general_qa`: 일반적인 코드 질문
- `config_query`: 빌드 설정 관련
- `macro_expansion`: 매크로 확장 확인

**구현 방식**:
- LLM 기반: GPT-mini (정확도 높음, API 비용 발생)
- 규칙 기반: 정규식 + 키워드 패턴 (무료, fallback용)

### 7. 인덱싱 체크포인트

**목표**: 대규모 코드베이스 인덱싱 중단/재개 지원

**상태 파일**: `~/.kernel-chat/data/index-state.json`

**기능**:
- 서브시스템별 진행률 추적
- 체크포인트 기반 재개 (`--resume`)
- 인덱싱 통계 누적 (노드 수, 엣지 수, API 비용)
- `semantic_version` 필드: 마지막 의미적 인덱싱 git commit hash

**원자적 쓰기**:
```python
# 임시 파일 → rename (원자적)
tmp_file = state_file.with_suffix(".tmp")
# ... tmp_file에 쓰기 ...
tmp_file.rename(state_file)
```

---

### 8. 의미적 인덱싱 (Semantic Indexing) [JOB-1209]

**목적**: C 코드의 자연어 설명을 생성하여, 한국어/영어 자연어 질문이 의미적으로 관련 있는 코드를 찾을 수 있게 함.

#### Description Generator

```python
class DescriptionGenerator:
    """LLM으로 함수/블록별 자연어 설명 생성."""

    def generate_descriptions(
        self, client, model: str, func_name: str, blocks: list[dict]
    ) -> list[str]:
        """배치 처리 (3개 블록/batch, 44% token 마진).
        Returns: [description_1, description_2, ...]
        """
```

**입력**: 함수 시그니처 + 파일 경로 + 코드 블록 (본문 포함, 1500자/블록 안전 제한)
**출력**: 1-2문장 영어 기술 설명 (150자 이하)
**배치**: 3 blocks/batch (3×1,200 tokens ≈ 3,600 / 8,191 = 44% 사용률)
**폴백**: 3단계 — JSON 파싱 → regex 추출 → 빈 문자열 (3회 재시도)
**테스트**: `MockOpenAIClient`로 LLM 호출 없이 테스트 (token 비용 방지)

```python
# Mock client — 실제 API 호출 없이 테스트 가능
from src.llm.description_generator import MockOpenAIClient

mock = MockOpenAIClient(responses=[["initizes scheduler", "handles interrupts"]])
descriptions = generate_descriptions(mock, "gpt-4o-mini", "schedule", blocks)
```

#### 체크섬 기반 증분 갱신 (Git 불의존)

```python
class SemanticIndexManager:
    def get_changed_files(self, current_files: list[str], checkpoint_path: str):
        """MD5 체크섬 비교로 변경 파일 추출 (git 불필요)."""
        # tarball/압축 파일 등 non-git 소스도 지원
```

- 파일 MD5 체크섬을 `index-state.json`에 저장
- 변경된 파일만 설명 재생성 → 비용 최소화
- git commit hash 방식 대신 파일 내용 기반 → tarball 커널 소스 지원

**비용 산정 공식**: `전체 블록 수 ÷ 배치 크기(3) × $0.005 × 재시도율(1.2) ≈ $8.10`
(커널 스케줄러 기준 ~1,619 호출, 증분 업데이트는 ~$0)

#### 검색 시 Semantic Search

```python
def _semantic_search(self, query: str, top_k: int) -> list[dict]:
    """kernel_function_descs 컬렉션에서 의미적 검색."""
    if not self.openai_client:
        return []
    embedding = self.openai_client.embed([query])[0]
    results = self.vector_store.collections["kernel_function_descs"].query(
        query_embeddings=[embedding],
        n_results=top_k,
        include=["documents", "metadatas", "distances"],
    )
    # → 표준 결과 형식 변환
```

#### 한국어 개념어 → 심볼 매핑

```python
KOREAN_CONCEPT_MAP = {
    "스케줄링": ["schedule", "sched", "tick", "preempt"],
    "프로세스": ["task_struct", "do_fork", "wake_up"],
    "메모리할당": ["kmalloc", "alloc_pages", "vmalloc"],
    "스핀락": ["spin_lock", "spin_unlock"],
    # ...
}

def _resolve_korean_concepts(self, query: str) -> list[str]:
    resolved = []
    for concept, symbols in KOREAN_CONCEPT_MAP.items():
        if concept in query:
            resolved.extend(symbols)
    return resolved
```

**⚠️ 한계**: 하드코딩 매핑은 확장성에 한계 있음. 장기적으로는 LLM 기반 동적 개념 매핑 필요.

## 구현 가이드

### 단계별 구현 순서

1. **P0-P3**: 프로젝트 구조 + 파서 + 심볼 테이블 + 그래프 스키마
2. **P4-P6**: Chunking + 벡터 스토어 + 하이브리드 검색
3. **P7-P9**: Query Understanding + CLI 통합 + 체크포인트

### 테스트 전략 (JOB-1209 교훈 반영)

**⚠️ 핵심: ChromaDB mock 테스트 금지**. mock ChromaDB는 중복 ID 거부를 구현하지 않아 실제 환경에서 `Expected IDs to be unique` 에러를 발생시킵니다. JOB-1209에서 이 문제로 2,700+ chunk 인덱싱 실패.

1. **Import 테스트**: 각 모듈 import 확인
2. **기능 테스트**: 핵심 클래스 메서드 검증
3. **실제 ChromaDB 테스트**: `PersistentClient`로 upsert/duplicate 동작 검증
4. **messy 테스트 데이터**: 중복 심볼, inline 함수, 50줄 초과 대용량 함수 포함
5. **CLI smoke 테스트**: --help, init, index, search, status
6. **통합 테스트**: **빌드된 실행파일**(PyInstaller)로 E2E 검증
7. **LLM mock 허용**: `MockOpenAIClient`로 token 비용 방지하되 파이프라인 흐름 검증

**상세 가이드**: `references/testing.md` 참조

```python
# ✅ 실제 ChromaDB로 upsert 테스트
def test_chromadb_upsert_deduplicates(tmp_path):
    import chromadb
    client = chromadb.PersistentClient(path=str(tmp_path))
    col = client.get_or_create_collection(name="test", metadata={"hnsw:space": "cosine"})
    col.upsert(ids=["func1"], documents=["original"], embeddings=[[0.1, 0.2]])
    col.upsert(ids=["func1"], documents=["updated"], embeddings=[[0.3, 0.4]])
    result = col.get(ids=["func1"])
    assert result["documents"][0] == "updated"

# ✅ messy 테스트 데이터 — 중복 심볼
symbols = [
    _make_symbol("my_func", "function", line_start=1, line_end=10),
    _make_symbol("my_func", "function", line_start=20, line_end=30),  # 중복
]
chunks = chunker.chunk_from_symbols(symbols, source, "/test/dup.c")
assert len([c for c in chunks if "my_func" in c.chunk_id]) == 1  # 중복 제거 검증
```

### Windows 배포

- Python 스크립트 + `pip install` 의존성 분리
- PyInstaller 배제 (~200MB 크기 과다)
- 실행: `python kernel-chat.py` 또는 `kernel-chat.bat` 쉘 스크립트

## 구현 패턴 (핵심)

### HybridSearch 3-way 검색 시그니처

CLI에서 `ask`와 `search` 두 명령어가 서로 다른 방식으로 HybridSearch를 호출하므로 **keyword-only 시그니처**로 통일하세요.

```python
class HybridSearch:
    def search(
        self,
        query: str,
        symbols: list[str] | None = None,    # QueryRouter에서 추출된 심볼명
        intent: str = "general_qa",             # 의도 타입
        top_k: int = 5,
        use_graph: bool = True,
        use_vector: bool = True,
        use_keyword: bool = True,
    ) -> list[dict]:
        ...
```

각 결과 dict는 반드시 다음 필드를 포함:
```python
{
    "node_id": str,     # 또는 "id" (ChromaDB 결과)
    "name": str,        # 심볼명 또는 문서명
    "label": str,       # 노드 타입 (Function, Struct, ...)
    "file": str,        # 파일 경로
    "line_start": int,
    "line_end": int,
    "score": float,     # 0.0 ~ 1.0
    "source": str,      # "graph" | "vector" | "keyword"
    "content": str,     # 코드 스니펫 (선택, 벡터 검색 결과)
}
```

### 의도 기반 검색 가중치 (Intent-based Weighting)

3-way/4-way 검색 결과를 통합할 때, 의도 타입에 따라 각 소스에 다른 가중치를 적용해야 합니다.

```python
INTENT_WEIGHTS = {
    # 7개 핵심 intent + semantic 통합 (합 = 1.0)
    "what_does":         {"graph": 0.3, "vector": 0.2, "semantic": 0.5},
    "how_to_call":       {"graph": 0.4, "vector": 0.3, "semantic": 0.3},
    "what_calls":        {"graph": 0.8, "vector": 0.1, "semantic": 0.1},
    "what_called_by":    {"graph": 0.8, "vector": 0.1, "semantic": 0.1},
    "find_symbol":       {"graph": 0.5, "vector": 0.3, "semantic": 0.2},
    "compare":           {"graph": 0.4, "vector": 0.2, "semantic": 0.4},
    "debug_trace":       {"graph": 0.6, "vector": 0.2, "semantic": 0.2},
    "general_qa":        {"graph": 0.2, "vector": 0.2, "semantic": 0.6},
    # +6 legacy intent (keyword 기반)
}
```

**중복 제거 (2-pass dedup)**:
1. **1차**: `node_id`(unified format: `func:name:hash`) 기준으로 중복 제거
2. **2차**: `symbol_name` 기준으로 동일 함수 결과 병합 — semantic 설명을 code 결과 metadata에 `semantic_description` 필드로 injection

```python
def _combine(self, graph_results, vector_results, semantic_results, intent):
    weights = INTENT_WEIGHTS.get(intent, INTENT_WEIGHTS["general_qa"])

    # 1. 각 소스 가중치 적용
    scored = []
    for r in graph_results:
        r["score"] *= weights["graph"]
        scored.append(r)
    # ... vector, semantic 동일

    # 2. 1차 dedup: node_id 기준
    seen_ids: dict[str, dict] = {}
    for r in scored:
        nid = r.get("node_id")
        if nid not in seen_ids or r["score"] > seen_ids[nid]["score"]:
            seen_ids[nid] = r

    # 3. 2차 dedup: symbol_name 기준 병합
    seen_names: dict[str, dict] = {}
    for r in seen_ids.values():
        sname = r.get("metadata", {}).get("symbol_name", "")
        if sname in seen_names:
            # semantic 설명 병합
            desc = r.get("metadata", {}).get("semantic_description")
            if desc:
                seen_names[sname]["metadata"]["semantic_description"] = desc
        else:
            seen_names[sname] = r
```

### LLM 답변 생성 (generate_answer)

검색 결과를 LLM 컨텍스트로 조립할 때는 다음 구조를 따르세요:

```python
SYSTEM_PROMPT = """너는 {도메인} 전문가야. 아래 검색 결과를 바탕으로 질문에 답해줘.
규칙:
1. 검색 결과에 기반하여 정확하고 구체적인 답변을 제공
2. 코드 참조 시 파일 경로와 행번호를 반드시 포함: [file:line]
3. 질문이 한국어면 한국어로, 영어면 영어로 답변
4. 기술적으로 정확하게 답변 — 추측은 명시적으로 표시

검색 결과 활용:
- "graph_overview" 소스 데이터가 있으면 인덱싱된 전체 구조를 설명하고, 구체적인 질문을 유도
- 검색 결과가 적으면 "인덱싱된 범위 내에서"라는 전제를 명시하고 답변
- 검색 결과가 전혀 없을 때: 인덱싱 상태, 가능한 질문 예시, 구체적인 키워드 사용 권고 제공"""

def _build_context(search_results, understanding):
    """검색 결과를 LLM 컨텍스트 문자열로 포맷팅."""
    lines = ["## 검색 결과\n"]

    # graph_overview가 있으면 먼저 포함
    overview = [r for r in search_results if r.get("node_id") == "__graph_overview__"]
    if overview:
        stats = json.loads(overview[0].get("context", "{}"))
        lines.append(f"### 인덱싱된 그래프 구조")
        lines.append(f"- 총 노드: {stats.get('nodes', 0)}개")
        lines.append(f"- 총 관계: {stats.get('edges', 0)}개")
        # node_types, edge_types도 포함

    # 실제 검색 결과 (graph_overview 제외)
    actual_results = [r for r in search_results if r.get("node_id") != "__graph_overview__"]
    if not actual_results:
        if not overview:
            lines.append("(검색 결과가 없습니다)")
        else:
            lines.append("(구체적인 매칭 결과 없음 — 위 그래프 구조를 참고하세요)")
        return "\n".join(lines)
    # ... 실제 결과 포맷팅
```

**⚠️ 한국어 쿼리 한계**: `_extract_keywords`가 `\w+` 패턴만 추출하므로 한국어 질문에서는 빈 결과가 나옵니다. `general_qa` + 심볼 없을 때 반드시 `_graph_overview()`로 폴백하여 그래프 요약을 반환하세요.

```python
# HybridSearch.search() 내에서
if not combined and intent == "general_qa" and not symbols:
    combined = self._graph_overview(top_k)
```

### ChromaDB 임베딩 저장 패턴

ChromaDB Collection을 embedding function 없이 생성한 경우, **임베딩을 명시적으로 전달**해야 합니다.

```python
# 저장 시
vector_store.add_vectors(
    collection="kernel_functions",
    documents=docs,
    ids=ids,
    metadatas=metas,
    embeddings=embeddings,  # ← OpenAI API에서 미리 생성
)

# 검색 시 — query_texts가 아닌 query_embeddings 사용
col.query(
    query_embeddings=[query_embedding],  # ← query_texts가 아님!
    n_results=10,
    include=["documents", "metadatas", "distances"],
)
```

### 의미적 검색 패턴 (_semantic_search)

```python
def _semantic_search(self, query: str, top_k: int = 5) -> list[dict]:
    """kernel_function_descs 컬렉션에서 의미적 검색."""
    if not self.openai_client:
        return []
    embedding = self.openai_client.embed([query])[0]
    results = self.vector_store.collections["kernel_function_descs"].query(
        query_embeddings=[embedding],
        n_results=top_k,
        include=["documents", "metadatas", "distances"],
    )
    # metadata에서 symbol_name, function_name, source_file 추출
    # → 표준 결과 형식으로 변환 후 반환
```

### AST 기반 Chunking 패턴

Tree-sitter 파싱 결과(Symbol 객체)에서 Chunk를 생성할 때, 라인 번호 기반 텍스트 추출을 사용하세요.

```python
from pathlib import Path

def chunk_from_symbols(symbols, file_path):
    source = Path(file_path).read_text()
    lines = source.splitlines()
    chunks = []
    for sym in symbols:
        if sym.symbol_type == "function":
            text = "\n".join(lines[sym.line_start-1:sym.line_end])
            chunks.append(Chunk(
                chunk_id=f"func:{sym.name}:{hash(file_path)[:8]}",
                tier=2.0,  # ← float 타입! (int 아님)
                content=text,
                source_file=sym.file_path,
                line_start=sym.line_start,
                line_end=sym.line_end,
                metadata={"function_name": sym.name, "return_type": sym.return_type},
            ))
            # 대용량 함수는 블록 분할
            if len(text.splitlines()) > 50:
                chunks.extend(chunk_function_blocks(
                    sym.name, text, sym.file_path, sym.line_start,
                    file_hash, chunks[-1].metadata,
                ))
    return chunks
```

**⚠️ Chunk.tier는 `float` 타입**: tier 2.0 = 함수 전체, tier 2.1 = 함수 내 논리적 블록.
`parent_chunk_id` + `block_index` 필드로 계층 관계 추적.

### 계층적 블록 분할 (Hierarchical Block Chunking)

```python
@staticmethod
def chunk_function_blocks(func_name, func_content, source_file, func_line_start,
                          file_hash, func_metadata, max_block_lines=80):
    """50줄 초과 함수를 논리적 블록으로 분할."""
    lines = func_content.splitlines()
    # 분할점: 주석(/*, //), 전처리기(#if/#elif/#else)
    # greedy packing: max_block_lines까지 누적 → 분할점에서 끊음
    # 결과: tier=2.1, parent_chunk_id=상위 함수 chunk_id
```

**분할 규칙**:
- 함수 ≤ 50줄: 분할하지 않음
- 함수 > 50줄: 논리적 경계(주석, 전처리기)에서 분할
- 최대 80줄/블록 (8191 토큰 제한의 안전 마진)
- `parent_chunk_id`로 상위 함수 참조, `block_index`로 순서 유지

### CLI 의미적 인덱싱 플래그

```bash
# 의미적 인덱싱 활성화 (LLM 호출 필요)
kernel-chat index -s sched --semantic

# 강제 초기화 + 의미적 재생성
kernel-chat index -s sched --force --semantic

# 의미적 인덱싱 강제 스킵
kernel-chat index -s sched --skip-semantic
```

**CLI 구현**:
- `--semantic`: LLM 기반 함수 설명 생성 + `kernel_function_descs` 컬렉션 저장
- `--skip-semantic`: 의미적 인덱싱 강제 스킵
- `--force` + `--semantic`: `clear_semantic_checkpoint()` → 전체 재생성
- 체크섬 기반: 변경된 파일만 LLM 호출

### GraphDB 자동 로딩 패턴

CLI 시작 시 GraphDB 인스턴스는 빈 그래프로 생성됩니다. 기존 `graph.db`가 있으면 명시적으로 로드해야 합니다.

```python
graph_db = GraphDB(str(data_dir / "graph.db"))
graph_file = data_dir / "graph.db"
if graph_file.exists() and graph_db.graph.number_of_nodes() == 0:
    graph_db.load_from_sqlite()
```

## PITFALLS

### ChromaDB 디폴트 임베딩 함수 — PyInstaller 번들에서 onnxruntime/tokenizers/huggingface-hub 에러 [JOB-1209 핵심]

**문제**: PyInstaller 번들 실행 시 `The onnxruntime python package is not installed` 또는 `The tokenizers python package is not installed` 에러 발생. `--collect-all onnxruntime`, `--collect-all tokenizers` 추가해도 해결 안됨.

**근본 원인**: `get_or_create_collection()`이 **디폴트 임베딩 함수**를 자동 초기화. 이 함수가 런타임에 `onnxruntime`/`tokenizers`/`huggingface-hub` import. PyInstaller `--collect-all`이 이를 잡아내지 못함.

**실패한 시도**:
1. `--collect-all onnxruntime tokenizers huggingface_hub` → 번들에 포함 안 됨
2. `pyproject.toml` 의존성 추가 → venv에는 설치되지만 번들에 포함 안 됨
3. `pip install onnxruntime` 명시적 설치 → 동일하게 실패

**근본 해결**: 컬렉션 생성 시 `embedding_function=None`으로 디폴트 임베딩 함수 완전 비활성화.

```python
import chromadb

# ❌ 실패: 디폴트 임베딩 함수 초기화 → onnxruntime/tokenizers import 시도
col = client.get_or_create_collection(
    name="my_collection",
    metadata={"hnsw:space": "cosine"},
)

# ✅ 성공: 디폴트 임베딩 함수 비활성화 — 외부 의존성 필요 없음
col = client.get_or_create_collection(
    name="my_collection",
    metadata={"hnsw:space": "cosine"},
    embedding_function=None,  # ← 필수!
)
```

**왜 작동하는가**: ChromaDB 컬렉션 생성 시 `DefaultEmbeddingFunction`을 설정하고, 이것이 내부적으로 `onnxruntime`/`tokenizers`를 lazy import합니다. `embedding_function=None`으로 설정하면 디폴트 함수가 전혀 로딩되지 않습니다. 우리는 항상 OpenAI 임베딩을 명시적으로 전달하므로 디폴트 함수는 필요 없습니다.

**⚠️ 반드시 모든 컬렉션 생성 시 적용할 것**. 하나의 컬렉션이라도 `embedding_function=None`을 생략하면 전체 번들이 에러 발생.

### ChromaDB add() vs upsert() — 재인덱싱 시 중복 ID 에러 [JOB-1209]

**문제**: `collection.add()`는 중복 ID를 **거부**합니다. 같은 서브시스템을 재인덱싱하면 `Expected IDs to be unique, found duplicates of: func:xxx:hash` 에러 발생.

**원인**
1. 동일 파일에서 같은 심볼이 여러 번 추출됨 (함수 선언+정의, 정적 인라인 헤더)
2. 재인덱싱 시 기존 ChromaDB에 같은 chunk_id가 이미 존재

**해결**: `add()` → `upsert()` 변경. 기존 ID가 있으면 덮어쓰고 없으면 추가.

```python
# ❌ 재인덱싱 시 중복 ID로 실패
col.add(ids=ids, documents=docs, metadatas=metas)

# ✅ 재인덱싱 안전 (중복 시 덮어씀)
col.upsert(ids=ids, documents=docs, metadatas=metas)
```

**추천**: 모든 ChromaDB 저장 작업은 `upsert()`로 통일. idempotent하게 설계하면 재인덱싱/중복/재시도 모두 자연스럽게 처리됨.

### Chunker 중복 chunk_id — 동일 파일 내 심볼 중복 [JOB-1209]

**문제**: Tree-sitter가 동일 파일에서 같은 함수를 여러 번 추출 (선언+정의, 헤더 인라인 포함 등). `func:{name}:{file_hash}` ID가 중복 생성 → ChromaDB upsert로 덮어씌워지지만 불필요한 계산 발생.

**해결**: `chunk_from_symbols()`에서 `seen_ids: set[str]`로 중복 제거

```python
seen_ids: set[str] = set()
for sym in symbols:
    chunk_id = f"func:{sym_name}:{file_hash}"
    if chunk_id in seen_ids:
        continue  # 동일 파일 내 중복 스킵
    seen_ids.add(chunk_id)
    # Chunk 생성...
```

**적용 범위**: function, struct/enum/typedef, variable 전 타입에 동일하게 적용.

### ChromaDB 의존성: onnxruntime 필수 [JOB-1209]

**문제**: ChromaDB가 내부 임베딩 모델에 `onnxruntime`를 필요로 하지만 명시적 의존성으로 포함 안됨. `pip install chromadb`만 하면 `The onnxruntime python package is not installed` 에러.

**해결**: `pyproject.toml`에 명시적 의존성 추가
```toml
dependencies = [
    "chromadb>=0.4.22",
    "onnxruntime>=1.17.0",  # ← ChromaDB 내부 임베딩용
]
```

**현상**: 벡터 인덱싱 중 일부 batch에서만 간헐적 발생 (ChromaDB 내부 lazy-load 때문). PyInstaller 빌드 시에도 `--collect-all onnxruntime` 포함 필요.

### CLI ↔ 모듈 API 불일치 (가장 흔한 버그)

CLI 코드가 설계서 기준 API를 가정하지만, 실제 모듈 클래스에는 존재하지 않는 메서드를 호출하는 문제가 빈번합니다.

**실제 발견된 불일치**:
- `graph_builder.add_file(path, symbols)` ❌ → 실제: `build_from_parse_results(list[ParseResult])` ✅
- `symbol_table.add_symbols(list, file)` ❌ → 실제: `add(SymbolEntry)` (단건) ✅
- `parser.parse_file()` 반환값이 `ParseResult` (심볼 포함)인데 이를 `AST node`로 잘못 취급
- `HybridSearch.search(query, top_k)`만 있었는데 CLI가 `search(query, symbols, intent)` 호출

**해결**: 구현 시작 시 `grep -r "def " src/`로 실제 공개 API를 먼저 확인하세요. CLI에서 호출하는 메서드가 모듈에 실제로 있는지 반드시 검증.

### Python API 불일치

테스트 중 발견된 일반적인 문제:
- 클래스명/메서드명 불일치: `inspect.signature()`로 실제 API 확인
- 반환값 타입: `None` vs `[]` (빈 리스트)
- 임포트 경로: `sys.path` 설정 필수

**해결**: 테스트 스위트 먼저 작성 → 실행 → API 확인 → 수정

### GraphDB API (NetworkX)

**❌ 존재하지 않는 메서드**:
```python
db.node_count()     # 없음
db.edge_count()     # 없음
```

**✅ 올바른 방식** (NetworkX 그래프 직접 접근):
```python
db.graph.number_of_nodes()
db.graph.number_of_edges()
```

**노드 라벨**: 대문자 필수 (`Function`, `Struct`, `File`) — 소문자(`function`, `struct`)는 유효성 검증 실패

### SymbolTable API

**❌ 존재하지 않는 메서드**:
```python
st.add_symbol(name, type, file, line)  # 없음
```

**✅ 올바른 방식**:
```python
from src.parser.symbol_table import SymbolEntry
entry = SymbolEntry(name="foo", symbol_type="Function", file_path="path.c", line_start=10, line_end=20)
st.add(entry)
```

**조회 반환값**: `st.lookup(name)` → `list[SymbolEntry]` 반환 (None 아님, 빈 리스트 `[]` 반환)

### ChromaDB Config 임포트

```python
# ❌ 에러: Config 없음
from chromadb import Config

# ✅ 올바른 방식
import chromadb
client = chromadb.PersistentClient(path="data/")
```

### fcntl.fsync 호환성

```python
# ❌ Python 3.11+에서 에러
fcntl.fsync(f.fileno())

# ✅ 올바른 방식
import os
os.fsync(f.fileno())
```

### Windows 호환성 문제

**flock 미지원**: Windows에서 `fcntl.flock()` 동작하지 않음.
- **대안**: `msvcrt.locking()` 또는 파일 기반 뮤텍스
- **체크포인트 패턴**: atomic write (tmp + rename)은 Windows에서도 동작

**파일 경로 구분자**:
- WSL/Linux: `/` (포워드는러시)
- Windows: `\` (백슬래시) → `pathlib.Path` 사용 권장

**Tree-sitter Windows 설치**: Visual Studio Build Tools (C 컴파일러) 필요
```powershell
# Windows 의존성 설치
pip install tree-sitter tree-sitter-languages
# MSVC Build Tools 설치 필요 (https://visualstudio.microsoft.com/visual-cpp-build-tools/)
```

### Typer CLI 명령어 검증

**❌ 틀린 방식**: `app.registered_commands`의 `name` 속성이 None일 수 있음
```python
# ❌ 이 방식은 작동하지 않음
commands = [cmd.name for cmd in app.registered_commands]
assert "ask" in commands  # AssertionError: None 확인
```

**✅ 올바른 방식**: `--help` 출력으로 명령어 존재 확인
```bash
# CLI 명령어 존재 확인
python -m src.cli --help | grep "ask"
```

또는 Python 테스트에서:
```python
from typer.testing import CliRunner
runner = CliRunner()
result = runner.invoke(app, ["--help"])
assert "ask" in result.output
```

### 한글 경로 (WSL)

```bash
# ❌ bash glob 확장 실패
cd /path/JOB-1186-리눅스*

# ✅ 변수 사용
JOB_DIR="$HOME/.hermes/workspace/jobs/JOB-1186-리눅스 커널 분석 챗봇"
cd "$JOB_DIR"
```

### 임베딩 컬렉션 분리 (Collection Separation) [JOB-1209]

**❌ 금지**: 코드 임베딩과 설명 임베딩을 같은 컬렉션에 혼합 저장

```python
# ❌ 코드+설명을 같은 컬렉션에 저장하면 cosine similarity 간섭 발생
vector_store.add_vectors(
    collection="kernel_functions",
    documents=[f"{description}\n\n{code}"],  # ❌ 혼합
)
```

**✅ 정답**: 목적별 컬렉션 분리

```python
# ✅ 코드 컬렉션 (코드 기반 검색용)
vector_store.add_vectors(
    collection="kernel_functions",
    documents=[code_text],
)

# ✅ 설명 컬렉션 (의미적 검색용)
vector_store.add_vectors(
    collection="kernel_function_descs",
    documents=[description],
)
```

### 2-pass Deduplication 필요 [JOB-1209]

**문제**: Graph 결과와 Semantic 결과가 같은 함수를 다른 `node_id`로 반환 → 중복 출력

**해결**:
1. 1차 dedup: `node_id` 기준 (정확히 동일한 결과 제거)
2. 2차 dedup: `symbol_name` 기준 (동일 함수의 다중 소스 결과 병합)
3. 병합 시 semantic 결과를 code 결과의 `metadata["semantic_description"]`에 injection

### 증분 업데이트: 체크섬 vs Git [JOB-1209]

**❌ git diff 가정 금지**: 커널 소스가 tarball 압축파일이나 non-git 환경일 수 있음

```python
# ❌ git diff는 tarball 환경에서 작동하지 않음
os.system("git diff <old> HEAD -- <path>")
```

**✅ 체크섬 기반**:
```python
import hashlib
checksum = hashlib.md5(Path(file_path).read_bytes()).hexdigest()
# 체크포인트(JSON)에 저장 → 변경 파일만 처리
```

### 대용량 함수 Chunk 크기 제한 [JOB-1209]

**문제**: `text-embedding-3-small` 최대 8191 토큰. 커널 함수는 500줄 이상도 흔함.

**해결**: 계층적 블록 분할
- 함수 ≤ 50줄: 단일 Chunk
- 함수 > 50줄: 제어문 기반 블록 분할
- 최대 블록 크기: 80줄 (안전 마진)

## 검색 실패 시 키워드 제안

검색 결과가 0개일 때 사용자에게 "다른 키워드로 시도하세요"만 표시하면 UX가 나쁩니다.
**인덱싱된 심볼명 top-K를 추천**하여 사용자가 다음 행동을 알 수 있게 하세요.

```python
def suggest_keywords(self, top_k: int = 10) -> list[str]:
    """인덱싱된 심볼에서 추천 키워드 추출."""
    from collections import Counter
    names: Counter = Counter()
    for _, data in self.graph_db.graph.nodes(data=True):
        name = data.get("name", "")
        if name:
            names[name] += 1
    return [name for name, _ in names.most_common(top_k)]
```

CLI에서 사용:
```python
if not results:
    suggestions = search_engine.suggest_keywords(top_k=10)
    console.print("[yellow]⚠️  검색 결과가 없습니다.[/yellow]")
    if suggestions:
        console.print(f"   💡 다음 키워드로 시도해보세요: [cyan]{', '.join(suggestions)}[/cyan]")
```

## 프롬프트 엔지니어링

### SYSTEM_PROMPT: 빈/부분 결과 시나리오 포함

```python
SYSTEM_PROMPT = """\
너는 {도메인} 전문가야. 아래 검색 결과를 바탕으로 질문에 답해줘.

검색 결과 활용:
- "graph_overview" 소스 데이터가 있으면 인덱싱된 전체 구조를 설명하고, 구체적인 질문을 유도
- 검색 결과가 적으면 "인덱싱된 범위 내에서"라는 전제를 명시하고 답변
- 검색 결과가 전혀 없을 때: 인덱싱 상태, 가능한 질문 예시, 구체적인 키워드 사용 권고 제공

예시 답변 패턴:
- "현재 sched 서브시스템이 인덱싱되어 있습니다. schedule 함수, task_struct 등 {N}개 심볼이 분석되어 있습니다. 'schedule 함수의 호출 흐름'처럼 구체적으로 물어봐주세요."
"""
```

### Context Builder: graph_overview 자동 포함

```python
def _build_context(search_results):
    lines = ["## 검색 결과\n"]
    overview = [r for r in search_results if r.get("node_id") == "__graph_overview__"]
    if overview:
        stats = json.loads(overview[0].get("context", "{}"))
        lines.append(f"### 인덱싱된 그래프 구조")
        lines.append(f"- 총 노드: {stats.get('nodes', 0)}개")
        lines.append(f"- 총 관계: {stats.get('edges', 0)}개")
    # ... 실제 결과 포맷팅
```

## AI 기술 스택 문서화

GraphRAG 프로젝트의 `docs/03-architecture-deep-dive.md`에 다음을 명시하세요:
- 사용 중인 AI 기술 (OpenAI, ChromaDB, NetworkX, Tree-sitter 등) + 버전
- **미사용** 기술도 명시 (LangGraph, LangChain, Llama 등)
- 검색 파이프라인 다이어그램
- Chunking 전략 테이블

## 엣지 케이스 테스트 필수

다음 시나리오는 반드시 테스트해야 합니다:
- **한국어/다국어 질문**: `\w+` 패턴이 동작하지 않음 → graph_overview 폴백 필수
- **general_qa + 심볼 없음**: 그래프 요약 반환
- **빈 검색 결과**: keyword suggestion + helpful message
- **API 키 없음**: vector indexing skip + 경고 메시지
- **임베딩 실패**: fallback (문서만 저장) + 경고

- Tree-sitter: https://tree-sitter.github.io/
- ChromaDB: https://www.trychroma.com/
- NetworkX: https://networkx.org/
- GraphRAG 논문: https://arxiv.org/abs/2404.56580
- **kernel-chat 구현 교훈**: `references/kernel-chat-lessons.md` (Rich markup, 한국어 쿼리, PyInstaller 등)
- **ChromaDB + PyInstaller 번들링 문제 해결**: `references/chromadb-pyinstaller-bundling.md`

## Tree-sitter C 파싱 0.22+ API (§ absorbed from tree-sitter-c-parsing)

**필수 설치**: `pip install tree-sitter tree-sitter-c`

### 초기화 (0.22+ API)

```python
import tree_sitter
from tree_sitter import Language, Parser, Query, QueryCursor
import tree_sitter_c

lang = Language(tree_sitter_c.language())
parser = Parser(lang)  # 언어를 생성자에 전달

source = Path(file_path).read_bytes()
tree = parser.parse(source)
```

**⛔ 이전 API 사용 금지**:
```python
# ❌ 0.21 이하 방식
parser = Parser()
parser.set_language(lang)  # AttributeError 발생
```

### 쿼리 작성 (QueryCursor 필수)

```python
# ✅ 0.22+ 방식
query = Query(lang, "(function_definition (identifier) @name)")
cursor = QueryCursor(query)
matches = list(cursor.matches(root))
# captures 값은 LIST (단일 노드가 아님!)
name_nodes = captures.get("name")  # list[Node]
name_node = name_nodes[0] if name_nodes else None
```

**⛔ 이전 API 사용 금지**:
```python
# ❌ 0.21 이하 방식
captures = query.matches(node)  # AttributeError
```

### C AST 구조

```
function_definition
  primitive_type              # 반환 타입
  function_declarator         # 함수 선언부
    identifier                # 함수명
    parameter_list            # 파라미터
  compound_statement          # 함수 본문

struct_specifier
  type_identifier             # 구조체명
  field_declaration_list
    field_declaration
      field_identifier        # 필드명 (identifier 아님!)

preproc_def                   # 매크로 (macro_definition 아님!)
  identifier                  # 매크로명
  preproc_arg                 # 본문
```

### Pitfalls

| # | 함정 | 해결 |
|---|------|------|
| 1 | QueryCursor 반복자는 한번만 사용 가능 | 각각 새 `QueryCursor(query)` 생성 |
| 2 | 캡처 값은 항상 리스트 | `captures.get("name")[0]` |
| 3 | `node.sexp()` 제거됨 | 커스텀 `print_tree()` 함수 사용 |
| 4 | `preproc_def`/`preproc_include` 노드명 변경 | `preprocessor_def`가 아님 |
| 5 | qualifier 추출 방식 변경 | `function_definition` 직접 자식에서 추출 |
| 6 | Rich 이모지 마크업 충돌 | 이모지는 `end=""`로 태그 밖에서 출력 |
| 7 | Python CLI import 경로 | `sys.path.insert(0, str(Path(__file__).parent))` |
| 8 | 필드명 매칭 미지원 | 위치 기반 매칭 사용 |
