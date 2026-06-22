# 🧠 첫 Knowledge 저장하기

> Hermes의 Knowledge 시스템을 처음 사용하는 가이드입니다.
> Knowledge는 에이전트의 장기 기억 — 한 번 저장하면 영원히 기억합니다.

---

## Knowledge란?

Knowledge는 Hermes가 영구적으로 기억하는 정보입니다. 
대화 컨텍스트와 달리, **세션이 끝나도 사라지지 않습니다**.

| 대화 컨텍스트 | Knowledge |
|-------------|-----------|
| 현재 세션에서만 유지 | 영구 보관 |
| 자동 생성 | 명시적 저장 필요 |
| 검색 불가 (스크롤만) | FTS5 검색 가능 |

---

## Knowledge 저장하기

### 기본 명령어

Knowledge는 자연어로 저장할 수 있습니다:

```
knowledge에 저장: 내 API 키는 sk-xxxx 형식이야
```

또는 더 구조화된 형식으로:

```
knowledge add "API 키 형식: sk-로 시작하는 32자리 문자열"
```

### 태그와 함께 저장

Knowledge를 더 쉽게 찾으려면 태그를 추가하세요:

```
knowledge add --tags api,설정 "API 엔드포인트: https://api.example.com/v2"
```

나중에 태그로 검색할 수 있습니다:

```
knowledge search --tags api
```

---

## Knowledge 검색하기

### 기본 검색

```
knowledge search "API 키"
```

FTS5(Full-Text Search) 엔진이 관련 Knowledge를 찾아줍니다.

### 고급 검색 옵션

| 옵션 | 설명 | 예시 |
|------|------|------|
| `--tier` | 계층 필터 (T1/T2/T3) | `--tier T1` |
| `--tags` | 태그 필터 | `--tags api,설정` |
| `--days` | 최근 N일 | `--days 7` |
| `--limit` | 결과 개수 | `--limit 5` |

### 검색 예제

```
# 특정 태그 + 최근 30일
knowledge search "배포 스크립트" --tags deploy --days 30

# T1 계층만 검색 (변하지 않는 사실)
knowledge search "비밀번호 규칙" --tier T1
```

---

## Knowledge 계층 이해하기

Knowledge는 중요도에 따라 3계층(Tier)으로 나뉩니다:

### T1 — Facts (사실)
변하지 않는 정보. 시스템 설정, 규칙, 상수.

```
knowledge add --tier T1 "데이터베이스 포트: 5432"
```

### T2 — Context (맥락)
프로젝트 관련 정보. 아키텍처 결정, 설계 이유.

```
knowledge add --tier T2 "이 프로젝트는 FastAPI를 사용하기로 결정됨 (팀 회의 2025-01-15)"
```

### T3 — Reasoning (추론)
분석 결과, 판단, 평가.

```
knowledge add --tier T3 "기존 API는 응답 시간이 평균 2.3초로, 캐싱 도입이 필요함"
```

---

## Knowledge 활용 시나리오

### 시나리오 1: 개발 환경 설정
```
# 설정 저장
knowledge add "로컬 개발 서버: localhost:8000, PostgreSQL: localhost:5432"

# 다음 세션에서 검색
knowledge search "로컬 개발 서버"
→ "로컬 개발 서버: localhost:8000, PostgreSQL: localhost:5432"
```

### 시나리오 2: 프로젝트 결정 사항
```
# 결정 저장
knowledge add --tier T2 "프로젝트 네이밍 규칙: snake_case 사용"

# 나중에 확인
knowledge search "네이밍 규칙"
→ "프로젝트 네이밍 규칙: snake_case 사용"
```

---

## 🎯 실습: 첫 Knowledge 저장하기

지금 바로 해보세요:

```
1. knowledge add "내 첫 Knowledge: Hermes는 기억하는 AI다"
2. knowledge add --tier T1 "Hermes Agent는 Nous Research가 만들었다"
3. knowledge search "Hermes"
```

검색 결과에 두 Knowledge가 모두 표시된다면 성공입니다!

> **💡 Tip**: Knowledge는 적을수록 좋습니다. 정말 필요한 정보만 저장하세요. 불필요한 Knowledge는 검색 노이즈가 됩니다.
>
> **🔗 다음 읽을거리**: [Core Concepts](../core-concepts.md) — Knowledge 시스템의 이론적 배경 이해하기
