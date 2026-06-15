---
name: directory-migration
description: Directory restructuring with path refactoring across script libraries — physical moves, environment variable abstraction, bulk updates, and verification.
---

# Directory Migration & Path Refactoring

문서/데이터베이스/스크립트 라이브러리의 디렉토리 구조 변경 시 사용하는 클래스 레벨 워크플로우.

## 트리거

- 디렉토리 구조 변경 (계층화, 분류, 이동)
- 경로 변수화 (절대 경로 → 환경 변수 추상화)
- 스크립트/설정 파일의 대량 경로 업데이트
- 심링크 제거 (물리적 이동으로 전환)

## 설계 원칙

1. **심링크 금지**: 물리적 이동만. 심링크는 LLM 탐색 효율 저하 (JOB-1626)
2. **경로 추상화**: `$HERMES_ROOT` 또는 `$PROJECT_ROOT` 환경 변수 사용. 절대 경로 금지
3. **원자적 실행**: flock 기반 원자적 파일 생성
4. **백업 필수**: 변경 전 백업, 되돌릴 수 있는 상태 유지
5. **5-Tier 아키텍처**: core/(정적) → runtime/(동적) → hooks/(인터페이스) → state/(인프라) → release/(선택)

## 단계

### Phase 0: 환경 변수 추상화

```bash
# 1. 절대 경로 식별
grep -rn '/home/[^/]*/\\.hermes/' path/ --include='*.sh' | wc -l

# 2. HERMES_ROOT 기반 패턴으로 교체
# 스크립트 헤더에 다음 패턴 추가:
#   HERMES_ROOT="${HERMES_ROOT:-$HOME/.hermes}"
# 또는 .env 파일에 설정:
#   HERMES_ROOT="$HOME/.hermes"

# 3. 스크립트 내 직접 교체 ($HERMES_ROOT 사용)
for f in $(grep -rl '/home/[^/]*/\\.hermes/' path/ --include="*.sh"); do
    sed -i "s|/home/[^/]*/\\.hermes/|\\$HERMES_ROOT/|g" "$f"
done

# 4. Python 스크립트 추상화 (os.path.expanduser → HERMES_ROOT env)
# 권장 패턴:
#   import os
#   HERMES_ROOT = os.environ.get('HERMES_ROOT', os.path.expanduser('~/.hermes'))
#   BASE_DIR = Path(HERMES_ROOT)

# 5. 검증
grep -rn '/home/[^/]*/\\.hermes/' path/ --include='*.sh' | wc -l  # 0
```

### Phase 1: 물리적 계층화 (5-Tier)

```bash
# 1. 계층 구조 정의
# core/     - Tier 1: 정적 (변경 안 됨): scripts, skills, cron.registry
# runtime/  - Tier 2: 동적 상태 (실행 시 생성): sessions, memory
# hooks/    - Tier 3: 인터페이스 (gateway 스크립트): group-chat, classify-input
# state/    - Tier 4: 인프라 상태: jobs, events (event bus)
# release/  - Tier 5: 배포용 (선택)

# 2. 물리적 이동 (심링크 X)
# ⚠️ mv는 심링크를 심링크 상태로 유지! 심링크가 있다면 rm + cp -r 사용
mkdir -p "$HERMES_ROOT/core"
rm -rf "$HERMES_ROOT/scripts"  # 심링크 제거
cp -r "$OLD_PATH/scripts" "$HERMES_ROOT/core/scripts/"  # 물리적 복사
# 또는 rsync:
# rsync -a --copy-links "$OLD_PATH/scripts/" "$HERMES_ROOT/core/scripts/"

# 3. 스크립트 내 경로 업데이트
for f in $(grep -rl '\$HERMES_ROOT/scripts/' path/ --include="*.sh"); do
    sed -i 's|\\$HERMES_ROOT/scripts/|$HERMES_ROOT/core/scripts/|g' "$f"
done
```

### Phase 2: 검증

```bash
# 1. 구 경로 참조 확인 (0여야 함)
grep -rn '\$HERMES_ROOT/scripts/' path/ --include='*.sh' | wc -l

# 2. 신규 경로 확인
grep -rn '\$HERMES_ROOT/core/scripts/' path/ --include='*.sh' | wc -l

# 3. crontab 경로 업데이트 (스크립트 폴더 이동 시 필수)
crontab -l | sed 's|old/path/core/scripts|new/path/core/scripts|g' | crontab -
# 또는:
crontab -l  # 구경로 확인 → sed로 수정 → crontab -으로 적용

# 4. 실행 테스트
bash -n path/to/script.sh  # 구문 검사
bash path/to/script.sh --help  # 실행 테스트

# 5. 이벤트 버스 경로 확인 (state/events/ 기반)
ls -la $HERMES_ROOT/state/events/bus/ | head
```

## Pitfalls

- **심링크 유혹**: `ln -s`는 사용하지 않음. 물리적 이동 강제
- **`mv`가 심링크를 유지하는 문제**: `mv`는 심링크를 심링크 상태로 유지. 심링크가 있는 폴더 이동 시 `rm` 후 `cp -r` 또는 `rsync` 사용 필수 (JOB-1629 Phase 1 발견)
- **경로 부분 일치**: `sed` 시 전체 경로 매칭 필수 (partial match 오버라이트 주의)
- **설정 파일 누락**: 스크립트만 수정하고 config.yaml/.env 업데이트 누락
- **crontab 경로를 잊는 것**: 스크립트 폴더 이동 후 crontab의 절대경로도 전량 업데이트 필요 (`crontab -l | sed | crontab -`)
- **백업 없음**: 변경 전 백업 없으면 되돌릴 수 없음
- **권한 문제**: 이동 후 chmod/ownership 확인
- **$HERMES_ROOT 세션 scope**: `HERMES_ROOT="..."` (할당만)은 현재 shell에서만 유효. `export HERMES_ROOT="..."` 또는 `.env` 파일 설정이 없으면 서브프로세스/스크립트에서 참조 불가 (JOB-1629 Phase 2 발견)

## 검증 체크리스트

- [ ] 구 경로 참조 0개 확인
- [ ] 신규 경로 참조 예상 수 확인
- [ ] `bash -n` 구문 검사 PASS
- [ ] 대표 스크립트 1-2개 실행 테스트
- [ ] 설정 파일 (config.yaml, .env) 업데이트 확인
