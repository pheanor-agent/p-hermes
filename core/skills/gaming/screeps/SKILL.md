---
name: screeps
description: >
  Screeps MMO game bot programming in JavaScript. Room setup, creep spawning,
  harvesting, controller upgrading, multi-source management, body optimization,
  and debugging workflows.
category: gaming
tags: [screeps, javascript, mmorpg, bot, automation, game-dev]
---

# Screeps Bot Programming

Screeps는 JavaScript로 실시간 MMO 게임을 프로그래밍하는 플랫폼이다.
이 스킬은 E13S29 룸을 기준으로 작성되었지만, 일반적인 Screeps 패턴도 포함한다.

## 트리거 조건

- Screeps 코드 작성/수정/디버깅
- 게임 봇 자동화 요청
- 크립 스폰/하베스트/업그레이드 전략
- 사양서 기반 코드 생성

## 사양서 기반 워크플로우

**사양서 → 코드 → 배포** 파이프라인 운영. 사양서 변경 시 코드 재생성.

### 파일 구조

```
~/.hermes/workspace/projects/screeps/
├── specs/
│   └── active/components/
│       └── room-{ROOM}.yaml    # 플랫폼 무관 사양서
├── build/
│   └── main.js             # 생성된 게임 코드
├── generate.js             # 사양서 → 코드 생성기
├── package.json
└── .git/
```

### 사양서 스키마 (핵심 필드)

```yaml
config:
  max_agents: 4
  spawn_threshold: 100       # spawn 최소 에너지
  spawn_interval: 50         # spawn 쿨다운 (tick)
  replace_interval: 100      # 교체 쿨다운 (tick)
  replace_energy_threshold: 300  # 교체 최소 에너지
  init_burst: true           # 첫 실행 시 즉시 다중 생성

body_builder:
  min_resource: 50
  base: [WORK, CARRY, MOVE]
  scalable:
    - part: WORK, cost: 100, max: 5, position: front
    - part: MOVE, cost: 50, max: 3, position: back

behavior:
  type: "location-based"
  rules:
    - condition: "rangeToSource <= 1 && energy < capacity"
      action: "harvest(source)"
      priority: 1
    - condition: "rangeToController <= 1 && energy > 0"
      action: "upgradeController(controller)"
      priority: 2

replacement:
  strategy: "efficiency-based"
  trigger: "all_slots_full && energy >= threshold"
```

## 핵심 개념

### 게임 루프

```javascript
module.exports.loop = function() {
    const room = Game.rooms['E13S29'];
    if (!room) return;
    // ... 크립 행동
};
```

- 매 tick 실행 (약 1초 간격)
- `Game.rooms`에 접근 가능한 룸만 처리
- `Game.time`은 게임 내 시간 (tick 수)

### 구조물 찾기

```javascript
const spawns = room.find(FIND_MY_STRUCTURES, {
    filter: s => s.structureType === STRUCTURE_SPAWN
});
const extensions = room.find(FIND_MY_STRUCTURES, {
    filter: s => s.structureType === STRUCTURE_EXTENSION
});
const controller = room.controller;
const sources = room.find(FIND_SOURCES);
```

### 크립 스폰

```javascript
// 바디 구성 (WORK=100, CARRY=50, MOVE=50 에너지)
const body = [WORK, CARRY, MOVE];
const name = `creep_${Game.time}`;
const result = spawn.spawnCreep(body, name);

// result 확인
// OK: 성공
// ERR_NOT_ENOUGH_ENERGY: 에너지 부족
// ERR_NAME_EXISTS: 이름 중복
```

### 크립 행동 패턴

**⚠️ 위치 기반 로직을 사용하세요. 임계값 기반은 tick 오차로 인해 불안정합니다.**

```javascript
// ✅ 위치 기반 (권장)
const rangeToSource = creep.pos.getRangeTo(source);
const rangeToController = creep.pos.getRangeTo(controller);

if (rangeToSource <= 1 && energy < capacity) {
    creep.harvest(source);
}
else if (rangeToController <= 1 && energy > 0) {
    creep.upgradeController(controller);
}
else if (energy >= capacity) {
    creep.moveTo(controller);
}
else {
    creep.moveTo(source);
}
```

**❌ 임계값 기반 (비권장)**: `energy < capacity * 0.95` 조건은 tick마다 에너지가 1 증가/감소하므로,
오차로 인해 크립이 소스와 컨트롤러를 왔다갔다 하며 에너지를 낭비함 (49→47→재채집 버그).

