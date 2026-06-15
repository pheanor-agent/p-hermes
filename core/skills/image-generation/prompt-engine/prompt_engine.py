"""
이미지 생성 프롬프트 엔진 (Image Prompt Engineering System)

모델별 특화 템플릿 + 스토리적 연출 + 노출 레벨 제어 + ⚠️ 적응적 특성 분석
"""

import os
import random
import yaml
import json
from pathlib import Path

# 템플릿 경로
TEMPLATE_DIR = Path(__file__).parent / "templates"
HISTORY_DIR = Path(__file__).parent / "history"

# 적응적 엔진 import
import sys
sys.path.insert(0, str(Path(__file__).parent / "adaptive"))
from adapter import AdaptiveTemplateEngine

class PromptEngine:
    """⚠️ 적응적 프롬프트 엔진 (실행 이력 기반 학습)"""
    
    def __init__(self, template_dir=None, history_dir=None):
        """템플릿 로드 + 적응적 엔진 초기화"""
        self.template_dir = Path(template_dir) if template_dir else TEMPLATE_DIR
        self.history_dir = Path(history_dir) if history_dir else HISTORY_DIR
        self.templates = self._load_templates()
        self.story_generator = self._load_story_generator()
        self.adaptive = AdaptiveTemplateEngine(self.template_dir, self.history_dir)
    
    def _load_templates(self):
        """YAML 템플릿 로드"""
        templates = {}
        
        # 장르 템플릿
        with open(self.template_dir / "genres.yaml", 'r', encoding='utf-8') as f:
            templates['genres'] = yaml.safe_load(f)
        
        # 노출 템플릿
        with open(self.template_dir / "exposure.yaml", 'r', encoding='utf-8') as f:
            templates['exposure'] = yaml.safe_load(f)
        
        # 포즈 템플릿
        with open(self.template_dir / "poses.yaml", 'r', encoding='utf-8') as f:
            templates['poses'] = yaml.safe_load(f)
        
        # 모델 설정
        with open(self.template_dir / "models.yaml", 'r', encoding='utf-8') as f:
            templates['models'] = yaml.safe_load(f)
        
        return templates
    
    def _load_story_generator(self):
        """스토리 생성기 로드"""
        from narrative.story_generator import StoryGenerator
        return StoryGenerator()
    
    def generate(self, subject="Korean woman", genre="beach", exposure="moderate",
                 pose="walking", model="flux2_pro", use_story=False):
        """
        프롬프트 생성 (⚠️ 적응적 모델 설정 적용)
        
        Args:
            subject: 피사체 (기본: "Korean woman")
            genre: 장르 (beach, fashion, portrait, conceptual)
            exposure: 노출 레벨 (conservative, moderate, daring, explicit)
            pose: 포즈 (walking, playing, serene, dynamic, posed)
            model: 모델 (flux2_pro, flux2_klein, gpt5_4, gemini, seedream, comfyui)
            use_story: 스토리 컨텍스트 사용 여부
            
        Returns:
            dict: {prompt, model, resolution, timeout, adaptive_info}
        """
        # ⚠️ 적응적 모델 설정 조회
        model_config = self.adaptive.get_adaptive_model_config(model)
        
        # ⚠️ 성공률 기반 템플릿 추천 (이력 충분 시)
        adaptive_info = {}
        suggested = self.adaptive.suggest_optimal_template(model, genre, exposure)
        if suggested:
            adaptive_info["suggested_pattern"] = suggested
            # TODO: 성공 패턴 기반으로 템플릿 조정
        
        # 1. 장르 컨텍스트
        genre_template = self.templates['genres'][genre]
        
        # 2. 노출 레벨 의상
        exposure_template = self.templates['exposure'][exposure]
        
        # 3. 포즈/동작
        pose_template = self.templates['poses'][pose]
        
        # 4. 모델별 특화 (적응적 설정)
        # model_config는 이미 적응적 설정 적용됨
        
        # 5. 스토리 컨텍스트 (필요 시)
        story = None
        if use_story or model_config.get('story_needed'):
            theme = random.choice(genre_template.get('themes', ['summer romance'])) if 'themes' in genre_template else 'summer romance'
            story = self.story_generator.generate(
                genre=random.choice(list(self.story_generator.GENRES.keys())),
                theme=theme
            )
        
        # 6. 조합
        prompt = self._combine(
            subject=subject,
            story=story,
            genre=genre_template,
            exposure=exposure_template,
            pose=pose_template,
            model_style=model_config['prompt_style']
        )
        
        result = {
            'prompt': prompt,
            'model': model_config['name'],
            'resolution': model_config['resolution'],
            'timeout': model_config['timeout'],
            'adaptive_info': adaptive_info,
            'lora': model_config.get('lora_recommendations') if model_config.get('lora_support') else None
        }
        
        return result
    
    def record_result(self, model, prompt, success, result_metadata=None):
        """
        ⚠️ 실행 결과 기록 (적응 학습)
        
        Args:
            model: 모델 ID
            prompt: 사용된 프롬프트
            success: 성공 여부
            result_metadata: 결과 메타데이터 (선택)
        """
        self.adaptive.update_from_execution(model, prompt, success, result_metadata)
    
    def get_model_stats(self, model):
        """⚠️ 모델별 실행 통계 조회"""
        return self.adaptive.get_model_stats(model)
    
    def get_recommendations(self, model):
        """⚠️ 모델별 권장사항 조회"""
        return self.adaptive.get_recommendations(model)
    
    def _combine(self, subject, story, genre, exposure, pose, model_style):
        """프롬프트 조합"""
        parts = []
        
        # 스토리 컨텍스트
        if story:
            parts.append(story)
        
        # 주제 + 장르
        beach_type = random.choice(genre.get('beach_types', ['golden sand']))
        time = random.choice(genre.get('times', ['golden hour']))
        parts.append(f"A beautiful {subject} on a {beach_type} beach at {time}")
        
        # 의상 + 노출
        clothing = random.choice(exposure['clothing'])
        parts.append(f"wearing a {clothing}")
        
        # 노출 상세 설명 (daring/explicit)
        if exposure['details']:
            detail = random.choice(exposure['details'])
            if exposure.get('structure'):
                structure = exposure['structure'].format(detail=detail).replace('\n', ' ')
                parts.append(structure)
            else:
                parts.append(f"with {detail}")
        
        # 포즈
        pose_variation = random.choice(pose['variations'])
        parts.append(f"She is {pose_variation}")
        
        # 헤어
        if pose.get('hair'):
            hair = random.choice(pose['hair'])
            parts.append(f"Her {hair}")
        
        # 조명 + 스타일
        lighting = random.choice(genre.get('lighting', ['natural lighting']))
        style = random.choice(genre.get('styles', ['professional photography']))
        parts.append(f"{lighting}, {style}")
        
        # 모델별 스타일 적용
        if model_style == "concise":
            return ", ".join(parts)
        elif model_style == "narrative":
            return " ".join(parts)
        elif model_style == "detailed":
            return " ".join(parts) + " Professional photography with attention to detail."
        elif model_style == "cinematic":
            return " ".join(parts) + " Cinematic quality with dramatic composition."
        elif model_style == "high_res":
            return " ".join(parts) + " Ultra high resolution 2048x2048, crystalline detail, photorealistic."
        else:
            return ", ".join(parts)
    
    def generate_multiple(self, count=3, **kwargs):
        """다중 프롬프트 생성"""
        return [self.generate(**kwargs) for _ in range(count)]
    
    def list_models(self):
        """사용 가능한 모델 목록"""
        return list(self.templates['models'].keys())
    
    def list_genres(self):
        """사용 가능한 장르 목록"""
        return list(self.templates['genres'].keys())
    
    def list_exposure_levels(self):
        """사용 가능한 노출 레벨 목록"""
        return list(self.templates['exposure'].keys())
    
    def list_poses(self):
        """사용 가능한 포즈 목록"""
        return list(self.templates['poses'].keys())


