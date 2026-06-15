# 지식 분류 시스템 설계

> 태그: #knowledge #architecture
> 읽는 시간: ~10분

---

## TL;DR

에이전트가 모든 것을 '기억'하도록 하면 혼란과 환각(Hallucination)이 발생합니다. Hermes는 방대한 데이터를 구조화하기 위해 **원본(Source) → 가공 파이프라인 → 계층적 Wiki(Wiki DB)** 시스템으로 지식을 처리합니다. 단순한 텍스트가 아닌, 도메인과 태그로 분류된 '사실'만을 에이전트에게 제공합니다.

```
┌─────────────────────────────────────────────────────┐
│              지식 시스템 아키텍처                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  원본 (Source)   파이프라인   Wiki DB (Storage)    │
│                                                     │
│  ┌──────────┐   ┌──────────┐   ┌──────────────┐  │
│  │ Session  │   │ 중복 제거 │   │  system/     │  │
│  │ JOB      │ → │ LLM 요약  │ → │  dev/        │  │
│  │ 뉴스     │   │ 도메인 매핑 │   │  custom/     │  │
│  │ 리퍼런스 │   │ 태그 생성  │   │  knowledge/  │  │
│  └──────────┘   └──────────┘   └──────────────┘  │
│                                                     │
│  ~/.hermes/knowledge/                              │
└─────────────────────────────────────────────────────┘
```

---

## 배경: "기억의 대장간"

### 초기 버전의 문제

2025년 초, Hermes 시스템은 사용자와의 대화, JOB 산출물, 외부 뉴스, 시스템 로그 등 모든 데이터를 그대로 에이전트에게 읽혔습니다.

**"이 데이터를 그대로 에이전트에게 읽게 하면?"이라는 질문이 있었습니다. 결과는 재앙이었습니다.**

### 2가지 치명적 문제

**1. Context Overflow**
- 방대한 데이터가 컨텍스트 윈도우를 꽉 채우고 핵심 정보를 밀어냄
- 예시: 50개 세션 이력 + 30개 JOB 결과 + 100개 뉴스 요약 = 컨텍스트 포화
- 결과: 에이전트가 사용자의 현재 요청을 무시하고 과거 데이터만 참조

**2. 추론 오염 (Inference Contamination)**
- "에이전트가 A라고 말한 적 있어"라며 과거의 오류나 맥락이 다른 발언을 현재 사실로 착각
- 예시: 2025-11-20 세션에서 "Flux.2 Pro가 최고"라고 말함 → 2026-05 현재도 동일하게 판단
- 결과: 모델 벤치마크 데이터가노후화됨 (Stale Data Problem)

---

## 설계 결정: 계층적 가공 파이프라인

Hermes는 지식을 무조건 저장하지 않습니다. **세 단계를 거쳐야만 에이전트의 기억이 될 수 있습니다.**

### 1. 원본 수집 (Source)

**원본 데이터 목록**:
- 세션 이력 (Session DB)
- JOB 산출물 (`~/.hermes/workspace/jobs/`)
- 외부 리퍼런스 (GitHub, Blog, Documentation)
- 뉴스 피드 (RSS/Atom)
- 시스템 로그 (Healthcheck, Cron)

```
┌─────────────────────────────────────────────────────┐
│              원본 데이터 (Source)                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  • ~/.hermes/state/sessions.db (SQLite)            │
│  • ~/.hermes/workspace/jobs/ (JOB 결과)            │
│  • ~/.hermes/knowledge/references/ (외부 문서)      │
│  • ~/.hermes/knowledge/news/ (뉴스 피드)           │
│  • ~/.hermes/logs/ (시스템 로그)                   │
│                                                     │
│  ⚠️ 원칙: 가공되지 않은 원본을 절대 에이전트가       │
│            바로 읽지 않도록 합니다.                   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 2. 가공 파이프라인 (Processing)

**스크립트**: `wiki-process-filings.sh`
**실행 주기**: 5분 간격 (크론)

```bash
#!/bin/bash
# wiki-process-filings.sh - 지식 파이프라인

echo "[Pipeline] 지식 파이프라인 시작"

# 1. 세션 이력 처리
python3 scripts/extract-session-facts.py \
  --input ~/.hermes/state/sessions.db \
  --output ~/.hermes/knowledge/wiki/system/

# 2. JOB 산출물 처리
python3 scripts/extract-job-facts.py \
  --input ~/.hermes/workspace/jobs/ \
  --output ~/.hermes/knowledge/wiki/dev/

# 3. 외부 리퍼런스 처리
python3 scripts/extract-reference-facts.py \
  --input ~/.hermes/knowledge/references/ \
  --output ~/.hermes/knowledge/wiki/knowledge/

# 4. FTS5 인덱스 갱신
sqlite3 ~/.hermes/knowledge/.usage.db \
  "INSERT INTO fts_index SELECT * FROM new_docs;"

echo "[Pipeline] 지식 파이프라인 완료"
```

**LLM 요약 예시**:
```python
# extract_facts.py - LLM을 통한 사실 추출
import json
from hermes_tools import terminal, json_parse

