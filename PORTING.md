# Porting Guide

**Hermes Agent — New Environment Setup Guide**

이 가이드는 새 환경에 Hermes Agent를 초기화하는 방법을 설명합니다.

---

## Overview

Hermes를 새 환경에 포팅하려면 다음 단계가 필요합니다:

1. **디렉토리 구조 생성** — 필수 디렉토리 트리 설정
2. **config.yaml 구성** — API 키 및 모델 설정
3. **AGENTS.md 설정** — 에이전트 프로필 구성
4. **핵심 스크립트 설치** — workflow-gate, create-job 등
5. **검증** — 필수 파일/디렉토리 확인

---

## Prerequisites

| 항목 | 요구사항 |
|------|---------|
| OS | Linux (WSL 포함) |
| Bash | 4.0+ |
| Python | 3.11+ |
| Git | 2.30+ |
| 디스크 | 최소 2GB 권장 |

---

## Step 1: Directory Structure

```bash
# Hermes Home 설정
HERMES_HOME="$HOME/.hermes"

# 핵심 디렉토리
mkdir -p "$HERMES_HOME"/{scripts,skills,hooks,plugins}
mkdir -p "$HERMES_HOME"/knowledge/{wiki,references,lessons,news}
mkdir -p "$HERMES_HOME"/cron/{backups,cache,history,output}
mkdir -p "$HERMES_HOME"/state/{hermes,openclaw}
mkdir -p "$HERMES_HOME"/workspace/{jobs,projects,novels,reports,research}
mkdir -p "$HERMES_HOME"/{events/bus,backups/{tier1,tier2}}

# 스킬 카테고리 디렉토리
mkdir -p "$HERMES_HOME"/skills/{custom,software-development,creative,system-common,research,writing}

# Wiki 초기화
touch "$HERMES_HOME"/knowledge/wiki/index.md
echo "# Wiki Index" > "$HERMES_HOME"/knowledge/wiki/index.md

# Cron 레지스트리 초기화
cat > "$HERMES_HOME"/cron/registry.yaml << 'EOF'
# Hermes Cron Registry
# 버전: 1.0
# 사용법: 작업 추가 시 이 파일에 등록
jobs: []
EOF

echo "✅ 디렉토리 구조 생성 완료: $HERMES_HOME"
```

---

## Step 2: config.yaml

```yaml
# Hermes Configuration
# 버전: 1.0
# 사용법: 환경변수로 API 키 설정 후 사용
# 예: HERMES_API_KEY=sk-xxx bash setup.sh

model:
  api_key: "${HERMES_API_KEY}"        # 필수: API 키
  base_url: "https://api.airouter.ch/v1"  # 기본 엔드포인트
  default: "Qwen3.6"                  # 기본 모델
  provider: custom                    # 프로바이더 타입

providers:
  # 프로바이더 추가
  # 예:
  # airrouter:
  #   base_url: "https://api.airouter.ch/v1"
  #   api_key: "${AIRROUTER_API_KEY}"
  # openrouter:
  #   base_url: "https://openrouter.ai/api/v1"
  #   api_key: "${OPENROUTER_API_KEY}"

workflow:
  # 워크플로우 설정
  checkpoint_validation: true       # I1~I16 검증 활성화
  auto_transition: true             # 자동 단계 전이
  state_file: ".workflow-state"     # 상태 파일명

knowledge:
  # 지식 시스템 설정
  wiki_path: "~/.hermes/knowledge/wiki"
  references_path: "~/.hermes/knowledge/references"
  update_interval: 300              # Wiki 갱신 간격 (초)

cron:
  # 크론 시스템 설정
  registry: "~/.hermes/cron/registry.yaml"
  history_dir: "~/.hermes/cron/history"
```

> **⚠️ 보안**: 실제 API 키는 환경변수로 설정하세요. `config.yaml`에 평문으로 저장하지 마십시오.

---

## Step 3: AGENTS.md

```yaml
# Agents Configuration
# 각 에이전트의 프로필과 설정

agents:
  hermes:
    name: "Hermes Agent"
    model: "Qwen3.6"
    provider: "custom"
    skills_path: "~/.hermes/skills"
    knowledge_path: "~/.hermes/knowledge"
    workspace: "~/.hermes/workspace"
```

