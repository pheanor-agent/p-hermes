# p-hermes

**Hermes Agent System — Architecture & Reference Documentation**

[![GitHub Pages](https://img.shields.io/badge/GitHub-Pages-blue)](https://pheanor-agent.github.io/p-hermes/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-orange)](CHANGELOG.md)

> Hermes Agent는 다중 LLM 프로바이더, 144+ 스킬, 9단계 워크플로우 파이프라인, 그리고 자동화 지능형 에이전트 플랫폼입니다. 이 리포지토리는 시스템의 **아키텍처와 설계 문서**를 공개합니다.

---

## Hermes는 무엇인가?

Hermes Agent는 다음과 같은 핵심 기능을 갖춘自律적 AI 에이전트 시스템입니다:

| 기능 | 설명 |
|------|------|
| **Multi-Provider** | OpenRouter, Airrouter, Anthropic 등 다중 LLM 제공사 지원, 자동 Fallback |
| **Skill System** | 144개 이상의 스킬, 30개 이상의 카테고리, 트리거 기반 자동 로딩 |
| **Workflow Pipeline** | 9단계 상태 머신, 체크포인트 검증 (I1~I16), 자동 전이 |
| **Knowledge System** | Wiki (T1/T2/T3 분류), References, Lessons 자동 생성, 뉴스 수집 |
| **Cron & Automation** | registry.yaml 기반 주기 작업 관리, no-agent 모드 |
| **Integration** | Telegram/Discord 메시징, 이미지 생성 (ComfyUI/OpenRouter), 콘텐츠 제작 |

---

## 3-Tier Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Hermes Agent System                          │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────┐   │
│  │           Layer 1: Core Engine (핵심 엔진)               │   │
│  │  Model & Provider  │  Skill System  │  Workflow Pipeline │   │
│  │  • Multi-provider  │  • 144+ skills│  • 9-step pipeline │   │
│  │  • Fallback        │  • 30+ cats   │  • I1~I16 checks   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │        Layer 2: Knowledge & State (지식 및 상태)          │   │
│  │  Knowledge System  │  Cron & Auto  │  Blackboard & Bridge│   │
│  │  • Wiki (T1/T2/T3)│  • Periodic   │  • Dual-agent      │   │
│  │  • References     │  • No-agent   │  • JOB management  │   │
│  │  • Lessons        │  • Registry   │  • State sharing   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │       Layer 3: Integration & Output (연동 및 출력)        │   │
│  │  Messaging Platform  │  Image Gen  │  Content Creation   │   │
│  │  • Telegram          │  • ComfyUI  │  • Novel writing    │   │
│  │  • Discord           │  • OpenRouter│ • Creative content │   │
│  │  • Channel routing   │             │  • Documents        │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 계층 요약

| 계층 | 역할 | 주요 구성 요소 |
|------|------|----------------|
| **Layer 1** | 핵심 처리 엔진 | 모델 라우팅, 스킬 관리, 워크플로우 상태 머신 |
| **Layer 2** | 지식 축적 & 상태 관리 | Wiki/T1-T3, Cron 자동화, 블랙보드 협업 |
| **Layer 3** | 외부 연동 & 출력 | 메시징, 이미지 생성, 콘텐츠 제작 |

---

## Quick Start

새 환경에서 Hermes를 초기화하려면 [PORTING.md](PORTING.md)를 참고하세요.

### 1. 디렉토리 구조 생성

```bash
mkdir -p ~/.hermes/{scripts,skills,hooks,plugins}
mkdir -p ~/.hermes/knowledge/{wiki,references,lessons,news}
mkdir -p ~/.hermes/cron/{backups,cache,history,output}
mkdir -p ~/.hermes/state/{hermes,openclaw}
mkdir -p ~/.hermes/workspace/{jobs,projects,novels,reports,research}
```

### 2. config.yaml 설정

```yaml
model:
  api_key: "${HERMES_API_KEY}"
  base_url: "https://api.airouter.ch/v1"
  default: "Qwen3.6"
  provider: custom
```

### 3. 검증

```bash
# 필수 파일/디렉토리 확인
test -f ~/.hermes/config.yaml && echo "✅ config.yaml"
test -f ~/.hermes/AGENTS.md && echo "✅ AGENTS.md"
test -d ~/.hermes/skills && echo "✅ skills/"
test -d ~/.hermes/knowledge/wiki && echo "✅ knowledge/wiki/"
test -d ~/.hermes/workspace/jobs && echo "✅ workspace/jobs/"
```

---

## Documentation

| 문서 | 설명 |
|------|------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | 3계층 아키텍처 전체 설명 + 다이어그램 |
| [PORTING.md](PORTING.md) | 새 환경 포팅 가이드 |
| [CHANGELOG.md](CHANGELOG.md) | 변경 로그 |

### Wiki (상세 참조)

| 문서 | 내용 |
|------|------|
| [docs/index.md](docs/index.md) | Wiki 인덱스 |
| [docs/layer1-core-engine.md](docs/layer1-core-engine.md) | Layer 1: Core Engine 상세 |
| [docs/layer2-knowledge-state.md](docs/layer2-knowledge-state.md) | Layer 2: Knowledge & State 상세 |
| [docs/layer3-integration.md](docs/layer3-integration.md) | Layer 3: Integration & Output 상세 |
| [docs/workflow-pipeline.md](docs/workflow-pipeline.md) | 9단계 파이프라인 |
| [docs/skill-system.md](docs/skill-system.md) | 스킬 시스템 |

### Systems (시스템별 심화)

| 문서 | 내용 |
|------|------|
| [docs/systems/overview.md](docs/systems/overview.md) | 시스템 종합 |
| [docs/systems/models.md](docs/systems/models.md) | 모델 시스템 |
| [docs/systems/knowledge.md](docs/systems/knowledge.md) | 지식 시스템 |
| [docs/systems/cron.md](docs/systems/cron.md) | 크론 시스템 |
| [docs/systems/backup.md](docs/systems/backup.md) | 백업 시스템 |
| [docs/systems/deploy.md](docs/systems/deploy.md) | 배포 시스템 |

---

## System Overview

| # | 시스템 | SSOT | 핵심 역할 |
|---|--------|------|-----------|
| 1 | **JOB** | `.workflow-state` | 9단계 워크플로우 상태 머신 |
| 2 | **Knowledge** | `wiki/index.md` | Wiki/T1-T3, References, Lessons |
| 3 | **Cron** | `registry.yaml` | 주기 작업 자동화 |
| 4 | **Model** | `catalog.json` | 다중 모델 라우팅, Fallback |
| 5 | **Backup** | N/A | Tier 1 (Hot) / Tier 2 (Warm) |
| 6 | **Deploy** | N/A | ComfyUI, GPU Health Check |
| 7 | **SpecDev** | `_index.yaml` | 사양서 검증, 체크포인트 |
| 8 | **Event Bus** | `event.sh` | 시스템 간 이벤트 발행/구독 |
| 9 | **Express** | `SKILL.md` | 표현력 시스템, 이미지 라우팅 |

---

## Core Statistics

| 항목 | 수 |
|------|-----|
| Scripts | 168개 |
| Skills | 144개 (30+ 카테고리) |
| Knowledge Wiki | 1,094 페이지 |
| Knowledge References | 210개 |
| Hooks | 4개 |
| Plugins | 5개 |
| Jobs | 714개 |
| Projects | 7개 |
| Config Lines | 881줄 |

---

## License

[MIT License](LICENSE) © 2026 Hermes Agent Contributors

---

## Disclaimer

이 리포지토리는 **시스템 아키텍처 문서화 용도**입니다. 실제 작업 데이터, 개인 정보, API 키는 포함되지 않습니다.
