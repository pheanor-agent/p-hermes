# GraphRAG 코드 분석 테스트 가이드

## 통합 테스트 스위트 템플릿

```python
"""통합 테스트 스위트."""
import sys
import tempfile
import os
from pathlib import Path

# 프로젝트 src 디렉토리 추가
sys.path.insert(0, str(Path(__file__).parent / "src"))

passed = 0
failed = 0
errors = []

def test(name, func):
    """테스트 헬퍼 함수."""
    global passed, failed
    try:
        func()
        print(f"  ✅ {name}")
        passed += 1
    except Exception as e:
        print(f"  ❌ {name}: {e}")
        failed += 1
        errors.append((name, str(e)))

# ─── Import 테스트 ───
def test_import_module():
    from src.module import ClassName
test("module import", test_import_module)

# ─── 기능 테스트 ───
def test_feature():
    from src.module import ClassName
    obj = ClassName()
    assert obj.some_method() == expected_result
test("기능 테스트", test_feature)

# ─── 결과 요약 ───
print(f"\n테스트 결과: ✅ {passed} / ❌ {failed} / 총 {passed + failed}")
sys.exit(0 if failed == 0 else 1)
```

## Python API 불일치 패턴

| 증상 | 원인 | 해결 |
|------|------|------|
| `cannot import name 'X'` | 클래스명/함수명 불일치 | `dir(module)`로 실제 내보내기 확인 |
| `got an unexpected keyword argument` | 시그니처 불일치 | `inspect.signature()` 확인 |
| `has no attribute 'X'` | 메서드명 변경 또는 상속 누락 | `dir(obj)`로 실제 메서드 확인 |
| 반환값 타입 불일치 | 예상 `None` vs 실제 `[]` (빈 리스트) | 반환 타입 주석 확인 |

## API 검증 명령어

```python
import inspect
from src.module import ClassName, some_function

# 클래스 메서드 목록
print([m for m in dir(ClassName) if not m.startswith('_')])

# 함수 시그니처
print(inspect.signature(some_function))
```

## 가상 환경 테스트

```bash
# 시스템 Python이 PEP 668로 보호된 경우
python3 -m venv .venv && source .venv/bin/activate
pip install -q pytest typer rich tree-sitter chromadb openai
python test_all.py
```

## WSL 한글 경로 주의사항

```bash
# ❌ 실패: bash glob 확장 문제
cd /path/JOB-1186-리눅스*

# ✅ 성공: 변수 사용
JOB_DIR="$HOME/.hermes/workspace/jobs/JOB-1186-리눅스 커널 분석 챗봇"
cd "$JOB_DIR"
```

---

## ⚠️ ChromaDB 테스트: mock 금지 (JOB-1209 교훈)

**핵심 원칙**: ChromaDB의 핵심 동작(add vs upsert, 중복 ID 처리, 메타데이터 검증)은 **실제 ChromaDB PersistentClient로 테스트**해야 합니다. mock은 중복 ID 거부를 구현하지 않아 심각한 버그를 감춥니다.

### 왜 mock으로 테스트하면 안 되는가

JOB-1209에서 2,700+ chunk가 `Expected IDs to be unique` 에러로 실패했습니다. mock ChromaDB는 중복 ID를 허용했기 때문에 테스트는 통과했지만 실제 환경에서 대량으로 실패했습니다.

```python
# ❌ mock 테스트 — 중복 ID 버그 감출 수 있음
class MockCollection:
    def add(self, ids, documents, **kwargs):
        # 중복 체크 없이 저장 → 테스트 통과하지만 실제 ChromaDB는 실패
        self.data[ids] = documents

# ✅ 실제 ChromaDB로 테스트 — 중복 ID 에러를 실제 감지
def test_chromadb_upsert_deduplicates(tmp_path):
    """실제 ChromaDB에서 upsert가 중복 ID를 덮어씌우는지 확인."""
    import chromadb
    client = chromadb.PersistentClient(path=str(tmp_path))
    col = client.get_or_create_collection(
        name="test_upsert",
        metadata={"hnsw:space": "cosine"},
    )
    col.upsert(ids=["func1"], documents=["original"], embeddings=[[0.1, 0.2]])
    col.upsert(ids=["func1"], documents=["updated"], embeddings=[[0.3, 0.4]])
    result = col.get(ids=["func1"])
    assert result["documents"][0] == "updated"  # ✅ 실제 동작 검증
```

