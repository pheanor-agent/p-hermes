# Screeps 코드 생성기 패턴 (JOB-1467)

## 파일 구조

```
~/.hermes/workspace/projects/screeps/
├── specs/active/components/room-{ROOM}.yaml  # 사양서 (수정 대상)
├── build/main.js                              # 생성된 코드
├── generate.js                                # 생성기
├── package.json
└── .git/
```

## 워크플로우

```bash
# 1. 사양서 수정
nano specs/active/components/room-E13S29.yaml

# 2. 코드 재생성
node generate.js room-E13S29.yaml

# 3. 문법 검증
node -c build/main.js

# 4. 배포
scp -i ~/.ssh/id_ed25519 -P 2222 build/main.js root@100.110.197.35:/code/main.js
```

## 핵심 버그: 바디 기본 비용 계산 (JOB-1467)

**현상**: 에너지 300⚡에서 크립 1개만 생성되고 더 이상 spawn 안 됨

**원인**:
```javascript
// ❌ 잘못됨
function getOptimalBody(energy) {
    if (energy < 50) return [];  // 50⚡는 WORK 파트 1개 비용
    const body = [WORK, CARRY, MOVE];  // 실제 비용: 200⚡
    let remaining = energy - 50;  // 300-50=250⚡ (잘못된 계산)
```

**수정**:
```javascript
// ✅ 정확함
function getOptimalBody(energy) {
    const baseCost = 200; // WORK(100) + CARRY(50) + MOVE(50)
    if (energy < baseCost) return [];
    const body = [WORK, CARRY, MOVE];
    let remaining = energy - baseCost;  // 300-200=100⚡ (정확)
```

**결과**: spawn_threshold 200⚡ 이상에서 정상 spawn, 에너지 계산 정확화

## 역할 기반 크립 시스템

사양서에서 `body_builder`가 `harvester`/`builder`로 분리되면:

```yaml
body_builder:
  harvester:
    base: [WORK, CARRY, MOVE]
  builder:
    base: [WORK, MOVE]
```

생성기는 `getHarvesterBody()`와 `getBuilderBody()` 함수를 각각 생성하며, spawn 시 `{ memory: { role: 'builder' } }` 옵션으로 역할 저장.

## 건설 로직 동작 순서

1. 100tick마다 `planRoads()` 실행 → 경로 분석 → 건설 사이트 생성
2. 빌더 크립: `FIND_CONSTRUCTION_SITES` 스캔 → 건설 → 에너지 부족 시 채집
3. 하베스터 크립: 기존 채집/업그레이드 로직 유지