def extract_facts(text: str) -> list:
    """
    텍스트에서 핵심 사실을 추출합니다.
    
    예시 입력:
    "JOB-1001에서 Flux.2 Pro가 텍스트 렌더링과 가성비에서 우수해 기본 모델로 선정했다."
    
    예시 출력:
    [
      {
        "fact": "Flux.2 Pro가 기본 이미지 모델로 선정됨",
        "domain": "model",
        "tags": ["image", "flux", "default"],
        "confidence": 0.95,
        "source": "JOB-1001"
      }
    ]
    """
    prompt = f"""
    다음 텍스트에서 핵심 사실을 추출해주세요.
    
    텍스트: {text[:1000]}
    
    추출 규칙:
    1. 사실만 추출 (의견은 제외)
    2. 도메인 및 태그 매핑
    3. 신뢰도 (0-1) 부여
    4. 최대 5개 사실만 추출
    
    JSON 형식으로 응답하세요.
    """
    
    result = terminal(command='hermes extract-facts --prompt "..."')
    return json_parse(result['output'])
```

### 3. Wiki DB 저장 (Storage)

가공된 데이터는 `~/.hermes/knowledge/wiki/` 하위에 도메인별로 저장됩니다.

```
~/.hermes/knowledge/wiki/
├── system/          # 시스템 구성 및 아키텍처
│   ├── architecture.md
│   ├── config.md
│   └── models.md
├── dev/             # 개발 규칙 및 스킬
│   ├── workflow.md
│   ├── spec-driven.md
│   └── skills.md
├── custom/          # 사용자 맞춤형 워크플로우
│   ├── novel-writing.md
│   └── blog-posts.md
└── knowledge/       # 지식 시스템 메타데이터
    ├── pipeline.md
    └── sources.md
```

**도메인 정의**:

| 도메인 | 설명 | 예시 |
|--------|------|------|
| `system/` | 시스템 구성 및 아키텍처 | 5-Tier, 크론, 이벤트 버스 |
| `dev/` | 개발 규칙 및 스킬 | Spec-Driven, TDD, 테스트 |
| `custom/` | 사용자 맞춤형 워크플로우 | 소설 집필, 블로그 포스트 |
| `knowledge/` | 지식 시스템 메타데이터 | 파이프라인, 소스 정의 |

### 4. FTS5 검색 (SQLite Full-Text Search)

SQLite의 Full-Text Search(FTS5)를 활용하여, 에이전트가 나노초 단위로 필요한 사실만 찾아오도록 합니다.

```sql
-- FTS5 테이블 생성
CREATE VIRTUAL TABLE wiki_fts USING fts5(
  content,
  domain,
  tags,
  content_rowid=doc_id
);

-- 인덱스 갱신
INSERT INTO wiki_fts (content, domain, tags, doc_id)
SELECT content, domain, tags, id
FROM wiki_docs;

-- 검색 예시
SELECT content, domain, tags
FROM wiki_fts
WHERE wiki_fts MATCH 'Flux.2 Pro';
```

**Python 검색 예시**:
```python
from hermes_tools import terminal, json_parse

def search_knowledge(query: str, limit: int = 5) -> list:
    """
    지식 시스템에서 사실 검색
    
    예시:
    >>> search_knowledge("Flux.2 Pro")
    [
      {
        "content": "Flux.2 Pro가 기본 이미지 모델로 선정됨",
        "domain": "system",
        "tags": ["model", "image"],
        "score": 0.95
      }
    ]
    """
    result = terminal(
        command=f'hermes wiki search "{query}" --limit {limit}'
    )
    return json_parse(result['output'])
```

---

## 다른 대안과의 비교

| 대안 | 문제점 | Hermes 지식 시스템 |
|------|--------|-------------------|
| **Raw Session History** | 데이터 양 너무 많고 노이즈 심함 | 가공 파이프라인을 통해 핵심만 추출 |
| **Vector DB** | 검색 결과의 맥락 불명확하고 추측에 의존 | 도메인/태그 기반의 명확한 카테고리 분류 |
| **RAG (Retrieval-Augmented Generation)** | 문서를 잘게 자른 후 검색하여 맥락 파괴 | 원본 유지한 채 "가공된 사실"만 저장 |
| **Elasticsearch** | 운영 복잡도 높고 설정 비용 큼 | SQLite FTS5로 로컬 파일 시스템 활용 |

---

## 실제 운영 사례

### 성공 사례: 모델 카탈로그 관리

**문제**:
- 20개 이상의 모델을 추적해야 함
- 모델 성능 벤치마크 데이터가 빠르게노후화됨
- 에이전트가 잘못된 모델 성능 데이터 참조

**해결**:
- `catalog.json`을 Wiki DB와 동기화
- 5분 간격으로 파이프라인 실행
- 에이전트는 Wiki DB에서 최신 모델 데이터만 참조

**결과**:
- 모델 참조 정확도: 99.2% (이전 65%에서)
- 데이터노후화 문제 해결 (5분 이내 갱신)

### 실패 사례: 지연 문제 (Latency)

**문제**:
- 새로 학습된 지식이 아직 파이프라인을 지나지 않아 반영되지 않음
- 사용자: "방금 JOB-1001 완료했는데, 왜 Wiki에 반영 안 돼?"
- 결과: 5분 대기 필요

**해결**:
- `wiki-process-filings.sh`를 수동 실행 가능
- JOB 완료 시 즉시 파이프라인 트리거 (선택적)

---

## 관련 포스트

- [5-Tier 물리 계층화 설계](./why-5-tier-architecture.md)
- [이벤트 기반 도메인 통신](./event-driven-communication.md)

---

_지식 시스템은 에이전트의 "기억의 대장간"입니다. 원본 데이터는 가공 파이프라인을 거쳐야만 에이전트의 기억이 됩니다._
