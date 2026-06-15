#!/bin/bash
#==============================================================================
HERMES_ROOT="${HERMES_ROOT:-$HOME/.hermes}"
# check-symlink.sh - 파일/폴더 삭제 전 심링크 확인
#==============================================================================
#
# 사용법: check-symlink.sh {경로}
#
# 출력:
#   안전: 일반 파일/폴더
#   주의: 심링크 존재 (확인 필요)
#   위험: 심링크 공유 폴더 (inode 동일)
#
#==============================================================================

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <path> [path2...]"
    exit 1
fi

check_path() {
    local target="$1"
    
    if [[ ! -e "$target" ]]; then
        echo "❌ 존재하지 않음: $target"
        return 1
    fi
    
    # 1. 심링크 확인
    if [[ -L "$target" ]]; then
        local link_target=$(readlink -f "$target")
        echo "🔗 심링크: $target → $link_target"
        
        # 원본이 다른 경로인지 확인
        local real_target=$(realpath "$target")
        local canonical=$(readlink -f "$target")
        
        if [[ "$real_target" != "$canonical" ]]; then
            echo "⚠️  주의: 심링크가 다른 위치를 가리킴"
            echo "    원본: $real_target"
            echo "    링크: $canonical"
            return 2
        fi
        return 0
    fi
    
    # 2. 디렉토리인 경우 inode 확인 (공유 폴더 감지)
    if [[ -d "$target" ]]; then
        local inode=$(stat -c %i "$target" 2>/dev/null || stat -f %i "$target" 2>/dev/null)
        local device=$(stat -c %d "$target" 2>/dev/null || stat -f %d "$target" 2>/dev/null)
        
        # 공유 폴더 확인
        if [[ "$target" == *"/workspace/jobs"* ]]; then
            echo "📁 작업 폴더: $target"
            echo "   Inode: $inode, Device: $device"
            
            # 다른 경로에서 동일한 inode 확인
            for alt in $HERMES_ROOT/workspace/jobs; do
                if [[ -d "$alt" && "$alt" != "$target" ]]; then
                    local alt_inode=$(stat -c %i "$alt" 2>/dev/null || stat -f %i "$alt" 2>/dev/null)
                    if [[ "$alt_inode" == "$inode" ]]; then
                        echo "🔗 공유 폴더: $alt (동일 inode)"
                        return 3
                    fi
                fi
            done
        fi
    fi
    
    echo "✅ 안전: $target"
    return 0
}

# 모든 인수 처리
exit_code=0
for path in "$@"; do
    check_path "$path" || exit_code=$?
done

exit $exit_code
