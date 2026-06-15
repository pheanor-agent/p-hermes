# Cross-Filesystem Fallback Pattern

## 문제

`/tmp` (tmpfs)에서 생성한 파일을 `~/.hermes/events/bus/` (ext4)로 `mv -n` 시 실패.
동일 파일 시스템에서만 원자적 이동 보장.

## 해결: 3단계 폴백

```bash
# 1차: mv -n (동일 FS, 원자적)
if mv -n "$tmp_file" "$dest_file" 2>/dev/null; then
    return 0
fi

# 2차: 동일 FS 확인 후 install -b
local src_dev=$(stat -c %d "$tmp_file" 2>/dev/null)
local dst_dev=$(stat -c %d "$(dirname "$dest_file")" 2>/dev/null)

if [[ "$src_dev" == "$dst_dev" ]]; then
    if install -b "$tmp_file" "$dest_file" 2>/dev/null; then
        return 0
    fi
fi

# 3차: cross-FS 폴백 (비원자적)
if cp "$tmp_file" "$dest_file.tmp" && mv "$dest_file.tmp" "$dest_file"; then
    rm -f "$tmp_file"
    return 0
fi
```

## 권장 사항

- **원자성 필요 시**: BUS_DIR을 tmpfs가 아닌 로컬 FS에 설정
- **환경변수**: `HERMES_EVENTS_DIR`로 대체 경로 구성 가능

## 검증 (JOB-1621)

```bash
# cross-FS 테스트 (성공)
source ~/.hermes/skills/shared/system-common/lib/event.sh
emit_event "test.cross-fs" "TEST-$$" '{"test": true}'
# → /tmp → ~/.hermes/events/bus/ 성공 (3단계 폴백)
```
