# 지식 시스템 가이드

p-hermes의 지식 관리 시스템 구조와 사용 방법을 설명합니다.

## 📁 지식 시스템 폴더 구조

```
~/.hermes/
├── knowledge/              # 지식 시스템 루트
│   ├── index.md            # 지식 인덱스 (전체 지식 구조 요약)
│   ├── references/         # 외부 리퍼런스 (원본 링크 모음)
│   │   └── index.md        # 외부 리퍼런스 상세 인덱스
│   ├── wiki/               # 위키 (가공된 지식 저장소)
│   │   ├── index.md        # 위키 진입점 (98페이지 카탈로그)
│   │   ├── filing/         # 신규 지식 대기 구역
│   │   ├── blogs/          # 블로그 관련 지식
│   │   ├── tools/          # 도구/기술 문서
│   │   ├── architecture/   # 아키텍처 관련 지식
│   │   ├── jobs/           # JOB 관련 지식
│   │   └── inbox.md        # Signal Detector 수집 데이터
│   └── scripts/            # 지식 관리 스크립트
│       ├── wiki-process-filings.sh    # filing → wiki 자동 이동
│       ├── build-scores.sh            # T1/T2/T3 점수 계산
│       └── wiki-cleanup.sh            # 지식 정리
```

## 🔄 지식 관리 워크플로우

### 1. 지식 수집
- Signal Detector가 대화 중 URL, 결정, 개념, 문제를 감지하여 `wiki/inbox.md`에 기록
- 주기적으로 `wiki/inbox.md` → `wiki/filing/`으로 이동
- cron: 5분 간격 (`wiki-process-filings.sh`)

### 2. 지식 처리
- `wiki/filing/`에 모인 파일들을 도메인별로 분류
- `build-scores.sh`로 T1/T2/T3 점수 자동 계산
- T1: 직접 참조됨, T2: 간접 참조됨, T3: 미사용

### 3. 지식 활용
- 작업 시작 시 `wiki/index.md` → 관련 도메인 폴더 → 상세 파일 순으로 탐색
- 원본 파일 직접 참조 우선 (지식 인덱싱 1:1 매핑 확인)
- 위키에는 가공된 데이터만 기록

## 🛠️ 사용 방법

### 지식 검색
```bash
# 키워드로 검색
grep -rn "검색어" ~/.hermes/knowledge/wiki/

# T3 파일 확인 (정리 대상)
bash ~/.hermes/knowledge/scripts/build-scores.sh
```

### 지식 추가
```bash
# filing에 추가
cp 원본파일.md ~/.hermes/knowledge/wiki/filing/
# 5분 후 cron이 자동 분류
```

### 지식 정리
```bash
# T3 파일 정리 (백업 후 삭제)
bash ~/.hermes/knowledge/scripts/wiki-cleanup.sh
```

## ⚠️ 주의 사항

- **원본 직접 참조**: 지식 인덱스에 의존하기보다 원본 파일 직접 확인
- **가공 데이터만 위키**: 원본 그대로 복사 금지, 가공 후 저장
- **계층적 탐색**: 한 번에 전체 로딩 금지, 진입점에서 단계적 탐색
- **점수 기반 정리**: T3 파일은 정리 대상 (사용 빈도 기반)

## 🔗 관련 문서

- [지식 시스템 설계](../../blog/posts/knowledge-system-design.md)
- [슬라이드: 지식 시스템](../../../pages/slides/decks/knowledge-system.html)
