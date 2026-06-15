# JOB-1394: 지식 폴더 구조 통합

**완료일**: 2026-05-30
**관련 스킬**: llm-wiki, knowledge-graph-export, workflow

---

## 목표

지식 자체를 줄이지 않고, **관리 방식을 Karpathy 3계층 구조로 재설계**. 중복 제거, 인덱스 통합, 원본 보존.

---

## 설계 철학

### Karpathy 3계층 + 계층적 접근 혼합

1. **Raw vs Wiki 분리**: 원시 데이터 (불변) vs 가공 지식 (LLM 소유) 명확히 구분
2. **Append-only raw**: raw/는 수집만, 수정/삭제 없음 → 진실의 원천 보장
3. **LLM이 소유하는 wiki**: 요약, 개념, 종합은 LLM이 관리 → 검색/질의 최적화
4. **경험적 + 합성 메모리 병행**: clawsouls 실험 결과 요약만 있으면 정보 손실 (2.65점), 원본+요약 조합이 최적 (4.95점)

### 작동 흐름

```
수집        ┌──────────┐    LLM 컴파일     ┌──────┐
───────→   │ raw/     │ ──────────────→   │wiki/ │
(불변)     └──────────┘    (요약/분류/    └──────┘
            ↑              교차참조 추가)    ↑
     원본 참조 ←────────────────────  질의/답변
```

---

## 최종 구조

```
~/.hermes/knowledge/
├── raw/                          # 불변 원시 데이터 (수집만)
│   ├── job-artifacts/            # JOB 산출물 symlink → ~/.hermes/workspace/jobs/
│   ├── sources/                  # OpenClaw 덤프, 웹 스크랩, API 로깅
│   └── references/               # 큐레이션된 리퍼런스
│
├── wiki/                         # LLM이 가공한 지식 (검색/질의용)
│   ├── SCHEMA.md                 # 위키 구조와 규칙
│   ├── index.md                  # master index (카테고리별)
│   ├── log.md                    # 시간순 기록
│   ├── lessons-index.md          # 교훈 통합 인덱스
│   ├── sources-index.json        # 소스 메타데이터 통합
│   ├── graph.json                # wikilinks 그래프
│   ├── concepts/                 # 개념 페이지 (31개)
│   ├── entities/                 # 엔티티 페이지 (61개)
│   ├── comparisons/              # 비교 분석 (on-demand)
│   ├── queries/                  # 저장된 쿼리/결과 (on-demand)
│   ├── syntheses/                # 종합 문서 (on-demand)
│   └── topics/                   # 주제별 인덱스
│
├── archive/                      # 격리된 과거 데이터
│   ├── openclaw-sync/            # wiki-sync → 여기로 이동
│   └── legacy/                   # deprecated 구조
│
└── _scripts/                     # 지식 관리 자동화
    ├── collect.sh                # raw → wiki 컴파일
    ├── lint.sh                   # 건강 검사
    └── index.sh                  # 인덱스 자동 생성
```

---

## 실행 결과

### Before/After

| 항목 | Before | After |
|------|--------|-------|
| wiki/ | 4,089개 | 1,068개 |
| 중복 구조 | wiki-sync(2,820개) | archive/openclaw-sync (격리) |
| lessons | 3군데 분산 | wiki/lessons-index.md (통합) |
| entities | knowledge/(JSON 3,077개) | wiki/entities/(MD 61개) |
| graph | graph.json | wiki/graph.json 통합 |
| cron | sources/index.json | wiki/sources-index.json (연동 완료) |

### 크기

| 폴더 | 파일 수 | 크기 |
|------|---------|------|
| raw/ | 3,123개 | 34.4MB |
| wiki/ | 1,068개 | 10.0MB |
| archive/ | 5,953개 | 42.9MB |
| **총계** | **10,197개** | **82.3MB** |

---

## 크론 연동

- `wiki-collect-sources.sh` → `wiki/sources-index.json` 경로 업데이트
- `graph-export.sh` → `wiki/graph.json` 유지

---

## raw/ vs wiki/ 비교

| | raw/ | wiki/ |
|---|---|---|
| **소유자** | 외부/시스템 | LLM |
| **변경** | ❌ append-only | ✅ CRUD 모두 가능 |
| **내용** | 원본 그대로 | 요약, 개념, 종합 |
| **파일 수** | 많음 (3,000~7,000+) | 적음 (200~500) |
| **용도** | 진실의 원천, 원본 참조 | 검색, 질의, 탐색 |

---

## 교훈

1. **중복은 아카이브로 격리, 삭제 아님**: 데이터 손실 방지
2. **symlink로 원본 참조**: JOB 산출물 이동 금지, symlink로 참조
3. **경험적+합성 메모리 병행**: 요약만 있으면 정보 손실
4. **자동화 스크립트 필수**: collect.sh, lint.sh, index.sh로 유지보수 부하 감소
