# p-hermes 포팅 가이드

이 가이드는 Hermes Agent 시스템을 새로운 환경에 복제하고 실행하는 방법을 설명합니다.

---

## 📋 선결 조건

- **Hermes Agent 설치 완료**: [공식 문서](https://hermes-agent.nousresearch.com/docs)를 참고하여 Hermes를 설치하세요
- **Python 3.11+**: `python3 --version`으로 확인
- **Git**: 버전 관리용

---

## 🚀 자동 설치 (권장)

```bash
# 1. 리포지토리 클론
git clone https://github.com/pheanor-agent/p-hermes.git
cd p-hermes

# 2. 자동 설치 스크립트 실행
bash setup.sh ~/.hermes
```

설치가 완료되면 `verify.sh`가 자동으로 실행되어 포팅 성공 여부를 검증합니다.

---

## 🔧 수동 설치 (setup.sh 실행 시 에러 발생 시만)

`setup.sh` 실행 후에도 오류가 발생한다면 다음 단계를 수동으로 진행하세요.

### 1. 설정 파일 수정

```bash
# 설정 파일 위치: ~/.hermes/config.yaml

# [필수] 다음 필드를 수정하세요:
#   - model.api_key: 실제 API 키 또는 환경변수
#   - model.base_url: 실제 API 엔드포인트
#   - model.default: 기본 모델명
```

### 2. 크론 레지스트리 초기화

```bash
# 크론 스케줄 파일: ~/.hermes/infra/cron/registry.yaml
```

### 참고: 폴더 구조

`setup.sh`는 다음 5-Tier 구조를 자동으로 생성합니다:

```
~/.hermes/
├── core/          # 정적 설정 (스크립트, 스킬)
├── runtime/       # 동적 상태 (세션, 워크스페이스)
├── interfaces/    # 휘발성 데이터 (디스코드, 텔레그램 연동)
├── infra/         # 상태 관리 (크론, 백업)
└── release/       # 선택적 배포 (wiki, 블로그, 슬라이드)
└── knowledge/     # 지식 시스템 (원본 → 가공 파이프라인 → Wiki DB)
```

---

## ✅ 포팅 검증

```bash
bash verify.sh ~/.hermes
```

모든 항목이 `✅`로 표시되면 포팅 성공입니다.

---

## ⚙️ 설정 가이드

### API 키 설정

```bash
# 환경변수에 API 키 설정 (권장)
export HERMES_API_KEY=your_actual_api_key_here

# 또는 config.yaml에 직접 입력 (보안 주의)
# model.api_key: "your_actual_api_key_here"
```

### 크론 작업 추가

`~/.hermes/infra/cron/registry.yaml`에 다음 형식으로 추가하세요:

```yaml
- id: job-your-task
  name: "작업 이름"
  schedule: "0 9 * * *"  # 매일 오전 9시
  deliver: "origin"      # 결과 전송 채널
  enabled: true
```

---

## 🎯 시작하기

설치가 완료되면 다음을 실행하여 에이전트를 시작하세요:

```bash
hermes start
```

에이전트와 첫 대화를 시작하려면 Discord 또는 Telegram에서 봇을 호출하세요.

---

## 📚 추가 자료

- **[Guide Wiki](./docs/wiki/index.md)**: 사용 가이드
- **[Dev Blog](./docs/blog/index.md)**: 기술 심층 분석
- **[Slides](./docs/index.html)**: 시스템 구조 시각화
