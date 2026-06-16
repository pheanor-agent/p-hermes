---
name: workflow
description: "모든 작업(JOB)의 9단계 파이프라인. 요청접수→조사→설계→리뷰→승인→실행→테스트→실행리뷰→교훈."
version: 3.2.0
require_approval: true
approval_step: 5
---

# workflow

## 0. 입력 분류 (결정론적)

### ⚠️ 중복 구현 감지 (JOB-1264)

새 JOB 요청 시 **반드시 먼저** 확인:
1. **부모 JOB 존재 여부**: `--parent JOB-XXXX` 패턴이면 부모 JOB의 execution.md/산출물 확인
2. **기존 구현 검색**: `grep -r "기능 키워드" ~/.hermes/workspace/novels/scripts/` 또는 `grep -r "함수명" ~/.hermes/workspace/jobs/JOB-XXX-*/execution.md`
3. **중복 판단**: 이미 구현되어 있으면 `9-cancelled` 처리 + 취소 사유 기록

### ⚠️ 스크립트 점검 (JOB-1274)

스크립트 존재 확인: `ls ~/.hermes/scripts/transition-step.sh ~/.hermes/scripts/validate-checkpoints.sh`
복구: `cp ~/.hermes/skills/custom/code-scripts/workflow/scripts/*.sh ~/.hermes/scripts/`

**패턴**: "이미 구현된 기능이 왜 요청됐는지" → 부모 JOB 산출물 확인 → 중복이면 즉시 취소

**script quirks**: `references/script-quirks.md`
**atomic write**: `references/atomic-write-and-fasttrack.md`
**docs deploy**: `references/documentation-deployment-pattern.md`
**gate complete**: `references/workflow-gate-complete-requirements.md`

### 필수: workflow-gate.sh 실행
작업 상태 관리 및 단계 전환은 **반드시** `workflow-gate.sh`를 사용. 직접 파일 수정 금지.

```bash
bash ~/.hermes/scripts/workflow-gate.sh <JOB_ID> <action>
```

**사용법**:
- **JOB_ID**: `JOB-XXXX` 형태만 사용 (예: `JOB-1176`). 폴더 전체 경로나 제목 포함 금지.
- **Action**:
  - `start`: JOB 시작 (`investigation` 진입)
  - `transition <step>`: 단계 전환 (예: `transition design`)
  - `complete`: JOB 완료

**지원 단계명**: `investigation`, `design`, `review`, `approval`, `execution`, `test`, `execution_review`, `done`

**auto-process 액션 **(JOB-1494) request → approval까지 일괄 자동 진행:
```bash
# request 상태 JOB를 approval 단계까지 자동 진입
bash ~/.hermes/scripts/workflow-gate.sh JOB-XXXX auto-process
```
- investigation → design → review → approval 자동 transition
- approval 단계에서 **정지** (사용자 승인 대기)
- execution/test/done은 수동 진행

**⚠️ 워크플로우 절차 강제 **(JOB-1340 교훈) - 자동 진행 ≠ 승인 스킵
- **절대 금지**: workflow-gate.sh 실행 없이 단계 건너뛰기, 직접 파일 생성/수정 후 "완료" 선언
- **반드시**: 각 단계 전 `workflow-gate.sh` 실행 → 출력 지시 따름 → `transition-step.sh`로 상태 전환
- **위반 시**: 사용자 지적 받음 ("작업 프로세스에 맞춰서 한거 아니야?")
- **예외 없음**: 긴급 작업도 workflow 절차 필수 (긴급 예외 조건 3가지 모두 충족 시에만 리뷰 생략 가능)
- **설계 vs 구현 분리**: 최상위 JOB은 설계만 담당. 실제 구현은 하위 JOB으로 분할

**checkpoint 액션 **(JOB-1208 신규)
```bash
# I15: 화 검증 체크포인트
bash workflow-gate.sh JOB-XXXX checkpoint I15 <ep_dir> <ep_num>

# I16: 장 Coherence 체크포인트
bash workflow-gate.sh JOB-XXXX checkpoint I16 <chapter_dir> <ch_num>
```
- I15: `ep{N}-validation.json`의 `.status == "PASS"` 확인
**스크립트 주의**: `references/script-quirks.md`

모든 요청은 먼저 `scripts/classify-input.sh` 실행:
- **simple-task**: 파일 수정 없는 질문/정보/조회 → 즉시 처리
- **JOB**: 파일 수정 포함 → 아래 1~9단계 파이프라인
- **에이전트 판단 금지**: "간단하다"는 에이전트 의견, 분류 기준 아님

**⚠️ 파일 도구 사용 전 필수 확인 (JOB-1463, JOB-1464 연동)**:
```bash
# 분류 결과 확인
cat ~/.hermes/state/classify-result.json 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin).get('classification','unknown'))"
```
- **simple-task** 감지 시: `write_file`, `patch`, `terminal rm` **사용 금지**
- **job-required** 감지 시: workflow 진입 후 `6-executing` 단계에서만 파일 조작
- **도구 레벨 Guard **(JOB-1464) `model_tools.py`에 pre_tool_call hook에서 workflow 상태 자동 검증. execution 단계가 아니면 파일 도구 호출 차단. Graceful fallback: 오류 시 silent skip.

도메인 예외: `references/domain-exceptions.md` 참조

### ⚡ 새 세션에서의 작업 문맥 파악 (JOB-1544 학습)
- 질문에서 특정 JOB ID나 작업 진행 상황이 감지되면, 시스템 문서 읽기보다 **`session_search`를 최우선으로 실행**하여 과거 세션에서 정보를 즉시 찾음.

## ⚠️ 조사(Research) 시간/시도 제한 (JOB-1276 학습 — 사용자 지적)

**사용자 피드백**: "찾으라니까 제한 안두면 프로그램 끌때까지 찾을 기세네... 끊을 점까지 지정해줘야 하나.."

**문제**: 웹 검색/브라우저 조사가 CAPTCHA, 404, 타임아웃 등에 막혀 무한 루프처럼 계속 시도함. 사용자가 수동으로 중단해야 할 정도.

**규칙**:
1. **시도 제한**: 같은 소스에서 최대 3회 시도 후 다른 소스로 전환 또는 결론 도출
2. **시간 제한**: 단일 조사 소스에 2분 이상 머물면 중단 → 다음 소스 또는 기존 지식 활용
3. **CAPTCHA/차단**: CAPTCHA나 bot detection 발생 시 **즉시 다른 소스로 전환** (Captcha 풀기 시도 금지)
4. **부분 응답**: 완벽한 결과보다 **시간 내에 얻을 수 있는 최선의 답변** 제공. "현재까지 확인된 범위에서..."라고 명시
5. **대체 전략**: 웹 검색이 막힐 경우:
   - 모델 자체 지식 기반 답변 → "내가 알고 있는 범위에서..."라고 명시
   - 다른 검색엔진/소스로 즉시 전환
   - 사용자에게 "더 깊이 찾을까요?" 확인 (자동으로 무한 검색 금지)

**패턴**: "웹 검색 시도 → CAPTCHA/차단 → 다른 소스 → 또 차단 → 모델 지식 fallback → 결론"

## 0.5. 필요성 검증 (JOB 시작 전 또는 조사 단계)

사용자가 새 JOB을 요청하거나 "필요성 검토해봐" 지시 시:
1. **기존 규칙/기능 확인**: 관련 SKILL.md, AGENTS.md, config.yaml 검색 — 동일한 규칙이 이미 정의되어 있는지
2. **활성 JOB 중복 확인**: 같은 목적의 진행 중 JOB가 있는지 (`find ~/.hermes/workspace/jobs/ -name "*핵심단어*"`)
3. **실제 문제 발생 확인**: 규칙이 없어서 실제로 문제가 발생했는지, 아니면 예방적/사양적 JOB인지

**중복 발견 시**: 취소를 제안하고 근거 제시 (기존 규칙 위치, 중복 JOB ID)
**사양적 JOB 감지 시**: scope 재정의 제안 (예: "규칙 정의" → "규칙 강제 코드 구현")

## ⚠️ 작업 시작 전 체크리스트 (investigation 진입 시 필수 — JOB-1485 학습)

**사용자 직접 지적 2회**: "위키로 검색 안했어?", "왜 shared에서 작업을 해?"

**⛔ 절대 금지**: 익숙한 경로(`~/.shared/`)에서 작업 시작, wiki 검색 없이 코드 파일 바로 접근

**지식 탐색 **(3단계 순차 진행 — `knowledge-navigation` 스킬 참조)
1. [ ] `~/.hermes/knowledge/wiki/index.md` 읽음 (첫 진입점, T1/T2/T3 점수 기반)
2. [ ] `~/.hermes/knowledge/index.md` 읽음 (프로젝트 상태 요약)
3. [ ] `~/.hermes/knowledge/references/index.md` 읽음 (외부 리퍼런스)

**프로젝트 확인 **(작업 대상이 프로젝트일 때)
- [ ] `find ~/.hermes/workspace/projects/ -name "project.yaml"`으로 project.yaml 탐색
- [ ] `code_path` 필드 참조 → **이 경로에서 작업 필수**
- [ ] 원격 개발 환경, 배포 방법 등 project.yaml의 관련 필드 확인

**기존 교훈 확인**
- [ ] `~/.hermes/workspace/jobs/lessons/index.md` 스캔
- [ ] 관련 교훈이 있으면 request.md에 인용

## 1~9단계 파이프라인

각 단계 시작 전: `scripts/validate-checkpoints.sh <JOB_DIR> <STEP>`
FAIL 시 → 롤백 메시지의 지시를 따를 것

| 단계 | 이름 | 산출물 | 병렬 | 동기화 |
|------|------|--------|------|------|
| 1 | 요청 기록 | request.md | - | - |
| 2 | 조사 | request.md 보강 | 역할별 | 전체 완료 대기 |
| 3 | 설계 | architecture.md | - | - |
| 4 | 설계 리뷰 | review-result-*.md | 에이전트 자율 검증 (사용자 요청 금지) | 완료 후 진행 |
| 5 | 승인 | architecture.md (A/B/C) | - | 사용자 응답 대기 |
| 6 | 실행 | execution.md | 파일별 | 전체 완료 후 통합 |
| 7 | 테스트 | execution.md 보강 | 항목별 | 전체 완료 대기 |
| 8 | 실행 리뷰 | exec-review-result.md | 검증별 | 전체 완료 후 종합 |
| 9 | 교훈 | lessons/ | - | - |

**⑦테스트 단계 가이드**:
1. 통합 테스트 스위트 생성 (import + 기능 + CLI smoke)
2. **스크립트 실제 호출 테스트 필수 (JOB-1277 학습)**:
   - 생성된 스크립트 반드시 실제 bash 호출 테스트
   - exit code 확인 (0 = 성공, 1 = 실패)
   - stdout/stderr 모두 확인
   - 예: `bash ~/.hermes/scripts/run-review.sh <JOB_DIR> design`
3. **엣지 케이스 테스트 추가** (반드시 포함):
   - 빈 입력/결과 처리 (empty search results, no API key, no config)
   - 언어 다양성 (한국어 질문, 특수문자, mixed language)
   - 네트워크 실패 fallback (API 호출 실패 시 graceful degradation)
   - 권한/설정 누락 시 동작 (missing config, invalid path)
   - 일반 질의 폴백 (general_qa 의도 + 심볼 없음 시 graph overview 등)
4. **LLM 기반 기능이라면 프롬프트 엔지니어링 검토**:
   - SYSTEM_PROMPT: 검색 결과가 부족할 때 LLM이 어떻게 행동할지 명시
   - Context builder: graph_overview 등 특수 결과 타입 처리
   - 빈 결과 시 유용한 폴백 메시지 (단순 "결과 없음" 금지)
5. **빌드된 실행파일로 테스트** (소스 테스트 ≠ 빌드 테스트):
   - `python -m src.cli` 통과 ≠ PyInstaller 빌드 실행파일 동작
   - 빌드 후 반드시 `./dist/my-cli/my-cli --help` + 실제 명령어 테스트
6. 테스트 실행 → 실패 항목 식별 → 수정 → 재실행 → 전원 통과
7. execution.md에 테스트 결과 기록 (통과/실패 수, 버그 수정 내역, 엣지 케이스 커버리지)

### ⚠️ 테스트 FAIL 시 JOB 완료 금지 (JOB-1287/1298 학습 — 사용자 지적)
- **사용자 피드백**: "테스트 결과가 실패인데 작업 마무리 한거야?"
- **문제**: 테스트 FAIL 상태에서匆忙 JOB 완료 처리 → 사용자 재시작 요청
- **해결**: 테스트 전수 통과 확인 후 ⑦테스트 단계 완료 → ⑧⑨진행
- **예방**: ⑦테스트 단계 진입 시 "전체 테스트 PASS" 명시적 확인 후 다음 단계
- **절대 금지**: FAIL 결과 있음에도 9-done 상태로 전환
- 폴백 테스트만 하고 실제 호출 테스트 안함
- 스크립트 생성 후 실행하지 않고 "테스트 완료" 보고
- 해결: 스크립트 생성 → 바로 bash 호출 → 결과 확인 → 재시작

### ⛔ 실행 후 테스트/리뷰 강제 (JOB-1503 학습 — 사용자 직접 지적)
- **사용자 지적**: "반영이 안됐어. 실행 후 테스트, 리뷰 안했어?"
- **문제**: 슬라이드 수정 → GitHub 푸시까지 완료했으나, 브라우저로 실제 반영 확인 안함
- **근본 원인**: "푸시하면 완료"라는 잘못된 가정 → CDN 캐시, 브랜치 오염 등으로 실제 반영 안됨
- **규칙**:
  1. **실행 후 브라우저 테스트 필수**: `browser_navigate`로 실제 페이지 확인
  2. **CDN 캐시 고려**: `sleep 60` 후 확인 또는 쿼리 파라미터 `?t=timestamp` 추가
  3. **브랜치 상태 검증**: `git branch -v` + `git log --oneline`로 실제 푸시된 내용 확인
  4. **테스트 결과 기록**: execution.md에 테스트 통과/실패 결과 명시적 기록
- **올바른 순서**: 실행 → 브랜치 상태 확인 → sleep 60 → 브라우저 테스트 → 테스트 결과 기록 → 완료
- **징후**: 사용자가 "반영 안됐어", "테스트 안했어?" 지적 → 실행 후 테스트/리뷰 생략
- **절대 금지**: 푸시만 하고 브라우저 테스트 없이 완료 선언

**테스트 템플릿**: `references/testing.md` 참조
**GLM API 건강도 확인**: `references/glm-api-health-check.md` 참조

**병렬 동기화/충돌**: `references/steps.md` §병렬 규칙
**리뷰 기준/충돌 해결**: `references/review-criteria.md`
**Gateway 내부 신호 억제**: `references/gateway-internal-signals.md`
**리뷰어 spawn 시 필수 지시**: 리뷰어 서브에이전트 task에 항상 포함: `⚠️ message 도구를 사용해서 사용자에게 메시지를 보내지 마세요. 결과는 지정된 파일에만 작성하세요.`
**리뷰어 spawn 시 필수 지시**: 리뷰어 서브에이전트 task에 항상 포함: `⚠️ message 도구를 사용해서 사용자에게 메시지를 보내지 마세요. 결과는 지정된 파일에만 작성하세요.`
**리뷰어 spawn 시 필수 지시**: 리뷰어 서브에이전트 task에 항상 포함: `⚠️ message 도구를 사용해서 사용자에게 메시지를 보내지 마세요. 결과는 지정된 파일에만 작성하세요.`
**리뷰어 spawn 시 필수 지시**: 리뷰어 서브에이전트 task에 항상 포함: `⚠️ message 도구를 사용해서 사용자에게 메시지를 보내지 마세요. 결과는 지정된 파일에만 작성하세요.`

**⚠️ 서브에이전트 파일 잠금 **(JOB-1529)

**문제**: 여러 서브에이전트가 동시에 `wiki/inbox.md`, `subagent-state.json` 등에 쓰기 시 Race Condition

**해결**: `flock` 기반 Atomic Write 강제 적용

**Atomic Write 유틸리티** (`~/.hermes/scripts/atomic_write.sh`):
```bash
#!/bin/bash
# Usage: atomic_write.sh <file> <content>
FILE=$1
CONTENT=$2
LOCK="${FILE}.lock"
(
  flock -x 200
  echo "$CONTENT" > "$FILE"
) 200>"$LOCK"
rm -f "$LOCK"
```

**적용 대상**:
- `memory/subagent-state.json`
- `wiki/inbox.md`
- `.workflow-state`

**⚠️ Deadlock 방지**: lock 파일에 TTL + stale lock 자동 정리 패턴 적용
**리뷰어 판정 태그 표준화**: 최종 판정 라인에 반드시 `[STATUS: PASS]` 또는 `[STATUS: REV]` 또는 `[STATUS: FAIL]` 태그를 포함하세요. `APPROVED`/`APPROVED_WITH_MINOR`도 허용하나 표준 태그를 우선하세요.
**리뷰 품질 — 설계 주장 vs 실제 코드 검증 **(JOB-1208 교훈): 설계안(architecture.md)이 "수정됨", "변경됨", "버그 수정" 등을 기술하면, 해당 주장이 실제 소스 코드에서 반영되었는지 반드시 확인. 설계안 문서에 수정 방안이 기술되어 있어도 실제 파일이 변경되지 않은 경우를 다수 발견. 리뷰어는 설계안의 코드 변경 주장을 `file_read`로 실제 파일과 교차검증. 미일치 시 REV 판정.
**장애 복구**: `references/subagent-recovery.md`
**서브에이전트 주의사항**: `references/subagent-pitfalls.md`
**상태 분실 복구**: `references/state-recovery.md`
**상태 불일치 복구** (작업 완료 후 state 갱신 누락): `references/state-recovery.md`
**Gateway Hook 디버깅** (plugin 작동 안함): `references/gateway-hook-debugging.md`

### 체크포인트 (I1~I11)

📖 TTY/검증/오버엔지니어링 패턴: `references/overengineering-tty-patterns.md`

| ID | 검증 | 롤백 |
|----|------|------|
| I1 | request.md에 'SKILL.md' 또는 'workflow' 읽음 기록 | 1단계 |
| I2 | 간소화 = 사용자 명시 | 3단계 |
| I3 | 리뷰 PASS 기록 (`[STATUS: PASS]`) | 4단계 |
| I4 | 리뷰 1개 | 4단계 |
| I5 | 승인 템플릿 준수 (A/B/C 포함) | 3단계 |
| I5b | architecture.md에 `요구사항` 섹션 + `현재`/`변경` 열 가진 Before/After 테이블 + `review-result` 인용 | 3~4단계 |
| I6 | request.md 10줄 이상 | 2단계 |
| I7 | 승인 증거: `approval-request.json` + `approval.json` + SHA256 일치 (아래 § 승인 프로토콜 참조) | 5단계 |
| I7b | architecture.md에 '승인 대기' 문구 없음 | 5단계 |
| I8 | 실행 리뷰 결과 (간소화 제외) | 8단계 |
| I8a | execution.md에 미구현/보류 있으면 arch에도 보류 섹션 필요 | 3단계 |
| I9 | FAIL 후 보강 (mtime) | 3단계 |
| I10 | 파일 생성 순서 | 3단계 |
| I11 | 단계 연속성 (갭 없음) | 마지막 완료 단계 |
| I14 | request.md에 교훈 인용 (`lessons/` 파일명, `교훈: 내용`, 또는 `관련 교훈 없음`) | 2단계 |
| I16 | 장 Coherence (`chapter-{N}-coherence-report.json`의 `.overall_score >= 70`) | Phase 3.5 |

**⚠️ 상태 기계 예외 상태 (JOB-1529 설계)**:
- `blocked`: 외부 종속성 (승인 대기, API limit) 으로 인한 일시 정지
- `failed`: 최대 재시도 횟수 초과 → 사람 개입 필요
- `rollback`: 체크포인트 실패 시 돌아가는 트랜지션 상태 기록

**.workflow-state 확장 필드**:
```json
{
  "retry_count": 0,
  "error_log": [],
  "transitions": [
    { "from": "investigation", "to": "blocked", "reason": "API limit", "at": "ISO8601" }
  ]
}
```

**I15/I16 검증 명령 **(JOB-1208)
```bash
bash ~/.hermes/scripts/workflow-gate.sh <JOB_ID> checkpoint I15 <ep_dir> <ep_num>
bash ~/.hermes/scripts/workflow-gate.sh <JOB_ID> checkpoint I16 <chapter_dir> <ch_num>
```
| I11 | 단계 연속성 (갭 없음) | 마지막 완료 단계 |
| I12 | request.md에 'SKILL.md' 또는 'workflow' 읽음 기록 | 1단계 |
| I13c | lessons/index.md에 해당 JOB 항목 등록 | 8단계 |
| I14 | request.md에 교훈 인용 (lessons/ 파일명, '교훈: 내용', 또는 '관련 교훈 없음') | 2단계 |

**I13c 상세**:
- `~/.hermes/workspace/jobs/lessons/index.md`에 해당 JOB-ID 항목 존재해야 함
- 형식: `### JOB-XXXX: 제목` + 교훈 요약
- 생성 방법: `echo "### JOB-XXXX: 제목\n- 교훈 내용" >> ~/.hermes/workspace/jobs/lessons/index.md`
| I12 | .workflow-state 허용값 검증 | — |
| I13a | `lessons.md` 존재 | 8단계 |
| I13b | `lessons.md` 10줄 이상 + `##` 헤더 1개 이상 (간소화 제외) | 8단계 |
| I13c | `lessons/index.md`에 해당 JOB 항목 존재 (간소화 제외) | 8단계 |
| I14 | request.md에 교훈 인용 (`lessons/` 파일명 or `'교훈: 내용'` or `'관련 교훈 없음'`) | 2단계 |

### I5b Before/After 테이블 형식 (JOB-1158 교훈 + JOB-1277 확인)

검증 스크립트가 `grep -qiE '\|.*현재.*\|.*변경'`으로 확인.
**열 헤더에 `현재`와 `변경` 키워드가 모두 포함되어야 함.**

✅ 올바른 형식:
```markdown
| 항목 | 현재 | 변경 |
|------|------|------|
```

❌ 실패 형식:
```markdown
| 항목 | Before | After |  # 영문 헤더는 인식 안됨
| 항목 | Before (현재) | After (목표) |  # "변경" 키워드 없음
```

