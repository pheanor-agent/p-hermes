# p-hermes GitHub Pages 문서화 워크플로우

**세션**: JOB-1542 (2026-06-13)
**리포**: pheanor-agent/p-hermes (public)

## 워크플로우 요약

Hermes 시스템 아키텍처를 GitHub Pages로 공개 배포하는 파이프라인.

## 단계

### 1. 리포 생성
```bash
gh repo create pheanor-agent/p-hermes --public --description "..."
cd ~/.hermes/workspace && git clone https://github.com/pheanor-agent/p-hermes.git
```

### 2. 필수 파일
- `.nojekyll` (빈 파일) — GitHub Pages에서 Jekyll 빌드 스킵
- `.gitignore` — node_modules, .DS_Store, Thumbs.db, *.tmp, *.swp, *.bak
- `LICENSE` — MIT License

### 3. 문서 구조
```
p-hermes/
├── README.md           # 시스템 개요 + Quick Start
├── ARCHITECTURE.md     # 3계층 아키텍처 다이어그램
├── PORTING.md          # 포팅 가이드
├── CHANGELOG.md        # 변경 로그
├── .nojekyll
├── .gitignore
├── LICENSE
└── docs/               # GitHub Pages 소스
    ├── index.md        # Wiki 인덱스
    ├── layer1-*.md     # Layer별 상세
    ├── layer2-*.md
    ├── layer3-*.md
    ├── workflow-pipeline.md
    ├── skill-system.md
    └── systems/        # 시스템별 상세
        ├── overview.md
        ├── models.md
        ├── knowledge.md
        ├── cron.md
        ├── backup.md
        └── deploy.md
```

### 4. GitHub Pages 활성화 (수동)
**⚠️ CLI로 활성화 불가** — 브라우저에서 수동 설정 필요.

1. https://github.com/pheanor-agent/p-hermes/settings/pages 접근
2. Source: `Deploy from a branch`
3. Branch: `main` → `/docs` 폴더
4. Save

**실패한 자동화 시도**:
- `gh pages publish` — 명령어 없음 (extension 필요)
- `gh pages enable` — 명령어 없음
- `gh api repos/.../pages -X PUT` — 404 Not Found (권한/엔드포인트 문제)

## 빌드 파이프라인

`~/.hermes/scripts/build-p-hermes.sh`:
- Markdown 링크 검증 (markdown-link-check)
- YAML 파일 검증
- 파일 통계
- Git 상태 확인

## 민감 정보 필터링

공개 배포 시 제외해야 할 데이터:
- API 키, 토큰, 개인 데이터
- 실제 작업 데이터 (`jobs/`, `novels/`, `research/`)
- 내부 IP 주소, 서버 정보
- Blackboard 데이터

## docs/ 폴더 외부 참조

문서 생성 시 시스템 정보 소스:
- `~/.hermes/workspace/jobs/JOB-1542-*/systems-overview/systems.md`
- `~/.hermes/knowledge/wiki/index.md`
- `~/.hermes/config.yaml` (설정 패턴만, 값 제외)