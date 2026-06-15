# JOB-1209: 의미적 인덱싱 구현 기록

## 개요
- **날짜**: 2026-05-19
- **목표**: C 코드의 자연어 설명을 LLM으로 생성하여 의미적 검색 가능하게 함
- **결과**: 4-way 검색(G/V/K/S) + 14 intent 가중치 + 2-pass dedup

## 구현 아키텍처

### 계층적 Chunking
```
함수 (tier 2.0)
├── Block 0 (tier 2.1, lines 1-80, parent_chunk_id=func:xxx)
├── Block 1 (tier 2.1, lines 81-150, parent_chunk_id=func:xxx)
└── Block 2 (tier 2.1, lines 151-200, parent_chunk_id=func:xxx)
```

**분할 기준**:
- 50줄 초과 함수만 분할 대상
- 분할점: `/* */` 주석, `//` 주석, `#if/#elif/#else` 전처리기
- 최대 80줄/블록 (8191 토큰 제한 대비)

### LLM 설명 생성 파이프라인
```
함수 소스 → chunk_function_blocks() → [Block 0, Block 1, ...]
    ↓ 배치 (3개)
LLM prompt: "Function: xxx\nBlock 0: ... Block 1: ... Block 2: ..."
    ↓ 응답
["description 0", "description 1", "description 2"]
    ↓
ChromaDB kernel_function_descs 컬렉션 저장
```

**토큰 계산**:
- 3 blocks × ~1,200 tokens = ~3,600 tokens / 8,191 limit ≈ 44%
- 커널 스케줄러 전체: ~1,619 호출 × $0.005 = ~$8.10
- 재시도 포함 시 ~$9.70

### 체크섬 기반 증분 업데이트
```
index-state.json:
{
  "semantic_checksums": {
    "kernel/sched/schedule.c": "abc123..."
  },
  "semantic_descriptions": {
    "kernel/sched/schedule.c:schedule": {
      "checksum": "abc123...",
      "status": "done"
    }
  }
}
```

**처리 흐름**:
1. `get_changed_files()` → MD5 체크섬 비교
2. 변경 파일만 `needs_description()` 확인
3. `generate_descriptions()` → LLM 호출
4. `mark_descriptions_done()` → 체크포인트 업데이트

## 14 Intent 가중치 테이블

| Intent | Graph | Vector | Semantic | 설명 |
|--------|-------|--------|----------|------|
| what_does | 0.3 | 0.2 | 0.5 | 함수 역할 질문 |
| how_to_call | 0.4 | 0.3 | 0.3 | 함수 사용법 |
| what_calls | 0.8 | 0.1 | 0.1 | 호출하는 함수 |
| what_called_by | 0.8 | 0.1 | 0.1 | 호출받는 함수 |
| find_symbol | 0.5 | 0.3 | 0.2 | 심볼 찾기 |
| compare | 0.4 | 0.2 | 0.4 | 함수 비교 |
| debug_trace | 0.6 | 0.2 | 0.2 | 디버깅 추적 |
| general_qa | 0.2 | 0.2 | 0.6 | 일반 질문 |
| +6 legacy | keyword 기반 | | | 기존 유지 |

**검증**: 모든 intent의 가중치 합 = 1.0 (테스트로 검증)

## 2-pass Deduplication

```
Graph: [func:sched:abc123, func:sched:abc123]
Semantic: [desc:sched:abc123]

1차: node_id dedup → [func:sched:abc123, desc:sched:abc123]
2차: symbol_name dedup → [func:sched:abc123 {metadata: {semantic_description: "..."}}]
```

## MockOpenAIClient 구현

```python
class MockOpenAIClient:
    """테스트용 mock — 실제 API 호출 없음"""
    def __init__(self, responses: list[list[str]] | None = None):
        self.responses = responses or []
        self.call_count = 0

    def chat_completions_create(self, **kwargs):
        # client.chat.completions.create() 체인 구조 정확히 모방
        text = json.dumps(self.responses[self.call_count])
        self.call_count += 1
        return type("R", (), {"choices": [MockChoice(text)]})()
```

**핵심**: 실제 OpenAI client의 `client.chat.completions.create()` 메서드 체인 구조를 정확히 따라야 함.

## 발견된 문제

### 1. 서브에이전트 파일 수정 → 스태일 컨텍스트
- `delegate_task`가 완료되면 modified files 목록 확인
- 부모 에이전트가 이미 읽은 파일이 수정됨 → 반드시 재읽기

### 2. LLM 응답 JSON 파싱 실패
- 3단계 폴백: JSON.loads → regex 추출 → 빈 문자열
- 3회 재시도 후 실패 시 빈 설명으로 대체

### 3. tier int→float 변경 호환성
- 기존 `tier: int` → `tier: float`로 변경
- 전체 코드베이스에서 tier 참조하는 곳 검색 + 타입 일치 확인
