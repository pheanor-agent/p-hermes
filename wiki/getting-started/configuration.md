# 기본 설정 가이드

Hermes Agent의 성능과 동작 방식을 결정하는 핵심 설정 파일들에 대해 알아봅니다. 이 가이드를 통해 자신의 워크플로우에 최적화된 에이전트 환경을 구축할 수 있습니다.

## ⚙️ 1. 모델 라우팅 설정 (`catalog.json`)

Hermes는 작업 단계별로 가장 적합한 모델을 자동으로 배정하는 **역할 기반 라우팅**을 사용합니다. 

- **설정 위치**: `~/.hermes/core/skills/custom/model-catalog/catalog.json` (또는 지정된 경로)
- **핵심 개념**: `routing` 섹션에서 각 단계(step)에 사용할 모델을 지정합니다.

**추천 라우팅 전략:**
- **Design/Review**: 논리적 추론 및 종합 분석에 특화된 고성능 모델
- **Execution/Test**: 프로그래밍 언어 이해도가 높고 실행 속도가 빠른 모델
- **Investigation**: 범용성이 높고 응답이 빠른 모델

```json
"routing": {
  "design": "High-Reasoning-Model",
  "review": "Cross-Check-Model",
  "execution": "High-Speed-Coding-Model"
}
```

---

## 🤖 2. 에이전트 프로필 설정 (`AGENTS.md`)

에이전트의 정체성과 작업 환경을 정의합니다.

- **설정 위치**: `~/.hermes/AGENTS.md`
- **주요 항목**:
  - `skills_path`: 사용할 스킬들이 저장된 경로.
  - `knowledge_path`: 지식 베이스(Wiki 등)가 위치한 경로.
  - `workspace`: 실제 작업 파일들이 생성되는 작업 공간.

---

## 🛠️ 3. 시스템 동작 설정 (`config.yaml`)

시스템의 전역 동작 파라미터를 제어합니다.

- **설정 위치**: `~/.hermes/config.yaml`
- **주요 설정 항목**:
  - `workflow.checkpoint_validation`: 각 단계 전이 전 검증 스크립트 실행 여부. (안정성을 위해 `true` 권장)
  - `knowledge.update_interval`: 지식 시스템의 자동 갱신 주기(초).
  - `cron.registry`: 주기 작업 목록이 관리되는 파일 경로.

---

## 🔐 4. 보안 및 API 키 관리

Hermes는 보안을 위해 API 키를 설정 파일에 직접 저장하는 것을 금지합니다.

**권장 관리 방법:**
1. **환경변수 사용**: `.bashrc` 또는 `.zshrc`에 키를 등록합니다.
   ```bash
   export HERMES_API_KEY="sk-..."
   export OPENROUTER_API_KEY="sk-..."
   ```
2. **Config 참조**: `config.yaml`에서는 `${VARIABLE}` 형태로 참조하여 런타임에 주입합니다.

## 💡 설정 팁: 성능 최적화
- **응답 속도 향상**: `Investigation` 단계의 모델을 더 가벼운 모델로 변경하세요.
- **설계 품질 향상**: `Design` 및 `Review` 단계에 최신 고성능 모델을 배치하고, `Review` 모델을 `Design` 모델과 다르게 설정하여 **상호 견제(Cross-Check)** 구조를 만드세요.

## ➡️ 다음 단계
이제 환경 설정이 완료되었습니다. 이제 Hermes의 진정한 힘인 **[스킬 시스템 활용](./../guides/use-skills.md)** 가이드로 이동하여 에이전트의 능력을 확장하는 방법을 배워보세요.
