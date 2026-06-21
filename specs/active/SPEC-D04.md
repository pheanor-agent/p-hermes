---
spec_id: SPEC-D04
version: 1.0.0
parent: SPEC-D01
status: approved
changed_at: "2026-06-17T00:00:00Z"
type: requirement
title: "p-hermes 문서 작성 요구사항 명세서"
domain: documentation
tags: [docs, requirements, 3-track, multi-domain, expression]
---

# p-hermes 문서 작성 요구사항 명세서

> **작성일**: 2026-06-16
> **수정**: 고성능 추론 모델 리뷰 반영 (26개 이슈 해결)
> **목적**: 실제 문서 집필을 위한 상세 요구사항 정의
> **대상**: 핵심 시스템 6개(A1~A6) + 배경 2개(B1~B2) = 8도메인 × 3매체 = 24개 문서

---

## 공통 요구사항

### 도메인별 차등 분량

| 도메인 그룹 | 포함 도메인 | Wiki (자) | Blog (자) |
|-------------|-------------|-----------|-----------|
| **A 도메인** | A1~A6 (Workflow, Spec-Driven Dev, Content System, Knowledge System, Cron/Automation, Model Routing) | 3,500 이상 | 10,000 이상 |
| **B 도메인** | B1~B2 (Hermes Agent 개요, 아키텍처) | 2,500 이상 | 8,000 이상 |

### Wiki: 가이드형 (A1-A6)
- **분량**: 3,500자 이상 (A 도메인 기준)
- **어조**: 객관적, 지시적, 간결함 (3인칭 관찰자 시점)
- **구조**: 서론 → 전제조건 → 설정 방법 → 단계별 실행 절차 → 검증 및 예외 처리 → FAQ
- **요구 요소**:
  - 코드 블록은 \`\`\`bash/\`python\` fenced 코드 블록 사용
  - CLI 출력 예시는 코드 블록에 명시
  - 설정값은 표(Table) 형태로 압축
  - Mermaid JS 다이어그램 포함
  - 부정대조 패턴(`~대신`, `~아니라`, `~반면`) 사용 금지

### Wiki: 레퍼런스형 (B1-B2)
- **분량**: 2,500자 이상 (B 도메인 기준)
- **어조**: 객관적, 기술적, 참조용
- **구조**: 서론 → 개념 설명 → 구조 → 구성 요소 → 관련 링크 → FAQ
- **요구 요소**:
  - 디렉토리 구조는 텍스트 다이어그램
  - 설정 파일은 fenced 코드 블록
  - Mermaid JS 다이어그램 포함
  - 부정대조 패턴 사용 금지

### Blog (모든 도메인)
- **분량**: 10,000자 이상 (A 도메인 기준) / 8,000자 이상 (B 도메인 기준)
- **어조**: 분석적, 해설적, 설득력 있는 비평적 문체
- **모든 도메인 Blog = 기술 블로그 (Why 중심)**
- **구조**: 기존 시스템의 한계 → 설계 철학 → 심층 메커니즘 분석 → 향후 전망
- **요구 요소**:
  - 1단 텍스트 중심, 여백 활용
  - 아키텍처 맵, 데이터 흐름도, 인포그래픽 포함
  - Mermaid JS 다이어그램 사용
  - 기술적 근거와 정량적 데이터 필수
  - L5 Judge Model 검증 대상
  - 부정대조 패턴 사용 금지

### Slides (모든 도메인)
- **분량**: 8~10장
- **어조**: 단정적, 압축적, 시각적 직관성
- **구조**: 후크 → 핵심 개념 3원칙 → 시각적 파이프라인 → 실행 요약
- **요구 요소**:
  - HTML 형식 (라이트 테마)
  - 텍스트 최소화, 고대비 타이포그래피
  - Mermaid JS 다이어그램 필수
  - 진행적 공개(Progressive disclosure) 원칙
  - Guy Kawasaki 10-20-30 Rule 준수 (30pt 폰트, 20분, 10장)
  - 부정대조 패턴 사용 금지
  - YAML 프런트매터 포함

### 공통 메타데이터
- 모든 Wiki/Blog 최상단에 YAML 프런트매터 포함:
```yaml
---
id: DOC-{도메인}-{매체}
domain: {도메인명}
type: wiki | blog | slides
title: {제목}
date: 2026-06-16
version: "1.0.0"
compatibility: v0.16.0
author: {에이전트/사용자}
status: draft | review | published
tags: ["tag1", "tag2"]
related_specs: ["SPEC-XXX", "SPEC-YYY"]
---
```

### 교차 참조(Cross-link) 정책
- 모든 문서 말미에 **"관련 문서"** 섹션 포함
- 최대 3개 링크로 제한
- 형식: `[도메인명] 문서명 (Wiki/Blog/Slides)`
- 과도한 상호 참조 금지

### 링크 경로 규칙 (GitHub Pages 배포 고려)

| 링크 유형 | 형식 | 예시 |
|-----------|------|------|
| **내부 문서 (동일 매체)** | `./` 또는 `../` 상대경로 | `./request-task.md` |
| **내부 문서 (다른 매체)** | `/docs/` 루트 기준 상대경로 | `/docs/wiki/guides/request-task.md` |
| **GitHub Pages (Slides)** | `/docs/` 루트 기준 절대경로 | `/docs/slides/decks/workflow-pipeline.html` |
| **외부 URL** | `https://` 전체 URL | `https://github.com/pheanor/p-hermes` |

> **⚠️ GitHub Pages Slides 배포 시 주의사항**:
>
> 1. **절대 URL 금지**: `http://` 또는 `https://`로 시작하는 내부 링크 사용 금지. 도메인 변경 시 모두 수정 필요.
> 2. **상대 경로 통일**: 모든 내부 링크는 `/docs/` 루트 기준 절대 경로 또는 `./` 상대 경로만 사용.
> 3. **Slides 내부 링크**: HTML Slides에서 Wiki/Blog로跳转하는 링크는 `/docs/` 루트 기준 절대 경로 사용.
> 4. **외부 링크**: `target="_blank" rel="noopener noreferrer"` 필수 적용.
> 5. **Fragment 링크**: 동일 문서 내 섹션跳转 시 `#section-id` 사용. 다른 문서 섹션은 `/path/to/doc.md#section-id`.
> 6. **GitHub 파일 링크**: 소스 코드, 스크립트 파일 참조 시 `https://github.com/pheanor/p-hermes/blob/main/` 형식.

