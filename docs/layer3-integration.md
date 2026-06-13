# Layer 3: Integration & Output (연동 및 출력)

Hermes Agent의 외부 시스템 연동 및 콘텐츠 출력 계층입니다.

---

## 구성 요소

| 구성 요소 | 역할 | 주요 도구 |
|-----------|------|-----------|
| **Messaging Platform** | Telegram/Discord 연동 | `send_message` |
| **Image Generation** | 로컬/클라우드 이미지 생성 | ComfyUI, OpenRouter |
| **Content Creation** | 문서/소설/크리에이티브 출력 | Novel, ASCII, HTML |

---

## 1. Messaging Platform

### 1.1 Telegram 연동

| 기능 | 설명 |
|------|------|
| 채널별 라우팅 | 채널 ID 기반 메시지 라우팅 |
| 그룹 채팅 | 그룹 내 메시지 처리 |
| 파일 첨부 | 미디어 파일 전송 |

### 1.2 Discord 연동

| 기능 | 설명 |
|------|------|
| 쓰레드별 타겟팅 | 특정 쓰레드에 메시지 전송 |
| 홈 채널 | 기본 출력 채널 |
| 미디어 첨부 | 이미지/오디오 네이티브 전송 |

### 1.3 메시지 도구

`send_message` 도구를 통해 플랫폼 간 통일된 메시지 전송:

```
Hermes Engine
     │
     ├── send_message(platform="telegram", channel="...", content="...")
     ├── send_message(platform="discord", thread="...", content="...")
     └── send_message(platform="discord", channel="home", content="...")
```

---

## 2. Image Generation

### 2.1 ComfyUI (로컬)

로컬 GPU에서 이미지 생성 파이프라인을 실행합니다.

| 기능 | 설명 |
|------|------|
| 워크플로우 기반 | 노드 기반 이미지 파이프라인 |
| 배치 처리 | 여러 이미지 동시에 생성 |
| GPU 관리 | 로컬 GPU 리소스 사용 |

### 2.2 OpenRouter 이미지 모델 (클라우드)

클라우드 기반 이미지 모델을 사용합니다.

| 모델 | 특징 |
|------|------|
| Flux.2 | 고화질 이미지 생성 |
| Seedream | 스타일 기반 생성 |

### 2.3 큐 관리

| 기능 | 설명 |
|------|------|
| 배치 처리 | 대기 큐에 요청 저장 |
| 그룹 격리 | 사용자별 큐 분리 |
| 우선순위 |緊急 작업 우선 처리 |

### 2.4 라우팅 논리

```
이미지 요청
  → ComfyUI가 가동 중인가?
    → Yes → ComfyUI로 전송
    → No  → OpenRouter 이미지 모델로 폴백
```

---

## 3. Content Creation

### 3.1 Novel Writing

웹소설 연재 구조를 지원합니다.

```
novels/
├── series-1/
│   ├── ep001.md   # 1화
│   ├── ep002.md   # 2화
│   └── ...
├── series-2/
│   └── ...
└── ... (9개 시리즈)
```

**구조:**
- 시리즈 → 화 → 장 → 편
- 메타데이터 (제목, 요약, 태그)
- 연재 일정 관리

### 3.2 Creative Content

| 유형 | 설명 |
|------|------|
| ASCII Art | 텍스트 기반 아트 |
| 인포그래픽 | 데이터 시각화 |
| 슬라이드 | 세미나 발표 자료 (HTML) |

### 3.3 Document Generation

| 포맷 | 도구/방법 |
|------|----------|
| PowerPoint | Python pptx 라이브러리 |
| PDF | WeasyPrint / ReportLab |
| HTML | 직접 생성 |

---

## 4. Express System (표현력 시스템)

### 4.1 구조

- **SSOT**: `SKILL.md`
- **경로**: `skills/custom/expression-system/`
- **라우팅**: 콘텐츠 유형별 모델 매핑
- **연계**: D5 이미지 → ComfyUI 자동 라우팅

### 4.2 콘텐츠 라우팅

```
콘텐츠 유형 감지
  ├── 이미지 요청  → D5 모델 선택 → ComfyUI/OpenRouter
  ├── 텍스트 작성  → Qwen3.6 / Claude
  ├── 코드 생성    → Qwen3.6
  └── 분석/요약    → Claude-Sonnet
```

---

## 계층 간 인터페이스

### Layer 3 ← Layer 1

| 인터페이스 | 설명 |
|-----------|------|
| 워크플로우 출력 | execution/test 단계 결과 출력 |
| 모델 호출 | 이미지 모델 API 호출 |

### Layer 3 ← Layer 2

| 인터페이스 | 설명 |
|-----------|------|
| 자동 알림 | Cron 완료 시 메시지 전송 |
| 지식 기반 콘텐츠 | Wiki 데이터 → 콘텐츠 생성 |

---

## 참조

- [ARCHITECTURE.md](../ARCHITECTURE.md) — 전체 아키텍처
- [docs/systems/deploy.md](systems/deploy.md) — 배포 시스템 심화
