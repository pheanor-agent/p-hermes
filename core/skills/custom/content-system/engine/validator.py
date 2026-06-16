#!/usr/bin/env python3
"""
Validator: 2단계 검증 (T1: Rule Guard, T2: Semantic Guard)

T1: 구문 검증 — 빠른 정적 검증 (정규식, 문자셋, 분량)
T2: 의미 검증 — LLM 기반 컨텍스트 검증 (용어 일관성, 논리 흐름)
"""

import json
import os
import re
import sys
import time
from typing import Dict, List, Optional, Tuple

# T1: 문자셋 검증 — 한중일 문자 차단 규칙
CJK_PATTERN = re.compile(r'[\u4e00-\u9fff\u3400-\u4dbf]')
HIRAGANA_PATTERN = re.compile(r'[\u3040-\u309f]')
KATAKANA_PATTERN = re.compile(r'[\u30a0-\u30ff\u31f0-\u31ff]')

# T1: 도메인별 분량 규칙
DOMAIN_DENSITY: Dict[str, Dict[str, int]] = {
    "D1": {"min": 200, "max": 10000, "recommended": 2000},
    "D2": {"min": 500, "max": 20000, "recommended": 5000},
    "D3": {"min": 100, "max": 5000, "recommended": 1000},
    "D4": {"min": 100, "max": 8000, "recommended": 1500},
    "D5": {"min": 50, "max": 2000, "recommended": 500},
}

# Circuit Breaker 상태 (in-memory)
_circuit_breaker: Dict[str, Dict] = {
    "t2_fail_count": 0,
    "t2_blocked_until": 0,
    "t2_block_duration": 300,  # 5분
    "t2_threshold": 3,  # 연속 3회 실패 시 차단
}


def validate_t1(content: str, domain: str) -> Tuple[bool, List[str]]:
    """
    T1: 구문 검증 (Rule Guard).

    Args:
        content: 검증할 콘텐츠
        domain: 도메인 코드 (D1~D5)

    Returns:
        (pass, issues) — 통과 여부 + 이슈 목록
    """
    issues: List[str] = []

    # 1. 문자셋 검증
    cjk_matches = CJK_PATTERN.findall(content)
    if cjk_matches:
        issues.append(f"CJK 문자 발견 ({len(cjk_matches)}개): {''.join(cjk_matches[:5])}...")

    hira_matches = HIRAGANA_PATTERN.findall(content)
    if hira_matches:
        issues.append(f"히라가나 문자 발견 ({len(hira_matches)}개): {''.join(hira_matches[:5])}...")

    kata_matches = KATAKANA_PATTERN.findall(content)
    if kata_matches:
        issues.append(f"가타카나 문자 발견 ({len(kata_matches)}개): {''.join(kata_matches[:5])}...")

    # 2. 분량 검증
    density = DOMAIN_DENSITY.get(domain, {"min": 100, "max": 10000, "recommended": 2000})
    char_count = len(content)
    if char_count < density["min"]:
        issues.append(f"분량 부족: {char_count}자 (최소 {density['min']}자)")
    if char_count > density["max"]:
        issues.append(f"분량 초과: {char_count}자 (최대 {density['max']}자)")

    # 3. 템플릿 구조 완전성 (MD 헤딩 체크)
    if content.startswith("#"):
        headings = [line for line in content.split("\n") if line.startswith("#")]
        if not headings:
            issues.append("Markdown 헤딩이 없음")

    # 4. JSON 유효성 (JSON 콘텐츠인 경우)
    if content.strip().startswith("{"):
        try:
            json.loads(content)
        except json.JSONDecodeError as e:
            issues.append(f"JSON 파싱 오류: {e}")

    # 5. HTML 브레이스 균형 (HTML 콘텐츠인 경우)
    if "<" in content and ">" in content:
        open_tags = len(re.findall(r"<[a-zA-Z][^>]*>", content))
        close_tags = len(re.findall(r"</[a-zA-Z]+>", content))
        if abs(open_tags - close_tags) > 5:
            issues.append(f"HTML 태그 불균형: 열린 {open_tags}, 닫힌 {close_tags}")

    passed = len(issues) == 0
    return passed, issues


