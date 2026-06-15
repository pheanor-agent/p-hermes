# Bash Heredoc with Python — Known Pitfalls

## JOB-1507/1508에서 발견된 문제

### 1. Python 인자 전달 실패

**문제**: `python3 << 'PYEOF' "$arg"` 패턴은 arg를 Python에 전달하지 않음

```bash
# ❌ 잘못됨 — Python이 Spec 파일을 실행코드로 인식
python3 << 'PYEOF' "$spec_file" "$version"
import sys
spec_file = sys.argv[1]  # → IndexError: list index out of range
PYEOF

# ✅ 올바름 — python3 - 사용
python3 - "$spec_file" "$version" << 'PYEOF'
import sys
spec_file = sys.argv[1]  # → 정상 작동
PYEOF
```

**근본 원인**: bash heredoc에서 `<< 'PYEOF'`는 stdin으로만 전달. `-` 플래그가 없으면 Python이 파일 인자를 실행코드로 해석.

### 2. YAML frontmatter 파싱 에러

**문제**: Spec 파일의 `---` frontmatter가 Python 문법으로 해석

```python
# ❌ Spec 파일 내용: ---
# spec_id: SPEC-B1
# SyntaxError: invalid syntax
with open(spec_file) as f:
    content = f.read()  # Python이 ---를 실행코드로 해석
```

**해결**: 파일 읽기 전에 frontmatter 제거

```python
with open(spec_file) as f:
    raw = f.read()

# frontmatter 제거
if raw.startswith("---"):
    end = raw.find("---", 3)
    content = raw[end+3:].strip() if end != -1 else raw
```

### 3. set -u + unbound variable

**문제**: `set -euo pipefail` 환경에서 heredoc 내에서 bash 변수 사용 시 에러

```bash
# ❌ set -u 활성화 시 에러
python3 - << 'PYEOF'
import sys
# spec_file이 bash 변수로 인식되지 않음
PYEOF

# ✅ sys.argv 사용
python3 - "$spec_file" << 'PYEOF'
import sys
spec_file = sys.argv[1]
PYEOF
```

### 4. lookup 명령어 누락

**문제**: 설계에 있는 명령어가 스크립트에 구현 안 됨

**해결**: 
1. `cmd_lookup()` 함수 구현
2. case 문에 `lookup)` 등록
3. 테스트 실행

---

## 참고

- spec-version-map.sh에서 발견된 실제 버그
- JOB-1507에서 3개 버그 수정 (heredoc, frontmatter, lookup)
- JOB-1508에서 롤백/drift 스크립트 설계 시 동일 패턴 적용
