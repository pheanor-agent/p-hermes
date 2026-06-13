# Layer 1: Core Engine (핵심 엔진)

Hermes Agent 시스템의 핵심 처리 계층입니다. LLM 호출, 스킬 관리, 워크플로우 관리를 담당합니다.

---

## 구성 요소

| 구성 요소 | 역할 | SSOT |
|-----------|------|------|
| **Model & Provider** | 다중 LLM 라우팅, Fallback, 비용 추적 | `catalog.json` |
| **Skill System** | 144+ 스킬 관리, 카테고리/트리거 로딩 | `skills/*/SKILL.md` |
| **Workflow Pipeline** | 9단계 상태 머신, 체크포인트 검증 | `.workflow-state` |

---

## 1. Model & Provider

### 1.1 다중 프로바이더 아키텍처

Hermes는 여러 LLM 제공사를 동시에 지원합니다.

```
                    ┌──────────────┐
                    │  Hermes      │
                    │  Core Engine │
                    └──────┬───────┘
                           │ 요청
                   ┌───────┴────────┐
                   │  Model Router   │
                   └───┬───┬───┬────┘
         ┌────────┐    │   │   │    └────┐
         │ Fallback│  ┌┴──┐ └┬─┐ ┌┴────┐ │
         └────────┘  │AR  │ │Z │ │OR   │ │ 비용
                     │  3 │ │ 4 │ │13  │ │ 추적
                     └────┘ └──┘ └─────┘ └──┘
                      ↑      ↑     ↑
                   Airrouter Z.AI OpenRouter
```

**프로바이더 현황:**

| 프로바이더 | 모델 수 | 특징 |
|-----------|---------|------|
| Airrouter | 3 | 기본 엔드포인트, 저지연 |
| Z.AI | 4 | 대용량 처리 특화 |
| OpenRouter | 13 | 다양한 모델 접근 |
| **총계** | **20** | |

### 1.2 모델 라우팅

워크플로우 단계에 따라 최적의 모델을 선택합니다.

```json
{
  "routing": {
    "request": "Qwen3.6",
    "investigation": "Qwen3.6",
    "design": "Gemma-4",
    "review": "Claude-Sonnet-4-5",
    "approval": "Qwen3.6",
    "execution": "Qwen3.6",
    "test": "Qwen3.6",
    "execution_review": "Qwen3.6",
    "done": null
  }
}
```

### 1.3 Fallback 메커니즘

primary 모델 호출 실패 시 secondary로 자동 전환됩니다:

```
1. primary 모델 호출
2. 실패 감지 (timeout, rate limit, error)
3. secondary 모델 선택 (catalog.json에서)
4. 재시도
5. 실패 시 에러 리포트
```

### 1.4 비용 추적

모든 API 호출에 대해 사용량을 로깅합니다:
- 토큰 수 (입력/출력)
- 모델명
- 프로바이더
- 작업 ID (JOB)
- 타임스탬프

---

## 2. Skill System

### 2.1 구조

```
skills/
├── custom/                      # 사용자 정의 (최우선 로딩)
│   ├── model-catalog/           # 모델 카탈로그
│   ├── expression-system/       # 표현력 시스템
│   └── ...
├── software-development/        # 소프트웨어 개발
├── creative/                    # 창의적 작업
├── research/                    # 연구
├── writing/                     # 글쓰기
├── system-common/               # 공통 유틸리티
│   └── lib/
│       └── event.sh             # 이벤트 버스 라이브러리
└── ... (30+ 카테고리)
```

### 2.2 스킬 로딩 순서

1. **Custom** (`skills/custom/`) — 최우선
2. **Task-specific category** — 작업 유형에 맞는 카테고리
3. **System-common** — 공통 유틸리티
4. **Default** — 기본 스킬

### 2.3 트리거 기반 로딩

스킬은 키워드/패턴 매칭으로 자동 로딩됩니다:

```yaml
# 스킬 메타데이터 예시
triggers:
  - "git push"
  - "deploy"
  - "release"
category: software-development
priority: high
```

사용자 입력에서 `deploy` 키워드 감지 → `software-development/deploy` 스킬 자동 로딩

### 2.4 SKILL.md 문서화

각 스킬 디렉토리에 `SKILL.md`가 포함되어 있습니다:

```markdown
# 스킬명
- **카테고리**: software-development
- **트리거**: git push, deploy
- **설명**: ...
- **사용법**: ...
```

### 2.5 핵심 통계

| 항목 | 수 |
|------|-----|
| 총 스킬 | 144+ |
| 카테고리 | 30+ |
| Custom 스킬 | 사용자 정의 |
| 시스템 공통 | event.sh 등 |

---

## 3. Workflow Pipeline

### 3.1 9단계 파이프라인

```
request → investigation → design → review → approval → execution → test → execution_review → done
  [0]        [1]              [2]      [3]       [4]         [5]         [6]      [7]             [8]
   ↑            ↑               ↑        ↑          ↑           ↑          ↑          ↑               ↑
  입력       조사           설계     검토      승인       실행      검증     실행검토        완료
```

### 3.2 상태 관리

- **SSOT**: `.workflow-state` (JSON)
- **경로**: `~/.hermes/workspace/jobs/JOB-XXXX/.workflow-state`
- **자동 전이**: 단계 완료 후 즉시 다음 단계 진입

### 3.3 체크포인트 검증

각 단계 전환 시 I1~I16 검증 규칙이 적용됩니다:

| 규칙 | 설명 |
|------|------|
| I1 | 작업 정의 존재 확인 |
| I2 | 산출물 명확성 검증 |
| I3 | 의존성 체크 |
| ... | ... |
| I16 | 최종 완성도 검증 |

### 3.4 핵심 스크립트

| 스크립트 | 역할 |
|---------|------|
| `create-job.sh` | 새 JOB 생성 + 디렉토리 설정 |
| `workflow-gate.sh` | 단계 검증 + 상태 전이 + 모델 전환 |
| `on-job-complete.sh` | JOB 완료 후 지식 sync + 리포트 |

---

## 계층 간 인터페이스

### Layer 1 → Layer 2

| 인터페이스 | 설명 |
|-----------|------|
| 지식 읽기 | Wiki T1/T2 항목 조회 |
| 지식 쓰기 | Lessons 생성 (JOB 완료 시) |
| 상태 공유 | Blackboard 파일 시스템 |
| Cron 이벤트 | 이벤트 버스 구독 |

### Layer 1 → Layer 3

| 인터페이스 | 설명 |
|-----------|------|
| 메시지 전송 | `send_message` 도구 |
| 이미지 생성 | ComfyUI/OpenRouter 호출 |
| 콘텐츠 출력 | 파일 생성 (HTML, PDF 등) |

---

## 참조

- [ARCHITECTURE.md](../ARCHITECTURE.md) — 전체 아키텍처
- [docs/workflow-pipeline.md](workflow-pipeline.md) — 파이프라인 상세
- [docs/skill-system.md](skill-system.md) — 스킬 시스템 상세
- [docs/systems/models.md](systems/models.md) — 모델 시스템 심화
