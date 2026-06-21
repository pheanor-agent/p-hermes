---
spec_id: SPEC-D03
version: 1.2.0
parent: null
status: approved
changed_at: "2026-06-21T00:00:00Z"
type: guideline
title: "p-hermes 문서 작성 및 표현력 시스템(Expression) 표준"
domain: expression
tags: [expression, d1, documentation-standard, multi-level, pre-direction]
---

# SPEC-D03: p-hermes 문서 작성 및 표현력 시스템 표준

## 1. 정의 및 목적

본 사양서는 p-hermes 프로젝트의 모든 공개 문서(Wiki, Blog, Slides)가 일관된 품질과 톤, 깊이를 유지하도록 강제하는 작성 표준입니다. 단순히 정보를 전달하는 것을 넘어, 기술적 배경이 다른 다양한 독자가 단계적으로 지식을 습득할 수 있는 **'다층적 지식 전달 체계'** 구축을 목적으로 합니다.

### 1.1 품질 관리 방식: Pre-Direction 아키텍처 (JOB-1735)

콘텐츠 품질 관리는 기존 사후 검증(post_validator) 방식에서 **사전 방향성(Pre-Direction)** 방식으로 전환되었습니다. 생성 전에 방향성을 먼저 결정하고, 이 방향성에 따라 생성 및 검증이 진행됩니다.

**Pre-Direction 7단계 모듈**:

| 단계 | 모듈 | 역할 |
|------|------|------|
| 1 | `strategy_selector` | 전략 프레임 선택 |
| 2 | `audience_analyzer` | 청중 3축 분석 (기술수준·관심도·목적) |
| 3 | `template_selector` | 구조 템플릿 매칭 |
| 4 | `design_guide_provider` | 디자인 방향성 설정 |
| 5 | `design_system_loader` | 구체적 디자인 토큰 로드 |
| 6 | `direction_compiler` | direction-guide.json 생성 |
| 7 | `guide_validator` | 자체 검증 (방향성 유효성 확인) |

**공유 엔진 7개 모듈**:

| 엔진 | 역할 | 적용 도메인 |
|------|------|-------------|
| `persona_generator` | 페르소나 기반 문체 생성 | D4 창작 |
| `emotion_merger` | 감정어 합성 및 문장 흐름 조절 | D4 창작 |
| `analogy_builder` | 비유 생성 및 유사성 매핑 | D2 교육, D4 창작 |
| `tier_generator` | 계층적 구조 생성 (요약→상세→심화) | D1~D5 전체 |
| `template_filler` | 템플릿 기반 콘텐츠 생성 | D3 프레젠테이션, D5 비즈니스 |
| `tone_adapter` | 톤 적응 및 문체 일관성 유지 | D1~D5 전체 |
| `strategy_selector` | 전략 프레임 선택 (Pre-Direction) | D1~D5 전체 |

> Pre-Direction 7개 모듈과 공유 엔진 7개 중 `strategy_selector`가 중복되어, **총 13개 고유 모듈**로 구성됩니다.

### 1.2 검증 파이프라인: 5계층 게이트

Pre-Direction 완료 후, 생성된 콘텐츠는 5계층 검증 게이트를 통과합니다:

| 계층 | 검증 항목 | 설명 |
|------|----------|------|
| L1 | 구조 검증 (Struct) | JSON/Markdown 구조 유효성 |
| L2 | 에러 체크 (Error) | 렌더링 실패 토큰 차단 |
| L3 | 어조 검증 (Voice) | 금지 어휘, 전환어구 중복 차단 |
| L4 | 도메인 검증 (Domain) | 도메인별(D1~D5) 품질 기준 확인 |
| L5 | Judge Model (Blog 전용) | 경량 LLM이 어조·뉘앙스 평가 |

> L3/L4/L5 실패 시 Pre-Direction 단계로 피드백 루프를 형성하여 방향성 재조정 후 재생성합니다.

---

## 2. 핵심 작성 원칙

### 2.1 다층적 지식 전달 구조 (The Layered Approach)
모든 문서는 다음의 구조를 엄격히 준수하여, 독자가 자신의 지식 수준에 맞춰 읽을 수 있도록 구성합니다.

