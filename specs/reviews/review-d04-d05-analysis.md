# SPEC-D04/D05 검토 분석 결과

> **작성일**: 2026-06-16
> **대상**: SPEC-D04 (문서 요구사항), SPEC-D05 (Slides 디자인)
> **참조**: SPEC-D01, SPEC-D02, SPEC-D03

---

## 1. 충돌 분석 (Conflict)

### C-01: 테마 충돌 (D03 vs D05) — ✅ 해결: 라이트 통일

| 항목 | SPEC-D03 §3.1 | SPEC-D05 §2 |
|------|---------------|-------------|
| 정의 | `라이트 테마 (흰 배경, 짙은 텍스트)` | `다크 테마 (#0d1117)` |

**해결**: D05 전체를 라이트 테마로 변경. 색상 변수 반전.

### C-02: 링크 규칙 충돌 (D03 vs D05) — ✅ 해결: GitHub Pages 절대 URL

| 항목 | SPEC-D03 §3.1 | SPEC-D05 §12 |
|------|---------------|-------------|
| 외부 링크 | `https://pheanor-agent.github.io/p-hermes/...` | `/docs/` 상대경로 (절대 URL 금지) |

**해결**: D03 §3.1과 D05 §12 모두 "GitHub Pages 웹 주소는 절대 URL, 내부 링크는 상대경로"로 통일.

### C-03: 분량 상향 (D03 vs D04) — 🟢 확장으로 판정

| 매체 | SPEC-D03 | SPEC-D04 | 비율 |
|------|----------|----------|------|
| Wiki | ≥ 1,500자 | ≥ 3,500자 | 2.3x |
| Blog | ≥ 3,000자 | ≥ 10,000자 | 3.3x |

**판정**: D03이 "최소 자립성 기준" 정의, D04가 "도메인별 요구사항"으로 상향.
의도적 `raises` 관계. `_matrix.json`에 기록됨.

**추가 결정**: 도메인별 차등 적용 (A/B 도메인별 상이한 분량).

---

## 2. 확장 분석 (Extension)

### E-01: D01 → D04 (도메인 확장)

| 항목 | D01 | D04 |
|------|-----|-----|
| 범위 | p-hermes 1개 프로젝트 | 8개 도메인 (A1~A6, B1, B2) |
| 문서 수 | 3트랙 구조만 정의 | 24개 문서 (8×3) |
| 분량 | 미정 | 정량화 (Wiki ≥ 3.5k, Blog ≥ 10k) |
| 프런트매터 | 미정 | 7필드 정의 (id, domain, type, title, date, version, compatibility) |
| 검증 | validate-links.sh | 체크리스트 + 분량 + 도표 포함 여부 |

### E-02: D03 → D04 (표준 정량화)

| 항목 | D03 | D04 |
|------|-----|-----|
| 어조 | D1 원칙 (개념적) | 5개 차원 점수화 (정량적) |
| 다이어그램 | Mermaid 필수 | ≥ 1개/문서 (정량화) |
| 분량 | Wiki ≥ 1.5k, Blog ≥ 3k | Wiki ≥ 3.5k, Blog ≥ 10k |

### E-03: D01 → D05 (Slides 구체화)

| 항목 | D01 | D05 |
|------|-----|-----|
| Slides 정의 | `slides/decks/` 디렉토리 | HTML/CSS/JS 전체 스펙 |
| 디자인 | 없음 | CSS 변수 40+개, 5종 템플릿 |
| 레이아웃 | 없음 | 타이틀, 콘텐츠, 다이어그램, 비교, 요약 |
| 네비게이션 | 없음 | 키보드 + 사이드바 + 진행바 |
| 애니메이션 | 없음 | fadeInUp, stagger, progressive disclosure |
| 반응형 | 없음 | 1024px/768px 브레이크포인트 |

---

## 3. 신규 발견 사항

### N-06: YAML 프런트매터 필드 불완전 (D04)

현재 7필드: `id, domain, type, title, date, version, compatibility`

추가 필요:
- `author` — 작성자 (에이전트/사용자 구분)
- `status` — draft | review | published
- `tags` — 검색/태그 기반 필터링
- `related_specs` — 관련 사양서 ID (SPEC-D01 등)
- `related_docs` — 교차 참조 문서 ID

### N-07: 버전 관리 규칙 누락

`version` 필드 포함 but 증가 규칙 미정의.

