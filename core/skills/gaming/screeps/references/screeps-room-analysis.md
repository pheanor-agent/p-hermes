# Screeps World Room Analysis Workflow

## Coordinate System

**Format:** `WxWy` or `WxWz`
- `W` = West (X-axis, increases East)
- `N` = North (Y-axis negative)
- `S` = South (Y-axis positive)

**Examples:**
- W8S25: X=8, Y=25
- W11S27: X=11, Y=27
- W8N34: X=8, Y=-34

**Distance Calculation:**
```
distance = |x2 - x1| + |y2 - y1|
W8S25 → W11S27: |11-8| + |27-25| = 3 + 2 = 5 rooms
W8S25 → W8N34: |8-8| + |25-(-34)| = 0 + 59 = 59 rooms
```

## Room Selection Checklist

### Priority 1: Safe Mode Duration
- ✅ 30+ days: Ideal starting room
- ⚠️ 10-30 days: Acceptable with backup plan
- ❌ <10 days: High competition risk

### Priority 2: Owner Status
- `Owner: None`: Immediate start possible
- `Owner: <player>`: Cannot start here (unless attacking)

### Priority 3: Resource Density
- 2 sources: High value (W8S24, W9S24 pattern)
- 1 source: Standard
- 0 sources: Noob room (avoid for automation)

### Priority 4: Expansion Potential
- Adjacent rooms with Safe Mode: Safe expansion path
- Noob rooms nearby: Low value targets
- Owned rooms nearby: Competition risk

## Vision Analysis Limitations

### What Static Maps Show
- ✅ Terrain (walls, obstacles)
- ⚠️ Sources (yellow dots) — **UNRELIABLE for counting** (low resolution, visual artifacts)
- ✅ Room borders
- ✅ Grid structure

### What Static Maps Do NOT Show
- ❌ Safe Mode duration
- ❌ Owner names
- ❌ Noob room status
- ❌ Dynamic game state
- ❌ **Accurate source count** (terrain dots ≠ confirmed energy sources)

**Critical Lesson (JOB-1349):** Terrain map screenshots consistently miscount sources. Yellow dots may be visual artifacts, not actual energy sources. **Always verify source count via game UI.**

**Workaround:** Request tooltip screenshots for each candidate room + in-game visual confirmation.

## Room Analysis Template

```
Room: W8S25
├── Safe Mode: [days]
├── Owner: [None/PlayerName]
├── Sources: [count]
├── Terrain: [wall density]
└── Adjacent:
    ├── W7S25: [summary]
    ├── W9S25: [summary]
    ├── W8S24: [summary]
    └── W8S26: [summary]
```

## Session Notes (JOB-1349)

- Initial room candidate: W11S27 (Safe Mode 11일) → misread from tooltip as W115Z7
- Revised room: W8S25 (surrounding 3x3 analysis needed) → user clarification
- Final room: W8S24 (Safe Mode 35일, source 1개)
- **Source count error**: Terrain map showed 2 sources for W8S24, but game UI confirmed only 1
- **Coordinate confusion chain**: W115Z7 → W11S27 → W8N34 → W8S25 → W8S24
- User preference: Game-specific architecture, not generic code
- Expansion direction: Adjacent rooms first (1 room distance), not distant targets (64 rooms)
- **Key lesson**: Trust game UI over screenshot analysis for source counts, Safe Mode timers, and ownership

## Expansion Strategy

### Phase 1: Foundation (Stage 0-1)
- Start in high Safe Mode room (30+ days)
- Build basic infrastructure (spawn, harvester, builder)

### Phase 2: Fortification (Stage 2-3)
- Upgrade controller to level 3+
- Build defense structures (tower, wall)

### Phase 3: Adjacent Expansion (Stage 4)
- Target rooms within 1-2 distance
- Prioritize Safe Mode rooms for safe expansion

### Phase 4: Distant Expansion (Stage 5)
- Target rooms 5+ rooms away
- Requires multi-room logistics (terminal, container network)
