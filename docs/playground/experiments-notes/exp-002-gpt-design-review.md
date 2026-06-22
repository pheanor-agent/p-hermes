전체적으로는 문제를 정확히 발견했고 방향도 맞다고 봅니다. 특히 "현재 시스템은 post-validation 중심이고 pre-coaching이 없다"는 진단은 설득력이 있습니다.
다만 설계서에는 몇 가지 중요한 구조적 빈틈이 있습니다.

───

가장 중요한 문제
1. pre_direction.py가 너무 많은 책임을 가짐
현재 설계
text
pre_direction.py
 ├ 전략 프레임 선택
 ├ 청중 분석
 ├ 구조 템플릿
 ├ 디자인 시스템
 ├ 검증 기준
 └ direction-guide 생성

사실상 콘텐츠 시스템의 두뇌 역할을 전부 수행합니다.
2~3개월 뒤를 생각하면
text
전략 프레임 5개
→ 12개

청중 유형 5개
→ 20개

디자인 시스템
→ 여러 브랜드

문서 유형
→ 수십 개

가 되면서 거대한 if-else 덩어리가 될 가능성이 높습니다.

───

권장 구조
text
pre_direction.py
    ├ strategy_selector.py
    ├ audience_analyzer.py
    ├ template_selector.py
    ├ design_guide_provider.py
    └ direction_compiler.py

pre_direction은 orchestration만 수행.

───

2. direction-guide.json이 너무 D3(슬라이드) 중심
예시를 보면
json
{
  "font_size_min":"30px",
  "max_words_per_slide":20
}

이건 D3 전용입니다.
하지만 설계 목표는
text
D1 문서
D2 기술설명
D3 슬라이드
D4 창작
D5 제안서

전체 지원입니다.

───

현재 구조의 문제
D1에서
json
max_words_per_slide

의미 없음.
D4에서
json
font_size_min

의미 없음.

───

권장
공통 스키마 + 도메인 확장
json
{
  "domain":"D3",

  "strategy": {...},

  "audience": {...},

  "constraints": {...},

  "domain_specific": {...}
}

예)
json
{
  "domain_specific": {
      "max_words_per_slide": 20,
      "font_size_min": 30
  }
}


───

3. 프레임워크 선택 기준이 없음
현재
text
Golden Circle
Pyramid
BAB
Storytelling
PSB

만 존재.
문제는
언제 어떤 프레임을 선택하는가?
가 없음.

───

예시
사용자 입력
text
Hermes Agent 설명 자료

그러면
text
Golden Circle?
Pyramid?
Story?

어떤 기준으로 선택?
알 수 없음.

───

추가 필요
yaml
framework_selection_rules:

  D1:
    default: pyramid

  D3:
    architecture:
      - golden_circle

    comparison:
      - pyramid

    onboarding:
      - storytelling

  D5:
    proposal:
      - problem_solution_benefit

선택 규칙이 반드시 필요.

───

4. 청중 분석이 너무 단순
현재
text
개발자
입문자
발표청중
독자
의사결정자

실제 현업에서는 부족합니다.
예)
text
CTO
CEO
PM
Developer
Architect
Sales
Investor
Customer

은 전혀 다른 설명 방식 필요.

───

권장
청중 유형보다
text
knowledge_level
decision_power
technical_depth

축으로 분해

───

예
json
{
  "audience": {
      "knowledge":"low",
      "authority":"high",
      "technical_depth":"low"
  }
}

그러면 CEO/투자자/임원 모두 대응 가능.

───

5. design_system_loader를 제거하면 안 됨
설계서에서
text
P2 design_system_loader 미구현
→ pre_direction으로 대체

라고 되어 있음.
이건 위험.

───

이유
Direction과 Design은 다른 책임.
text
pre_direction
    → 어떤 디자인을 써야 하는가

design_system_loader
    → 실제 디자인 토큰 제공

예)
json
{
   "theme":"corporate_blue"
}

까지는 pre_direction.
실제
json
{
   "primary":"#2563EB",
   "radius":"16px",
   "spacing":"24px"
}

는 design_system_loader.

───

권장
text
삭제 X
축소 유지 O


───

6. 가장 큰 누락: 피드백 루프
현재 흐름
text
pre_direction
    ↓
agent 작성
    ↓
validator

끝.

───

실제 좋은 시스템은
text
pre_direction
    ↓
agent 작성
    ↓
validator
    ↓
gap analyzer
    ↓
guide 개선

루프가 있어야 함.

───

예
Validator 결과
text
글씨가 너무 작음

누적 100회
↓
자동 학습
text
font_size_min
30 → 36


───

현재 설계는 여전히 정적 시스템.

───

7. 적용률 0% 문제는 해결되지 않음
설계서에서
text
P6 적용률 0%
범위 제외

라고 되어 있음.
사실 가장 위험한 부분.

───

현재
yaml
content: true

없으면
text
SKIP

이라면
pre_direction을 추가해도
text
실행 안 됨

가능성이 큼.

───

우선순위는 사실
text
P0 사전 방향성 부재
+
P6 적용률 0%

동시 해결이어야 함.

───

추가로 넣으면 좋은 것
A. confidence score
json
{
  "framework":"golden_circle",
  "confidence":0.82
}

낮으면 fallback 사용.

───

B. rationale
json
{
  "framework":"golden_circle",

  "reason":
  "아키텍처 소개형 발표 자료로 판단"
}

디버깅이 매우 쉬워짐.

───

C. multiple candidates
json
{
  "primary":"golden_circle",

  "alternatives":[
      "pyramid",
      "storytelling"
  ]
}

향후 LLM 기반 선택에 유리.

───

최종 평가
현재 설계 점수

항목
점수

문제 진단
9/10

해결 방향
8/10

확장성
6/10

운영성
6/10

아키텍처
7/10


총평: 7.5/10
"Pre-direction 엔진을 추가한다"는 핵심 방향은 맞습니다.
다만 현재 설계는 슬라이드(D3) 중심의 단일 엔진 설계에 가깝고, 장기적으로는
text
PreDirection Orchestrator
 ├ Strategy Selector
 ├ Audience Analyzer
 ├ Template Selector
 ├ Design System Loader
 └ Feedback Loop

형태로 분리하는 것이 더 안정적입니다.
그리고 실제 우선순위는 P0보다도 P6(적용률 0%)를 함께 해결하는 것입니다. pre_direction을 아무리 잘 만들어도 실행되지 않으면 효과가 없기 때문입니다.