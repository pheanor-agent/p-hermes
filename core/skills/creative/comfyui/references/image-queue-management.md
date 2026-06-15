# 이미지 생성 큐 관리 스크립트 (image-queue.sh)

## 용도

Hermes 이미지 생성 큐 (`~/.shared/queue/images/pending.json`) 관리.

## 기능

- `add`: 새 작업 큐에 추가
- `next`: 다음 pending 작업 가져오기
- `complete`: 작업 완료 표시
- `fail`: 작업 실패 표시
- `list`: 큐 상태 조회
- `lock`: flock 기반 동시성 제어

## 사용법

```bash
# 새 작업 추가
bash ~/.shared/scripts/image-queue.sh add \
  --project-id "blood-bind" \
  --scene-id "ep005" \
  --prompt "A warrior standing on a cliff" \
  --source-channel "telegram:-3975653825:219"

# 다음 작업 가져오기
bash ~/.shared/scripts/image-queue.sh next

# 작업 완료
bash ~/.shared/scripts/image-queue.sh complete --entry-id "e20260524123456789"

# 큐 상태 조회
bash ~/.shared/scripts/image-queue.sh list --status pending
```

## 큐 엔트리 구조

```json
{
  "id": "e20260524123456789",
  "projectId": "blood-bind",
  "sceneId": "ep005",
  "loraId": "none",
  "sourceChannel": "telegram:-3975653825:219",
  "sourceUser": "pheanor",
  "priority": 2,
  "status": "pending",
  "attempts": 0,
  "maxAttempts": 3,
  "createdAt": "2026-05-24T12:34:56+09:00",
  "startedAt": null,
  "completedAt": null,
  "error": null,
  "metadata": {
    "prompt": "A warrior standing on a cliff",
    "resolution": "1024x1024"
  }
}
```

## 상태 전환

```
pending → claimed → processing → completed
                                 → failed_archive
```

## TTL 자동 롤백

- 15 분 TTL 초과 시 자동 롤백 (pending 상태 복원)
- `queue.lock` 파일에서 flock 기반 동시성 제어

---

**참조**: `references/runpod-comfyui-integration.md` § 대기 큐 구조