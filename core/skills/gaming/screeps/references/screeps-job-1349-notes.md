# JOB-1349: Screeps World Debug Session Notes

**Date:** 2026-05-25  
**Room:** W8S26 (Safe Mode 35일, Source 2개)  
**Issue:** Creeps not moving/harvesting, module errors, energy management

---

## Key Discoverings

### 1. Screeps World API Incompatibilities

| API | Screeps Classic | Screeps World | Notes |
|-----|----------------|---------------|-------|
| `pos.isAdjacentTo()` | ✅ Supported | ❌ Not found | Use `pos.getRangeTo() <= 1` |
| `require('./module')` | ✅ Supported | ❌ Not supported (free) | Single file only |
| `pos.inRangeTo(target, 1)` | ✅ Works | ⚠️ Use with care | `getRangeTo()` more reliable |

### 2. Error -6 (ERR_NOT_ENOUGH_ENERGY) Patterns

**Scenario 1: Spawn failure**
```
[SPAWN] ❌ creep2 failed: -6
```
- **Cause:** `spawn.store[RESOURCE_ENERGY] < 100`
- **Fix:** Check energy before spawn + reduce max creeps

**Scenario 2: Upgrade failure**
```
[name] ❌ Upgrade failed: -6 (dist:1)
```
- **Cause:** Creep has 0 energy but tries to upgrade
- **Fix:** Explicit `energy === 0` check → force move to source

### 3. Creep Idle at 0⚡ Root Cause

**Symptom:** Creep stuck at controller with 0 energy, not harvesting

**Original buggy code:**
```javascript
if (energy < capacity) {
    // Harvest logic - BUT creep may be at controller!
    if (pos.getRangeTo(source) > 1) {
        creep.moveTo(source);
    }
}
```

**Problem:** When `energy === 0`, creep still tries to check distances and may not move properly

**Fix:**
```javascript
if (energy === 0) {
    creep.moveTo(sources[0]);  // Force move
    continue;                   // Skip all other logic
}
```

### 4. Log Interval Confusion

**User expectation:** "40초마다 로그"  
**My initial code:** `Game.time % 100 === 0`  
**Problem:** 
- 1 tick = 1.5 seconds (not 1 second)
- 100 ticks = 150 seconds (2.5 minutes, not 40 seconds!)
- `% 100` can fire multiple times if loop runs multiple times per tick

**Correct approach:**
```javascript
let lastLog = 0;
if (Game.time - lastLog >= 27) {  // 27 ticks = 40 seconds
    console.log('...');
    lastLog = Game.time;
}
```

### 5. Debug Logging That Actually Helps

**Minimal logs:** Just status every 100 ticks  
**Effective logs:** Include coordinates + distances + error codes

```javascript
// ✅ Good: Includes all diagnostic info
console.log(`[${name}] ❌ moveTo failed: ${result} (pos:${pos.x},${pos.y} target:${source.pos.x},${source.pos.y} dist:${pos.getRangeTo(source)})`);

// ❌ Bad: Not enough info to diagnose
console.log(`[${name}] Failed to move`);
```

---

## Final Working Code Pattern (v1.2)

```javascript
let lastLog = 0;
let lastSpawn = 0;

module.exports.loop = function() {
    const room = Game.rooms['W8S26'];
    if (!room) return;

    const spawn = room.find(FIND_MY_STRUCTURES, { filter: s => s.structureType === STRUCTURE_SPAWN })[0];
    const controller = room.controller;
    const sources = room.find(FIND_SOURCES);

    if (!spawn || !controller || !sources.length) return;

    // Spawn creeps (max 2, energy 100⚡ needed)
    if (Game.time - lastSpawn > 100 && Object.keys(Game.creeps).length < 2 && spawn.store[RESOURCE_ENERGY] >= 100) {
        spawn.spawnCreep([WORK, CARRY, MOVE], 'creep' + Object.keys(Game.creeps).length);
        lastSpawn = Game.time;
    }

    // Creep behavior
    for (const name in Game.creeps) {
        const creep = Game.creeps[name];
        const energy = creep.store[RESOURCE_ENERGY];
        const pos = creep.pos;

        // CRITICAL: Force move when energy depleted
        if (energy === 0) {
            creep.moveTo(sources[0]);
            continue;
        }

        // Harvest mode
        if (energy < creep.store.getCapacity() / 2) {
            if (pos.getRangeTo(sources[0]) > 1) {
                creep.moveTo(sources[0]);
            } else {
                creep.harvest(sources[0]);
            }
        }
        // Upgrade mode
        else {
            if (pos.getRangeTo(controller) > 3) {
                creep.moveTo(controller);
            } else {
                creep.upgradeController(controller);
            }
        }
    }

    // Status log every 20 ticks (30 seconds)
    if (Game.time - lastLog >= 20) {
        let creepInfo = [];
        for (const name in Game.creeps) {
            const c = Game.creeps[name];
            creepInfo.push(`${name}:${c.store[RESOURCE_ENERGY]}⚡@${c.pos.x},${c.pos.y}`);
        }
        console.log(`[STATUS] T:${Game.time} | Spawn:${spawn.store[RESOURCE_ENERGY]}⚡ | Ctrl:${controller.level}@${controller.pos.x},${controller.pos.y} | Source:${sources[0].pos.x},${sources[0].pos.y} | Creeps:[${creepInfo.join(',')}]`);
        lastLog = Game.time;
    }
};
```

---

## Lessons for Future Screeps Sessions

1. **Always assume single-file requirement** for Screeps World (free version)
2. **Use `getRangeTo()`** for all distance checks - NOT `isAdjacentTo()`
3. **Explicit `energy === 0` handling** prevents idle creeps
4. **Log interval = ticks × 1.5 seconds** - clarify with user
5. **Include coordinates in logs** - essential for debugging movement issues
6. **Check ALL preconditions** before actions (spawn energy, creep energy, distance)
7. **Static variables for timing** (`lastLog`, `lastSpawn`) - more reliable than `% N`
