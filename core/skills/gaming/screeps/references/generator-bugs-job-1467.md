# Generator Bugs - JOB-1467 Session

## 발견된 버그 패턴 (2026-06-02)

### CRITICAL-1: 미정의 함수 호출
**문제**: `getOptimalBody()` 호출但该函数不存在
**원인**: 역할 분리(harvester/builder) 후 함수명 변경 안됨
**수정**: 역할별 함수로 분기 (`getHarvesterBody()` / `getBuilderBody()`)
```javascript
// ❌ 버그
const newBody = getOptimalBody(totalEnergy);

// ✅ 수정
const isBuilder = creep.memory.role === 'builder';
const newBody = isBuilder ? getBuilderBody(totalEnergy) : getHarvesterBody(totalEnergy);
```

### CRITICAL-2: 스코프 에러
**문제**: `planRoads()` 함수에서 `room`, `controller` 변수 참조 불가
**원인**: 함수가 `module.exports.loop` 외부에서 정의 → 내부 변수 접근 불가
**수정**: 파라미터 전달
```javascript
// ❌ 버그
function planRoads() {
    const sources = room.find(FIND_SOURCES); // room 미정의
}

// ✅ 수정
function planRoads(room, controller, sources) {
    // 파라미터 사용
}

// 호출 시
planRoads(room, controller, sources);
```

### CRITICAL-3: 미정의 변수
**문제**: `creep.pos.findPathTo()` 호출但该变量不存在
**원인**: `creep` 변수가 현재 스코프에서 정의 안됨
**수정**: `source.pos` 사용
```javascript
// ❌ 버그
const path = creep.pos.findPathTo(controller);

// ✅ 수정
const path = source.pos.findPathTo(controller.pos);
```

### MAJOR-4: 들여쓰기 불일치
**문제**: 조건문 들여쓰기 16칸 (정상 8칸)
**원인**: 템플릿 문자열 생성 시 들여쓰기 계산 오류
**수정**: 들여쓰기 정렬

## 코드 리뷰 체크리스트

생성 후 반드시 확인:
1. ✅ 미정의 함수 호출 (`getOptimalBody` 등)
2. ✅ 스코프 에러 (함수 외부 변수 참조)
3. ✅ 미정의 변수 (`creep.pos` 등)
4. ✅ 들여쓰기/문법 검증 (`node -c build/main.js`)
5. ✅ 역할별 메모리 설정 (`{ memory: { role: '...' } }`)

## 사용자 피드백

> "코드 작성 후 리뷰 안했어?"

→ 코드 리뷰는 **선택사항이 아님**. 생성 → 리뷰 → 검증 → 배포 순서 강제.
