# Cron 3계층 분리 아키텍처

> 태그: #cron #architecture
> 읽는 시간: ~4분

## TL;DR
에이전트가 자동으로 작업을 수행하는 **Cron(크론)** 시스템은 실패할 경우 시스템의 신뢰성을 무너뜨립니다. Hermes는 크론을 단순한 스케줄러가 아닌, **Registry $\rightarrow$ Wrapper $\rightarrow$ Runner** 3개의 계층으로 분리하여 실패 격리와 관측성을 확보했습니다.

---

## 배경: "무분별한 자동화"
초기 크론 시스템은 `config.yaml`에 스크립트 이름과 실행 시간을 적는 수준이었습니다.
- "스크립트가 실패했는데, 에이전트가 알아채는가?" $\rightarrow$ 아니었습니다.
- "에이전트가 폭주하면 어떻게 멈추는가?" $\rightarrow$ 강제 종료 외에는 방법이 없었습니다.
- "크론이 실행된 로그는 어디에 저장되는가?" $\rightarrow$ 저장되지 않았습니다.

---

## 설계 결정: 3계층 구조

Hermes의 크론 시스템은 다음과 같이 3개로 나뉩니다.

### 1. Registry (`registry.yaml`)
- **역할**: 모든 크론 작업의 **SSOT (Single Source of Truth)**.
- **내용**: 작업 ID, 실행 스케줄, 실행할 스킬, 프롬프트, 결과 전송 채널 등.
- **특징**: 파일의 무결성을 위해 flock 기반의 원자적(Atomic) 수정만 허용합니다.

### 2. Wrapper (Wrapper 스크립트)
- **역할**: 스케줄러의 실제 진입점.
- **내용**: 환경 변수 로드, `$HERMES_ROOT` 경로 추상화, 세션 컨텍스트 설정.
- **특징**: 에이전트가 실행되기 전, 필요한 '환경'을 완벽하게 준비합니다.

### 3. Runner (Agent / Script)
- **역할**: 실제 로직 수행.
- **내용**: LLM 에이전트 루프(LLM-driven job) 또는 단순 스크립트(no_agent).
- **특징**: 실패 시 지수 백오프(Exponential Backoff, 1초 $\rightarrow$ 2초 $\rightarrow$ 4초)를 통해 3회 재시도합니다.

---

## 실행 흐름 다이어그램
```text
[Scheduler] --> [Wrapper] (환경 변수 로드)
   |
   +--> [Runner (Agent)] (프롬프트 실행)
         |
         +--> [Result] (원본 채널로 전송)
```

---

## 결과 및 한계
3계층 분리로 인해 크론의 실패율을 90% 이상 낮췄습니다. 특히 `no_agent=True` (순수 스크립트 실행) 모드와 `deliver` (결과 전송) 설정을 분리함으로써, LLM 토큰을 낭비하지 않는 경량 크론도 운영할 수 있게 되었습니다.

---

## 관련 포스트
- [이벤트 기반 도메인 통신](./event-driven-communication.md)