# CLI 인터페이스
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="⚠️ Image Prompt Engineering System (Adaptive)")
    parser.add_argument("--subject", default="Korean woman", help="Subject description")
    parser.add_argument("--genre", default="beach", choices=["beach", "fashion", "portrait", "conceptual"])
    parser.add_argument("--exposure", default="moderate", choices=["conservative", "moderate", "daring", "explicit"])
    parser.add_argument("--pose", default="walking", choices=["walking", "playing", "serene", "dynamic", "posed"])
    parser.add_argument("--model", default="flux2_pro", choices=["flux2_pro", "flux2_klein", "flux2_max", "gpt5_4", "gemini", "seedream", "comfyui"])
    parser.add_argument("--story", action="store_true", help="Use narrative context")
    parser.add_argument("--count", type=int, default=1, help="Number of prompts to generate")
    
    # ⚠️ 적응적 기능
    parser.add_argument("--record", action="store_true", help="Record execution result")
    parser.add_argument("--success", type=bool, default=True, help="Success flag for --record")
    parser.add_argument("--prompt", type=str, help="Prompt for --record")
    parser.add_argument("--stats", action="store_true", help="Show model stats")
    parser.add_argument("--recommendations", action="store_true", help="Show model recommendations")
    
    args = parser.parse_args()
    
    engine = PromptEngine()
    
    # ⚠️ 실행 결과 기록
    if args.record:
        if not args.prompt:
            print("Error: --prompt required for --record")
            exit(1)
        engine.record_result(args.model, args.prompt, args.success)
        print(f"✅ 실행 기록 완료: {args.model} (success={args.success})")
        exit(0)
    
    # ⚠️ 모델 통계 조회
    if args.stats:
        stats = engine.get_model_stats(args.model)
        print(f"📊 {args.model} 통계:")
        print(f"  총 실행: {stats['total']}")
        print(f"  성공: {stats['success']}")
        print(f"  성공률: {stats['success_rate']*100:.1f}%")
        print(f"  패턴 수: {stats['pattern_count']}")
        print(f"  마지막 업데이트: {stats['profile_last_updated']}")
        exit(0)
    
    # ⚠️ 권장사항 조회
    if args.recommendations:
        recs = engine.get_recommendations(args.model)
        print(f"💡 {args.model} 권장사항:")
        print(f"  상태: {recs['status']}")
        print(f"  {recs['message']}")
        if recs['status'] == 'optimized':
            print(f"  더 사용: {recs.get('use_more', [])}")
            print(f"  줄임: {recs.get('use_less', [])}")
        exit(0)
    
    # 기존 프롬프트 생성
    if args.count == 1:
        result = engine.generate(
            subject=args.subject,
            genre=args.genre,
            exposure=args.exposure,
            pose=args.pose,
            model=args.model,
            use_story=args.story
        )
        print(f"Model: {result['model']}")
        print(f"Resolution: {result['resolution']}")
        print(f"Timeout: {result['timeout']}s")
        if result['lora']:
            print(f"LoRA: {', '.join(result['lora'])}")
        if result['adaptive_info']:
            print(f"⚠️ Adaptive: {json.dumps(result['adaptive_info'], indent=2, ensure_ascii=False)}")
        print(f"\nPrompt:\n{result['prompt']}")
    else:
        results = engine.generate_multiple(
            count=args.count,
            subject=args.subject,
            genre=args.genre,
            exposure=args.exposure,
            pose=args.pose,
            model=args.model,
            use_story=args.story
        )
        for i, result in enumerate(results, 1):
            print(f"\n{'='*60}")
            print(f"Prompt {i}")
            print(f"{'='*60}")
            print(f"Model: {result['model']}")
            print(f"Prompt:\n{result['prompt']}")
