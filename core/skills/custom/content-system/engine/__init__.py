#!/usr/bin/env python3
"""
Engine Loader: 하이픈 포함 모듈 동적 로딩

Pitfall: 파일명이 tier-generator.py 같이 하이픈을 포함하면 
`import tier_generator`로 직접 import 불가.
해결: importlib.util.spec_from_file_location() 동적 로드 사용.
"""

import importlib.util
import sys
import os
from typing import Dict, Type

# 엔진 모듈 캐시
_engine_cache: Dict[str, Type] = {}


def load_engine(module_name: str, file_path: str) -> Type:
    """
    하이픈 포함 엔진 모듈 동적 로딩.

    Args:
        module_name: 모듈 이름 (import 시 사용)
        file_path: 파일 경로 (상대 또는 절대)

    Returns:
        로드된 모듈 객체
    """
    if module_name in _engine_cache:
        return _engine_cache[module_name]

    # 절대 경로로 변환
    if not os.path.isabs(file_path):
        skill_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        file_path = os.path.join(skill_dir, file_path)

    spec = importlib.util.spec_from_file_location(module_name, file_path)
    if spec is None:
        raise ImportError(f"Cannot load module: {file_path}")

    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    spec.loader.exec_module(module)

    _engine_cache[module_name] = module
    return module


def load_all_engines() -> Dict[str, Type]:
    """
    모든 엔진 모듈 로드.

    Returns:
        {engine_name: module} 딕셔너리
    """
    engines = {
        'tier_generator': 'engine/tier-generator.py',
        'tone_adapter': 'engine/tone-adapter.py',
        'validator': 'engine/validator.py',
        'analogy_builder': 'engine/analogy-builder.py',
        'template_filler': 'engine/template-filler.py',
        'image_prompt_builder': 'engine/image-prompt-builder.py',
        'model_selector': 'models/scoring.py',
    }

    loaded = {}
    for name, path in engines.items():
        try:
            loaded[name] = load_engine(name, path)
        except Exception as e:
            print(f"Warning: Failed to load {name}: {e}", file=sys.stderr)

    return loaded


if __name__ == "__main__":
    # 테스트
    engines = load_all_engines()
    print(f"✅ Loaded {len(engines)} engines:")
    for name, module in engines.items():
        print(f"  - {name}: {list(dir(module))[:5]}...")
