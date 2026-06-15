# JOB-1218: Message Flow Verification Patterns

## Context
JOB-1218 designed a persona enforcement system for Telegram group chat. Initial design had critical assumptions about message flow that were proven wrong through codebase verification.

## Platform Adapter Separation

### Telegram Messages
```
Telegram Bot API
  → TelegramAdapter._handle_text_message()
    → _build_message_event()  # user_id = actual Telegram ID
    → Gateway Runner
    (Bridge NOT involved)
```

### Bridge Messages
```
OpenClaw
  → POST /hermes
    → BridgeAdapter._handle_hermes_message()
      → SessionSource(user_id="openclaw", chat_id="bridge")
      → Gateway Runner
    (Telegram Adapter NOT involved)
```

**Key Finding:** Platforms are completely separate. Bridge's `user_id="openclaw"` hardcoding does NOT affect Telegram messages.

## Verification Commands

### 1. List all platform adapters
```bash
ls gateway/platforms/
# Shows: telegram.py, bridge.py, discord.py, slack.py, etc.
```

### 2. Trace message flow in specific adapter
```bash
grep -n "_handle_text_message\|_build_message_event\|user_id=" gateway/platforms/telegram.py
```

### 3. Find hook insertion points
```bash
grep -n "invoke_hook\|pre_gateway_dispatch\|post_send" gateway/run.py gateway/platforms/base.py
```

### 4. Check for bypass routes
```bash
# Find all places that call adapter.send() directly
grep -rn "adapter\.send()\|self\.send(" gateway/ --include="*.py"

# Find all places that bypass _send_with_retry()
grep -rn "_send_with_retry\|adapter.send" gateway/platforms/base.py
```

## Existing Functionality Discovery

### Telegram Adapter Already Had:
- `require_mention` config → skip messages without @mention
- `mention_patterns` → custom regex patterns for triggers
- `free_response_chats` → chats where bot always responds
- `_is_reply_to_bot()` → check if message replies to bot
- `_message_mentions_bot()` → Telegram server-side @mention detection

### Design Initially Added (Unnecessary):
- `busy_pre_dispatch` hook (new)
- Mention pattern matching (duplicate)
- Conversation turn tracking (over-engineered)
- Intrusion detection (over-engineered)

### After Verification:
- Removed all unnecessary features
- Kept only: system prompt injection + outgoing validation hook
- **Result:** 45% less code (55 lines → 30 lines)

## Bypass Routes Discovered

| Bypass Route | Impact | Fix |
|-------------|--------|-----|
| `_handle_active_session_busy_message()` | Skipped `pre_gateway_dispatch` hook | Added `busy_pre_dispatch` hook |
| `GatewayStreamConsumer` direct `adapter.send()` | Skipped `_send_with_retry()` | Added `stream_chunk` hook in `on_delta()` |
| `_run_background_task()` | Didn't receive `ephemeral_system_prompt` | Added parameter passing |

## Lessons Learned

1. **Never assume message flows** - Always trace actual code paths
2. **Search for existing functionality** - Avoid duplicate implementation
3. **Validate hook insertion points** - Verify line numbers and bypass routes
4. **Delegate verification** - Use subagents for codebase cross-validation

## Template: Design Verification Checklist

```markdown
## Design Verification

### Message Flow Verification
- [ ] Actual adapter files identified
- [ ] Message flow traced through code
- [ ] Platform separation confirmed
- [ ] user_id/source assignment verified

### Existing Functionality Check
- [ ] Searched for existing filters/hooks
- [ ] Compared new features vs existing
- [ ] Removed duplicates

### Hook Insertion Validation
- [ ] Insertion points exist at specified lines
- [ ] All message paths covered (no bypass)
- [ ] Background tasks included
- [ ] Streaming/non-streaming both covered
```

---
*Reference: JOB-1218 design process, 2026-05-20*
