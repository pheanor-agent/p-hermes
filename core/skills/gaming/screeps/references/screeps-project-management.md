# Screeps Project Management Workflow

**Session:** JOB-1461 (2026-06-02)
**Room:** E13S29 (SHARD0, Owner: Pheanor)

## Project Setup Workflow

When user requests to manage a Screeps game as a project:

### 1. Create JOB
```bash
bash ~/.hermes/scripts/create-job.sh -y 기능 "Screeps 프로젝트 생성 및 관리 - <room> 룸 설정, 코드 최적화"
```
- Use `-y` flag for non-interactive mode
- Use Korean job type: `기능` (feature)

### 2. Create Project
```bash
bash ~/.hermes/scripts/create-project.sh screeps "Screeps 게임 프로젝트" --job-id JOB-XXXX
```
- Links project to JOB for tracking
- Creates metadata and code directories

### 3. Directory Structure
```
~/.hermes/knowledge/projects/screeps/
├── project.yaml      # Metadata with room_info
├── context.md        # Current status summary
├── decisions.md      # Decision history
└── timeline.md       # Project timeline

~/.hermes/workspace/projects/screeps/
├── src/
│   └── main.js       # Game code
├── data/             # Game state data
└── docs/             # Documentation
```

## Room Metadata Structure (project.yaml)

```yaml
room_info:
  shard: SHARD0
  room: E13S29
  owner: Pheanor
  respawn_days: 35
  safe_mode_ticks: 19990
  structures:
    - Spawn1
  terrain: plains_with_obstacles
```

## Safe Mode Awareness

**Critical:** Safe mode protects from attacks. Track ticks remaining:
- 19990 ticks = ~28 days (at 1.5s/tick)
- "거의 종료" (almost expired) when <20000 ticks
- When safe mode ends, room becomes vulnerable to attacks

**Action:** When safe mode is expiring soon, prioritize:
1. Building defense structures (towers, walls)
2. Increasing controller level for more structure capacity
3. Preparing for potential invasions

## Initial Code Analysis Checklist

When receiving user's Screeps code:

1. **Check room target** - Does code match actual room? (common mismatch)
2. **Check safe mode status** - Is defense needed soon?
3. **Check source utilization** - Using all sources or just one?
4. **Check creep naming** - Will names conflict with existing creeps?
5. **Check body optimization** - Is [WORK, CARRY, MOVE] optimal for controller level?

## Context.md Template

```markdown
# 현재 상태 요약

**프로젝트**: Screeps 게임 프로젝트
**상태**: active
**생성일**: YYYY-MM-DD

## 기본 정보
- **룸**: E13S29 (SHARD0)
- **오너**: Pheanor
- **Respawn**: 35일 남음
- **Safe mode**: 19990 ticks

## 현재 코드
- `src/main.js`: [summary]
- 타겟 룸: E13S29
- 크립 바디: [WORK, CARRY, MOVE]
- 최대 크립: N마리

## 개선 필요사항
1. [item]
2. [item]
```

## Decisions.md Template

```markdown
# 결정 이력

## YYYY-MM-DD
- **룸 선택**: E13S29 (SHARD0)로 프로젝트 설정
  - 이유: [reason]
- **코드 구조**: [structure]
  - 패턴: [pattern]
```

## Lessons

1. **Always verify room in code matches user's screenshot** - W8S26 vs E13S29 mismatch was caught visually
2. **Safe mode is a ticking clock** - Track remaining ticks and plan defense accordingly
3. **Project metadata enables quick resumption** - Context.md and room_info let future sessions start immediately
4. **Use `-y` flag on create-job.sh** - Interactive mode fails in non-interactive sessions
