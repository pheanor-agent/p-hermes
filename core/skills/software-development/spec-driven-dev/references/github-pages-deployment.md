# GitHub Pages 배포 가이드

## gh CLI로 Pages 활성화

### ❌ 실패 패턴 (gh api --field)
```bash
# JSON 인코딩 문제 — escaping 오류
gh api repos/owner/repo/pages --method POST \
  --field source='{"branch":"gh-pages","path":"/"}'
# → "Invalid property /source: is not of type object"
```

### ✅ 올바름 (curl + API Version 헤더)
```bash
curl -s -X POST \
  -H "Authorization: token $(gh auth token)" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/owner/repo/pages \
  -d '{"source":{"branch":"gh-pages","path":"/"}}'
```

**핵심**: `X-GitHub-Api-Version: 2022-11-28` 헤더 필수. 없으면 422 에러.

## Private 리포지토리 + GitHub Pages

### 제한사항
- **Free plan**: Public 리포지만 Pages 지원
- **Private 리포**: Pro/Team/Enterprise 필요

### 해결: 리포 공개화
```bash
# ❌ --public 플래그 없음
gh repo edit owner/repo --public
# → unknown flag: --public

# ✅ visibility 플래그 사용
gh repo edit owner/repo --visibility public --accept-visibility-change-consequences
```

## gh-pages 브랜치 생성 (orphan 방식)

```bash
cd /path/to/project

# 1. orphan 브랜치 생성 (히스토리 분리)
git checkout --orphan gh-pages
git rm -rf .

# 2. 배포 파일 복사
cp docs/slides.html index.html  # 또는 다른 진입점

# 3. 커밋 + 푸시
git add index.html
git commit -m "gh-pages: 배포"
git push origin gh-pages

# 4. 메인 브랜치 복귀
git checkout main
```

**⚠️ 함정**: `git checkout --orphan`은 모든 파일을 작업트리에서 삭제. 푸시 전 백업 확인 필수.

## Pages 상태 확인

```bash
gh api repos/owner/repo/pages | python3 -m json.tool
# html_url 필드 확인: https://owner.github.io/repo/
```

## 배포 URL 패턴

| 브랜치 | URL |
|--------|-----|
| gh-pages (repo) | `https://owner.github.io/repo/` |
| main (user pages) | `https://owner.github.io/` |