### 버전 관리 정책
- 프런트매터 `version` 필드 필수 (semver: `MAJOR.MINOR.PATCH`)
- **Major**: 구조 변경 (섹션 재구성, 전체 개편)
- **Minor**: 섹션 추가, 내용 대폭 보충
- **Patch**: 오타 수정, 링크 수정, 서식 조정
- 변경 이력은 각 문서 말미 **"변경 이력"** 섹션에 기록

---

## A1. Workflow (워크플로우)

### Wiki: `docs/wiki/guides/request-task.md`

**제목**: 워크플로우 사용 가이드

**내용 구성**:
1. **서론** (300자): 워크플로우 시스템의 역할과 9단계 구조 소개
2. **JOB 등록** (600자): `create-job.sh` 실행 방법, 파라미터 설명, 생성되는 폴더 구조
3. **9단계 상태 관리** (1,500자): 3개 그룹으로 구성
   - **준비 단계** (500자): request → investigation → design (조사와 설계)
   - **실행 단계** (600자): review → approval → execution → test (승인과 실행)
   - **완료 단계** (400자): execution_review → done (검토와 완료)
4. **workflow-gate.sh 사용법** (400자): 상태 전이 검증 명령어, 병렬 실행 차단, 승인 게이트
5. **`.workflow-state` 파일** (400자): JSON 구조 설명, flock 원자적 갱신 메커니즘
6. **예외 처리** (300자): 실패 시 롤백, 오류 상태 처리
7. **FAQ** (300자): 자주 묻는 질문 3-4개

**시각화**: 9단계 상태 전이 시퀀스 다이어그램 (Mermaid)

**실제 코드 필요**:
- `create-job.sh` 사용 예시
- `workflow-gate.sh start/complete` 명령어
- `.workflow-state` JSON 샘플

---

### Blog: `docs/blog/posts/why-9-step-workflow.md`

**제목**: 9단계 워크플로우: 에이전트 신뢰도를 설계하는 방법

**내용 구성**:
1. **서론** (1,000자): 초기 에이전트 모델들의 불안정성 문제, 무분별한 병렬 작업의 위험성
2. **상태 충돌 문제와 해결책** (2,500자): AI 환각이 야기하는 코드 파괴 사례, 9단계가 방어하는 메커니즘 (해결책 40% 배분)
3. **9단계 철학** (2,000자): 조사-설계-실행 분절화, 중간 리뷰와 승인 게이트의 역할
4. **원자적 상태 관리** (1,500자): flock 기반 파일 락 메커니즘, 병렬 실행 차단의 공학적 의의
5. **검증과 방어** (1,500자): AI 환각에 대한 다층 방어 체계, 승인 게이트의 인지적 허들 역할
6. **향후 전망** (1,500자): 자동화 워크플로우의 진화 방향, 다중 에이전트 협업 시나리오

**시각화**: 유향 비순환 그래프(DAG) 형태의 9단계 플로우차트 (Mermaid)

---

### Slides: `docs/slides/decks/workflow-pipeline.html`

**제목**: 워크플로우 파이프라인: AI 작업을 신뢰하게 하는 설계

**슬라이드 구성** (8~10장):
1. **타이틀**: 워크플로우 파이프라인 (후크: "AI가 작업을 신뢰할 수 있게 하는 방법")
2. **문제 정의**: 상태 충돌과 AI 환각의 위험성
3. **해법**: 9단계 상태 머신 소개
4. **핵심 개념 3**: 분절화, 검증, 원자적 관리
5. **준비 단계**: request → investigation → design
6. **실행 단계**: review → approval → execution → test
7. **완료 단계**: execution_review → done
8. **원자적 관리**: flock 기반 상태 파일 갱신
9. **핵심 명령어**: create-job.sh, workflow-gate.sh
10. **요약**: 9단계 워크플로우의 가치

**시각화**: 9단계 파이프라인 다이어그램, 진행률 바 애니메이션

---

## A2. Spec-Driven Dev (사양서 기반 개발)

### Wiki: `docs/wiki/guides/spec-driven-dev.md`

**제목**: 사양서 기반 개발 가이드

**내용 구성**:
1. **서론** (300자): Spec-Driven Dev의 정의와 SSOT 원칙
2. **Spec 구조** (600자): `specs/active/SPEC-XXX.md` 파일 구조, 필수 포함 항목
3. **5단계 상태 주기** (800자): draft → review → approved → active → archived 전이
4. **검증 스크립트** (800자): 7개 검증 도구 목록과 역할 (구조, 링크, conformance, triage 등)
5. **실행 방법** (500자): `--run-tests` 플래그 사용법, 명령어와 출력값 대비
6. **변경 로그** (300자): `change-log.md` 작성 규칙
7. **강제 규칙** (200자): 직접 파일 수정 금지, 정량적 주장 근거 필수
8. **FAQ** (200자): 자주 묻는 질문 2-3개

**시각화**: Spec 상태 주기 다이어그램 (Mermaid)

**실제 코드 필요**:
- SPEC-XXX.md 템플릿
- 검증 스크립트 실행 예시
- `--run-tests` 출력 샘플

---

### Blog: `docs/blog/posts/spec-driven-dev.md`

**제목**: 구조적 강제: 사양서가 코드를 지배하는 이유

**내용 구성**:
1. **서론** (1,000자): 문서 부패(Documentation rot) 문제의 보편성
2. **문서-코드 분리 비용** (2,000자): 기술 부채의 악순환, 스프레드 시트화되는 코드베이스
3. **단일 진실 출처** (2,500자): Spec을 SSOT로 강제하는 공학적 의의, 변경 로그의 추적성
4. **검증 파이프라인** (2,000자): 7개 검증 도구가 시스템 엔트로피를 낮추는 메커니즘
5. **선순환 구조** (1,500자): Spec 변경 → 코드 갱신 → 테스트 자동화 순환
6. **향후 전망** (1,000자): living spec 개념, AI 시대 개발 방법론의 진화

**시각화**: 뫼비우스의 띠 형태 순환 다이어그램 (Mermaid)

---

### Slides: `docs/slides/decks/spec-driven-dev.html`

**제목**: Spec-Driven Dev: 사양서가 코드를 지배하는 방식