| 섹션 | 목적 | 타겟 독자 | 필수 내용 |
|---|---|---|---|
| **💡 한 줄 요약** | 핵심 메시지 즉시 전달 | 모든 독자 | 50자 이내의 명확한 요약 |
| **🌱 기본 개념** | 진입 장벽 제거 | 비기술자 / 입문자 | 일상적 비유, 기본 용어 정의, "왜 필요한가?" |
| **🔍 문제 상황** | 설계 동기 부여 | 입문자 / 개발자 | 기존의 통증(Pain point), 실제 사고 사례, 한계점 |
| **🏗️ 기술 설계** | 구현 메커니즘 상세화 | 개발자 / 전문가 | 구체적 로직, 파일 경로, 변수, 알고리즘, 공학적 이유 |
| **📊 구조/흐름도** | 시각적 이해 | 모든 독자 | Mermaid 다이어그램 (Flowchart, Sequence 등) |
| **💡 활용 예시** | 실용성 검증 | 모든 독자 | 구체적인 설정값, 실행 명령어, 결과물 예시 |
| **🔗 관련 주제** | 지식 확장 | 모든 독자 | 내부 문서 교차 링크 (GitHub Pages URL) |

### 2.2 기술 서술의 깊이 (Technical Depth)
"동작한다"는 결과보다 **"어떻게 동작하는가"**라는 과정에 집중합니다.

- **구체성**: "상태를 관리한다" $\rightarrow$ "`.workflow-state` JSON 파일에 상태를 기록하고 `flock`으로 동시성을 제어한다"
- **원리 서술**: 사용된 기술의 공학적 근거 제시 (예: 지수 백오프를 사용하는 이유 $\rightarrow$ Thundering Herd 문제 방지)
- **예외 처리**: Happy Path뿐만 아니라, 에러 발생 시의 복구 시나리오(Fallback)를 반드시 포함.
- **독립성**: 각 문서는 해당 주제를 80% 이상 자립적으로 이해할 수 있을 만큼 충분한 양의 정보를 포함해야 함.
  - **최소 분량**: Wiki 가이드 $\ge$ 1,500자, Blog 포스트 $\ge$ 3,000자.

### 2.3 표현력 시스템 D1 적용 (Tone & Manner)
비기술적 대상 독자를 위해 **Content System D1** 톤을 적용합니다.

- **친근한 비유**: 복잡한 아키텍처를 일상적인 역할(예: 팀장-사원, 비서-사장)에 비유하여 설명.
- **단계적 확장**: 쉬운 용어 $\rightarrow$ 기술 용어 $\rightarrow$ 심화 개념 순으로 전개.
- **능동적 문체**: "되어진다" $\rightarrow$ "합니다/입니다" 등 명확하고 자신감 있는 전문적 어조.

---

## 3. 포맷 및 제약 사항 (Contract)

### 3.1 시각 요소 표준
- **다이어그램**: ASCII Art 절대 금지 $\rightarrow$ **Mermaid JS** 포맷만 사용.
- **색상/테마**: 라이트 테마(흰색 배경, 짙은 회색 텍스트) 기준의 스타일 적용.
- **링크**: README 및 외부 문서에서는 **GitHub Pages 절대 URL** 사용.

### 3.2 용어 정합성
- **사양서 기반 개발 (Spec-Driven Dev)**: "사양서(Spec)가 SSOT가 되어 코드를 제어하는 프로세스"로 정의.
- **스크립트 활용 정책**: "명령어 복붙 대신 스크립트를 작성/활용하는 에이전트의 행동 규칙"으로 정의.
- 두 용어를 혼용하지 않고, 각각 '프로세스'와 '정책'으로 명확히 구분하여 서술.

---

## 4. Acceptance Criteria (검증 기준)

**Given**: 에이전트가 문서를 생성/수정함
**When**: 아래 기준을 모두 충족함
1. [ ] 구조: `한 줄 요약` $\rightarrow$ `기본 개념` $\rightarrow$ `문제` $\rightarrow$ `설계` $\rightarrow$ `흐름도` $\rightarrow$ `예시` 순서 준수
2. [ ] 분량: Wiki $\ge$ 1,500자 또는 Blog $\ge$ 3,000자 충족
3. [ ] 기술: 단순 결과 서술이 아닌 구체적 메커니즘(함수, 파일, 로직)이 포함됨
4. [ ] 시각: 모든 다이어그램이 Mermaid 포맷임
5. [ ] 링크: 외부 링크가 `https://pheanor-agent.github.io/p-hermes/...` 형태임
**Then**: 문서 승인 및 배포 대상으로 확정
