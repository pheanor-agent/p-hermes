# Knowledge System

Wiki, References, Lessons, News로 구성된 지식 축적 및 관리 시스템입니다.

---

## Overview

| 항목 | 값 |
|------|-----|
| SSOT | `wiki/index.md` |
| 경로 | `~/.hermes/knowledge/` |
| Wiki 페이지 | 1,094+ |
| References | 210+ |
| 갱신 간격 | 5분 (Wiki), 일일 (News) |

---

## 디렉토리 구조

```
~/.hermes/knowledge/
├── wiki/                     # 가공 지식
│   ├── index.md              # 인덱스 (SSOT)
│   ├── t1/                   # 핵심 지식 (KPL ≥ 0.7)
│   ├── t2/                   # 참고 지식 (KPL 0.4~0.69)
│   └── t3/                   # 보조 지식 (KPL < 0.4)
├── references/               # 외부 원본
│   ├── github/               # GitHub 리포/이슈
│   ├── papers/               # 학술 논문
│   └── guides/               # 공식 가이드
├── lessons/                  # 교훈 (자동 생성)
└── news/                     # 뉴스 (주기 수집)
```

---

## Wiki: T1/T2/T3 분류

### KPL (Knowledge Priority Level)

KPL 점수는 지식 항목의 중요도를 수치화한 것입니다.

| 등급 | KPL 범위 | 설명 | 에이전트 동작 |
|------|----------|------|--------------|
| **T1** | ≥ 0.7 | 핵심 지식 | 모든 작업 시작 시 반드시 로딩 |
| **T2** | 0.4 ~ 0.69 | 참고 지식 | 관련 작업 시 로딩 |
| **T3** | < 0.4 | 보조 지식 | 검색 요청 시만 반환 |

### KPL 점수 계산

`build-scores.sh`가 다음 요소로 점수를 계산합니다:

| 요소 | 가중치 | 설명 |
|------|--------|------|
| 참조 빈도 | 0.3 | 과거 JOB에서 몇 번 참조되었는지 |
| 최근 사용 | 0.2 | 마지막 사용 시점 (시간 가중) |
| 교훈 레벨 | 0.25 | Lessons에서 파생된 지식 |
| 관련성 | 0.25 | 현재 작업과의 토픽 관련성 |

### wiki/index.md 구조

```markdown
# Wiki Index
# 마지막 갱신: 2026-06-13T00:00:00Z
# 총 항목: 1094

## T1 — 핵심 지식 (120개)
- [Hermes 워크플로우 파이프라인](t1/workflow-pipeline.md) — KPL: 0.95
- [모델 라우팅 전략](t1/model-routing.md) — KPL: 0.88
- ...

## T2 — 참고 지식 (450개)
- ...

## T3 — 보조 지식 (524개)
- ...
```

---

## References (외부 원본)

외부 자료를 원본 그대로 저장합니다.

| 소스 | 경로 | 예시 |
|------|------|------|
| GitHub | `references/github/` | 리포 README, 이슈, PR |
| Papers | `references/papers/` | 학술 논문 요약 |
| Guides | `references/guides/` | 공식 문서 링크 |

**특징:**
- 원본 마스킹 없음 (공공 자료 기준)
- 링크 + 로컬 복사본 병기
- 주기적 갱신

---

## Lessons (교훈 시스템)

### 자동 생성 파이프라인

```
JOB 완료
  → on-job-complete.sh
    → 작업 내용 분석
      → 성공 패턴 추출
      → 실패 원인 분석
      → 개선안 도출
    → lessons/JOB-XXXX.md 생성
    → wiki/index.md KPL 업데이트
    → 이벤트 버스: knowledge.indexed
```

### Lessons 파일 구조

```markdown
# JOB-XXXX 교훈

**작업**: ~
**완료일**: 2026-06-13
**단계**: request → done

## 성공 패턴
- ...

## 실패/장애
- ...

## 개선안
- ...

## KPL 영향
- 관련 Wiki 항목 점수 조정
```

---

## News (뉴스 수집)

### 일일 파이프라인

```
daily-knowledge.sh
  → 기술 뉴스 소스 스크랩
  → 관련성 필터링
  → 번역 (필요 시)
  → news/ 디렉토리 저장
  → Wiki 관련 항목 갱신
```

---

## 갱신 파이프라인

### wiki-process-filings.sh (5분 간격)

```
Signal Detector (변경 감지)
  → inbox/ (새 자료 임시 저장)
  → wiki-process-filings.sh
    → 내용 분류
    → T1/T2/T3 등급 할당
    → wiki/ 디렉토리로 이동
    → index.md 업데이트
```

### build-scores.sh (주기적)

```
build-scores.sh
  → 모든 Wiki 항목 스캔
  → KPL 점수 재계산
  → 등급 변경 시 디렉토리 이동 (t1↔t2↔t3)
  → index.md 갱신
```

---

## 참조

- [ARCHITECTURE.md](../ARCHITECTURE.md) — 전체 아키텍처
- [docs/layer2-knowledge-state.md](../layer2-knowledge-state.md) — Layer 2
- [docs/systems/cron.md](cron.md) — 갱신 자동화 (Cron)
