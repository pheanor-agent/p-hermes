#!/usr/bin/env python3
"""
D5 Domain Wrapper: ComfyUI Remote 래핑

공유 엔진 연동:
- Image Prompt Builder: 이미지 모델 프롬프트 최적화
- Validator: T1(프롬프트 구조 검증)
- Tier Generator: 의도→구도→세부 계층화

기존 스킬: comfyui-remote (독립 사용 가능)
"""

import json
import sys
import os
from typing import Dict, Optional

# expression-system 엔진 경로 추가
SKILL_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, SKILL_DIR)

# 하이픈 포함 모듈 동적 로딩
from engine import load_engine

tier_generator = load_engine('tier_generator', 'engine/tier-generator.py')
image_prompt_builder = load_engine('image_prompt_builder', 'engine/image-prompt-builder.py')
validator = load_engine('validator', 'engine/validator.py')

generate_tiers = tier_generator.generate_tiers
build_prompt = image_prompt_builder.build_image_prompt
analyze_intent = image_prompt_builder.analyze_intent
map_visual_elements = image_prompt_builder.map_visual_elements
validate = validator.validate


def wrap_comfyui(
    prompt: str,
    model: str = "flux-dev",
    lora: Optional[str] = None,
    width: int = 1024,
    height: int = 1024,
    steps: int = 20,
    cfg: float = 7.0
) -> Dict:
    """
    ComfyUI 이미지 생성 — 공유 엔진 연동.

    Args:
        prompt: 원본 프롬프트
        model: 이미지 모델 (flux-dev, flux-realism, 등)
        lora: LoRA 모델 (선택)
        width: 너비
        height: 높이
        steps: 샘플링 단계
        cfg: CFG 스케일

    Returns:
        {
            "tiers": {"L1": "...", "L2": "...", "L3": "..."},
            "optimized_prompt": {...},
            "validation": {"t1": {...}},
            "comfyui_workflow": {...}  # 기존 comfyui-remote와 호환 구조
        }
    """
    result = {
        "domain": "D5",
        "model": model,
        "lora": lora,
    }

    # 1. Tier Generator: 의도→구도→세부 계층화
    tiers = generate_tiers("D5", "이미지", prompt)
    result["tiers"] = tiers

    # 2. Image Prompt Builder: 프롬프트 최적화
    intent = analyze_intent(prompt)
    visual_elements = map_visual_elements(intent['intent'], intent['mood'])
    optimized_prompt = build_prompt(prompt, "image", None)
    
    result["optimized_prompt"] = {
        "original": prompt,
        "optimized": optimized_prompt.get("prompt", prompt),
        "intent": intent,
        "visual_elements": visual_elements,
    }

    # 3. Validator: 프롬프트 구조 검증
    validation = validate(prompt, "D5", {
        "tiers": tiers,
        "optimized_prompt": optimized_prompt,
    })
    result["validation"] = validation

    # 4. ComfyUI 워크플로우 생성 (기존 comfyui-remote와 호환)
    workflow = _generate_comfyui_workflow(
        optimized_prompt.get("prompt", prompt),
        model, lora, width, height, steps, cfg
    )
    result["comfyui_workflow"] = workflow

    return result


def _generate_comfyui_workflow(
    prompt: str,
    model: str,
    lora: Optional[str],
    width: int,
    height: int,
    steps: int,
    cfg: float
) -> Dict:
    """
    ComfyUI 워크플로우 구조 생성 - 기존 comfyui-remote와 호환.

    NOTE: 실제 API 호출은 comfyui-remote 스킬이 담당.
    이 wrapper는 프롬프트 최적화 + 워크플로우 구조만 제공.
    """
    workflow = {
        "prompt": prompt,
        "model": model,
        "parameters": {
            "width": width,
            "height": height,
            "steps": steps,
            "cfg_scale": cfg,
        },
    }
    
    if lora:
        workflow["lora"] = lora

    return workflow


def main():
    """CLI: JSON 입력 → D5 ComfyUI 워크플로우 출력."""
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Usage: d5-comfyui.py <prompt>"}, ensure_ascii=False))
        sys.exit(1)

    prompt = sys.argv[1]
    
    model = "flux-dev"
    if len(sys.argv) > 2:
        model = sys.argv[2]

    result = wrap_comfyui(prompt, model)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
