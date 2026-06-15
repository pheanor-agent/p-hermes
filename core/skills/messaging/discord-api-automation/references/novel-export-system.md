# Novel Export System - Discord Integration

> **Created**: 2026-05-28 (JOB-1378)
> **Purpose**: Automated novel publishing to Discord #novel channel

## System Architecture

```
Novel episodes/ep{N}.md
    ↓
novel-export.py {slug} [all|chapter-N|episode-N]
    ↓
1. Read project.yaml (title, version)
2. Group episodes by chapter (5 episodes/chapter)
3. Create chapter-level thread in #novel (ID: 1505074053097066597)
4. Send episode messages (split at 2000 chars)
```

## Key Components

### Entry Point
- **Script**: `~/.hermes/workspace/novels/scripts/novel-export.py`
- **Wrapper**: `~/.hermes/workspace/novels/scripts/novel-export.sh`
- **Documentation**: `~/.hermes/workspace/novels/scripts/README.md`

### Discord Configuration
- **Channel**: #novel (`1505074053097066597`)
- **Token**: `env.DISCORD_BOT_TOKEN`
- **Thread Type**: 11 (Public Thread for text channels)

## Message Splitting Algorithm

**Discord Limit**: 2000 characters per message
**Safety Margin**: 100 characters (split at 1900)

### Algorithm
1. If content ≤ 1900 chars → send as-is
2. Find scene boundary (`\n\n`) near 1900 chars
3. If no boundary found before 950 chars → force split at 1900
4. Include trailing newlines to maintain formatting

### Python Implementation
```python
def split_message(text: str, max_length: int = 1900) -> List[str]:
    if len(text) <= max_length:
        return [text]

    messages = []
    remaining = text

    while len(remaining) > max_length:
        # Try to split at scene boundary (double newline)
        split_point = remaining.rfind("\n\n", 0, max_length)

        # If no scene boundary found or too early, force split
        if split_point == -1 or split_point < max_length * 0.5:
            split_point = max_length

        # Extend to include trailing newlines
        while split_point < len(remaining) and remaining[split_point] not in "\n":
            split_point += 1

        messages.append(remaining[:split_point].strip())
        remaining = remaining[split_point:].strip()

    if remaining:
        messages.append(remaining)

    return messages
```

## Chapter Grouping

**Default Rule**: 5 episodes per chapter
- Chapter 1: Episodes 1-5 (Lv1)
- Chapter 2: Episodes 6-10 (Lv2)
- Chapter 3: Episodes 11-15 (Lv3)

**Formula**:
```python
chapter_num = (episode_number - 1) // 5 + 1
chapter_key = f"장 {chapter_num}"
```

**Thread Naming**: `{title} ({version}) - {chapter_key}`
- Example: `마인드벤드 카페 (v1.0) - 장 1`

## Project Metadata Extraction

### YAML Format
```python
for line in content.splitlines():
    if ":" in line and not line.strip().startswith("#"):
        key, value = line.split(":", 1)
        result[key.strip()] = value.strip()
```

### Markdown Format (Fallback)
```python
# Extract title from first header
match = re.search(r"#\s+(.+)", content)
if match:
    title = match.group(1).split("—")[0].strip()
```

## Usage Patterns

### Full Novel Export
```bash
bash ~/.hermes/workspace/novels/scripts/novel-export.py mindbend-cafe all
```

### Single Chapter
```bash
bash ~/.hermes/workspace/novels/scripts/novel-export.py mindbend-cafe chapter-1
```

### Single Episode
```bash
bash ~/.hermes/workspace/novels/scripts/novel-export.py mindbend-cafe episode-3
```

### Dry Run (No Discord Posts)
```bash
bash ~/.hermes/workspace/novels/scripts/novel-export.py mindbend-cafe all --dry-run
```

## Integration Points

### Novel Writing Pipeline
After episode validation:
```bash
bash ~/.hermes/workspace/novels/scripts/novel-export.py {slug} all
```

### Automated Triggers
- Episode file creation
- Validation pass
- Manual invocation

## Troubleshooting

### Thread Creation Fails
- **Error**: "Invalid Form Body, type must be one of (10, 11, 12, 19)"
- **Cause**: Channel is a forum channel (type 15)
- **Fix**: Use type 11 (public thread) instead of type 15 (forum thread)

### Message Too Long
- **Symptom**: Discord API 400 error
- **Fix**: Ensure split_message() uses max_length=1900

### Missing BOT Token
- **Symptom**: "DISCORD_BOT_TOKEN not found"
- **Fix**: Check `~/.hermes/.env` or set `env.DISCORD_BOT_TOKEN`

## Test Results (JOB-1378)

**마인드벤드 카페 Export**:
- 장 1 (1-5화): 6 messages (3화 split into 2)
- 장 2 (6-10화): 5 messages
- 장 3 (11-15화): 5 messages
- **Total**: 16 messages across 3 threads

## Related Skills
- `novel-writing`: Novel creation workflow
- `discord-api-automation`: Discord API patterns
