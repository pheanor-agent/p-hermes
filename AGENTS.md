# p-hermes 프로젝트

## Scope
Hermes Agent 시스템 문서화 및 GitHub Pages 배포.

## Spec 연동
- specs/active/SPEC-D01.md — 문서 구조 (SSOT)
- specs/active/SPEC-D02.md — GitHub Pages 배포
- specs/active/SPEC-D03.md — Expression D1 연동 가이드라인

## 배포
```bash
bash src/deploy.sh  # 링크 검증 → llms.txt 재생성 → git push
```

## 검증
```bash
bash tests/validate-links.sh  # 링크 검증
```

## 규칙
- docs/ 변경 → SPEC-D01 구조 준수 → validate-links.sh → deploy.sh
- 내용 변경 시 Spec 먼저 검토 (직접 docs/ 수정 시 invariant 위반 가능성)
- llms.txt/llms-full.txt → deploy.sh 실행 시 자동 재생성
