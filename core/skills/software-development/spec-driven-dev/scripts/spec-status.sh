#!/usr/bin/env bash
# SPEC-STATUS — Spec 상태 갱신 + 버전 자동 증가 + CHANGELOG 자동 생성 + ADR 생성
# 
# Usage: bash spec-status.sh <slug> <spec-id> <status> [job-id] [bump-level]
# Example: bash spec-status.sh my-api SPEC-A001 approved JOB-1500
#          bash spec-status.sh my-api SPEC-A001 proposed JOB-1500 major  # breaking change
#
# 상태: proposed → approved → in_progress → implemented → verified
# 분기: changed ← deprecated → re-verified
#
# P0: 버전 자동 증가 (MAJOR.MINOR.PATCH)
# P0: CHANGELOG 자동 생성 (git diff 기반)
# P0: ADR 자동 생성 (MAJOR 변경 시)

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SKILL_DIR}/spec-version.sh"

# ── 검증 ──────────────────────────────────────────────
[[ $# -lt 3 ]] && {
    echo "Usage: bash spec-status.sh <slug> <spec-id> <status> [job-id] [bump-level]"
    echo "  bump-level: major | minor | patch (기본: 자동)"
    exit 1
}

SLUG="$1"
SPEC_ID="$2"
STATUS="$3"
JOB_ID="${4:-UNKNOWN}"
MANUAL_BUMP="${5:-}"  # 수동 버전 강제 지정 (major|minor|patch)

PROJECT_DIR="$HOME/.hermes/workspace/projects/${SLUG}"

# 프로젝트 확인
[[ ! -d "$PROJECT_DIR" ]] && {
    echo "❌ 프로젝트 '${SLUG}'을/를 찾을 수 없습니다"
    exit 1
}

# Spec 파일 확인
SPEC_FILE=$(find "$PROJECT_DIR/specs/active" -name "*.md" -exec grep -l "${SPEC_ID}" {} \; 2>/dev/null | head -1)
[[ -z "$SPEC_FILE" ]] && {
    echo "❌ Spec '${SPEC_ID}'을/를 찾을 수 없습니다"
    exit 1
}

# ── 현재 metadata 읽기 ────────────────────────────────
CURRENT_STATUS=$(grep -E "^status:" "$SPEC_FILE" | head -1 | awk '{print $2}')
CURRENT_VERSION=$(grep -E "^version:" "$SPEC_FILE" | head -1 | awk '{print $2}')

# v 접두사 제거 → SemVer로 변환
CURRENT_VERSION=$(version_from_vformat "$CURRENT_VERSION")

# Spec 제목 추출 (frontmatter 후 첫 ### heading)
TITLE=$(sed -n '/^---$/,/^---$/p' "$SPEC_FILE" | grep -v '^---' | head -1 || true)
TITLE=$(grep -E "^# " "$SPEC_FILE" | head -1 | sed 's/^# *//' || true)
TITLE="${TITLE:-breaking-change}"

[[ -z "$CURRENT_STATUS" ]] && {
    echo "❌ 현재 상태를 읽을 수 없습니다"
    exit 1
}

echo "📋 Spec: ${SPEC_ID}"
echo "   현재 상태: ${CURRENT_STATUS}"
echo "   현재 버전: ${CURRENT_VERSION}"
echo "   대상 상태: ${STATUS}"

# ── 상태 전이 검증 ────────────────────────────────────
VALID_TRANSITIONS=(
    "proposed:approved"
    "approved:in_progress"
    "in_progress:implemented"
    "implemented:verified"
    "approved:changed"
    "implemented:changed"
    "verified:deprecated"
    "deprecated:proposed"
    "changed:in_progress"
)

VALID=false
for transition in "${VALID_TRANSITIONS[@]}"; do
    IFS=':' read -r from to <<< "$transition"
    if [[ "$CURRENT_STATUS" == "$from" && "$STATUS" == "$to" ]]; then
        VALID=true
        break
    fi
done

[[ "$VALID" != "true" ]] && {
    echo "❌ 상태 전이 '${CURRENT_STATUS} → ${STATUS}'는/는 허용되지 않습니다"
    echo "   허용된 전이:"
    for transition in "${VALID_TRANSITIONS[@]}"; do
        IFS=':' read -r from to <<< "$transition"
        echo "   ${from} → ${to}"
    done
    exit 1
}

# ── P0: 버전 자동 증가 ────────────────────────────────
if [[ -n "$MANUAL_BUMP" ]]; then
    BUMP_LEVEL="$MANUAL_BUMP"
else
    BUMP_LEVEL=$(get_version_bump_level "$CURRENT_STATUS" "$STATUS")
fi

NEW_VERSION=$(version_bump "$CURRENT_VERSION" "$BUMP_LEVEL")
CHANGELOG_TYPE=$(get_changelog_type "$CURRENT_STATUS" "$STATUS")

echo "   버전 증가: ${CURRENT_VERSION} → ${NEW_VERSION} (${BUMP_LEVEL})"
echo "   CHANGELOG 유형: ${CHANGELOG_TYPE}"

# ── 상태 + 버전 갱신 ──────────────────────────────────
sed -i "s/^status: ${CURRENT_STATUS}/status: ${STATUS}/" "$SPEC_FILE"
sed -i "s/^version: .*/version: ${NEW_VERSION}/" "$SPEC_FILE"

# version_history 갱신
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
DATE_TODAY=$(date +%Y-%m-%d)
SUMMARY="${CURRENT_STATUS} → ${STATUS}"

update_spec_version "$SPEC_FILE" "$NEW_VERSION" "$SUMMARY"

# updated 날짜 갱신
sed -i "s/^updated: .*/updated: ${DATE_TODAY}/" "$SPEC_FILE"

echo "✅ 상태 갱신: ${SPEC_ID} → ${STATUS}"
echo "   버전: ${CURRENT_VERSION} → ${NEW_VERSION}"

# ── P0: CHANGELOG 자동 생성 ───────────────────────────
CHANGELOG_DIR="$PROJECT_DIR/specs/history"
CHANGELOG_FILE="$CHANGELOG_DIR/CHANGELOG.md"
mkdir -p "$CHANGELOG_DIR"

# CHANGELOG 헤더 확인/생성
if [[ ! -f "$CHANGELOG_FILE" ]]; then
    cat > "$CHANGELOG_FILE" << 'HEADER'
# Spec 변경 이력 (Changelog)

본 파일은 spec-status.sh 및 spec-changelog.sh에 의해 자동 관리됩니다.
변경 이력은 [Keep a Changelog](https://keepachangelog.com/) 형식을 따릅니다.

HEADER
fi

# git diff 추출 (저장소 내라면)
GIT_DIFF=""
CHANGED_SECTIONS=""
if git -C "$PROJECT_DIR" diff HEAD -- "$SPEC_FILE" >/dev/null 2>&1; then
    GIT_DIFF=$(git -C "$PROJECT_DIR" diff HEAD -- "$SPEC_FILE" 2>/dev/null || true)
    CHANGED_SECTIONS=$(echo "$GIT_DIFF" | grep -E "^[\+\-]##" | sed 's/^[\+\-]##* //' | sort -u || true)
fi

# 관련 JOB 커밋 메시지 추출
RELATED_COMMITS=$(git -C "$PROJECT_DIR" log --oneline -5 -- "$SPEC_FILE" 2>/dev/null | head -3 || true)

# CHANGELOG entry 생성 (실제 줄바꿈 사용)
NL=$'\n'
ENTRY=""
ENTRY+="${NL}## [${NEW_VERSION}] ${SPEC_ID} — ${DATE_TODAY}${NL}${NL}"
ENTRY+="- **변경 유형**: ${CHANGELOG_TYPE}${NL}"
ENTRY+="- **전환**: \`${CURRENT_STATUS}\` → \`${STATUS}\`${NL}"
ENTRY+="- **버전**: \`${CURRENT_VERSION}\` → \`${NEW_VERSION}\` (${BUMP_LEVEL})${NL}"
ENTRY+="- **작업**: ${JOB_ID}${NL}"
ENTRY+="- **Spec 파일**: ${SPEC_FILE#$PROJECT_DIR/}${NL}"

if [[ -n "$CHANGED_SECTIONS" ]]; then
    ENTRY+="${NL}### 변경된 섹션${NL}"
    while IFS= read -r section; do
        [[ -n "$section" ]] && ENTRY+="- \`${section}\`${NL}"
    done <<< "$CHANGED_SECTIONS"
fi

if [[ -n "$GIT_DIFF" ]]; then
    # diff 요약 (최대 10라인)
    ENTRY+="${NL}### 변경 내용 (git diff)${NL}"
    ENTRY+="\`\`\`diff${NL}${GIT_DIFF}${NL}\`\`\`${NL}"
fi

# CHANGELOG에 삽입 (헤더 다음에)
HEADER_CONTENT=$(head -7 "$CHANGELOG_FILE")
EXISTING_CONTENT=$(tail -n +8 "$CHANGELOG_FILE" 2>/dev/null || true)

cat > "$CHANGELOG_FILE" << EOF
${HEADER_CONTENT}
${ENTRY}
${EXISTING_CONTENT}
EOF

echo "✅ CHANGELOG 갱신: $CHANGELOG_FILE"

# ── _matrix.json 버전 갱신 ────────────────────────────
MATRIX_FILE="$PROJECT_DIR/specs/_matrix.json"
if [[ -f "$MATRIX_FILE" ]]; then
    python3 << PYEOF
import json

matrix_file = "${MATRIX_FILE}"
with open(matrix_file) as f:
    matrix = json.load(f)

spec_data = matrix["items"].get("${SPEC_ID}", {})
if spec_data:
    spec_data["version"] = "${NEW_VERSION}"
    spec_data["status"] = "${STATUS}"
    spec_data["version_history"] = spec_data.get("version_history", []) + [
        {
            "version": "${NEW_VERSION}",
            "date": "${DATE_TODAY}",
            "status": "${STATUS}",
            "summary": "${CURRENT_STATUS} → ${STATUS}"
        }
    ]

with open(matrix_file, 'w') as f:
    json.dump(matrix, f, indent=2, ensure_ascii=False)
PYEOF
    echo "✅ _matrix.json 갱신 (version: ${NEW_VERSION})"
fi

# ── P0: ADR 생성 (MAJOR 변경 시) ──────────────────────
IS_BREAKING=false
if [[ "$BUMP_LEVEL" == "major" ]]; then
    IS_BREAKING=true
fi

if [[ "$IS_BREAKING" == "true" ]]; then
    ADR_DIR="$PROJECT_DIR/specs/adrs"
    mkdir -p "$ADR_DIR"

    # ADR 번호 할당 (기존 파일 수 + 1)
    EXISTING_ADR_COUNT=$(find "$ADR_DIR" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d '[:space:]')
    EXISTING_ADR_COUNT="${EXISTING_ADR_COUNT:-0}"
    ADR_NUM=$(printf "%04d" "$((EXISTING_ADR_COUNT + 1))")

    # 파일명: kebab-case
    ADR_SLUG=$(echo "$SPEC_ID ${TITLE:-breaking-change}" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
    ADR_FILE="$ADR_DIR/${ADR_NUM}-${ADR_SLUG}.md"

    # 템플릿 사용 + 실제 데이터로 치환
    ADR_TEMPLATE="$SKILL_DIR/../templates/adr.md"
    if [[ -f "$ADR_TEMPLATE" ]]; then
        cp "$ADR_TEMPLATE" "$ADR_FILE"
        sed -i "s/\[ADR 제목 - 변경 사항 요약\]/${SPEC_ID} Breaking Change — ${TITLE}/" "$ADR_FILE"
        sed -i "s/date: YYYY-MM-DD/date: ${DATE_TODAY}/" "$ADR_FILE"
        sed -i "s/spec_refs: \[\]/spec_refs: [\"${SPEC_ID}\"]/" "$ADR_FILE"
        sed -i "s/version: MAJOR.MINOR.PATCH/version: ${NEW_VERSION}/" "$ADR_FILE"
        sed -i "s/ADR-NNNN/ADR-${ADR_NUM}/" "$ADR_FILE"
        sed -i "s/\[ADR 제목\]/${SPEC_ID} Breaking Change/" "$ADR_FILE"
    else
        cat > "$ADR_FILE" << EOF
---
title: "${SPEC_ID} Breaking Change — ${CURRENT_STATUS} → ${STATUS}"
date: ${DATE_TODAY}
status: proposed
spec_refs: ["${SPEC_ID}"]
version: ${NEW_VERSION}
bump_level: major
---

# ADR-${ADR_NUM}: ${SPEC_ID} Breaking Change

## Context
${SPEC_ID} Spec에 대한 MAJOR 버전 변경 (${CURRENT_VERSION} → ${NEW_VERSION})이 발생했습니다.
상태 전이: \`${CURRENT_STATUS}\` → \`${STATUS}\`

## Decision
Breaking change를 수행하여 Spec을 재설계합니다.

## Consequences
- 기존 구현이 변경될 수 있습니다
- 관련 코드의 마이그레이션이 필요할 수 있습니다
EOF
    fi

    echo "⚠️  MAJOR 변경 — ADR 생성됨: $ADR_FILE"
    echo "   ADR 내용을 검토하고 수정하세요"
fi

# ── P1: VERSION_MAP.yaml 갱신 (JOB-1507) ─────────────
VERSION_MAP_SCRIPT="$SKILL_DIR/spec-version-map.sh"
if [[ -f "$VERSION_MAP_SCRIPT" ]]; then
    bash "$VERSION_MAP_SCRIPT" update-from-status "$SLUG" "$SPEC_ID" "$NEW_VERSION" "$STATUS" "$JOB_ID" 2>/dev/null || {
        echo "  ⚠️  VERSION_MAP 갱신 실패 (graceful degradation)"
    }
fi

# ── BLACKBOARD FILE DROP (JOB-1500 P2) ────────────────
BLACKBOARD_DIR="$HOME/.shared/knowledge/specs"
mkdir -p "$BLACKBOARD_DIR"

BLACKBOARD_FILE="$BLACKBOARD_DIR/${JOB_ID}-spec-status.json"

cat > "$BLACKBOARD_FILE" << BBEOF
{
  "jobId": "${JOB_ID}",
  "specId": "${SPEC_ID}",
  "specRefs": ["${SPEC_ID}"],
  "specChanges": {
    "${SPEC_ID}": {
      "from": "${CURRENT_STATUS}",
      "to": "${STATUS}",
      "versionFrom": "${CURRENT_VERSION}",
      "versionTo": "${NEW_VERSION}",
      "bumpLevel": "${BUMP_LEVEL}",
      "isBreaking": ${IS_BREAKING}
    }
  },
  "timestamp": "${TIMESTAMP}",
  "specFile": "${SPEC_FILE}",
  "changelog": "${CHANGELOG_FILE}"
}
BBEOF

echo "   Blackboard: $BLACKBOARD_FILE"

# SPEC-IMPACT CASCADE (JOB-1499 P1 추가)
CASCADE_SCRIPT="$HOME/.hermes/skills/custom/research-analysis/triage/scripts/spec-cascade.sh"
if [[ -f "$CASCADE_SCRIPT" ]]; then
    echo ""
    echo "=== Spec-Impact Cascade ==="
    bash "$CASCADE_SCRIPT" "$SLUG" "$SPEC_ID" "$STATUS" 2>&1 || {
        echo "  ⚠️  Cascade 실행 실패 (graceful degradation)"
    }
fi

echo ""
echo "✅ 완료: ${SPEC_ID} → ${STATUS} (version: ${CURRENT_VERSION} → ${NEW_VERSION})"
