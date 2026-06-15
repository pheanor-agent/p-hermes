"""
모델별 실행 이력 추적 및 특성 분석

실행 결과 기록 → 패턴 분석 → 모델 프로필 업데이트
"""

import json
from pathlib import Path
from datetime import datetime
from collections import defaultdict


class ModelTracker:
    """실행 이력 기반 모델 특성 추적"""
    
    def __init__(self, history_dir=None):
        self.history_dir = Path(history_dir) if history_dir else Path(__file__).parent.parent / "history"
        self.history_dir.mkdir(parents=True, exist_ok=True)
        self.executions_file = self.history_dir / "executions.jsonl"
        self.profiles_file = self.history_dir / "model_profiles.json"
    
    def record_execution(self, model, prompt, result=None, success=True, metadata=None):
        """실행 기록"""
        record = {
            "timestamp": datetime.now().isoformat(),
            "model": model,
            "prompt": prompt,
            "result": result,
            "success": success,
            "metadata": metadata or {}
        }
        with open(self.executions_file, 'a', encoding='utf-8') as f:
            f.write(json.dumps(record, ensure_ascii=False) + "\n")
    
    def get_model_profile(self, model):
        """모델별 특성 프로필 조회"""
        if self.profiles_file.exists():
            with open(self.profiles_file, 'r', encoding='utf-8') as f:
                profiles = json.load(f)
            return profiles.get(model, {})
        return {}
    
    def update_model_profile(self, model, features):
        """모델 특성 프로필 업데이트 (적응)"""
        if self.profiles_file.exists():
            with open(self.profiles_file, 'r', encoding='utf-8') as f:
                profiles = json.load(f)
        else:
            profiles = {}
        
        if model not in profiles:
            profiles[model] = {
                "prompt_patterns": {},
                "success_rates": {},
                "optimal_settings": {},
                "last_updated": None
            }
        
        # 패턴 기반 업데이트
        for pattern, success in features.items():
            if pattern not in profiles[model]["success_rates"]:
                profiles[model]["success_rates"][pattern] = {"total": 0, "success": 0}
            
            profiles[model]["success_rates"][pattern]["total"] += 1
            if success:
                profiles[model]["success_rates"][pattern]["success"] += 1
        
        profiles[model]["last_updated"] = datetime.now().isoformat()
        
        with open(self.profiles_file, 'w', encoding='utf-8') as f:
            json.dump(profiles, f, indent=2, ensure_ascii=False)
    
    def get_recent_executions(self, model, limit=50):
        """최근 실행 기록 조회"""
        if not self.executions_file.exists():
            return []
        
        executions = []
        with open(self.executions_file, 'r', encoding='utf-8') as f:
            for line in f:
                record = json.loads(line.strip())
                if record["model"] == model:
                    executions.append(record)
        
        # 최신순 정렬
        executions.sort(key=lambda x: x["timestamp"], reverse=True)
        return executions[:limit]
    
    def get_stats(self, model):
        """모델별 실행 통계"""
        executions = self.get_recent_executions(model, limit=100)
        if not executions:
            return {"total": 0, "success": 0, "success_rate": 0}
        
        total = len(executions)
        success = sum(1 for e in executions if e["success"])
        return {
            "total": total,
            "success": success,
            "success_rate": success / total if total > 0 else 0
        }