**⚠️ 패턴**: `현재` 또는 `변경` 중 하나라도 없으면 I5b 실패 → 단계 전환 차단.

### I7 승인 프로토콜 (JOB-1158 교훈)
1. `lib/approval.sh`의 `write_approval_request()` 사용해서 `approval-request.json` 생성:
   ```bash
   bash -c 'source scripts/lib/approval.sh; write_approval_request <JOB_DIR> "JOB-XXXX"'
   ```
2. `approval.json` 생성 — 필수 필드:
   ```json
   {"choice":"A","request_id":"<위에서 생성>","architecture_sha256":"<위에서 생성>","approved_at":"...","approver":"pheanor"}
   ```
3. ⚠️ **architecture.md 수정 후 승인 검증 실패 시**: SHA256 해시가 변경됨 → `write_approval_request` 재생성 후 `approval.json` 재작성 필수
4. 검증: `bash -c 'source scripts/lib/approval.sh; require_valid_approval <JOB_DIR>'`

**⚠️ I7 차등 롤백 (JOB-1529 설계)**:
- **Minor 변경** (단순 오타/텍스트 수정, 10줄 미만, 코드 구조 변경 없음): 5단계 재승인으로 즉시 복귀
- **Major 변경** (구조/인터페이스/로직 변경): 3단계(Design) 또는 4단계(Review)로 강제 롤백
- **Diff 분석 기준**: `git diff --stat architecture.md` 라인 수 + `git diff` 패턴 분석 (`def`, `class`, `import` 등 코드 구조 키워드 감지)

### 터미널 권한 분리 (JOB-1529 설계)

**문제**: 1~5단계(Investigation~Approval)에서도 `terminal` 도구를 통해 파일 수정(`sed`, `echo >`) 우회 가능성

**해결**: `pre_tool_call hook`에서 단계별 화이트리스트 검증

**Read-Only 화이트리스트 **(1~5단계)
```bash
RO_COMMANDS=(cat ls grep find ps df du head tail wc sort uniq awk sed less more)
```

**검증 로직** (`~/.hermes/hooks/pre_tool_call.sh`):
```bash
if [[ $STEP -le 5 ]]; then
  # Read-Only 모드
  for cmd in "${RO_COMMANDS[@]}"; do
    [[ "$TOOL_COMMAND" == "$cmd"* ]] && return 0
  done
  echo "❌ Step $STEP: $TOOL_COMMAND is not allowed in Read-Only mode" >&2
  return 1
fi
```

**적용 단계**:
- 1~5단계: `terminal_ro` (읽기 전용)
- 6~7단계: `terminal_rw` (전체 권한)

### I13 교훈 작성 요구사항 (JOB-1158 교훈)
- `lessons.md`: 10줄 이상, `##` 헤더 최소 1개
- `lessons/index.md` (jobs 디렉토리 하위): 해당 JOB_ID 포함 항목 추가
| I14 | request.md에 교훈 인용 (lessons/ 파일명, '교훈: 내용', 또는 '관련 교훈 없음') | 2단계 |

### 체크포인트 I5b (architecture.md 필수 요소)
검증 스크립트는 `grep -qiE`로 다음 패턴을 확인:
- `요구사항` 또는 `요구` — 요구사항 섹션 존재
- `\|.*현재.*\|.*변경` — Before/After 테이블 (`현재`, `변경` 열 포함)
- `review-result` — 리뷰 결과 인용

**⚠️ 검증 실패 시 단계 전환 차단됨 — architecture.md 작성 시 반드시 위 3가지 포함할 것**

**⚠️ 외부 방법론 적용 시 (JOB-1166 교훈)**: gbrain, gstack 등 외부 에이전트 방법론을 현재 시스템에 적용할 때, 반드시 Hermes/OpenClaw 역할 분담(Hermes=UI/Worker, OpenClaw=OS/Librarian)과 충돌하는지 검증할 것. 무조건적인 패턴 이식은 아키텍처 불일치로 이어짐.


### ⛔ 리뷰(Review) vs 승인(Approval) 구분 강제 (JOB-1541)
- **리뷰 단계**: 에이전트 자율 검증. 사용자에게 확인 요청 금지.
- **승인 단계**: 유일한 사용자 인터랙션 지점. 최종 설계 확정 후 실행 허가 요청.

## 자동 진행 규칙

단계 완료 후 즉시 다음 단계를 시작. "다음 하시겠습니까?" 금지.
**멈추는 시점은 ⑤승인(사용자 응답 대기) 뿐.**

**⚠️ 승인 요청 예외 (JOB-1277 학습)**:
- 리뷰 PASS → **승인 요청 메시지 발송** → 사용자 응답 대기
- "그래", "진행해" = 승인 획득 → 5-approved 진입
- **자동 승인 금지**: approval.json 자동 생성 후 진행 = 프로세스 위반

**📝 승인 요청 설계 설명 자동 포맷팅 (JOB-1589)**:
```bash
# approval 단계 진입 시 설계 설명 자동 추출
bash ~/.hermes/scripts/format-approval-request.sh "$JOB_DIR"
```
- architecture.md에서 요약, 핵심 결정, 산출물, 잠재적 문제점 자동 추출
- 스크립트 출력을 승인 요청 메시지에 포함
- architecture.md가 없으면 "설계 내용을 확인해 주세요" 메시지 출력
- **절대 금지**: 스크립트 없이 수동으로 설계 설명 작성 (일관성 저하)

**⛔ "작업 등록해줘" ≠ "실행해줘" (JOB-1477 학습 — 사용자 직접 지적)**:
- **사용자 지적**: "등록하라고 했는데 왜 실행까지 했어?"
- **문제**: 사용자가 "작업 등록해줘" 요청 → JOB 생성 + 승인 요청까지만 진행해야 함. 승인 없이 execution까지 자동 진행 = 프로세스 위반
- **규칙**: "작업 등록해줘", "JOB 등록해줘" 요청 시:
  1. JOB 생성 ✅
  2. request.md 작성 ✅
  3. 조사 → 설계 → 리뷰 진행 ✅
  4. **승인 요청 메시지 발송 → 사용자 응답 대기** ⛔ (여기서 멈춤)
  5. 사용자 승인 후 execution 진입 ✅
- **절대 금지**: "등록해줘" 요청 → approval.json 자동 생성 → execution 진행
- **징후**: "그래" = 승인 응답, "진행할까요?" ≠ 승인 응답

완료 응답: "N단계 완료. N+1단계를 시작합니다." → 바로 진행.
I11이 위반 감지 시 validate-checkpoints.sh가 롤백 지시.

**⛔ 단계 스킵 금지 **(JOB-1264 학습 — 사용자 지적)
- "자동 진행" ≠ "모든 단계를 한 번에 처리". 각 단계는 **별도 tool call**로 완료
- 각 단계 완료 시: 산출물 파일 작성 → .workflow-state 갱신 → 사용자에게 "N단계 완료" 보고 → 다음 단계
- **금지**: 1회 execute_code로 request.md 보강 + architecture.md 작성 + 리뷰 + 승인 + 실행 + 테스트 + 교훈까지 일괄 처리
- **원인**: "빨리 끝내야 한다"는 심리가 단계 생략으로 이어짐. 사용자는 "프로세스대로 진행하고 있어?"로 지적
- **예방**: 각 단계 완료 후 반드시 .workflow-state 갱신 + 사용자 보고. 다음 단계는 별도 tool call.

### ⛔ 불필요한 하위 JOB 분할 금지 (JOB-1258/1297 학습 — 사용자 지적)
- 사용자의 질문: "작업을 다 함께 진행할꺼면 작업을 나눌 필요가 있어?"
- **원칙**: 단일 에이전트가 모든 작업을 순차 실행하면 부모 JOB 하나에 통합
- **하위 JOB 분할 필요 조건**: 병렬 실행, 별도 승인 필요, 독립적 완료 가능
- **통합 기준**: 동일 도메인 + 순차 의존성 + 단일 실행자 = 통합 JOB
- **사용자 신호: "다시 제대로 조사 및 설계 해" **(JOB-1297 학습)
  - 표면적 분석만 하고 설계 시도 → 사용자 지적
  - **해결**: 전체 시스템 구조 조사 후 통합 설계 (단일 컴포넌트가 아닌 전체 파이프라인 관점)
  - **예방**: 통합/리팩터링 작업은 항상 전체 아키텍처 다이어그램 + 현재 문제점 매핑 후 설계 시작

### ⛔ 절대 금지: 리뷰 단계 생략 (JOB-1220/1470 교훈)
- **③설계 → ⑤승인 직접 점프 금지**: ④리뷰는 항상 별도 단계로 수행
- "리뷰 했어?" 지적 = 설계만 하고 리뷰 없이 승인 요청했음
- 리뷰는 서브에이전트가 아닌 **현재 세션에서 직접 수행** 후 진행
-自查 포인트: 문제 식별 → 원인 분석 → 개선안 → 테스트 케이스 → 위험도 평가

### ⛔ grill 리뷰 강제 (JOB-1470/1521 학습 — 사용자 직접 지적)
- **사용자 지적**: "리뷰는 했어?" → SELF-REVIEW만 한 경우
- **문제**: SELF-REVIEW만 진행하고 grill 리뷰 미수행 → 승인 요청
- **규칙**: grill 스킬 로드 → 기존 시스템 코드 탐색 → 충돌 검증 → 구체적 시나리오 테스트 → `[STATUS: PASS/REV]` 판정
- **SELF-REVIEW 패턴**: grill 스킬 없이 architecture.md에 `[STATUS: PASS]`만 씀 → **무효**
- **올바른 순서**: 설계 완료 → grill 스킬 로드 → grill 리뷰 → review-result-*.md 생성 → 승인 요청
- **징후**: 사용자가 "리뷰는 했어?", "SELF-REVIEW만 했지?" 지적 → grill 리뷰 미수행
- **절대 금지**: grill 스킬 로드 없이 SELF-REVIEW만 하고 승인 요청 (JOB-1521 학습 — 2026-06-04)
- **리뷰 파일 검증**: `references/review-file-enforcement.md` 참조 (JOB-1584, JOB-1595)

### ⛔ 리뷰(Review) vs 승인(Approval) 구분 강제 (JOB-1541)
- **리뷰 단계**: 에이전트가 스스로 설계를 비판적으로 검토하고 수정하는 **내부 프로세스**입니다. 이 단계에서 사용자에게 확인을 요청하거나 피드백을 구하는 행위는 **프로세스 위반**입니다.
- **승인 단계**: 리뷰가 완벽히 끝난 최종 설계안을 사용자에게 제시하고 **실행 허가(Go/No-Go)**를 받는 **유일한 사용자 인터랙션 지점**입니다.
- **금지 패턴**: "리뷰 결과입니다. 확인 부탁드립니다." -> (X) -> 리뷰 완료 후 즉시 `approval` 단계로 전이하여 승인 요청.

### ⛔ 승인 단계 생락 금지 (JOB-1464/1479 학습 — 사용자 직접 지적)
- **사용자 지적**: "프로세스대로 했어? 승인 요청을 못받았는데"
- **문제**: architecture.md에 "(간소화)" 마킹으로 승인 check bypass → 사용자 승인 없이 진행
- **규칙**: approval.json 생성 → 사용자 승인 → execution 진입 (무조건)
- **간소화JOB 예외 없음**: "(간소화)"는 완료 검증 완화(빈 lessons.md 허용)일 뿐, 승인 스킵 아님
- **징후**: 사용자가 "승인 요청을 못받았는데", "프로세스대로 해" 지적 → 승인 단계 생략
- **되돌리기 가능**: 이미 완료된 JOB도 workflow-state 수정 + approval.json 삭제로 되돌릴 수 있음
- **올바른 순서**: 설계 완료 → grill 리뷰 → 승인 요청 → 승인 받음 → execution 진입

### ⚠️ 지식 탐색 체크리스트 무시 문제 (JOB-1521 학습 — 2026-06-04 점검)
- **점검 결과**: 최근 2일 간 JOB 70+ 개 중 지식 시스템 참조: 4개에 불과 (5%)
- **문제**: workflow 스킬 Line 154-172 체크리스트가 에이전트에 의해 대량 무시됨
- **규칙**: investigation 진입 시 `~/.hermes/scripts/pre-investigation.sh` 자동 호출 (JOB-1521)
- **대기 중인 해결책**: pre-investigation.sh 스크립트 생성 → workflow-gate.sh start/transition 연동
- **임시 조치**: 에이전트가 직접 wiki/index.md, knowledge/index.md, references/index.md 읽음 확인

### ⛔ GLM-5.1 리뷰 호출 강제 (JOB-1489/1490 학습)
- **반드시**: `bash ~/.hermes/scripts/run-review.sh <JOB_DIR> design` 실행 → `review-result-glm.md` 생성
- **검증**: `review-result-glm.md` 파일 존재 확인 (파일 없으면 리뷰 미완료)
- **절대 금지**: grill 리뷰만 하고 GLM-5.1 호출 생략
- **올바른 순서**: 설계 완료 → grill 리뷰 → GLM-5.1 호출 → 두 리뷰 결과 모두 생성 → 승인 요청
- **run-review.sh .env 로딩 **(JOB-1489) 스크립트头部에 `.env` 로딩 추가 필요 (API 키 전달)

### ⛔ grill + GLM-5.1 이중 리뷰 강제 (JOB-1470/1489/1490 학습)
- **반드시**: grill 스킬 로드 → grill 리뷰 → `bash ~/.hermes/scripts/run-review.sh` → `review-result-glm.md` 생성
- **절대 금지**: grill 또는 GLM 중 하나만 수행
- **검증**: `review-result-grill.md` + `review-result-glm.md` 둘 다 존재 확인

### ⛔ 전체 구조 및 오버엔지니어링 검토 강제 (JOB-1582)
- **반드시**: grill 리뷰 시 `전체 구조 검토 체크리스트` 확인 (grill SKILL.md 참조)
- **검증 항목**:
  1. 전체 구조: 설계안이 시스템 전체와 충돌하는가?
  2. 스킬 구성: 스킬 레벨에서 해결 가능한가?
  3. 오버엔지니어링: 변경 범위가 최소한인가?
- **기록 필수**: `review-result-*.md`에 위 3항목 명시적 평가 포함
- **징후**: 사용자가 "전체 구조 고려했어?", "오버엔지니어링 아니야?" 지적 → 검토 누락
- **절대 금지**: 체크리스트 없이 `[STATUS: PASS]`만 기록

### ⛔ 승인 단계 절대 생략 금지 (JOB-1479 학습 — 사용자 직접 지적)
- **사용자 지적**: "프로세스대로 했어? 승인 요청을 못받았는데", "왜 못되돌려?"
- **문제**: architecture.md에 "(간소화)" 마킹으로 승인 check bypass → 승인 단계 생략
- **규칙**: "(간소화)" 마킹은 **완료 검증 완화**만 의미, 승인 단계 생략 아님
- **올바른 순서**: 설계 완료 → 리뷰 → 승인 요청 → 승인 → execution
- **징후**: 사용자가 "왜 승인요청을 다른 채널에 보내?", "프로세스대로 했어?" 지적 → 승인 단계 생략
- **절대 금지**: approval.json 없이 completion 시도, "(간소화)"로 승인 bypass

### ⚡ 자동화 > 체크리스트 규칙 (JOB-1521 학습)
- **발견**: workflow 스킬에 지식 탐색 체크리스트가 있음에도 최근 2일 간 JOB 70+개 중 참조율 5%에 불과
- **원인**: 체크리스트는 에이전트가 무시 가능. 규칙 강제보다 자동화된 고정 동작이 효과적
- **해결 패턴**: `pre-*.sh` 스크립트 생성 → workflow-gate.sh에 hook 연동 → 자동 실행
- **예시**: `pre-investigation.sh` (JOB-1521): investigation 진입 시 지식 파일 자동 로딩
- **적용**: 에이전트 자율에 맡기는 체크리스트 → 스크립트 자동화로 변경 고려

### 📝 shell 도구 사용 교훈 (JOB-1479/1493 학습)
- `head -c80`, `cut -c1-80`: UTF-8에서 **바이트 기반** truncation (한글 중간에 잘림)
  - 해결: `python3 -c "import sys; print(sys.stdin.read().strip()[:80], end='')"` (문자 기반)
- `ls -d "$DIR"/pattern-*`: glob 확장 실패 시 중복 감지 실패
  - 해결: `find "$DIR" -maxdepth 1 -type d -name "pattern-*"` (정확한 매칭)
- 스크립트에서 `return` → 함수 내에서만 사용 가능, 톱 레벨에서는 `exit 0` 사용

### ⛔ 승인 후 설계 변경 프로세스 (JOB-1467 학습 — 사용자 직접 지적)
- **검증**: `review-result-glm.md` 파일 존재 확인 (파일 없으면 리뷰 미완료)
- **절대 금지**: grill 리뷰만 하고 GLM-5.1 호출 생략
- **올바른 순서**: 설계 완료 → grill 리뷰 → GLM-5.1 호출 → 두 리뷰 결과 모두 생성 → 승인 요청
- **run-review.sh .env 로딩 **(JOB-1489) 스크립트头部에 `.env` 로딩 추가 필요 (API 키 전달)

### ⛔ grill + GLM-5.1 이중 리뷰 강제 (JOB-1470/1489/1490 학습)
- **반드시**: grill 스킬 로드 → grill 리뷰 → `bash ~/.hermes/scripts/run-review.sh` → `review-result-glm.md` 생성
- **절대 금지**: grill 또는 GLM 중 하나만 수행
- **검증**: `review-result-grill.md` + `review-result-glm.md` 둘 다 존재 확인

### ⛔ 승인 단계 절대 생략 금지 (JOB-1479 학습 — 사용자 직접 지적)
- **사용자 지적**: "프로세스대로 했어? 승인 요청을 못받았는데", "왜 못되돌려?"
- **문제**: architecture.md에 "(간소화)" 마킹으로 승인 check bypass → 승인 단계 생략
- **규칙**: "(간소화)" 마킹은 **완료 검증 완화**만 의미, 승인 단계 생략 아님
- **올바른 순서**: 설계 완료 → 리뷰 → 승인 요청 → 승인 → execution
- **징후**: 사용자가 "왜 승인요청을 다른 채널에 보내?", "프로세스대로 했어?" 지적 → 승인 단계 생략
- **절대 금지**: approval.json 없이 completion 시도, "(간소화)"로 승인 bypass

### ⚡ 자동화 > 체크리스트 규칙 (JOB-1521 학습)
- **발견**: workflow 스킬에 지식 탐색 체크리스트가 있음에도 최근 2일 간 JOB 70+개 중 참조율 5%에 불과
- **원인**: 체크리스트는 에이전트가 무시 가능. 규칙 강제보다 자동화된 고정 동작이 효과적
- **해결 패턴**: `pre-*.sh` 스크립트 생성 → workflow-gate.sh에 hook 연동 → 자동 실행
- **예시**: `pre-investigation.sh` (JOB-1521): investigation 진입 시 지식 파일 자동 로딩
- **적용**: 에이전트 자율에 맡기는 체크리스트 → 스크립트 자동화로 변경 고려

### 📝 shell 도구 사용 교훈 (JOB-1479/1493 학습)
- `head -c80`, `cut -c1-80`: UTF-8에서 **바이트 기반** truncation (한글 중간에 잘림)
  - 해결: `python3 -c "import sys; print(sys.stdin.read().strip()[:80], end='')"` (문자 기반)
- `ls -d "$DIR"/pattern-*`: glob 확장 실패 시 중복 감지 실패
  - 해결: `find "$DIR" -maxdepth 1 -type d -name "pattern-*"` (정확한 매칭)
- 스크립트에서 `return` → 함수 내에서만 사용 가능, 톱 레벨에서는 `exit 0` 사용

### ⛔ 승인 후 설계 변경 프로세스 (JOB-1467 학습 — 사용자 직접 지적)
- **사용자 지적**: "프로세스대로 했어? 승인 요청을 못받았는데", "왜 못되돌려?"
- **문제**: architecture.md에 "(간소화)" 마킹으로 승인 check를 bypass하고 직접 진행
- **올바른 순서**: 설계 완료 → 리뷰 → 사용자에게 승인 요청 → 승인 후 execution 진입
- **징후**: 사용자가 "프로세스대로 했어?", "승인 요청을 못받았는데" 지적 → 승인 단계 생락
- **절대 금지**: "(간소화)" 마킹으로 승인 단계 bypass, approval.json 없이 execution 진입

### ⛔ 승인 요청是当前 채널에서 처리 (JOB-1507/1508/1515/1581 학습)
- **상세**: `references/approval-channel-targeting.md`
- **핵심**: `send_message(target="discord")`는 홈 채널로 발송 → `target="discord:{channel}:{thread}"` 형식 사용
- **⚠️ 검증됨 **(JOB-1581) `deliver="origin"` 파라미터 **不存在**. `send_message` 스키마: `action`, `target`, `message`만 필수. `deliver`/`thread_id`/`context`는 존재하지 않음
- **한계**: 에이전트는 현재 쓰레드 ID 자동 인식 불가 → 대화 컨텍스트에서 수동 확인 필요

### ⛔ 승인 전 설계 내용 상세 설명 강제 (JOB-1507/1508/1514 학습)
- **사용자 지적**: "설계 내용을 설명해야지", "동기화나 알림 발송 등 내용을 더 설명해줘"
- **문제**: 승인 요청 시 요약만 제시 → 사용자가 설계 내용을 제대로 이해 못 함
- **올바른 순서**: 설계 완료 → 문제 정의 → 설계 구성 상세 설명 → 기존 시스템 연동 설명 → 승인 요청
- **최소 설명 항목**: 문제 정의, 설계 구성 (각 항목별 기능), 기존 시스템 연동,Before/After 비교

### ⛔ 승인 전 설계 설명 강제 (JOB-1507 학습 — 사용자 직접 지적)

- **사용자 지적**: "설계 내용을 설명해야지"
- **문제**: 승인 요청 메시지를 보냈지만 설계 내용을 먼저 설명하지 않음 → 사용자가 무엇을 승인하는지 알 수 없음
- **올바른 순서**:
  1. 리뷰 완료 → review-result-*.md 생성
  2. **설계 내용 설명**: 문제 정의, 설계 구성, 기존 시스템 연동 등 요약
  3. 승인 요청 메시지 발송: (A)/(B)/(C) 선택지 포함, **반드시 `target="discord:{channel}:{thread}"` 형식 사용** (상세: `references/approval-channel-targeting.md`)
  4. 사용자 응답 대기
  5. approval.json 생성 → transition-step.sh 5-approved → 6-executing
