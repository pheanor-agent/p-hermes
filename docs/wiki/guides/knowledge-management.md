# 📚 지식 관리 전체 워크플로우

> Knowledge의 저장, 검색, 동기화까지 전체 라이프사이클을 다룹니다.
> Hermes의 장기 기억 시스템을 효과적으로 운영하는 방법.

---

## Knowledge Lifecycle

Knowledge는 다음 5단계를 거칩니다:

```
수집 → 저장 → 검색 → 활용 → 동기화/백업
```

---

## 1. 수집 (Collection)

### 자동 수집
Hermes는 작업 중 생성된 산출물을 자동으로 수집합니다:
- JOB 산출물 (조사 보고서, 설계 문서, 테스트 결과)
- 대화 내용 (세션 DB)
- 도구 실행 결과

### 명시적 수집
사용자가 직접 Knowledge로 저장합니다:
```
# 코드 조각 저장
knowledge add "JWT 토큰 검증 코드는 auth/utils.py 참조"

# 의사 결정 저장
knowledge add --tier T2 "데이터베이스는 PostgreSQL 16 사용 결정 (2025-01-15)"
```

---

## 2. 저장 (Storage)

### 계층별 저장 전략

| 계층 | 저장 기준 | 예시 |
|------|----------|------|
| **T1 (Facts)** | 절대 변하지 않는 정보 | API 엔드포인트, 포트 번호, 규칙 |
| **T2 (Context)** | 프로젝트 맥락 | 아키텍처 결정, 설계 이유 |
| **T3 (Reasoning)** | 분석/판단 결과 | 성능 분석, 코드 리뷰 결과 |

### 저장 형식

```yaml
# 권장 형식
knowledge add --tier T1 --tags database,config \
  "데이터베이스 연결: postgresql://localhost:5432/hermes"
```

---

## 3. 검색 (Search)

### 기본 검색
```
knowledge search "데이터베이스 설정"
```

### 고급 검색 전략

| 전략 | 명령어 | 효과 |
|------|--------|------|
| 키워드 검색 | `knowledge search "API 키"` | 가장 빠름 |
| 태그 필터 | `knowledge search --tags api` | 정확도 향상 |
| 계층 필터 | `knowledge search --tier T1` | 신뢰도 향상 |
| 시간 필터 | `knowledge search --days 30` | 최신 정보 우선 |

---

## 4. 활용 (Utilization)

### Knowledge가 사용되는 곳

1. **작업 수행 중**
   - 현재 작업과 관련된 Knowledge 자동 검색
   - 과거 유사 작업의 결과 참조

2. **코드 생성 시**
   - 프로젝트 컨벤션 Knowledge 적용
   - API 사용법 Knowledge 참조

3. **의사 결정 시**
   - 과거 결정 사항 검토
   - 유사 상황의 결과 분석

### Knowledge 우선순위

Hermes는 Knowledge 검색 결과를 다음과 같이 우선순위화합니다:

```
1. T1 (Facts) > T2 (Context) > T3 (Reasoning)
2. 최근 저장된 Knowledge 우선
3. 태그 일치도 높은 Knowledge 우선
```

---

## 5. 동기화 및 백업

### 동기화
Knowledge는 여러 저장소에 분산될 수 있습니다:

```
# 로컬 Knowledge 동기화
hermes knowledge sync

# 원격 저장소와 동기화 (설정 시)
hermes knowledge sync --remote
```

### 백업
```
# 전체 Knowledge 백업
hermes backup --knowledge

# 특정 계층만 백업
hermes backup --knowledge --tier T1
```

---

## Knowledge 관리 모범 사례

### ✅ 좋은 Knowledge

```
knowledge add --tier T1 "Redis 캐시 TTL: 3600초 (1시간)"
→ 구체적이고, 변하지 않으며, 검색하기 쉬움
```

```
knowledge add --tier T2 "API 버전 2는 요청 본문에 version 필드 추가"
→ 프로젝트 맥락을 명확히 설명
```

### ❌ 나쁜 Knowledge

```
knowledge add "오늘 날씨가 좋다"
→ 일시적이고, 재사용 가치가 낮음
```

```
knowledge add "코드가 좀 느리다"
→ 모호하고, 구체적인 데이터가 없음
```

---

## Knowledge 정리 전략

### 정기적 검토
```
# 90일 이상 된 Knowledge 검토
knowledge list --older-than 90

# 사용 빈도가 낮은 Knowledge 확인
knowledge list --unused
```

### 중복 제거
```
# 중복 Knowledge 검색
knowledge search --dedup

# 중복 제거 및 병합
knowledge merge <id1> <id2>
```

---

## 실전 워크플로우

### 일일 Knowledge 관리 루틴

```
1. 아침: 어제 저장된 Knowledge 검토
   knowledge list --days 1

2. 작업 중: 중요한 결정 Knowledge 저장
   knowledge add --tier T2 "..."

3. 저녁: 오늘의 Knowledge 정리
   knowledge list --days 1 --unorganized
```

### 프로젝트 종료 시
```
1. 프로젝트 Knowledge 백업
2. 중요 Knowledge 승격 (T3 → T1/T2)
3. 불필요 Knowledge 정리
4. 최종 아카이브
```

> **💡 Tip**: Knowledge는 많을수록 좋지 않습니다. 정말 가치 있고 재사용 가능한 정보만 저장하세요. Knowledge의 질이 양보다 중요합니다.
>
> **🔗 더 알아보기**: [Memory 시스템](memory-system.md) — Knowledge와 Memory의 차이 이해하기
