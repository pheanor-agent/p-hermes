<div align="center">

# ⚡ p-hermes

**Persistent AI Agent Framework**

**Memory** · **Workflow** · **Knowledge** · **Projects** · **Content**

<br>

설치하면 대화가 끝나도 잊지 않고, 작업 단위로 관리하며, 지식을 축적하는 AI 에이전트를 쓸 수 있습니다.

<br>

[![Quick Start](https://img.shields.io/badge/⚡_Quick_Start-2EA043?style=for-the-badge)](#-quick-start)
[![Wiki](https://img.shields.io/badge/📘_Guide_Wiki-58A6FF?style=for-the-badge)](https://github.com/pheanor-agent/p-hermes/blob/main/docs/wiki/index.md)
[![Blog](https://img.shields.io/badge/✍️_Dev_Blog-D2A8FF?style=for-the-badge)](https://github.com/pheanor-agent/p-hermes/blob/main/docs/blog/index.md)
[![Slides](https://img.shields.io/badge/🖼️_Slides-3FB950?style=for-the-badge)](https://github.com/pheanor-agent/p-hermes/blob/main/docs/slides/index.md)

</div>

---

## ⚡ Quick Start

```bash
git clone https://github.com/pheanor-agent/p-hermes.git
cd p-hermes && bash setup.sh
```

자세한 설치는 [📘 설치 가이드](https://github.com/pheanor-agent/p-hermes/blob/main/docs/wiki/getting-started/install.md) 참고.

---

## 🎯 실제 이렇게 씁니다

| 시나리오 | 흐름 |
|----------|------|
| 🔍 **설계 문서 리뷰** | "이 문서 검토해줘" → **JOB 생성** → **Investigation** → **Architecture** → **Review** → **Knowledge 저장** → **Result** |
| 🎨 **슬라이드 생성** | "이 내용을 슬라이드로 만들어줘" → **Content System** → **생성** → **검증** → **Knowledge 축적** |

---

## 📖 문서 탐색

p-hermes 문서는 **3-Track 구조**로 구성되어 있습니다.

| Track | 역할 | 읽는 곳 | 내용 |
|:-----:|:----:|:--------:|------|
| 📘 **Guide Wiki** | **How** | GitHub 소스뷰어 | 설치부터 고급 기능까지 단계별 가이드 |
| ✍️ **Dev Blog** | **Why** | GitHub 소스뷰어 | 설계 철학과 기술적 결정 이유 |
| 🖼️ **Slides** | **What** | GitHub Pages | 시스템 구조 시각화 — 발표용 HTML 슬라이드 |

### 빠른 링크

| 문서 | 링크 |
|------|:----:|
| 📘 Guide Wiki | [전체 목록](https://github.com/pheanor-agent/p-hermes/blob/main/docs/wiki/index.md) |
| ✍️ Dev Blog | [전체 목록](https://github.com/pheanor-agent/p-hermes/blob/main/docs/blog/index.md) |
| 🖼️ **Slides** | [전체 목록](https://github.com/pheanor-agent/p-hermes/blob/main/docs/slides/index.md) |

---

## 🔧 핵심 기능

| 기능 | 설명 |
|------|------|
| **🧠 Memory** | 에이전트가 사용자를 기억합니다. 대화가 끝나도 선호도, 환경 정보, 프로젝트 컨텍스트가 유지됩니다. |
| **⚙️ Workflow Gate** | 모든 작업이 9단계 품질 게이트(Request → Investigation → Design → Review → Execution → Test → Done)를 통과합니다. |
| **📚 Knowledge** | 지식을 구조화하고 점수화합니다. AI가 학습한 내용을 영속적으로 저장하고 검색할 수 있습니다. |
| **📋 Jobs** | 작업을 단위로 관리합니다. 추적 가능하고, 재현 가능하며, 검증된 품질을 보장합니다. |
| **🔧 Content** | 표현 품질을 자동 검증합니다. 도메인별(D2~D5)로 최적화된 콘텐츠를 생성합니다. |

---

## 🏗️ 시스템 아키텍처

```
p-hermes/
├── core/scripts/     ← 24개 실행 스크립트 (JOB, 백업, 알림 등)
├── core/skills/      ← 4개 커스텀 스킬 (Workflow, Content, Cron, Knowledge)
├── docs/             ← 문서 (Wiki + Blog + Slides)
├── examples/         ← 실제 Job 사례 5종
├── setup.sh          ← 설치 스크립트
└── tests/            ← 검증 스크립트
```

---

## 📋 실제 작업 사례

| # | 사례 | 설명 |
|:-:|------|------|
| 1 | [🔍 설계 리뷰](https://github.com/pheanor-agent/p-hermes/blob/main/examples/design-review/result.md) | 설계 문서 요청 → JOB → 검토 → Knowledge 저장 |
| 2 | [🎨 슬라이드 생성](https://github.com/pheanor-agent/p-hermes/blob/main/examples/slide-generation/result.md) | Content System으로 슬라이드 자동 생성 |
| 3 | [✍️ 블로그 작성](https://github.com/pheanor-agent/p-hermes/blob/main/examples/blog-creation/result.md) | 아이디어 → 블로그 포스트 → Wiki 동기화 |
| 4 | [📚 Knowledge 축적](https://github.com/pheanor-agent/p-hermes/blob/main/examples/knowledge-management/result.md) | 뉴스 분석 → Knowledge 저장 → 검색 |
| 5 | [📦 프로젝트 관리](https://github.com/pheanor-agent/p-hermes/blob/main/examples/project-management/result.md) | 신규 프로젝트 생성 → 첫 JOB 등록 |

---

## 🚀 시작하기

1. **설치**: `git clone && bash setup.sh`
2. **설정**: `~/.hermes/config.yaml`에서 API 키 설정
3. **실행**: `hermes start`
4. **첫 작업**: Hermes에게 "이 설계 문서를 리뷰해줘" 라고 말해보세요

> 더 자세한 내용은 [📘 Wiki](https://github.com/pheanor-agent/p-hermes/blob/main/docs/wiki/index.md)에서 확인하세요.

---

<div align="center">
  <br>
  <a href="https://github.com/pheanor-agent/p-hermes">📦 GitHub Repository</a>
  ·
  <a href="https://github.com/pheanor-agent/p-hermes/blob/main/docs/wiki/index.md">📘 Wiki</a>
  ·
  <a href="https://github.com/pheanor-agent/p-hermes/blob/main/docs/blog/index.md">✍️ Blog</a>
  ·
  <a href="https://github.com/pheanor-agent/p-hermes/blob/main/docs/slides/index.md">🖼️ Slides</a>
  <br><br>
  Built with Hermes Agent
</div>