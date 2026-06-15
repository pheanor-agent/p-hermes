---
name: cli-development
description: "Python CLI app development: Typer/Click argument handling, shell parsing quirks, testing strategies, and deployment."
version: 1.0.0
---

# CLI Development (Python/Typer)

## Shell Argument Parsing (CRITICAL)

**Shell splits arguments on spaces BEFORE Python sees them.** This breaks natural language input.

```bash
# User types this:
kernel-chat ask 어떤 함수를 알고 있어?

# Shell passes to Python:
argv = ['kernel-chat', 'ask', '어떤', '함수를', '알고', '있어?']
```

Typer/Click sees 4 separate positional args, not 1 string.

**Fix**: Preprocess `sys.argv` in `main()` to join args after subcommand:

```python
def main():
    # Join all args after 'ask'/'search' into single string
    argv = sys.argv[1:]
    new_argv = []
    i = 0
    while i < len(argv):
        if argv[i] in ("ask", "search") and i + 1 < len(argv):
            new_argv.append(argv[i])
            i += 1
            query_parts = []
            while i < len(argv):
                if argv[i].startswith("--"):
                    if query_parts:
                        new_argv.append(" ".join(query_parts))
                        query_parts = []
                    new_argv.append(argv[i])
                    # Handle --flag value
                    if "=" not in argv[i] and i + 1 < len(argv) and not argv[i+1].startswith("--"):
                        new_argv.append(argv[i+1])
                        i += 2
                        continue
                    i += 1
                else:
                    query_parts.append(argv[i])
                    i += 1
            if query_parts:
                new_argv.append(" ".join(query_parts))
        else:
            new_argv.append(argv[i])
            i += 1
    sys.argv = [sys.argv[0]] + new_argv
    app()
```

**⚠️ Do NOT rely on users quoting input.** Always test unquoted.

## Typer Pitfalls

| Issue | Fix |
|-------|-----|
| `tuple[str, ...]` not supported | Use `sys.argv` preprocessing in `main()` |
| Korean/multi-word input fails | Preprocess argv as shown above |
| `allow_extra_args` + Typer | Use `@click.pass_context` or sys.argv preprocessing |
| Rich MarkupError on user data | Always `rich.markup.escape()` user input |
| `[bold blue]...[/bold]` tag mismatch | Tags must match: `[/bold blue]` |
| Optional expensive features (LLM) | `--feature` flag opt-in, default OFF |

### Rich MarkupError — Always escape user data

Rich `console.print()` interprets `[` and `]` as markup tags. User data containing brackets causes `MarkupError`.

```python
from rich.console import Console
from rich.markup import escape

console = Console()

# ❌ Dangerous — MarkupError if kernel_path contains brackets
console.print(f"[red]❌ Not found: {kernel_path}[/red]")

# ✅ Safe — always escape() user data
console.print(f"[red]❌ Not found: {escape(str(kernel_path))}[/red]")
```

**Escape required for ALL**: paths, filenames, user input, search terms, LLM responses.

### Optional expensive feature flag pattern

LLM API calls etc. should be **OFF by default**, opt-in via explicit flag:

```python
@app.command()
def index(
    semantic: bool = False,       # --semantic: LLM description generation
    skip_semantic: bool = False,  # --skip-semantic: force skip
    force: bool = False,          # --force: reinitialize
):
    if skip_semantic:
        semantic = False
    if semantic and not get_api_key():
        raise typer.Exit("OpenAI API key required (.env)")
```

## Project Structure (pyproject.toml)

```
my-cli/
├── pyproject.toml         # Package metadata + dependencies + entry point
├── requirements.txt       # Dev dependencies
├── build.sh / build.bat   # Build scripts
├── README.md
├── .gitignore
├── src/
│   ├── __init__.py
│   ├── cli.py             # Typer/Click CLI entry point
│   └── ...
└── tests/
    ├── __init__.py
    └── test_*.py
```

### Correct build-backend

```toml
[build-system]
requires = ["setuptools>=68.0", "wheel"]
build-backend = "setuptools.build_meta"    # ✅ Correct
# ❌ build-backend = "setuptools.backends._legacy:_Backend" → ImportError
```

### Entry point (src layout)

```toml
[project.scripts]
my-cli = "src.cli:main"                    # ✅ src/ package

[tool.setuptools.packages.find]
where = ["."]
include = ["src*"]
```

**Trap**: entry point must match actual directory structure or `ModuleNotFoundError` occurs.

## Testing Strategy

**Three layers required:**

1. **Unit tests**: Test Python functions directly (fast, precise)
2. **CLI integration tests**: Test actual CLI via `subprocess` (catches shell parsing issues)
3. **Mock API tests**: LLM/external API calls mocked (prevent token costs)

```python
# Mock OpenAI client — no real API calls
class MockOpenAIClient:
    # ... mock implementation matching real API chain structure
```

**⚠️ Mock must exactly match the real API method chain structure.**
`client.chat.completions.create()` → mock also `mock.chat.completions.create()`.

**Run integration tests with BUILT executable**, not Python directly.

```python
# tests/test_cli_integration.py
import subprocess

def test_ask_unquoted_korean():
    result = subprocess.run(
        ["kernel-chat", "ask", "어떤", "함수를", "알고", "있어?"],
        capture_output=True, text=True
    )
    assert result.returncode == 0
    assert "Q:" in result.stdout
```

