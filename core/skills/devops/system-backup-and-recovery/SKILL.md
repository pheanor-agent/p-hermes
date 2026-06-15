---
name: system-backup-and-recovery
description: Strategy and implementation for preserving Hermes/OpenClaw core assets with multi-tiered recovery options.
---

# System Backup & Recovery

This skill defines the standards for protecting Hermes' core intelligence and user assets, ensuring that accidental deletions or system failures do not result in permanent data loss.

## 🎯 Core Asset Scope
Only high-value, durable assets are targeted for backup to optimize storage and performance:
- **Work History**: `~/.hermes/workspace/jobs/` (Critical - all results, lessons, and process logs)
- **Project Assets**: `~/.hermes/workspace/projects/` (Critical - Spec-driven code and documentation)
- **Intelligence**: `~/.hermes/skills/`, `~/.hermes/knowledge/` (High - procedural and declarative knowledge)
- **Configuration**: `~/.hermes/profiles/`, `config.yaml` (High - system identity and model settings)

**Excluded**: Runtime states, temporary caches.

## 🛠️ Multi-Tiered Strategy (3-2-1 Rule)
Adheres to the industry standard: **3** copies of data, **2** different media, **1** off-site copy.

### Tier 1: Local Fast Snapshot (RPO: 4h)
- **Tool**: `Restic` (Content-Addressable Storage/Deduplication).
- **Logic**: Fast, encrypted snapshots with high efficiency for small files (JSON/MD).
- **Retention**: Keep last 24 snapshots (approx. 1 day).
- **Use Case**: Rapid, selective recovery of accidentally deleted files.

### Tier 2: Warm Archive (RPO: Daily)
- **Tool**: `Restic` $\rightarrow$ Compressed encrypted bundle.
- **Logic**: Daily consolidated snapshots with deduplication.
- **Retention**: 7 daily, 4 weekly.
- **Use Case**: Rolling back the system to a known stable state from a previous day.

### Tier 3: Cold Storage (Disaster Recovery)
- **Tool**: Encrypted mirror to Cloud Object Storage (S3, B2, Azure).
- **Logic**: Weekly off-site synchronization.
- **Use Case**: Full system reconstruction after total host/disk failure.

## 📋 Implementation Workflow

1. **Initialization**:
   - Establish a backup root (e.g., `~/.hermes/backups/`).
   - Configure Restic repository on the Linux root (ext4) to avoid WSL2 9P protocol bottlenecks.
2. **Execution**:
   - Implement a `backup-lock` mechanism to prevent "torn reads" (backing up while the agent is writing).
   - Trigger backups via cron (Tier 1: 4h, Tier 2: Daily).
3. **Management**:
   - Use CLI wrapper (e.g., `hermes-backup.sh`) for `list`, `now`, `restore`, and `audit`.
4. **Verification (Recovery Audit)**:
   - **Canary Testing**: Regularly verify the existence of a unique canary file.
   - **Randomized Restore**: Weekly automated restoration of 5-10 random files to verify checksums.

## ⚠️ Pitfalls & Lessons
- **WSL2 Bottleneck**: NEVER backup directly to `/mnt/c/` for many small files. Perform all operations on the Linux root and only sync the final encrypted repository.
- **Atomicity**: Always use lock-files or `flock` to ensure the agent is not writing to a file during its snapshot.
- **Symmetry**: Ensure the restore path maps correctly back to the workspace.
- **Validation**: A backup is a liability until it is proven restoreable. Automate recovery testing.

See `references/backup-recovery-standards.md` for detailed industry standards (RPO/RTO, CAS).
