# ⏰ 잊지 않고 일하는 AI의 비결: 크론(Cron) 3계층 아키텍처

> **💡 한 줄 요약**: 에이전트가 정해진 시간에 정확히 작업을 수행하고, 실패해도 스스로 복구하는 '신뢰할 수 있는 자동화' 시스템 설계 이야기입니다.

---

## 🌱 기본 개념: '크론(Cron)'이란 무엇일까요?

컴퓨터 세계에는 **'크론(Cron)'**이라는 아주 성실한 비서가 있습니다. 이 비서의 유일한 임무는 **\"정해진 시간에 정해진 일을 실행하는 것\"**입니다.

- **일상생활의 비유**: 매일 아침 7시에 울리는 알람 시계, 혹은 매주 일요일 저녁에 규칙적으로 찾아오는 쓰레기 수거 서비스와 같습니다. 정해진 '주기'와 '시점'이 핵심입니다.
- **AI 에이전트에게는?**: \"매일 아침 9시에 최신 뉴스를 요약해서 알려줘\", \"6시간마다 시스템 메모리를 체크해서 보고해줘\" 같은 요청을 처리하는 심장과 같습니다. AI가 스스로 깨어나 능동적으로 업무를 시작하게 만드는 장치입니다.

하지만 AI는 사람과 달리 예상치 못한 변수에 취약합니다. 네트워크가 잠시 끊기거나, API 한도를 초과하거나, 혹은 엉뚱한 루프에 빠져 시스템 전체를 마비시키기도 하죠. Hermes는 이러한 불안정성을 해결하기 위해 단순 실행이 아닌 **'3계층 분리 구조'**라는 공학적 안전장치를 도입했습니다.

### 왜 단순한 `cron` 명령어로 충분하지 않은가?

OS 레벨의 `cron`은 프로세스를 시작만 할 뿐, 실행 결과의 성공/실패를 추적하지 않습니다. AI 기반 작업은 실패 원인이 다양하고 복잡하므로, '실행 자체'와 '실행 관리', '작업 정의'를 분리해야 합니다.

```bash
# OS cron — 프로세스 시작만
* * * * * /path/to/script.sh
# ↑ 실패해도 알 수 없음. 재시도도 안 됨. 상태도 기록 안 됨.

# Hermes Cron 3계층 — 정의, 관리, 실행 분리
registry.yaml → cron-wrapper.sh → cron-runner.sh
# ↑ 언제 실행할지, 실행을 감시하고 재시도, 실제 AI 작업 수행
```

---

## 🔍 문제 상황: 왜 그냥 실행하면 안 될까?

초기 Hermes의 크론은 매우 단순했습니다. \"시간이 되면 스크립트를 실행해!\"라고 명령하는 수준이었죠. 하지만 실제 운영 환경에서 세 가지 치명적인 '페인 포인트(Pain Point)'가 발생했습니다.

### 1. 침묵의 실패 (Silent Failure)
스크립트가 내부 에러로 멈췄지만, 외부에서는 알 방법이 없었습니다. 사용자는 보고서가 오지 않아 의아해하지만, 시스템은 조용히 죽어있는 상태였습니다. 이는 '신뢰성'이 생명인 자동화 시스템에서 가장 치명적인 문제입니다.

### 2. 에이전트의 폭주 (Agent Rampage)
뉴스 수집 AI가 예상치 못한 무한 루프에 빠져 30분 만에 수백 개의 세션을 생성한 사례가 있었습니다. 결과적으로 전체 API 토큰을 순식간에 소모하여 시스템 전체가 마비되었습니다. '브레이크 없는 자동차'와 같은 상황이었습니다.

### 3. 기록의 부재 (Lack of Observability)
\"어제 오후 3시 작업이 왜 실패했지?\"라는 질문에 답할 수 없었습니다. 실행 결과가 표준 출력으로만 나갔거나 사라졌기 때문에, 사후 분석(Post-mortem)이 불가능했고 동일한 실수를 반복하게 되었습니다.

---

## 🔬 실제 사례: JOB-1188 \"크론 시스템 리팩토링\"

실제 3계층 크론 아키텍처 도입 과정에서의 사건들을 추적합니다.

### 사건 1: 뉴스 수집 에이전트 폭주 (도입 전 사고 기록)

```bash
# 2026-02-14 03:00 — 뉴스 수집 cron 실행
$ cat ~/.hermes/runtime/state/cron-20260214-0300.log

[03:00:01] cron-start: job-news-collect 실행
[03:00:15] RSS 피드 수집: 23개 아티클
[03:00:45] LLM 요약 요청... 응답 대기
[03:01:30] API Error: Rate Limit Exceeded
[03:01:31] 재시도... (재시도 로직 없음 — 무한 루프 진입)
[03:01:31] API Error: Rate Limit Exceeded
[03:01:31] 재시도...
... (30분간 2,847회 재시도) ...
[03:31:00] API Quota: 100% 사용 — 시스템 전체 차단
[03:31:01] 수동 종료 필요
```