**슬라이드 구성** (8~10장):
1. **타이틀**: "직접 파일 수정 금지" (도발적 문구)
2. **문제 정의**: 문서 부패와 기술 부채
3. **해법**: Spec을 SSOT로 강제
4. **핵심 개념 3**: 검증, 추적, 강제
5. **5단계 상태 주기**: draft → archived
6. **검증 파이프라인**: 7개 검증 도구
7. **선순환 구조**: Spec → 코드 → 테스트
8. **실제 적용**: 프로젝트 사례
9. **핵심 명령어**: --run-tests, 검증 스크립트
10. **요약**: 구조적 강제의 가치

**시각화**: 방사형 신경망 맵, 순환 다이어그램

---

## A3. Content System (콘텐츠 시스템)

### Wiki: `docs/wiki/guides/content-system.md`

**제목**: 콘텐츠 시스템 사용 가이드

**내용 구성**:
1. **서론** (300자): Content System의 역할과 파이프라인 개요
2. **페르소나 생성기** (500자): `persona_generator.py` 사용법, 파라미터 설명
3. **톤 어댑터** (500자): `tone-adapter.py` 사용법, D1-D5 레벨 조정 척도
4. **Emotion Merger 설정** (300자): Blog 서사형에만 조건적 적용 방법
5. **검증 게이트** (800자): L1-L4 게이트별 기능 설명, JSON 페이로드 구조
6. **L5 검증 설정** (300자): Blog 전용 Judge Model 활성화 방법
7. **Anti-Slop 설정** (500자): `anti-slop-library.json` 구성 방법, 금지어/패턴 추가
8. **명칭 통일 검증** (200자): `Content System` 강제 규칙
9. **파이프라인 실행** (300자): 초안 → 검증 → 최종 출력 흐름
10. **FAQ** (200자): 자주 묻는 질문 2-3개

**시각화**: 파이프라인 흐름도 (Mermaid), 2단 그리드 레이아웃

**실제 코드 필요**:
- `persona_generator.py` 파라미터 예시
- `anti-slop-library.json` 샘플
- 검증 게이트 JSON 페이로드

---

### Blog: `docs/blog/posts/content-system-design.md`

**제목**: Anti-Slop 파이프라인: AI 텍스트의 품질을 보증하는 5계층 검증

**내용 구성**:
1. **서론** (1,000자): AI 생성 텍스트의 'Slop' 현상과 그 비용
2. **기존 검증의 한계** (2,000자): 휴리스틱 기반 검출의 실패 사례, 문법 검사기의 한계
3. **L1-L4 게이트 설계** (1,500자): 구조, 오류, 어조, 도메인 게이트의 메커니즘
4. **L5 Judge Model** (1,000자): 별도 LLM 호출을 통한 거시적 품질 심사, 비용-효용 분석
5. **조건적 최적화** (1,500자): Wiki는 L1-L4, Blog는 L5 추가 적용 전략, Emotion Merger 조건화
6. **향후 전망** (2,000자): 자동 콘텐츠 품질 관리의 진화, 인간-기계 협업 서사

**시각화**: 정제 파이프라인 다이어그램 (원수 → 5계층 필터 → 결정체)

---

### Slides: `docs/slides/decks/content-system.html`

**제목**: Content System

**슬라이드 구성** (8~10장):
1. **타이틀**: "AI가 인간 같은 글을 쓰는 법" (후크)
2. **문제 정의**: Slop 현상과 품질 문제
3. **해법**: 5계층 Anti-Slop 게이트
4. **핵심 개념 3**: 페르소나, 톤, 검증
5. **L1-L4 게이트**: 구조, 오류, 어조, 도메인
6. **L5 Judge Model**: Blog 전용 최종 심사
7. **조건적 적용**: Wiki vs Blog 검증 레벨 차이
8. **Before/After**: 금지어 차단 효과 시각화
9. **파이프라인**: 초안 → 검증 → 최종 출력
10. **요약**: 콘텐츠 품질 보증 체계

**시각화**: 스텝 뷰 레이아웃, 필터 메타포 다이어그램

---

## A4. Knowledge System (지식 시스템)

### Wiki: `docs/wiki/guides/knowledge-system.md`

**제목**: 지식 시스템 사용 가이드

**내용 구성**:
1. **서론** (300자): 지식 시스템의 역할과 계층적 구조 개요
2. **원본 소스** (500자): 세션 이력, JOB 기록, 뉴스 피드, 리퍼런스 링크 수집
3. **Wiki 트리 구조** (600자): `~/.hermes/knowledge/wiki/` 디렉토리 구조 설명
4. **점수 체계** (600자): T1/T2/T3 분류 기준, 빈도/최근성/참조 수 기반 채점
5. **자동 갱신** (500자): `wiki-process-filings.sh` 5분 간격 cron, 수동 실행 방법
6. **스크립트 사용법** (400자): `build-scores.sh`, `knowledge-sync.sh` 실행 절차
7. **무결성 규칙** (300자): LLM 추정 금지, 원본 직접 참조만 허용
8. **예외 처리** (200자): 데이터 가지치기, 컴팩션
9. **FAQ** (200자): 자주 묻는 질문 2-3개

**시각화**: 3-Tier 점수 체계 다이어그램, 트리 구조도 (Mermaid)

**실제 코드 필요**:
- `wiki-process-filings.sh` 실행 예시
- `build-scores.sh` 출력 샘플
- Wiki 디렉토리 구조 텍스트 다이어그램

---

### Blog: `docs/blog/posts/knowledge-system-design.md`

**제목**: 지식 시스템: 세션 데이터를 영구 자산으로 만드는 설계

**내용 구성**:
1. **서론** (1,000자): 일시적 데이터와 영구 자산의 경계 문제
2. **메모리 드리프트** (2,000자): 과거 에이전트의 지식 열화 문제, 컨텍스트 윈도우 한계
3. **동적 채점 로직** (2,500자): 빈도/최근성/참조 수 기반 알고리즘의 설계 철학
4. **3-Tier 점수 체계** (2,000자): T1/T2/T3가 정보 부패를 지연시키는 메커니즘
5. **폐쇄형 학습 루프** (1,500자): GEPA 메커니즘과 지식 시스템의 연계
6. **향후 전망** (1,000자): 자가 진화 지식 플랫폼, 인간-기계 공동 지식 생태계

**시각화**: 3단 피라미드 다이어그램 (원본 → 점수화 → T1 Wiki)

