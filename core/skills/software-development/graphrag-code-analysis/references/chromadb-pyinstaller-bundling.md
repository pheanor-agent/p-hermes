# ChromaDB + PyInstaller 번들링 문제 해결 (JOB-1209)

## 문제 발현 경로

1. JOB-1209 의미적 인덱싱 구현 완료 → 단위 테스트 61/61 통과
2. 사용자 실제 커널 소스에서 `kernel-chat index --subsystem sched` 실행
3. **중복 ID 에러 발생**: `Expected IDs to be unique, found duplicates of: func:task_group_is_autogroup:2778fbdf`
4. → 해결: chunker dedup + `add()` → `upsert()` 변경
5. 다시 실행 → **onnxruntime 에러**: `The onnxruntime python package is not installed`
6. → 시도 1: `--collect-all onnxruntime` 추가 → 실패
7. 다시 실행 → **tokenizers 에러**: `The tokenizers python package is not installed`
8. → 시도 2: `--collect-all tokenizers` + `pyproject.toml` 의존성 추가 → 실패
9. → **근본 원인 발견**: ChromaDB `get_or_create_collection()`이 디폴트 임베딩 함수 초기화
10. → 해결: `embedding_function=None` — 완전 성공 ✅

## 수정 내역 (총 7개 커밋)

| 커밋 | 내용 |
|------|------|
| `2df8ca5` | feat: semantic indexing (JOB-1209) |
| `0b24183` | fix: duplicate chunk IDs and upsert |
| `eef3a20` | docs: update deployment docs |
| `68416b7` | fix: add onnxruntime to PyInstaller bundle |
| `320774b` | fix: ensure onnxruntime in venv |
| `053ff37` | fix: comprehensive ChromaDB dependency bundling |
| `27a8b12` | fix: disable ChromaDB default embedding (근본 해결) |

## 근본 해결책

```python
import chromadb

client = chromadb.PersistentClient(path="data/")

# ✅ embedding_function=None 필수
col = client.get_or_create_collection(
    name="kernel_functions",
    metadata={"hnsw:space": "cosine"},
    embedding_function=None,  # ← ChromaDB 디폴트 임베딩 완전 차단
)
```

## PyInstaller --collect-all 한계

PyInstaller의 `--collect-all` 플래그는 패키지의 **정적 의존성**만 탐지합니다.
ChromaDB는 다음과 같은 lazy import 패턴을 사용하므로 `--collect-all`이 효과를 못 봄:

1. 컬렉션 생성 시 `DefaultEmbeddingFunction` 클래스 인스턴스화
2. 이 함수가 내부적으로 `onnxruntime`, `tokenizers`, `huggingface-hub` lazy import
3. PyInstaller는 런타임 import를 정적 분석으로 잡아낼 수 없음

**해결책**: ChromaDB 측면에서 `embedding_function=None`으로 디폴트 동작 완전 비활성화.

## 테스트 보강 (30 → 61개)

- `test_chromadb_upsert_deduplicates`: 실제 ChromaDB로 upsert 동작 검증
- `test_chromadb_add_rejects_duplicates_in_batch`: add() 중복 거부 동작 문서화
- `test_chunker_dedup_same_function_name`: 중복 함수명 chunk 제거
- `test_chunker_dedup_same_symbol_name`: 중복 struct/변수 chunk 제거
- 기존 mock 테스트 → 실제 ChromaDB PersistentClient 테스트로 변경

## 교훈

1. **외부 라이브러리 디폴트 동작**: 불필요한 의존성을 유발하면 명시적 비활성화
2. **PyInstaller --collect-all 한계**: 보장되지 않음, 근본 해결책은 라이브러리 설정 변경
3. **실제 데이터 E2E 테스트**: 샘플 데이터로는 발견 불가능한 버그 다수
4. **ChromaDB upsert()**: 재인덱싱 시 항상 upsert() 사용, add()는 중복 ID 거부
5. **ChromaDB metadata**: 빈 리스트/딕트 금지, 미리 필터링 필수