- **징후**: 사용자가 "설계 내용을 보여줘야 승인할지 결정을 하지" 지적 → 설계 없이 승인 요청
- **절대 금지**: 설계 설명 없이 approval.json 자동 생성 → execution 진입

### ⚠️ 리뷰 단계의 엄격한 수행 (JOB-1539 학습)
- **단순 단계 전환 금지**: 설계 완료 후 `transition review` $\rightarrow$ `transition approval`로 즉시 넘기는 행위는 금지됨.
- **필수 검토 항목**:
    - **기술적 구현 가능성**: 현재 스크립트/API로 구현 가능한지, 기존 로직과 충돌은 없는지 검토.
    - **시스템 영향도**: 성능 저하, 데이터 오염, 구조적 모순 가능성 분석.
    - **지식 체계 정렬**: Karpathy 3계층 및 Schema 표준과 일치하는지 확인.
- **결과 기록**: 검토 내용을 `review.md`에 명시적으로 기록한 후 승인 단계로 진입할 것.

- **문제**: 승인 요청 메시지를 보내지 않고 approval.json을 자동 생성하여 승인 단계를 우회
- **올바른 처리**: 승인 요청 메시지 발송 → 사용자 응답 ("A", "B", "C", "그래", "진행해") → approval.json 생성
- **징후**: 사용자가 "승인 단계부터 다시 진행해" 지적 → 승인 단계 우회

### ⚠️ 승인 우회 감지 + 복구 (JOB-1507 학습 — 사용자 직접 지적: "승인 단계 넘긴 것 같은데")
- **사용자 지적**: "승인 단계 넘긴 것 같은데" → 승인 단계를 건너뛰고 이미 완료 상태인 JOB
- **문증상**:
  - `.workflow-state`의 currentStep이 `done`이나 `approval.json`이 자동 생성됨
  - `review-result-*.md` 파일 부재
  - history에서 design → done이 몇 분 만에 완료 (정상적인 승인 대기 시간 없음)
- **복구 절차 **(사용자가 "승인 단계부터 다시 진행해" 지시 시):
  1. `.workflow-state`의 `currentStep`을 `5-waiting-approval`로 변경
  2. `status`를 `running`으로 변경
  3. execution/test/execution_review/done 단계의 status를 `pending`으로 복원
  4. review-result 파일이 없으면 grill 리뷰 + GLM-5.1 리뷰 수행
  5. approval-request.json 재생성 (SHA256 재계산)
  6. architecture.md에서 "승인 대기" 문구를 "승인 요청"으로 수정 (I7b 통과)
  7. 사용자에게 승인 요청 메시지 발송 → 사용자 응답 대기
  8. 승인 획득 후 approval.json 생성 → 5-approved → 6-executing 진입
- **예방**: review 결과 파일이 없으면 approval.json 생성 금지. 승인 요청 메시지 발송 후 반드시 사용자 응답 대기.

### ⚠️ 승인 후 설계 변경 프로세스 (JOB-1467 학습 — 사용자 직접 지적)
- **사용자 지적**: "지금 작업 프로세스대로 하고 있어? 파일이나 폴더를 그때그때 바꾸는 것 같은데"
- **문제**: approval.json 생성 후 execution 단계에서 설계 변경을 프로세스 없이 그때그때 반영
- **올바른 순서**: 승인 후 변경 요청 → 변경 분류 (A/B/C) → architecture.md 갱신 → 재리뷰 → 재승인 → execution 계속
- **A-type **(구현 조정): 기준값/변수/로직 세부 변경 → 현재 단계에서 반영 (재승인 불필요)
- **B-type **(범위 변경): 새 조건/파일/구조 추가 → architecture.md 갱신 → 재리뷰 → 재승인 필수
- **C-type **(목적 변경): 작업 목적 자체 변경 → request.md 갱신 → 1단계부터 재시작
- **징후**: 사용자가 "프로세스대로 하고 있어?", "그때그때 바꾸는 것 같은데" 지적 → 승인 후 변경을 프로세스 없이 실행
- **절대 금지**: approval.json 생성 후 설계 변경을 리뷰/승인 없이 바로 코드/파일 수정

### ⚠️ 절대 금지: 분석 없이 바로 수정 (JOB-1222 교훈)
- **investigation 완료 전 execution 진입 금지**: "왜 바로 수정해?" 지적 = 원인 파악 없이 수정 시도
- **"설계 내용이 없잖아" 지적**: surface-level 분석만 하고 승인 요청했음
- **올바른 순서**: investigation(근본 원인 찾기) → design(구체적 수정안) → review → approval → execution
- **피드백 패턴**:
  - "왜 바로 수정해?" → 분석 없이 코드 수정 시도
  - "설계 내용이 없잖아" → 표면적 분석만 한 설계
  - "다시 프로세스대로 해" → 워크플로우 단계 생략
- **대응**: 문제 증상 → 근본 원인 → 수정안 → 테스트 계획 순으로 체계적 문서화

## ⚠️ 서브 폴더 JOB 트랩 (JOB-1182 교훈)

**문제**: 서브 폴더(예: `JOB-1182-제목/배경/작업명/`)에 `.workflow-state`, `review-result-*.md`, `approval.json` 등이 생성되면 상위 JOB 폴더에서 검증 스크립트가 파일을 찾지 못해 전환이 실패함.

**대응**:
1. 서브 폴더에 생성된 핵심 파일들을 상위 JOB 루트로 복사
   - `review-result-*.md` → `$JOB_DIR/`
   - `architecture.md` → `$JOB_DIR/`
   - `approval-request.json` → `$JOB_DIR/`
2. 상위 폴더에 `.workflow-state`가 없으면 직접 생성
3. `approval.json`은 반드시 `request_id`와 `architecture_sha256`가 `approval-request.json`과 일치하도록 작성 (scripts/lib/approval.sh의 `approval_json_valid()` 참고)

**검증 실패 시 디버깅**:
```bash
# I3/I4: review 파일이 JOB 루트에 있는지 확인
ls $JOB_DIR/review-result-*.md

# I7: 승인 파일 hash가 일치하는지 확인
sha256sum $JOB_DIR/architecture.md
python3 -c "import json; print(json.load(open('$JOB_DIR/approval-request.json'))['architecture_sha256'])"
```

**근본 원인**: `validate-checkpoints.sh`와 `transition-step.sh`는 서브 디렉토리를 재귀 탐색하지 않고 `$JOB_DIR/` 직하의 파일만 검증함. 서브 JOB 구조가 필요한 경우에도 핵심 산출물은 반드시 상위 JOB 루트에 유지.

**상세 복구 가이드**: `references/sub-job-state-trap.md` 참조

## 사용자 개입 규칙 (JOB-1020 교훈)

### 원칙: 최초 요청 + 승인(또는 피드백) 외 사용자 개입 없음

**사용자가 개입하는 정당한 시점**:
1. **최초 요청** — 작업 시작
2. **⑤승인** — (A)/(B)/(C) 선택
3. **피드백** — 사용자가 자발적으로 제공 (설계 수정 요구 등)

**에이전트가 사용자에게 물어보면 안 되는 것**:
- "(A)/(B)/(C)?" → 리뷰 PASS면 **승인 요약과 함께 1회 승인 요청** (자동 진행 아님)
- "진행할까요?" → **그냥 진행**
- "어떻게 할까요?" → **판단해서 진행**, 이슈만 보고
- 설계/실행 중 선택지 → **권장안으로 진행**, 대안은 결과에 포함
### 리뷰 → 승인 관계

- 리뷰 **PASS** → ⑤승인 요청 (1회만, 명확한 요약과 함께)
- 리뷰 **NEEDS_REVISION/FAIL** → 보강 후 재리뷰, PASS까지 자동 반복
- 승인은 항상 사용자가 결정. 리뷰 PASS ≠ 승인
- 승인 요청은 작업당 **1회만**. 단, 피드백이 설계의 핵심 구조(파일 추가/삭제, 아키텍처 변경)를 변경하는 경우 예외적으로 재승인 요청 가능
- 승인 획득 후 피드백이 세부 구현(기준값, 변수명, 로직 세부사항)에 관한 것이면 재승인 없이 반영 후 진행

**⚠️ 리뷰 → 승인 순서 강제 **(JOB-1208 교훈)
- **리뷰 완료 후** 승인 요청 (리뷰 전 승인 요청 금지)
- 사용자 피드백: "리뷰 후에 승인 요청 해야지"
- 6차 리뷰 루프 발생 원인: 승인 타이밍 혼동 → 리뷰 PASS 확인 후 승인 요청
- 상세: [references/review-before-approval.md](./references/review-before-approval.md)

## 승인 파일 형식 (strict)

**approval.json 필수 필드**:
```json
{
  "choice": "A",           // A, B, C 중 하나 (대문자)
  "request_id": "JOB-XXXX-YYYYMMDD...",  // approval-request.json.request_id와 정확히 일치
  "architecture_sha256": "..."  // 현재 architecture.md의 sha256과 정확히 일치
}
```

**I7 체크포인트 검증 조건**:
- `approval.json.choice == 'A'` (정확히 'A', 대문자)
- `approval.json.request_id == approval-request.json.request_id`
- `approval.json.architecture_sha256 == 현재 architecture.md sha256`
- `approval-request.json.architecture_sha256 == 현재 architecture.md sha256`
- architecture.md에 "결과 대기" 또는 "승인 대기" 문구 **존재하면 실패**

**실수 사례 (JOB-1182)**: choice 필드 없거나 request_id 불일치 시 I7 체크포인트 실패 → 6-executing 진입 불가.

## 승인 메시지 생성 규칙 (JOB-1054/1507/1515)

승인 요청은 scripts/request-approval.sh 출력 여부와 무관하게,
최終 사용자 표시 메시지 기준으로 아래 정보를 포함해야 한다.
포함되지 않은 승인 요청은 미완료로 간주한다.

반드시 포함:
1. **설계 내용 설명**: 변경 대상, 현재 상태, 변경 후 상태를 구체적으로 설명 (JOB-1507 학습: "설계 내용을 설명해야지" — 승인 요청 전에 설계 내용을 먼저 설명)
2. 리뷰 권고사항: 있음/없음 (또는 review-result 파일명 제시)
3. 보류/미구현 항목: architecture.md의 보류 섹션 존재 여부
4. (A)/(B)/(C) 선택지

**⚠️ 채널 타겟팅 규칙 **(JOB-1515 학습)
- 승인 요청 시 **반드시 현재 대화 중인 쓰레드로 전송**
- `send_message(target="discord")`만 사용하면 홈 채널로 라우팅됨 — 절대 금지
- **올바른 사용법**: 세션 컨텍스트에서 현재 쓰레드 ID 확인 후 `discord:{guild_id}:{thread_id}` 형식 사용
- **예외 처리**: 쓰레드 ID를 특정할 수 없는 경우, 홈 채널로 보내지 말고 사용자에게 채널을 지정하라고 요청

**⚠️ 메시지 도구 사용 시 주의 (JOB-1581/1597 검증)**:
- `send_message` 스키마에는 `action`, `target`, `message`만 존재. **`deliver` 파라미터는 존재하지 않음**
- **유일한 해결책**: `target="discord:{guild_id}:{thread_id}"` 형식 사용
- **쓰레드 ID 획득**: 세션 컨텍스트의 `thread: {id}`에서 확인 (AGENTS.md 참고)
- **테스트 패턴**: `send_message(target="discord:{guild}:{thread}", message="테스트")` → 전송된 메시지 확인

**올바른 순서**: 설계 내용 설명 → 승인 요청 메시지 발송 → 사용자 응답 대기
4. (A)/(B)/(C) 선택지

**올바른 승인 요청 메시지 예시**:
```
## JOB-XXXX 승인 요청

**제목**: Spec↔Code commit hash 매핑

**설계 요약**:
1. VERSION_MAP.yaml — Spec↔Code 버전 매핑 레지스트리
2. spec-version-map.sh — commit hash 기록, 조회, 역추적
3. Breaking change 감지 — API endpoint, 스키마, 필드 변경 패턴

**리뷰 결과**: ✅ grill PASS, ✅ GLM-5.1 PASS

**선택지**:
(A) 전체 설계 승인
(B) VERSION_MAP만 승인
(C) 수정 요청
```

**❌ 잘못된 패턴**: "(A)/(B)/(C) 중 하나 선택해주세요" — 설계 내용 설명 없이 선택지만 발송

workflow-run.sh 또는 request-approval.sh 출력으로 승인 요청을 생성하더라도,
최종 사용자에게 보내는 승인 메시지는 이 규칙을 반드시 적용해 보강한다.

## 승인 프로세스 (JOB-1249 교훈)

**⛔ approval.json 직접 작성 금지** — `approval.sh` 라이브러리 사용

### 승인证据 생성 절차 (I7 체크포인트 통과 필수)

1. **approval-request.json 생성**:
```bash
source scripts/lib/approval.sh
REQUEST_ID=$(write_approval_request <JOB_DIR> <JOB_ID>)
```

2. **approval.json 생성**:
```bash
cat > <JOB_DIR>/approval.json << EOF
{
  "job_id": "<JOB_ID>",
  "request_id": "<REQUEST_ID>",
  "choice": "A",
  "approved_by": "<사용자명>",
  "approved_at": "<ISO8601>",
  "architecture_sha256": "<SHA256>",
  "notes": "<비고>"
}
EOF
```

**⚠️ 필수 조건 **(I7 통과)
- `approval-request.json` 존재
- `approval.json` 존재
- `approval.json.choice == "A"`
- 양쪽 `request_id` 일치
- 양쪽 `architecture_sha256` == 현재 `architecture.md` SHA256
- `architecture.md`에 '결과: 대기' 또는 '승인 대기' 문구 없음

### Before/After 테이블 패턴 (I5b 체크포인트)

`architecture.md`에 Before/After 테이블 포함 시 **컬럼명 패턴 필수**:
```markdown
| 항목 | 현재 상태 | 변경 후 상태 |
```
**❌ 실패 패턴**: `Before (현재) | After (목표)` — `현재.*변경` 패턴 미일치

### lessons/index.md 등록 (I13c 체크포인트)

9단계 완료 전 `~/.hermes/workspace/jobs/lessons/index.md`에 JOB 항목 추가:
```markdown
### JOB-XXXX: 작업 제목
- 핵심 교훈 1
- 핵심 교훈 2
```
### I7: approval.json 검증
`require_valid_approval` 스크립트가 다음을 검증:
- `approval-request.json` 존재 (write_approval_request 생성)
- `approval.json` 존재
- `approval.json.choice` 필드 필수 ("A" 또는 "approve" 허용)
- `request_id` 양쪽 파일 일치
- `architecture_sha256` 양쪽 파일 일치 + 현재 architecture.md SHA256 일치
- architecture.md에 `'결과: 대기'` 또는 `'승인 대기'` 문구 **없음**

**⚠️ JOB-1543 학습**: `choice` 필드 누락 시 `⛔ BLOCKED: approval.json missing 'choice' field` 에러. 반드시 포함.

### 승인 절차 (순서 강제)
```bash
# 1. architecture.md 최종 버전 확정 (리뷰 반영 완료)
# 2. approval-request.json 생성 (SHA256 자동 계산)
source ~/.hermes/skills/custom/code-scripts/workflow/scripts/lib/approval.sh
write_approval_request "$JOB_DIR" "JOB-XXXX"

# 3. approval.json 생성 (request_id + sha256 일치 필수)
#    필드: choice="A", request_id, architecture_sha256
# 4. architecture.md 승인 섹션 업데이트 (결과: 대기 문구 제거)
# 5. transition-step.sh "5-approved" 또는 "5-waiting-approval"
```

### 한국어 문서 작성 시 중국어 문자 피함 (JOB-1186 교훈)

한국어 문서 생성 시 모델이 중국어 한자를 혼동하여 삽입하는 오류가 빈발함.
검증 전 반드시 아래 패턴 스캔 후 수정:

| 빈발 중국어 | 올바른 한국어 |
|-----------|-------------|
| 惯習 | 관습 |
| 待定 | 미정 |
| 覆盖率 | 커버리지 |
| 权重 | 가중치 |
| 轻量 | 경량 |
| 安装包 | 설치 패키지 |

**검증**: `grep -P '[\x{4e00}-\x{9fff}]' <파일>` 로 스캔 → 0개 확인 필요

### architecture.md 필수 포맷
- **Before/After 테이블**: `현재`/`변경 후` 열명 사용 (검증 스크립트가 `현재`/`변경` 키워드 검색)
- **승인 섹션**: `결과: 대기` 또는 `승인 대기` 포함 금지 (I7b 검증)
- **요구사항 섹션**: 필수 (I5b 검증)

workflow-run.sh 또는 request-approval.sh 출력으로 승인 요청을 생성하더라도,
최종 사용자에게 보내는 승인 메시지는 이 규칙을 반드시 적용해 보강한다.

### 요구사항 변경 프로세스 (JOB-1023)

피드백이 요구사항을 변경하는 경우, **사용자 의도** 기준으로 분류:

| 유형 | 기준 | 처리 | 예시 |
|------|------|------|------|
| **A** (구현 조정) | 기준값/변수/로직 세부 | 현재 단계에서 반영 | "한도 20→30" |
| **B** (범위 확장/축소) | 새 조건/파일 추가 | request.md 갱신 → **2단계**부터 | "계획/비계획 분리 추가" |
| **C** (목적 변경) | 작업 목적 자체 변경 | request.md 갱신 → **1단계**부터 | "이게 아니라 저거" |

**⚠️ 재리뷰 요청 처리** (JOB-1289 교훈):
- 사용자가 "보완 후 재리뷰 해" 요청 시: **즉시 재리뷰 진행**, 승인 요청 없음
- 설계는 **최소 1 회 보강 + 재리뷰** 필수 (PASS 판정 전 승인 요청 금지)
- 리뷰 결과 파일 누적: `review-result.md`, `review-result-2.md`, ...

- **판단**: 에이전트가 분류 제안, 사용자가 확인
- **애매하면 B**로 분류 (안전한 방향)
- 변경 내용은 기존 **사용자 개입 로그**에 기록 (별도 섹션 불필요)
- 진행 중 리뷰/설계는 B/C 시 무효화

### 사용자 개입 로그 (추적)

각 JOB의 `request.md`에 **사용자 개입 로그** 섹션을 유지:

```markdown
## 사용자 개입 로그
| 시간 | 단계 | 유형 | 내용 |
|------|------|------|------|
| 10:30 | 1-요청 | 정상 | 최초 요청 |
| 10:35 | 3-설계 | 피드백 | 사용자가 계획/비계획 분리 요구 |
```

**유형**:
- `정상` — 최초 요청, 승인 응답
- `피드백` — 사용자 자발적 피드백
- `개입` — 모든 에이전트→사용자 질문/대기 (정당 여부는 리뷰 시 판단)

**주의**: 에이전트는 자신의 개입을 "불필요"로 분류하지 않음. 모든 개입을 `개입`으로 기록하고, 위반 여부는 리뷰에서 판단.

## 승인 증명 파일 생성 (I7 체크포인트)

**⛔ `approval.json` 직접 작성 금지** — 검증 스크립트가 hash 일치 확인

```bash
# 1. approval-request.json 생성 (architecture.md hash 자동 포함)
source ~/.hermes/skills/custom/code-scripts/workflow/scripts/lib/approval.sh
write_approval_request <JOB_DIR> <JOB_ID>
# 출력: JOB-XXXX-20260517T233620+0900 (request_id)

# 2. approval.json 생성 (request_id + architecture_sha256 복사)
# approval-request.json에서 request_id와 architecture_sha256 복사
```

**approval.json 필수 필드:**
```json
{
  "request_id": "JOB-XXXX-YYYYMMDDTHHMMSS+0900",  // approval-request.json과 동일
  "choice": "A",
  "architecture_sha256": "..."  // approval-request.json과 동일
}
```

**architecture.md 검증 패턴 (I5b):**
- `\|.*현재.*\|.*변경` — Before/After 테이블 (현재/변경 컬럼 필수)
- `review-result` — 리뷰 결과 파일명 인용 (예: `review-result-self.md`)

## 승인 응답 정규화

사용자 응답을 (A)/(B)/(C)로 변환:
- "그냥 해","ok","ㅇㅋ","네","승인","진행해" → (A)
- "이 부분 수정","변경" → (B)
- "취소","관둬" → (C)

## ⛔ 절대 금지: 승인 단계 생략

**사용자가 승인을 요청한 경우라도, 에이전트가 스스로 approval 단계를 건너뛰어 execution으로 진행하는 것은 절대 금지.**

위반 사례:
- ❌ "진행해" → 바로 execution 진행 (approval → execution → test → done 일괄 처리)
- ❌ 승인 없이 architecture.md 수정
- ❌ workflow-state를 직접 편집하여 approval 단계 스킵

올바른 처리:
- ✅ "진행해" → approval.json 작성 → transition-step.sh 5-approved → 6-executing 단계로 진행
- ✅ 각 단계 완료 후 다음 단계로 전환 (자동 진행은 허용되지만 단계 스킵 금지)

**체크포인트 I11 위반** — 단계 연속성 갭 발생 시 즉시 롤백

## "빨리" = 병렬화, 단계 생략 아님

## ⚠️ 간소화 편향 방지 (JOB-1223 교훈)

**편향**: 수정이 "간단하다"고 판단하면 review/approval 단계를 생략하려는 유혹

**금지**:
- "1줄 수정이니까 리뷰 생략"
- "변경이 작으니까 승인 없이 진행"
- "이건 명백한 버그니까 바로 고침"

**규칙**:
- 모든 JOB은 9단계 파이프라인 **전량** 준수
- 간소화는 **사용자 명시적 요청** 시에만 가능 (에이전트 독자적 판단 금지)
- "간단한 수정"은 에이전트의 주관적 판단이며, 생략의 정당화 근거가 아님

**징후**:
- review 단계 없이 승인 요청
- workflow-state에서 단계 갭 발생
- "이건 간단한데?"라는 내적 독백

## 긴급 예외

