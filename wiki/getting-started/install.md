# 설치 및 환경 설정

p-hermes를 새로운 환경에 구축하여 작동시키기 위한 단계별 가이드입니다.

## 📋 전제 조건

설치를 시작하기 전, 다음 환경이 준비되어 있는지 확인하세요.

- **OS**: Linux (Ubuntu 22.04+ 권장) 또는 WSL2 (Windows Subsystem for Linux)
- **런타임**: Python 3.11+
- **도구**: Bash 4.0+, Git 2.30+
- **권한**: 사용자 홈 디렉토리(`~`)에 대한 쓰기 권한

---

## 🛠️ 설치 단계

### 1. 디렉토리 구조 생성
Hermes의 물리적 계층화(5-Tier) 구조를 생성합니다. 아래 명령어를 터미널에 복사하여 실행하세요.

```bash
# Hermes Home 설정
HERMES_HOME="$HOME/.hermes"

# 5-Tier 물리 구조 생성
mkdir -p "$HERMES_HOME"/{core,runtime,interfaces,infra,release}

# 상세 하위 디렉토리
mkdir -p "$HERMES_HOME"/core/{scripts,skills,hooks,plugins}
mkdir -p "$HERMES_HOME"/infra/{cron,backups,state,events/bus}
mkdir -p "$HERMES_HOME"/runtime/workspace/{jobs,projects,novels,reports,research}
mkdir -p "$HERMES_HOME"/runtime/knowledge/{wiki,references,lessons,news}

# 초기 파일 생성
touch "$HERMES_HOME"/runtime/knowledge/wiki/index.md
echo "# Wiki Index" > "$HERMES_HOME"/runtime/knowledge/wiki/index.md
```

### 2. 핵심 설정 파일 작성
시스템 동작의 중심이 되는 `config.yaml`과 `AGENTS.md`를 작성합니다.

#### config.yaml
`$HERMES_HOME/config.yaml` 경로에 작성하세요. **API 키는 직접 적지 말고 환경변수를 사용하세요.**

```yaml
model:
  api_key: "${HERMES_API_KEY}"
  base_url: "https://api.airouter.ch/v1"
  default: "High-Speed-Coding-Model"
  provider: custom

workflow:
  checkpoint_validation: true
  auto_transition: true
  state_file: ".workflow-state"

knowledge:
  wiki_path: "~/.hermes/runtime/knowledge/wiki"
  update_interval: 300

cron:
  registry: "~/.hermes/infra/cron/registry.yaml"
```

#### AGENTS.md
`$HERMES_HOME/AGENTS.md` 경로에 에이전트 프로필을 정의합니다.

```yaml
agents:
  hermes:
    name: "Hermes Agent"
    model: "High-Speed-Coding-Model"
    provider: "custom"
    skills_path: "~/.hermes/core/skills"
    knowledge_path: "~/.hermes/runtime/knowledge"
    workspace: "~/.hermes/runtime/workspace"
```

### 3. 핵심 스크립트 배치
시스템 운영에 필수적인 유틸리티 스크립트들을 `$HERMES_HOME/core/scripts/`에 배치하고 실행 권한을 부여합니다.

- `create-job.sh`: 새 작업(JOB) 생성 및 초기화
- `workflow-gate.sh`: 워크플로우 단계 검증 및 전이
- `on-job-complete.sh`: 작업 완료 후 지식 동기화 처리
- `pre-delete-backup.sh`: 파일 삭제 전 안전 백업

```bash
chmod +x "$HERMES_HOME"/core/scripts/*.sh
```

---

## ✅ 최종 검증

모든 설정이 완료되었다면, 아래 명령어로 필수 구성 요소가 누락되지 않았는지 확인하세요.

```bash
# 검증 스크립트 실행 (설치본에 포함됨)
bash "$HERMES_HOME"/core/scripts/verify.sh
```

**성공 시**: `✅ 검증 완료: 모든 필수 파일 존재` 메시지가 출력됩니다.

## 💡 문제 해결 (Troubleshooting)

| 현상 | 원인 | 해결 방법 |
|---|---|---|
| **API 연결 오류** | 환경변수 누락 | `export HERMES_API_KEY=sk-xxx` 실행 확인 |
| **권한 오류 (Permission Denied)** | 스크립트 권한 미부여 | `chmod +x` 명령어로 실행 권한 부여 |
| **디렉토리 누락** | 생성 스크립트 오류 | `Step 1`의 `mkdir -p` 명령어를 재실행 |

## ➡️ 다음 단계
설치가 완료되었습니다! 이제 **[첫 번째 작업 요청하기](./first-job.md)** 가이드로 이동하여 Hermes에게 첫 임무를 맡겨보세요.
