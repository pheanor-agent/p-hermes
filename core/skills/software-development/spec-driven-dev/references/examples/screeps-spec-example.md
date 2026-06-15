# Screeps Spec 사례

## 배경
Screeps MMO 게임 봇 프로젝트. E13S29 룸 운영.

## Spec 예시
```yaml
id: SPEC-C001
type: component
title: 에너지 수확
status: approved

examples:
  - name: "충분한 에너지"
    input: { energy: 500, creep: "harvester1" }
    expected: { body: [WORK:3, CARRY:2, MOVE:3] }
  - name: "부족한 에너지"
    input: { energy: 50, creep: "harvester1" }
    expected: { body: [MOVE:1] }

contract:
  preconditions:
    - "energy >= 0"
    - "creep exists"
  postconditions:
    - "body cost <= energy"
    - "creep created or error"
```

## 코드 생성
```javascript
// SPEC-SPEC-C001
function getHarvesterBody(energy) {
    if (energy < 50) return [MOVE];
    if (energy < 200) return [WORK, CARRY, MOVE];
    return [WORK, WORK, WORK, CARRY, CARRY, MOVE, MOVE, MOVE];
}
```

## Traceability
- Spec: SPEC-C001
- Code: src/creeps/harvester.js
- Test: tests/test_harvester.js