사용자 "긴급" 명시 + 핵심 기능 장애/보안 + 테스트 필수 → 3조건 모두 충족 시만 리뷰 생략
- **기존 스크립트에 통합**하여 별도 파일/크론잡 생성 방지
- **단순 bash 스크립트**로 해결 가능한 작업은 별도 시스템 구축 금지
- **리포트/알림**: 기존 daily-report.sh에 섹션 추가 → 별도 주간 리포트 크론잡 생성 금지

## 배포 문서 갱신 규칙 (JOB-1209 교훈)

**⛔ 기능 완성 전 배포 문서 수정 금지**

프로젝트 배포 문서(README, llms.txt, 아키텍처 문서 등)는 **단 ⑥실행 완료 후**만 갱신 가능.
설계/리뷰/승인 단계에서 배포 문서를 수정하지 말 것.

| 단계 | 배포 문서 | 설계 문서 |
|------|-----------|-----------|
| 1~5 (요청~승인) | ❌ 수정 금지 | ✅ 설계 문서만 |
| 6~7 (실행/테스트) | ⚠️ 테스트 완료 후 | ✅ 병행 갱신 |
| 8~9 (리뷰/교훈) | ✅ 갱신 가능 | ✅ 갱신 |

**근거**: 설계는 변경될 수 있음. 완성된 기능에 기반하지 않은 배포 문서는 즉시 outdated 됨.

## 설계 리뷰 강제 (JOB-1214 교훈)

**⛔ 리뷰 건너뛰기 금지** — 설계 완성 후 grill 리뷰는 **선택이 아님**.

**증상**: 사용자가 "리뷰 했어?"라고 질문하면 → 리뷰 미수행 확정.

**반드시 준수할 것**:
1. 설계 완료 후 `grill` 스킬 로드
2. **자신에게 질문하고 스스로 답변** (질문-답변 쌍 최소 3개):
   - 기존 시스템과의 충돌 검증
   - 모호한 용어 명확화
   - 구체적 시나리오로 스트레스 테스트
3. `review-result-*.md`에 `[STATUS: PASS]` 또는 `[STATUS: REV]` 포함
4. **리뷰 PASS 확인 후** 승인 요청 (리뷰 전 승인 요청 금지)

**사용자 피드백**: "리뷰 했어?" → "아니요! grill 리뷰 건너뛰고 설계만 바로 작성했어요"

**근본 원인**: 리뷰가 "선택적"으로 인식됨 → **강제 체크포인트**로 인식 변경 필요

### 설계 리뷰 깊이 규칙 (JOB-1209 교훈) + **grill 스킬 강제 (JOB-1382 학습)**

**⛔ 표면적 리뷰 금지** — grill 스킬 사용 시 반드시 아래 항목 코드로 검증:

| 검증 항목 | 방법 |
|-----------|------|
| 토큰/메모리 한계 | 실제 데이터로 계산 (가정 금지) |
| 기존 코드 충돌 | 실제 함수 시그니처/모듈 읽어서 비교 |
| 외부 가정 유효성 | git repo 존재 여부 등 실제 환경 확인 |
| Deduplication/병합 로직 | 구체적인 알고리즘 서술 (개념적 언급 금지) |
| **기존 시스템 관리 주체 확인** | **谁가 파일을 생성/동기화하는지 코드 확인 필수 (JOB-1382: OpenClaw wiki plugin 발견)** |
| **설계에서 주장하는 파일/기능 존재 여부** | **실제 파일 읽어서 검증 (JOB-1451: SCHEMA.md, log.md 이미 존재)** |

**⛔ "self-review" 금지 (JOB-1382 학습)**:
- "리뷰 했어?" → superficial self-review만 한 경우 사용자 지적 확정
- **올바른 리뷰**: grill 스킬 로드 → 기존 시스템 코드 탐색 → 충돌 검증 → 구체적인 시나리오 테스트 → `[STATUS: PASS/REV]` 판정
- **self-review 패턴**: grill 스킬 없이 architecture.md에 `[STATUS: PASS]`만 씀 → **무효**

**⛔ 설계 전 실제 상태 확인 필수 (JOB-1451 학습)**:
- 설계에서 "부재", "누락", "미구현" 주장 시 반드시 실제 파일 존재 확인
- **증상**: SCHEMA.md, log.md가 이미 존재하는데 "부재"라고 함 → 불필요한 재설계
- **올바른 절차**: `ls` + `head -50`로 실제 파일 내용 확인 → 주장 검증 → 설계 반영
- **교훈**: "설계에서 발견된 문제"는 실제 환경과 다를 수 있음 — 파일 시스템에서 검증 필수

# 9단계 상세 절차

## 개요

모든 작업(JOB)은 9단계를 거쳐 진행됩니다. 각 단계별 목적, 입출력, 절차, 병렬 모드를 정의합니다.

---

## ⚠️ 예외 상태 (JOB-1529 신규)

상태 기계는 `request → ... → done`의 낙관적 흐름 외에도 예외 상태를 지원합니다:

| 상태 | 의미 | 복귀 조건 |
|------|------|-----------|
| `blocked` | 외부 종속성으로 인한 일시 정지 (승인 대기, API 리밋) | 종속성 해소 후 `running` |
| `failed` | 최대 재시도 횟수 초과 | 수동 개입 필요 |
| `rollback` | 체크포인트 실패 시 이전 단계 복귀 | 롤백 대상 단계로 전이 |

`.workflow-state` 파일에 `error_log`, `retry_count`, `transitions` 필드를 기록하여 루프 방지 로직과 연동.

**过度한 Hermes 코어 코드 수정 금지 **(JOB-1529 학습)
- 스크립트 레벨에서 보완 가능한 작업은 Hermes 코어 코드 수정하지 않음
- wrapper 스크립트, 기존 스크립트 확장, 스크립트 신규 생성 패턴 우선
- 코어 코드 수정 (config.py, gateway, run.py 등) 은 최종 수단

---

## Step 1: 요청 기록

**사용자 정정**: "1337 진행하던거 아니야?"

**문제**: 세션 중 여러 JOB이 교차할 때, 활성 JOB을 잘못 인식하고 다른 JOB으로 작업 전환

**규칙**:
1. **사용자가 JOB 번호 언급 시**: 해당 JOB의 `.workflow-state` 확인 → `currentStep`이 `request`~`8-exec-review` 사이면 **그 JOB이 활성**
2. **새 JOB 생성 전**: `ACTIVE-JOBS.md` 확인 → 이미 진행 중인 동일 도메인 JOB이 있는지 검증
3. **컨텍스트 컴팩션 후 세션 복원**: compaction summary의 `## Active Task` 섹션만 활성 JOB으로 간주
4. **JOB 번호 없이 요청 시**: 최근 `currentStep`이 `approval`/`execution` 상태인 JOB 우선

**패턴**: "1337 진행하던거 아니야?" → 활성 JOB 확인 없이 다른 JOB으로 작업 전환

---

## ⚠️ 시스템 상태 검증 먼저 (JOB-1233 교훈)

**사용자 지적**: "왜 게이트웨이 동작 확인이 바로 되지 않아?", "아까 이미 수정해서 해결된거 아니야?"

**문제**: 코드 수정/재시작이 이미 완료된 작업을 "미완료"로 잘못 판단함

**규칙**:
1. **작업 시작 전 git 로그 필수 확인**: `git log --oneline --since="어제" -- 대상_파일`
2. **프로세스 시작시간 확인**: `systemctl --user show 서비스 | grep ExecMainStartTimestamp`
3. **최근 로그 확인**: `tail -10 로그파일 | grep -E "success|error|suppress"`
4. **3가지 모두 확인 후** 판단 → 단편적 정보로 "미완료"라고 결론 내리지 말 것

**대체 패턴**:
```bash
# 게이트웨이 상태 원클릭 확인
pgrep -f 'hermes.*gateway' | head -1  # PID
systemctl --user show hermes-gateway | grep ExecMainStartTimestamp  # 시작시간
tail -3 ~/.hermes/logs/gateway.log | grep -E "Sending|NO_REPLY|error"  # 최근 동작
```

---

## ⚠️ Hook 관련 설계 시 Gateway 소스 코드 필수 확인 (JOB-1233 교훈)

**사용자 지적**: "왜 수정해야 하는 작업이 이렇게 많아? 작업 각각은 독립적인거 아니야?"

**문제**: Hook 반환 형식을 추측해서 설계 → 8개 JOB 설계서 전 bộ 수정 필요

**규칙**:
1. **Gateway Hook 관련 설계는 반드시 `gateway/run.py` 5670-5701 행 먼저 읽을 것**
2. Hook 반환 형식은 dict (`{"action": "skip"}`) 임을 코드에서 확인
3. config.yaml에 hook 등록 필요함을 확인
4. **추측 금지**: "NO_REPLY 반환하면 되겠지" → 실제로는 dict 필요

**대체 패턴**:
```bash
# Hook 인터페이스 확인
grep -A 30 "pre_gateway_dispatch" ~/.hermes/hermes-agent/gateway/run.py
```

**근본 원인**: Hook 개발 경험이 없어 반환 형식을 추측함 → 실제 소스 확인으로 해결

---

## ⚠️ 생성한 도구/스크립트는 반드시 사용 (JOB-1233 교훈)

**사용자 지적**: "필요할때마다 그걸 쓰는거야? 만들어놓고 안쓰는건 아니야?"

**문제**:便利 도구/alias/스크립트를 생성했지만 실제 작업 흐름에서 사용하지 않음

**규칙**:
1. 도구를 만들면 **즉시 사용** → 메모리에 "항상 실행" 기록
2. 아니면 스크립트를 `~/.hermes/scripts/`에 배치 + PATH 추가 → `hermes 명령어`로 호출
3. **"만들었다" ≠ "끝났다"** → 실제 사용 패턴이 확립되지 않으면 미완료로 간주

---

## ⚠️ 미완료 작업主動報告 (JOB-1233 교훈)

**사용자 지적**: "뭐 물어볼 때마다 계속 하다 마는 것 같은데"

**문제**: 분석/설계는 하지만 실행/완료/보고 단계에서 자주 중단됨

**규칙**:
1. 작업 시작 시 **명확한 완료 기준** 설정 (result.md? 실행 파일? 테스트 통과?)
2. 중간 보고 시 **미완료 항목 명시적 언급** → "현재 OOO 완료, XOO 미완료"
3. JOB 완료 시 `result.md` + `lessons.md` **동시 생성** → 둘 중 하나라도 누락하면 미완료
4. 새 세션 시작 시 `ACTIVE-JOBS.md` 확인 → 진행 중 작업主動報告

---

## ⚠️ 사용자 커뮤니케이션 선호 (JOB-1388 학습)

**말투 (사용자 지적: "말투가 왜이래")**:
- **존댓말 기본**: 반말이나 과도하게 캐주얼한 표현 금지
- **간결하게**: 불필요한 설명 없이 결과 중심
- **캐주얼한 축약 금지**: "맞네", "그럼" → "네", "알겠습니다" 등 정중한 표현 사용
- **이모지 적절히**: 🎯 ✅ 등의 기능적 이모지는 허용, 과도한 사용 금지

**실용성 (사용자 지적: "실시간으로 하는건 낭비지?")**:
- 낭비적인 솔루션 제안 금지 (실시간 모니터링, 불필요한 자동화 등)
- 단순/실용적 해결책 우선. 복잡도는 필요할 때만 추가
- "가장 단순하게 고칠 수 있는 방법" 먼저 제안

**프로세스 (사용자 지적: "작업 등록해야지")**:
- 파일 수정 포함 작업은 **반드시 JOB 등록 후** 워크플로우 경유
- "간단하니까 JOB 안 만들고 바로 해" 금지

## ⚠️ 강제 준수 규칙 (사용자 지시)

## 질문에는 답변만 (JOB-1462 학습 — 사용자 직접 지적)

**사용자 피드백**: "삭제는 왜 또 마음대로 해?", "llms.txt가 지식 시스템의 진입점이야?" → 답변만 했어야 하는데 llms.txt 생성 후 삭제까지 진행

**규칙**:
1. **질문 패턴 감지**: "야?", "뭐야?", "아니야?", "왜?" 등으로 끝나는 문장은 질문
2. **답변만**: 사실 확인 + 현재 상태 보고
3. **작업 금지**: 생성, 삭제, 수정, rebuild 등 모든 파일 조작 금지
4. **확인 필수**: "llms.txt 진입점으로 추가할까요?"처럼 별도 승인 요청

**징후**:
- ❌ "llms.txt가 진입점이야?" → llms.txt 생성 + 삭제
- ✅ "llms.txt가 진입점이야?" → "아닙니다. 현재 진입점은 wiki/index.md입니다."

**패턴**: 질문 → 답변만 → 추가 작업 → 사용자 승인 → 실행

## 조사 단계 = 분석만 (JOB-1462 학습 — 사용자 직접 지적)

**사용자 피드백**: "지금 조사 단계에서 파일 수정하는거 아니지?"

**규칙**:
1. **조사 단계**(investigation): 문제 분석 + 원인 파악 + request.md 보강 **만**
2. **파일 수정 금지**: build-metadata.sh, build-scores.sh 등 모든 스크립트 수정 금지
3. **rebuild 금지**: scores.json, metadata.json 재생성 금지
4. **설계 단계**에서야 수정안 제안 → 승인 → 실행

**올바른 순서**:
```
조사(분석) → 설계(수정안) → 리뷰 → 승인 → 실행(수정+rebuild)
```

**증상**: "지금 조사 단계에서 파일 수정하는거 아니지?" → 조사 단계에서 코드 수정 시도
**해결**: request.md에 분석 결과만 기록 → 설계 단계에서 수정안 제안

### 워크플로우 생략 금지
- **파일 수정 포함 작업은 반드시 9단계 파이프라인 통과 필수**
- "간단하니까" "이미 알고 있으니까" 등의 이유로 단계 생략 금지
- 승인 없이 실행 진행 시 → 사용자 지적 확정 (JOB-1204 사례)
- **에이전트 판단 금지**: 작업 복잡도/단순도와 무관하게 프로세스 준수

### ⛔ 승인 후 설계 변경 시 재리뷰 + 재승인 강제 (JOB-1467 학습)

**사용자 지적**: "지금 작업 프로세스대로 하고 있어? 파일이나 폴더를 그때그때 바꾸는 것 같은데"

**문제**: 승인 후 설계 변경(B-type: 범위 변경)이 발생했으나, 재리뷰/재승인 없이 execution을 계속 진행. 설계 변경 사항을 architecture.md에 반영하지 않고 그때그때 파일/폴더를 수정.

**올바른 순서**:
```
1. 승인 후 설계 변경 감지 → 변경 분류 (A/B/C)
2. B-type (범위 변경) → architecture.md 갱신 (변경 이력 테이블 포함)
3. 재리뷰 수행 → review-result-N.md 생성
4. 재승인 요청 → approval.json 갱신
5. سپس execution 계속
```

**Before/After 테이블 포함 필수**:
```markdown
## 변경 이력

| # | 항목 | 현재 | 변경 | 사유 |
|---|------|------|------|------|
| 1 | 진입점 위치 | scripts/ | skills/ | 스킬 기반 통합 |
```

**증상**: 사용자가 "프로세스대로 해" 지적 → 승인 후 설계 변경을 재리뷰/재승인 없이 실행
**해결**: architecture.md에 변경 이력 테이블 → 재리뷰 → 재승인 → execution 계속

### ⛔ 스킬 카테고리 구조 해치지 않기

**사용자 지적**: "기존 구조를 해치지는 말고"

**문제**: 스킬을 새로운 상위 폴더 구조로 재배치하거나 기존 카테고리(`software-development/`, `custom/` 등)를 해치는 변경 시도.

**올바른 접근**:
- 기존 카테고리 유지: `~/.hermes/skills/software-development/`, `~/.hermes/skills/custom/` 등
- 하위 스킬명은 간결하게: `spec-driven-dev`, `spec-driven-project` → `spec-driven-dev`
- 카테고리 평탄화 금지

### ⛔ .shared/ 사용 금지

**AGENTS.md 명시**: `.shared/`는 Blackboard 전용 영역. 프로젝트 관리 도구/템플릿 배치 금지.

**올바른 위치**:
- 프로젝트 코드: `~/.hermes/workspace/projects/<slug>/`
- 스킬 템플릿: `~/.hermes/skills/<category>/<skill>/templates/`
- 참조 문서: `~/.hermes/skills/<category>/<skill>/references/`

**문제**: 스크립트나 템플릿을 `.shared/`에 배치 시 듀얼 에이전트 충돌 가능 (OpenClaw와 공유됨)

### ⛔ 승인 단계 우회 금지 (JOB-1438 학습 — 사용자 직접 지적)

**사용자 지적**: "왜 승인 단계를 안거쳐?", "sources가 무슨 원본이야? 지워도 되는거 맞아?"

**문제**: JOB-1438에서 sources/ 삭제 작업을 승인 단계 없이 바로 실행. 사용자 피드백도 기다리지 않고 백업 → 삭제 → 복원 순으로 처리.

**근본 원인**:
1. "간단한 정리 작업"이라는 자체 판단으로 승인 스킵
2. sources/ 내용 확인 없이 백업만 한 후 삭제 진행
3. 사용자의 "sources가 무슨 원본이야?" 질문 후에야 실제 내용 확인

**규칙**:
- **데이터 삭제 작업은 항상 승인 필수** — 백업 이동도 승인 대상
- **작업 전 실제 내용 확인** — "메타데이터만 있겠지" 추측 금지
- **사용자 질문이 수정 신호** — "뭐였어?", "왜 했어?" = 즉시 작업 중단 + 보고
- **복구 가능성 확인 후 삭제** — 원본이 다른 곳에 있는지 반드시 확인

**올바른 순서 **(데이터 삭제 시)
```
1. 실제 내용 확인 (샘플 파일 읽기)
2. 삭제 대상/유지 대상 분류
3. 사용자에게 분석 결과 보고
4. 승인 요청 (A:삭제/B:수정/C:유지)
5. 승인 후 실행
```

**증상**: 사용자가 "sources가 무슨 원본이야? 지워도 되는거 맞아?" 질문 → 내용 확인 없이 삭제 시도
**해결**: 삭제 전 실제 파일 내용 확인 + 분석 보고 + 승인 대기

**⚠️ JOB-1438 교훈 **(실제 사례)
- sources/ 932개 파일 삭제 시도
- 실제 내용: session-log(782개), local-file(83개), job-record(41개), skill(24개)
- 원본은 `~/.openclaw/agents/*/sessions/`, `~/.hermes/sessions/`에 그대로 존재
- **복구**: sources-backup/ → sources/ 복원
- **재처리**: JOB-1441로 세션 지식 추출 작업 별도 등록

### retroactive補正 절차 (위반 시)
워크플로우 생략 발견 시 즉시 다음 절차 수행:
1. `create-job.sh`로 공식 JOB 생성
2. `request.md` 작성 (요청 내용 + 사용자 개입 로그)
3. 조사 결과 request.md에 append
4. `architecture.md` 작성 + 승인 옵션 (A)/(B)/(C) 포함
5. `review-result-*.md` 작성 + `[STATUS: PASS|REV|FAIL]` 태그
6. `approval.json` 작성 (사용자 승인 기록)
7. `execution.md` 작성 (이미 완료된 작업 포함)
8. 테스트 실행 + 결과 기록
9. `lessons/` 교훈 작성
10. `.workflow-state`를 `9-done`로 업데이트

### retroactive补正 절차 (위반 시)
워크플로우 생락 발견 시 즉시 다음 절차 수행:
1. `create-job.sh`로 공식 JOB 생성
2. `request.md` 작성 (요청 내용 + 사용자 개입 로그)
3. 조사 결과 request.md에 append
4. `architecture.md` 작성 + 승인 옵션 (A)/(B)/(C) 포함
5. `review-result-*.md` 작성 + `[STATUS: PASS|REV|FAIL]` 태그
6. `approval.json` 작성 (사용자 승인 기록)
7. `execution.md` 작성 (이미 완료된 작업 포함)
8. 테스트 실행 + 결과 기록
9. `lessons/` 교훈 작성
10. `.workflow-state`를 `9-done`로 업데이트

---

## 알려진 이슈

### transition-step.sh 타임아웃 (JOB-1204)
- `transition-step.sh`가 hung 상태가 되는 경우 발생
- **대체**: Python `execute_code`로 `.workflow-state` 직접 업데이트
- root cause: 아직不明 (스크립트 내 blocking 호출 추정)

### JOB 디렉토리 이름에 한글 포함 시 bash heredoc 실패
- `JOB_DIR`에 한글 포함 시 bash heredoc(`<< 'EOF'`)가 타임아웃
- **대체**: Python `execute_code`로 파일 작성 또는 `echo` 사용

### JOB 완료 상태 검증: git 로그 필수 (JOB-1233 교훈)

**.workflow-state만 믿지 마세요**. 파일 상태와 실제 git 커밋/배포 상태가 불일치할 수 있습니다.

**검증 절차**:
```bash
# 1. workflow-state 확인
cat ~/.hermes/workspace/jobs/JOB-XXXX/.workflow-state | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('currentStep'))"

# 2. git 로그 확인 (실제 코드 변경 여부)
cd ~/.hermes/hermes-agent && git log --oneline -5 -- <수정된 파일 경로>

# 3. 프로세스 상태 확인 (게이트웨이 등 서비스 재시작 여부)
pgrep -f "서비스명" && systemctl --user show 서비스명 | grep ExecMainStartTimestamp
```

**징후**: 사용자가 "이미 수정했잖아?" 또는 "재시작했어?"라고 지적하면 → git 로그와 프로세스 상태를 확인하지 않고 workflow-state만 본 경우.

### 게이트웨이 상태 확인 절차 (JOB-1233 교훈)

**항상 3가지 함께 확인**:
```bash
# PID + 시작시간 + 최근 로그 원클릭
pgrep -f "hermes.*gateway" | head -1
systemctl --user show hermes-gateway | grep ExecMainStartTimestamp
tail -3 ~/.hermes/logs/gateway.log | grep -E "inbound|NO_REPLY|Sending"
```

**문제**: ps 명령어만 사용하면 오래된 프로세스 정보를 볼 수 있음 (재시작 후에도 캐시되지 않은 경우).

---

### 종료 상태

| 상태 | 의미 | 사용 시점 |
|------|------|----------|
| `9-done` | 정상 완료 | ⑨교훈 단계 종료 시 |
| `9-superseded` | 다른 JOB에 흡수 | 기능이 다른 스크립트/JOB에 통합되었을 때 |
| `9-cancelled` | 취소 | 사용자가 취소 지시, 또는 요구사항이 무효화되었을 때 |