---

## Step 4: Core Scripts

필수 스크립트들을 `$HERMES_HOME/scripts/`에 설치합니다:

| 스크립트 | 역할 |
|---------|------|
| `create-job.sh` | 새 JOB 생성 |
| `workflow-gate.sh` | 워크플로우 단계 검증/전이 |
| `on-job-complete.sh` | JOB 완료 후 처리 (지식 sync) |
| `pre-delete-backup.sh` | 파일 삭제 전 백업 |

```bash
# 스크립트 설치 예시 (실제 스크립트 내용은 Hermes 설치본에서 복사)
cp /path/to/hermes/scripts/*.sh "$HERMES_HOME/scripts/"
chmod +x "$HERMES_HOME/scripts/"*.sh
```

---

## Step 5: Model Catalog

```json
{
  "providers": {
    "airrouter": {
      "base_url": "https://api.airouter.ch/v1",
      "models": [
        { "name": "Qwen3.6", "role": "default" },
        { "name": "Gemma-4", "role": "design" },
        { "name": "Claude-Sonnet-4-5", "role": "analysis" }
      ]
    },
    "z_ai": {
      "base_url": "https://api.z.ai/v1",
      "models": []
    },
    "openrouter": {
      "base_url": "https://openrouter.ai/api/v1",
      "models": []
    }
  },
  "routing": {
    "request": "Qwen3.6",
    "investigation": "Qwen3.6",
    "design": "Gemma-4",
    "review": "Claude-Sonnet-4-5",
    "execution": "Qwen3.6",
    "test": "Qwen3.6"
  }
}
```

---

## Step 6: Verification

포팅이 완료되었는지 검증합니다:

```bash
#!/bin/bash
# verify.sh — 포팅 검증 스크립트

HERMES_HOME="${1:-$HOME/.hermes}"
ERRORS=0

check_file() {
    if [ ! -f "$1" ]; then
        echo "❌ 누락: $1"
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ 존재: $1"
    fi
}

check_dir() {
    if [ ! -d "$1" ]; then
        echo "❌ 누락: $1"
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ 존재: $1"
    fi
}

echo "=== Hermes 포팅 검증 ==="
check_file "$HERMES_HOME/config.yaml"
check_file "$HERMES_HOME/AGENTS.md"
check_dir "$HERMES_HOME/scripts"
check_dir "$HERMES_HOME/skills"
check_dir "$HERMES_HOME/knowledge/wiki"
check_dir "$HERMES_HOME/knowledge/references"
check_dir "$HERMES_HOME/knowledge/lessons"
check_dir "$HERMES_HOME/cron"
check_file "$HERMES_HOME/cron/registry.yaml"
check_dir "$HERMES_HOME/workspace/jobs"
check_dir "$HERMES_HOME/state"
check_dir "$HERMES_HOME/events/bus"

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "✅ 검증 완료: 모든 필수 파일 존재"
    exit 0
else
    echo "❌ 검증 실패: $ERRORS 개 누락"
    exit 1
fi
```

---

## Troubleshooting

| 문제 | 해결 방법 |
|------|----------|
| API 키 오류 | `HERMES_API_KEY` 환경변수 설정 확인 |
| 스크립트 실행 불가 | `chmod +x` 권한 확인 |
| 디렉토리 누락 | Step 1 다시 실행 |
| 모델 라우팅 실패 | `catalog.json` 검증 |
| Wiki 갱신 실패 | `wiki/index.md` 존재 확인 |
| Cron 실행 안됨 | `registry.yaml` 구문 검증 |

---

## Next Steps

포팅 완료 후:

1. `bash ~/.hermes/scripts/verify.sh` 실행
2. 테스트 JOB 생성: `bash ~/.hermes/scripts/create-job.sh --test`
3. 워크플로우 파이프라인 테스트
4. Cron 레지스트리에 첫 작업 등록
5. 지식 시스템 초기 Wiki 항목 생성

상세한 워크플로우 및 시스템 동작은 [ARCHITECTURE.md](ARCHITECTURE.md) 및 [docs/](docs/) 문서를 참조하세요.
