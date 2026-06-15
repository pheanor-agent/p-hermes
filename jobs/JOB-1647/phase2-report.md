# JOB-1647 Phase 2 완료 보고서

**완료일**: 2026-06-15  
**상태**: ✅ 완료  

---

## 문제 진단

### 증상
- GitHub Pages: https://pheanor-agent.github.io/p-hermes/ 접속 시 "404 Page not found"
- 로컬 `python3 -m http.server 8080`에서는 정상 작동

### 근본 원인
1. **Jekyll 빌드 에러**: GitHub Pages는 `docs/index.md` 파일에서 `layout: default` front matter를 읽으려 했지만, `_layouts/default.html` 파일이不存在하여 빌드 실패
2. **docs/ 폴더 삭제**: 이전 커밋에서 `docs/` 폴더가 삭제됨 → Jekyll이 빈 소스로 빌드

---

## 해결

### 1. docs/ 폴더 복원
- `blog/`, `slides/`, `wiki/` 폴더를 `docs/` 하위로 복사
- GitHub Pages는 `docs/`를 소스로 사용하므로, blog/slides/wiki도 `docs/` 안에 있어야 함

### 2. Jekyll 빌드 스킵
- `docs/.nojekyll` 파일 생성 → Jekyll 빌드 스킵, 정적 파일 직접 서빙
- 모든 `.md` 파일을 `.html`로 복사 (GitHub Pages에서 `.md`는 렌더링 안됨)

### 3. 링크 수정
- 절대 경로 (`/blog/`) → 상대 경로 (`../blog/`)로 변환
- 프로젝트 홈 링크, 시스템 문서 링크, wiki 링크 등 모두 상대 경로로 업데이트

---

## 결과

| 페이지 | URL | 상태 |
|--------|-----|------|
| 프로젝트 홈 | https://pheanor-agent.github.io/p-hermes/ | ✅ |
| 시스템 문서 | https://pheanor-agent.github.io/p-hermes/systems/overview.html | ✅ |
| Blog | https://pheanor-agent.github.io/p-hermes/blog/ | ✅ |
| Slides | https://pheanor-agent.github.io/p-hermes/slides/ | ✅ |
| Wiki | https://pheanor-agent.github.io/p-hermes/wiki/ | ✅ |

---

## 커밋 이력

1. `abb1bc7` fix(JOB-1647): docs/ 폴더 복원 - GitHub Pages 소스 구조 유지
2. `985418d` feat(JOB-1647): docs/에 blog, slides, wiki 통합 - GitHub Pages 단일 소스
3. `4b4348c` fix(JOB-1647): .nojekyll 추가, .md→.html 복사 - Jekyll 빌드 스킵

---

## 다음 단계

### 권장: build-system.sh 업데이트
- 현재 `build-system.sh`는 루트 레벨 `blog/`, `slides/`, `wiki/`를 빌드
- `docs/` 하위로 빌드 대상 변경 필요

### 권장: GitHub Actions 연동
- 푸시 시 자동 빌드 + GitHub Pages 배포
- 테스트 환경에서 미리 빌드 검증

---

## 참고

- GitHub Pages 설정: `main` 브랜치 `/docs` 폴더를 소스로 사용
- 빌드 타입: `legacy` (Jekyll)
- `.nojekyll` 존재 시 Jekyll 스킵, 정적 파일 직접 서빙
