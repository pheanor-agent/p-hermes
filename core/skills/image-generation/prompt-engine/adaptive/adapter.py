"""
실행 이력 기반 자동 템플릿 조정

모델별 특성 프로필 기반 적응적 템플릿 추천
"""

import yaml
from pathlib import Path
from model_tracker import ModelTracker
from feature_analyzer import FeatureAnalyzer


class AdaptiveTemplateEngine:
    """실행 이력 기반 템플릿 자동 조정"""
    
    def __init__(self, template_dir, history_dir=None):
        self.template_dir = Path(template_dir)
        self.tracker = ModelTracker(history_dir)
        self.analyzer = FeatureAnalyzer()
    
    def get_adaptive_model_config(self, model):
        """적응적 모델 설정 반환"""
        # 기본 설정 로드
        with open(self.template_dir / "models.yaml", 'r', encoding='utf-8') as f:
            base_config = yaml.safe_load(f)
        
        base = base_config.get(model, {}).copy()
        
        # 실행 이력 기반 적응
        profile = self.tracker.get_model_profile(model)
        if profile and profile.get("optimal_settings"):
            # 실행 이력이 있으면 기본 설정 오버라이드
            base.update(profile["optimal_settings"])
        
        return base
    
    def update_from_execution(self, model, prompt, success, result_metadata=None):
        """실행 결과 기반 특성 업데이트"""
        # 실행 기록
        self.tracker.record_execution(model, prompt, result_metadata, success)
        
        # 특성 분석
        features = self.analyzer.analyze_prompt(prompt)
        
        # 프로필 업데이트
        feature_results = {}
        for feature_name, matches in features.items():
            pattern_key = f"{feature_name}:{','.join(matches)}"
            feature_results[pattern_key] = success
        
        self.tracker.update_model_profile(model, feature_results)
    
    def suggest_optimal_template(self, model, genre, exposure):
        """성공률 기반 최적 템플릿 추천"""
        executions = self.tracker.get_recent_executions(model, limit=100)
        
        if len(executions) < 10:
            return None  # 이력 부족 → 기본 템플릿 사용
        
        # 성공률 80% 이상인 패턴 필터링
        high_success = self.analyzer.get_high_success_patterns(model, executions, threshold=0.8)
        
        if not high_success:
            return None
        
        # 가장 성공률이 높고 실행 횟수 많은 패턴 반환
        best_pattern = max(
            high_success.items(), 
            key=lambda x: (x[1]["success_rate"], x[1]["total"])
        )
        
        return {
            "pattern": best_pattern[0],
            "success_rate": best_pattern[1]["success_rate"],
            "total": best_pattern[1]["total"]
        }
    
    def get_model_stats(self, model):
        """모델별 실행 통계"""
        stats = self.tracker.get_stats(model)
        profile = self.tracker.get_model_profile(model)
        
        return {
            **stats,
            "profile_last_updated": profile.get("last_updated"),
            "pattern_count": len(profile.get("success_rates", {}))
        }
    
    def get_recommendations(self, model):
        """모델별 권장사항"""
        executions = self.tracker.get_recent_executions(model, limit=100)
        
        if len(executions) < 10:
            return {
                "status": "learning",
                "message": f"실행 이력 부족 ({len(executions)}/10). 기본 템플릿 사용 중."
            }
        
        suggestions = self.analyzer.suggest_pattern_adjustments(model, executions)
        
        return {
            "status": "optimized",
            "message": f"적응적 최적화 활성화 ({suggestions['high_success_count']}개 성공 패턴)",
            "use_more": suggestions["use_more"],
            "use_less": suggestions["use_less"]
        }
