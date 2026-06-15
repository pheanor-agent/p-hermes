# JOB-1534: 세미나 슬라이드 레이아웃 개선

## 문제점
- 모든 슬라이드가 동일한 중심 정렬 레이아웃 → 단조로움
- 카드형, 그리드형 등 다양한 레이아웃 누락
- 다이어그램 색상 일률적 (모두 purple) → 강조점 없음
- T1/T2/T3, 도메인 분류가 텍스트 목록으로 표현 → 시각적 구분 부족

## 개선안
- **Slide 3**: 카드 3개 (계층 1/2/3) + 아이콘
- **Slide 4**: 2열 비교 레이아웃 (신입사원 vs AI)
- **Slide 5**: 다이어그램 레이블 추가 (1.수집/2.가공/3.저장)
- **Slide 6-7**: 단계별 색상 (amber→purple→green)
- **Slide 8**: T1/T2/T3 카드 + 색상 코딩 (rose/amber/green)
- **Slide 9**: 도메인 카드 4개
- **Slide 10**: 4단계 탐색 다이어그램

## 추가된 CSS
```css
.grid-2 { grid-template-columns: 1fr 1fr; }
.grid-3 { grid-template-columns: 1fr 1fr 1fr; }
.grid-4 { grid-template-columns: 1fr 1fr 1fr 1fr; }
.card.highlight { border-color: var(--accent); background: var(--accent-dim); }
.card.tier-1 { border-top: 4px solid var(--rose); }
.card.tier-2 { border-top: 4px solid var(--amber); }
.card.tier-3 { border-top: 4px solid var(--green); }
.diagram-node.amber { border-color: var(--amber); background: var(--amber-dim); color: var(--amber); }
.diagram-node.purple { border-color: var(--purple); background: var(--purple-dim); color: var(--purple); }
.diagram-node.green { border-color: var(--green); background: var(--green-dim); color: var(--green); }
.diagram-node.rose { border-color: var(--rose); background: var(--rose-dim); color: var(--rose); }
```

## Anti-Patterns
- ❌ **Text Wall**: 긴 텍스트 블록 → Card/Diagram으로 변환
- ❌ **Bullet Hell**: 5개 이상 불릿 → Grid 레이아웃으로 분리
- ❌ **Mixed Density**: 폰트 크기 혼재 → 타이포그래피 계층 일관성 유지

## 교훈
- 레이아웃 다양성이 발표 효과를 극대화
- 색상 코딩은 정보 계층을 직관적으로 전달
- 카드형 레이아웃은 텍스트 밀도를 낮추고 가독성 향상
