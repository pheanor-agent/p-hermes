#!/bin/bash
#==============================================================================
# dedup-jobs.sh — 중복 JOB 번호 정리 스크립트 (v2)
#
# 사용법: bash dedup-jobs.sh [--dry-run]
#
# 주의: 폴더명 특수문자(콜론, 이모티콘, 인코딩 문자) 포함 시 bash array 처리 실패 가능
#       이 버전은 find + while 읽기로 안전하게 처리
#
#==============================================================================

set -euo pipefail

JOBS_DIR="$HOME/.hermes/workspace/jobs"
DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "🔍 DRY-RUN 모드"
fi

echo "🔍 중복 JOB 스캔 시작..."

next_global=0

# 첫 패스: 다음 사용 가능 번호 계산
max_num=0
for d in "$JOBS_DIR"/JOB-*/; do
    [[ -d "$d" ]] || continue
    basename=$(basename "$d")
    num=$(echo "$basename" | sed 's/^JOB-//' | grep -oP '^\d+' 2>/dev/null || true)
    [[ -n "$num" ]] && [[ "$num" =~ ^[0-9]+$ ]] && [[ "$num" -gt "$max_num" ]] && max_num=$num
done
next_global=$((max_num + 1))

echo "  기준 번호: JOB-${next_global}"

# 중복 감지 및 정리
duplicate_count=0
renamed_count=0

while IFS= read -r num; do
    [[ -z "$num" ]] && continue
    
    folders=$(find "$JOBS_DIR" -maxdepth 1 -type d -name "JOB-${num}*" -printf '%f\n' 2>/dev/null)
    count=$(echo "$folders" | wc -l)
    
    [[ $count -le 1 ]] && continue
    
    duplicate_count=$((duplicate_count + 1))
    echo "📁 JOB-${num}: $count 개"
    
    first=true
    while IFS= read -r folder; do
        [[ -z "$folder" ]] && continue
        
        if $first; then
            echo "  ✅ 유지: $folder"
            first=false
        else
            old_path="$JOBS_DIR/$folder"
            new_folder="JOB-${next_global}-${folder#JOB-${num}-}"
            new_path="$JOBS_DIR/$new_folder"
            
            echo "  🔄 JOB-${num} → JOB-${next_global}"
            
            if [[ "$DRY_RUN" != "true" ]]; then
                mv "$old_path" "$new_path"
                
                # 파일 내 번호 갱신
                [[ -f "$new_path/.workflow-state" ]] && \
                    sed -i "s/\"JOB-${num}\"/\"JOB-${next_global}\"/g" "$new_path/.workflow-state"
                [[ -f "$new_path/request.md" ]] && \
                    sed -i "s/JOB-${num}/JOB-${next_global}/g" "$new_path/request.md"
                [[ -f "$new_path/architecture.md" ]] && \
                    sed -i "s/JOB-${num}/JOB-${next_global}/g" "$new_path/architecture.md"
                [[ -f "$new_path/execution-result.md" ]] && \
                    sed -i "s/JOB-${num}/JOB-${next_global}/g" "$new_path/execution-result.md"
            fi
            
            renamed_count=$((renamed_count + 1))
            next_global=$((next_global + 1))
        fi
    done <<< "$folders"
done < <(find "$JOBS_DIR" -maxdepth 1 -type d -name "JOB-*" -printf '%f\n' 2>/dev/null | \
  sed 's/JOB-\([0-9]*\).*/\1/' | sort -n | uniq -d)

echo ""
echo "=== 정리 완료 ==="
echo "  중복 감지: $duplicate_count"
echo "  재할당: $renamed_count"
echo "  다음 기준 번호: JOB-${next_global}"

if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    echo "⚠️  DRY-RUN 모드 — 실제 변경 없음"
    echo "   --dry-run 옵션 없이 실행하면 실제 변경됨"
fi

# 검증
if [[ "$DRY_RUN" != "true" ]]; then
    remaining=$(find "$JOBS_DIR" -maxdepth 1 -type d -name "JOB-*" -printf '%f\n' 2>/dev/null | \
      sed 's/JOB-\([0-9]*\).*/JOB-\1/' | sort | uniq -c | awk '$1>1' | wc -l)
    echo ""
    echo "📊 최종 검증: 중복 $remaining 개"
    
    if [[ "$remaining" -gt 0 ]]; then
        echo "⚠️  중복이 남아 있습니다 — 재실행 권장"
        exit 1
    fi
fi

exit 0
