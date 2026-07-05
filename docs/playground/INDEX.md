# p-hermes Playground — Index

## 개요

p-hermes Playground는 두 가지 카테고리를 관리합니다:

| 카테고리 | 위치 | 현재 버전 | 설명 |
|----------|------|----------|------|
| **운영 덱** | `ops/` | **v4** | Golden Circle 기반 8개 운영 슬라이드 |
| **강의** | `lectures/` | **v4** | 학습용 강의 시리즈 (Nord 테마) |

---

## 운영 덱 (Operations)

8개 운영 슬라이드 (workflow, cron, knowledge, architecture 등)

| 버전 | 상태 | 위치 | 설명 |
|------|------|------|------|
| **v4** | ✅ Current | `ops/v4/` | 운영 덱 Current |
| v3 | 📦 Archive | `ops/v3/gc/` | GC Refined |
| v2 | 📦 Archive | `ops/v2/gc/` | Golden Circle |

---

## 강의 (Lectures)

학습용 강의 시리즈

| 버전 | 상태 | 강의 | 슬라이드 | 위치 |
|------|------|------|---------|------|
| **v4** | ✅ Current | 3강 | 55장 | `lectures/v4/` |
| v1.9 | 📦 Archive | 6강 | 98장 | `lectures/archive/v1.9/` |
| v1.0~v1.8 | 📦 Archive | 4강 | 100장 | `lectures/archive/v1.0~v1.8/` |

---

## 폴더 구조

```
playground/
├── INDEX.md              ← 이 파일
├── index.html            ← 메인 HTML 인덱스
│
├── ops/                  ← 운영 덱
│   ├── versions.json
│   ├── v4/               ← ✅ Current
│   ├── v3/
│   └── v2/
│
└── lectures/             ← 강의
    ├── INDEX.md
    ├── index.html
    ├── SPEC-SLIDES.md
    ├── TEMPLATE.md
    ├── versions.json
    ├── v4/               ← ✅ Current (3강 55장)
    │   ├── components/
    │   ├── tests/
    │   ├── lecture-a-*.html
    │   ├── lecture-b-*.html
    │   └── lecture-c-*.html
    └── archive/
        ├── v1.0/ ~ v1.8/
        ├── v1.9/
        ├── index.html
        └── versions.json
```

---

## 버전 관리 규칙

1. **버전 번호**: 각 카테고리별 독립 numbering (ops/v4, lectures/v4)
2. **Current 마킹**: 현재 사용 중인 버전만 `v4/` 등의 최상위 폴더에
3. **Archive**: 이전 버전은 `archive/` 폴더로 이동
4. **versions.json**: 각 카테고리별로 버전 메타데이터 유지
