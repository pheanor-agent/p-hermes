# GraphRAG for Code Analysis

> Session: JOB-1186 Linux kernel analysis chatbot
> Date: 2026-05-18

## Architecture Overview

GraphRAG (Graph + Vector + Keyword) hybrid retrieval for code analysis:

1. **Graph Retrieval** (NetworkX + SQLite)
   - Exact symbol matching
   - Call graph traversal
   - Include dependency chains
   - Highest weight (1.0-1.5)

2. **Vector Retrieval** (ChromaDB)
   - Semantic similarity search
   - Function/file chunk embeddings
   - Metadata filtering (subsystem, config)
   - Medium weight (0.7-0.9)

3. **Keyword Retrieval** (tantivy/BM25)
   - Exact keyword matching
   - Symbol name search
   - Lowest weight (0.3-0.6)

4. **LLM Refinement** (GPT-5.4 mini)
   - Merge and rank results
   - Generate natural language answer
   - Context assembly

## 3-Tier Chunking Strategy

| Tier | Unit | Embedding Model | Use Case |
|------|------|-----------------|----------|
| 1: Symbol | Variable, constant, enum | text-embedding-3-small (1024) | Exact symbol lookup |
| 2: Function | Full function (AST) | text-embedding-3-small (1024) | Semantic search + call graph |
| 3: File/Module | File or subsystem | text-embedding-3-large (3072) | Structural exploration |

## Chunk Metadata Schema

```json
{
  "chunk_id": "chunk:kernel/sched/core.c:schedule",
  "chunk_type": "function",
  "tier": 2,
  "code": "asmlinkage __visible void __sched schedule(void) {\n...",
  "file_path": "kernel/sched/core.c",
  "line_range": "6031-6190",
  "symbol_name": "schedule",
  "signature": "void schedule(void)",
  "callers": ["context_switch", "sched_yield", "kthread"],
  "callees": ["pick_next_task", "context_switch", "preempt_schedule"],
  "config_depends": ["CONFIG_SMP", "CONFIG_PREEMPT"],
  "subsystem": "scheduler",
  "embedding_model": "text-embedding-3-small",
  "embedding_dimensions": 1024
}
```

## ChromaDB Collections

| Collection | Dimension | Content |
|-----------|-----------|---------|
| kernel_functions | 1024 | Function-level embeddings |
| kernel_files | 3072 | File-level embeddings |
| kernel_docs | 3072 | Documentation embeddings |
| kernel_chunks | 1024 | Code block embeddings |

## SQLite Graph Schema

```sql
-- 10 node types: function, struct, macro, variable, file, module, config, enum, typedef, include_guard
CREATE TABLE nodes (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL,
    name TEXT NOT NULL,
    file_path TEXT,
    line_start INTEGER,
    line_end INTEGER,
    signature TEXT,
    docstring TEXT,
    config_depends TEXT,
    subsystem TEXT
);

-- 9 edge types: CALLS, INCLUDES, DEFINES, REFERENCES, DEPENDS_ON, EXTENDS, MEMBER_OF, CALLS_VIA_MACRO, CONFIG_DEPENDS
CREATE TABLE edges (
    id TEXT PRIMARY KEY,
    source TEXT REFERENCES nodes(id),
    target TEXT REFERENCES nodes(id),
    type TEXT NOT NULL,
    file_path TEXT,
    line INTEGER,
    properties TEXT  -- JSON
);
```

## Technology Selection Rationale

| Component | Choice | Alternatives | Reason |
|-----------|--------|-------------|--------|
| Parser | Tree-sitter + Clang | ctags (low accuracy), CodeQL (complex) | Speed + accuracy balance |
| Graph DB | NetworkX + SQLite | Neo4j (separate process), igraph (license) | Windows native, no extra service |
| Vector DB | ChromaDB | Qdrant (Docker), LanceDB (ecosystem) | SQLite backend, local mode |
| Embedding | OpenAI API | BGE-M3 (needs fine-tuning), CodeT5+ (needs GPU) | Immediate use, no GPU needed |
| LLM | GPT-5.4 mini | GPT-4o (expensive), local models (accuracy) | Code understanding + cost |
| Distribution | Python script | PyInstaller (~200MB) | Size reduction |

## Kernel-Specific Handling

### Macro Dual-Layer

```
Original: container_of(ptr, type, member)
  ├─ Layer 1: Macro definition node
  │  edge: EXTENDS → expanded_code
  └─ Layer 2: Expansion result
     edge: CALLS_VIA_MACRO → actual called function
```

### CONFIG Conditional Compilation

```c
#ifdef CONFIG_SMP
    smp_call_function(...);  // Only in graph if CONFIG_SMP enabled
#endif
```

- Filter by defconfig
- Record `config_depends` metadata
- Separate CONFIG dependency graph

### Kernel Idioms

| Pattern | Handling |
|---------|----------|
| `container_of(ptr, type, member)` | Reverse lookup: member → struct |
| `EXPORT_SYMBOL(name)` | Module boundary (edge: EXPORTS) |
| `list_for_each_entry()` | Macro-based iteration → edge: ITERATES |
| `static inline` | Header file functions |

## Partial Indexing

For large codebases, support subsystem-level indexing:

```bash
# Available subsystems
sched   - kernel/sched/
vfs     - fs/
net     - net/
mm      - mm/
driver  - drivers/
ipc     - ipc/, kernel/exit.c
block   - block/
crypto  - crypto/
common  - lib/, include/linux/

# Commands
kernel-chat index --subsystem sched          # ~minutes
kernel-chat index --subsystem sched,vfs,net  # ~tens of minutes
kernel-chat index --all                      # ~hours (document as long)
```

## Distribution Strategy (Python Script)

```
kernel-chat/
├── kernel-chat.py          # Entry point
├── src/
│   ├── cli.py               # Typer CLI
│   ├── parser/              # Tree-sitter + Clang
│   ├── graph/               # NetworkX + SQLite
│   ├── vector/              # ChromaDB wrapper
│   ├── chunking/            # 3-Tier Chunker
│   ├── search/              # Hybrid search
│   └── llm/                 # OpenAI client
├── requirements.txt
└── README.md
```

Install:
```bash
pip install -r requirements.txt
python kernel-chat.py init
```

## Cost Estimates (1000 queries/month)

| Model | Purpose | Monthly |
|-------|---------|---------|
| GPT-5.4 mini | Answer generation | $5-15 |
| text-embedding-3-small | Function/symbol embedding | $1-3 |
| text-embedding-3-large | File/module embedding (optional) | $2-5 |

**Total: $8-23/month**

## Key Lessons Learned

1. **Separate LLM vs Vector concerns** — users need clear distinction between when each is used
2. **Support partial indexing** — full kernel indexing takes hours, testing requires subsystem selection
3. **Python script > PyInstaller** — 200MB .exe is too large for distribution
4. **Design change log essential** — multiple iterations require full change history
5. **Chinese character scanning** — Korean output can include Chinese chars (惯習, 待疐, 覆盖率, 轻量, 安装包)
6. **Phase mapping must match** — roadmap phases must align with acceptance criteria
