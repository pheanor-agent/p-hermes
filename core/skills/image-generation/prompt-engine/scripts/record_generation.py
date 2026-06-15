#!/usr/bin/env python3
"""
이미지 생성 자동 기록 유틸리티

모든 이미지 생성 API 호출 후 자동으로 실행 이력 기록.
프롬프트 엔진의 적응적 학습과 연동.
"""

import os
import sys
import json
from pathlib import Path

# 프롬프트 엔진 경로 추가
PROMPT_ENGINE_DIR = Path(__file__).parent.parent.parent / "prompt-engine"
sys.path.insert(0, str(PROMPT_ENGINE_DIR))
sys.path.insert(0, str(PROMPT_ENGINE_DIR / "adaptive"))


def record_image_generation(model, prompt, success=True, metadata=None):
    """
    이미지 생성 결과 자동 기록
    
    Args:
        model: 모델 ID (flux2_pro, flux2_klein, comfyui, etc.)
        prompt: 사용된 프롬프트
        success: 성공 여부
        metadata: 추가 메타데이터 (해상도, 소요시간, etc.)
    """
    try:
        from prompt_engine import PromptEngine
        
        engine = PromptEngine()
        engine.record_result(model, prompt, success, metadata)
        
        # 학습 상태 로깅
        if success:
            stats = engine.get_model_stats(model)
            if stats['total'] % 10 == 0:  # 10회마다 상태 출력
                print(f"📊 {model} 학습 진행: {stats['total']}회 (성공률: {stats['success_rate']*100:.1f}%)")
        
    except Exception as e:
        # 기록 실패 시 경고만 출력 (이미지 생성은 계속)
        print(f"⚠️ 실행 기록 실패: {e}")


def record_openrouter_generation(model_id, prompt, response_data, success=True):
    """
    OpenRouter 이미지 생성 결과 기록
    
    Args:
        model_id: OpenRouter 모델 ID (black-forest-labs/flux.2-pro, etc.)
        prompt: 사용된 프롬프트
        response_data: API 응답 데이터
        success: 성공 여부
    """
    # 모델 ID를 내부 ID로 변환
    model_map = {
        "black-forest-labs/flux.2-pro": "flux2_pro",
        "black-forest-labs/flux.2-klein-4b": "flux2_klein",
        "black-forest-labs/flux.2-max": "flux2_max",
        "openai/gpt-5.4-image-2": "gpt5_4",
        "google/gemini-3.1-flash-image-preview": "gemini",
        "seedream/seedream-4.5": "seedream",
    }
    
    model = model_map.get(model_id, model_id)
    
    # 메타데이터 추출
    metadata = {
        "provider": "openrouter",
        "model_id": model_id,
        "cost": response_data.get('usage', {}).get('cost', 0) if response_data else 0,
    }
    
    record_image_generation(model, prompt, success, metadata)


def record_comfyui_generation(prompt, loras=None, success=True, elapsed_sec=None):
    """
    ComfyUI 이미지 생성 결과 기록
    
    Args:
        prompt: 사용된 프롬프트
        loras: 사용된 LoRA 목록
        success: 성공 여부
        elapsed_sec: 소요시간 (초)
    """
    metadata = {
        "provider": "comfyui",
        "loras": loras or [],
        "elapsed_sec": elapsed_sec,
    }
    
    record_image_generation("comfyui", prompt, success, metadata)


# 테스트
if __name__ == "__main__":
    # OpenRouter 테스트
    print("OpenRouter 기록 테스트...")
    record_openrouter_generation(
        model_id="black-forest-labs/flux.2-pro",
        prompt="test prompt with braless sideless",
        response_data={"usage": {"cost": 0.03}},
        success=True
    )
    
    # ComfyUI 테스트
    print("\nComfyUI 기록 테스트...")
    record_comfyui_generation(
        prompt="test prompt",
        loras=["koreandoll2.safetensors"],
        success=True,
        elapsed_sec=15.5
    )
    
    print("\n✅ 기록 테스트 완료")
