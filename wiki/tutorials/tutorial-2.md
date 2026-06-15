# 튜토리얼: 나만의 스킬 추가하기

Hermes의 기본 기능만으로도 충분하지만, 당신만의 독특한 워크플로우를 시스템화하고 싶다면 **커스텀 스킬(Custom Skill)**을 작성해 보세요.

## 🎯 목표
이 튜토리얼에서는 **[GitHub Issue 자동 생성 스킬]**을 만들어 보겠습니다.

---

## 1단계: 스킬 생성 요청
Hermes에게 스킬 생성을 요청합니다.

> `[TASK] GitHub 저장소의 Issue를 자동으로 생성하는 스킬을 만들어줘. 제목, 설명, 라벨을 입력하면 자동으로 생성되도록 해.`

## 2단계: 스킬 구조 확인
Hermes는 `~/.hermes/skills/custom/github-auto-issue/` 폴더를 생성합니다.

```text
github-auto-issue/
├── SKILL.md          # 핵심 로직 및 단계
├── references/       # 공식 문서 링크 등
└── scripts/          # gh CLI 호출 스크립트
```

## 3단계: SKILL.md 내용 확인
에이전트는 `SKILL.md`에 다음을 작성합니다:

1. **Trigger (트리거)**: "GitHub Issue를 만들어줘", "이 기능을 추가해줘" 등의 문구를 인식.
2. **Steps (실행 단계)**:
   - 저장소 경로 확인.
   - `gh issue create` 명령어 구성.
   - 라벨(`tags`) 매핑 및 적용.
3. **Verification (검증)**: 생성된 Issue URL을 반환하여 확인.

## 4단계: 스킬 테스트
> `[TASK] 이 스킬을 사용해 '버그 수정' 관련 테스트 이슈를 하나 생성해줘.`

Hermes는 방금 만든 스킬을 로드하고, 실제로 디스코드/GitHub에 이슈를 생성합니다. 생성된 링크가 제공되면 성공입니다!

## 💡 배운 점
- 반복 작업을 스킬로 정의하면 Hermes가 그것을 "专业技能"으로 습득합니다.
- 스킬은 SKILL.md라는 문서와 스크립트의 조합으로 이루어집니다.
- 스킬을 수정(`patch`)하거나 삭제(`delete`)하여 계속 발전시킬 수 있습니다.