---

### Slides: `docs/slides/decks/knowledge-system.html`

**제목**: Knowledge System

**슬라이드 구성** (8~10장):
1. **타이틀**: "지식이 성장하는 시스템" (후크)
2. **문제 정의**: 메모리 드리프트와 지식 열화
3. **해법**: 계층적 지식 관리 플랫폼
4. **핵심 개념 3**: 수집, 점수화, 계층화
5. **원본 소스**: 세션, JOB, 뉴스, 리퍼런스
6. **3-Tier 점수 체계**: T1/T2/T3 분류
7. **동적 채점**: 빈도/최근성/참조 수 알고리즘
8. **자동 갱신**: 5분 간격 cron, 수동 실행
9. **무결성 규칙**: 원본 직접 참조 강제
10. **요약**: 자가 진화 지식 플랫폼

**시작화**: 3단 피라미드, 필터 메타포 애니메이션

---

## A5. Cron/Automation (자동화)

### Wiki: `docs/wiki/guides/automation.md`

**제목**: Cron/자동화 시스템 가이드

**내용 구성**:
1. **서론** (300자): 자동화 인프라의 3층 구조 개요
2. **registry.yaml** (600자): `~/.hermes/cron/registry.yaml` 작성 문법, 파라미터 설명
3. **스케줄 문법** (500자): cron 표현식, `30m`, `every 2h` 등 확장 문법 예시
4. **Job 속성** (600자): model, enabled_toolsets, deliver 속성 사용법
5. **이벤트 버스 사용법** (500자): `event.sh` 명령어, JSONL 히스토리 확인
6. **system-common 유틸리티** (400자): mkdir atomic mutex, 유틸리티 함수 백과사전
7. **다채널 전달** (300자): Telegram, Discord, 다채널 deliver 설정
8. **silent-on-success** (200자): 실패 시에만 알림 원칙
9. **FAQ** (200자): 자주 묻는 질문 2-3개

**시각화**: 3층 구조 다이어그램, 이벤트 버스 흐름도 (Mermaid)

**실제 코드 필요**:
- `registry.yaml` 샘플
- cron 표현식 예시 테이블
- `event.sh` 실행 명령어

---

### Blog: `docs/blog/posts/cron-3layer-design.md`

**제목**: 3층 분리 아키텍처: 자동화 인프라를 계층화하는 설계

**내용 구성**:
1. **서론** (1,000자): 동기식 스크립트 호출의 시스템 성능 취약성
2. **결합도 문제** (2,000자): 직접 호출이 야기하는 교착 상태, 모듈 간 의존성 폭발
3. **3층 구조 설계** (2,500자): L1 Scheduler, L2 Runtime, L3 Delivery의 책임 분리, silent-on-success 원칙 통합
4. **이벤트 버스** (2,000자): `event.sh` 단일 진입점이 결합도를 낮추는 메커니즘
5. **향후 전망** (2,500자): 이벤트 기반 아키텍처의 진화, 마이크로서비스와의 유사성

**시각화**: 3층 파이프라인 다이어그램 (Mermaid)

---

### Slides: `docs/slides/decks/cron-system.html`

**제목**: Cron/Automation

**슬라이드 구성** (8~10장):
1. **타이틀**: "보이지 않는 인프라를 가시화하다" (후크)
2. **문제 정의**: 동기식 호출의 결합도 문제
3. **해법**: 3층 분리 아키텍처
4. **핵심 개념 3**: 스케줄링, 실행, 전달
5. **L1 Scheduler**: registry.yaml, cron 표현식
6. **L2 Runtime**: cronjob 도구, job 실행
7. **L3 Delivery**: 다채널 전달, silent-on-success
8. **이벤트 버스**: event.sh 단일 진입점
9. **실제 적용**: Job 속성 설정 예시
10. **요약**: 비동기 자동화의 가치

**시작화**: 3단계 파이프라인, 다채널 분기 다이어그램

---

## A6. Model Routing (모델 라우팅)

### Wiki: `docs/wiki/guides/model-routing.md`

**제목**: 모델 라우팅 가이드

**내용 구성**:
1. **서론** (300자): 모델 라우팅 시스템의 역할과 라우팅 규칙 개요
2. **model-roles.yaml** (600자): 역할별 모델 매핑 파일 구조, 선언적 문법
3. **라우팅 규칙** (500자): prefix 무시 규칙, provider 기반 라우팅 (zai/, airouter/)
4. **역할별 할당** (500자): creative/reasoning → 고성능 추론 모델, coding/default → 고속 코딩 모델, review → 리뷰 전용 모델
5. **catalog.json** (400자): `~/.hermes/core/skills/custom/model-catalog/catalog.json` 갱신 절차
6. **다중 공급자** (400자): Zai, OpenRouter, NovitaAI, Ollama API 통합 설정
7. **핫스왑** (200자): `/model <name>` 명령어 사용법
8. **교차검증** (200자): design ↔ review 시 다른 모델 할당 규칙
9. **FAQ** (200자): 자주 묻는 질문 2-3개

**시각화**: 역할-모델 매핑 다이어그램 (Mermaid)

**실제 코드 필요**:
- `model-roles.yaml` 샘플
- `catalog.json` 구조 예시
- `/model` 명령어 예시

---

### Blog: `docs/blog/posts/model-routing-design.md`

**제목**: 다중 모델 라우팅: 하나의 에이전트에 다수의 브레인을 연결하는 설계

**내용 구성**:
1. **서론** (1,000자): 단일 모델 생태계의 종속성 문제와 벤더 락인
2. **단일 장애점** (2,000자): 모델 환각이 시스템 전체 실패로 이어지는 메커니즘
3. **인지적 다양성** (2,500자): 설계와 검토에 서로 다른 모델 할당의 공학적 의의
4. **벤더 중립성** (2,000자): 300+ 모델 생태계 조율의 전략적 우위, Tool Gateway 통합
5. **비용 최적화** (1,500자): 작업 유형별 경제성 분석, 저가 모델 활용 전략
6. **향후 전망** (1,000자): 다중 모델 협업의 진화, 자율 모델 선택 알고리즘

**시작화**: 모델 분기 트랙 다이어그램 (Mermaid)

---

### Slides: `docs/slides/decks/model-routing.html`

**제목**: 모델 라우팅: 한 에이전트, 다중 모델 전략

