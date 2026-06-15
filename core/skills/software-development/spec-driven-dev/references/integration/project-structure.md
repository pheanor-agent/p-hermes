# 프로젝트 구조 가이드

## 프로젝트 생성 후 기본 구조

```
~/.hermes/workspace/projects/<slug>/
├── .git/
├── .gitignore
├── AGENTS.md
├── README.md
├── specs/
│   ├── _index.yaml
│   ├── _matrix.json
│   ├── active/
│   │   ├── components/
│   │   ├── interfaces/
│   │   ├── requirements.md
│   │   └── architecture.md
│   ├── history/
│   │   └── CHANGELOG.md
│   └── templates/  → (symlink to skill templates)
├── src/
├── tests/
└── docs/
```

## .gitignore 필수 패턴

```
# Hermes
.herms/
.openclaw/
.shared/
jobs/

# Secrets
.env*
*.secret
*.key

# Python
__pycache__/
*.pyc
*.pyo
.venv/
venv/

# Node.js
node_modules/
npm-debug.log*

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db
```

## AGENTS.md 포함 사항

```markdown
# 프로젝트: {name}

## Spec 연동 가이드

### Spec 구조
- `specs/active/requirements.md` — 요구사항
- `specs/active/components/` — 컴포넌트 Spec
- `specs/active/interfaces/` — 인터페이스 Spec
- `specs/history/CHANGELOG.md` — 변경 이력

### 코드 Annotation 패턴
```python
# SPEC-A001: JWT 인증
def jwt_issue(user_id: str) -> dict:
    """
    JWT 토큰 발급
    
    @spec_id("SPEC-A001")
    """
    ...
```

### 테스트 Annotation 패턴
```python
# tests/test_auth.py
import pytest

class TestJWT:
    @spec_id("SPEC-A001")
    def test_jwt_issued(self):
        """JWT 발급 테스트"""
        ...
```

### Workflow 연동
- Spec 참조: `request.md`에 `SPEC-XXX` 포함
- 상태 갱신: `spec-status.sh <slug> <spec-id> <status>`
- 영향 분석: `spec-impact.sh <slug> <spec-id>`
- 준수도 검증: `spec-conformance.sh <slug>`
- Matrix 동기화: `spec-sync.sh <slug>`

### Git 브랜치 컨벤션
```
feature/SPEC-XXX — 신규 기능
fix/SPEC-XXX — 버그 수정
spec/SPEC-XXX — Spec 변경
```

### 커밋 메시지 컨벤션
```
<type>(SPEC-XXX): <message>

type: spec, feat, fix, test, refactor, chore
```