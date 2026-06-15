# Telegram Group Trigger Debugging

When the bot responds to messages it shouldn't (e.g., "안녕" without being called), or misses messages it should respond to.

## Root Cause Checklist

| Symptom | Likely Cause | Config Key |
|---------|--------------|------------|
| Responds to ALL messages | `require_mention: false` | `telegram.require_mention` |
| Responds to nothing | `allowed_chats` mismatch / guest_mode issues | `telegram.allowed_chats` |
| Responds to wrong name | `mention_patterns` not set or wrong regex | `telegram.mention_patterns` |
| Responds in DM but not group | `_should_process_message()` returns False | Multiple (see below) |

## Critical Config Keys

```yaml
telegram:
  require_mention: true        # MUST be true for group filtering
  mention_patterns:            # Regex wake words
    - 에르메스
    - Hermes
    - '@Hermes260513Bot'
  allowed_chats: ''            # Whitelist (leave empty for all chats)
  free_response_chats: ''      # Bypass require_mention
  guest_mode: false            # Allow explicit @mentions to bypass allowed_chats
```

## How `_should_process_message()` Works

```
message arrives
  ↓
_is_group_chat? → No → return True (DM, unrestricted)
  ↓ Yes
_allowed_chats set? → Yes → chat_id in whitelist? → No → return False
  ↓
guest_mention bypass? → Yes → return True
  ↓
free_response_chats? → Yes → return True
  ↓
require_mention? → No → return True (ALL messages processed!)
  ↓
_is_reply_to_bot? → Yes → return True
  ↓
_message_mentions_bot? → Yes → return True
  ↓
_message_matches_mention_patterns? → Yes → return True
  ↓
return False (message ignored)
```

**Key insight:** `require_mention: false` short-circuits ALL mention checks. The message is passed to LLM regardless of content. System prompt rules cannot compensate — the damage is done before the model sees the message.

## Debugging Steps

1. **Check config:**
   ```bash
   grep -A 5 "mention_patterns" ~/.hermes/config.yaml
   grep "require_mention" ~/.hermes/config.yaml
   ```

2. **Verify gateway loaded patterns:**
   ```bash
   grep "mention pattern" ~/.hermes/logs/gateway.log | tail -5
   ```
   Expected: `[Telegram] Loaded 3 Telegram mention pattern(s)`

3. **Check actual message flow:**
   ```python
   import sqlite3
   conn = sqlite3.connect('/home/bot/.hermes/logs/gateway_messages.db')
   cur = conn.cursor()
   cur.execute("""
     SELECT direction, content FROM messages 
     WHERE chat_id='-3938942705' 
     ORDER BY timestamp DESC LIMIT 10
   """)
   for row in cur.fetchall():
     print(row)
   conn.close()
   ```

4. **Test after fix:**
   - Send "안녕" → Should be silent
   - Send "에르메스 안녕" → Should respond
   - Check gateway.log for `_should_process_message` decisions

## Common Pitfalls

- **System prompt only fix doesn't work:** If `require_mention: false`, the message reaches LLM before any filtering. System prompt rules are "soft" — the model can still respond politely.
- **Supergroup ID mismatch:** `-3975653825` vs `-1003938942705`. See `hermes-agent` skill → Telegram group not responding section.
- **⚠️ `group_persona` is NOT an official Hermes API**: It may appear in config.yaml but is NOT processed by the Hermes gateway. It will NOT enforce group-specific rules. The gateway code does not reference `group_persona` anywhere. For Telegram group-specific behavior, use:
  - `require_mention: true` + `mention_patterns` for strict mention filtering
  - `free_response_chats` for chats that should bypass mention requirements
  - System prompt engineering (but note: this is "soft" filtering - the model may still respond)
- **⚠️ `channel_prompts` is Discord-only**: This official API does NOT work for Telegram. It only applies to Discord channels.
- **group_persona chat_id mismatch (if used):** If you have `group_persona.groups` in config.yaml, it must use `-100` prefixed supergroup ID. However, note this is NOT an official feature and may not work as expected.
- **Mention patterns are regex:** Special chars need escaping. Use `re.escape()` for literal strings.
- **Gateway restart required:** Config changes don't apply until gateway restarts. Use `/restart` in gateway or `systemctl --user restart hermes-gateway`.
- **Hook handler structure:** `~/.hermes/hooks/*/handler.py` MUST have a top-level `handle(event_name, **kwargs)` function. Event-specific functions (`pre_gateway_dispatch`, `post_send`) alone are NOT called — the hook loader (`gateway/hooks.py` Line 124) looks for `handle` function specifically.

## Follow-up Conversation Behavior

When `require_mention: true`:
- First message must match `mention_patterns` or `@mention`
- **Follow-up messages in active session:** Processed regardless of mention (session context maintained)
- **Session timeout:** After timeout, next message must match mention patterns again
- Controlled by `group_sessions_per_user: true` (default) in config.yaml

## Gateway Hook System

Hooks in `~/.hermes/hooks/` are loaded by `gateway/hooks.py::discover_and_load()`:

```python
# Line 124: Looks for 'handle' function
handle_fn = getattr(module, "handle", None)
if handle_fn is None:
    print(f"[hooks] Skipping {hook_name}: no 'handle' function found", flush=True)
    continue
```

**Required handler.py structure:**
```python
def handle(event_name: str, **kwargs):
    """Route events to appropriate handlers."""
    if event_name == "pre_gateway_dispatch":
        return pre_gateway_dispatch(**kwargs)
    elif event_name == "post_send":
        return post_send(**kwargs)
    # ... other events
    return None

# Event-specific handlers
def pre_gateway_dispatch(event, gateway, session_store):
    # ...

def post_send(chat_id, content, chat_type, metadata, session_key):
    # ...
```

**Debug hook loading:**
```bash
grep "hooks.*Loaded\|hooks.*Skipping" ~/.hermes/logs/gateway.log | tail -10
```

**Common hook issues:**
- DB exists but empty → `handle` function missing (hook never called)
- `HOOK.yaml` events not firing → Check `plugins.enabled` in config.yaml
- Hook errors silent → Check `~/.hermes/logs/errors.log`

## Code References

- `_should_process_message()`: `gateway/platforms/telegram.py` Line 3921
- `_message_matches_mention_patterns()`: Line 3895
- `_compile_mention_patterns()`: Line 3790
- Config loading: `telegram.py` Line 384
