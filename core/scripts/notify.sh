#!/usr/bin/env bash
# notify.sh - Hermes/OpenClaw Bridge Notification Script
# Usage: notify.sh <type> <subject> <message> [json_data]
# Types: decision, job, alert, security

set -euo pipefail

# Configuration
BRIDGE_URL="${BRIDGE_URL:-http://localhost:8080}"
BRIDGE_ENDPOINT="${BRIDGE_URL}/event"
BLACKBOARD_DECISIONS_DIR="$HERMES_ROOT/knowledge/decisions"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TOKEN_FILE="$HERMES_ROOT/projects/dual-agent-bridge/.api_token"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[NOTIFY]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err() { echo -e "${RED}[ERROR]${NC} $1"; }

# Arguments
TYPE="${1:-alert}"
SUBJECT="${2:-No Subject}"
MESSAGE="${3:-No Message}"
JSON_DATA="${4:-{}}"

if [ -z "$TYPE" ]; then
    log_err "Usage: $0 <type> <subject> <message> [json_data]"
    exit 1
fi

# 1. Construct Payload
PAYLOAD=$(cat <<EOF
{
  "type": "${TYPE}",
  "timestamp": "${TIMESTAMP}",
  "data": {
    "subject": "${SUBJECT}",
    "message": "${MESSAGE}",
    "meta": ${JSON_DATA:-{}}
  },
  "source": "hermes"
}
EOF
)

# 2. Update Blackboard if Decision (Local backup)
if [[ "$TYPE" == "decision" ]]; then
    mkdir -p "$BLACKBOARD_DECISIONS_DIR"
    DECISION_FILE="$BLACKBOARD_DECISIONS_DIR/decision-$(date +%Y%m%d-%H%M%S).json"
    # Combine message and json data for the decision record
    FINAL_DECISION=$(jq -n \
        --arg ts "$TIMESTAMP" \
        --arg type "$TYPE" \
        --arg subj "$SUBJECT" \
        --arg msg "$MESSAGE" \
        --argjson data "${JSON_DATA:-{}}" \
        '{
            type: $type,
            subject: $subj,
            message: $msg,
            timestamp: $ts,
            data: $data,
            source: "hermes"
        }')
    
    echo "$FINAL_DECISION" > "$DECISION_FILE"
    log_info "Decision saved to Blackboard: $DECISION_FILE"
fi

# 3. Send via Bridge API
# Check if token exists
TOKEN=""
if [ -f "$TOKEN_FILE" ]; then
    TOKEN=$(cat "$TOKEN_FILE" | tr -d '[:space:]')
    AUTH_HEADER="Authorization: Bearer $TOKEN"
else
    log_warn "API Token not found at $TOKEN_FILE. Sending without auth (if allowed)."
    AUTH_HEADER="Authorization: Bearer placeholder"
fi

log_info "Sending ${TYPE} notification: ${SUBJECT}"

# Send request
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$BRIDGE_ENDPOINT" \
    -H "Content-Type: application/json" \
    -H "$AUTH_HEADER" \
    -d "$PAYLOAD" 2>/dev/null || echo "000")

if [[ "$HTTP_CODE" =~ ^2 ]]; then
    log_info "Notification sent successfully (HTTP $HTTP_CODE)"
else
    log_err "Failed to send notification (HTTP $HTTP_CODE)"
    echo "Payload: $PAYLOAD"
    exit 1
fi
