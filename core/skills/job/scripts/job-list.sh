#!/bin/bash
# job-list.sh - Hermes Local Job List
# Reads from ~/.hermes/workspace/jobs/

JOBS_DIR="$HOME/.hermes/workspace/jobs"

if [ ! -d "$JOBS_DIR" ]; then
    echo "❌ Jobs directory not found: $JOBS_DIR"
    exit 1
fi

echo "📋 Hermes Job List (Recent 10)"
echo "─────────────────────────────────────"

# List directories matching JOB-*, sort by name (newest first if numbering is sequential)
ls -dt "$JOBS_DIR"/JOB-* 2>/dev/null | head -10 | while read -r job_dir; do
    # Extract Job ID and Title
    dirname=$(basename "$job_dir")
    job_id=$(echo "$dirname" | grep -oE 'JOB-[0-9]+' | head -1)
    title=$(echo "$dirname" | sed "s/^JOB-[0-9]*-//")
    
    # Check status
    state_file="$job_dir/.workflow-state"
    status="unknown"
    step="unknown"
    
    if [ -f "$state_file" ]; then
        status=$(grep -o '"status": *"[^"]*"' "$state_file" | head -1 | cut -d'"' -f4)
        step=$(grep -o '"currentStep": *"[^"]*"' "$state_file" | head -1 | cut -d'"' -f4)
    else
        status="no-state-file"
        step="?"
    fi

    # Icon based on status
    ICON="⬜"
    [[ "$status" == "running" ]] && ICON="🔄"
    [[ "$status" == "completed" ]] && ICON="✅"
    [[ "$status" == "failed" ]] && ICON="❌"

    echo "${ICON} ${job_id} | ${status:-unknown:10} (${step}) | ${title}"
done
