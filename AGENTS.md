# p-hermes 프로젝트

## 프로젝트 개요
**p-hermes**는 **Hermes Agent 시스템**의 공식 문서화 프로젝트입니다.
Hermes Agent의 기능, 설정, 활용법을 체계적으로 문서화하고 GitHub Pages로 배포합니다.

## 디렉토리 구조
```
p-hermes/
├── docs/                    # 문서 소스 (MkDocs / GitHub Pages)
│   ├── index.md
│   ├── guide/
│   └── ...
├── specs/                   # Spec 문서 (SSOT — Single Source of Truth)
│   └── active/
│       ├── SPEC-D01.md      # 문서 구조
│       ├── SPEC-D02.md      # GitHub Pages 배포
│       └── SPEC-D03.md      # Expression D1 연동 가이드라인
├── src/
│   ├── deploy.sh            # 배포 스크립트
│   └── ...
├── tests/
│   ├── validate-links.sh    # 링크 검증
│   └── ...
├── config.yaml.example      # 설정 파일 템플릿
├── project.yaml             # 프로젝트 메타데이터
└── setup.sh                 # 초기 설정 스크립트
```

## Scope
Hermes Agent 시스템 문서화 및 GitHub Pages 배포.

## Spec 연동
- specs/active/SPEC-D01.md — 문서 구조 (SSOT)
- specs/active/SPEC-D02.md — GitHub Pages 배포
- specs/active/SPEC-D03.md — Expression D1 연동 가이드라인

내용 변경 시 Spec을 먼저 검토하세요. docs/를 직접 수정하면 invariant를 위반할 수 있습니다.

## 초기 설정
```bash
bash setup.sh  # 의존성 설치, hooks 설정, 초기 디렉토리 생성
```

## 배포
```bash
bash src/deploy.sh  # 링크 검증 → llms.txt 재생성 → git push
```
deploy.sh 실행 시 자동으로:
1. 링크 유효성 검증 (validate-links.sh)
2. llms.txt / llms-full.txt 재생성
3. Git 커밋 및 푸시

## 검증
```bash
bash tests/validate-links.sh  # 문서 내 링크 검증
```

## 규칙
- docs/ 변경 → SPEC-D01 구조 준수 → validate-links.sh → deploy.sh
- 내용 변경 시 Spec 먼저 검토 (직접 docs/ 수정 시 invariant 위반 가능성)
- llms.txt/llms-full.txt → deploy.sh 실행 시 자동 재생성
- 절대경로 하드코딩 금지 (config.yaml.example 참고)
- 모델명 하드코딩 금지, your-{role}-model 형식의 placeholder 사용

## 기여 가이드
1. 작업 전 해당 Spec (SPEC-D01~D03)을 먼저 읽으세요.
2. 변경 사항은 Spec에 정의된 구조와 invariant를 준수해야 합니다.
3. 배포 전 `bash tests/validate-links.sh`로 링크를 검증하세요.
4. `bash src/deploy.sh`로 배포하며, 배포 전 변경 사항을 커밋하세요.
5. llms.txt / llms-full.txt는 수동 편집하지 말고 deploy.sh를 통해 재생성하세요.
6. config.yaml.example에 실제 모델명을 하드코딩하지 마세요.