**제안**: semver (Major.Minor.Patch)
- Major: Breaking change (구조 변경)
- Minor: 기능 추가 (새 섹션, 새 도표)
- Patch: 수정 (오타, 링크 수정)

### N-08: 폰트 스택 한글 미로딩 (D05)

**문제**: Inter, JetBrains Mono는 한글 미지원. Noto Sans KR은 CSS 스택에 선언만, Google Fonts 로드 안 함.

**테스트 결과**:
- Noto Sans KR: Google Fonts ✅ (1,165B)
- Noto Sans Mono KR: Google Fonts ✅ (6,520B)

**해결**: HTML `<link>`에 Noto Sans KR + Noto Sans Mono KR 추가.

### N-09: D04 체크리스트 자동화 누락

D04 §7.3 체크리스트 수동 검증만 정의. 자동 스크립트 없음.

**판정**: D04 자체 Acceptance Criteria. SDD나 콘텐츠 시스템과 무관.
자동화 필요하지만 별도 스크립트 (`validate-docs.sh`)로 구현 권장.

### N-10: 10-20-30 Rule — ✅ 거짓 양성

D04(8~10장)와 D05(최대 10장) 일관. 예시 코드가 5장인 것만 샘플.
**이슈 아님.**

---

## 4. Blog 분류 분석

D01 정의: Blog = "Dev Blog — 왜 그렇게 설계했는가 (Why)"

8개 도메인 모두 Blog 적용 시:

| 도메인 | Blog 성격 | 예시 |
|--------|-----------|------|
| A1 Workflow | 기술적 Why | `why-9-step-workflow.md` |
| A2 Spec-Driven Dev | 기술적 Why | `why-spec-driven-dev.md` |
| A3 Hermes Agent Intro | 기술적 Why | `why-hermes-agent-architecture.md` |
| A4 Model Lifecycle | 기술적 Why | `why-model-routing.md` |
| A5 Model Routing | 기술적 Why | `model-routing-deep-dive.md` |
| A6 Cron System | 기술적 Why | `why-cron-3layer.md` |
| B1 Architecture | 기술적 Why | `why-5tier-architecture.md` |
| B2 Knowledge | 기술적 Why | `knowledge-system-evolution.md` |

**사용자 결정**: A3, B2도 기술 블로그로 구성. Blog는 단일 정체성 유지.

---

## 5. 슬라이드 글자수 분석

### 현재 제약
- 1줄당 최대 12자 (D05 §3.3)
- 1슬라이드 최대 6라인 (D05 §3.3)
- => 최대 본문 ~72자 (헤딩/캡션 제외)

### 하한 미정의 문제
현재 "Progressive Disclosure" 원칙상 텍스트 최소화 철학으로 하한 없음.
=> 과도한 미니멀리즘 가능성 (텍스트 1줄 + 빈 공간 슬라이드)

### 대안 3가지

| 대안 | 내용 |
|------|------|
| A | 라인 상한 6→8 확대 (~96자) |
| B | 최소 3라인 하한 정의 |
| C | 밀도 등급 3단계 (Light 2-4, Standard 4-6, Dense 6-8) + 도메인별 권장 |

**권장**: B + C 병행.

---

## 6. 수정 계획

### D03 수정
- [ ] §3.1 링크 규칙: "GitHub Pages 절대 URL 권장"으로 명확화

### D04 수정
- [ ] §2.1 Blog 정의: "모든 도메인 Blog = 기술 블로그" 명시
- [ ] §3 분량 테이블: 도메인별 차등 (A: 기술 심화, B: 시스템 통합)
- [ ] §2.1 프런트매터: author, status, tags, related_specs 추가
- [ ] §2.1 버전 규칙: semver 규칙 추가
- [ ] §7.3 검증: 자동화 스크립트 언급 추가 (선택)

### D05 수정
- [ ] §2 색상 팔레트: 다크→라이트 테마 전량 변경
- [ ] §3.1 폰트 스택: Noto Sans KR/Mono KR Google Fonts 로드
- [ ] §3.3 타이포그래피: 최소 3라인 + 밀도 등급 정의
- [ ] §8 Mermaid: 라이트 테마 변수로 변경
- [ ] §11 HTML 예시: 라이트 테마 적용
- [ ] §12 링크 규칙: GitHub Pages 절대 URL로 통일
- [ ] 부록 CSS: 라이트 테마로 변경

---

_분석 완료. 수정 진행 전 사용자 확인 대기._
