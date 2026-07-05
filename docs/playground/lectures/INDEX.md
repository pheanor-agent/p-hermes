# p-hermes 강의 — Index

## 현재 버전: v4 (Slide Design System)

| 강의 | 슬라이드 | 프레임워크 | 링크 |
|------|---------|-----------|------|
| Lecture A — 왜 Agent OS인가? | 15장 | SCQA→Golden Circle | [v4/lecture-a-why-agent-os.html](v4/lecture-a-why-agent-os.html) |
| Lecture B — Memory vs Knowledge | 20장 | Progressive Disclosure | [v4/lecture-b-memory-knowledge.html](v4/lecture-b-memory-knowledge.html) |
| Lecture C — Architecture & Runtime | 20장 | Pyramid Principle | [v4/lecture-c-architecture-runtime.html](v4/lecture-c-architecture-runtime.html) |

---

## 버전 히스토리

| 버전 | 날짜 | 강의 | 슬라이드 | 위치 |
|------|------|------|---------|------|
| **v4** | 2026-07-05 | 3강 | 55장 | `v4/` |
| v1.9 | 2026-06-29 | 6강 | 98장 | `archive/v1.9/` |
| v1.0~v1.8 | 2026-06-23~24 | 4강 | 100장 | `archive/v1.0~v1.8/` |

---

## 폴더 구조

```
lectures/
├── INDEX.md              ← 이 파일
├── index.html            ← HTML 인덱스
├── SPEC-SLIDES.md        ← 슬라이드 명세
├── TEMPLATE.md           ← 템플릿
├── versions.json         ← 버전 메타데이터
│
├── v4/                   ← ✅ Current
│   ├── components/
│   │   └── slides-components-v5.css
│   ├── tests/
│   │   └── validate-slides.py
│   ├── lecture-a-why-agent-os.html
│   ├── lecture-b-memory-knowledge.html
│   └── lecture-c-architecture-runtime.html
│
└── archive/
    ├── v1.0/ ~ v1.8/     ← 초기 개발 이력
    ├── v1.9/             ← 6강 Gold+Dark
    ├── index.html
    └── versions.json
```

---

## 설계 문서

- JOB-2058 산출물: `~/.hermes/workspace/jobs/JOB-2058-*/p-hermes-slides-complete-deliverable.md`
- 전체 리뷰: 9.8/10 (pheanor 평가)
