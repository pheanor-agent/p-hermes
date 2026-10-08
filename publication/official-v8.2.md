# p-hermes v1 v8.2 공식 발표 자료

2026년 7월 15일 릴리스된 플레이그라운드 v8.2를 2026년 10월 8일 공식 발표 자료로 등록한다. 발표 자료의 내용과 동작은 당시 버전 그대로 보존한다.

공식 진입점은 `docs/index.html`과 `docs/lectures/index.html`이다. 공식 덱은 `docs/lectures/v8.2/`에 있으며, 출처는 `docs/playground/lectures/v8.2/`다. 출처 기준 커밋은 `9c843cee3b03c40a252d1f190705f70784ebe1fa`다.

다음 여섯 파일의 공식 사본과 출처는 바이트 단위로 동일하다.

- `deck-a-core-v8.2.html` — 35장
- `deck-b-knowledge-v8.2.html` — 36장
- `deck-c-skill-v8.2.html` — 38장
- `deck-d-workflow-v8.2.html` — 47장
- `slides-v8.2.css`
- `slides-v8.2.js`

기존 6강과 이전 덱, 위키·블로그 본문, 과거 사양서, 버전 이력을 유지한다. 자료의 현재 진입점은 홈·목차에서 관리한다. v1.9 폴더의 기존 링크가 열리도록 목차를 추가했으며 해당 버전 슬라이드에는 변경이 없다.

`python3 tests/validate-official-lectures.py`는 원본 동일성, 156장 구성, 자산, 현재 진입점의 실제 페이지와 앵커를 검사한다. `src/deploy.sh`는 이 검사를 배포 전에 수행하고 검색 색인을 생성한다. 역사적 사양서의 과거 경로·형식 설명은 당시 기록으로 보존하며 이번 공식화의 경로와 검증 범위는 이 기록을 따른다.