**슬라이드 구성** (8~10장):
1. **타이틀**: "One Agent, Multiple Brains" (후크)
2. **문제 정의**: 단일 모델의 한계와 벤더 락인
3. **해법**: 다중 모델 라우팅 시스템
4. **핵심 개념 3**: 라우팅, 교차검증, 벤더 중립
5. **역할별 할당**: creative, coding, review 모델 매핑
6. **라우팅 규칙**: prefix 무시, provider 기반
7. **교차검증**: design ↔ review 다른 모델
8. **벤더 중립**: 300+ 모델, Tool Gateway 통합
9. **실제 적용**: model-roles.yaml, catalog.json
10. **요약**: 지능적 모델 분배의 가치

**시작화**: 트랙 전환 애니메이션, 모델 분기 다이어그램

---

## B1. Hermes Agent 개요

### Wiki: `docs/wiki/getting-started/install.md`

**제목**: 에르메스 설치 및 설정

**내용 구성**:
1. **서론** (300자): 에르메스 에이전트 개요와 지원 환경
2. **무인 설치** (500자): `curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash` 명령어
3. **OAuth 로그인** (500자): `hermes setup --portal` 명령어, Tool Gateway 활성화
4. **파일 트리 구조** (600자): `~/.hermes/` 디렉토리 구조, skills/, cron/, memory/ 설명
5. **기본 설정** (500자): `config.yaml` 주요 파라미터, AGENTS.md 역할
6. **프로필 시스템** (500자): `~/.hermes/profiles/<name>/` 격리 환경
7. **검증** (200자): 설치 완료 확인 명령어
8. **FAQ** (200자): 자주 묻는 질문 2-3개

**시작화**: 파일 트리 텍스트 다이어그램, 설치 흐름도 (Mermaid)

---

### Blog: `docs/blog/posts/hermes-agent-intro.md`

**제목**: 에르메스 에이전트: 자율적 AI 플랫폼이 개척하는 패러다임

**내용 구성**:
1. **서론** (1,000자): 챗봇 래퍼 시대의 종식과 자율적 에이전트 패러다임
2. **영속적 생명력** (2,000자): 서버 상주, 프로젝트 학습, 도구 선택, 브라우저 제어
3. **폐쇄형 학습 루프** (2,500자): GEPA 메커니즘, 스킬 자생, 지식 내재화
4. **확장성** (2,000자): MLOps 인프라, 훈련 데이터 합성, RL 실험
5. **오픈소스 운동** (1,500자): Nous Research의 비전, 커뮤니티 기여
6. **향후 전망** (1,000자): 자율 AI 플랫폼의 진화 방향

**시작화**: 노드 네트워크 다이어그램 (에이전트 중심, 도구/메모리/인터페이스 위성 배치)

---

### Slides: `docs/slides/decks/hermes-overview.html`

**제목**: Hermes Agent 개요

**슬라이드 구성** (8~10장):
1. **타이틀**: "AI 에이전트의 새로운 표준" (후크)
2. **문제 정의**: 챗봇 래퍼의 한계
3. **해법**: 영속적 자율 에이전트 플랫폼
4. **핵심 개념 3**: 영속성, 자율성, 확장성
5. **영속적 생명력**: 서버 상주, 프로젝트 학습
6. **폐쇄형 학습 루프**: GEPA, 스킬 자생
7. **확장성**: MLOps 인프라, 훈련 데이터
8. **다중 연동**: Telegram, Discord, 300+ 모델
9. **실제 적용**: 설치 명령어, 파일 구조
10. **요약**: 자율 AI 플랫폼의 가치

**시작화**: 노드 네트워크, 위성 궤도 다이어그램

---

## B2. 아키텍처

### Wiki: `docs/wiki/system-architecture.md`

**제목**: 시스템 아키텍처 레퍼런스

**내용 구성**:
1. **서론** (300자): 5-Tier 아키텍처 개요와 설계 원칙
2. **5-Tier 구조** (800자): Core, Runtime, Interfaces, Infra, Release 계층별 책임
3. **디렉토리 맵** (500자): 각 계층별 디렉토리 구조와 파일 위치
4. **설계 원칙** (600자): 심링크 금지, `$HERMES_ROOT` 추상화, 이벤트 기반 통신
5. **이벤트 버스 개념** (500자): `event.sh` 단일 진입점의 아키텍처적 역할, JSONL 히스토리
6. **system-common 개념** (400자): mkdir atomic mutex, 공통 유틸리티의 위치
7. **안티패턴** (300자): 절대경로 하드코딩, 심링크 생성, 직접 스크립트 호출
8. **확장성** (200자): 수평적 확장, 모듈 간 느슨한 결합
9. **FAQ** (200자): 자주 묻는 질문 2-3개

**시작화**: 5-Tier 레이어 케이크 다이어그램, 디렉토리 트리 (Mermaid)

**실제 코드 필요**:
- `$HERMES_ROOT` 사용 예시
- `event.sh` 명령어
- 디렉토리 구조 텍스트 다이어그램

---

### Blog: `docs/blog/posts/architecture-5tier.md`

**제목**: 5계층 아키텍처: 왜 모듈화가 에이전트 시스템의 생존 조건인가

**내용 구성**:
1. **서론** (1,000자): 단단한 결합이 야기하는 시스템 취약성
2. **교착 상태 문제** (2,000자): 스크립트 간 직접 호출의 위험, 교착 상태 사례
3. **비동기 통신** (2,500자): 상태 파일 전송 방식과 `event.sh` 단일 진입점의 설계 철학
4. **5-Tier 분리** (2,000자): Core에서 Release로 수직 분리가 수평 확장을 가능하게 하는 메커니즘
5. **감사 추적성** (1,500자): JSONL 이벤트 히스토리의 디버깅 편의성
6. **향후 전망** (1,000자): 마이크로서비스 아키텍처와의 수렴, 모듈화 플랫폼의 진화

**시작화**: 레이어 케이크 다이어그램, 이벤트 버스 흐름도 (Mermaid)

---

### Slides: `docs/slides/decks/architecture.html`

**제목**: 아키텍처