### 크립 생명주기 관리

| 상태 | 동작 |
|------|------|
| 초기화 | `init_burst: true`면 에너지 충분 시 MAX_CREEPS까지 즉시 생성 |
| 크립 부족 | `spawn_interval` tick마다 `spawn_threshold` 에너지로 spawn |
| 크립 가득 차 + 에너지 충분 | 효율 낮은 크립 → suicide() → 더 큰 바디로 respawn |
| 크립 가득 차 + 에너지 부족 | 유지 |

### 효율 기반 교체 (efficiency-based replacement)

```javascript
function getUpgradeEfficiency(creep) {
    let workParts = 0;
    for (const part of creep.body) {
        if (part.type === WORK) workParts++;
    }
    return workParts / creep.body.length;
}

function getWorstCreep() {
    let worst = null;
    let minEfficiency = 1;
    for (const name in Game.creeps) {
        const efficiency = getUpgradeEfficiency(Game.creeps[name]);
        if (efficiency < minEfficiency) {
            minEfficiency = efficiency;
            worst = Game.creeps[name];
        }
    }
    return worst;
}
```

- WORK 파트 비율이 낮은 크립을 식별
- 에너지 충분 시 `suicide()` → 더 큰 바디로 respawn
- 교체 후 효율 증가 확인 (`newEfficiency > oldEfficiency`)

## 세션에서 학습한 패턴

### 동적 바디 계산

컨트롤러 레벨에 따라 WORK 파트 수 조정:

```javascript
function getOptimalBody(energyAvailable, controllerLevel) {
    const body = [];
    let remaining = energyAvailable;
    
    const workParts = Math.min(3 + Math.floor(controllerLevel / 2), 5);
    const carryParts = 2;
    const moveParts = 2;
    
    for (let i = 0; i < workParts && remaining >= 100; i++) {
        body.push(WORK);
        remaining -= 100;
    }
    for (let i = 0; i < carryParts && remaining >= 50; i++) {
        body.push(CARRY);
        remaining -= 50;
    }
    for (let i = 0; i < moveParts && remaining >= 50; i++) {
        body.push(MOVE);
        remaining -= 50;
    }
    
    return body;
}
```

### 다중 소스 관리

가장 가까운 소스로 이동:

```javascript
function findNearestSource(creep, sources) {
    let nearest = null;
    let nearestRange = Infinity;
    
    for (const source of sources) {
        const range = creep.pos.getRangeTo(source);
        if (range < nearestRange) {
            nearestRange = range;
            nearest = source;
        }
    }
    
    return nearest;
}
```

### 에너지 통합 계산

스폰 + 익스텐션 에너지 합산:

```javascript
let totalEnergy = 0;
for (const spawn of spawns) {
    totalEnergy += spawn.store[RESOURCE_ENERGY];
}
for (const ext of extensions) {
    totalEnergy += ext.store[RESOURCE_ENERGY];
}
```

### 크립 네이밍 (충돌 방지)

```javascript
let creepCounter = 0;
function getCreepName(role) {
    creepCounter++;
    return `${role}_${creepCounter}_${Game.time}`;
}
```

## 디버깅 워크플로우

### 스폰 문제 진단

```javascript
// 1. 스폰 확인
console.log(`Spawns: ${spawns.length}`);
for (const s of spawns) {
    console.log(`${s.name} | cooldown: ${s.cooldown} | energy: ${s.store[RESOURCE_ENERGY]}`);
}

// 2. 사용 가능한 스폰 찾기
const available = spawns.find(s => s.cooldown === 0);
if (!available) {
    console.log('No available spawn (all on cooldown)');
}
```

### 일반 디버깅 패턴

1. `console.log()`로 상태 출력
2. `ERR_*` 코드 확인 (에러 메시지)
3. `Game.time`으로 타이밍 확인
4. `pos.getRangeTo()`로 거리 확인

## 사양서 → 코드 생성기 워크플로우

**사양서만 수정하면 코드가 자동 생성됩니다.**

```bash
# 1. 사양서 수정
nano ~/.hermes/workspace/projects/screeps/specs/active/components/room-E13S29.yaml

# 2. 코드 재생성
cd ~/.hermes/workspace/projects/screeps
node generate.js room-E13S29.yaml

# 3. ⚠️ 코드 리뷰 (필수!)
#    - 미정의 함수 호출 확인 (getOptimalBody 등)
#    - 스코프 에러 확인 (함수 외부 변수 참조)
#    - 미정의 변수 확인 (creep.pos 등)
#    - 문법 검증: node -c build/main.js

# 4. 배포
scp -i ~/.ssh/id_ed25519 -P 2222 build/main.js root@100.110.197.35:/code/main.js
```

