#!/usr/bin/env bash
# create-project.sh — SW 프로젝트 생성 (Spec-driven 구조)
#
# 사용법: bash create-project.sh <slug> <name>
# 예시:   bash create-project.sh my-api "내 API 서비스"

set -euo pipefail

# 경로 설정
SKILL_DIR="${HOME}/.hermes/skills/software-development/spec-driven-dev"
PROJECTS_DIR="${HOME}/.hermes/workspace/projects"
TEMPLATES_DIR="${SKILL_DIR}/templates"
GITIGNORE_TEMPLATE="${SKILL_DIR}/templates/.gitignore"

# 인자 검증
if [[ $# -lt 2 ]]; then
    echo "사용법: $0 <slug> <name>"
    echo "예시:   $0 my-api \"내 API 서비스\""
    exit 1
fi

SLUG="$1"
NAME="$2"
PROJECT_DIR="${PROJECTS_DIR}/${SLUG}"

# 이미 존재하는지 확인
if [[ -d "${PROJECT_DIR}" ]]; then
    echo "❌ 프로젝트 '${SLUG}'이(가) 이미 존재합니다: ${PROJECT_DIR}"
    exit 1
fi

echo "📦 프로젝트 생성: ${SLUG} (${NAME})"
echo "   위치: ${PROJECT_DIR}"

# 1. 디렉토리 구조 생성
mkdir -p "${PROJECT_DIR}/specs/active/components"
mkdir -p "${PROJECT_DIR}/specs/active/interfaces"
mkdir -p "${PROJECT_DIR}/specs/history"
mkdir -p "${PROJECT_DIR}/specs/templates"
mkdir -p "${PROJECT_DIR}/src"
mkdir -p "${PROJECT_DIR}/tests"
mkdir -p "${PROJECT_DIR}/docs"
mkdir -p "${PROJECT_DIR}/scripts/spec"

# 2. Git init
cd "${PROJECT_DIR}"
git init -b main
echo "✅ Git init 완료"

# 3. .gitignore 생성
if [[ -f "${GITIGNORE_TEMPLATE}" ]]; then
    cp "${GITIGNORE_TEMPLATE}" "${PROJECT_DIR}/.gitignore"
else
    # 기본 .gitignore 생성
    cat > "${PROJECT_DIR}/.gitignore" << 'EOF'
# Hermes Agent files (백업 충돌 방지)
.hermes/
.openclaw/
.shared/

# JOB files
jobs/

# 환경 변수
.env
.env.local
.env.*.local
*.secret
*.key

# Build artifacts
dist/
build/
*.pyc
__pycache__/

# Node.js
node_modules/

# Logs/DBs
*.log
*.db
*.sqlite
*.tmp

# OS files
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
EOF
fi
echo "✅ .gitignore 생성"

# 4. AGENTS.md 생성 (내장 템플릿)
cat > "${PROJECT_DIR}/AGENTS.md" << 'EOF'
# 프로젝트 운영 규칙

## Spec 연동

### Spec 위치
- `specs/active/` — 현재 유효한 Spec
- `specs/history/` — 변경 이력
- `specs/_index.yaml` — Spec 인덱스
- `specs/_matrix.json` — Traceability Matrix

### Spec 생성
```bash
bash ~/.hermes/skills/software-development/spec-driven-dev/scripts/spec-create.sh <slug> <type> <title>
```

### 구조 검증
```bash
bash ~/.hermes/skills/software-development/spec-driven-dev/scripts/validate-project.sh <slug>
```

## Git 정책

### 브랜치 전략
- `main` — 안정 버전 (보호 브랜치)
- `feature/SPEC-XXX` —新功能 개발
- `fix/SPEC-XXX` — 버그 수정
- `spec/SPEC-XXX` — Spec 변경 전용

### Commit 컨벤션
```
<type>(SPEC-XXX): <message>
```

| Type | 용도 |
|------|------|
| `spec` | Spec 추가/수정 |
| `feat` |新功能 구현 |
| `fix` | 버그 수정 |
| `test` | 테스트 추가/수정 |
| `refactor` | 코드 리팩토링 |

## Hermes Workflow 연동

JOB-XXXX/request.md → specs/ 참조
JOB-XXXX/execution.md → Spec ID 기반 작업 기록
EOF
echo "✅ AGENTS.md 생성"

# 5. README.md 생성
cat > "${PROJECT_DIR}/README.md" << EOF
# ${NAME}

## 개요

${NAME} 프로젝트

## 구조

\`\`\`
specs/                  # Spec 중앙 관리
├── active/             # 현재 유효한 Spec
├── history/            # 변경 이력
├── templates/          # 템플릿
├── _index.yaml         # Spec 인덱스
└── _matrix.json        # Traceability Matrix
src/                    # 소스 코드
tests/                  # 테스트
docs/                   # 보조 문서
scripts/spec/           # Spec 도구
\`\`\`

## 진입점

### Spec 생성
\`\`\`bash
bash ~/.hermes/scripts/spec/spec-create.sh ${SLUG} <type> <title>
\`\`\`

### 구조 검증
\`\`\`bash
bash ~/.hermes/scripts/project/validate-project.sh ${SLUG}
\`\`\`

### 영향 분석
\`\`\`bash
bash ~/.hermes/scripts/spec/spec-impact.sh ${SLUG} <spec-id>
\`\`\`
EOF
echo "✅ README.md 생성"

# 6. Spec 템플릿 심링크
if [[ -d "${TEMPLATES_DIR}" ]]; then
    rm -rf "${PROJECT_DIR}/specs/templates"
    ln -s "${TEMPLATES_DIR}" "${PROJECT_DIR}/specs/templates"
else
    echo "⚠️ 템플릿 디렉토리 없음: ${TEMPLATES_DIR}"
fi

# 7. 초기 Spec 파일 생성
cat > "${PROJECT_DIR}/specs/_index.yaml" << EOF
# Spec Index
project: ${SLUG}
spec_version: v0.1
created: $(date +%Y-%m-%d)
updated: $(date +%Y-%m-%d)

next_spec_id:
  A: 1
  B: 1
  C: 1
  D: 1
  E: 1
  F: 1
  S: 1
  M: 1
  O: 1

specs: []
EOF

cat > "${PROJECT_DIR}/specs/_matrix.json" << EOF
{
  "project": "${SLUG}",
  "spec_version": "v0.1",
  "created": "$(date +%Y-%m-%d)",
  "updated": "$(date +%Y-%m-%d)",
  "items": {}
}
EOF

cat > "${PROJECT_DIR}/specs/history/CHANGELOG.md" << EOF
# Spec 변경 이력

## v0.1 ($(date +%Y-%m-%d))
- 프로젝트 생성
EOF

echo "✅ Spec 초기화 완료"

# 9. 초기 commit
cd "${PROJECT_DIR}"
git add -A
git commit -m "chore: 프로젝트 생성 — ${NAME}" || true
echo "✅ 초기 commit 완료"

echo ""
echo "🎉 프로젝트 '${SLUG}' 생성 완료!"
echo "   위치: ${PROJECT_DIR}"
echo ""
echo "다음 단계:"
echo "  1. cd ${PROJECT_DIR}"
echo "  2. Spec 생성: bash ~/.hermes/skills/software-development/spec-driven-dev/scripts/spec-create.sh ${SLUG} requirement \"제목\""
echo "  3. 구조 검증: bash ~/.hermes/skills/software-development/spec-driven-dev/scripts/validate-project.sh ${SLUG}"
