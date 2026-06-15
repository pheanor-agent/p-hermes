# Python Package Quality Checklist

Session-derived patterns from kernel-chat quality audit (JOB ongoing).

## Common Issues Found

### 1. Missing `__all__` exports
**Problem**: No explicit export list → `from module import *` pulls internals.
**Fix**: Add `__all__` after imports, listing only public symbols.

```python
# After all imports
__all__ = [
    "PublicClass",
    "public_function",
    "PUBLIC_CONSTANT",
]
```

### 2. Inline imports (function-level)
**Problem**: `import hashlib` inside `make_node_id()` instead of module level.
**Impact**: Redundant lookups, harder to audit dependencies.
**Fix**: Move to module-level imports (after `from __future__`).

### 3. Unused imports
**Problem**: `import hashlib` in builder.py but never used.
**Detection**: `grep -n "hashlib\." file.py` returns nothing.
**Fix**: Remove unused import.

### 4. Return type mismatches
**Problem**: Declared `-> list[list[str]]` but returns `list[set[str]]` (from `nx.connected_components()`).
**Fix**: Match declared type to actual return. Use `list[set[str]]` or cast explicitly.

### 5. Magic numbers
**Problem**: Hardcoded `1024`, `1536` for embedding dimensions.
**Fix**: Extract to constants with doc comments:
```python
# OpenAI text-embedding-3-small dimension
_OPENAI_EMBEDDING_DIM = 1536
```

### 6. f-strings in except blocks
**Problem**: `logger.error(f"Failed: {e}")` in except can mask original traceback.
**Fix**: Capture `err_msg = str(e)` before f-string or use `exc_info=True`.

### 7. `__init__.py` eager imports → circular dependency
**Problem**: `from . import semantic_router, vector_store, ...` causes ImportError.
**Fix**: Use lazy imports after `__all__`:
```python
__all__ = ["GraphDB", "ChromaStore"]
# ...
from src.graph.graph_db import GraphDB  # noqa: E402,F401
```

### 8. Missing module docstrings
**Problem**: Files without descriptive docstrings.
**Fix**: Add 1-line docstring describing module purpose.

## Tools

```bash
# Pylint (project-level)
.venv/bin/pylint --rcfile=pyproject.toml src/

# Pyright (type checking)
.venv/bin/pyright src/ --outputjson

# Ruff (fast linting)
ruff check src/

# Import sorting
ruff check --select I src/  # isort
```

## Batch Workflow

1. `grep -rn "^__all__" src/` → identify missing exports
2. `grep -rn "^import\|^from" src/ | sort` → audit imports
3. Parallel patch: `__all__` additions + unused import removals
4. Sequential patch: type hints, magic numbers
5. Re-verify: pylint/pyright

## Session Notes

- kernel-chat uses `src/` as package root (not `src/kernel_chat/`)
- `pyproject.toml` has `include = ["src*"]` and `"" = "."`
- ChromaDB collections need explicit `embedding_function=None` to avoid PyInstaller issues
- OpenAI SDK type hints are strict — use `# type: ignore` for dynamic dicts when necessary