**슬라이드 구성** (8~10장):
1. **타이틀**: "단단한 결합을 부수다" (후크)
2. **문제 정의**: 교착 상태와 결합도 문제
3. **해법**: 5-Tier 아키텍처
4. **핵심 개념 3**: 분리, 비동기, 확장
5. **Core 계층**: config, skills, AGENTS.md
6. **Runtime 계층**: cron, memory, state
7. **Interfaces 계층**: Telegram, Discord, CLI
8. **Infra/Release 계층**: GitHub, OpenRouter, GitHub Pages
9. **이벤트 버스**: event.sh, JSONL 히스토리
10. **요약**: 모듈화 아키텍처의 가치

**시작화**: 5-Tier 레이어 케이크, 이벤트 버스 광선 애니메이션

---

## 파일명 정리

| 도메인 | Wiki 파일명 | Blog 파일명 | Slides 파일명 |
|--------|------------|------------|---------------|
| A1. Workflow | `request-task.md` | `why-9-step-workflow.md` | `workflow-pipeline.html` |
| A2. Spec-Driven Dev | `spec-driven-dev.md` | `spec-driven-dev.md` | `spec-driven-dev.html` |
| A3. Content System | `content-system.md` | `content-system-design.md` | `content-system.html` |
| A4. Knowledge System | `knowledge-system.md` | `knowledge-system-design.md` | `knowledge-system.html` |
|| A5. Cron/Automation | `automation.md` | `cron-automation-design.md` | `cron-system.html` |
| A6. Model Routing | `model-routing.md` | `model-routing-design.md` | `model-routing.html` |
| B1. Hermes 개요 | `install.md` | `hermes-agent-intro.md` | `hermes-overview.html` |
|| B2. 아키텍처 | `system-architecture.md` | `architecture-5tier.md` | `architecture-5tier.html` |

---

## 도메인 간 중복 해결

### A5 (Cron) ↔ B2 (아키텍처)

| 항목 | A5 처리 | B2 처리 |
|------|---------|---------|
| `event.sh` | **사용법**: 명령어, 파라미터, 출력 예시 | **개념**: 아키텍처적 역할, 단일 진입점 설계 철학 |
| `system-common` | **유틸리티 함수**: 사용법, 예시 | **개념**: 위치, 목적, 설계 원칙 |
| `silent-on-success` | **설정 방법**: registry.yaml 파라미터 | — (B2에서 제외) |

---

## 문서 작성 순서 권장

1. **Wiki** (절차/레퍼런스) — 실제 코드와 시스템 상태 기반
2. **Blog** (철학/논증) — Wiki 내용 참조, 서사적 확장
3. **Slides** (시각화) — Wiki/Blog 내용 압축, 그래픽 중심

## Content System 파이프라인 적용

| 단계 | 도구 | 적용 범위 |
|------|------|-----------|
| 1. 초안 생성 | persona_generator.py | 모든 문서 |
| 2. 톤 조정 | tone-adapter.py | 모든 문서 |
| 3. 정서 추가 | emotion_merger.py | Blog만 |
| 4. 검증 L1-L4 | validator.py | 모든 문서 |
| 5. 검증 L5 | Judge Model | Blog만 |

## 부정대조 패턴 검출 규칙

`anti-slop-library.json`에 다음 패턴 추가:
- `~대신 ~을 사용` → **적극적 서술로 재구성** (`~을 사용`)
- `~아니라 ~이다` → **적극적 서술로 재구성** (`~이다`)
- `~반면 ~이다` → **적극적 서술로 재구성** (`~이다`)
- `~반대로 ~이다` → **적극적 서술로 재구성** (`~이다`)

> **주의**: 단순 삭제가 아닌 문맥에 맞는 적극적 서술로 재구성해야 함.

## 명칭 통일 검증 규칙

- `Expression System` → `Content System` 강제 교정
- 모든 문서에서 `Content System` 명칭 사용 필수

---

## 부록: Slides(HTML) 디자인 스펙

> **전체 스펙 파일**: [slides-design-spec.md](./slides-design-spec.md) (1,818줄, HTML/CSS/JS 포함)
>
> 본 섹션은 핵심 규칙 요약입니다. 상세 코드는 위 파일 참조.

### 1. 디자인 철학

| 원칙 | 설명 |
|------|------|
| **Progressive Disclosure** | 한 슬라이드, 한 메시지. 정보 양 최소화 |
| **10-20-30 Rule** | 최대 10장, 20분 발표, 최소 30pt 본문 |
| **High Contrast** | 라이트 배경 + 짙은 텍스트, WCAG AA 이상 |
| **Grid-First** | CSS Grid 12컬럼 기반 레이아웃 |
| **No Decorative Noise** | 모든 시각 요소는 정보 전달에 기여 |

### 2. 색상 팔레트 (GitHub Light 기반)

```css
:root {
  /* 배경 */
  --bg-primary:   #ffffff;  /* 메인 배경 */
  --bg-secondary: #f6f8fa;  /* 카드/섹션 */
  --bg-tertiary:  #eaeef2;  /* 호버/인터랙션 */

  /* 텍스트 */
  --text-primary:  #1f2328;  /* 본문/타이틀 (15:1 대비) */
  --text-secondary:#656d76;  /* 보조 설명 */
  --text-muted:    #b0b5ba;  /* placeholder */

  /* 액센트 */
  --accent-primary:   #0969da;  /* 블루: 링크, 강조 */
  --accent-secondary: #1a7f37;  /* 그린: 성공, 완료 */
  --accent-warning:   #9a6700;  /* 옐로우: 경고 */
  --accent-danger:    #cf222e;  /* 레드: 오류 */
  --accent-purple:    #8250df;  /* 퍼플: Mermaid 노드 */
  --accent-orange:    #bc4c00;  /* 오렌지: 진행 중 */
  --accent-cyan:      #0891b2;  /* 사이안: 데이터 흐름 */

  /* 테두리/그림자 */
  --border-default:   #d0d7de;
  --shadow-sm: 0 1px 2px rgba(31, 35, 40, 0.1);
  --shadow-md: 0 4px 12px rgba(31, 35, 40, 0.12);
  --shadow-glow-blue: 0 0 20px rgba(9, 105, 218, 0.12);
}
```

### 3. 타이포그래피

**폰트 스택**:
- Sans: `Inter` → `Noto Sans KR` → 시스템 폰트
- Mono: `JetBrains Mono` → `Fira Code` → `SF Mono`

**크기 계층**:

| 역할 | CSS | px | 사용처 |
|------|-----|-----|--------|
| `--text-h1` | `3.0rem` | 48px | 슬라이드 타이틀 |
| `--text-h2` | `2.25rem` | 36px | 섹션 제목 |
| `--text-h3` | `1.75rem` | 28px | 하위 섹션 |
| `--text-body` | `1.25rem` | 20px | 본문 |
| `--text-small` | `1rem` | 16px | 보조 텍스트 |
| `--text-code` | `0.9rem` | 14.4px | 인라인 코드 |
| `--text-meta` | `0.8rem` | 12.8px | 페이지 번호 |

**규칙**:
- 한 줄당 최대 8단어 / 12자
- 한 슬라이드 텍스트 최대 6라인
- 헤딩 자간: `-0.02em`, 본문: `0`, 라벨: `0.05em`

### 4. 레이아웃 템플릿 (5종)

#### 4.1 타이틀 템플릿
```
┌─────────────────────────────────┐
│        p-hermes                 │
│       ───                       │
│       WORKFLOW                  │
│       REDEFINED                 │
│   핵심 시스템 재정의             │
│   2026.06 — v0.16.0            │
└─────────────────────────────────┘
```
- Grid: `place-items: center`, 단일 영역
- 프로젝트명 + 제목 + 부제목 + 메타 정보

#### 4.2 콘텐츠 템플릿
```
┌─────────────────────────────────┐
│  WORKFLOW ARCHITECTURE          │
│  ┌─────────────────────────┐    │
│  │ • 9단계 상태 머신        │    │
│  │ • 원자적 게이트          │    │
│  │ • 병렬 차단             │    │
│  └─────────────────────────┘    │
└─────────────────────────────────┘
```
- Grid: `1fr 2fr` (좌측 제목, 우측 본문)

#### 4.3 다이어그램 템플릿
```
┌─────────────────────────────────┐
│  STATE TRANSITION PIPELINE      │
│  ┌────────────────────────────┐ │
│  │    [Mermaid 다이어그램]    │ │
│  └────────────────────────────┘ │
│  상태 전이: 원자적 flock 기반   │
└─────────────────────────────────┘
```
- Grid: `auto 1fr auto` (상단 제목, 하단 풀너)
- 다이어그램 컨테이너: `bg-secondary` 배경, `8px` 둥근 모서리

#### 4.4 비교 템플릿
```
┌─────────────────────────────────┐
│  BEFORE vs. AFTER               │
│  ┌──────────────┬──────────────┐ │
│  │   BEFORE     │   AFTER      │ │
│  │  ─────────   │  ─────────   │ │
│  │  수동 승인    │  자동 게이트  │ │
│  │  직렬 처리    │  병렬 차단    │ │
│  └──────────────┴──────────────┘ │
└─────────────────────────────────┘
```
- Grid: `1fr 1fr`, 중앙 구분선 포함
- Before: `bg-primary` + `text-muted`, After: `bg-secondary` + `accent-primary`

#### 4.5 요약 템플릿
```
┌─────────────────────────────────┐
│  KEY TAKEAWAYS                  │
│  ┌────┐  ┌────┐  ┌────┐       │
│  │ 01 │  │ 02 │  │ 03 │       │
│  │ 상태 │  │ 게이트│  │ 원자성│       │
│  │ 머신 │  │ 체제 │  │        │       │
│  └────┘  └────┘  └────┘       │
│  Next: implementation guide     │
└─────────────────────────────────┘
```
- 3컬럼 카드, CTA 링크 포함
- 카드 hover: `border-color` + `glow-shadow` 효과

### 5. 그래픽 요소

**모서리 둥글기**:
- 카드/패널: `8px`
- 버튼/태그: `6px`
- 코드 블록: `6px`
- 원형 아이콘: `50%`
- 진행 바: `4px`

**그림자**:
- 카드 기본: `--shadow-sm`
- Hover: `--shadow-md`
- 모달: `--shadow-lg`
- 다이어그램: `--shadow-glow-blue`

**테두리**:
- 기본: `1px solid --border-default`
- 강조: `border-color: --accent-primary` + `--shadow-glow-blue`
- 상태별: `--accent-secondary` (성공), `--accent-warning` (경고), `--accent-danger` (오류)

**아이콘** (SVG 인라인, 1.5px 선두께):
- 체크: `--accent-secondary`
- 화살표: `--accent-primary`
- 경고: `--accent-warning`
- 오류: `--accent-danger`

**배지**:
- `inline-flex`, `6px` 둥근 모서리, `uppercase`
- 상태별: `--badge--success`, `--badge--warning`, `--badge--danger`, `--badge--info`

### 6. 애니메이션

| 효과 | 지속시간 | easing |
|------|----------|--------|
| 슬라이드 전이 | 400ms | `cubic-bezier(0.4, 0, 0.2, 1)` |
| fadeInUp (stagger) | 500ms | 동일 |
| Progressve disclosure | 350ms | `ease` |
| 카드 hover | 200ms | 동일 |

**stagger 지연**: 0.1s ~ 0.6s (0.1s 간격)

**접근성**: `prefers-reduced-motion: reduce` 시 모든 애니메이션 0.01ms로 축소

### 7. 슬라이드 구조 (CSS Grid)

```
┌──────────────────────────────────┐
│ <body>                           │
│  ┌────────────────────────────┐  │
│  │ <section class="slide">    │  │
│  │  <header> 타이틀          │  │
│  │  <main>  콘텐츠           │  │
│  │  <footer> 페이지 정보      │  │
│  │ </section>                 │  │
│  └────────────────────────────┘  │
│  <nav class="progress-bar">      │
│  </nav>                          │
└──────────────────────────────────┘
```

- `aspect-ratio: 16/9` 고정
- `header`: `auto`, `main`: `1fr`, `footer`: `auto`
- `padding`: `clamp(1.5rem, 3vw, 3rem)` 반응형

### 8. Mermaid 다이어그램 스타일

```javascript
mermaid.initialize({
  theme: 'default',
  themeVariables: {
    primaryColor: '#e1ecf4',
    primaryTextColor: '#1f2328',
    primaryBorderColor: '#8250df',
    lineColor: '#0891b2',
    background: 'transparent',
    nodeBkg: '#f6f8fa',
    clusterBkg: '#eaeef2',
    clusterBorder: '#d0d7de',
  },
  flowchart: { htmlLabels: true, curve: 'basis' },
});
```

