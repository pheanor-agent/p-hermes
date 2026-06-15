# Kernel-Chat 구현 참조 (2026-05-19)

GraphRAG 기반 커널 코드 분석 챗봇 구현 세션에서 도출된 실제 구현 패턴.

## 아키텍처 요약

```
CLI (Typer+Rich) → QueryRouter → HybridSearch → Graph/Vector/Keyword
                              ↓
                        OpenAIClient (GPT-4o-mini)
                              ↓
                        자연어 답변 (스트리밍 지원)
```

## 핵심 구현 패턴

### HybridSearch._combine() — 3-way 결과 통합

```python
def _combine(self, parts: dict[str, list[dict]], intent: str) -> list[dict]:
    # intent 기반 가중치 적용
    weights = BOOSTS.get(intent, BOOSTS["general_qa"])
    merged: dict[str, dict] = {}  # node_id -> best result
    for source, items in parts.items():
        boost = weights.get(source, 1.0)
        for item in items:
            boosted_score = item["score"] * boost
            nid = item.get("node_id") or item.get("id", "")
            if nid not in merged or boosted_score > merged[nid]["score"]:
                merged[nid] = {**item, "score": round(boosted_score, 4)}
    return sorted(merged.values(), key=lambda r: r["score"], reverse=True)
```

### Keyword Search — SQLite LIKE 패턴

```python
def _keyword_search(self, query, symbols, top_k):
    # 심볼명 정확 매칭 (우선순위 높음)
    for sym in symbols:
        for nid in self.graph_db.get_nodes_by_name(sym):
            ... # score 0.95

    # SQL 기반 LIKE 검색 (이름, 파일명)
    rows = self.graph_db.query_sql(
        "SELECT id, label, name, file_path, line_start, line_end, properties "
        "FROM nodes WHERE name LIKE ? LIMIT ?",
        (f"%{keyword}%", top_k),
    )
```

### Vector Search — query_embeddings 필수

ChromaDB Collection이 embedding function 없이 생성되면 `query_texts`로 검색 불가. 반드시 `query_embeddings` 사용.

```python
# 검색 시
resp = col.query(
    query_embeddings=[query_embedding],  # query_texts가 아님!
    n_results=min(top_k, 10),
    include=["documents", "metadatas", "distances"],
)
# distance → score 변환: score = max(0.0, 1.0 - cosine_distance)
```

### 인덱싱 파이프라인 수정

기존 설계: `parser.parse_file() → parser.extract_symbols(ast)` ❌
실제 구현: `parser.parse_file()`이 이미 `ParseResult` 반환 (symbols 포함)

```python
# 올바른 인덱싱 루프
for c_file in c_files:
    parse_result = parser.parse_file(str(c_file))  # → ParseResult
    # 그래프 빌드 (일괄)
    parse_results.append(parse_result)
    # 벡터 인덱싱
    chunks = chunker.chunk_file(str(c_file), parse_result.symbols)
    _index_vectors(chunks, vector_store, llm_client)
# 그래프 빌드는 파일 루프 완료 후 일괄 처리
graph_builder.build_from_parse_results(parse_results)
```

## 발견된 API 불일치 (CLI ↔ 모듈)

| CLI에서 호출 | 실제 모듈 API |
|---|---|
| `graph_builder.add_file(path, symbols)` | `build_from_parse_results(list[ParseResult])` |
| `symbol_table.add_symbols(list, file)` | `add(SymbolEntry)` 단건 |
| `parser.parse_file() → AST` | `ParseResult` (symbols 포함) |
| `search_engine.search(q, symbols, intent)` | `search(query=..., symbols=..., intent=...)` keyword |
| `llm_client.generate_answer()` | 존재하지 않음 → 새로 구현 |
