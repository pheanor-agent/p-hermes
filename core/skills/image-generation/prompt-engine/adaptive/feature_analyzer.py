"""
프롬프트 특성 분석 및 패턴 추출

정규식 기반 프롬프트 특성 패턴 추출 및 성공률 분석
"""

import re
from collections import defaultdict


class FeatureAnalyzer:
    """프롬프트에서 특성 패턴 추출"""
    
    # 분석 대상 특성 (정규식)
    PROMPT_FEATURES = {
        "story_context": r"(A scene from|A still from|An illustration from|A photograph from|A promotional image)",
        "exposure_keywords": r"(braless|sideless|backless|wide open armhole|high-cut|deep V-neck|micro bikini|minimal coverage)",
        "structure_description": r"(The design features|zero side coverage|completely open|front panel.*back panel)",
        "pose_type": r"(walking|playing|serene|dynamic|posed|standing|running|jumping)",
        "lighting": r"(golden hour|sunset|sunrise|studio lighting|backlight|natural light)",
        "style": r"(editorial|professional|cinematic|fashion|photography|magazine)",
        "genre": r"(beach|ocean|fashion|portrait|studio|urban|tropical)",
        "character_detail": r"(\d+-year-old|art student|photographer|novelist|designer|model)"
    }
    
    def analyze_prompt(self, prompt):
        """프롬프트에서 특성 추출"""
        features = {}
        for feature_name, pattern in self.PROMPT_FEATURES.items():
            matches = re.findall(pattern, prompt, re.IGNORECASE)
            if matches:
                features[feature_name] = matches
        return features
    
    def analyze_success_patterns(self, model, executions):
        """성공/실패 패턴 분석"""
        patterns = defaultdict(lambda: {"success": 0, "total": 0})
        
        for exec_data in executions:
            features = self.analyze_prompt(exec_data["prompt"])
            for feature_name, matches in features.items():
                pattern_key = f"{feature_name}:{','.join(matches)}"
                patterns[pattern_key]["total"] += 1
                if exec_data["success"]:
                    patterns[pattern_key]["success"] += 1
        
        # 성공률 계산
        for pattern_key in patterns:
            total = patterns[pattern_key]["total"]
            success = patterns[pattern_key]["success"]
            patterns[pattern_key]["success_rate"] = success / total if total > 0 else 0
        
        return dict(patterns)
    
    def get_high_success_patterns(self, model, executions, threshold=0.8):
        """고성공률 패턴 필터링"""
        patterns = self.analyze_success_patterns(model, executions)
        
        high_success = {
            k: v for k, v in patterns.items()
            if v.get("success_rate", 0) >= threshold and v["total"] >= 3  # 최소 3회 이상
        }
        
        return high_success
    
    def get_failed_patterns(self, model, executions, threshold=0.3):
        """저성공률 패턴 식별"""
        patterns = self.analyze_success_patterns(model, executions)
        
        failed = {
            k: v for k, v in patterns.items()
            if v.get("success_rate", 1) < threshold and v["total"] >= 3
        }
        
        return failed
    
    def suggest_pattern_adjustments(self, model, executions):
        """패턴 조정 권장사항"""
        high_success = self.get_high_success_patterns(model, executions)
        failed = self.get_failed_patterns(model, executions)
        
        suggestions = {
            "use_more": list(high_success.keys())[:5],  # 더 사용해야 할 패턴
            "use_less": list(failed.keys())[:5],        # 줄여야 할 패턴
            "high_success_count": len(high_success),
            "failed_count": len(failed)
        }
        
        return suggestions
