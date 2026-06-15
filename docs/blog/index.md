# ✍️ p-hermes Dev Blog

Hermes의 기술적 결정과 설계 철학을 기록하는 공간입니다. 단순한 기능 설명을 넘어, **"왜(Why)"** 이 방식을 선택했는지에 집중합니다.

## 🏷️ 주제별 탐색
#architecture #workflow #knowledge #cron #spec-driven #lessons-learned

## 📑 최신 포스트

| 포스트 제목 | 주제 | 핵심 내용 | 링크 |
|---|---|---|---|
| **왜 9단계 상태머신인가?** | #workflow | 설계 사유 및 상태 전이 로직 | [읽기](./posts/why-9-step-workflow.md) |
| **5-Tier 물리 계층화 설계** | #architecture | 물리적 경로 격리와 도메인 분리 | [읽기](./posts/why-5-tier-architecture.md) |
| **초기 설계: 워커 vs 오케스트레이터 분리의 교훈** | #architecture #deprecated | Dual-Peer → Hot Standby 아키텍처 진화 | [읽기](./posts/dual-agent-design.md) |
| **지식 분류 시스템 설계** | #knowledge | domain/tag 기반의 계층적 지식 구조 | [읽기](./posts/knowledge-system-design.md) |
| **Cron 3계층 분리 구조** | #cron | Registry $\rightarrow$ Wrapper $\rightarrow$ Runner | [읽기](./posts/cron-3layer-separation.md) |
| **이벤트 기반 도메인 통신** | #architecture | 직접 호출 제거 및 상태 파일 기반 통신 | [읽기](./posts/event-driven-communication.md) |
| **역할 기반 모델 라우팅** | #architecture | 작업 특성별 모델 자동 배정 메커니즘 | [읽기](./posts/model-routing-design.md) |
| **텍스트 규칙의 코드 강제** | #spec-driven | Spec $\rightarrow$ Script $\rightarrow$ Validation 루프 | [읽기](./posts/structural-enforcement.md) |
| **실패 패턴에서 배운 교훈** | #lessons-learned | 반복되는 오류를 시스템적으로 막는 법 | [읽기](./posts/lessons-from-failures.md) |

---

## 🔗 관련 링크
- [어떻게 쓰는가? (Guide Wiki)](../wiki/index.md)
- [시스템 구조 한눈에 보기 (Slides)](../../pages/index.html)
