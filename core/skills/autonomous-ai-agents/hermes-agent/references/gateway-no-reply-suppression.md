# Gateway NO_REPLY Internal Signal Suppression

## Problem (JOB-1223)

The agent's `NO_REPLY` internal signal was being delivered as plain text to users in Telegram/Discord groups instead of suppressing the response entirely.

**Symptom**: User asked a question the bot shouldn't respond to; bot replied "NO_REPLY" as visible text.

## Root Cause

`NO_REPLY` is an internal signal instructing the gateway to not send any response. Only the Feishu Comment platform (`feishu_comment.py:1357`) had suppression logic:

```python
# feishu_comment.py
_NO_REPLY_SENTINEL = "NO_REPLY"
if not response or _NO_REPLY_SENTINEL in response:
    logger.info("[Feishu-Comment] Agent returned NO_REPLY, skipping delivery")
    # delivery skipped
```

All other platforms (Telegram, Discord, Slack, etc.) route through `BasePlatformAdapter._process_message_background()` in `gateway/platforms/base.py`, which had **no** NO_REPLY check — it treated the sentinel as normal response text.

## Data Flow

```
telegram.py → handle_message() → _message_handler(event)
  → run.py:_handle_message(5651)
    → run.py:_handle_message_with_agent(6968)
      → agent run → final_response (run.py:7594)
      → return response (run.py:7916)
  → base.py:_process_message_background(3016)
    → response check (line 3096) — NO_REPLY NOT checked here ❌
    → _send_with_retry (line 3178) — NO_REPLY sent as text ❌
```

## Fix

Add NO_REPLY suppression in `base.py:_process_message_background()`, line 3096, so all platforms inherit the behavior:

```python
# base.py, after line 3075 (EphemeralReply unwrap)
_NO_REPLY_SENTINEL = "NO_REPLY"
if response and _NO_REPLY_SENTINEL in response:
    logger.info("[%s] Agent returned NO_REPLY, suppressing for %s",
                self.name, event.source.chat_id)
    response = None
```

This uses the same `in` check pattern as Feishu (substring match, not exact), handling cases where the agent appends extra text around the sentinel.

## Streaming Edge Case

When streaming is enabled (`already_sent=True`), the response body is delivered incrementally via `stream_consumer.py`. If the streamed content is `NO_REPLY`, it's already sent to the user before the suppression check. For a complete fix, streaming should also check for the sentinel before initiating the stream.

Location: `run.py` streaming dispatch site — the response is sent inline before `_handle_message_with_agent` returns.

## Files Involved

| File | Line | Role |
|------|------|------|
| `gateway/platforms/base.py` | ~3096 | `_process_message_background()` — response check (fix target) |
| `gateway/platforms/feishu_comment.py` | 1357 | Existing NO_REPLY suppression (reference) |
| `gateway/run.py` | 7594 | `final_response` extraction from agent |
| `gateway/run.py` | 7916 | Response return to caller |
| `gateway/run.py` | ~6688 | `_final_text` extraction (streaming path) |
