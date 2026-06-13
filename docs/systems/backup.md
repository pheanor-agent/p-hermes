# Backup System

Hermes 시스템의 데이터 백업 및 복구 시스템입니다.

---

## Overview

| 항목 | 값 |
|------|-----|
| 경로 | `~/.hermes/backups/` |
| Tier 1 (Hot) | 24시간 보존 |
| Tier 2 (Warm) | 7일 보존 |
| 트리거 | 수동 + 자동 (파일 삭제 전) |

---

## 디렉토리 구조

```
~/.hermes/backups/
├── tier1/                    # Hot (24h) — 빠른 복구용
│   ├── 2026-06-13-0000.tar.gz
│   ├── 2026-06-13-0600.tar.gz
│   └── ...
└── tier2/                    # Warm (7d) — 장기 보관
    ├── 2026-06-13-0000.tar.gz
    └── ...
```

---

## 백업 계층 (Tier)

### Tier 1 — Hot (24시간)

| 항목 | 값 |
|------|-----|
| 보존 기간 | 24시간 |
| 빈도 | 주기적 (crontab 기반) |
| 목적 | 빠른 복구 |
| 스크립트 | `tier1-backup.sh` |

Tier 1 백업은 최근 데이터를 빠르게 복구하기 위한 것입니다.

### Tier 2 — Warm (7일)

| 항목 | 값 |
|------|-----|
| 보존 기간 | 7일 |
| 빈도 | 일일 |
| 목적 | 장기 보관 |
| 스크립트 | `tier2-backup.sh` |

Tier 2 백업은 장기 보관 및 이력 추적을 위한 것입니다.

---

## 백업 스크립트

### tier1-backup.sh

```bash
#!/bin/bash
# Tier 1 백업 (Hot, 24h)
# 사용법: bash tier1-backup.sh

TIMESTAMP=$(date +%Y-%m-%d-%H%M)
BACKUP_DIR="$HOME/.hermes/backups/tier1"

mkdir -p "$BACKUP_DIR"

tar -czf "$BACKUP_DIR/$TIMESTAMP.tar.gz" \
    --exclude='backups' \
    --exclude='cache' \
    --exclude='history' \
    -C "$HOME/.hermes" .

# 24시간 이전 파일 정리
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +1 -delete

echo "✅ Tier 1 백업: $BACKUP_DIR/$TIMESTAMP.tar.gz"
```

### tier2-backup.sh

```bash
#!/bin/bash
# Tier 2 백업 (Warm, 7d)
# 사용법: bash tier2-backup.sh

TIMESTAMP=$(date +%Y-%m-%d)
BACKUP_DIR="$HOME/.hermes/backups/tier2"

mkdir -p "$BACKUP_DIR"

tar -czf "$BACKUP_DIR/$TIMESTAMP.tar.gz" \
    --exclude='backups' \
    --exclude='cache' \
    -C "$HOME/.hermes" .

# 7일 이전 파일 정리
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete

echo "✅ Tier 2 백업: $BACKUP_DIR/$TIMESTAMP.tar.gz"
```

---

## 사전 백업 (Pre-Delete Backup)

10개 이상의 파일을 삭제하기 전에 자동으로 백업합니다.

### `pre-delete-backup.sh`

```bash
#!/bin/bash
# 파일 삭제 전 백업
# 10개 이상 파일 삭제 시 자동 트리거

FILE_COUNT=${1:-0}

if [ "$FILE_COUNT" -ge 10 ]; then
    TIMESTAMP=$(date +%Y-%m-%d-%H%M%S)
    BACKUP_DIR="$HOME/.hermes/backups/tier1"
    mkdir -p "$BACKUP_DIR"
    
    echo "⚠️ $FILE_COUNT개 파일 삭제 감지 — 자동 백업 실행"
    tar -czf "$BACKUP_DIR/pre-delete-$TIMESTAMP.tar.gz" "$@"
    echo "✅ 사전 백업: $BACKUP_DIR/pre-delete-$TIMESTAMP.tar.gz"
fi
```

---

## 복구

### restore.sh

```bash
#!/bin/bash
# 백업 복구
# 사용법: restore.sh <backup-file.tar.gz>

BACKUP_FILE="${1:?백업 파일 경로 필수}"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ 파일 없음: $BACKUP_FILE"
    exit 1
fi

# 현재 상태 백업
TIMESTAMP=$(date +%Y-%m-%d-%H%M)
mkdir -p "$HOME/.hermes/backups/tier1"
tar -czf "$HOME/.hermes/backups/tier1/pre-restore-$TIMESTAMP.tar.gz" -C "$HOME/.hermes" .

# 복구
tar -xzf "$BACKUP_FILE" -C "$HOME/.hermes/"

echo "✅ 복구 완료: $BACKUP_FILE"
```

---

## Cron 연동

백업 시스템은 Cron 시스템과 연동됩니다.

| Cron 작업 | 백업 역할 |
|-----------|----------|
| `tier1-backup.sh` | Tier 1 정기 백업 |
| `tier2-backup.sh` | Tier 2 일일 백업 |
| 자동화 | crontab 기반 실행 |

---

## 참조

- [ARCHITECTURE.md](../ARCHITECTURE.md) — 전체 아키텍처
- [docs/systems/overview.md](overview.md) — 시스템 종합
- [docs/systems/cron.md](cron.md) — Cron 연동
