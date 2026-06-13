# Skill System

Hermes Agent의 스킬 시스템은 144개 이상의 스킬을 30개 이상 카테고리로 분류하여 관리합니다.

---

## Overview

| 항목 | 수 |
|------|-----|
| 총 스킬 | 146 |
| 카테고리 | 31 |
| Custom 스킬 | 사용자 정의 |
| 트리거 기반 자동 로딩 | ✅ |
| 계층적 상속 | ✅ |

---

## 디렉토리 구조

```
~/.hermes/skills/
├── custom/                      # 사용자 정의 (최우선)
│   ├── model-catalog/
│   │   ├── SKILL.md
│   │   └── catalog.json
│   ├── expression-system/
│   │   ├── SKILL.md
│   │   └── ...
│   └── ...
├── software-development/
│   ├── git/
│   │   └── SKILL.md
│   ├── deploy/
│   │   └── SKILL.md
│   └── ...
├── creative/
│   ├── ascii-art/
│   │   └── SKILL.md
│   └── ...
├── research/
│   └── ...
├── writing/
│   └── ...
├── system-common/
│   └── lib/
│       └── event.sh             # 이벤트 버스 라이브러리
└── ... (30+ categories)
```

---

## 스킬 로딩 순서

스킬은 우선순위 계층에 따라 로딩됩니다:

```
1. custom/          (사용자 정의, 최우선)
2. 작업 카테고리/    (software-development/, creative/ 등)
3. system-common/    (공통 유틸리티)
4. default/          (기본 스킬)
```

**동일 카테고리 충돌 시**: `custom/`의 스킬이 다른 카테고리보다 우선합니다.

---

## 트리거 기반 자동 로딩

스킬은 입력 패턴에 따라 자동으로 로딩됩니다.

### 트리거 정의

각 스킬의 `SKILL.md`나 메타데이터에 트리거 패턴이 정의됩니다:

```yaml
# 예시: deploy 스킬
name: deploy
category: software-development
triggers:
  - "deploy"
  - "git push"
  - "release"
  - "프로덕션 배포"
priority: high
```

### 트리거 매칭 과정

```
사용자 입력: "서비스를 프로덕션에 배포해줘"
  → 키워드 스캔
    → "배포" 감지
    → deploy 스킬 매치
    → priority 확인 (high)
    → 스킬 자동 로딩
```

### 매칭 전략

| 전략 | 설명 |
|------|------|
| 키워드 매칭 | 정확 일치 |
| 패턴 매칭 | 정규식 기반 |
| 언어 감지 | 한국어 ↔ 영어 매핑 |
| 문맥 분석 | 대화 맥락 고려 |

---

## SKILL.md 구조

각 스킬 디렉토리의 `SKILL.md` 파일은 스킬의 문서화입니다:

```markdown
# 스킬명

**카테고리**: software-development
**우선순위**: high
**트리거**: deploy, git push, release

## 설명
프로덕션 배포 자동화 스킬입니다.

## 사용법
```bash
deploy --target production --env prod
```

## 의존성
- git
- docker

## 출력
- 배포 로그
- 상태 리포트
```

---

## 카테고리별 스킬 예시

### software-development

| 스킬 | 설명 |
|------|------|
| git | Git 작업 (commit, push, merge) |
| deploy | 프로덕션 배포 |
| debugging | 디버깅 지원 |
| code-review | 코드 리뷰 |

### creative

| 스킬 | 설명 |
|------|------|
| ascii-art | ASCII 아트 생성 |
| infographic | 인포그래픽 생성 |
| slide | 발표 슬라이드 제작 |

### research

| 스킬 | 설명 |
|------|------|
| literature-review | 문헌 조사 |
| data-analysis | 데이터 분석 |
| paper-writing | 논문 작성 |

### system-common

| 스킬 | 설명 |
|------|------|
| event.sh | 이벤트 버스 라이브러리 |
| file-utils | 파일 유틸리티 |
| log-format | 로그 포맷팅 |

---

## 스킬 상속

상위 카테고리에서 하위 카테고리로 스킬이 상속됩니다:

```
system-common/  (모든 카테고리에서 접근 가능)
  │
  ├── software-development/
  │     │
  │     ├── backend/   (software-development 스킬 + backend 전용)
  │     └── frontend/
  │
  ├── creative/
  │     │
  │     ├── visual/
  │     └── text/
  │
  └── research/
```

**상속 예시:**
- `software-development/backend/` 스킬은 `system-common/`의 스킬을 자동으로 상속
- `custom/backend/`는 `software-development/backend/`보다 우선

---

## Model Catalog 스킬

`skills/custom/model-catalog/`는 모델 라우팅의 핵심입니다.

**`catalog.json`:**
```json
{
  "providers": {
    "airrouter": {
      "base_url": "https://api.airouter.ch/v1",
      "models": [
        { "name": "Qwen3.6", "role": "default", "cost": 0.001 },
        { "name": "Gemma-4", "role": "design", "cost": 0.002 },
        { "name": "Claude-Sonnet-4-5", "role": "analysis", "cost": 0.003 }
      ]
    },
    "z_ai": { "base_url": "...", "models": [...] },
    "openrouter": { "base_url": "...", "models": [...] }
  },
  "routing": {
    "request": "Qwen3.6",
    "design": "Gemma-4",
    "review": "Claude-Sonnet-4-5",
    "execution": "Qwen3.6"
  }
}
```

---

## Express System (표현력 스킬)

`skills/custom/expression-system/`는 콘텐츠 유형에 따른 표현 방식을 관리합니다.

| 콘텐츠 유형 | 모델 매핑 | 출력 |
|------------|----------|------|
| 이미지 | D5 → ComfyUI | PNG |
| 텍스트 | Qwen3.6 | Markdown |
| 코드 | Qwen3.6 | Source |
| 분석 | Claude-Sonnet | Report |

---

## 참조

- [시스템 종합](systems/overview.md) — 전체 시스템 현황
- [워크플로우 파이프라인](workflow-pipeline.md) — 9단계 파이프라인
- [인덱스](index.md) — 문서 탐색
