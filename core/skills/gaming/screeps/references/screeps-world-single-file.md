# Screeps World Single-File Patterns

**Session:** JOB-1349 (2026-05-25)
**Room:** W8S26 (Source: 2, Safe Mode: 35일)

## Problem: No Module Support

Screeps World (무료 버전) does NOT support:
- `require()` statements
- Folder structures (`stages/`, `roles/`)
- Multi-file modules

**Solution:** All code in single `main.js` file with inline functions.

## Working Code Pattern

```javascript
module.exports.loop = function() {
    const room = Game.rooms['W8S26'];
    if (!room) return;

    const spawn = room.find(FIND_MY_STRUCTURES, { filter: s => s.structureType === STRUCTURE_SPAWN })[0];
    const controller = room.controller;  // Direct access
    const sources = room.find(FIND_SOURCES);

    if (!spawn || !controller || !sources.length) return;

    // Spawn creeps (energy check!)
    const creepCount = Object.keys(Game.creeps).length;
    if (creepCount < 2 && spawn.store[RESOURCE_ENERGY] >= 100) {
        spawn.spawnCreep([WORK, CARRY, MOVE], 'creep' + creepCount);
    }

    // Creep behavior
    for (const name in Game.creeps) {
        const creep = Game.creeps[name];
        const energy = creep.store[RESOURCE_ENERGY];
        const pos = creep.pos;

        // Build if construction sites exist
        const sites = room.find(FIND_CONSTRUCTION_SITES);
        if (energy > 0 && sites.length > 0) {
            creep.moveTo(sites[0]);
            if (pos.inRangeTo(sites[0], 1)) creep.build(sites[0]);
            continue;
        }

        // Harvest or upgrade based on energy
        if (energy < creep.store.getCapacity()) {
            creep.moveTo(sources[0]);
            if (pos.getRangeTo(sources[0]) <= 1) creep.harvest(sources[0]);
        } else {
            creep.moveTo(controller);
            if (pos.getRangeTo(controller) <= 3) creep.upgradeController(controller);
        }
    }
};
```

## Key API Patterns

### Room Controller Access
```javascript
// ✅ Correct - direct property
const controller = room.controller;

// ❌ Wrong - find() may not work consistently
const controller = room.find(FIND_STRUCTURES, { filter: s => s.structureType === STRUCTURE_CONTROLLER })[0];
```

### Harvest Requires Adjacency
```javascript
// ✅ Screeps World: use getRangeTo() instead of isAdjacentTo()
if (pos.getRangeTo(source) <= 1) {
    creep.harvest(source);
}

// ❌ isAdjacentTo() may not work on Screeps World free version
if (pos.isAdjacentTo(source)) {
    creep.harvest(source);  // May fail
}

// ❌ inRangeTo(1) is not the same as adjacency
if (pos.inRangeTo(source, 1)) {
    creep.harvest(source);  // May fail with ERR_NOT_IN_RANGE
}
```

### Energy Check Before Spawn
```javascript
// ✅ Correct - check energy first
if (spawn.store[RESOURCE_ENERGY] >= 100) {
    spawn.spawnCreep([WORK, CARRY, MOVE], name);
}

// ❌ Wrong - spawns fail silently with ERR_NOT_ENOUGH_ENERGY
spawn.spawnCreep([WORK, CARRY, MOVE], name);
```

## Error Codes

| Code | Meaning | Fix |
|------|---------|-----|
| -6 | ERR_NOT_ENOUGH_ENERGY | Check `spawn.store[RESOURCE_ENERGY] >= 100` |
| -7 | ERR_NOT_IN_RANGE | Use `isAdjacentTo()` for harvest/transfer |
| -12 | ERR_NAME_EXISTS | Use unique creep names |
| -22 | ERR_INVALID_TARGET | Verify target exists before action |

## Debug Logging Pattern

```javascript
// Status every 100 ticks
if (Game.time % 100 === 0) {
    console.log(`[STATUS] Time: ${Game.time} | Spawn: ${spawn.store[RESOURCE_ENERGY]}⚡ | Controller: ${controller.level}`);
}

// Creep position every 25 ticks
if (Game.time % 25 === 0) {
    console.log(`[${name}] Pos: ${pos.x},${pos.y} | Energy: ${energy} | Near: ${pos.inRangeTo(sources[0], 3) ? 'Source' : 'None'}`);
}
```

## Lessons Learned

1. **No folders in free version** — inline everything
2. **Energy check mandatory** — spawn fails with -6 without it
3. **isAdjacentTo() for harvest** — inRangeTo(1) not sufficient
4. **Separate move logic** — energy state determines target (source vs controller)
5. **Direct room.controller access** — more reliable than find()
