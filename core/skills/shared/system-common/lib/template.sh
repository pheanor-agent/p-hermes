#!/bin/bash
# system-common/lib/template.sh
# 듀얼 엔진 템플릿 처리 (envsubst / Jinja2 자동 분기)
#
# 사용법:
#   source ~/.hermes/skills/shared/system-common/lib/template.sh
#   template_render "input.md" '{"name": "test"}' "output.md"

JINJA_RENDERER="${HERMES_JINJA_RENDERER:-$HOME/.hermes/skills/shared/template-engine/engine/jinja_renderer.py}"

# 템플릿 렌더링 (복잡도에 따라 엔진 자동 분기)
template_render() {
    local template_path="$1"
    local context_json="$2"
    local output_path="$3"

    if [[ ! -f "$template_path" ]]; then
        echo "[ERROR] template_render: 템플릿 파일 없음 (${template_path})" >&2
        return 1
    fi

    # Jinja2 제어문 ({% 또는 {{ ) 패턴 존재 여부 검사
    if grep -qE '\{%|\{\{' "$template_path" 2>/dev/null; then
        # 복잡한 템플릿: Jinja2 엔진 호출
        if [[ -f "$JINJA_RENDERER" ]]; then
            python3 "$JINJA_RENDERER" "$template_path" "$context_json" > "$output_path"
            return $?
        else
            echo "[WARN] template_render: Jinja2 엔진 없음, envsubst 폴백" >&2
            _render_envsubst "$template_path" "$context_json" "$output_path"
            return $?
        fi
    else
        # 단순 템플릿: envsubst 초고속 처리
        _render_envsubst "$template_path" "$context_json" "$output_path"
        return $?
    fi
}

# envsubst 기반 단순 렌더링
_render_envsubst() {
    local template_path="$1"
    local context_json="$2"
    local output_path="$3"

    # JSON을 환경 변수로 변환하여 export
    export $(echo "$context_json" | jq -r 'to_entries|map("\(.key)=\(.value|tostring)")|.[]' 2>/dev/null)

    envsubst < "$template_path" > "$output_path"
    return $?
}