**분석**: 재시도 로직이 있었지만 '지수 백오프(Exponential Backoff)'와 '최대 재시도 횟수'가 없어서 무한 루프에 빠졌습니다.

### 사건 2: 3계층 도입 후 동일 상황의 처리

```bash
# 2026-05-20 09:00 — 동일한 Rate Limit 상황
$ cat ~/.hermes/runtime/state/cron-20260520-0900.json

{
  "job_id": "job-news-digest",
  "trigger_time": "2026-05-20T09:00:00Z",
  "attempts": [
    {
      "attempt": 1,
      "time": "09:00:02",
      "result": "error",
      "error": "API Rate Limit Exceeded",
      "next_retry_in_seconds": 1
    },
    {
      "attempt": 2,
      "time": "09:00:03",
      "result": "error",
      "error": "API Rate Limit Exceeded",
      "next_retry_in_seconds": 2
    },
    {
      "attempt": 3,
      "time": "09:00:05",
      "result": "error",
      "error": "API Rate Limit Exceeded",
      "next_retry_in_seconds": 4
    },
    {
      "attempt": 4,
      "time": "09:00:09",
      "result": "success",
      "summary_length": 482
    }
  ],
  "max_retries": 5,
  "final_status": "completed",
  "total_duration_seconds": 9,
  "notification_sent": true
}
```

**분석**: Wrapper가 지수 백오프(1초 → 2초 → 4초)를 적용하여 Rate Limit이 풀리는 9초 만에 성공했습니다. 최대 재시도 5회가 설정되어 있어 무한 루프가 물리적으로 불가능합니다.

### 사건 3: 중복 실행 방지 (flock)

```bash
# cron-wrapper.sh 내부 flock 메커니즘
$ cat core/scripts/cron-wrapper.sh | grep -A5 "flock"

exec 200>/tmp/cron-${JOB_ID}.lock
flock -n 200 || {
    echo "[WRAP] Another instance is running. Exiting."
    exit 1
}
```

Wrapper가 실행 중인 상태에서 동일한 작업이 트리거되면 `flock`이 즉각 차단합니다.

---

## 🏗️ 기술 설계: Registry $\\rightarrow$ Wrapper $\\rightarrow$ Runner

Hermes는 이 문제를 해결하기 위해 역할을 셋으로 쪼개어 **'책임과 권한'**을 엄격히 분리했습니다. 이는 소프트웨어 공학의 '단일 책임 원칙(Single Responsibility Principle)'을 물리적 구조로 구현한 것입니다.

### 1️⃣ 레지스트리 (Registry): \"전략적 계획표\"
가장 윗단에 있는 레지스트리는 **'무엇을, 언제, 누구(모델)가, 어디로'** 보낼지를 정의한 마스터 명단입니다. 주로 `registry.yaml` 파일로 관리됩니다.

- **공학적 역할**: 작업의 정의 및 스케줄링의 **SSOT (Single Source of Truth)** 역할을 수행합니다.
- **비유**: 회사 내의 '전사 업무 스케줄표'입니다. \"월요일 9시, 뉴스 요약 작업, Claude-3.5 모델 사용, 텔레그램으로 전송\"이라고 명시된 공식 문서입니다.
- **핵심 데이터**: `Job ID`, `Cron Expression`, `Target Model`, `Prompt Path`, `Notification Channel`.

### 2️⃣ 래퍼 (Wrapper): \"철저한 관리 감독관\"
레지스트리에 설정된 시간이 되면, 래퍼(`cron-wrapper.sh`)가 깨어나 작업을 준비하고 감시합니다.

- **공학적 역할**: 세션 생성, 상태 기록(State Tracking), 예외 처리 및 지수 백오프(Exponential Backoff) 기반의 재시도 로직을 담당합니다.
- **비유**: 신입 사원에게 업무를 맡기는 '깐깐한 팀장님'입니다. \"자, 지금부터 작업 시작해. 세션 ID는 이거고, 만약 실패하면 1초, 2초, 4초 간격으로 다시 시도해봐. 그리고 모든 진행 상황을 기록지에 꼼꼼히 적어둬.\"라고 지시하고 감시합니다.
- **메커니즘**:
    - `flock`을 이용한 중복 실행 방지.
    - `~/.hermes/runtime/state/cron-*.json` 파일에 실시간 상태 기록.
    - Runner의 종료 코드를 확인하여 성공/실패 판정.

### 3️⃣ 러너 (Runner): \"능숙한 실무 작업자\"
실제 AI 모델이 구동되어 구체적인 업무를 수행하는 단계입니다(`cron-runner.sh`).

