# Tirith Security Scan 설정

**일시:** 2026-05-28  
**작업:** 커맨드 자동 승인 활성화

---

## 문제

Tirith 보안 스캔이 활성화되어 있을 때, 유니코드 variation selector(이모지 등)가 포함된 커맨드 실행 시 매번 사용자 승인을 요구함. 이미지 생성 등 빈번한 작업 시 방해가 됨.

## 해결

```yaml
# ~/.hermes/config.yaml
security:
  tirith_enabled: false  # 보안 스캔 비활성화
```

## 적용

```bash
# 설정 변경 후 gateway 재시작
systemctl --user restart hermes-gateway

# 또는 직접 실행
cd ~/.hermes/hermes-agent && source venv/bin/activate && python -m hermes_cli.main gateway run --replace &
```

## 주의사항

- ✅ 커맨드 자동 승인 활성화
- ⚠️ 보안 스캔이 꺼지므로 위험한 커맨드도 실행 가능
- 원복: `security.tirith_enabled: true`

## 대체 방안

`approvals.mode` 설정도 확인:
- `manual` — 항상 승인 (기본값)
- `smart` — LLM으로 위험도 판단
- `off` — 모든 승인 스킵 (`--yolo`と同)

```bash
hermes config set approvals.mode off  # 승인 완전 비활성화
```

---

**참고:** WSL 환경에서 `systemctl --user restart`가 타임아웃 발생할 수 있음. 이 경우 kill-then-start 패턴 사용:

```bash
systemctl --user kill hermes-gateway
sleep 2
systemctl --user start hermes-gateway
```