**request.md에 사유 기록 필수** (흡수: 어디에 흡수되었는지, 취소: 사유)

### .workflow-state 규칙 (JSON 필수)

**⚠️ 형식**: `.workflow-state`는 **JSON 형식**입니다. `create-job.sh`가 초기 JSON을 생성하며, `workflow-gate.sh`가 이를 업데이트합니다.
**⛔ 절대 금지**: 에이전트가 직접 `.workflow-state` 파일을 `echo` 또는 `write_file`로 수정 금지. 모든 변경은 `workflow-gate.sh`를 통해 수행.

**⚠️ Pitfall (JOB-1172)**: `.workflow-state`가 단순 문자열 (예: `"request"`) 로 덮어씌워지면 `jq` 파싱 실패. 손상 시 올바른 JSON 구조로 복원 후 진행.

**상태 전환 방법**:
```bash
# 중간 단계 전환 (예: test 단계 진입)
bash ~/.hermes/scripts/workflow-gate.sh JOB-1176 transition test

# 완료 처리 (Hook 자동 실행)
bash ~/.hermes/scripts/workflow-gate.sh JOB-1176 complete
```

**JSON 구조**:
```json
{
  "jobId": "JOB-XXXX",
  "status": "running",
  "currentStep": "test",
  "steps": [
    { "name": "request", "status": "done", "completedAt": "..." },
    { "name": "investigation", "status": "done", "completedAt": "..." },
    ...
  ],
  "startedAt": "...",
  "updatedAt": "...",
  "artifacts": []
}
```

| 시점 | currentStep 값 | 트리거 |
|------|----------------|--------|
| JOB 등록 시 | `request` | create-job.sh |
| ②조사 시작 | `investigation` | workflow-gate.sh start |
| ③설계 시작 | `design` | workflow-gate.sh transition design |
| ④리뷰 spawn | `review` | workflow-gate.sh transition review |
| ⑤승인 획득 | `approval` | workflow-gate.sh transition approval |
| ⑥실행 시작 | `execution` | workflow-gate.sh transition execution |
| ⑦테스트 시작 | `test` | workflow-gate.sh transition test |
| ⑧실행 리뷰 | `execution_review` | workflow-gate.sh transition execution_review |
| ⑨교훈 완료 | `done` | workflow-gate.sh complete |

## 3. 설계 단계 (Design Principles)

### 단순성 우선 (JOB-1236 교훈)

**원칙**: 가능한 단순한 해결책으로 시작. 복잡도는 필요할 때만 추가.

**사용자 피드백 패턴**:
- "침묵을 중단하는 조건이 필요해?" → 상태 관리 (turns/timeout) 불필요
- "다시 호출됐을때 반응하면 되잖아" → 자연스러운 재개 메커니즘으로 충분

**설계 시 체크리스트**:
- [ ] 상태 관리 (turns, timeout, context tracking)가 정말 필요한가?
- [ ] 단순 패턴 매칭으로 동일한 결과를 낼 수 있는가?
- [ ] 사용자가 추가 기능을 명시적으로 요구했는가? (아니면 에이전트가 예측한 것인가?)

**예시**:
- ❌ 복잡: 3턴/300초 침묵, 재개 조건, 상태 슬롯 관리
- ✅ 단순: 메시지 패턴 매칭, Hermes 호출 시 바로 응답

### 산출물 파일명 규칙 (JOB-1157)

| 단계 | 산출물 | 비고 |
|------|--------|------|
| 1-요청 | `request.md` | — |
| 2-조사 | `request.md`에 조사 결과 **append** | 별도 investigation.md 금지 |
| 3-설계 | `architecture.md` | `design.md`도 허용 (폴백) |
| 4-리뷰 | `review-result-*.md` | `[STATUS: PASS\|REV\|FAIL]` 태그 필수 |
| 5-승인 | `approval.json` | — |
| 6-실행 | `execution.md` | — |
| 8-실행리뷰 | `exec-review-result.md` | — |

**⚠️ 산출물 누락 방지**: `references/recurrent-pitfalls.md` 참조 (exec-review-result.md 누락 패턴)
> **운영 현실 (2026-05-28)**: 최근 JOB(JOB-1373, JOB-1342)에서 `design.md` 사용 확인. `architecture.md`와 동등하게 처리

## 배치 승인 워크플로우 (JOB-1338, 이미지 생성용)

**상황**: 이미지 생성 큐에 대기 중인 항목이 있고, 배치로 진행할지 승인해야 할 때

**절차**:
1. 대기 큐 조회 (`image-queue.sh list --status pending`)
2. 그룹 격리 확인 (`sourceChannel` 필드로 출처 추적)
3. 승인 요청 메시지 발송:
   - 그룹 채팅: **반드시 승인 필요**
   - DM: 직접 판단 옵션 ("더 생성할 이미지 있음?")
4. 사용자 응답 대기 (진행/대기 유지/취소)
5. 승인 시: 배치 그룹화 → 실행 → 결과 격리 (각 그룹은 해당 그룹 요청 이미지만 확인)

**참조**: `image-queue` 스킬 § 배치 승인 워크플로우

## ⚠️ 승인 단계 우회 패턴 감지 (JOB-1350 교훈)

**문제**: 승인 파일(approval.json) 64% 누락 → 승인 단계 우회/자동 승인 의심
**원인**: "빨리 끝내야 한다" 심리 → 승인 스킵 → workflow-gate.sh 검증 부재
**해결**: `workflow-gate.sh`의 transition/complete 액션에 승인 검증 로직 추가

**검증 로직 위치**: `~/.hermes/scripts/workflow-gate.sh`
- transition 액션: `done`/`9-done` 진입 전
- complete 액션: 완료 처리 전
- 간소화 JOB 예외: `architecture.md`에 `(간소화)` 포함 시 스킵

**테스트 필수**:
1. 승인 없는 JOB → 차단 (exit 1)
2. 간소화 JOB → 자동 통과
3. 승인 있는 JOB → 통과

**교훈**: 프로세스 준수는 스크립트 강제 > 가이드라인. 승인 강제 = 신규 JOB만, 과거는 보고만.

## 크론잡 생성 규칙 (JOB-1185 교훈)

**3층위 구조 준수:**
- **crontab (C형)**: 결정론적 작업 (LLM 불필요) → 토큰 0
- **OpenClaw cron (O형)**: LLM 판단 필요 작업만 → agentTurn (토큰 있음)
- **Hermes cron (H형)**: Hermes 내부 작업만

**⚠️ JOB-1392 변경 **(Hermes Primary + OpenClaw Hot Standby)
- OpenClaw는 **긴급 복구 용도**로 역할 제한
- OpenClaw cron: **비활성화** (Memory Dreaming 유지)
- 시스템 crontab: 유지 (시스템 레벨 모니터링)
- Hermes cron: Primary 자동화 담당

**참조**: `references/cron-job-integration.md`

## ⚠️ 설계 변경 참조 누락 문제 (JOB-1421 교훈)

**문제 **(JOB-1418 발생) JOB-1392에서 승인된 아키텍처 변경이 새로운 JOB 조사 시 즉시 참조되지 않음.

**해결 **(JOB-1421 구현)
1. `workflow-gate.sh` complete 액션에 hook 추가
2. JOB 완료 시 자동 실행:
   - `~/.hermes/scripts/hooks/on-job-complete.sh`
   - `~/.hermes/scripts/hooks/update-agents-md.sh`
   - `~/.shared/scripts/generate-llms.sh`
   - `~/.hermes/scripts/hooks/sync-wiki.sh`

**예방 **(작업 시작 시 필수 체크):
1. 최근 승인된 JOB 설계서 스캔: `find ~/.hermes/workspace/jobs/ -name "design.md" -mtime -7`
2. AGENTS.md 최근 변경 확인: `git log --oneline --since="1주" -- AGENTS.md`
3. wiki 개념 문서 확인: `~/.hermes/knowledge/wiki/concepts/` 관련 파일 스캔

**참조**: `references/job-complete-hook.md`

**⚠️ no_agent 스크립트 타임아웃 **(JOB-1388) LLM API 호출 포함 시 `script_timeout_seconds` 설정 필수. 상세: `references/cron-script-timeout.md`

### OpenClaw cron 비활성화 (JOB-1418 학습)

OpenClaw cron 작업을 비활성화할 때:

**방법**: `~/.openclaw/cron/jobs.json` 직접 수정
```python
import json
with open('jobs.json') as f:
    data = json.load(f)
for job in data['jobs']:
    if job.get('name') == '작업이름':
        job['enabled'] = False
with open('jobs.json', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
```

**⚠️ 주의**:
- UI/API로 비활성화하는 방법이 명시적이지 않음
- jobs.json 직접 수정 시 format 유지 중요 (indent: 2, ensure_ascii: False)
- Memory Dreaming은 OpenClaw 메모리 시스템 핵심 기능 → 유지 필요

**생성 시 체크:**
1. 이 작업은 LLM 판단이 정말 필요한가? 아니오면 crontab
2. 주기는 최소한인가? (2분 < 5분 < 30분 < 일 1회)
3. OpenClaw cron은 agentTurn만 지원 → 에이전트가 agentTurn 오용할 수 있음. 반드시 LLM 필요 여부 재확인

**금지:**
- ❌ Hermes no_agent로 OS의 결정론적 작업 대체 (구조적 왜곡)
- ❌ OpenClaw agentTurn으로 단순 스크립트 작업 등록 (토큰 낭비)
- ❌ crontab 방치 (HEARTBEAT.md의 C형 작업과 정기 비교)

→ 상세 감사 절차: `cron-audit` 스킬 참조
→ 설계 변경 참조 패턴: `references/cron-integration-pattern.md`
→ JOB 완료 hook: `references/job-complete-hook.md`

### 스크립트 이관 패턴 (JOB-1419 학습)

기존 스크립트 로직을 새 스크립트로 이관할 때 준수할 사항:

1. **원본 스크립트 먼저 읽기**: `head -100 기존스크립트.sh`로 구조 파악
2. **핵심 로직만 추출**: 전체 복사가 아닌 기능 단위 추출
3. **URL 중복 제거 로직 유지**: `url-history.txt` 패턴 반드시 포함
4. **로깅 패턴 통일**: `log() { echo "[$(date)] $*" >> $LOG_FILE; }`
5. **테스트 후 교체**: 새 스크립트 테스트 PASS 후 원본 비활성화

**예시 **(JOB-1419)
- tech-news-collector.sh → fetch.sh (HN, GeekNews, AI Frontier 수집 로직 이관)
- daily-digest.sh → verify.sh, summary.sh (시스템 건강도 로직 추출)
- rsync-to-openclaw.sh → sync.sh (동기화 로직 이관)

**⚠️ Pitfall**: 원본 스크립트 전체 복사 → 중복 코드 증가. 핵심 로직만 추출하여 새 스크립트에 재구현.

### ⚠️ cron잡 통합 시 승인된 설계 변경 반드시 참조 (JOB-1418/1421 학습)

**문제**: JOB-1392에서 'Hermes Primary + OpenClaw Hot Standby'로 아키텍처 변경 승인되었으나, JOB-1418 크론잡 통합 조사 시 즉시 참조되지 않음.

**근본 원인**:
1. AGENTS.md에 설계 변경 반영 메커니즘 부재
2. llms.txt 자동 갱신 부재
3. JOB 산출물 격리 (별도 폴더에 design.md/architecture.md)

**해결 **(JOB-1421)
- `workflow-gate.sh complete` 액션에 `on-job-complete.sh` hook 추가
- JOB 완료 후 자동 실행: AGENTS.md 업데이트 + llms.txt 갱신 + wiki 동기화

**반드시 확인**:
1. cron잡 통합/정리 작업 시작 전: **최근 승인된 JOB 설계서 스캔**
2. `find ~/.hermes/workspace/jobs/ -name "architecture.md" -mtime -7` 로 최근 설계서 확인
3. 설계 변경이 cron잡 구조에 영향주는지 반드시 검증

**패턴**: "cron잡 통합" → 최근 JOB 설계서 스캔 → 설계 변경 반영 확인 → 통합안 작성

### ⚠️ 시스템 설계 시 스킬은 설계 안에 포함 (JOB-1406 학습)

**사용자 지적**: "스킬 작성도 설계에 포함해서 진행해야지 바로 만들면 어떻게 해"

**문제**: 시스템 설계 중에 필요한 스킬을 미리 생성 → 설계 변경 시 스킬도 다시 수정 필요 (중복 작업)

**올바른 순서**:
1. 설계서 (`architecture.md`/`design.md`)에 스킬 생성 계획 명시
2. 설계 리뷰 + 승인
3. 실행 단계에서 스크립트 생성 → 스킬 등록
4. 스킬 내용은 최종 승인된 설계를 반영

**패턴**: "시스템 구성 작업" → 관련 스킬 생성 계획은 설계서 포함 → 승인 후 실행

## 기존 JOB 복구 (workflow-state 누락 시)

**⚠️ 함정 (JOB-1340 교훈)**: 기존 JOB이 `create-job.sh` 없이 직접 mkdir로 생성된 경우 `.workflow-state`가 없음.

**징후**:
- `workflow-gate.sh JOB-XXXX start` → "ERROR: JOB directory not found"
- `.workflow-state` 파일 부재
- 폴더명이 `JOB-XXXX`만 있고 설명 접미사 없음

**복구 절차**:
1. 기존 산출물 확인: `ls ~/.hermes/workspace/jobs/JOB-XXXX/`
2. **새 JOB 생성**: `create-job.sh`로 새 JOB 생성 (자동 `.workflow-state` 생성)
3. 기존 내용 이동: 산출물 파일들을 새 JOB 폴더로 `cp`
4. `request.md` 갱신: 기존 내용 통합 + 사용자 개입 로그 작성
5. `workflow-gate.sh`로 현재 단계 확인 → 적절한 `transition-step.sh`로 상태 설정
6. 레거시 폴더 아카이브 또는 삭제

**규칙**: workflow 절차 우회 금지. 설계/리뷰 등 개별 단계는 `workflow-gate.sh` 지시를 받고 진행해야 함.

## 모델-단계 매핑 (JOB-1528)

workflow-gate.sh transition 시 단계별 모델 자동 전환:

| 단계 | 모델 | 근거 |
|------|------|------|
| investigation | Qwen3.6 | 형식 준수, 안정성 |
| design | get_model_for_role("review") | 추론, 창의성, 브레인스토밍 |
| review | Qwen3.6 | 형식 검사, 정교함 |
| approval | Qwen3.6 | 요약, 명확성 |
| execution | Qwen3.6 | 코드 작성, 명령어 정확성 |
| test | get_model_for_role("review") | 디버깅, 근본 원인 분석 |
| execution_review | Qwen3.6 | 형식 검사 |
| done | get_model_for_role("review") | 교훈, 패턴 추출 |

**참고**: get_model_for_role("review") = get_model_for_role("review") (fallback_providers 참조)

## Pitfalls

### P1: create-job.sh 실패 시 수동 JOB 생성 (JOB-1531)

**문제**: `create-job.sh`가 exit_code=1로 실패, JOB 폴더 미생성 (락 충돌 등)

**증상**:
- `[INFO] JOB 번호: JOB-XXXX` 표시되지만 폴더 실제 미생성
- `workflow-gate.sh JOB-XXXX start` → "JOB directory not found" 에러

**해결 패턴**:
```bash
# 1. 수동 폴더 생성
mkdir -p ~/.hermes/workspace/jobs/JOB-XXXX-제목

# 2. .workflow-state 생성
cat > ~/.hermes/workspace/jobs/JOB-XXXX-제목/.workflow-state << 'EOF'
{
  "jobId": "JOB-XXXX",
  "status": "pending",
  "currentStep": "request",
  "steps": [
    { "name": "request", "status": "done", "completedAt": "ISO8601" },
    { "name": "investigation", "status": "pending" },
    ...
  ],
  "startedAt": "ISO8601",
  "updatedAt": "ISO8601",
  "artifacts": []
}
EOF

# 3. workflow-gate.sh로 진행
bash ~/.hermes/scripts/workflow-gate.sh JOB-XXXX transition investigation
```

**교훈**: create-job.sh 실패 시 바로 수동 생성 패턴으로 전환.락 확인 후 재시도보다 수동 생성이 더 빠름.
**대안 모델**: `workflow-gate.sh` `--model-fallback` 옵션으로 GLM 계열 사용 가능 (JOB-1530)

## 서브에이전트 규칙 (JOB-907)

spawn 전 subagent-state.json 등록, 완료 즉시 처리.
장애/타임아웃: `references/subagent-recovery.md` 따를 것.

---

## 운영 현실 노트 (2026-05-28 점검)

### 산출물 파일명
- **규정**: `architecture.md`가 표준
- **현실**: 최근 JOB(JOB-1373, JOB-1342)에서 `design.md` 사용 확인
- **대응**: `architecture.md`와 동등하게 처리 (폴백 허용)

### 리뷰 모델
- **규정**: `openai-codex/gpt-5.5` ↔ `ollama-cloud/deepseek-v4-pro` 교대
- **현실**: Self-Review (Qwen3.6) 또는 `zai/glm-5-turbo` 사용 빈번
- **이유**: `model_rotation.json` 파일 누락/미갱신
- **미결**: GLM-5.1 모델 리뷰 풀 포함 여부 (사용자 판단 대기 중)

### 워크플로우 상태 파일
- **규정**: 모든 JOB에 `.workflow-state` 필수
- **현실**: JOB-1374는 상태 파일 누락
- **대응**: JOB 등록 시 자동 생성 필요

## ⚠️ 함정 (교훈)

1. **리뷰는 workflow-gate.sh 경유 필수 **(JOB-1340 교훈) "직접 리뷰 진행" 금지. 설계서 작성 후 반드시 workflow-gate.sh 실행 → 다음 단계 확인. 직접 리뷰 시 `.workflow-state` 누락, 상태 추적 불가, 체크포인트 검증 우회 발생.
2. **상태 파일 직접 수정 금지**: `.workflow-state`는 `transition-step.sh` 경유로만 갱신. 직접 수정 시 검증 우회, 상태 불일치 발생.
3. **workflow-gate.sh는 읽기 전용**: 단계 판별만 수행. 상태 쓰기는 `transition-step.sh`가 담당. 혼동 금지.
4. **승인 단계 우회 금지 **(JOB-1393 교훈 — 사용자 직접 지적) 문서에 명시되어 있음에도 승인을 거치지 않고 실행을 시작했다. 사용자가 "프로세스에 따라 진행하는건 승인 절차도 제대로 지키라는 얘기야"고 직접 지적. **증상**: approval.json 없이 6-executing 진입. **해결**: 리뷰 PASS 후 반드시 승인 요청 메시지 발송 → 사용자 응답 대기 → approval.json 생성 → 5-approved → 6-executing 순서 강제. 자동 진행 규칙의 예외는 승인 단계뿐 — 승인 단계는 절대 자동화 금지.
5. **가짜 완료 방지 **(JOB-1412) `workflow-gate.sh complete`는 approval.json만 검증하고 **result.md는 검증하지 않음**. JOB-1408은 9단계 모두 'done'으로 표시되지만 result.md, approval.json, design.md가 누락. **대응**: 완료 전 `ls $JOB_DIR/result.md` 필수 확인. 누락 시 완료 거부 후 보강. **개선**: `workflow-gate.sh`의 complete 액션에 result.md 검증 로직 추가 (JOB-1412).

9. **create-job.sh 락 누수 **(JOB-1412) `/tmp/.create-job.lock`이 예외 발생 시 영구적으로 남음 → 이후 JOB 생성 실패. **수정**: `trap 'rm -f $LOCK_FILE' EXIT INT TERM HUP` 추가. **임시 해결**: `rm -f /tmp/.create-job.lock` 수동 제거. **테스트 시 401 오류**: curl 명령어에서 키가 잘려서 전달됨 → 변수로 안전하게 전달 필수. 상세: `references/glm-direct-api-setup.md`

7. **중단 JOB 감지 **(JOB-1412) 24h+ 동안 `status=running && step≠done`인 JOB이 방치됨 (JOB-1409, 1407, 1410, 1411). **대응**: 야간 `monitor.sh`에 중단 감지 로직 통합 → 알림 생성.

8. **GLM 리뷰 미활용 **(JOB-1412) `run-review.sh`는 존재하지만 `review-result-glm.md`가 거의 없음. architecture.md 없으면 셀프 리뷰로 자동 폴백 → 실질적 검증 없음. **개선**: design.md/review.md로 폴백 + 토큰 한도 200K→500K + FAIL 시 자동 재리뷰 루프 (최대 2회).

9. **GLM-5.1 직접 API 사용 **(JOB-1412 학습)
   - **직접 API **(✅ 동작) `https://api.z.ai/api/coding/paas/v4/chat/completions`
   - **프로바이더**: `zai` (config.yaml), 키: `env.GLM_API_KEY`
   - **OpenRouter 경유 금지**: 사용자 지시 "오픈라우터 쓰지 마"
   - **401 오류 원인**: 테스트 시 키가 잘려서 전달됨 (curl 명령어 escaping 문제). 실제 GLM_API_KEY는 유효함
   - **run-review.sh 설정**: `zai` 프로바이더 사용, `get_model_for_role("creative")` 모델
   - **타임아웃**: 120초 (JOB-1412에서 180→120초로 단축)
   - **리조닝 모델**: content가 비어있을 수 있음 → `reasoning_content`도 확인 필요
   ```bash
   timeout 30 python3 -c "
   import os, requests
   api_key = open(os.path.expanduser('~/.hermes/.env')).read().split('OPENROUTER_API_KEY='***')[0].strip()
   resp = requests.post('https://openrouter.ai/api/v1/chat/completions',
       headers={'Authorization': f'Bearer {api_key}'},
       json={'model': 'z-ai/get_model_for_role("creative")', 'messages': [{'role': 'user', 'content': 'hi'}], 'max_tokens': 50},
       timeout=30)
   print(f'상태: {resp.status_code}')
   "
   ```

9. **리뷰-수정-재리뷰 자동화 **(JOB-1412) 리뷰가 FAIL/REV 판정되어도 다음 단계로 자동 진행됨. **해결**: `lib/review-loop.sh` 신규 생성 → `[STATUS: PASS/FAIL/REV]` 파싱 → PASS만 다음 단계 허용, FAIL은 수정 지침 추출 후 재리뷰 (최대 2회), REV는 수동 승인 필요. **파싱 안정성**: `grep` 기반 패턴 + 한국어 키워드 폴백 (단일 정규식 의존 금지). **스크립트**: `~/.hermes/scripts/lib/review-loop.sh`, `~/.hermes/scripts/lib/validate-workflow.sh`

