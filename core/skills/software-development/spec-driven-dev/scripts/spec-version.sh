#!/usr/bin/env bash
# spec-version.sh — Spec 버전 관리 헬퍼 함수
#
# 사용법:
#   source spec-version.sh
#   version_bump "1.0.0" "major"   # → 2.0.0
#   version_bump "1.0.0" "minor"   # → 1.1.0
#   version_bump "1.0.0" "patch"   # → 1.0.1
#   version_compare "1.0.0" "2.0.0"  # → "-1" (less), "0" (equal), "1" (greater)
#   version_format "1.0.0"          # → "1.0.0"
#   version_from_vformat "v1.0"     # → "1.0.0"
#
# 세맨틱 버저닝 2.0.0 준수 (semver.org)

# ──────────────────────────────────────────────────────
# version_bump <version> <level>
# 버전 증가. level: major | minor | patch
# ──────────────────────────────────────────────────────
version_bump() {
    local version="$1"
    local level="$2"

    # v 접두사 제거
    version="${version#v}"

    # MAJOR.MINOR.PATCH 분해
    IFS='.' read -r major minor patch <<< "$version"
    major="${major:-0}"
    minor="${minor:-0}"
    patch="${patch:-0}"

    case "$level" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        *)
            echo "❌ 유효하지 않은 버전 레벨: $level (major|minor|patch)" >&2
            return 1
            ;;
    esac

    echo "${major}.${minor}.${patch}"
}

# ──────────────────────────────────────────────────────
# version_compare <v1> <v2>
# 두 버전 비교. 결과: -1 (v1<v2), 0 (same), 1 (v1>v2)
# ──────────────────────────────────────────────────────
version_compare() {
    local v1="${1#v}"
    local v2="${2#v}"

    IFS='.' read -r maj1 min1 pat1 <<< "$v1"
    IFS='.' read -r maj2 min2 pat2 <<< "$v2"

    maj1="${maj1:-0}"; min1="${min1:-0}"; pat1="${pat1:-0}"
    maj2="${maj2:-0}"; min2="${min2:-0}"; pat2="${pat2:-0}"

    if (( maj1 > maj2 )); then echo "1"; return; fi
    if (( maj1 < maj2 )); then echo "-1"; return; fi
    if (( min1 > min2 )); then echo "1"; return; fi
    if (( min1 < min2 )); then echo "-1"; return; fi
    if (( pat1 > pat2 )); then echo "1"; return; fi
    if (( pat1 < pat2 )); then echo "-1"; return; fi
    echo "0"
}

# ──────────────────────────────────────────────────────
# version_from_vformat <old-version>
# 기존 v1.0 → 1.0.0 변환
# ──────────────────────────────────────────────────────
version_from_vformat() {
    local v="${1#v}"
    IFS='.' read -r major minor patch <<< "$v"
    major="${major:-0}"
    minor="${minor:-0}"
    patch="${patch:-0}"
    echo "${major}.${minor}.${patch}"
}

# ──────────────────────────────────────────────────────
# get_version_bump_level <from-status> <to-status>
# 상태 전이에 따른 버전 증가 레벨 반환
# ──────────────────────────────────────────────────────
get_version_bump_level() {
    local from="$1"
    local to="$2"

    case "${from}:${to}" in
        proposed:approved)    echo "minor" ;;  # 승인 = 기능 확정
        approved:in_progress) echo "patch" ;;  # 구현 시작
        in_progress:implemented) echo "patch" ;;  # 구현 완료
        implemented:verified) echo "patch" ;;  # 검증 완료
        approved:changed)     echo "patch" ;;  # 사소한 변경
        implemented:changed)  echo "patch" ;;  # 사소한 변경
        changed:in_progress)  echo "patch" ;;  # 변경 구현
        verified:deprecated)  echo "patch" ;;  # deprecated
        deprecated:proposed)  echo "major" ;;  # 대대적 재설계
        *)                    echo "patch" ;;  # 기본값
    esac
}

# ──────────────────────────────────────────────────────
# get_changelog_type <from-status> <to-status>
# 상태 전이에 따른 CHANGELOG 유형 반환
# ──────────────────────────────────────────────────────
get_changelog_type() {
    local from="$1"
    local to="$2"

    case "${from}:${to}" in
        proposed:approved)    echo "Added" ;;
        approved:in_progress) echo "Changed" ;;
        in_progress:implemented) echo "Changed" ;;
        implemented:verified) echo "Fixed" ;;
        *:changed)            echo "Changed" ;;
        verified:deprecated)  echo "Deprecated" ;;
        deprecated:proposed)  echo "Changed" ;;
        *)                    echo "Changed" ;;
    esac
}

# ──────────────────────────────────────────────────────
# is_breaking_change <from-status> <to-status>
# Breaking change 여부 확인 (ADR 필수)
# ──────────────────────────────────────────────────────
is_breaking_change() {
    local level
    level=$(get_version_bump_level "$1" "$2")
    [[ "$level" == "major" ]]
}

# ──────────────────────────────────────────────────────
# update_spec_version <spec-file> <new-version> <summary>
# spec 파일의 버전과 version_history 갱신
# ──────────────────────────────────────────────────────
update_spec_version() {
    local spec_file="$1"
    local new_version="$2"
    local summary="$3"
    local date_today
    date_today=$(date +%Y-%m-%d)
    local current_status
    current_status=$(grep -E '^status:' "$spec_file" | head -1 | awk '{print $2}')

    # 현재 버전 읽기 (v 접두사 있음/없음 모두 지원)
    local current_version
    current_version=$(grep -E "^version:" "$spec_file" | head -1 | awk '{print $2}')
    current_version="${current_version#v}"

    # 버전 필드 갱신
    sed -i "s/^version: .*/version: ${new_version}/" "$spec_file"

    # version_history가 없으면 추가
    if ! grep -q "^version_history:" "$spec_file"; then
        # status 줄 다음에 version_history 블록 삽입
        sed -i "/^status:/a\\
version_history:\\
  - version: ${new_version}\\
    date: ${date_today}\\
    status: ${current_status}\\
    summary: \"${summary}\"" "$spec_file"
    else
        # 같은 버전의 entry가 이미 있으면 중복 추가 방지
        # (version_history 내의 들여쓰기된 "- version:" 패턴만 탐색)
        if grep -q "  - version: ${new_version}$" "$spec_file"; then
            # 같은 버전 entry가 이미 존재하면 스킵
            true
        else
            # version_history 다음 줄에 새 entry 추가
            sed -i "/^version_history:/a\\
  - version: ${new_version}\\
    date: ${date_today}\\
    status: ${current_status}\\
    summary: \"${summary}\"" "$spec_file"
        fi
    fi

    # updated 날짜 갱신
    sed -i "s/^updated: .*/updated: ${date_today}/" "$spec_file"
}

# ──────────────────────────────────────────────────────
# extract_diff_sections <spec-file>
# spec 파일에서 변경된 섹션명 추출
# ──────────────────────────────────────────────────────
extract_diff_sections() {
    local spec_file="$1"
    # git diff로 변경된 라인 추출 (git 저장소 내여야 함)
    if git -C "$(dirname "$spec_file")" diff --name-only HEAD -- "$spec_file" >/dev/null 2>&1; then
        git -C "$(dirname "$spec_file")" diff HEAD -- "$spec_file" 2>/dev/null | \
            grep -E "^[\+\-]##" | \
            sed 's/^[\+\-]##* //' | \
            sort -u || true
    fi
}
