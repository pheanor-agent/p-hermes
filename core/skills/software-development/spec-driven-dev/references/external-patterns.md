# External Patterns for Spec Versioning (JOB-1505 조사 결과)

## GitOps + SpecOps

**도구**: Argo CD, Flux CD
**개념**: Git에 Spec 저장 → 변경 감지 → 자동 적용
**Hermes 적용**:
- Spec 변경 시 workflow-gate.sh 자동 트리거
- VERSION_MAP.yaml Git 추적
- `git diff specs/`로 변경 사항 자동 분석

## OpenAPI/Swagger 버전 관리

**도구**: swagger-cli, openapi-diff
**개념**: API 스키마 버전 관리 + breaking change 감지
**Hermes 적용**:
- Spec 변경 시 breaking change 자동 감지
- 패턴: 필드 삭제, 타입 변경, enum 값 삭제
- 참고: `openapi-diff spec-v1.yaml spec-v2.yaml`

## Backstage 개발 포털

**도구**: Backstage.io
**개념**: 개발 포털에 Spec/코드/테스트 통합 표시
**Hermes 적용**:
- 지식 시스템에 Spec 대시보드 추가
- Traceability Matrix 시각화
- Conformance Score 표시

## Semantic Versioning + Spec 매핑

**도구**: npm, pip, cargo
**개념**: MAJOR.MINOR.PATCH 버전 체계
**Hermes 적용**:
- 개별 Spec SemVer 적용
- MAJOR: breaking change (API 구조 변경)
- MINOR:新功能 (기능 추가)
- PATCH: 버그 수정 (소규모 변경)

## Spec-Driven CI/CD

**도구**: GitHub Actions, GitLab CI
**개념**: Spec 변경 시 자동 테스트/검증
**Hermes 적용**:
- Spec lint (스키마 검증)
- Conformance test (SBE 예시 기반)
- Breaking change scan
- VERSION_MAP 갱신

## Flux CD + Custom Resource Definition

**도구**: Flux CD, Kubernetes CRD
**개념**: Spec을 CRD로 관리 → 상태 기계 자동화
**Hermes 적용**:
- spec-status.sh 상태 전이 자동화
- Breaking change 시 자동 ADR 생성
- Rollback 시 Spec 버전 자동 복원

## Architecture Decision Records (ADR)

**도구**: ADR template, decision tracker
**개념**: 설계 결정 문서화 + 추적
**Hermes 적용**:
- MAJOR 버전 전환 시 ADR 자동 생성
- Context/Decision/Consequences 구조
- `specs/adrs/0001-adr.md` 패턴

## Karpathy 3계층 지식 시스템

**도구**: Karpathy's LLM Wiki
**개념**: Source → Processed → Synthesis 3계층
**Hermes 적용**: (선택)
- Spec 변경 이력 → processed notes
- Conformance 결과 → synthesis
- ⚠️ 사용자 지적: "사양서 기반 개발 컨셉 더 확실하게 반영" → SBE/DbC/BDD 기본, 외부 연계 선택

## 참조 링크

- https://swagger.io/docs/specification/breaking-changes/
- https:// backstage.io/docs/features/software-catalog
- https://argoproj.github.io/cd/
- https://github.com/openshift/openapi-diff
- https://semver.org/
- https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions
