# GitHub Pages API 제약 (JOB-1545/1553 학습)

## 문제
GitHub Pages API가 `main` 브랜치를 소스로 지원하지 않음.

## 허용 값
- `gh-pages`
- `master`
- `master /docs`

## 해결 방법
1. `main` → `master` rename: `git branch -m main master`
2. 푸시: `git push origin master --force`
3. Pages 설정 변경: `gh api repos/{owner}/{repo}/pages --method PUT --field build_type="legacy" --field source='master'`

## 참고
- GitHub 웹 UI에서 default branch 변경 필요
- `remotes/origin/main` 삭제: `git remote prune origin`
