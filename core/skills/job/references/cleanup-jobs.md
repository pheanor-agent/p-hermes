# Job Cleanup Script

Python script for consolidating and archiving job directories.

## Usage

```python
# Run in ~/.hermes/workspace/jobs context
python3 cleanup_jobs.py
```

## Features

1. **Duplicate Consolidation**: Groups JOB-XXX folders and keeps the canonical one
2. **Active Job Protection**: Restores jobs with `running`, `investigation`, `execution`, `review` status from duplicates
3. **Status-Based Archiving**: Moves completed/cancelled/superseded jobs to appropriate archive subdirectories

## Archive Structure

```
archive/
├── legacy/        # JOB-200~900 series (old system)
├── completed/     # status: 9-done, completed, done
├── cancelled/     # status: 9-cancelled, cancelled
├── superseded/    # status: 9-superseded
└── duplicates/    # Duplicate folders (after consolidation)
```

## Canonical Folder Selection Logic

When multiple folders exist for the same JOB-XXX:
1. Prefer folders with `.workflow-state` file
2. Prefer folders with non-empty status/step fields
3. Prefer folders with descriptive names (JOB-XXX-Description > JOB-XXX)
4. Prefer folders with newer modification time
5. **Never archive** folders with active status (`running`, `investigation`, `design`, `execution`, `review`)

## Safety Notes

- Always verify active jobs after cleanup
- Check `archive/duplicates/` for any mistakenly archived active jobs
- Restore from duplicates if needed before proceeding

## Example Output

```
RESTORED: JOB-1131-Bridge-Adapter-포트-개방-및-Gateway-플랫폼-등록 (Status: , Step: execution)
RESTORED: JOB-1108-Blackboard+Wiki-동기화-구조-구축 (Status: , Step: investigation)
Archived 26 completed/cancelled/superseded jobs.
```