## Build & Deploy (PyInstaller)

```bash
pyinstaller --noconfirm \
    --name my-cli \
    --onedir \
    --console \
    --collect-all chromadb \
    --collect-all openai \
    --collect-all tree_sitter \
    --collect-all networkx \
    --collect-all rich \
    --hidden-import src \
    --hidden-import src.cli \
    src/cli.py
```

- **`--collect-all`** mandatory for packages with dynamic imports
- Test built executable: `./dist/my-cli/my-cli --help`
- **⚠️ Source test ≠ build test**: `python -m src.cli` passing does NOT mean the built executable works. PyInstaller freezes code at build time. Always test the built binary.

### `--collect-all` limitation (ChromaDB case)

`--collect-all` only detects static dependencies. ChromaDB lazy-imports `onnxruntime`, `tokenizers`, `huggingface-hub` which `--collect-all` misses. **Solution**: disable library defaults (e.g., ChromaDB `embedding_function=None`).

## Silent Failure Debugging

Background work (vector indexing, API calls) failures must NOT be silenced:

```python
# ❌ Forbidden: silent exception swallowing
try:
    embeddings = llm_client.embed(documents)
    vector_store.add_vectors(...)
except Exception:
    pass

# ✅ Required: warning message + count tracking
def _index_vectors(chunks, vector_store, llm_client, console=None):
    if not chunks or not llm_client:
        if console:
            console.print("[yellow]⚠️  Vector indexing skipped (no API key)[/yellow]")
        return 0
    indexed = 0
    for ...:
        try:
            embeddings = llm_client.embed(docs)
            vector_store.add_vectors(..., embeddings=embeddings)  # ← embeddings required!
            indexed += len(docs)
        except Exception as e:
            if console:
                console.print(f"[yellow]⚠️  Embedding failed: {escape(str(e))}[/yellow]")
    return indexed
```

**Key**: Always pass `embeddings` to `add_vectors()`. Omitting stores docs without embeddings. Never use `except: pass`.

## API Key Input UX

`getpass.getpass()` hides input — users may think nothing happened. Add feedback:

```python
import getpass
from rich.console import Console
console = Console()

console.print("Enter OpenAI API key (sk-...)")
console.print("[dim]Input is hidden for security.[/dim]")
key = getpass.getpass()
if key:
    config.set_api_key(key)
    masked = f"{key[:8]}...{key[-4:]}"
    console.print(f"[green]✅ API key saved ({masked})[/green]")
```

**Rule**: If API key already set, skip re-prompting.

## Build Script Essentials (build.sh)

```bash
#!/bin/bash
set -e

# 1. venv
[ ! -d ".venv" ] && python3 -m venv .venv
source .venv/bin/activate

# 2. Dependencies
pip install --upgrade pip
pip install -e .
pip install pyinstaller

# 3. Build
pyinstaller --noconfirm --name my-cli --onedir --console \
    --collect-all chromadb --collect-all openai \
    --collect-all tree_sitter --collect-all networkx --collect-all rich \
    --hidden-import src --hidden-import src.cli \
    src/cli.py

# 4. PATH symlink
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"
ln -sf "$(pwd)/dist/my-cli/my-cli" "$LOCAL_BIN/my-cli"

# 5. Test built executable
./dist/my-cli/my-cli --help || echo "⚠️ Build test failed!"
```

**⚠️ Critical**: `--collect-all` cannot coexist with `.spec` files. Use command-line build directly.

## Shell Variable Trap

Variables defined in build scripts do NOT propagate to user shell:

```bash
# ❌ Build script local var — user's shell sees empty $LOCAL_BIN
LOCAL_BIN="$HOME/.local/bin"
echo "export PATH=$LOCAL_BIN:\$PATH"

# ✅ Use $HOME or absolute paths
echo "export PATH=\$HOME/.local/bin:\$PATH" >> ~/.bashrc
```

## Bash Backtick Escaping (JOB-1614)

Backticks inside double-quoted strings are interpreted as **command substitution**, not literal characters.

```bash
# ❌ BROKEN: ``` is treated as command substitution
echo "```json"
#    ^^^ bash tries to run `` as a command, then sees "json""

# ✅ FIX: Use single quotes for literal backticks
echo '```json'

# ✅ FIX: Escape each backtick with backslash
echo "\`\`\`json"
```

**Common affected patterns**:
- Markdown code blocks in echo/cat heredocs: `echo "```bash"` → use `echo '```bash'`
- YAML frontmatter with backticks in generated files
- Any `echo "..."` that contains template literals or markdown fenced blocks

**Rule of thumb**: When generating markdown or code that contains backticks, **always use single-quoted echo** or a heredoc with a quoted delimiter (`cat << 'EOF'`).

## Git Push Pre-Checklist

1. **Executable permissions**: `chmod +x build.sh build.bat` → git add → commit
2. **Build test**: Run `./build.sh` locally before pushing
3. **.gitignore**: `.env`, `*.db`, `.venv/`, `__pycache__/`
4. **Entry point verification**: `python -m src.cli --help` or `.venv/bin/my-cli --help`
5. **Built executable test**: `./dist/my-cli/my-cli --help`

## Related Skills

- `test-driven-development` — testing methodology
- `systematic-debugging` — debugging approach