**⚠️ 코드 리뷰 생제 금지.** 생성 후 반드시 리뷰 → 검증 → 배포 순서 준수. 사용자 피드백 (JOB-1467): "코드 작성 후 리뷰 안했어?" → 리뷰 단계는 선택사항이 아님.

## Screeps Bot Development 패턴 (§ absorbed from screeps-bot-development)

### 크립 바디 구성
- **최소 구성**: `[WORK, MOVE]` (150 에너지) — 하베스트 가능
- **권장 구성**: `[WORK, CARRY, MOVE]` (200 에너지) — 에너지 운반 가능
- **WORK만 있으면 안 됨**: MOVE 파트 없이 크립은 이동 불가

### 스폰(Spawn) 속성 주의사항
- **cooldown 속성 없음**: 일부 shard/버전에서는 `spawn.cooldown`이 undefined
- **해결**: cooldown 체크 대신 `spawnCreep()` 직접 호출

### capacity=null 문제
- **원인**: 크립이 제대로 초기화 안 되었거나 죽은 상태
- **해결**: MOVE 없는 크립 자동 삭제 + 재생성

### 원격 개발 환경 (Docker SSH)
ComfyUI PC 등 별도 환경에 Docker 컨테이너 설정:
- 컨테이너: `ubuntu:22.04` + openssh-server + vim/nano
- SSH 포트: 2222, 키 기반 인증
- Windows 폴더 마운트: Screeps 스크립트 폴더 ↔ 컨테이너 `/code`

### 파일 구조 (2026-06-03 기준)
```
~/.hermes/workspace/projects/screeps/        # Spec 기반 개발 (E13S29)
~/.hermes/workspace/projects/screeps-world/  # 단일 파일 (W8S24)
```
**⛔ 제거된 경로**: `~/.hermes/code/screeps/`, `~/.shared/code/screeps/` — 통합됨

### ⚠️ 앱 실행 필수 (JOB-1485)
- **Screeps 앱이 실행 중이어야 코드 변경이 적용됨**
- 저장 후 에러 계속 발생 시 앱 실행 상태 반드시 확인

상세: `references/screeps-debug-patterns.md`, `references/spec-driven-development.md`

**생성기 (`generate.js`)가 사양서 YAML의 다음 필드를 해석하여 코드로 변환:**
- `config.*` → JavaScript 상수 (`MAX_CREEPS`, `SPAWN_INTERVAL` 등)
- `body_builder.*` → 역할별 바디 함수 (`getHarvesterBody()`, `getBuilderBody()`)
- `behavior.rules[]` → `if/else if` 행동 체인
- `replacement.strategy` → 효율 기반 교체 로직
- `construction.*` → 길 건설 계획 + 빌더 크립 로직
- `spawn_logic` → 초기화 burst + 일반 spawn 조건

**수동 코드 수정 금지.** 사양서 변경 → `node generate.js` 실행 → 배포. 수동 수정하면 다음 생성 시 덮어씌워짐.

상세: `references/generator-pattern.md`

**생성기 (`generate.js`)가 사양서 YAML의 다음 필드를 해석하여 코드로 변환:**
- `config.*` → JavaScript 상수 (`MAX_CREEPS`, `SPAWN_INTERVAL` 등)
- `body_builder.*` → `getOptimalBody()` 함수 (scalable 루프 포함)
- `behavior.rules[]` → `if/else if` 행동 체인
- `replacement.strategy` → 효율 기반 교체 로직
- `spawn_logic` → 초기화 burst + 일반 spawn 조건

**수동 코드 수정 금지.** 사양서 변경 → `node generate.js` 실행 → 배포. 수동 수정하면 다음 생성 시 덮어씌워짐.

## 원격 배포

### 환경

- **Tailscale IP**: `100.110.197.35`
- **SSH Port**: `2222`
- **SSH User**: `root`
- **SSH Key**: `~/.ssh/id_ed25519` (키 기반 인증)
- **컨테이너**: `screeps-editor` (ubuntu:22.04)
- **마운트 경로**: `C:\Users\jeong\AppData\Local\Screeps\scripts\screeps.com\default` ↔ `/code`

### 배포 명령

