# 📋 명령어 레퍼런스

> 자주 사용하는 Hermes 명령어를 표 형식으로 정리했습니다.

---


## 한 줄 요약



## 기본 개념



## 문제 상황



## 기술 설계



## 구조/흐름도



## 활용 예시


## 슬래시 명령어

| 명령어 | 설명 | 사용 예 |
|--------|------|---------|
| `/model` | 현재 모델 확인 또는 변경 | `/model`, `/model gpt-4` |
| `/reset` | 세션 컨텍스트 초기화 | `/reset` |
| `/new` | 새 세션 시작 | `/new` |
| `/skills` | 스킬 목록 보기 | `/skills`, `/skills load deploy` |
| `/sessions` | 세션 목록/검색 | `/sessions`, `/sessions search "API"` |
| `/help` | 도움말 | `/help` |
| `/kanban` | Kanban 보드 관리 | `/kanban`, `/kanban add Task` |

---

## Knowledge 명령어

| 명령어 | 설명 | 사용 예 |
|--------|------|---------|
| `knowledge add` | Knowledge 저장 | `knowledge add "내용" --tags 태그` |
| `knowledge search` | Knowledge 검색 | `knowledge search "키워드"` |
| `knowledge list` | Knowledge 목록 | `knowledge list --days 7` |
| `knowledge delete` | Knowledge 삭제 | `knowledge delete <id>` |
| `knowledge merge` | Knowledge 병합 | `knowledge merge <id1> <id2>` |

---

## JOB 명령어

| 명령어 | 설명 | 사용 예 |
|--------|------|---------|
| `JOB으로 만들어줘` | 작업을 JOB으로 등록 | `JOB으로 만들어줘: README 작성` |
| `/jobs` | JOB 목록 보기 | `/jobs` |
| `/jobs open` | JOB 상세 보기 | `/jobs open JOB-1234` |

---

## 도구 명령어

| 명령어 | 설명 | 사용 예 |
|--------|------|---------|
| `hermes tools list` | 도구 목록 보기 | `hermes tools list` |
| `hermes tools enable` | 도구 활성화 | `hermes tools enable browser` |
| `hermes tools disable` | 도구 비활성화 | `hermes tools disable delegate_task` |

---

## 시스템 명령어

| 명령어 | 설명 | 사용 예 |
|--------|------|---------|
| `hermes config` | 설정 보기/변경 | `hermes config show` |
| `hermes backup` | 시스템 백업 | `hermes backup` |
| `hermes cleanup` | 시스템 정리 | `hermes cleanup --days 90` |
| `hermes setup` | 초기 설정 | `hermes setup` |

---

## 세션 검색 명령어

| 명령어 | 설명 | 사용 예 |
|--------|------|---------|
| `session_search()` | 과거 세션 검색 | `session_search("키워드")` |
| `/sessions search` | 세션 검색 (CLI) | `/sessions search "배포"` |

---

## 크론 명령어

| 명령어 | 설명 | 사용 예 |
|--------|------|---------|
| `cronjob` | 크론 작업 생성 | `cronjob create --every 1h --prompt "..."` |
| `cronjob list` | 크론 작업 목록 | `cronjob list` |
| `cronjob remove` | 크론 작업 삭제 | `cronjob remove <id>` |

---

## 단축 참고

```
┌─────────────────────────────────────────┐
│  /model     → 모델 변경                 │
│  /reset     → 컨텍스트 초기화           │
│  /new       → 새 세션                   │
│  /skills    → 스킬 관리                 │
│  /sessions  → 세션 관리                 │
│  JOB:       → 작업 등록                 │
│  knowledge  → 지식 관리                 │
│  cronjob    → 예약 작업                 │
└─────────────────────────────────────────┘
```

> **💡 Tip**: 이 레퍼런스는 자주 사용하는 명령어만 모았습니다. 전체 명령어는 `/help` 또는 공식 문서를 참조하세요.
