# bash heredoc + Python 통합 패턴

## 올바른 패턴

### Python 인자 전달 (O)
```bash
python3 - "$var1" "$var2" << 'PYEOF'
import sys
var1 = sys.argv[1]
var2 = sys.argv[2]
# ... 코드 ...
PYEOF
```

### Python 인자 전달 (X)
```bash
# Python이 $var1을 실행 파일로 인식 → 에러
python3 << 'PYEOF' "$var1" "$var2"
import sys
# ... 코드 ...
PYEOF
```

## f-string 따옴표 충돌 해결

### 변수 분리 후 출력 (O)
```python
# heredoc 내에서 사용
from_v = entry.get('from_version', '?')
to_v = entry.get('to_version', '?')
print(f'  {from_v} → {to_v}')
```

### 직접 출력 (X)
```python
# bash가 따옴표 해석 실패
print(f'  {entry.get("from_version", "?")} → {entry.get("to_version", "?")}')
```

## YAML frontmatter 제거

```python
with open(spec_file, "r") as f:
    raw_content = f.read()

# YAML frontmatter (---로 시작하고 ---로 끝나는 부분) 제거
if raw_content.startswith("---"):
    end_marker = raw_content.find("---", 3)
    if end_marker != -1:
        content = raw_content[end_marker + 3:].strip()
    else:
        content = raw_content
else:
    content = raw_content
```

## set -u + unbound variable

- **원인**: heredoc 내에서 bash 변수가 Python에서 인식 안 됨
- **해결**: quote된 delimiter `'PYEOF'` 사용 + `sys.argv`로 인자 전달
- **확인**: `python3 - "$vm_file" << 'PYEOF'` 형태에서만 동작

## 검증 체크리스트

- [ ] `bash 스크립트명 --help` 실행 테스트
- [ ] 모든 명령어별 테스트
- [ ] YAML frontmatter 포함 파일 테스트
- [ ] f-string 출력 시 따옴표 이스케이프 확인
- [ ] set -u 환경에서 unbound variable 에러 없음
