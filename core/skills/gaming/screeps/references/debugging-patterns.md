# Screeps 디버깅 패턴

> **생성**: 2026-06-02 (JOB-1461)
> **목적**: 크립 스폰 실패, 구조물 문제, 에러 진단 워크플로우

## 크립 스폰 실패 디버깅

**증상**: `[STATUS] Creeps:0/4` — 크립이 생성되지 않음

**진단 체크리스트**:

### 1. 스폰 상태 확인
```javascript
// 디버깅 로그 추가 (한정 회수만)
let debugCount = 0;
debugCount++;
if (debugCount <= 10) {
    console.log(`[DEBUG] Spawns: ${spawns.length}, Energy: ${totalEnergy}, Creeps: ${activeCreeps.length}`);
    for (let i = 0; i < spawns.length; i++) {
        const s = spawns[i];
        console.log(`[DEBUG] Spawn[${i}]: ${s.name} | cooldown: ${s.cooldown} | energy: ${s.store[RESOURCE_ENERGY]}`);
    }
}
```

### 2. 사용 가능한 스폰 확인
```javascript
const availableSpawn = spawns.find(s => s.cooldown === 0);
if (!availableSpawn) {
    console.log('[SPAWN] ❌ No available spawn (all on cooldown)');
}
```

### 3. 바디 계산 확인
```javascript
const body = getOptimalBody(totalEnergy, controllerLevel);
if (body.length === 0) {
    console.log(`[SPAWN] ❌ Body calculation failed (energy: ${totalEnergy})`);
}
```

## 일반 디버깅 패턴

### 에러 코드 확인
```javascript
const result = creep.harvest(source);
if (result !== OK && result !== ERR_NOT_IN_RANGE) {
    console.log(`[ERROR] ${creep.name}: ${result}`);
}
```

**주요 에러 코드**:
- `ERR_NOT_ENOUGH_ENERGY`: 에너지 부족
- `ERR_NAME_EXISTS`: 크립 이름 중복
- `ERR_NOT_IN_RANGE`: 거리 초과
- `ERR_INVALID_TARGET`: 유효하지 않은 대상

### 상태 모니터링
```javascript
if (Game.time - lastLog >= LOG_INTERVAL) {
    console.log(`[STATUS] T:${Game.time} | Energy:${totalEnergy}⚡️ | Ctrl:L${controller.level} | Creeps:${activeCreeps.length}/${MAX_CREEPS}`);
    lastLog = Game.time;
}
```

## 디버깅 버전 배포 워크플로우

1. **문제 확인** — STATUS 로그 분석
2. **디버깅 로그 추가** — 원인 진단 코드 삽입
3. **한정 회수만 실행** — `debugCount <= 10` 패턴 사용
4. **결과 분석** — 디버깅 로그로 원인 파악
5. **수정 코드 배포** — 문제 해결 후清洁生产 코드

## 관련

- [Screeps API Docs](https://docs.screeps.com/)
- [Screeps Wiki](https://wiki.screeps.com/)