- **공학적 역할**: 프롬프트 주입, LLM 호출, 결과 수집, 최종 알림 전송이라는 '순수 기능'에만 집중합니다.
- **비유**: 실제로 뉴스를 검색하고 요약하는 '실무자'입니다. 팀장님(Wrapper)이 준 지침과 환경(세션) 속에서 일을 끝내고 결과를 보고하는 역할입니다.
- **특징**: 러너는 자신이 실패하더라도 시스템 전체를 죽이지 않습니다. 실패하면 Wrapper에게 에러 코드를 반환할 뿐이며, 복구 책임은 Wrapper에게 있습니다.

### 📊 시스템 흐름도 (Mermaid)

```mermaid
graph TD
    A[Registry: registry.yaml] -->|스케줄 트리거| B[Wrapper: cron-wrapper.sh]
    B -->|1. flock 중복 실행 체크| B
    B -->|2. 세션 생성 및 상태 기록| C[Runner: cron-runner.sh]
    C -->|3. LLM 프롬프트 실행| D[AI Model]
    D -->|4. 결과 반환| C
    C -->|5. 결과 전송| E[사용자 채널]
    C -->|6. 종료 코드 반환| B
    B -->|7. 지수 백오프 재시도| C
    B -->|8. 최종 상태 기록| F[state/cron-*.json]

    style A fill:#e3f2fd,stroke:#1565c0
    style B fill:#fce4ec,stroke:#c62828
    style C fill:#e8f5e9,stroke:#2e7d32
    style F fill:#fff3e0,stroke:#e65100
```

---

## ⚖️ 대안 비교: 3계층 Cron vs 다른 자동화 방식

| 비교 항목 | 3계층 Cron | OS Cron + Script | Airflow/Prefect | Simple Timer Loop |
| :--- | :--- | :--- | :--- | :--- |
| **재시도 로직** | 지수 백오프 내장 | 없음 (별도 구현 필요) | 있음 | 없음 |
| **상태 추적** | JSON 상태 파일 | stdout만 | DB/웹 UI | 없음 |
| **중복 실행 방지** | flock | 없음 | Built-in | 없음 |
| **설정 방식** | YAML 레지스트리 | crontab | DAG 코드 | 코드 내 하드코딩 |
| **AI 특화** | 모델 라우팅 통합 | 일반 스크립트 | AI 미지원 | AI 미지원 |
| **복구 난이도** | 낮음 (상태 파일 기반) | 높음 | 중간 | 높음 |
| **운영 복잡도** | 중간 | 낮음 | 높음 | 낮음 |

---

## 📊 정량적 근거: 크론 시스템 신뢰성 데이터

### 2026년 4월-6월 운영 통계

| 지표 | 도입 전 (Simple Timer) | 도입 후 (3계층) |
| :--- | :--- | :--- |
| **작업 완료율** | 71% (29% 누락) | 99.2% |
| **침묵 실패 (Silent Fail)** | 23건/월 | 0건/월 |
| **평균 재시도 횟수** | 0회 (재시도 없음) | 0.8회/작업 |
| **API Rate Limit 차단** | 8건/월 | 0건/월 |
| **에이전트 폭주 사고** | 3건/월 | 0건/월 |
| **사후 분석 시간** | 45분/사고 | 2분/사고 (JSON 상태 파일) |

### 실패 재시도 패턴 분석

```bash
$ cat ~/.hermes/infra/knowledge/cron-retry-stats.json
{
  "period": "2026-04-01 to 2026-06-15",
  "total_jobs_triggered": 3840,
  "completed_first_try": 3512,
  "required_retry": 298,
  "retry_success_rate": 0.97,
  "final_failures": 30,
  "retry_distribution": {
    "1_retry": 187,
    "2_retries": 62,
    "3_retries": 31,
    "4+_retries": 18
  },
  "failure_reasons": {
    "api_rate_limit": 12,
    "network_timeout": 8,
    "model_unavailable": 5,
    "other": 5
  }
}
```

3,840회 트리거 중 3,512회(91.5%)가 첫 시도에서 성공했습니다. 나머지 298회 중 97%가 재시도에서 성공했습니다. 최종 실패는 30건(0.8%)으로, 대부분 모델 자체의 일시적 장애였습니다.

---

## 💡 활용 예시: \"주간 뉴스 소화제\"

실제로 이 시스템이 어떻게 작동하는지 시나리오를 통해 살펴보겠습니다.

**1. 설정 (Registry)**
- **ID**: `job-news-digest`
- **스케줄**: `0 9 * * 1` (매주 월요일 오전 9시)
- **모델**: `Claude 3.5 Sonnet`
- **프롬프트**: \"이번 주 AI 트렌드 Top 3를 분석하여 요약해줘.\"