```bash
scp -i ~/.ssh/id_ed25519 -P 2222 build/main.js root@100.110.197.35:/code/main.js
```

배포 후 게임에서 **F5** 새로고침으로 코드 재로드.

## 참고

- [Screeps API Docs](https://docs.screeps.com/)
- [Screeps Wiki](https://wiki.screeps.com/)
- [references/room-setup.md](references/room-setup.md) - 룸 설정 가이드
- [references/debugging-patterns.md](references/debugging-patterns.md) - 크립 스폰 실패/에러 진단 워크플로우

## Pitfall

1. **룸 이름 대소문자 민감**: `E13S29`는 `e13s29`와 다름
2. **스폰 쿨다운**: `spawn.cooldown > 0`이면 스폰 불가
3. **에너지 부족**: 바디 구성 시 각 파트별 에너지 확인
4. **이름 중복**: `ERR_NAME_EXISTS` 방지 위해 고유 네이밍 필수
5. **구조물 찾기**: `FIND_MY_STRUCTURES`는 소유한 구조물만 반환
6. **중복 중괄호 버그**: `module.exports.loop` 종료 시 `}};` 대신 `};` 사용 — SyntaxError 발생
7. **콘솔 로그 이스케이프**: `\\n` 문자 포함 시 SyntaxError 발생, 제거 필요
8. **임계값 기반 행동 로직**: `energy < capacity * 0.95`는 tick 오차로 인해 크립이 왔다갔다 함 → 위치 기반(`range <= 1`) 사용
9. **사양서 ↔ 코드 불일치**: 수동 코드 수정 후 사양서 업데이트 안 하면 시스템 신뢰도 하락 → 항상 동기화
10. **바디 에너지 최소값**: `getOptimalBody()`에서 `min_resource` 미만이면 빈 배열 반환 → spawn 실패
11. **TERRAIN_SWAMP 미정의**: Screeps 런타임에서 `TERRAIN_SWAMP` 상수 없음 → `terrain.getCost(x,y) === 2`로 습지 확인
12. **스copr 에러**: 함수 외부 변수 참조 금지 → 파라미터로 전달
13. **미정의 함수**: `getOptimalBody()` 없음 → 역할별 `getHarvesterBody()`/`getBuilderBody()` 사용
11. **바디 기본 비용 계산**: `[WORK, CARRY, MOVE]`는 200⚡ (WORK100+CARRY50+MOVE50) — 50⚡로 잘못 계산하면 spawn 무한 실패 루프 발생 (JOB-1467)
12. **프로젝트 위치**: 사양서 기반 프로젝트는 `~/.hermes/workspace/projects/<slug>/` 생성 — `.shared/`는 Blackboard 전용 (spec-driven-dev 스킬 준수)
13. **역할 기반 크립**: 빌더/하베스터 분리 시 `creep.memory.role`로 구분, spawn 시 `{ memory: { role: 'builder' } }` 명시 필수
14. **건설 사이트 우선 처리**: 빌더 크립은 `FIND_CONSTRUCTION_SITES` 스캔 → 건설 → 에너지 부족 시 채집 순서로 동작
15. **⚠️ 코드 리뷰 필수 (생략 금지)**: 생성 후 반드시 리뷰 → 검증 → 배포. 사용자 피드백 (JOB-1467): "코드 작성 후 리뷰 안했어?" → 리뷰는 선택사항 아님. 확인 항목: (a) 미정의 함수 호출 (b) 스코프 에러 (c) 미정의 변수 (d) 문법 검증 `node -c build/main.js`
16. **생성기 버그 패턴**: (a) `planRoads()` 함수 외부에서 `room/controller` 참조 → 파라미터 전달 필요 (b) `getOptimalBody()` 미정의 → `getHarvesterBody()/getBuilderBody()`로 역할별 분기 (c) `creep.pos.findPathTo()` 미정의 → `source.pos.findPathTo()` 사용
11. **생성기 파이프라인 필수**: 수동 코드 수정 금지. 사양서 변경 → `node generate.js` → 검증 → 배포. 수동 수정은 다음 생성 시 덮어씌워짐
12. **spawn 조건 체크**: `activeCreeps.length`는 배열이지만 `activeCreeps < MAX_CREEPS`로 비교해야 함 (Object.keys() 반환)
13. **교체 시 에너지 효율 검증**: `newEfficiency > oldEfficiency` 조건 없이 교체하면 효율이 낮은 크립으로 교체될 수 있음

## 스테이지 기반 아키텍처 (§ absorbed from gaming-automation-architecture)

사용자 우선순위: "**일반적인 1회성 구현 프로그램이 아닌 게임 특성에 맞춘 구조가 필요해**"

### 스테이지 전환 (게임 상태 기반)

```javascript
const STAGES = {
    0: 'explorer',    // Map analysis, room selection
    1: 'initialize',  // Spawn + basic infrastructure
    2: 'fortify',     // Controller upgrade, defense prep
    3: 'defend',      // Towers, walls, active defense
    4: 'expand',      // Multi-room, resource network
    5: 'conquer'      // Attack, room takeover
};

// 조건 충족 시 자동 전환
function checkStageTransition() {
    if (controller.level >= 3 && hasTower()) {
        advanceStage(3); // defend
    }
}
```

### Screeps World 특화 패턴 (무료판 제한)

**⛔ 무료판 `require()`/폴더 구조 미지원 — 반드시 단일 `main.js` 파일 사용**

### Vision Analysis 함정 (JOB-1349 학습)

- **정적 지형 맵 ≠ 동적 데이터**: Safe Mode 타이머, Owner, Noob 상태는 표시되지 않음
- **노란 점 ≠ 확인된 소스**: 낮은 해상도에서 카운팅 오류 발생
- **좌표 읽기 오류 흔함**: 툴팁이 다른 룸을 표시할 수 있음
- **✅ 해결**: 툴팁 스크린샷 필수 + 게임 UI 사이드바 확인 + 사용자에게 시각적 확인 요청

### Room Selection Checklist

- [ ] User가 게임 UI 사이드바로 룸 이름 확인
- [ ] 소스 수 게임 내 검증 (스크린샷 아님)
- [ ] Safe Mode 기간 툴팁에서 확인
- [ ] Owner 상태 툴팁에서 확인
- [ ] 확장 잠재력 인접 룸 분석
- [ ] 확장 계획 전 거리 계산

### 좌표 시스템

- Format: `WxWy` (e.g., W8S24, W11S27)
- W=West (X 양수), E=East (X 음수), N=North (Y 음수), S=South (Y 양수)
- 거리: `|x2-x1| + |y2-y1|`

### 크립 에너지=0 처리 (JOB-1349)

```javascript
// 에너지 고갈 시 강제 이동 — continue로 다른 로직 스킵
if (creep.store[RESOURCE_ENERGY] === 0) {
    creep.moveTo(sources[0]);
    continue;
}
```

### 크립 스틱 at 컨트롤러 해결

```javascript
if (energy < capacity) {
    creep.moveTo(source);      // 채집
    if (pos.getRangeTo(source) <= 1) creep.harvest(source);
} else {
    creep.moveTo(controller);  // 업그레이드
    if (pos.getRangeTo(controller, 1)) creep.upgradeController(controller);
}
```

### Tick 타이밍

- **1 tick = 1.5초** (1초 아님)
- 20 ticks = 30초, 100 ticks = 2.5분, 400 ticks = 10분

### 로깅 패턴

```javascript
let lastLog = 0;
module.exports.loop = function() {
    if (Game.time - lastLog >= 20) {
        console.log(`[${name}] status@pos:${pos.x},${pos.y}`);
        lastLog = Game.time;
    }
};
```

### Error Codes

| 코드 | 의미 | 해결 |
|------|------|------|
| -3 | ERR_NAME_EXISTS | 고유 네이밍 |
| -4 | ERR_NO_PATH | 경로 확인 |
| -6 | ERR_NOT_ENOUGH_ENERGY | 에너지 체크 + 0⚡ 강제 이동 |

**✅ `pos.isAdjacentTo()` 대신 `pos.getRangeTo()` 사용** — Screeps World API 미지원

## 프로젝트 관리

### 파일 버전 관리

- 코드 변경 후 버전화: `main-v1.0.js`, `main-v1.1.js`
- 피드백 기록: `feedback.md`
- **⚠️ 앱 실행 필수 (JOB-1485)**: Screeps 앱 실행 중이어야 코드 변경 적용됨

### 프로젝트 구조 (2026-06-03 기준)

```
~/.hermes/workspace/projects/screeps/        # Spec 기반 개발 (E13S29)
~/.hermes/workspace/projects/screeps-world/  # 단일 파일 (W8S24)
```

**⛔ 제거된 경로**: `~/.hermes/code/screeps/`, `~/.shared/code/screeps/` — 통합됨
