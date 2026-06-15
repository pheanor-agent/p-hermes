# kernel-chat v3 Tree-sitter 마이그레이션 세션 (JOB-1193)

## 세션 요약

2026-05-18, kernel-chat 프로젝트의 tree-sitter 관련 에러를 해결하기 위해 여러 API 변경 사항을 발견하고 수정함.

## 발견된 에러 및 해결

### 에러 1: Parser.set_language() 없음

```
AttributeError: 'tree_sitter.Parser' object has no attribute 'set_language'
```

**원인**: tree-sitter 0.22+에서 Parser 생성자가 language를 인자로 받음

**해결**:
```python
# Before
parser = Parser()
parser.set_language(lang)

# After
parser = Parser(lang)
```

### 에러 2: QueryError - Impossible pattern

```
QueryError: Impossible pattern at row 2, column 9
```

**원인**: tree-sitter-c 0.22+에서 쿼리 필드명 매칭 방식 변경

**해결**: `name: (identifier)` → `(identifier)` (위치 기반 매칭)

### 에러 3: Query.matches() 없음

```
AttributeError: 'tree_sitter.Query' object has no attribute 'matches'
```

**원인**: 0.22+에서 query.matches() 제거, QueryCursor 사용해야 함

**해결**:
```python
# Before
captures = query.matches(node)

# After
captures = list(QueryCursor(query).matches(node))
```

### 에러 4: 캡처 값이 리스트

```
AttributeError: 'list' object has no attribute 'text'
```

**원인**: QueryCursor.matches()는 캡처 값을 리스트로 반환

**해결**: `captures["name"][0]` 또는 헬퍼 함수 사용

### 에러 5: macro_definition 노드 없음

```
QueryError: Invalid node type at row 0, column 10: macro_definition
```

**원인**: tree-sitter-c에서 매크로 노드명이 `preproc_def`로 변경

**해결**: `macro_definition` → `preproc_def`, `body: (_)` → `(preproc_arg)`

## 수정된 파일

- `src/parser/c_parser.py`: Parser 초기화, 쿼리, _extract_* 메서드 전체 수정
- `src/cli.py`: import 경로 수정, Rich 이모지 패턴 수정, index 명령어 API 맞춘 것

## 교훈

1. tree-sitter 버전 확인 필수: `pip list | grep tree-sitter`
2. AST 구조 확인: `print_tree(root)` 함수로 실제 구조 확인 후 쿼리 작성
3. QueryCursor는 한번만 사용 가능 - 여러 번 반복하려면 새 커서 생성
4. Rich 이모지는 항상 마크업 태그와 분리

## 관련 링크

- https://github.com/tree-sitter/py-tree-sitter/releases
- https://tree-sitter.github.io/tree-sitter/using-parsers