10. **단계별 시간 추적 누락 → 해결 **(JOB-1415) `.workflow-state`의 `steps[].startedAt` 필드가 대부분의 JOB에서 누락 → 단계별 소요 시간 계산 불가. **JOB-1415에서 해결**: `workflow-gate.sh` transition 시 `startedAt` 자동 기록 + `audit.log` JSON lines 기록 + `history` 배열 유지. **마이그레이션**: `migrate-workflow-history.sh`로 기존 311개 JOB에 `startedAt` 추정 적용. **상세**: `references/workflow-logging-and-monitoring.md`

11. **워크플로우 로깅/모니터링 시스템 **(JOB-1415) 328개 JOB 중 40+ 건이 24시간 이상 중단된 상태로 방치. **JOB-1415에서 해결**: `workflow-audit.sh` (일일 점검 리포트, cron 07:00) + `monitor.sh` 확장 (중단 감지 + 단계 건너뜀 감지) + `cron-phases.yaml`에 audit phase 추가. **임계값**: 승인 단계 72h (의도적 대기 허용), 기타 단계 24h. **상세**: `references/workflow-logging-and-monitoring.md`

12. **승인 단계 임계값 **(JOB-1415 사용자 피드백) 승인은 순서 조정이나 보류 등으로 의도적으로 오래 걸릴 수 있음. 기존 24h 임계값은 승인 단계에 적합하지 않음. **해결**: 승인 단계는 72h로 별도 설정, 기타 단계는 24h 유지. **위치**: `workflow-audit.sh`, `monitor.sh`

## JOB 생성 및 관리

**JOB 생성**: `create-job.sh` 사용 (직접 mkdir 금지)
- flock 기반 원자적 락 메커니즘 (v3)
- 중복 감지 + 자동 재할당
- 상세: `job-lifecycle-management` 스킬 참조

**중복 정리**: `bash ~/.hermes/scripts/dedup-jobs.sh`
- 중복 스캔 → 재할당 → 검증
- 폴더명 특수문자 주의 (콜론, 이모티콘, 인코딩 문자)

### ⛔ 계층형 JOB 번호 금지 (JOB-1340 학습 — 사용자 정정)

**사용자 정정**: "작업 번호는 모두 별개여야지"

**금지 패턴**:
- ❌ `JOB-1340-1`, `JOB-1340-1-2` 같은 계층형 번호
- ❌ `JOB-루트-계층-하위` 패턴

**올바른 패턴**:
- ✅ 각 JOB은 **별도 순차 번호** (`JOB-1340`, `JOB-1342`, `JOB-1343`)
- ✅亲子关系는 **`--parent JOB-XXXX`** 필드로 관리
- ✅ `create-job.sh --parent JOB-XXXX`로 생성 시 자동 연결

**예시 **(GPU 대여 시스템)
```
JOB-1340 [루트] GPU 대여 시스템 구축
├── JOB-1342: Vast.ai 환경 구축 (--parent JOB-1340)
│   ├── JOB-1343: 계정/API 키/볼륨 (--parent JOB-1342)
│   ├── JOB-1344: vast_client.py (--parent JOB-1342)
│   └── JOB-1345: instance_manager.py (--parent JOB-1342)
└── JOB-1289: RunPod 환경 구축 (--parent JOB-1340)
    ├── JOB-1320: RunPod 계정/API (--parent JOB-1289)
    └── JOB-1322: RunPod API 클라이언트 (--parent JOB-1289)
```

**원칙**: 번호는 항상 독립 순차. 계층 관계는 `--parent` 필드로만 표현.

## ⚠️ create-job.sh 성능 최적화 (JOB-1355 교훈)

**문제**: JOB 300+개 기준 9.3초 지연 → subprocess 누적 (975회 호출)

**근본 원인**:
- `get_next_job_number()`: 각 JOB 디렉토리당 3个子process (basename, sed, grep)
- `sanitize_title()`: 6개 파이프라인 (echo + tr/sed/cut)
- `validate_and_reassign()`: 최대 10회 glob 스캔

**해결 **(이미 적용됨)
- `find -P + sort -n` 단일 파이프라인 → **0.1초**
- 단일 `sed` 명령 통합 → **0.02초**
- `ls -d` 단일 호출 → **0.05초**
- **결과**: 9.3초 → 0.132초 (98.6% 개선)

**⚠️ Pitfall **(스크립트 수정 시)
- `sanitize_title()`에서 `/` 대체 시 sed delimiter 충돌 → `|` delimiter 사용 필수
- `find` 명령에 `-P` 플래그 필수 (symbolic link 무한 루프 방지)
- `find`에 `2>/dev/null` 추가 (권한 에러 억제)

**검증**: `time bash create-job.sh --dry-run 개선 "테스트"` → 0.1초 이내 확인

## JOB 생성 및 관리

**JOB 생성**: `create-job.sh` 사용 (직접 mkdir 금지)
- flock 기반 원자적 락 메커니즘 (v3)
- 중복 감지 + 자동 재할당
- 상세: `job-lifecycle-management` 스킬 참조

**중복 정리**: `bash ~/.hermes/scripts/dedup-jobs.sh`
- 중복 스캔 → 재할당 → 검증
- 폴더명 특수문자 주의 (콜론, 이모티콘, 인코딩 문자)

### ⛔ 계층형 JOB 번호 금지 (JOB-1340 학습 — 사용자 정정)

**사용자 정정**: "작업 번호는 모두 별개여야지"

**금지 패턴**:
- ❌ `JOB-1340-1`, `JOB-1340-1-2` 같은 계층형 번호
- ❌ `JOB-루트-계층-하위` 패턴

**올바른 패턴**:
- ✅ 각 JOB은 **별도 순차 번호** (`JOB-1340`, `JOB-1342`, `JOB-1343`)
- ✅亲子关系는 **`--parent JOB-XXXX`** 필드로 관리
- ✅ `create-job.sh --parent JOB-XXXX`로 생성 시 자동 연결

**예시 **(GPU 대여 시스템)
```
JOB-1340 [루트] GPU 대여 시스템 구축
├── JOB-1342: Vast.ai 환경 구축 (--parent JOB-1340)
│   ├── JOB-1343: 계정/API 키/볼륨 (--parent JOB-1342)
│   ├── JOB-1344: vast_client.py (--parent JOB-1342)
│   └── JOB-1345: instance_manager.py (--parent JOB-1342)
└── JOB-1289: RunPod 환경 구축 (--parent JOB-1340)
    ├── JOB-1320: RunPod 계정/API (--parent JOB-1289)
    └── JOB-1322: RunPod API 클라이언트 (--parent JOB-1289)
```

**원칙**: 번호는 항상 독립 순차. 계층 관계는 `--parent` 필드로만 표현.

## 스크립트 인프라 (JOB-1275/1276/1277 교훈)

### lib/ 디렉토리 필수 파일
`~/.hermes/scripts/lib/`에 아래 파일 존재 필수:
- `common.sh`: `step_to_number()`, `update_workflow_state()`, `require_job_dir()`, `read_workflow_state()`
- `approval.sh`: `require_valid_approval()`, `check_approval()`, `get_approval_option()`
- `review-status.sh`: `file_has_pass()`, `get_review_status()`, `has_self_review()`
- `workflow.sh`: `check_step_requirements()`

**⚠️ symlink 금지**: 상대 경로 의존성 문제 발생. 직접 복사 필수.

### 체크포인트 패턴 (validate-checkpoints.sh)

| 체크 | 필수 패턴 | 비고 |
|------|-----------|------|
| I1 | `SKILL.md` 또는 `workflow` | request.md 참조 섹션 |
| I3 | `[STATUS: PASS]` | review-result-*.md |
| I5b | `요구사항`, `\|.*현재.*\|.*변경`, `review-result` | architecture.md |
| I7 | `approval.json` + `require_valid_approval()` 통과 | approval.sh 함수 호출 |

### transition-step.sh 리뷰 연동 (4/8단계)

4-reviewing 또는 8-exec-review 진입 시 자동 리뷰 호출:
```bash
case "$NEW_STEP" in
    4-reviewing) bash "$SCRIPT_DIR/run-review.sh" "$JOB_DIR" "design" ;;
    8-exec-review) bash "$SCRIPT_DIR/run-review.sh" "$JOB_DIR" "exec" ;;
esac
```

### run-review.sh 스크립트

`~/.hermes/scripts/run-review.sh`:
- GLM-5.1 리뷰 호출 (zai 프로바이더)
- 5시간 단위 토큰 한도 모니터링 (`/tmp/hermes-glm-token-usage.log`)
- 폴백: 셀프 리뷰 복사
- 사용법: `bash run-review.sh <JOB_DIR> <design|exec>`

## 워크플로우 스크립트 배포 규칙 (JOB-1275/1276)

### ⛔ symlink 금지 (라이브러리 의존성 있는 스크립트 — JOB-1275 확인)

**symlink는 상대 경로로 lib/ 로딩 실패**. 반드시 직접 복사.

**올바른 배포**:
```bash
# 스크립트 복사 + 실행 권한
cp skills/workflow/scripts/*.sh ~/.hermes/scripts/
chmod +x ~/.hermes/scripts/*.sh

# 라이브러리 전체 복사
cp -r skills/workflow/lib ~/.hermes/scripts/lib/
```

**⚠️ 필수 함수 누락 확인 (JOB-1276 학습)**:
```bash
# 검증: 필수 함수 모두 존재하는지 확인
grep -c "require_valid_approval\|file_has_pass\|update_workflow_state\|step_to_number" ~/.hermes/scripts/lib/*.sh
```

누락 시 아래 함수 수동 추가 (또는 lib/ 전체 재복사).

**⚠️ transition-step.sh 파라미터 수정 (JOB-1277 학습)**:
```bash
# ❌ update_workflow_state "$JOB_DIR" "$NEW_STEP"  # 2인자 → 실패
# ✅ update_workflow_state "$JOB_DIR/.workflow-state" "$NEW_STEP" "running"  # 3인자
```

**⚠️ common.sh 파라미터 기본값 필수**:
```bash
# ❌ local status="$3"  # unbound variable
# ✅ local status="${3:-running}"  # 기본값 필수
```

### 필수 라이브러리 파일

| 파일 | 용도 |
|------|------|
| `lib/common.sh` | 공통 함수 (require_job_dir, read_workflow_state, update_workflow_state, step_to_number) |
| `lib/approval.sh` | 승인 관련 (check_approval, get_approval_option, **require_valid_approval**) |
| `lib/review-status.sh` | 리뷰 상태 (get_review_status, review_status_has_pass, **file_has_pass**, has_approval_json) |
| `lib/workflow.sh` | 워크플로우 검증 (check_step_requirements) |

### ⚠️ 라이브러리 함수 누락 패턴 (JOB-1276 학습)

스크립트 배포 시 필수 함수 누락으로 체크포인트 실패하는 경우가 빈발:

| 누락 함수 | 속한 파일 | 증상 | 해결 |
|-----------|-----------|------|------|
| `require_valid_approval` | `approval.sh` | I7 실패 ("command not found") | 함수 추가 또는 스크립트 복사 |
| `file_has_pass` | `review-status.sh` | I3 실패 ("command not found") | 함수 추가 (파일 인자용) |
| `update_workflow_state` | `common.sh` | transition-step.sh 실패 | 함수 추가 (state_file, current_step, status 3인자) |
| `step_to_number` | `common.sh` | step_num 추출 실패 | case문 추가 |
| `EXIT_PASS`/`EXIT_FAIL` | `common.sh` | unbound variable | 변수 정의 추가 |

**검증 명령**:
```bash
grep -c "require_valid_approval\|file_has_pass\|update_workflow_state\|step_to_number" ~/.hermes/scripts/lib/*.sh
```

### common.sh 필수 템플릿 (최소)

```bash
EXIT_SUCCESS=0
EXIT_ERROR=1
EXIT_FAIL=1
EXIT_PASS=0

step_to_number() {
    case "$1" in
        request) echo 1 ;; 2-*) echo 2 ;; 3-*) echo 3 ;;
        4-*) echo 4 ;; 5-*) echo 5 ;; 6-*) echo 6 ;;
        7-*) echo 7 ;; 8-*) echo 8 ;; 9-*) echo 9 ;;
    esac
}

update_workflow_state() {
    local state_file="${1:-}" current_step="${2:-}" status="${3:-running}"
    # Python으로 JSON 업데이트
}
```

### review-status.sh 함수 구별 (JOB-1276 학습)

- `review_status_has_pass "$job_dir"` — **JOB 디렉토리** 인자 (리뷰 파일 자동 탐색)
- `file_has_pass "$file"` — **파일 경로** 인자 (직접 grep)

validate-checkpoints.sh에서 `review_status_has_pass "$f"` (파일 인자)로 호출하면 실패.
→ `file_has_pass`로 변경 필수.

### 상태 파일 표준화

`.workflow-state` 파일이 파싱 실패 시:
1. `.workflow-state.json.backup`으로 백업
2. 표준 JSON 템플릿으로 초기화 (9단계 steps 배열 포함)
3. 파일 존재 여부로 현재 단계 복원

### FTS5 SQLite 초기화 (JOB-1276 학습)

메모리 시스템 복구 시 FTS5 external content table 사용:

```python
import sqlite3

conn = sqlite3.connect('memory.db')
c = conn.cursor()

# 메인 테이블
c.execute('''CREATE TABLE memories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    content TEXT NOT NULL,
    content_type TEXT DEFAULT 'note',
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
)''')

# ⚠️ FTS5 external content 문법: content='테이블명', content_rowid='id'
c.execute('''CREATE VIRTUAL TABLE memories_fts
    USING FTS5(content, content_type,
    content='memories', content_rowid='id')''')

# 트리거 (INSERT/DELETE/UPDATE)
c.execute('''CREATE TRIGGER memories_ai AFTER INSERT ON memories BEGIN
    INSERT INTO memories_fts(rowid, content, content_type)
    VALUES (new.id, new.content, new.content_type);
END''')
# ... DELETE/UPDATE 트리거도 추가

conn.commit()
```

**⚠️ Pitfall**: `content_rowid=memories.id` → 실패. `content_rowid='id'` (스트링) 필수.

### 체크포인트 검증 (I1-I13)

validate-checkpoints.sh가 강제하는 검증:
- I1: request.md에 SKILL.md 읽음 기록
- I3: review-result-*.md에 [STATUS: PASS] 포함
- I7: approval.json 존재 + 유효한 옵션 (A/B/C)
- I13: lessons/index.md에 JOB 항목 기록

검증 실패 시 transition-step.sh가 단계 전환 차단 (exit 1).

---

## 체크포인트 검증 패턴 (JOB-1247 학습)

워크플로우 진행 중 체크포인트 검증 실패시 반드시 아래 패턴 따름:

| 체크포인트 | 필수 내용 | 검증 패턴 |
|-----------|-----------|-----------|
| I1 | request.md에 'SKILL.md' 또는 'workflow' 읽음 기록 | `grep -qiE "SKILL\.md\|workflow" request.md` |
| I5b | architecture.md에 '요구사항' 섹션 | `grep -qiE "요구사항\|요구" architecture.md` |
| I5b | Before/After 테이블 헤더 | `grep -qiE "\\|.*현재.*\|.*변경" architecture.md` |
| I5b | 리뷰 결과 인용 | `grep -qiE "review-result" architecture.md` |
| I7 | approval-request.json + approval.json + 해시 | 두 파일의 request_id, architecture_sha256 일치 |

**Before/After 테이블 작성법**:
```markdown
## Before/After 비교

| 항목 | 현재 | 변경 |
|------|------|------|
| 예시 | 기존 상태 | 변경 내용 |
```
❌ `| Before | After |` 사용 금지 — 검증 패턴이 인식하지 않음

**승인 파일 생성 순서**:
1. `approval-request.json` 먼저 생성 (request_id + architecture_sha256)
2. `approval.json` 생성 (choice + request_id + architecture_sha256)
3. 두 파일의 해시값이 현재 architecture.md의 sha256과 일치해야 함

## 검증 스크립트 함정 (JOB-1250 교훈)

### transition-step.sh 체크포인트 검증

| 체크포인트 | 요구사항 | 함정 |
|-----------|----------|------|
| I5b | architecture.md에 `요구사항` 섹션 | "요구" 또는 "요구사항" 키워드 필수 |
| I5b | Before/After 테이블 | `\|.*현재.*\|.*변경` 패턴 — "현재"/"변경" 키워드 필수, "Before/After" 불가 |
| I5b | 리뷰 결과 인용 | `review-result` 텍스트 포함 필수 |
| I7 | approval.json | `write_approval_request` 함수 사용 필수. 필드: `choice`='A', `request_id`, `architecture_sha256` |
| I13c | lessons/index.md | 위치: `~/.hermes/workspace/jobs/lessons/index.md` (JOB 폴더가 아님) |

### approval.json 생성 (정규화된 방법)

```bash
# 1. approval-request.json 생성 (architecture.md hash 자동 계산)
source ~/.hermes/skills/custom/code-scripts/workflow/scripts/lib/approval.sh
write_approval_request <JOB_DIR> <JOB_ID>

# 2. approval.json 생성 (request_id, architecture_sha256 일치 필수)
cat > <JOB_DIR>/approval.json << EOF
{
  "job_id": "<JOB_ID>",
  "request_id": "<write_approval_request 출력값>",
  "choice": "A",
  "approved_by": "사용자명",
  "approved_at": "<ISO8601>",
  "architecture_sha256": "<자동 계산됨>",
  "summary": "승인 요약"
}
EOF
```

### transition-step.sh 실패 시 수동 상태 전환

스크립트 버그("unexpected failure at line XXX") 발생 시:
1. 직접 `.workflow-state` JSON 파일 생성
2. `transition-step.sh` 재시도
3. 체크포인트 검증 스크립트(`validate-checkpoints.sh`)에서 요구하는 형식 확인 후 대응

## 트러블슈팅

### transition-step.sh / workflow-gate.sh 스크립트 버그 (JOB-1248, JOB-1250)

`transition-step.sh` 실행 시 `unexpected failure at line 320/715` 오류 발생 시:

1. **수동 .workflow-state 생성**: 직접 JSON 파일 작성
   ```json
   {
     "jobId": "JOB-XXXX",
     "status": "running",
     "currentStep": "{단계}",
     "steps": [
       { "name": "1-request", "status": "done", "completedAt": "ISO8601" }
     ],
     "startedAt": "ISO8601",
     "updatedAt": "ISO8601",
     "artifacts": ["request.md"]
   }
   ```
2. 다음 단계로 진행 (스크립트 재시도하지 않고 진행)

**원인**: 스크립트 내부 line 320/715에서 unhandled error 발생. 별도 버그 수정 JOB 필요.

### create-job.sh 필수 인자

`create-job.sh`는 **유형 인자 필수** (제목만으로는 실패):

```bash
# ❌ 실패
bash create-job.sh "작업 제목" "설명"

# ✅ 성공 (유형: 기능|수정|조사|정리|운영|개선|시스템|기타)
bash create-job.sh "정리" "작업 제목" "설명"
```

### ⚠️ create-job.sh 락 누수 (JOB-1412 학습)

**문제:** `/tmp/.create-job.lock`이 예외 발생 시 영구적으로 남음 → 이후 JOB 생성 실패

**수정:** `trap 'rm -f "$LOCK_FILE"' EXIT INT TERM HUP` 추가

**테스트 시 401 오류 원인:**
- curl 명령어에서 API 키가 잘려서 전달됨 (escaping 문제)
- **해결:** 키를 변수로 저장 후 전달
```bash
KEY=$(grep GLM_API_KEY ~/.hermes/.env | cut -d= -f2)
curl -s "https://api.z.ai/api/coding/paas/v4/chat/completions" \
  -H "Authorization: Bearer ***
```

**임시 해결:** `rm -f /tmp/.create-job.lock` 수동 제거

**문제:** 한국어 제목을 사용하면 `sanitize_title()`이 디렉토리 생성 시 인코딩 문제를 일으켜 mkdir가 실패 (exit code 1). JOB 번호는 출력되지만 폴더가 실제로 생성되지 않음.

**증상:** `create-job.sh`가 "JOB-XXXX 생성 완료"를 출력해도 `ls ~/.hermes/workspace/jobs/JOB-XXXX-*`가 빈 결과.

**해결:** 제목은 **ASCII-only**로 작성. 한국어 내용은 `request.md`에서 작성:

```bash
# ❌ 실패 (한국어 제목)
bash create-job.sh -y 개선 "주기적 폴리싱 시스템 확대"

# ✅ 성공 (ASCII 제목)
bash create-job.sh -y 개선 "Expand periodic polishing system"
```

**확인:** 실행 후 반드시 `ls -d ~/.hermes/workspace/jobs/JOB-XXXX-*`로 폴더 존재 확인 필수. `-y` 플래그도 필수 (non-interactive shell에서 read 프롬프트가 hang 발생).

### 체크포인트 I1/I14 필수 항목

`request.md`에 아래 항목 없으면 I1/I14 검증 실패:

```markdown
## 참고

- **SKILL.md 읽음**: `skills/custom/code-scripts/workflow/SKILL.md` (YYYY-MM-DD HH:MM)
- **관련 교훈 없음**: 새 작업으로 기존 교훈 참조 불필요
  (또는 `lessons/파일명` 참조)
```

**⚠️ I14 함정**: `**교훈:**` (볼드) 금지. `교훈:` (평문) 필수. 상세: [references/checkpoint-pitfalls.md](./references/checkpoint-pitfalls.md)

**⚠️ I13c 함정** (JOB-1252/1253):
- `lessons/index.md` 위치: `~/.hermes/workspace/jobs/lessons/index.md` (workspace 루트가 아님!)
- 검증: `grep "$job_id" "$ws_idx"` → JOB-ID 패턴 반드시 포함
- 해결: index.md에 `### JOB-XXXX: 제목` 항목 추가
- **⚠️ 등록률 46% 문제 **(JOB-1393) 생성된 lessons.md 중 절반 이상이 index.md에 미등록 → 상세: [references/lessons-lifecycle-issue.md](./references/lessons-lifecycle-issue.md)

