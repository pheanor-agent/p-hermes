#!/bin/bash
# job.sh — Hermes JOB 관리 스크립트
# OpenClaw 레거시 스크립트를 Hermes 환경에 맞게 통합

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREATOR="$SCRIPT_DIR/create-job.sh"
LISTER="$SCRIPT_DIR/job-list.sh"

case "${1:-help}" in
    create)
        shift
        bash "$CREATOR" "$@"
        ;;
    list)
        shift
        bash "$LISTER" "$@"
        ;;
    status)
        if [ -z "$2" ]; then
            echo "❌ JOB ID를 입력하세요. 예: /job status 1145"
            exit 1
        fi
        JOB_ID="JOB-$2"
        JOB_DIR="$HOME/.hermes/workspace/jobs/$JOB_ID-"
        # Find the job dir
        ACTUAL_DIR=$(ls -d $HOME/.hermes/workspace/jobs/${JOB_ID}-* 2>/dev/null | head -1)
        if [ -z "$ACTUAL_DIR" ]; then
            echo "❌ JOB-$2를 찾을 수 없습니다."
            exit 1
        fi
        STATE_FILE="$ACTUAL_DIR/.workflow-state"
        if [ -f "$STATE_FILE" ]; then
            echo "📊 $JOB_ID 상태:"
            cat "$STATE_FILE" | python3 -m json.tool 2>/dev/null || cat "$STATE_FILE"
        else
            echo "⚠️ 상태 파일을 찾을 수 없습니다."
        fi
        ;;
    *)
        echo "📋 Hermes JOB 관리 도구"
        echo ""
        echo "사용법:"
        echo "  /job create [OPTIONS] <유형> <제목>  — 새 작업 생성"
        echo "  /job list                           — 최근 작업 목록"
        echo "  /job status <ID>                    — 특정 작업 상태 조회"
        echo ""
        echo "예시:"
        echo "  /job create 기능 \"새 스킬 구현\""
        echo "  /job list"
        ;;
esac
