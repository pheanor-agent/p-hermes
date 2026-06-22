# 콘텐츠 생성

> **Content System**을 사용하여 Hermes의 표현 품질을 자동 검증하고 최적화하는 방법을 설명합니다.

---

## 개요

Content System은 Hermes Agent의 표현 품질 관리 시스템입니다. 작성한 콘텐츠의 도메인을 자동 감지하고, 도메인에 맞는 검증 기준과 템플릿을 적용하여 품질을 보장합니다.

| 도메인 | 코드 | 대상 |
|:------:|:----:|------|
| Novel | D2 | 장편 소설, 스토리 |
| Visual | D3 | 이미지 생성 프롬프트 |
| Slides | D4 | 발표 자료 |
| ComfyUI | D5 | ComfyUI 워크플로우 |

---

## 기본 사용법

### 1. Content System 활성화

```bash
# 설정에서 Content System 활성화
# ~/.hermes/config.yaml
content_system:
  enabled: true
  auto_detect: true
```

### 2. 콘텐츠 생성 요청

Hermes에게 직접 요청하면 자동으로 도메인이 감지됩니다.

> "이 아이디어를 블로그 포스트로 만들어줘"
> "이 내용을 슬라이드로 정리해줘"
> "이 개념을 소설 형식으로 풀어줘"

### 3. Pre-Direction (사전 방향 제시)

콘텐츠 생성 전에 청중과 의도를 명확히 하면 품질이 향상됩니다.

> "개발자를 대상으로 한 기술 블로그야. 핵심은 왜 이 아키텍처를 선택했는지 설명하는 거야."

---

## 고급 기능

### 템플릿 사용

Content System은 도메인별 템플릿을 제공합니다.

| 템플릿 | 도메인 | 특징 |
|--------|:------:|------|
| technical-blog | D1 | 기술 블로그 기본 |
| technical-seminar-dark | D4 | 다크 테마 슬라이드 |
| novel-chapter | D2 | 소설 챕터 구조 |

### 검증 기준

| 단계 | 검증 내용 |
|:----:|-----------|
| T1 | 기본 문법, 맞춤법, 필수 섹션 존재 여부 |
| T2 | 도메인별 규칙 준수, 분량 기준 |

---

## 주의사항

- **Pre-Direction 우선**: 생성 전에 방향을 먼저 설정하세요 (사후 검증보다 효과적)
- **도메인 명시**: 자동 감지가 실패하면 도메인을 직접 명시하세요
- **분량 기준**: Wiki 문서 1,500자+, Blog 3,000자+ 권장

---

> **🔗 다음 읽을거리**: [Knowledge 관리 가이드](knowledge-management.md) · [Blog Why 시리즈](/docs/blog/index.md)
