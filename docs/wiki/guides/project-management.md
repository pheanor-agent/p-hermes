# 개인 프로젝트 생성 및 관리 가이드

> 태그: #project #management
> 읽는 시간: ~10분

---

## TL;DR

Hermes는 개인 프로젝트를 체계적으로 관리하기 위해 **메타데이터와 코드를 분리**한 프로젝트 시스템을 제공합니다. `create-project.sh` 스크립트로 프로젝트를 생성하고, 프로젝트 폴더 구조와 아카이빙 기능을 활용하여 프로젝트를 관리합니다.

```
┌─────────────────────────────────────────────────────┐
│              프로젝트 관리 아키텍처                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  메타데이터         코드                             │
│  (Metadata)        (Code)                           │
│                                                     │
│  ~/.hermes/       ~/.shared/code/                   │
│  workspace/       <slug>/                           │
│  projects/        ├── src/                          │
│  <slug>/          ├── data/                         │
│  ├── project.yaml ├── docs/                         │
│  ├── timeline.md  └── tests/                        │
│  └── README.md                                │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 배경: "프로젝트 관리의 필요성"

### 문제 정의

2025년 초, Hermes 시스템은 작업을 관리하지만 프로젝트를 체계적으로 관리하지는 않았습니다.

**문제**:
- 작업 폴더가 혼재됨 (JOB 폴더와 프로젝트 폴더 구분 불가)
- 프로젝트별 메타데이터 부재 (시작일, 상태, 산출물)
- 프로젝트 아카이빙 부재 (완료된 프로젝트 정리 필요)

---

## 프로젝트 생성

### 1. create-project.sh 사용

```bash
# 프로젝트 생성
bash create-project.sh kernel-chat "Kernel Chat" --job-id JOB-1001

# 또는 승인된 프로젝트
bash create-project.sh kernel-chat "Kernel Chat" --approved-by "사용자명"
```

**스크립트 동작 흐름**:
```
1. 메타데이터 폴더 생성 (~/.hermes/workspace/projects/<slug>/)
2. 코드 폴더 생성 (~/.shared/code/<slug>/)
3. project.yaml 생성
4. timeline.md 생성
5. README.md 생성
6. Git 초기화 (선택)
```

### 2. project.yaml 구조

```yaml
# project.yaml
slug: kernel-chat
name: Kernel Chat
description: 커널과 대화하는 AI 프로젝트
status: active
created_at: "2026-06-15"
updated_at: "2026-06-15"
code_path: ~/.shared/code/kernel-chat
repository: https://github.com/pheanor-agent/kernel-chat
job_ids:
  - JOB-1001
  - JOB-1002
tags:
  - ai
  - kernel
  - chat
```

---

## 프로젝트 구조

### 메타데이터 폴더

```
~/.hermes/workspace/projects/
└── <slug>/
    ├── project.yaml       # 프로젝트 메타데이터
    ├── timeline.md        # 타임라인 (작업 이력)
    ├── README.md          # 프로젝트 개요
    └── .git/              # Git 버전 관리
```

### 코드 폴더

```
~/.shared/code/
└── <slug>/
    ├── src/               # 소스 코드
    ├── data/              # 데이터
    ├── docs/              # 문서
    └── tests/             # 테스트
```

**핵심 원칙**: 메타데이터와 코드 분리
- 메타데이터: 프로젝트 정보, 타임라인, 설정
- 코드: 실제 소스 코드, 데이터, 테스트

---

## 프로젝트 관리

### 상태 변경

```bash
# 프로젝트 상태 변경
# project.yaml의 status 필드 수정
sed -i 's/^status: active/status: archived/' project.yaml
```

**상태 목록**:
- `active`: 진행 중
- `paused`: 일시 중단
- `archived`: 아카이빙

### 타임라인 갱신

```markdown
# timeline.md

## 2026-06-15

- [JOB-1001] 프로젝트 생성
- [JOB-1002] 기본 구조 설정

## 2026-06-14

- [JOB-1000] 초기 조사
```

---

## 프로젝트 아카이빙

### archive-project.sh 사용

```bash
# 프로젝트 아카이빙
bash archive-project.sh kernel-chat --reason "완료된 프로젝트"
```

**스크립트 동작**:
```
1. project.yaml의 status 필드를 'archived'로 변경
2. timeline.md에 아카이빙 기록 추가
3. Git 푸시 (선택)
```

### 아카이빙 기준

- 프로젝트 완료
- 장기 미사용 (3개월 이상)
- 대체 프로젝트 존재

---

## 실제 예시: kernel-chat 프로젝트

### 1. 프로젝트 생성

```bash
bash create-project.sh kernel-chat "Kernel Chat" --approved-by "pheanor"
```

**생성된 구조**:
```
~/.hermes/workspace/projects/kernel-chat/
├── project.yaml
├── timeline.md
└── README.md

~/.shared/code/kernel-chat/
├── src/
├── data/
├── docs/
└── tests/
```

### 2. 작업 연결

```bash
# JOB 생성 시 --job-id로 프로젝트 연결
bash create-job.sh -y 기능 "새 기능 구현" --project kernel-chat
```

### 3. 프로젝트 완료 및 아카이빙

```bash
# 프로젝트 아카이빙
bash archive-project.sh kernel-chat --reason "프로젝트 완료"
```

---

## 관련 포스트

- [왜 9단계 상태머신인가?](../../blog/posts/why-9-step-workflow.md)
- [이벤트 기반 도메인 통신](../../blog/posts/event-driven-communication.md)

---

_프로젝트 관리 시스템은 메타데이터와 코드를 분리하여 체계적인 프로젝트 관리를 가능하게 합니다._
