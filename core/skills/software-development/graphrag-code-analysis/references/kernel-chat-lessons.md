# kernel-chat 구현 교훈 (JOB-1204, JOB-1209)

## Rich MarkupError

**문제**: `console.print(f"[red]❌ 경로: {kernel_path}[/red]")`에서 경로에 `[sched]` 같은 문자가 포함되면 MarkupError

**해결**: 모든 사용자 데이터에 `escape()` 적용
```python
from rich.markup import escape
console.print(f"[red]❌ 경로: {escape(str(kernel_path))}[/red]")
```

**태그 불일치**: `[bold blue]...[/bold]` ❌ → `[bold blue]...[/bold blue]` ✅

## 한국어 질문 검색 실패

**원인**: `_extract_keywords(query)`가 `\w+` 패턴만 추출 → 한국어 질문에서 빈 결과

**해결**: `general_qa` + 심볼 없을 때 `_graph_overview()`로 폴백
```python
if not combined and intent == "general_qa" and not symbols:
    combined = self._graph_overview(top_k)
```

## PyInstaller --collect-all

**.spec 파일과 --collect-all 충돌**: `.spec` 파일이 있을 때 `--collect-all` 옵션 무시됨

**해결**: `.spec` 파일 대신 명령줄로 직접 빌드
```bash
pyinstaller --noconfirm \
    --collect-all chromadb \
    --collect-all openai \
    --collect-all tree_sitter \
    --collect-all networkx \
    --collect-all rich \
    src/cli.py
```

## 빌드 후 실행파일 테스트 필수

**교훈**: `python -m src.cli` 통과 ≠ PyInstaller 빌드 실행파일 동작

**규칙**: `git pull` 후 반드시 `./build.sh` 재빌드 + `./dist/my-cli/my-cli --help` 테스트

## API 키 UX

- `getpass()` 사용 시 "보안상 입력 내용이 표시되지 않습니다" 안내 필수
- 저장 후 마스킹된 형태 표시: `sk-abc1234...xyz789`
- 이미 설정된 API 키는 재입력하지 않고 표시만

## 벡터 인덱싱 silent failure

**문제**: `except: pass`로 벡터 인덱싱 실패 침묵 → 사용자에게 알림 없음

**해결**:
- 실패 시 `console.print("[yellow]⚠️  벡터 인덱싱 실패: {error}[/yellow]")`
- `embeddings` 파라미터를 `add_vectors()`에 반드시 전달
- 인덱싱된 chunk 수를 반환하여 완료 후 요약 표시

## 프롬프트 엔지니어링

**SYSTEM_PROMPT 개선**:
- 검색 결과가 부족할 때 LLM이 어떻게 행동할지 명시
- graph_overview 활용 가이드 포함
- 빈 결과 시 유용한 폴백 메시지 패턴 제시

**Context builder**:
- `graph_overview` 결과 타입 자동 감지 → 그래프 통계 포함
- 빈 결과 시 "(검색 결과가 없습니다)"가 아닌 "(구체적인 매칭 결과 없음 — 위 그래프 구조를 참고하세요)"

---

## JOB-1209: 의미적 인덱싱 설계 교훈

### Typer 다국어 인자 파싱

**문제**: `kernel-chat ask 한국어 질문` → Shell이 띄어쓰기로 분리 → Typer "extra arguments" 에러

**해결**: `main()`에서 `sys.argv` 전처리
- `query: tuple[str, ...]` 사용 불가 (Typer Ellipsis 처리 충돌)
- **`sys.argv` 전처리가 유일한 안정적 해결책**

### 임베딩 컬렉션 분리 [핵심]

**문제**: 코드+설명을 같은 컬렉션에 혼합 → cosine similarity 간섭

**해결**:
```python
# 코드 컬렉션 (코드 기반 검색)
kernel_functions → code_text 임베딩

# 설명 컬렉션 (의미적 검색)
kernel_function_descs → description_text 임베딩
```

### 계층적 Chunking

- 함수 ≤ 50줄: 단일 Chunk
- 함수 > 50줄: 제어문(if/for/while) 기반 블록 분할
- 최대 80줄/블록 (text-embedding-3-small 8191 토큰 제한)
- `parent_chunk_id`로 상위 함수 참조

### Git 기반 증분 갱신

```python
# git diff로 변경 파일 감지
subprocess.run(
    ["git", "-C", kernel_path, "diff", "--name-only",
     f"{semantic_version}..HEAD", "--", kernel_path],
    capture_output=True, text=True
)
```
- `semantic_version` (git commit hash) 체크포인트에 저장
- 변경된 함수만 설명 재생성 → 비용 최소화

### 한국어 개념어 매핑

```python
KOREAN_CONCEPT_MAP = {
    "스케줄링": ["schedule", "sched", "tick", "preempt"],
    "프로세스": ["task_struct", "do_fork", "wake_up"],
    "메모리할당": ["kmalloc", "alloc_pages", "vmalloc"],
    "스핀락": ["spin_lock", "spin_unlock"],
    # ...
}
```

**한계**: 하드코딩 매핑은 확장성 한계. 장기적으로 LLM 기반 동적 매핑 필요.

---

## JOB-1209: 실제 커널 소스 인덱싱 버그

### ChromaDB 중복 ID 에러 (Production)

**현상**: 실제 커널 소스 인덱싱 시 `Expected IDs to be unique, found duplicates of: func:xxx:hash` 에러 대량 발생

**원인 2가지**:
1. **동일 파일 내 심볼 중복**: Tree-sitter가 함수 선언+정의를 모두 추출, 또는 헤더 인라인 함수가 여러 번 포함
2. **재인덱싱**: 같은 서브시스템을 2회 이상 인덱싱하면 기존 ChromaDB에 ID 충돌

**해결**:
1. `chunker.py`: `seen_ids` set로 동일 파일 내 중복 chunk_id 제거
2. `chroma_store.py`: `add()` → `upsert()` (중복 ID 덮어쓰기)

**검증**: `kernel-chat index --subsystem sched` 재실행 시 에러 없이 정상 동작

### ChromaDB onnxruntime 의존성 누락

**현상**: `The onnxruntime python package is not installed` — ChromaDB 내부 임베딩 모델에서 발생

**해결**: `pyproject.toml`에 `onnxruntime>=1.17.0` 의존성 추가 + `pip install onnxruntime`

**참고**: ChromaDB가 lazy-load로 필요할 때才发现. PyInstaller 빌드 시 `--collect-all onnxruntime`도 필요.

### 체크섬 기반 증분 vs Git diff

**수정**: 설계 단계에서 git diff 기반이었지만, 실제 tarball 커널 소스 환경에서는 git이 없을 수 있음. 파일 MD5 체크섬으로 변경.

```python
# 체크섬 기반 (tarball/압축 파일 환경에서도 동작)
checksum = hashlib.md5(Path(file_path).read_bytes()).hexdigest()
```
