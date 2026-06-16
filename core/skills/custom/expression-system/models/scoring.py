#!/usr/bin/env python3
"""Model Selector: 의도→모델 매핑 (Elo 점수 기반)"""

import json
import os
import sys
from typing import Dict, Optional, Tuple

# catalog.json 경로
CATALOG_PATH = os.path.join(os.path.dirname(__file__), "catalog.json")

# 의도→capability 가중치
INTENT_WEIGHTS: Dict[str, Dict[str, float]] = {
    "persuade": {"creative-writing": 0.25, "tone-adaptation": 0.40, "analogy-generation": 0.20, "narrative-fiction": 0.15},
    "explain": {"technical-documentation": 0.35, "non-fiction-explanation": 0.35, "analogy-generation": 0.20, "tone-adaptation": 0.10},
    "entertain": {"creative-writing": 0.30, "tone-adaptation": 0.25, "narrative-fiction": 0.25, "analogy-generation": 0.20},
    "inform": {"technical-documentation": 0.40, "non-fiction-explanation": 0.35, "tone-adaptation": 0.15, "analogy-generation": 0.10},
    "inspire": {"creative-writing": 0.30, "tone-adaptation": 0.35, "narrative-fiction": 0.20, "analogy-generation": 0.15},
}

# Elo threshold
ELO_THRESHOLD = 1600


def load_catalog() -> Dict:
    """catalog.json 로드."""
    with open(CATALOG_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def score_model(model_name: str, catalog: Dict, intent: str, domain: str) -> Tuple[float, Dict]:
    """
    모델의 종합 점수 계산.

    Args:
        model_name: 모델 이름
        catalog: 모델 카탈로그
        intent: 의도 (persuade, explain, entertain, inform, inspire)
        domain: 도메인 코드 (D1~D5)

    Returns:
        (score, details) — 점수 + 상세 정보
    """
    if model_name not in catalog:
        return 0, {"error": f"Model not found: {model_name}"}

    model = catalog[model_name]
    weights = INTENT_WEIGHTS.get(intent, INTENT_WEIGHTS["explain"])

    # Capability 가중합
    cap_score = 0
    cap_details = {}
    for capability, weight in weights.items():
        val = model["capabilities"].get(capability, 0)
        cap_score += val * weight
        cap_details[capability] = {"value": val, "weight": weight, "contribution": val * weight}

    # Elo 점수 정규화 (0~1 스케일)
    elo = model["domain_elos"].get(domain, 1600)
    elo_normalized = max(0, min(1, (elo - 1400) / 400))

    # 종합 점수 (Capability 70% + Elo 30%)
    total_score = cap_score * 0.7 + elo_normalized * 0.3

    return total_score, {
        "model": model_name,
        "capability_score": cap_score,
        "elo_score": elo_normalized,
        "elo_raw": elo,
        "details": cap_details,
    }


def select_model(intent: str, domain: str, catalog: Optional[Dict] = None) -> Tuple[str, Dict]:
    """
    의도+도메인에 최적의 모델 선택.

    Args:
        intent: 의도
        domain: 도메인 코드
        catalog: 모델 카탈로그 (None 시 자동 로드)

    Returns:
        (model_name, details) — 선택된 모델 + 상세 정보
    """
    if catalog is None:
        catalog = load_catalog()

    best_model = None
    best_score = -1
    all_scores = {}

    for model_name in catalog:
        score, details = score_model(model_name, catalog, intent, domain)
        all_scores[model_name] = {"score": score, "details": details}
        if score > best_score:
            best_score = score
            best_model = model_name

    # Elo threshold 확인
    if best_model:
        elo = catalog[best_model]["domain_elos"].get(domain, 1600)
        if elo < ELO_THRESHOLD:
            return best_model, all_scores[best_model]  # 여전히 반환 (fallback 없음)

    return best_model, all_scores[best_model]


def main():
    """CLI: 의도+도메인 → 최적 모델 출력."""
    if len(sys.argv) < 3:
        print(json.dumps({"error": "Usage: scoring.py <intent> <domain>"}, ensure_ascii=False))
        sys.exit(1)

    intent = sys.argv[1]
    domain = sys.argv[2]

    catalog = load_catalog()
    model, details = select_model(intent, domain, catalog)

    result = {
        "selected_model": model,
        "intent": intent,
        "domain": domain,
        "details": details,
    }

    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
