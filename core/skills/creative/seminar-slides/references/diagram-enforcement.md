# 다이어그램 사용 강제 규칙 (JOB-1553 학습)

## 문제
슬라이드 내용이 텍스트 중심이고, 다이어그램/그래픽 요소가 부재함. 기반 지식이 없는 사람도 이해하기 어려움.

## 규칙
**순차적/분류적 동작은 다이어그램 필수**:
- 순차적 동작 (Ingest→Link→Lint): 플로우 차트 필수
- 분류적 동작 (T1/T2/T3): 컬러 코딩 카드 필수
- 계층적 구조 (L1→L2→L3): 트리 다이어그램 필수
- 단순 설명만: 텍스트 허용

## 구현 방법
- HTML/CSS로 구현 가능한 간단한 다이어그램 사용
- CSS Grid/Flexbox로 카드 레이아웃 구성
- SVG 또는 CSS shape로 화살표/박스 표현
- 애니메이션은 최소화 (가독성 우선)

## 팝업 확장 규칙
- 코드/파일 구조 시각화 포함
- 실제 구현된 코드 스니펫 표시
- 파일 트리 구조 그림 포함

## 예시
```html
<!-- 순차적 다이어그램 -->
<div class="diagram-flow">
  <div class="diagram-node amber">Ingest</div>
  <div class="diagram-arrow">→</div>
  <div class="diagram-node purple">Link</div>
  <div class="diagram-arrow">→</div>
  <div class="diagram-node green">Lint</div>
</div>
```
