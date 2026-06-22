1|<div align="center">
2|
3|# ⚡ p-hermes
4|
5|**Persistent AI Agent Framework**
6|
7|**Memory** · **Workflow** · **Knowledge** · **Projects** · **Content**
8|
9|<br>
10|
11|설치하면 대화가 끝나도 잊지 않고, 작업 단위로 관리하며, 지식을 축적하는 AI 에이전트를 쓸 수 있습니다.
12|
13|<br>
14|
15|[![Quick Start](https://img.shields.io/badge/⚡_Quick_Start-2EA043?style=for-the-badge)](#-quick-start)
16|[![Wiki](https://img.shields.io/badge/📘_Guide_Wiki-58A6FF?style=for-the-badge)](https://github.com/pheanor-agent/p-hermes/blob/main/docs/wiki/index.md)
17|[![Blog](https://img.shields.io/badge/✍️_Dev_Blog-D2A8FF?style=for-the-badge)](https://github.com/pheanor-agent/p-hermes/blob/main/docs/blog/index.md)
18|[![Slides](https://img.shields.io/badge/🖼️_Slides-3FB950?style=for-the-badge)](https://github.com/pheanor-agent/p-hermes/blob/main/docs/slides/index.md)
19|
20|</div>
21|
22|---
23|
24|## ⚡ Quick Start
25|
26|```bash
27|git clone https://github.com/pheanor-agent/p-hermes.git
28|cd p-hermes && bash setup.sh
29|```
30|
31|자세한 설치는 [📘 설치 가이드](https://github.com/pheanor-agent/p-hermes/blob/main/docs/wiki/getting-started/install.md) 참고.
32|
33|---
34|
35|## 🎯 실제 이렇게 씁니다
36|
37|| 시나리오 | 흐름 |
38||----------|------|
39|| 🔍 **설계 문서 리뷰** | "이 문서 검토해줘" → **JOB 생성** → **Investigation** → **Architecture** → **Review** → **Knowledge 저장** → **Result** |
40|| 🎨 **슬라이드 생성** | "이 내용을 슬라이드로 만들어줘" → **Content System** → **생성** → **검증** → **Knowledge 축적** |
41|
42|---
43|
44|## 📖 문서 탐색
45|
46|p-hermes 문서는 **3-Track 구조**로 구성되어 있습니다.
47|
48|| Track | 역할 | 읽는 곳 | 내용 |
49||:-----:|:----:|:--------:|------|
50|| 📘 **Guide Wiki** | **How** | GitHub 소스뷰어 | 설치부터 고급 기능까지 단계별 가이드 |
51|| ✍️ **Dev Blog** | **Why** | GitHub 소스뷰어 | 설계 철학과 기술적 결정 이유 |
52|| 🖼️ **Slides** | **What** | GitHub Pages | 시스템 구조 시각화 — 발표용 HTML 슬라이드 |
53|
54|### 빠른 링크
55|
56|| 문서 | 링크 |
57||------|:----:|
58|| 📘 Guide Wiki | [전체 목록](https://github.com/pheanor-agent/p-hermes/blob/main/docs/wiki/index.md) |
59|| ✍️ Dev Blog | [전체 목록](https://github.com/pheanor-agent/p-hermes/blob/main/docs/blog/index.md) |
60|| 🖼️ **Slides** | [전체 목록](https://github.com/pheanor-agent/p-hermes/blob/main/docs/slides/index.md) |
61|
62|---
63|
64|## 🔧 핵심 기능
65|
66|| 기능 | 설명 |
67||------|------|
68|| **🧠 Memory** | 에이전트가 사용자를 기억합니다. 대화가 끝나도 선호도, 환경 정보, 프로젝트 컨텍스트가 유지됩니다. |
69|| **⚙️ Workflow Gate** | 모든 작업이 9단계 품질 게이트(Request → Investigation → Design → Review → Execution → Test → Done)를 통과합니다. |
70|| **📚 Knowledge** | 지식을 구조화하고 점수화합니다. AI가 학습한 내용을 영속적으로 저장하고 검색할 수 있습니다. |
71|| **📋 Jobs** | 작업을 단위로 관리합니다. 추적 가능하고, 재현 가능하며, 검증된 품질을 보장합니다. |
72|| **🔧 Content** | 표현 품질을 자동 검증합니다. 도메인별(D2~D5)로 최적화된 콘텐츠를 생성합니다. |
73|
74|---
75|
76|## 🏗️ 시스템 아키텍처
77|
78|```
79|p-hermes/
80|├── core/scripts/     ← 24개 실행 스크립트 (JOB, 백업, 알림 등)
81|├── core/skills/      ← 4개 커스텀 스킬 (Workflow, Content, Cron, Knowledge)
82|├── docs/             ← 문서 (Wiki + Blog + Slides)
83|├── examples/         ← 실제 Job 사례 5종
84|├── setup.sh          ← 설치 스크립트
85|└── tests/            ← 검증 스크립트
86|```
87|
88|---
89|
90|## 📋 실제 작업 사례
91|
92|| # | 사례 | 설명 |
93||:-:|------|------|
94|| 1 | [🔍 설계 리뷰](https://github.com/pheanor-agent/p-hermes/blob/main/examples/design-review/result.md) | 설계 문서 요청 → JOB → 검토 → Knowledge 저장 |
95|| 2 | [🎨 슬라이드 생성](https://github.com/pheanor-agent/p-hermes/blob/main/examples/slide-generation/result.md) | Content System으로 슬라이드 자동 생성 |
96|| 3 | [✍️ 블로그 작성](https://github.com/pheanor-agent/p-hermes/blob/main/examples/blog-creation/result.md) | 아이디어 → 블로그 포스트 → Wiki 동기화 |
97|| 4 | [📚 Knowledge 축적](https://github.com/pheanor-agent/p-hermes/blob/main/examples/knowledge-management/result.md) | 뉴스 분석 → Knowledge 저장 → 검색 |
98|| 5 | [📦 프로젝트 관리](https://github.com/pheanor-agent/p-hermes/blob/main/examples/project-management/result.md) | 신규 프로젝트 생성 → 첫 JOB 등록 |
99|
100|---
101|
102|## 🚀 시작하기
103|
104|1. **설치**: `git clone && bash setup.sh`
105|2. **설정**: `~/.hermes/config.yaml`에서 API 키 설정
106|3. **실행**: `hermes start`
107|4. **첫 작업**: Hermes에게 "이 설계 문서를 리뷰해줘" 라고 말해보세요
108|
109|> 더 자세한 내용은 [📘 Wiki](https://github.com/pheanor-agent/p-hermes/blob/main/docs/wiki/index.md)에서 확인하세요.
110|
111|---
112|
113|<div align="center">
114|  <br>
115|  <a href="https://github.com/pheanor-agent/p-hermes">📦 GitHub Repository</a>
116|  ·
117|  <a href="https://github.com/pheanor-agent/p-hermes/blob/main/docs/wiki/index.md">📘 Wiki</a>
118|  ·
119|  <a href="https://github.com/pheanor-agent/p-hermes/blob/main/docs/blog/index.md">✍️ Blog</a>
120|  ·
121|  <a href="https://github.com/pheanor-agent/p-hermes/blob/main/docs/slides/index.md">🖼️ Slides</a>
122|  <br><br>
123|  Built with Hermes Agent
124|</div>
125|