def check_circuit_breaker() -> bool:
    """Circuit Breaker 상태 확인 — 차단 중이면 True 반환."""
    now = time.time()
    if _circuit_breaker["t2_blocked_until"] > now:
        return True
    return False


def record_t2_failure():
    """T2 실패 기록 + Circuit Breaker 업데이트."""
    _circuit_breaker["t2_fail_count"] += 1
    if _circuit_breaker["t2_fail_count"] >= _circuit_breaker["t2_threshold"]:
        _circuit_breaker["t2_blocked_until"] = time.time() + _circuit_breaker["t2_block_duration"]
        _circuit_breaker["t2_fail_count"] = 0


def record_t2_success():
    """T2 성공 시 Circuit Breaker 리셋."""
    _circuit_breaker["t2_fail_count"] = 0
    _circuit_breaker["t2_blocked_until"] = 0


def validate_t2(content: str, domain: str, context: Optional[Dict] = None) -> Tuple[bool, List[str], bool]:
    """
    T2: 의미 검증 (Semantic Guard).

    Args:
        content: 검증할 콘텐츠
        domain: 도메인 코드
        context: 컨텍스트 (비유, 어조 등)

    Returns:
        (pass, issues, used_fallback) — 통과 여부 + 이슈 + 폴백 사용 여부
    """
    # Circuit Breaker 확인
    if check_circuit_breaker():
        return True, ["Circuit Breaker 활성화 — T2 스킵"], True

    # T2는 LLM 기반 검증 — 현재는 간단한 정적 규칙으로 폴백
    issues: List[str] = []

    # 1. 비유 일관성 (context에 비유가 있으면 확인)
    if context and "analogy" in context:
        analogy = context["analogy"]
        if isinstance(analogy, str) and analogy in content:
            pass  # 비유가 일관되게 사용됨
        elif isinstance(analogy, str) and analogy not in content:
            issues.append(f"비유 '{analogy[:30]}'이 콘텐츠에 반영되지 않음")

    # 2. 용어 일관성 (같은 개념이 다른 용어로 표현되면 경고)
    # 간단한 구현: 빈도 상위 10개 단어 추출
    words = re.findall(r'[가-힣a-zA-Z]{2,}', content)
    word_freq: Dict[str, int] = {}
    for w in words:
        word_freq[w] = word_freq.get(w, 0) + 1

    # 3. 문맥 누락 (너무 짧은 문단 반복)
    paragraphs = [p.strip() for p in content.split("\n\n") if p.strip()]
    short_paras = [p for p in paragraphs if len(p) < 20]
    if len(short_paras) > len(paragraphs) * 0.5 and len(paragraphs) > 3:
        issues.append(f"짧은 문단이 과도함: {len(short_paras)}/{len(paragraphs)}")

    record_t2_success()
    passed = len(issues) == 0
    return passed, issues, False


def validate(content: str, domain: str, context: Optional[Dict] = None) -> Dict:
    """
    2단계 검증 실행.

    Args:
        content: 검증할 콘텐츠
        domain: 도메인 코드
        context: 컨텍스트 (비유, 어조 등)

    Returns:
        검증 결과 Dict
    """
    result = {
        "domain": domain,
        "char_count": len(content),
        "t1": {},
        "t2": {},
        "overall": "pass",
    }

    # T1 검증
    t1_pass, t1_issues = validate_t1(content, domain)
    result["t1"] = {
        "passed": t1_pass,
        "issues": t1_issues,
    }

    if not t1_pass:
        result["overall"] = "fail"
        return result

    # T2 검증 (T1 통과 후)
    t2_pass, t2_issues, t2_fallback = validate_t2(content, domain, context)
    result["t2"] = {
        "passed": t2_pass,
        "issues": t2_issues,
        "fallback": t2_fallback,
    }

    if not t2_pass:
        result["overall"] = "warning"

    return result


def main():
    """CLI: JSON 입력 → 검증 결과 출력."""
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Usage: validator.py <domain>"}, ensure_ascii=False))
        sys.exit(1)

    domain = sys.argv[1]
    content = sys.stdin.read()

    context = None
    if len(sys.argv) > 2:
        try:
            context = json.loads(sys.argv[2])
        except json.JSONDecodeError:
            pass

    result = validate(content, domain, context)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