**CSS 오버라이드**:
- `rx: 6px` 둥근 모서리
- `state-active`: `--accent-secondary` stroke + glow
- `state-blocked`: `--accent-danger` stroke
- `cluster`: 점선 테두리 (`stroke-dasharray: 4 4`)

### 9. 반응형

| 브레이크포인트 | 조건 | 변화 |
|---------------|------|------|
| 기본 | 모든 크기 | 16:9 고정 |
| `--tablet` | `≤1024px` | 패딩 축소, 비교→수직, 요약 3→2열 |
| `--mobile` | `≤768px` | 세로 스크롤 폴백, 1열 레이아웃 |

### 10. 페이지 네비게이션

**진행 바**:
- 하단 고정, `3px` 높이
- `linear-gradient(90deg, --accent-primary, --accent-purple)`

**페이지 번호**:
- 푸터 우측, `--text-meta` 크기
- `::before`로 4px 블루 도트 장식

**키보드**:
- `ArrowRight`/`Space`: 다음
- `ArrowLeft`/`Backspace`: 이전
- `Home`/`End`: 처음/마지막

**사이드바 점 네비**:
- 우측 고정, `4px` 너비
- `active`: `--accent-primary` + glow

### 11. HTML 템플릿 구조

```html
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>p-hermes: {제목}</title>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&family=JetBrains+Mono:wght@400;500&family=Noto+Sans+KR:wght@300;400;500;700&family=Noto+Sans+Mono+KR:wght@400;500&display=swap" rel="stylesheet">
  <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
  <link rel="stylesheet" href="./slides-spec.css">
</head>
<body>
  <div class="slides">
    <section class="slide layout-title slide--active" data-slide="1">...</section>
    <section class="slide layout-content" data-slide="2">...</section>
    ...
  </div>
  <nav class="progress-bar"><div class="progress-fill"></div></nav>
  <nav class="sidebar">...</nav>
  <script>/* Mermaid 초기화 + 네비게이션 */</script>
</body>
</html>
```

### 12. YAML 프런트매터 (HTML 주석 또는 별도 파일)

```yaml
---
id: DOC-{도메인}-slides
domain: {도메인명}
type: slides
title: "{제목}"
date: 2026-06-16
version: "1.0"
compatibility: v0.16.0
---
```

### 13. 링크 경로 규칙 (GitHub Pages 배포용)

| 링크 유형 | 형식 | 예시 |
|-----------|------|------|
| 동일 슬라이드 내 섹션 | `#section-id` | `#architecture` |
| 다른 매체 (Wiki/Blog) | `/docs/` 루트 기준 절대경로 | `/docs/wiki/guides/request-task.html` |
| GitHub 소스 파일 | `https://github.com/...` | `https://github.com/pheanor/p-hermes/blob/main/...` |
| 외부 URL | `https://` + `target="_blank" rel="noopener noreferrer"` | `https://mermaid.js.org` |

**핵심 규칙**:
- p-hermes 관련 링크는 GitHub Pages 절대 URL(https://pheanor-agent.github.io/p-hermes/...) 사용. 내부 문서 간 링크는 상대경로 사용.
- 외부 링크는 `rel="noopener noreferrer"` 필수
- `<base href="/p-hermes/">` 태그 활용 시 모든 상대경로 자동 처리
- 외부 링크는 `↗` 아이콘으로 시각적 구분

---

> **상세 코드**: [slides-design-spec.md](./slides-design-spec.md) 파일 참조 (CSS 전량, HTML 예시 5슬라이드, JavaScript 네비게이션)

---

## Contract

contract:
  precondition:
    - specs/active/SPEC-D01.md approved 상태
    - Content System Phase 3 엔진 구동 가능
    - anti-slop-library.json 존재
  postcondition:
    - 24개 문서 (8도메인×3매체) 작성 완료
    - 모든 문서 Content System Validator L1-L5 통과
    - 분량 기준 충족 (Wiki A도메인 3.5k+, Blog 10k+)
  invariant:
    - 문서 작성은 Content System 파이프라인 필수 경유
    - 부정대조 패턴 사용 금지
    - 링크 규칙 준수 (GitHub Pages 절대 URL)

### Preconditions
- specs/active/SPEC-D01.md approved 상태
- Content System Phase 3 엔진 구동 가능
- anti-slop-library.json 존재

### Postconditions
- 24개 문서 (8도메인×3매체) 작성 완료
- 모든 문서 Content System Validator L1-L5 통과
- 분량 기준 충족 (Wiki A도메인 3.5k+, Blog 10k+)

### Invariants
- 문서 작성은 Content System 파이프라인 필수 경유
- 부정대조 패턴 사용 금지
- 링크 규칙 준수 (GitHub Pages 절대 URL)

## Examples

examples:
  - name: Wiki 문서 작성
    command: python3 persona_generator.py --domain A1 --track wiki > draft.md && python3 tone-adapter.py --level D1 draft.md > toned.md && python3 validator.py validate toned.md
  - name: Blog 문서 작성
    command: python3 persona_generator.py --domain A1 --track blog > draft.md && python3 tone-adapter.py --level D1 draft.md > toned.md && python3 emotion_merger.py toned.md > emotional.md && python3 validator.py validate emotional.md

### Example 1: Wiki 문서 작성
```bash
# persona_generator.py로 초안 생성
python3 persona_generator.py --domain A1 --track wiki > draft.md
# tone-adapter.py로 톤 조정
python3 tone-adapter.py --level D1 draft.md > toned.md
# validator.py로 검증 (L1-L4)
python3 validator.py validate toned.md
```

### Example 2: Blog 문서 작성
```bash
# persona_generator.py로 초안 생성
python3 persona_generator.py --domain A1 --track blog > draft.md
# tone-adapter.py로 톤 조정
python3 tone-adapter.py --level D1 draft.md > toned.md
# emotion_merger.py로 정서 추가 (Blog만)
python3 emotion_merger.py toned.md > emotional.md
# validator.py로 검증 (L1-L5, Blog는 L5 포함)
python3 validator.py validate emotional.md
```

## Acceptance Criteria
Given: 24개 문서 작성 완료
When: Content System Validator 전체 통과 확인
Then: 모든 문서 L1-L4 (Wiki) 또는 L1-L5 (Blog) 통과
---

_이 명세서는 p-hermes 문서 집필의 요구사항을 정의한다. 실제 작성 시 Content System 파이프라인을 통해 검증을 통과한 후 배포한다._