**2. 실행 프로세스**
- **T+0s**: 레지스트리에 의해 트리거 발생 $\\rightarrow$ **Wrapper**가 실행됩니다.
- **T+1s**: Wrapper가 `cron-20260616-0900` 세션을 생성하고, `state` 파일에 `\"status\": \"running\"`이라고 기록합니다.
- **T+2s**: Wrapper가 **Runner**를 호출합니다. Runner는 클로드 모델을 통해 뉴스를 요약합니다.
- **T+30s**: Runner가 요약본을 텔레그램으로 전송하고, Wrapper에게 `exit 0` (성공)을 반환합니다.
- **T+31s**: Wrapper가 상태를 `\"status\": \"completed\"`로 변경하고 로그를 저장하며 종료합니다.

**3. 예외 상황 (Edge Case): 네트워크 단절**
만약 Runner가 모델 호출 중 네트워크 오류로 `exit 1`을 반환했다면?
- **Wrapper**가 이를 즉시 감지합니다.
- **재시도 전략**: 1초 후 재시도 $\\rightarrow$ 실패 $\\rightarrow$ 2초 후 재시도 $\\rightarrow$ 성공.
- 결과적으로 사용자는 약간의 지연만 느낄 뿐, 작업이 완전히 누락되는 일은 없습니다. 만약 모든 재시도가 실패하면 Wrapper는 최후의 수단으로 사용자에게 \"뉴스 요약 작업이 최종 실패했습니다\"라고 알림을 보냅니다.

### 실제 registry.yaml 설정 예시

```yaml
# infra/cron/registry.yaml
jobs:
  - id: job-news-digest
    schedule: "0 9 * * 1"
    model: claude-3-5-sonnet
    provider: anthropic
    prompt_path: core/skills/prompts/news-digest.md
    notification: telegram
    max_retries: 5
    retry_base_delay: 1
    timeout_seconds: 300
    enabled: true

  - id: job-healthcheck
    schedule: "0 */6 * * *"
    model: glm-4
    provider: zai
    prompt_path: core/skills/prompts/healthcheck.md
    notification: discord
    max_retries: 3
    retry_base_delay: 2
    timeout_seconds: 120
    enabled: true
```

### 모니터링과 알림: 크론 작업 상태를 어떻게 관찰하는가?

 Wrapper는 모든 작업의 상태를 `state/cron-*.json`에 기록하지만, 사용자가 매번 파일을 열어서 확인하는 것은 비효율적입니다. Hermes는 작업 실패 시 실시간 알림과 주기적 상태 보고를 제공합니다.

```bash
# 실패 알림 예시 — Telegram 채널로 전송
$ cat core/scripts/cron-notify.sh | head -20
#!/bin/bash
# 작업 실패 시 알림 전송
JOB_ID="$1"
STATUS="$2"
ERROR="$3"

if [ "$STATUS" = "failed" ]; then
    # Telegram API를 통해 실패 알림 전송
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="⚠️ Cron 작업 실패: ${JOB_ID}
에러: ${ERROR}
상태 파일: ~/.hermes/runtime/state/cron-${JOB_ID}.json"
fi
```

### 상태 파일 수명 주기

`state/cron-*.json` 파일이 무한정 쌓이면 디스크 공간을 차지합니다. 자동 정리 정책이 적용됩니다.

- **7일 이내**: 유지 (사후 분석용)
- **7-30일**: 압축 (`cron-*.json.gz`)
- **30일 초과**: 삭제
- **실패한 작업**: 90일까지 유지 (재분석 필요 가능성 높음)

```bash
# 상태 파일 정리 — cron 작업
- id: job-cleanup-state
  schedule: "0 3 * * *"  # 매일 오전 3시
  script: core/scripts/cleanup-state-files.sh
  args: ["--retain-days", "7", "--compress-after", "7"]
```

---

## 🔗 관련 주제

- [이벤트 기반 도메인 통신](https://pheanor-agent.github.io/p-hermes/docs/blog/posts/event-driven-communication.md): 크론 작업 완료 후 다른 시스템을 깨우는 방법.
- [역할 기반 모델 라우팅 설계](https://pheanor-agent.github.io/p-hermes/docs/blog/posts/model-routing-design.md): 작업의 성격에 따라 어떤 모델을 Runner에 배정할 것인가.
- [5-Tier 물리 계층화 설계](https://pheanor-agent.github.io/p-hermes/docs/blog/posts/why-5-tier-architecture.md): 크론 레지스트리와 상태 파일이 저장되는 물리적 위치.

---

_Cron 3계층 아키텍처는 단순한 자동화를 넘어, AI가 스스로를 관리하고 보고하는 '엔지니어링적 신뢰성'의 기초가 됩니다._
