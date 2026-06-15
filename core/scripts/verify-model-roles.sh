#!/bin/bash
# model-roles.yaml 검증 스크립트
# 사용법: bash verify-model-roles.sh

ROLES_FILE="$HOME/.hermes/core/skills/shared/model-roles.yaml"

echo "✅ model-roles.yaml 검증 시작..."

if [[ ! -f "$ROLES_FILE" ]]; then
  echo "❌ 파일 없음: $ROLES_FILE"
  exit 1
fi

# 1. 프로바이더 유효성 검사
providers=$(grep 'valid_providers' "$ROLES_FILE" | sed 's/.*\[//;s/\].*//')
if [[ -z "$providers" ]]; then
  echo "❌ valid_providers 정의 없음"
  exit 1
fi

# 2. 모델 참조 검증 (roles 섹션)
in_roles=false
while IFS= read -r line; do
  if [[ "$line" == "roles:" ]]; then
    in_roles=true
    continue
  fi
  if [[ "$in_roles" == true ]] && [[ "$line" =~ ^[a-z] ]]; then
    in_roles=false
    continue
  fi
  if [[ "$in_roles" == true ]] && [[ "$line" =~ ^[[:space:]]+ ]]; then
    provider=$(echo "$line" | awk '{print $2}' | cut -d'/' -f1)
    if [[ -n "$provider" ]] && ! echo "$providers" | grep -q "$provider"; then
      echo "❌ 유효하지 않은 프로바이더: $provider (허용: $providers)"
      exit 1
    fi
  fi
done < "$ROLES_FILE"

echo "✅ 검증 완료"
exit 0
