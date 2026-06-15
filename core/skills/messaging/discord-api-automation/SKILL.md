---
name: discord-api-automation
description: "Discord Bot API 직접 호출을 통한 고급 자동화 - 쓰레드 생성, 메시지 관리, 채널 조작. send_message 도구로 불가능한 작업 처리."
version: 1.0.0
created: 2026-05-28
---

# Discord API 자동화

> **사용 시점**: `send_message` 도구로 불가능한 Discord 작업 필요 시
> **토큰 위치**: 환경변수 `DISCORD_BOT_TOKEN`

---

## 쓰레드 생성 (Thread Creation)

`send_message`는 연결된 쓰레드에만 전송 가능. 새 쓰레드 생성은 Discord API 직접 호출 필요.

### 일반 텍스트 채널 (type 0)에서 쓰레드 생성

```bash
curl -s -X POST "https://discord.com/api/v10/channels/{CHANNEL_ID}/threads" \
  -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "쓰레드 이름",
    "auto_archive_duration": 1440,
    "type": 11,
    "message": {
      "content": "초기 메시지"
    }
  }'
```

**반환값**: JSON 응답에서 `id` 필드가 쓰레드 ID

### 포럼 채널 (type 15)에서 쓰레드 생성

```bash
curl -s -X POST "https://discord.com/api/v10/channels/{CHANNEL_ID}/threads" \
  -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "포럼 쓰레드 이름",
    "auto_archive_duration": 1440,
    "type": 15,
    "message": {
      "content": "초기 메시지"
    }
  }'
```

### 채널 타입 확인

```bash
curl -s "https://discord.com/api/v10/channels/{CHANNEL_ID}" \
  -H "Authorization: Bot $DISCORD_BOT_TOKEN" | python3 -m json.tool
```

**type 필드**:
| 값 | 타입 |
|----|------|
| 0 | 일반 텍스트 채널 (GC_TEXT) |
| 15 | 포럼 채널 (FORUM) |

### 쓰레드 타입

| 값 | 사용 채널 | 설명 |
|----|----------|------|
| 11 | 텍스트 채널 | Public Thread |
| 15 | 포럼 채널 | Forum Thread |

---

## 쓰레드에 메시지 전송

```bash
# 쓰레드에 메시지 전송 (일반 채널과 동일)
curl -s -X POST "https://discord.com/api/v10/channels/{THREAD_ID}/messages" \
  -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content": "메시지 내용"}'
```

---

## 소설 연재 자동화 (예시)

화 단위로 쓰레드 생성 + 본문 전송:

```bash
# 1. 쓰레드 생성
THREAD_ID=$(curl -s -X POST "https://discord.com/api/v10/channels/{CHANNEL_ID}/threads" \
  -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"소설 제목 - {N}화\",
    \"auto_archive_duration\": 1440,
    \"type\": 11,
    \"message\": {\"content\": \"${N}화 시작\"
  }" | jq -r '.id')

# 2. 본문 전송 (파일 내용 읽어서)
CONTENT=$(cat ~/path/to/episode.md)
curl -s -X POST "https://discord.com/api/v10/channels/$THREAD_ID/messages" \
  -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"content\": \"$CONTENT\"}"
```

### ⚠️ 파일 첨부 제한 (JOB-1461 확인)

**문제**: `MEDIA:/path/to/file.js` 형식으로 소스 코드 파일(.js, .py, .ts 등)을 Discord에 첨부할 때, API는 성공 응답을 반환하지만 실제 파일이 Discord에 첨부되지 않음.

**확인된 동작** (JOB-1461 기준):
- ✅ 코드 블록 (` ```javascript ... ``` `) — 정상 표시
- ❌ `MEDIA:/path/to/file.js` — API 성공하지만 파일 미첨부
- ❌ `send_message` + `MEDIA:` — 동일하게 파일 미첨부

**원인**: Discord Bot API의 파일 첨부가 Hermes gateway에서 텍스트 메시지용으로만 구현됨. 미디어 파일(이미지/오디오/비디오)은 별도 처리 경로 사용.

**우회 방법** (순서대로 시도):
1. **코드 블록으로 전송** (권장) — 소스 코드는 ``` 형식으로 직접 메시지 포함
2. **GitHub Gist** — 코드를 Gist에 업로드 후 링크 전송
3. **paste.gg / hastebin** — 임시 코드 호스팅 서비스 사용

**사용자 요청 패턴**:
- "파일로 전달해줘" → 코드 블록으로 전송 (Discord에서는 파일 첨부 불가)
- "첨부해줘" → 동일하게 코드 블록
- 이미지가 아닌 코드 파일 요청 시 항상 코드 블록 사용

### 파일 형식별 권장 전송 방법

| 파일 형식 | 권장 방법 | 비고 |
|-----------|-----------|------|
| .js, .py, .ts, .md | 코드 블록 | ``` 형식 |
| .png, .jpg, .webp | MEDIA: | 이미지 첨부 |
| .json, .yaml | 코드 블록 | ``` 형식 |
| .pdf | GitHub Gist | 문서 호스팅 |

### 관련

- `send_message` 도구: 기본 메시지 전송 (연결된 채널/쓰레드만)
- `references/thread-types.md`: Discord 쓰레드 타입 상세

---

## Discord 플랫폼 특이사항 (§Platform Quirks)

### ⚠️ 파일 첨부 제한 (JOB-1461 확인)

**문제**: `MEDIA:/path/to/file.js` 형식으로 소스 코드 파일(.js, .py, .ts 등)을 Discord에 첨부할 때, API는 성공 응답을 반환하지만 실제 파일이 Discord에 첨부되지 않음.

**확인된 동작** (JOB-1461 기준):
- ✅ 코드 블록 (` ```javascript ... ``` `) — 정상 표시
- ❌ `MEDIA:/path/to/file.js` — API 성공하지만 파일 미첨부

**우회 방법** (순서대로 시도):
1. **코드 블록으로 전송** (권장) — 소스 코드는 ``` 형식으로 직접 메시지 포함
2. **GitHub Gist** — 코드를 Gist에 업로드 후 링크 전송

**사용자 요청 패턴**:
- "파일로 전달해줘" → 코드 블록으로 전송 (Discord에서는 파일 첨부 불가)

### 메시지 전송 제한

- **메시지 길이**: 최대 2000자/메시지 (초과 시 분할 전송 필요)
- **Rate limiting**: 분당 요청 제한 (기본 50회/분)

### 파일 형식별 권장 전송 방법

| 파일 형식 | 권장 방법 | 비고 |
|-----------|-----------|------|
| .js, .py, .ts, .md | 코드 블록 | ``` 형식 |
| .png, .jpg, .webp | MEDIA: | 이미지 첨부 |
| .json, .yaml | 코드 블록 | ``` 형식 |
| .pdf | GitHub Gist | 문서 호스팅 |