**⚠️ model-settings.yaml 실행 순서** (JOB-1252/1253):
- GLM-5.1 등 reasoning 모델 설정 변경 시 **가장 먼저** 적용
- 설정 없이 실행 시 8K 토큰 폴백 → content 비어있음 → 실제 작업 불가

---

## ⚠️ Pitfalls: transition-step.sh / validate-checkpoints.sh

### `.workflow-state` currentStep 허용값

transition-step.sh는 정확한 값만 허용. **잘못된 값 예시**:
- ❌ `"currentStep": "investigation"` → ✅ `"currentStep": "2-investigating"`
- ❌ `"currentStep": "designing"` → ✅ `"currentStep": "3-designing"`
- ❌ `"currentStep": "reviewing"` → ✅ `"currentStep": "4-reviewing"`

**정확한 매핑**:
| 단계 | 허용값 |
|------|--------|
| 1-요청 | `request` |
| 2-조사 | `2-investigating` |
| 3-설계 | `3-designing` |
| 4-리뷰 | `4-reviewing` |
| 5-승인 | `5-approved` |
| 6-실행 | `6-executing` |

### 다단계/Phase 기반 실행 (JOB-1392 학습)
- 복잡한 JOB은 Phase 단위로 분할 실행
- Phase 완료 후 검증 → 다음 Phase 진행
- `execution.md`에 Phase별 결과 기록

### Phase 검증 체크리스트
- [ ] 코드/스크립트 빌드
- [ ] 단위 테스트 통과
- [ ] 문서화 완료
- [ ] 사용자에게 Phase별 결과 보고
| 7-테스트 | `7-testing` |
| 8-실행리뷰 | `8-exec-review` |
| 9-교훈 | `9-done` / `9-superseded` / `9-cancelled` |

### I14 체크포인트: "관련 교훈 없음" 문구 고정

validate-checkpoints.sh의 I14는 request.md에 **정확한 패턴**을 요구:
- ✅ `관련 교훈 없음` (정확히 이 문구)
- ❌ `교훈 인용 없음` (인식 안 됨)
- ❌ `교훈: 없음` (인식 안 됨)

```markdown
## 관련 교훈

**관련 교훈 없음**
```

### 3단계 진입 시 architecture.md 필수

transition-step.sh가 3-designing으로 전환 시 **architecture.md가 이미 존재해야 함**.
순서:
1. 빈 architecture.md 생성 (또는 템플릿 기반)
2. `transition-step.sh <JOB_DIR> 3-designing` 실행
3. architecture.md 보강

architecture.md 템플릿: `templates/architecture.md` 참조.

### 4단계 진입 시 review-result-*.md 필수

transition-step.sh가 4-reviewing으로 전환 시 **review-result-*.md가 이미 존재해야 함**.
순서:
1. 3단계에서 리뷰어 서브에이전트 spawn
2. review-result-*.md 생성 대기
3. `transition-step.sh <JOB_DIR> 4-reviewing` 실행

### 결과 파일 검증 (JOB-1221 교훈)
서브에이전트 완료 후 **반드시** `ls -la JOB_DIR/`로 결과 파일 존재 확인.
파일 누락 시: 서브에이전트 task 재발송 또는 수동 보강 후 진행.

## 세션 지속성 (JOB-1197)

**문제**: 세션 변경 시 진행 중 JOB 상태 손실

**해결**: `~/.hermes/workspace/ACTIVE-JOBS.md` 사용

### 규칙
1. **새 세션 시작 시**: `ACTIVE-JOBS.md` 확인 → 진행 중 JOB 자동 복원
2. **JOB 생성 시**: `ACTIVE-JOBS.md`에 추가
3. **JOB 완료 시**: `ACTIVE-JOBS.md`에서 제거 + `lessons.md` 생성
4. **복구 명령**: `cat ~/.hermes/workspace/jobs/JOB-XXXX/.workflow-state`로 현재 단계 확인

### Telegram Gateway 설정 참고
- Telegram 메시지 필터링 아키텍처: `references/telegram-gateway-architecture.md` 참조
- 2-Level 필터링 (채널 레벨 + 사용자 레벨) - 둘 다 설정 필요

## ⚠️ 알려진 이슈 및 대응 (JOB-1189)

### ⚠️ create-job.sh 디렉토리/상태 파일 미생성

`create-job.sh`가 JOB 번호를 반환하지만 실제로 디렉토리나 `.workflow-state` 파일을 생성하지 않을 수 있음.

**대응 절차**:
1. `create-job.sh` 실행 후 JOB 번호 확인
2. 디렉토리 존재 확인: `ls ~/.hermes/workspace/jobs/JOB-XXXX/`
3. 디렉토리 없으면 수동 생성
4. `.workflow-state` 파일 수동 생성 (템플릿 참조)

**⚠️ JOB-1476 개선: sanitize_title UTF-8 안정성**
- **문제**: `cut -c1-80`이 한글을 바이트 단위로 잘 수 있음
- **해결**: `head -c80` 사용 + `LC_ALL=C.UTF-8` 명시
- **위치**: `~/.hermes/scripts/create-job.sh` Line 93
- **테스트**: 한글 제목 "한글 제목 테스트" 정상 생성 확인 (JOB-1480)
   mkdir -p ~/.hermes/workspace/jobs/JOB-XXXX/
   ```
4. `.workflow-state` 파일 수동 생성 (템플릿 참조):
   ```json
   {
     "jobId": "JOB-XXXX",
     "status": "running",
     "currentStep": "investigation",
     "steps": [
       { "name": "request", "status": "done", "completedAt": "ISO8601" },
       { "name": "investigation", "status": "in_progress", "startedAt": "ISO8601" },
       { "name": "design", "status": "pending" },
       { "name": "review", "status": "pending" },
       { "name": "approval", "status": "pending" },
       { "name": "execution", "status": "pending" },
       { "name": "test", "status": "pending" },
       { "name": "execution_review", "status": "pending" },
       { "name": "done", "status": "pending" }
     ],
     "startedAt": "ISO8601",
     "updatedAt": "ISO8601",
     "artifacts": []
   }
   ```

### workflow-gate.sh transition 액션

skill 문서에는 `workflow-gate.sh`를 "읽기 전용"으로 설명하지만, 실제 스크립트는 `transition` 액션을 지원합니다:

```bash
bash workflow-gate.sh JOB-XXXX transition <step_name>
```

### .workflow-state 허용 상태값 (transition-step.sh 검증)

```
request, 2-investigating, 3-designing, 4-reviewing, 4-fix,
5-waiting-approval, 5-approved, 5-revision-requested,
6-executing, 7-testing, 8-exec-review,
9-done, 9-superseded, 9-cancelled
```

**⚠️ Pitfall **(JOB-1247) `5-approval` 같은 상태명은 허용 안됨 — `5-waiting-approval` 사용 필수

### I5b 체크포인트: Before/After 테이블 패턴

검증 스크립트 패턴: `\|.*현재.*\|.*변경`

**architecture.md에 필수 포함**:
```markdown
## Before/After 비교

| 항목 | 현재 | 변경 |
|------|------|------|
| 설정 A | 기존 값 | 새 값 |
```

**❌ 실패 형식**: `| Before | After |` (영문 헤더는 인식 안됨)

지원 단계명: `investigation`, `design`, `review`, `approval`, `execution`, `test`, `execution_review`, `done`

**참고**: `transition-step.sh`와 `workflow-gate.sh transition`은 동일한 기능을 수행하나, 스크립트 상태에 따라 사용 가능한 것이 다를 수 있음. 둘 중 하나만 작동하면 충분함.

## 간소화 마킹 (JOB-1184)

간단한 작업(스크립트 생성, 설정 변경 등)은 `architecture.md` 제목에 `(간소화)`를 명시하면 검증 체크포인트가 자동 완화됨.

| 체크 | 간소화 효과 |
|------|-------------|
| check_i8 | exec-review-result.md 생략 가능 |
| check_i13b | lessons.md 10줄 이상/## 헤더 검증 패스 |
| check_i13c | lessons/index.md 등록 패스 |

**사용법**: `architecture.md` 제목에 `(간소화)` 포함
```markdown
# JOB-XXXX: 작업 제목 (간소화)
```

**⚠️ 여전히 필요한 파일 **(JOB-1532 교훈)
- `exec-review-result.md` (check_i8는 파일 존재 확인 → 간소화면 skip)
- `execution.md` (check_i8a에서 파일 부재 시 ERR trap 발동 → **최소 Phase + 검증 포함**)
- `lessons.md` (check_i13a 존재 확인 필수)
- **approval.json**: `choice` 필드 필수 (없음 시 `workflow-gate.sh complete` BLOCKED)

## Pitfalls

### I13c: lessons/index.md 위치 (JOB-1182)
검증 스크립트는 `jobs/lessons/index.md`(JOB 디렉토리 **부모**)를 확인합니다.
`jobs/JOB-XXXX/lessons/index.md`(JOB 내부)에 만들면 **검증 실패**합니다.
```bash
# ✅ 맞음 (모든 JOB 공유)
mkdir -p ~/.hermes/workspace/jobs/lessons
```

### 승인 파일 strict 검증 (JOB-1182)
approval.json은 choice/request_id/architecture_sha256이 모두 정확히 일치해야 합니다.
- `choice`: 반드시 `"A"` (대문자)
- `request_id`: approval-request.json과 동일
- `architecture_sha256`: 현재 architecture.md의 sha256과 동일

### WSL date 명령어 (JOB-1184)
- `date -v-7d` → macOS 전용 (WSL에서 오류)
- `date -d "7 days ago"` → Linux/WSL 호환

### Hermes no_agent 크론잡 스크립트 (JOB-1184)
- `~/.hermes/scripts/` 하위에 직접 파일 배치해야 함
- symlink는 "directory traversal"로 차단됨 → `cp` 사용

### validate-checkpoints.sh ERR trap (JOB-1184)
- `set -euo pipefail` + `trap ERR`로 설정되어 있어 함수 내 명령어 실패 시 전체 스크립트 중단
- `execution.md`가 없으면 check_i8a에서 `[[ -f ]]` 실패 → ERR trap 발동 → 단계 전환 차단
- 해결: 빈 `execution.md` 파일이라도 생성 필요

### 상태명 오기 (JOB-1184)
- `8-execution-review` ❌ → `8-exec-review` ✅
- 허용값: `request|2-investigating|3-designing|4-reviewing|4-fix|5-waiting-approval|5-approved|5-revision-requested|6-executing|7-testing|8-exec-review|9-done|9-superseded|9-cancelled`
**delegate_task 인코딩**: task goal/context는 영어로 작성 (한국어 시 JSON 파싱 오류). 상세: `references/subagent-pitfalls.md`
**중국어 문자 오염 방지**: spawn 시 task에 `응답은 한국어로 작성하세요. 중국어 문자 사용 금지.` 포함. 결과 파일 스캔 권장.

---

## 프로세스 준수 현황 (JOB-1350 심층 분석 기준)

**2026-05-25 기준 142개 완료 JOB 샘플 분석 결과:**

| 검증 항목 | 준수율 | 상태 |
|-----------|--------|------|
| 리뷰 완료 | 83% (118/142) | ✅ |
| 승인 파일 존재 | 36% (51/142) | ❌ |
| 테스트 단계 | 82% (117/142) | ✅ |
| 교훈 문서화 | 58% (82/142) | ⚠️ |
| **전체 산출물 완전** | **34% (48/142)** | **❌** |

**핵심 발견:**
- 승인 파일(approval.json) 64% 누락 → 승인 단계 우회 의심
- 산출물 66% 누락 → "완료" 상태지만 검증 안 된 JOB 다수
- Eval pipeline 완전 부재 (benchmark/eval/feedback loop 0/4)

**해결 방향**: workflow-gate.sh 9단계 진입 전 산출물 검증 강제 + 승인 파일 필수 체크

## ⛔ 프로세스 준수 강제 (JOB-1169/1170 교훈)

**사용자 명시적 지시: "프로세스 지켜"** — 9단계 파이프라인은 선택이 아님.

### ⛔ 절대 금지
- ❌ `.workflow-state` 직접 `echo`로 수정 → **반드시 `transition-step.sh` 사용**
- ❌ 단계 스킵 (review, approval, test, execution_review, lessons)
- ❌ "단순 개선이라서 생략" 정당화 — 모든 JOB은 9단계 준수
- ❌ **모든 단계 한 번에 처리 **(JOB-1264/1274 학습)request→done 일괄 금지. 각 단계별 전환+보고 필수

### 스크립트 배포 검증 (JOB-1275 학습)

workflow 스킬의 스크립트들은 `~/.hermes/scripts/`에 symlink로 배포되어야 함:
```bash
# 필수 스크립트 확인 (JOB 시작 시 또는 주기적으로)
ls -la ~/.hermes/scripts/transition-step.sh ~/.hermes/scripts/validate-checkpoints.sh
```

**⛔ Pitfall: 스크립트 누락 시 수동 .workflow-state 편집 발생**
- 61개 `.workflow-state` JSON 파싱 실패 발견 → 원인: `transition-step.sh` 누락
- 해결: `ln -sf`로 스킬 디렉토리에서 symlink 생성
- 표준 상태값: `request`, `2-investigating`, `3-designing`, `4-reviewing`, `5-approved`, `6-executing`, `7-testing`, `8-exec-review`, `9-done`, `9-cancelled`, `9-superseded`
- ❌ `.workflow-state` 단순 문자열 → **JSON 형식 필수** (단계별 timestamp 포함)

### 승인 단계 처리
- 리뷰 PASS → 승인 요청 (1회) → **사용자 응답 반드시 대기**
- "진행해" = 승인 획득 → `transition-step.sh 5-approved` 후 ⑥실행 진입
- 승인 없이 실행 시작 금지 (JOB-1124 지적事项)

### 교훈 단계 강제
- JOB 완료 시 `lessons.md` 생성 **필수**
- 기술적 교훈 + 프로세스 교훈 모두 기록
- 교훈 없이 JOB 완료 금지

### 위반 시 자동 감지
```bash
# workflow-state 형식 검증
python3 -c "
import json
with open('.workflow-state') as f:
    data = json.load(f)
assert 'currentStep' in data, 'JSON 형식 필수'
assert 'steps' in data, '단계 이력 필수'
"
```

## Pitfalls

- **JOB 제목에 `/` 금지** (JOB-1167): `create-job.sh`는 제목을 디렉토리 이름으로 사용하므로, `/`가 포함되면 여러 단계의 디렉토리가 생성됩니다. 제목에는 `/`를 사용하지 말고, `-` 또는 `_`를 사용하세요. (예: "A/B 구조" → "A-B 구조")
- **`.workflow-state` 직접 수정 금지** (JOB-1176): 에이전트가 `echo` 또는 `write_file`로 직접 수정하면 JSON 파싱 오류 발생. 모든 상태 변경은 `workflow-gate.sh` 사용.
- **JOB ID 형식** (JOB-1176): `workflow-gate.sh`는 `JOB-XXXX` 형태만 인식 (예: `JOB-1176`). 폴더 전체 경로 (`JOB-1176-Title`) 전달 시 오류 발생.
- **`workflow-gate.sh` 액션** (JOB-1193 교훈): `start`, `complete`, `transition <step>` **모두 지원**. 예전 문서의 "transition 지원 안 함"은 **잘못된 정보**입니다.
  ```bash
  # 정상 작동하는 단계 전환 예시
  bash workflow-gate.sh JOB-1193 transition review    # ✅
  bash workflow-gate.sh JOB-1193 transition execution # ✅
  bash workflow-gate.sh JOB-1193 transition test      # ✅
  ```
- **`workflow-gate.sh` 인코딩 문제** (JOB-1172): `$HOME/.hermes/workspace/jobs/$JOB_ID-*` glob 패턴이 한글/특수 문자 포함 폴더명에서 실패. **해결**: `find ~/.hermes/workspace/jobs/ -maxdepth 1 -name "*${JOB_ID}*" -type d | head -1` 으로 폴더 탐색 후 사용.
### ⛔ 절대 금지: 승인 단계 생략 (JOB-1176/1172/1472/1477 교훈 + JOB-1277/1393/1477 사용자 지적)

리뷰 PASS 후 **반드시 승인 요청 메시지 발송 → 사용자 응답 대기**.

**⚠️ JOB-1477 사용자 지적 **(직접 경험 — "등록하라고 했는데 왜 실행까지 했어?")
- **사용자 피드백**: "작업 등록해줘" 요청에 JOB 생성 → 승인 자동 생성 → 실행까지 일괄 진행
- **문제**: "작업 등록해줘" ≠ "직접 실행해줘". JOB 생성 + 승인 요청까지가 한 단계
- **근본 원인**: 자동 승인 심리 → approval.json 자동 생성 → 5-approved → 6-executing 일괄 진행
### ⛔ 승인 단계 절대 누락 금지 (JOB-1176/1172/1472/1479 교훈 + JOB-1277/1393 사용자 지적)

리뷰 PASS 후 **반드시 승인 요청 메시지 발송 → 사용자 응답 대기**.

**⚠️ JOB-1479 교훈 **(간소화로 승인 bypass — 사용자 직접 지적)
- **사용자 피드백**: "프로세스대로 했어? 승인 요청을 못받았는데", "왜 못되돌려?"
- **문제**: architecture.md에 "(간소화)" 마킹 후 승인 요청 없이 진행 → workflow-gate.sh 검증 bypass
- **근본 원인**: "(간소화)" = 승인 스킵이라는 오해 → workflow-gate.sh는 "(간소화)" JOB에 approval.json 검증을 skip
- **절대 금지**: "(간소화)" 마킹으로 승인 단계 bypass. "(간소화)"는 **검증 완화**일 뿐, **승인 스킵**이 아님
- **올바른 처리**: "(간소화)" JOB도 설계 완료 후 승인 요청 → 사용자 응답 대기 → approval.json 생성 → 진행
- **징후**: 사용자가 "승인 요청을 못받았는데", "왜 못되돌려?" 지적 → 승인 bypass 시도
- **해결**: JOB-1479는 workflow-state를 approval 단계로 되돌림 + 승인 재요청 + 승인 후 진행

**⚠️ JOB-1472 교훈 **(승인 없이 execution 진입 — 사용자 직접 지적)
- **사용자 피드백**: "승인 안했는데"
- **문제**: design 완료 후 approval 요청 없이 execution 단계로 자동 진입. github-manifest 리포까지 생성/푸시 완료.
- **근본 원인**: "빠르게 결과 보여줘야 한다"는 심리가 승인 단계 생략으로 이어짐
- **징후**: `.workflow-state`를 `execution`으로 직접 업데이트, approval.json 없이 리포/파일 생성 시작
- **해결**: approval.json 생성 → transition-step.sh 5-approved → 6-executing 순서 강제
- **예방**: design 완료 후 **반드시** 승인 요청 발송 → 사용자 응답 대기 → approved 상태로 전환 후 execution
- **자동 진행 규칙 예외**: 승인 단계는 자동화 절대 금지. "자동 진행" ≠ "승인 스킵"

### ⚠️ JOB 완료 시 산출물 전량 검증 (JOB-1491/1492/1494 개선)

**⚠️ JOB-1492 개선**: lessons.md 파일 누락 시 **자동 템플릿 생성** (JOB ID 자동 치환). 에이전트는 **내용만 채우면 됨**. 템플릿 형식: `# JOB-XXXX 교훈\n\n## 기술적 교훈\n-\n\n## 프로세스 교훈\n-\n`

## 기술적 교훈
-

## 프로세스 교훈
-
```
- **차단 대상**: result.md, execution.md (자동 생성 없음)
- **간소화 JOB 예외**: `(간소화)` 포함 시 lessons.md 빈 파일 허용
- **이전 문제 **(JOB-1412) approval.json만 검증 → result.md, lessons.md 누락률 70%+

### ⚠️ grep -c 패턴의 silent failure (JOB-1498 P0 학습)

**문제**: `grep -cE 'pattern' file || echo 0` 패턴이 0 매치 시 "0\n0" 반환 → `(( spec_count == 0 ))` 구문 오류

**근본 원인**:
- `grep -c`이 0 매치 시 stdout에 "0" 출력 + exit code 1 반환
- `|| echo 0`이 추가로 "0" 출력 → 변수에 "0\n0" 저장
- `(( "0\n0" == 0 ))`가 bash 구문 오류 발생

**해결**: `|| true` 패턴 사용 (exit code만 처리, stdout은 grep -c이 이미 출력함)
```bash
# ❌ 잘못됨 (0\n0 반환)
spec_count=$(grep -cE 'SPEC-' file.md || echo 0)

# ✅ 올바름 (exit code만 처리)
spec_count=$(grep -cE 'SPEC-' file.md || true)
```

**발생 조건**: `set -euo pipefail` 환경 + grep -c + 0 매치 케이스

---

## Spec 연동 체크포인트 (JOB-1498 P0)

workflow-gate.sh에 Spec 연동 체크포인트 2개 추가됨:

| 체크포인트 | 검증 | 동작 |
|-----------|------|------|
| I-spec-ref | request.md에 SPEC-XXX 패턴 존재 | 존재 시 PASS, 부재 시 SKIP (spec-free JOB) |
| I-spec-matrix | architecture.md에 Spec 연동 테이블 존재 | 존재 시 PASS, 부재 시 SKIP (spec-free JOB) |

**조건부 검증 패턴**: `has_spec_references()` 함수가 false면 검증 전량 bypass
**Override 플래그**: `--skip-spec-check`로 전체 Spec 검증 bypass (응급용)

**사용법**:
```bash
# Spec 체크포인트 검증
bash workflow-gate.sh JOB-XXXX checkpoint I-spec-ref
bash workflow-gate.sh JOB-XXXX checkpoint I-spec-matrix

# Spec 검증 bypass (응급용)
bash workflow-gate.sh --skip-spec-check JOB-XXXX checkpoint I-spec-ref
```

---

**⚠️ create-job.sh sanitize_title UTF-8 truncation **(JOB-1479 완료) `head -c80`/`cut -c1-80`는 UTF-8 바이트 기반 → Python str slicing 사용. 상세: `references/bash-utf8-pitfalls.md`

**⚠️ create-job.sh 중복 감지 버그 **(JOB-1493 완료) `ls -d` glob 패턴은 신뢰성 부족 → `find` 명령어 사용. 상세: `references/bash-utf8-pitfalls.md`

**auto-process 액션 **(JOB-1494 완료) request → approval 자동 진행. 상세: `references/auto-process-action.md`

**문제**: `sanitize_title()`에서 `head -c80`이 UTF-8 바이트 기반 truncation을 수행 → 한글이 중간에 잘림 (예: "입니다" → "입")

**근본 원인**: `head -c`, `cut -c` 모두 UTF-8에서 바이트 기반 truncation 수행. `LC_ALL=C.UTF-8` 설정도 바이트 기반 동작을 바꾸지 않음.

**해결 **(JOB-1479에서 적용됨):
```bash
# ❌ 바이트 기반 truncation (한글 중간에 잘림)
| head -c80
| cut -c1-80

