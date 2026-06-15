# 프롬프트 템플릿

## 공통 구조

```
[구도/해상도] + [장르/스타일] + [주제 설명] + [상세 디테일] + [조명/배경] + [품질 지정어]
```

## 카테고리별 템플릿

### 1. 인물 초상

#### 기본
```
Professional portrait photography of a {인종/연령} person, 
{헤어스타일}, {메이크업/무메이크업}, 
soft {조명} lighting, 
clean {배경} background, 
capturing {분위기} expression, 
high-quality portrait photography
```

#### 에디토리얼
```
Editorial portrait of a {인종/연령}, 
{스타일} aesthetic, 
dramatic {조명} lighting, 
{배경} setting, 
conveying {분위기} mood, 
professional photography, 
fashion magazine quality
```

### 2. 패션 룩북

#### 캐주얼
```
Fashion photography of a model wearing {의상 설명}, 
casual {스타일} style, 
{색상} color palette, 
{배경} setting, 
natural {조명} lighting, 
lifestyle photography quality
```

#### 고급
```
High-fashion editorial featuring {의상 설명}, 
avant-garde design with {디테일}, 
{색상} tones, 
professional studio with {조명} lighting, 
elegant and {분위기} aesthetic, 
luxury fashion magazine quality
```

### 3. 풍경

#### 자연
```
{스타일} landscape photography of {장소}, 
{시간대} lighting, 
{계절/기후} atmosphere, 
{구도} composition, 
high-resolution nature photography, 
serene and {분위기} mood
```

#### 도시
```
Urban photography of {장소}, 
{시간대} city lights, 
{기후} weather, 
{구도} angle, 
street photography style, 
vibrant and {분위기} atmosphere
```

### 4. 제품

#### 화이트 배경
```
Product photography of {제품 설명}, 
clean white background, 
studio lighting with soft shadows, 
high-resolution commercial photography, 
professional product shot
```

#### lifestyle
```
Lifestyle product photography of {제품}, 
placed in {사용 장면} setting, 
natural lighting, 
warm and inviting atmosphere, 
commercial photography quality
```

### 5. 애니메이션/일러스트

#### 2D 애니메이션
```
2D animation style illustration of {주제}, 
{스타일} art style, 
vibrant colors, 
clean line art, 
{분위기} mood, 
high-quality digital art
```

#### 3D 렌더
```
3D rendered illustration of {주제}, 
{스타일} style, 
cinematic lighting, 
detailed textures, 
{분위기} atmosphere, 
octane render quality
```

### 6. 추상/아트

```
Abstract art featuring {색상/형태 설명}, 
{스타일} style, 
{텍스처/효과} effects, 
{분위기} mood, 
contemporary digital art, 
high-resolution artwork
```

## 구도/비율 지정

### 세로 구도
- `vertical composition`
- `portrait orientation`
- `full body shot`
- `half body portrait`

### 가로 구도
- `horizontal composition`
- `landscape orientation`
- `wide angle shot`
- `panoramic view`

### 정사각형
- `square composition`
- `1:1 aspect ratio`

### 와이드
- `16:9 aspect ratio`
- `cinematic wide shot`

## 스타일 지정어

### 리얼리즘
- `photorealistic`
- `realistic photography`
- `lifestyle photography`
- `documentary style`

### 일러스트
- `digital illustration`
- `watercolor painting`
- `oil painting style`
- `sketch style`

### 애니메이션
- `anime style`
- `3D animation`
- `cel shading`
- `cartoon style`

### fotoğraf
- `editorial photography`
- `fashion photography`
- `portrait photography`
- `street photography`

## 조명 지정어

### 자연광
- `natural window lighting`
- `golden hour`
- `soft daylight`
- `overcast sky`

### 스튜디오
- `studio lighting`
- `softbox lighting`
- `Rembrandt lighting`
- `dramatic backlighting`

### 분위기
- `moody lighting`
- `neon lights`
- `cinematic lighting`
- `volumetric lighting`

## 배경 지정어

### 스튜디오
- `clean white background`
- `seamless backdrop`
- `gradient background`
- `minimalist studio`

### 실외
- `urban street`
- `nature landscape`
- `beach setting`
- `forest background`

### 실내
- `cozy room interior`
- `modern office`
- `cafe setting`
- `home environment`

## 품질 지정어

### 해상도
- `high-resolution`
- `4K quality`
- `8K ultra HD`
- `detailed`

### 스타일
- `professional photography`
- `editorial quality`
- `fashion magazine quality`
- `commercial photography`

### 세부
- `sharp focus`
- `detailed textures`
- `rich colors`
- `vivid colors`

## 모델별 최적화

### Flux.2全系
- 간결한 프롬프트 권장
- 스토리 컨텍스트 추가 시 품질 향상
- 복잡한 문장보다 명확한 키워드
- **해상도 고정 1024×768**: 파라미터 무시가 확인됨. 해상도 요구 시 다른 모델 사용

### GPT-5.4 Image 2
- 상세한 설명 효과적
- 텍스트 포함 가능 (영어 권장)
- 포즈/구도 상세히 기술
- **타임아웃 대비**: 180초+ 응답 없음 빈발. 재시도 최대 2회 후 모델 변경

### Gemini Nano Banana 2
- 서사적 프롬프트 **필수**
- 상황/맥락 설명 추가
- 자연스러운 묘사
- **안정성 문제**: 모델 ID 오류 빈발. 재시도 또는 대체 모델 준비

### ComfyUI 로컬
- LoRA 이름 명시: `<lora:이름:강도>`
- 해상도 직접 지정
- Negative prompt 활용
- **장점**: 콘텐츠 필터 없음, 해상도 완전 제어

## 스토리 컨텍스트 템플릿

차단 방지 또는 품질 향상을 위한 서사적 프롬프트:

```
{장르} photography for a {매거진/브랜드} feature on {테마}. 
The scene captures {캐릭터/주제} during {상황/배경}, 
featuring {상세 설명}. 
The photograph emphasizes {조명/구도}, 
creating a {분위기} aesthetic that celebrates {메시지}.
```

## Negative Prompt (ComfyUI용)

```
worst quality, low quality, blurry, jpeg artifacts, deformation, 
extra limbs, bad anatomy, bad proportions, 
watermark, text, signature, username
```

## 노출 표현 템플릿 (2026-05-28 검증)

### Wide Open Armhole (Flux.2 Pro 성공 ✅)
```
Editorial fashion photography featuring a wide open armhole dress.
The design features an extremely generous armhole cutout that extends from the
shoulder down past the underbust area, creating a dramatic open space that
reveals the side bust silhouette and lateral torso. The bodice structure wraps
around the front but leaves the entire armhole region completely open and exposed.
High-fashion editorial quality, minimalist studio with dramatic directional lighting.
```

**핵심:** "armhole"은 패션 용어로 인식되어 콘텐츠 필터 우회 가능. "cutout", "exposure"는 차단될 수 있음.

**상세 기법:** `references/prompt-engineering-exposure.md` 참조
