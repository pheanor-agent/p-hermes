# Spec & Code Versioning Concepts (JOB-1505 조사 결과)

## Spec 버전 관리 컨셉 (5개)

### 1. Change Lineage (이력 추적)
- **개념**: immutable snapshot + parent pointer + ancestry graph
- **Hermes 적용**: version_history 배열 + parent 필드
- **예시**: `version: 1.2.0` + `parent: 1.1.0` + version_history 배열

### 2. Spec↔Code 버전 매핑
- **개념**: commit pin, release tagging, bump file, frontmatter embedding
- **Hermes 적용**: VERSION_MAP.yaml (Spec ID → commit hash)
- **예시**: SPEC-B1 → src/auth/oauth.py@commit:a1b2c3d

### 3. Branching & Merging 전략
- **개념**: spec/feature, spec/release, spec/hotfix 브랜치 패턴
- **Hermes 적용**: Git 브랜치명 `feature/SPEC-XXX`, `spec/SPEC-XXX`
- **예시**: `git checkout -b feature/SPEC-B1-oauth2`

### 4. Rollback & Superseded lifecycle
- **개념**: draft → active → superseded → deprecated → archived
- **Hermes 적용**: spec-status.sh 상태 기계 (proposed → approved → ... → deprecated)
- **예시**: verified → deprecated → proposed (MAJOR 버전 증가 + ADR)

### 5. Diff & Impact 분석
- **개념**: section/requirement/interface level change detection
- **Hermes 적용**: detect-breaking-changes.sh (yaml 파일 비교)
- **예시**: 필드 삭제, 타입 변경, enum 값 삭제 감지

## Code 버전 관리 컨셉 (5개)

### 1. Spec 기반 코드 브랜칭
- **개념**: branch naming + commit conventions tied to SPEC-IDs
- **Hermes 적용**: `<type>(SPEC-XXX): <message>` 커밋 메시지
- **예시**: `feat(SPEC-B1): OAuth2 로그인 추가`

### 2. Auto Version Bump
- **개념**: code metadata auto-update on spec changes
- **Hermes 적용**: spec-status.sh 자동 버전 증가 (MAJOR/MINOR/PATCH)
- **예시**: proposed→approved = MINOR, deprecated→proposed = MAJOR

### 3. Bidirectional Traceability
- **개념**: forward (spec→code) + backward (code→spec) auto-tracking
- **Hermes 적용**: VERSION_MAP.yaml 양방향 lookup
- **예시**: `spec-version-map.sh reverse-lookup src/auth/oauth.py` → SPEC-B1

### 4. Rollback Impact 분석
- **개념**: spec drift detection on code rollback
- **Hermes 적용**: VERSION_MAP 기반 drift 감지
- **예시**: 코드 rollback 시 해당 Spec 버전도 함께 rollback

### 5. Spec-Driven Release Tagging
- **개념**: release tags encoding spec version vectors
- **Hermes 적용**: Git tag `v1.2.0-SPEC-B1`
- **예시**: `git tag -a v1.2.0-SPEC-B1 -m "SPEC-B1 OAuth2 완료"`

## 외부 패턴 (8개)

| 패턴 | 도구 | Hermes 적합도 | 적용 방안 |
|------|------|--------------|-----------|
| GitOps+SpecOps | Argo CD | ★★★★ | Spec 변경 시 자동 코드 업데이트 |
| OpenAPI/Swagger | swagger-cli | ★★★★ | Breaking change 감지 패턴 차용 |
| Backstage | Backstage.io | ★★★☆ | 개발 포털에 Spec 대시보드 |
| SemVer+Spec | npm, pip | ★★★★ | 개별 Spec SemVer 적용 |
| Spec-driven CI/CD | GitHub Actions | ★★★☆ | Spec lint + conformance test |
| Flux CD+CRD | Flux | ★★★☆ | Spec 상태 기계 자동화 |
| ADR 패턴 | ADR template | ★★★★★ | breaking change 문서화 |
| Karpathy 3계층 | - | ★★☆☆ | 지식 시스템 연계 (선택) |

## 참조

- Martin Fowler, "Specification By Example" (2004)
- OpenAPI Specification 3.0 (breaking change rules)
- Architecture Decision Records (Michael Nygard, 2011)
- Semantic Versioning 2.0.0