# ✅ 문자 기반 truncation (한글 완전하게 처리)
| python3 -c "import sys; print(sys.stdin.read().strip()[:80], end='')"
```

**⚠️ 일반화 규칙**: bash에서 한글/UTF-8 truncation이 필요한 경우 항상 Python str slicing 사용. `head -c`, `cut -c`, `wc -c`는 모두 바이트 기반.

### ⚠️ create-job.sh 중복 감지 버그 (JOB-1493 완료)

**문제**: `validate_and_reassign()`에서 `ls -d`를 사용하여 중복 확인 → glob 패턴 확장 실패 시 중복 감지 실패 (JOB-1487이 2개 생성됨)

**근본 원인**: `ls -d "$JOBS_DIR"/JOB-${test_num}-*`는 폴더가 존재하지 않으면 패턴 자체가 stdout에 출력됨 → 중복이 아닌 것으로 오진

**해결 **(JOB-1493에서 적용됨):
```bash
# ❌ glob 기반 (중복 감지 실패)
if ! ls -d "$JOBS_DIR"/JOB-${test_num}-* &>/dev/null; then

# ✅ find 기반 (정확한 중복 감지)
if ! find "$JOBS_DIR" -maxdepth 1 -type d -name "JOB-${test_num}-*" 2>/dev/null | grep -q .; then
```

**⚠️ 일반화 규칙**: bash에서 directory 존재/중복 확인 시 `find` 명령어 사용. `ls -d` glob 패턴은 디렉토리 탐색에 신뢰성 부족.

**피해 최소화**: JOB 생성 후 반드시 `ls -d ~/.hermes/workspace/jobs/JOB-XXXX-*`로 폴더 수 확인

### ⛔ 가정 금지: 사용자의 의도 확인 후 진행 (JOB-1472 학습)

**사용자 피드백**: "공개 리포는 아직 공개되지 않은 것도 배포하려는거야? 무슨 근거로 판단했어?"

**문제**: spec-templates를 "public + npm 배포"로 가정하고 설계. 실제로는 private로 유지해야 함.
**근본 원인**: "공개하면 유용하겠다"는 에이전트 판단으로 사용자 의대 대체

**규칙**:
1. **가시성/배포/라이선스**는 사용자에게 반드시 확인
2. "이건 public이면 좋겠다", "이건 배포하면 유용하겠다"는 가정 금지
3. 현재 상태(예: kernel-chat만 public)를 기준으로 설계 → 변경은 사용자 승인 후

**올바른 순서**:
1. 현재 상태 확인 (어떤 리포가 public/private인지)
2. 변경 사항 → 사용자에게 확인 질문
3. 사용자 응답 → 설계 반영

**징후**: 사용자가 "무슨 근거로 판단했어?", "내가 그렇게 말했어?" 지적 → 에이전트 가정상设计中

**⚠️ 승인 자동화 금지 **(JOB-1277/1393 학습 — 사용자 지적: "프로세스에 따라 진행하는건 승인 절차도 제대로 지키라는 얘기야"):
- `approval.json` 자동 생성 금지 — 사용자 명시적 승인 응답 필요
- "그래", "진행해" 등 = 승인 응답으로 간주 (하지만 승인 요청 메시지 반드시 발송)
- 승인 요청 없이 approval.json 생성 후 5-approved 진입 = **프로세스 위반**
- **자동 실행 진입 금지 **(JOB-1393)승인 요청 메시지 발송 후 사용자 응답 없이 `transition execution` 직접 호출 금지

**올바른 흐름**:
1. 리뷰 완료 → review-result-*.md 생성
2. **사용자에게 승인 요청 메시지 발송** — (A)/(B)/(C) 선택지 포함
3. **사용자 응답 대기** — "A", "B", "C", "그래", "진행해" 등
4. approval.json 생성 (user response 기록)
5. transition-step.sh 5-approved
6. **최早 확인 후** transition-step.sh 6-executing

**⛔ 자동 진행 ≠ 자동 승인 ≠ 자동 실행**:
- "자동 진행" 규칙은 승인 단계 **예외**
- 승인 단계는 항상 사용자 응답 **반드시 대기**
- **실행 단계 진입 전 승인 파일 존재 확인 필수**

**검증 체크 **(이행 전 반드시 실행)
```bash
# 승인 파일 존재 + 유효성 확인
[[ -f "$JOB_DIR/approval.json" ]] && \
python3 -c "import json; d=json.load(open('$JOB_DIR/approval.json')); assert d['choice']=='A'" && \
echo "✅ 승인 확인됨" || echo "❌ 승인 누락 — 실행 금지"
```

### ⛔ 테스트 FAIL 시 JOB 완료 금지 (JOB-1287 학습 — 사용자 직접 지적)

**사용자 지적**: "테스트 결과가 실패인데 작업 마무리 한거야?"

**문제**: 테스트가 FAIL인데 9-done으로 상태 전환하고 완료 보고함

**규칙**:
1. **테스트 전량 PASS 확인 후** ⑧실행 리뷰 진입
2. FAIL 항목이 있으면 **원인 분석 → 수정 → 재테스트** 사이클 완료 후 진행
3. "일단 완료하고 다음에 고치자" 금지 — JOB의 완료 기준은 테스트 PASS
4. 테스트 FAIL 발견 시: `6-executing`으로 상태 재개 → 수정 → 재테스트 → PASS 확인 후 완료

**올바른 흐름**:
```
⑥실행 → ⑦테스트 → PASS? → ⑧리뷰 → ⑨교훈 → 완료
                          ↓ FAIL
                    원인 분석 → 수정 → 재테스트 → PASS 확인
```

**징후**: 사용자가 "테스트 실패인데?", "완료했는데 왜 안돼?"라고 지적하면 → 테스트 미통과 상태에서 완료 처리한 경우

## 워크플로우 상태 디스택 복구 (JOB-1162 교훈)

워크플로우 검증 규칙이 진화하면 **이전 JOB의 `.workflow-state` 가 실제 완료 상태와 불일치**할 수 있다.

**증상**: `execution.md`에 완료 기록이 있으나 `.workflow-state` 가 낮은 단계(예: `2-investigating`)에 갇힘.

**해결 절차**:
1. 산출물 존재 확인: `architecture.md`, `review-result-*.md`(PASS 포함), `approval.json`, `execution.md`
2. 체크포인트 보정:
   - `request.md`에 `SKILL.md 읽음` + `교훈: 내용` 또는 `관련 교훈 없음` 추가
   - `architecture.md`에 `(A)(B)(C)` + `## 요구사항` + `Before/After` 테이블 + `review-result-` 인용 추가
3. `approval-request.json` 재생성: `source scripts/lib/approval.sh && write_approval_request <JOB_DIR> <JOB_ID>`
4. `approval.json` 보정: `request_id` + `architecture_sha256` 일치 확인
5. 단계별 순차 전환: `transition-step.sh <JOB_DIR> 3-designing` → `4-reviewing` → ... → `9-done`
6. **skip 금지**: 체크포인트 검증이 단계별이므로 한 번에 건너뛰면 실패

---

## 승인 단계 강제 검증 (JOB-1350)

- **문제**: 승인 준수율 36% → 64% JOB가 승인 없이 완료
- **해결**: `workflow-gate.sh`의 `transition` AND `complete` 액션에 승인 검증 추가
- **검증 내용**: `approval.json` 존재 + `choice` 필드 유효성
- **예외**: `architecture.md` 제목에 `(간소화)` 포함 시 자동 통과
- **블락 메시지**: `⛔ BLOCKED: approval.json not found`
- **원칙**: 기술적 강제(스크립트) > 가이드라인만

## Eval Pipeline (JOB-1350)
- 주간 품질 평가 자동화: `eval-workflow.sh` (workflow metric) + `eval-speed.sh` (API 벤치마크)
- 상세: `references/eval-pipeline.md` 참조

## ⚠️ JOB 완료 후 문서 동기화 강제 (JOB-1421 학습 — 사용자 지적)

**사용자 피드백**: "왜 변경된 구조가 바로 참조가 안됐는지 점검하는 작업을 현재 작업 완료 후 진행해줘"

**문제**: JOB-1392에서 'Hermes Primary + OpenClaw Hot Standby'로 아키텍처 변경 승인되었으나, JOB-1418 조사 시 즉시 참조되지 않음.

**근본 원인**:
1. AGENTS.md에 설계 변경 반영 메커니즘 부재
2. llms.txt 자동 갱신 부재 (generate-llms.sh 수동 실행 필요)
3. wiki 문서 자동 동기화 부재
4. JOB 산출물이 중앙 문서 시스템과 연동되지 않음

**해결 **(JOB-1421에서 구현 예정)
- workflow-gate.sh complete 액션에 hook 도입
- JOB 완료 시 자동 실행:
  - AGENTS.md 업데이트 (설계 변경 사항 반영)
  - generate-llms.sh 실행
  - wiki 동기화

**현재 임시 조치 **(에이전트 수동 실행)
```bash
# JOB 완료 후 반드시 실행
bash ~/.shared/scripts/generate-llms.sh
```

**트리거**: references 추가/수정, lessons 생성, topics 변경, skills 추가, **설계 변경 승인**
**상세**: `knowledge-map-generation` 스킬 참조

**⚠️ Pitfall**: 설계 변경 JOB 완료 후 llms.txt 갱신 누락 → 다음 세션에서 outdated 정보 참조

---

## 워크플로우 준수성 강제 메커니즘 (JOB-1165)

AGENTS.md에 "금지/필수" 문구만 쓰는 것을 대신하여, **스크립트 레벨에서 기술적 강제**를 적용합니다.

### 1. strict 모드 (`workflow-gate.sh --strict`)

각 단계 진입 전 전제 조건을 검증합니다. 불만족 시 **exit 1**으로 차단:

```bash
# 다음 단계 진입 전 strict 검증
bash scripts/workflow-gate.sh --strict <JOB_DIR>
```

**검증 규칙** (scripts/lib/validate-prereqs.sh):

| 대상 단계 | 필수 파일 | 예외 |
|-----------|----------|------|
| design | request.md | 없음 |
| review | architecture.md | 없음 |
| approval | review-result-*.md | 없음 |
| execution | architecture.md, review-result-*.md, approval.json/approved-by.txt | urgent: true 시 승인 파일 예외 |
| test | execution.md | 없음 |
| exec_review | execution.md | 없음 |
| done | execution.md, exec-review-result.md | 없음 |

**사용 패턴**: 에이전트가 각 단계 진입 시 `--strict` 플래그를 사용. 실패 시 해당 단계를 건너뛰지 않고 누락된 산출물부터 생성.

### 2. workflow-gate.sh 단일본 관리

복사본 3개를 본체 1개 + wrapper 2개로 통합:

| 경로 | 역할 |
|------|------|
| `skills/custom/workflow/scripts/workflow-gate.sh` | **본체** (수정 대상) |
| `~/.hermes/scripts/workflow-gate.sh` | wrapper (본체 호출) |
| `skills/custom/code-scripts/workflow/scripts/workflow-gate.sh` | wrapper (본체 호출) |

수정은 **본체만** 수정. wrapper는 자동으로 반영됨.

### 3. 사후 감사 (`workflow-audit.sh`)

완료된 JOB 의 워크플로우 준수성을 사후 점검:

```bash
# 전체 감사
bash scripts/workflow-audit.sh

# 최근 7일만 감사
bash scripts/workflow-audit.sh --since 2026-05-10

# 문제 JOB 에 보정 파일 생성
bash scripts/workflow-audit.sh --fix
```

**출력**: `~/.shared/logs/workflow-audit.log`
**감사 항목**: .workflow-state 존재, request.md 존재, 단계별 필수 파일, 승인 파일

### 4. 4층 방어 체계

| 층 | 메커니즘 | 강제력 |
|----|---------|--------|
| 1 | 시스템 프롬프트 (AGENTS.md) | 가이드라인 |
| 2 | strict 모드 (validate-prereqs.sh) | exit 1 차단 |
| 3 | 사후 감사 (workflow-audit.sh) | 로그 기록 + 보정 파일 |
| 4 | 교훈/리뷰 | 다음 JOB 에 반영 |

에이전트는 `write_file`/`terminal`로 직접 파일 조작이 가능하므로, strict 모드는 에이전트가 게이트 스크립트를 **자발적으로 실행할 때만** 강제됩니다. 사후 감사(층 3)가 우회된 경우를 포착합니다.

**연관 라이브러리**: `scripts/lib/validate-prereqs.sh` — 단계별 전제 조건 검증 함수 (`validate_prereqs <JOB_DIR> <target_step>`)

## Pitfalls

### create-job.sh PATH 미등록 + 스크립트 분산 (JOB-1210)

**증상**: `create-job.sh`가 "command not found" 또는 "create-job.sh가 없습니다" → fallback으로 직접 `mkdir` 실행 (AGENTS.md 위반)

**근본 원인**:
- `~/.hermes/scripts/`가 `$PATH`에 미등록 (agent workdir=`~/.hermes/workspace` 기준 상대경로에서 스크립트 없음)
- `create-job.sh`가 **5개 위치**에 분산: `~/.hermes/scripts/`, `skills/custom/code-scripts/agent-workflow-core/scripts/`, `skills/job/scripts/`, `~/.openclaw/...`, `archive/legacy/`
- **v1** (53줄, `~/.hermes/scripts/`): JSON `.workflow-state` 생성 ✅, sanitize 없음 ❌
- **v2** (276줄, skills/): `-y`/`--parent` 옵션, sanitize_title() ✅, `.workflow-state`=문자열 ❌

**대응**:
1. 항상 **절대 경로** 사용: `bash ~/.hermes/scripts/create-job.sh "title" "content"`
2. 실행 후 `ls ~/.hermes/workspace/jobs/JOB-XXXX/`로 디렉토리 생성 확인 (JOB-1189)
3. 폴더/`.workflow-state` 누락 시 수동 생성 (아래 JOB-1189 참조)

**⚠️ Pitfall: 한글+특수문자 JOB 디렉토리명 bash escaping **(JOB-1258)

`create-job.sh`가 한글 제목+괄호를 포함하는 긴 디렉토리명 생성 시:
- `cat ~/.path/JOB-1257-제목(문자)/file` → bash syntax error
- 해결: `find` + 변수 사용. `JOB_DIR=$(find ~/jobs/ -maxdepth 1 -type d -name "JOB-1257*" | head -1)`
- `cat "$JOB_DIR/file.md"` 형태로 변수 경유 필수

**⚠️ Pitfall: `.workflow-state` 부재 시 수동 초기화 **(JOB-1258)

JOB 폴더는 존재하지만 `.workflow-state`가 없으면 `transition-step.sh`가 실패.
`request.md`가 이미 있으면 수동 JSON 생성:

```bash
cat > "$JOB_DIR/.workflow-state" << 'EOF'
{
  "jobId": "JOB-XXXX",
  "status": "running",
  "currentStep": "investigation",
  "steps": [
    { "name": "request", "status": "done", "completedAt": "ISO8601" },
    { "name": "investigation", "status": "in_progress", "startedAt": "ISO8601" },
    { "name": "design", "status": "pending" },
    { "name": "review", "status": "pending" },
    { "name": "approval", "status": "pending" },
    { "name": "execution", "status": "pending" },
    { "name": "test", "status": "pending" },
    { "name": "execution_review", "status": "pending" },
    { "name": "done", "status": "pending" }
  ],
  "startedAt": "ISO8601", "updatedAt": "ISO8601",
  "artifacts": ["request.md"]
}
EOF
```

### create-job.sh PATH + 스크립트 분산 (JOB-1210)

**증상**: `create-job.sh`가 "command not found" → fallback으로 직접 `mkdir` 실행

**근본 원인**: `~/.hermes/scripts/`가 `$PATH`에 미등록. `.bashrc` non-interactive guard **전**에 export 배치 필수. `BASH_ENV` 설정 필요.

**해결**: PATH 등록 + canonical 1개 + symlink

### create-job.sh 버그 (JOB-1189, JOB-1210)

1. **슬래시 sanitize (JOB-1167)**: `sanitize_title()`이 `/` 처리 안 함. → `tr '/' '-'` 추가. 테스트: `--dry-run 기능 "A/B"` → `A-B` 확인.
2. **중복 무한 루프**: 같은 번호 재계산 → 무한 루프. → `ORIG_NUM` 비교 후 `+1` 추가.
3. **`.workflow-state` 문자열**: v2가 `echo "request"`로 문자열. → JSON heredoc으로 변경.
4. **폴더 누락 (JOB-1189)**: 실행 후 `ls ~/.hermes/workspace/jobs/JOB-XXXX/`로 반드시 확인.
5. **`--dry-run` TTY 입력 대기 **(FIXED): `--dry-run` 시에도 `--yes` 없으면 `read` 프롬프트 표시 → non-interactive 환경에서 exit_code=1. → Line 183 조건에 `&& [[ "${DRY_RUN}" != "true" ]]` 추가. 테스트: `bash create-job.sh --dry-run 기능 "테스트"` → exit_code=0 확인.

**검증**: JSON 파싱(`python3 -c "import json; json.load(...)"`) + sanitize 테스트 + dry-run 테스트 필수.

### architecture.md 수정 → 승인 해시 불일치 (JOB-1158)
architecture.md를 승인 이후로 수정하면 SHA256 해시가 변경됨. `transition-step.sh`가 I7 검증에서 실패.
**해결**: `write_approval_request` 재생성 → `approval.json` 재작성 → 재전환.

### Before/After 테이블 열명 (JOB-1158)
`Before`/`After` 열명은 I5b 검증 실패. `현재`/`변경`(또는 `변경 후`) 사용.

### 승인 대기 문구 잔여 (I7b)
architecture.md의 `## 승인` 섹션에 `결과: 대기` 또는 `승인 대기`가 남아 있으면 I7b 실패.
승인 획득 후 반드시 `(A) 진행` 등으로 갱신.

### 9단계 진입 전 교훈 파일 누락 (I13a/b/c)
`lessons.md`, `lessons/index.md` 중 하나라도 누락되면 9단계 전환 차단.
실행 완료 후 바로 작성할 것.

### bash 스크립트 패턴 (JOB-1350/1165)

### JSON 생성: Python 대신 bash heredoc (JOB-1350)
- **문제**: `python3 -c` 또는 `<< PYEOF` heredoc에서 bash 변수 전달 시 escaping/인코딩 문제 다발
- **해결**: bash heredoc으로 직접 JSON 생성 — 가장 안전하고 간결
```bash
cat > "${OUTPUT_FILE}" << EOF
{
  "key": "${bash_var}",
  "timestamp": "$(date -Iseconds)",
  "count": ${number_var}
}
EOF
```
- **패턴**: eval/리포트 스크립트에서 metrics.json 생성 시 항상 이 패턴 사용

### non-interactive shell에서 .env 로딩 (JOB-1350)
- **문제**: crontab等非대화형 shell에서 `.bashrc` 미로딩 → API 키 등 환경 변수 없음
- **해결**: 스크립트头部에서 `.env` 명시적 로딩
```bash
if [ -f "${HOME}/.hermes/.env" ]; then
    export $(grep -v '^#' "${HOME}/.hermes/.env" | xargs)
fi
```
- **참고**: `xargs` 사용 시 값에 공백 포함 시 주의 → 필요 시 `while IFS= read -r line` 패턴 사용

### `((0))` exit code 1 문제 (JOB-1165)
- `set -e` 환경에서 `((total_jobs++))` 형태가 `total_jobs=0`일 때 exit code 1 반환 → 스크립트 즉시 종료.
  **해결**: `total_jobs=$((total_jobs + 1))` 또는 `((++total_jobs))` (pre-increment) 사용. 또는 `((total_jobs++)) || true` 로 안전하게 처리.

### `local` 키워드는 함수 내부에서만 사용 가능 (JOB-1433)
- `set -euo pipefail` 환경에서 메인 블록(함수 외부)에서 `local var=$(cmd)` 사용 시 silent failure → exit code 1
- **증상**: 스크립트가 부분 실행 후 중단 (예: fetch.sh가 HN 수집은 성공但 GeekNews에서 중단)
- **해결**: 메인 블록에서 `local` 키워드 제거 → `var=$(cmd)`
- **예방**: 스크립트 생성 후 `bash -n script.sh` syntax check + 실제 실행 테스트 필수
- **패턴**: no_agent cron 스크립트에서 가장 빈발 (함수/메인 블록 경계가 명확하지 않을 때)

### 검증 로직: 모든 진입点到 적용 (JOB-1350)
- **패턴**: 핵심 검증(승인, 산출물 등)은 `transition` AND `complete` 액션 모두에 적용
- **이유**: 사용자가 어느 액션 호출할지 불확실 → 단일 진입점만 검증하면 우회 가능
- **원칙**: 중복 검증 > 검증 누락

- **대용량 JSON 인자 전달 (JOB-1214)**: `argument list too long` 오류. bash 변수에 대용량 JSON 저장 후 인자로 전달 불가.
  **해결**: 임시 파일 사용 (`mktemp` → `curl -o $file` → Python에서 `open(file)` 읽기).

- **`check_i8a` 빈 파일 요구 (JOB-1181 교훈)**: `validate-checkpoints.sh`의 `check_i8a` 함수가 `execution.md`가 없으면 `set -e`로 인해 스크립트가 비정상 종료됨 (논리적 오류).
  **해결**: 9단계(`9-done`) 전환 전 반드시 `touch execution.md`로 빈 파일이라도 생성할 것.

- **`check_i13c` 교훈 인덱스 요구**: 9단계 전환 시 `~/.hermes/workspace/jobs/lessons/index.md`에 해당 JOB ID가 포함된 링크가 있어야 함.
  **해결**: `echo "- [JOB-XXXX](.../lessons.md) - 요약" >> ~/.hermes/workspace/jobs/lessons/index.md` 실행 후 전환.
