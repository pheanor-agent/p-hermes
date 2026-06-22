# 💬 채팅 기본 사용법

> Hermes 채팅 인터페이스의 기본 사용법과 슬래시 명령어를 소개합니다.
> Hermes는 Discord, Telegram, CLI 등 다양한 플랫폼에서 사용할 수 있습니다.

---

## 슬래시 명령어

슬래시(`/`)로 시작하는 명령어는 Hermes의 동작을 직접 제어합니다.

### 기본 명령어

| 명령어 | 설명 | 사용 예 |
|--------|------|---------|
| `/model` | 현재 모델 확인/변경 | `/model` 또는 `/model gpt-4` |
| `/reset` | 세션 컨텍스트 초기화 | `/reset` |
| `/new` | 새 세션 시작 | `/new` |
| `/skills` | 스킬 목록 보기 | `/skills` |
| `/sessions` | 최근 세션 목록 | `/sessions` |
| `/help` | 도움말 | `/help` |

### 명령어 예제

```
/model
→ 현재 모델: deepseek-v4-flash (custom)

/model gpt-4
→ 모델 변경: deepseek-v4-flash → gpt-4
```

---

## 세션 관리

### 세션 시작

자연어로 대화를 시작하면 자동으로 세션이 생성됩니다:

```
안녕, 새 프로젝트를 시작하려고 해
→ 새 세션 생성 (session_xxxx)
```

`/new` 명령어로 명시적으로 새 세션을 시작할 수 있습니다:

```
/new
→ 새 세션이 시작되었습니다
```

### 세션 전환

```
/sessions
→ 최근 5개 세션 표시

/sessions open session_abc123
→ session_abc123 세션으로 전환
```

### 세션 초기화

대화 컨텍스트를 초기화하고 싶을 때:

```
/reset
→ 컨텍스트가 초기화되었습니다.
  Knowledge와 Memory는 유지됩니다.
```

---

## 스킬 관련 명령어

```
# 모든 스킬 보기
/skills

# 특정 스킬 로드
/skills load deployment-prep

# 스킬 검색
/skills search "배포"
```

---

## Knowledge 관련 명령어

```
# Knowledge 저장
knowledge add "내용" --tags 태그

# Knowledge 검색
knowledge search "키워드"

# Knowledge 계층별 검색
knowledge search "API" --tier T1
```

---

## 플랫폼별 특이사항

### Discord
- 봇을 서버에 초대하여 사용
- 쓰레드에서 작업 관리
- `@Hermes` 멘션으로 호출

### Telegram
- 개인 채팅 또는 그룹에 봇 추가
- 인라인 모드 지원
- 파일 첨부 지원

### CLI
- 가장 빠른 인터페이스
- 파이프라인과 스크립트에 적합
- 에디터 통합 가능

---

## Tips & Tricks

### Tip 1: 명확하게 요청하라
```diff
- ❌ "코드 좀 봐줘"
+ ✅ "로그인 모듈의 보안 취약점을 분석해줘 JOB으로 만들어서"
```

### Tip 2: JOB을 활용하라
간단한 요청도 JOB으로 만들면 추적과 재현이 가능합니다:
```
JOB으로 만들어줘: README 업데이트
```

### Tip 3: /reset은 마지막 수단
Knowledge와 Memory는 유지되지만, 현재 진행 중인 작업 맥락은 모두 사라집니다. `/reset`은 정말 필요할 때만 사용하세요.

> **💡 Tip**: 슬래시 명령어는 Hermes 제어의 기본입니다. `/model`로 모델을, `/skills`로 스킬을, `/sessions`로 세션을 관리하세요.
>
> **🔗 더 알아보기**: [세션 관리](session-management.md) — 세션 관리 심화