### 테스트 데이터: "messy real-world" 케이스 포함

테스트 데이터는 "ideally correct"가 아닌 **실제 환경의 messy 케이스**를 포함해야 합니다:

| 테스트 케이스 | 왜 필요한가 |
|--------------|-------------|
| 동일 파일 내 중복 함수명 | Tree-sitter가 선언+정의 모두 추출 |
| inline 함수/매크로 | 헤더 파일 포함 시 중복 정의 |
| `#ifdef` 블록 | 같은 함수가 여러 번 등장 |
| 50줄 초과 대용량 함수 | 계층적 블록 분할 검증 |

```python
def test_chunker_dedup_same_function_name():
    """동일 파일에서 같은 이름 함수가 여러 번 추출될 때 중복 제거."""
    from src.chunking.chunker import Chunker

    # 같은 함수 이름이 3번 등장하는 가짜 심볼
    symbols = [
        _make_symbol("my_func", "function", line_start=1, line_end=10),
        _make_symbol("my_func", "function", line_start=20, line_end=30),  # 중복
        _make_symbol("other_func", "function", line_start=40, line_end=50),
    ]

    source = "\n".join([f"line{i}" for i in range(1, 60)])
    chunker = Chunker()
    chunks = chunker.chunk_from_symbols(symbols, source, "/test/dup.c")

    my_func_chunks = [c for c in chunks if "my_func" in c.chunk_id]
    assert len(my_func_chunks) == 1, f"중복 제거 실패: {len(my_func_chunks)}개 반환"
```

### mock 테스트의 맹점

mock 테스트는 **runtime 의존성 누락**을 감출 수 있습니다:

| mock이 감추는 문제 | 실제 환경에서 |
|-------------------|---------------|
| onnxruntime 누락 | ChromaDB 내부 임베딩 실패 |
| tree-sitter grammar 누락 | 파싱 실패 |
| API endpoint 변경 | mock은 통과, 실제 호출 실패 |

**해결**: 핵심 파이프라인(integration) 테스트는 실제 의존성으로 실행. mock은 LLM 비용이 발생하는 부분(OpenAI API)에만 제한적 사용.

```python
# ✅ LLM 호출 mock — token 비용 방지하되 실제 파이프라인 흐름 검증
from src.llm.description_generator import MockOpenAIClient

mock = MockOpenAIClient(responses=[["initializes scheduler", "handles interrupts"]])
descriptions = generate_descriptions(mock, "gpt-4o-mini", "schedule", blocks)
assert len(descriptions) == 2  # 실제 파이프라인 흐름 검증

# ❌ ChromaDB mock — 중복 ID 버그 감춤
# mock_chroma = MockChroma()  # 절대 금지
```

## 테스트 커버리지 체크리스트

GraphRAG 프로젝트 테스트 시 다음 항목을 반드시 포함:

- [ ] Import 테스트 (모듈 전체)
- [ ] API 시그니처 검증 (CLI ↔ 모듈)
- [ ] **실제 ChromaDB** upsert/duplicate 테스트
- [ ] **중복 심볼** chunking 테스트
- [ ] 계층적 Chunking (50줄 초과 → 블록 분할)
- [ ] 체크포인트 증분 업데이트
- [ ] intent 가중치 합 = 1.0 검증
- [ ] 한국어/다국어 질문 처리
- [ ] 빈 검색 결과 + fallback
- [ ] **빌드된 실행파일**로 E2E 테스트
