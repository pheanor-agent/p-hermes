# kernel-chat E2E 테스트 패턴

## 테스트 환경 설정

```python
import sys
sys.path.insert(0, "src")
os.environ['PYTHONPATH'] = f"{HOME}/.shared/code/kernel-chat/src:{HOME}/projects/kernel-chat/.venv/lib/python3.11/site-packages"
```

venv Python 사용: `$HOME/projects/kernel-chat/.venv/bin/python3`

## 샘플 데이터 생성

```python
from pathlib import Path
sample_dir = Path("/tmp/kernel-chat-test/kernel/sched")
sample_dir.mkdir(parents=True, exist_ok=True)

# 실제 커널 코드 패턴 모방
sample_c = sample_dir / "schedule.c"
sample_c.write_text("""
struct task_struct { volatile long state; };

void schedule(void) {
    struct task_struct *next = pick_next_task();
    context_switch(next);
}

static void context_switch(struct task_struct *next) { ... }
""")
```

## 테스트 순서

1. **파싱**: `CParser().parse_file()` → 심볼 수 확인
2. **그래프 빌드**: `GraphBuilder.build_from_parse_results()` → 노드/엣지 수
3. **Chunking**: `Chunker().chunk_file()` → Chunk 수 + Tier 분포
4. **검색**: `HybridSearch(graph_db).search()` → 결과 수 + 점수 분포
5. **라우팅**: `QueryRouter(use_llm=False).route()` → 의도/심볼/서브시스템
6. **컨텍스트**: `OpenAIClient._build_context()` → 문자열 길이 + 내용 검증

## 검증 기준

| 단계 | 통과 기준 |
|------|-----------|
| 파싱 | 심볼 ≥ 1개, errors = 0 |
| 그래프 | nodes_added ≥ 심볼 수, edges_added ≥ 0 |
| Chunking | L1+L2+L3 ≥ 심볼 수 + 1 |
| 검색 | 결과 ≥ 1개, score > 0 |
| 라우팅 | intent가 빈 문자열이 아님 |
| 컨텍스트 | 길이 > 0, "검색 결과" 포함 |

## 실패 시 디버깅

```python
# AST 구조 확인
def print_tree(node, indent=0):
    print(f"{'  '*indent}{node.type} {node.text.decode()[:30]}")
    for child in node.children:
        print_tree(child, indent + 1)

# Query 확인
cursor = QueryCursor(query)
for pattern_idx, captures in cursor.matches(root):
    print(f"Pattern {pattern_idx}: {list(captures.keys())}")
```
