# 🧪 Playground 실험 일지

> 이 파일은 Playground에서 진행한 모든 실험의 변경 이력을 기록합니다.

---

## 초기 상태

- **생성일**: 2026-06-20
- **기반**: JOB-1696 Round 7 운영 슬라이드 복사본
- **JOB**: JOB-1733

---

## 실험 규칙

1. 각 실험은 `experiments/exp-NNN-[이름].md` 형식으로 기록
2. `_manifest.json`에 실험 메타데이터 등록
3. 실험 완료 후 운영 반영 여부 결정
4. 운영 반영 시 `slides/`에 별도 수정

---

## 실험 목록

| ID | 제목 | 상태 | 적용 버전 | 일시 |
|----|------|------|-----------|------|
| exp-001 | GPT Slide Content & Design Review | ✅ active | v3 | 2026-06-20 16:00 |
| exp-002 | GPT Design Review (content-system v2) | ✅ active | v3 | 2026-06-20 16:37 |
| exp-003 | GPT Design Review v2 (content-system v3) | ✅ active | v3 | 2026-06-20 17:05 |
| exp-004 | Hero Slide direction-guide 적용 | ✅ active | v2 | 2026-06-20 17:40 |
| exp-005 | Golden Circle Hero + WHY | ✅ active | v2 | 2026-06-20 17:42 |
| exp-006 | Golden Circle 전체 6단계 흐름 | ✅ active | v2 | 2026-06-20 17:45 |

---

## 버전 이력

### v3 — GC Refined (최신)
- **커밋**: `5850a13` (2026-06-20 22:15)
- **JOB**: JOB-1736 (UI/UX 개선) + JOB-1737 (콘텐츠 정정)
- **주요 변경**: 페이지 분할(12~15), 중앙 정렬, 듀얼→바닐라, WF 실제 반영, 모델명 추상화, 종료 페이지

### v2 — Golden Circle (구버전)
- **커밋**: `ba127e4` (2026-06-20 18:16)
- **JOB**: JOB-1734
- **주요 변경**: 8개 운영 슬라이드 Golden Circle 변환, direction-guide 최초 적용

> 버전 비교: [compare.html](compare.html)에서 v2 vs v3 side-by-side 확인 가능
