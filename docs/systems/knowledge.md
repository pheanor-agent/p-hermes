# Knowledge System

Wiki, References, Lessons로 구성된 지식 축적 및 관리 시스템입니다.

---

## Overview

| 항목 | 값 |
|------|-----|
| SSOT | `wiki/index.md` |
| 경로 | `~/.hermes/knowledge/` |
| Wiki 페이지 | 92개 파일 |
| References | 210+ |
| 갱신 간격 | 5분 (Wiki), 일일 (News) |

---

## 디렉토리 구조

```
~/.hermes/knowledge/
├── wiki/                     # 가공 지식
│   ├── index.md              # 인덱스 (SSOT)
│   ├── SCHEMA.md             # 스키마 정의
│   ├── domain-*.md           # 도메인별 지식
│   ├── concepts/             # 개념
│   ├── comparisons/          # 비교 분석
│   ├── cross-workspace/      # 교차 워크스페이스
│   ├── daily-synthesis/      # 일일 합성
│   ├── entities/             # 엔티티
│   ├── external/             # 외부 자료
│   └── filings/              # 접수 문서
├── references/               # 외부 원본
│   ├── github/               # GitHub 리포/이슈
│   ├── guides/               # 공식 가이드
│   ├── papers/               # 학술 논문
│   ├── mcp/                  # MCP 자료
│   └── knowledge/            # 지식 관련
├── lessons/                  # 교훈 (자동 생성)
└── news/                     # 뉴스 (주기 수집)
```

---

## Wiki: Domain 기반 분류

Wiki는 **도메인**과 **태그** 기반으로 조직됩니다. T1/T2/T3 계층 구조는 사용되지 않습니다.

### Domain 파일

| Domain | 설명 |
|--------|------|
| `domain-general.md` | 일반/공통 |
| `domain-agent.md` | 에이전트 |
| `domain-workflow.md` | 워크플로우 |
| `domain-knowledge.md` | 지식 |
| `domain-reference.md` | 리퍼런스 |
| `domain-memory.md` | 메모리 |
| `domain-session.md` | 세션 |
| `domain-system.md` | 시스템 |
| `domain-devops.md` | DevOps |
| `domain-github.md` | GitHub |
| `domain-image.md` | 이미지 |
| `domain-novel.md` | 소설 |
| `domain-presentation.md` | 프레젠테이션 |
| `domain-bug.md` | 버그 |
| `domain-bridge', 'system.md` | 브리지 |
| `domain-general', 'workflow.md` | 일반 워크플로우 |
| `domain-system', 'general.md` | 시스템 일반 |
| `domain-workflow', 'system.md` | 워크플로우 시스템 |

### Index 구조

wiki/index.md는 도메인 기반 링크 카드를 제공합니다.

---

## References (외부 원본)

외부 자료를 원본 그대로 저장합니다.

| 소스 | 경로 | 설명 |
|------|------|------|
| GitHub | `references/github/` | 리포 README, 이슈 |
| Guides | `references/guides/` | 공식 문서 |
| Papers | `references/papers/` | 학술 논문 |
| MCP | `references/mcp/` | MCP 관련 |
| Knowledge | `references/knowledge/` | 지식 관리 |

**특징:**
- 원본 그대로 저장 (공공 자료 기준)
- 링크 + 로컬 복사본 병기
- 주기적 갱신 (`github-reference-update.py`, 5일 간격)

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
```

---

## 갱신 파이프라인

### wiki-process-filings.sh (5분 간격)

```
Signal Detector (변경 감지)
  → inbox/ (새 자료 임시 저장)
  → wiki-process-filings.sh
    → 내용 분류
    → 도메인 태그 할당
    → wiki/ 디렉토리로 이동
    → index.md 업데이트
```

---

## 참조

- [시스템 종합](systems/overview.md) — 전체 시스템 현황
- [크론 시스템](systems/cron.md) — 갱신 자동화
- [인덱스](../index.md) — 문서 탐색
