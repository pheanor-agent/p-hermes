# GitHub Pages Deployment Checklist

## 전제 조건
- Public 리포지토리 (Private 리포는 GitHub Free 플랜에서 Pages 불가)
- `gh-pages` 브랜치 또는 `docs/` 폴더 설정
- GitHub CLI (`gh`) 로그인 상태

## 배포 프로세스

### 1. 로컬 파일 작성
```bash
# slides.html 작성
write_file docs/slides.html
```

### 2. main 브랜치 커밋
```bash
git add docs/slides.html
git commit -m "feat: 슬라이드 업데이트"
git push origin main
```

### 3. gh-pages 브랜치 업데이트
```bash
# orphan 브랜치 생성 (실패 시 기존 브랜치 확인)
git checkout --orphan gh-pages-temp 2>/dev/null || {
  git branch -D gh-pages-temp 2>/dev/null
  git checkout --orphan gh-pages-temp
}

# 작업 디렉토리 정리
git rm -rf .

# 파일 복사
git checkout main -- docs/slides.html
mv docs/slides.html index.html
rm -rf docs/

# 커밋 & 푸시
git add index.html
git commit -m "gh-pages: 슬라이드 배포"
git push origin gh-pages --force

# main으로 복귀
git checkout main
```

### 4. 브랜치 정리
```bash
git branch -D gh-pages-temp 2>/dev/null
```

## 검증

### 1. 파일 존재 확인
```bash
ls -la docs/slides.html
git ls-files gh-pages:index.html
```

### 2. GitHub Pages 상태 확인
```bash
# 1분 대기 (CDN 캐시 반영 시간)
sleep 60

# HTTP 상태 확인
curl -sI https://{owner}.github.io/{repo}/ | head -3

# 캐시 무효화 (쿼리 파라미터)
curl -s "https://{owner}.github.io/{repo}/?t=$(date +%s)" | head -5
```

### 3. 브라우저 테스트
```python
# browser_navigate로 실제 페이지 확인
# 슬라이드 수, 네비게이션, 팝업 기능 테스트
```

## 흔한 에러

### 브랜치 오염
- **증상**: main 브랜ちに gh-pages 커밋이 포함됨
- **해결**: `git reset --hard <correct-commit>`

### 파일 누락
- **증상**: `docs/slides.html` 존재하지 않음
- **해결**: `git checkout main -- docs/slides.html`

### CDN 캐시
- **증상**: 변경사항이 즉시 반영 안 됨
- **해결**: 1분 대기 + 쿼리 파라미터 `?t=timestamp`

### gh-pages 브랜치 충돌
- **증상**: `fatal: a branch named 'gh-pages-temp' already exists`
- **해결**: `git branch -D gh-pages-temp` 후 재시도

## 워크플로우 준수
- [ ] 설계 문서 작성
- [ ] 실행 (파일 작성)
- [ ] **브라우저 테스트** (1분 대기)
- [ ] 리뷰 (슬라이드 수/구성 확인)
- [ ] 완료 선언
- [ ] 작업 이력 기록 (`execution.md`)
