# Screeps 룸 설정 가이드

## 초기 룸 정보 수집

스크린샷 또는 게임 UI에서 다음 정보 확인:

| 항목 | 위치 | 예시 |
|------|------|------|
| 샤드 | 오른쪽 사이드바 | SHARD0 |
| 룸 | 오른쪽 사이드바 | E13S29 |
| 오너 | 오른쪽 사이드바 | Pheanor |
| Respawn | 파란색 텍스트 | 35 days left |
| Safe mode | 노란색 텍스트 | 19990 |
| 구조물 | 맵 영역 | Spawn1 |

## 구조물 식별

- **Spawn**: 노란 원 + 흰색 고리 (크립 스폰)
- **Controller**: 중앙 구조물 (업그레이드 대상)
- **Sources**: 노란 점 (에너지 소스)
- **Terrain**: 검은색 장애물, 초록색草地

## 코드에 반영

```javascript
// main.js 상단에 룸 이름 설정
const ROOM = 'E13S29';
const SHARD = 'SHARD0';

// 게임 루프에서 사용
const room = Game.rooms[ROOM];
```

## Safe mode 주의

- Safe mode 종료 후 외부 공격 가능
- 종료 임계값: 0 ticks
- 대응: 방어나 다른 룸으로 이동 필요

## Respawn area

- 사망 후 재출석 지역
- 0일 되면 컨트롤러 권한 상실
- 유지: 정기적 컨트롤러 업그레이드 필수

## 디버깅 체크리스트

- [ ] 룸 이름 정확한지 확인
- [ ] 스폰 존재 확인 (`spawns.length > 0`)
- [ ] 컨트롤러 레벨 확인 (`controller.level`)
- [ ] 에너지 소스 확인 (`sources.length`)
- [ ] 스폰 쿨다운 확인 (`spawn.cooldown === 0`)
