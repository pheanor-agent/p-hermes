# 코드 생성기 패턴 (Code Generator Pattern)

**사양서 → 자동 코드 생성 워크플로우** — 코드 직접 수정 대신 YAML 사양서 정의 → 코드 생성기 실행

## 프로젝트 구조

```
~/.shared/code/
├── templates/              # 공통 템플릿 시스템
│   ├── spec-schema/v1.yaml # 사양서 스키마
│   ├── generators/         # 플랫폼별 생성기
│   │   └── screeps.js
│   └── tests/
└── {project}/              # 프로젝트별
    ├── specs/              # YAML 사양서
    ├── build/              # 생성된 코드
    └── docs/
```

## 워크플로우

```
사양서 작성/수정 (YAML)
    ↓
코드 생성기 실행 (node generator.js spec.yaml → main.js)
    ↓
원격 배포 (scp build/main.js → 서버)
```

## Screeps 사양서 예시

```yaml
version: "1.0"
metadata:
  name: "E13S29"
  platform: "screeps"
config:
  max_agents: 4
  spawn_threshold: 150
  log_interval: 50
body_builder:
  min_resource: 150
  base: [WORK, CARRY, MOVE]
  scalable:
    - part: WORK
      cost: 100
      max: 5
      position: front
behavior:
  modes:
    - name: harvest
      condition: "energy < capacity * 0.95"
      actions:
        - type: moveTo
          target: source
        - type: harvest
          target: source
    - name: upgrade
      condition: "energy >= capacity * 0.95"
      actions:
        - type: moveTo
          target: controller
        - type: upgradeController
          target: controller
```

## Pitfalls (Screeps)

1. **Spawn cooldown 속성 없음**: `spawn.cooldown`이 undefined → 직접 `spawnCreep()` 호출
2. **에너지 효율**: 95% 미만 재채집 → 낭비 | 95% 이상 전환 | 0까지 다 사용
3. **바디 구성**: WORK만 있으면 이동 불가 → MOVE 필수
4. **Capacity null**: `getCapacity()`가 null일 수 있음 → fallback 필요
5. **위치 기반 동작**: 소스 근처면 harvest, 컨트롤러 근처면 upgrade

## 코드 생성기 구조

```javascript
class ScreepsGenerator {
  generateBodyBuilder(spec) { /* 바디 빌더 */ }
  generateBehavior(spec) { /* 위치 기반 행동 */ }
  generate() { /* 전체 코드 */ }
}
```

## 사용법

```bash
# 코드 재생성
node ~/.shared/code/templates/generators/screeps.js specs/room-E13S29.yaml build/main.js

# 원격 배포
scp -i ~/.ssh/id_ed25519 -P 2222 build/main.js root@{server}:/code/main.js
```
