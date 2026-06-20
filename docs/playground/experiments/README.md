# 🧪 Playground Experiments

이 폴더는 Playground에서 진행한 실험 기록을 보관합니다.

## 폴더 구조

```
experiments/
├── README.md           ← 이 파일
├── exp-template.md     ← 실험 기록 템플릿
├── _manifest.json      ← 실험 메타데이터 (자동 갱신)
├── exp-001-*.md        ← 개별 실험 기록
├── exp-002-*.md
└── ...
```

## 실험 등록 절차

1. `exp-template.md` 복사 → `exp-NNN-[이름].md` 생성
2. 실험 내용 기록
3. `_manifest.json`에 experiments 배열에 추가
4. `../NOTES.md` 실험 목록 표 갱신

## 네이밍 규칙

- `exp-NNN-kebab-case-name.md`
- NNN은 001부터 순차 증가
