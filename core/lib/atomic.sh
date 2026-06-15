#!/bin/bash
# atomic.sh - 원자적 파일 쓰기 라이브러리
HERMES_ROOT="${HERMES_ROOT:-$HOME/.hermes}"
#
# 사용법:
#   source $HERMES_ROOT/core/scripts/lib/atomic.sh
#   atomic_write <target_path> <data>
#
# 원리:
#   1. 임시 파일 생성 (mktemp)
#   2. 임시 파일에 데이터 쓰기 + sync (디스크 기록 보장)
#   3. mv (리눅스 VFS 수준에서 원자적 이름 변경)
#
# 특징:
#   - 프로세스 중단 시에도 파일은 "이전 버전" 또는 "새 버전" 중 하나만 존재
#   - 부분적 작성 상태 불가능
#   - trap EXIT로 tmp 파일 cleanup

atomic_write() {
    local target="$1"
    local data="${2:-}"
    
    if [ -z "$target" ]; then
        echo "ERROR: atomic_write requires target path" >&2
        return 1
    fi
    
    local dir=$(dirname "$target")
    mkdir -p "$dir" 2>/dev/null
    
    local tmp=$(mktemp "${dir}/.atomic-tmp.XXXXXX")
    
    # trap으로 cleanup 보장
    trap "rm -f '$tmp'" EXIT
    
    # stdin에서 입력 받거나 $2 사용
    if [ -t 0 ] && [ -n "$data" ]; then
        echo "$data" > "$tmp"
    elif [ ! -t 0 ]; then
        cat > "$tmp"
    else
        echo "" > "$tmp"
    fi
    
    # sync: .pending writes 디스크 플러시 (WSL에서도 가벼움 - 0.001s)
    sync
    
    if ! mv "$tmp" "$target"; then
        echo "ERROR: atomic_write mv failed for $target" >&2
        rm -f "$tmp"
        return 1
    fi
    
    # trap 해제
    trap - EXIT
    return 0
}

# atomic_write_file: 파일 내용을 원자적으로 업데이트
# 사용법: atomic_write_file <target_path> <source_file>
atomic_write_file() {
    local target="$1"
    local source="$2"
    
    if [ -z "$target" ] || [ -z "$source" ]; then
        echo "ERROR: atomic_write_file requires target and source" >&2
        return 1
    fi
    
    local dir=$(dirname "$target")
    mkdir -p "$dir" 2>/dev/null
    
    local tmp=$(mktemp "${dir}/.atomic-tmp.XXXXXX")
    trap "rm -f '$tmp'" EXIT
    
    cp "$source" "$tmp"
    sync
    
    if ! mv "$tmp" "$target"; then
        echo "ERROR: atomic_write_file mv failed for $target" >&2
        rm -f "$tmp"
        return 1
    fi
    
    trap - EXIT
    return 0
}
