# Screeps Spec-to-Code Generator Pattern

## 개요

`generate.js`는 YAML 사양서를 읽어서 Screeps JavaScript 코드로 자동 생성합니다.

## 파일 구조

```
~/.hermes/workspace/projects/screeps/
├── specs/active/components/room-E13S29.yaml  # 입력: 사양서
├── generate.js                               # 생성기
├── build/main.js                             # 출력: 게임 코드
└── node_modules/                             # js-yaml 의존성
```

## 생성기 동작

### 입력 파싱

```javascript
// generate.js 내부
const SPECS_DIR = path.join(__dirname, 'specs', 'active', 'components');
const spec = yaml.load(fs.readFileSync(specPath, 'utf8'));
```

### 필드 매핑

| 사양서 필드 | 생성된 코드 | 설명 |
|-------------|-------------|------|
| `config.max_agents` | `const MAX_CREEPS = N` | 최대 크립 수 |
| `config.spawn_threshold` | `const SPAWN_ENERGY_THRESHOLD = N` | spawn 최소 에너지 |
| `config.spawn_interval` | `const SPAWN_INTERVAL = N` | spawn 쿨다운 (tick) |
| `config.replace_interval` | `const REPLACE_INTERVAL = N` | 교체 쿨다운 |
| `config.replace_energy_threshold` | `const REPLACE_ENERGY_THRESHOLD = N` | 교체 최소 에너지 |
| `config.init_burst` | `if (!initialized) { ... }` | 초기 다중 생성 로직 |
| `body_builder.min_resource` | `if (energy < N) return []` | 바디 최소 에너지 |
| `body_builder.base` | `const body = [...]` | 기본 바디 구성 |
| `body_builder.scalable[]` | `for` 루프 | WORK/MOVE 파트 확장 로직 |
| `behavior.rules[]` | `if/else if` 체인 | 위치 기반 행동 규칙 |
| `replacement.strategy` | 효율 계산 + 교체 로직 | `efficiency-based`면 교체 함수 생성 |

### 생성된 코드 구조

```javascript
module.exports.loop = function() {
    // 1. 구조물 찾기 (spawns, controller, sources)
    // 2. 에너지 계산
    // 3. 로깅 (LOG_INTERVAL)
    // 4. 초기화 burst (init_burst: true)
    // 5. 크립 교체 (replacement.strategy)
    // 6. 일반 spawn (SPAWN_INTERVAL)
    // 7. 크립 행동 (behavior.rules)
};
```

## 사용법

```bash
# 기본 사용 (room-E13S29.yaml)
node generate.js

# 명시적 사양서
node generate.js room-E13S29.yaml

# 전체 경로도 가능
node generate.js specs/active/components/room-E13S29.yaml
```

## Pitfall

### 1. 경로 해결 실패

**문제**: `generate.js`가 `SPECS_DIR`을 `__dirname/specs/`로 하드코딩하면, spec-driven-dev 프로젝트 구조(`specs/active/components/`)에서 파일 못 찾음.

**해결**:
```javascript
const SPECS_DIR = path.join(__dirname, 'specs', 'active', 'components');

function loadSpec(specName) {
    const specPath = path.join(SPECS_DIR, specName);
    if (!fs.existsSync(specPath)) {
        if (fs.existsSync(specName)) {
            // Fallback: 상대/절대 경로 시도
            return yaml.load(fs.readFileSync(specName, 'utf8'));
        }
        throw new Error(`Spec not found: ${specPath}`);
    }
    return yaml.load(fs.readFileSync(specPath, 'utf8'));
}
```

### 2. 수동 코드 수정 금지

생성된 `build/main.js`를 직접 수정하면 다음 `node generate.js` 실행 시 **덮어씌워짐**. 모든 변경은 사양서에서 하세요.

### 3. 의존성 관리

`generate.js`는 `js-yaml` 패키지를 사용합니다:

```bash
cd ~/.hermes/workspace/projects/screeps
npm install js-yaml
```

### 4..spec vs 코드 정합성

사양서 변경 후 반드시:
1. `node generate.js` 실행
2. `node -c build/main.js` 문법 검증
3. `scp ... /code/main.js` 배포
4. 게임 F5 새로고침

## 생성기 확장

새 필드 추가 시 `generateCode()` 함수에 분기 추가:

```javascript
function generateCode(spec) {
    const config = spec.config || {};
    const newField = spec.new_section || {};
    
    // 기존 생성 로직...
    
    // 새 필드 처리
    if (newField.enabled) {
        code += generateNewFeature(newField);
    }
    
    return code;
}
```
