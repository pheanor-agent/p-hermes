#!/usr/bin/env python3
"""
slides-deploy-verify.py — 슬라이드 배포 후 Playwright로 시각 검증

사용법:
  python3 slides-deploy-verify.py
  python3 slides-deploy-verify.py --lecture lecture-02-memory-and-knowledge --slides 22,23
  python3 slides-deploy-verify.py --local http://localhost:8080

Playwright가 Hermes venv에 설치되어 있어야 함.
"""

import argparse
from playwright.sync_api import sync_playwright

BASE_URL = "https://pheanor-agent.github.io/p-hermes/playground/lectures"

def verify_screenshot(browser, url, slide_idx, screenshot_path, text_path):
    """slide-{N}로 스크롤 후 스크린샷 + 텍스트 추출"""
    page = browser.new_page(viewport={"width": 1920, "height": 1080})
    page.goto(url)
    page.wait_for_timeout(3000)  # CSS/JS 렌더링 대기
    
    # slide-N으로 스크롤 (evaluate로 직접 window.document 접근)
    page.evaluate(f"""
        (() => {{
            const deck = document.querySelector('.deck') || document.querySelector('[class~="deck"]');
            if (deck) {{
                deck.scroll({{ left: {slide_idx} * window.innerWidth }});
            }} else {{
                window.scroll({{ left: {slide_idx} * window.innerWidth }});
            }}
        }})()
    """)
    page.wait_for_timeout(1500)  # 스크롤 완료 + 렌더링
    
    # 스크린샷
    page.screenshot(path=screenshot_path)
    print(f"  ✅ 스크린샷: {screenshot_path}")
    
    # 텍스트 추출 (slide-N 또는 전체)
    slide_el = page.locator(f'#slide-{slide_idx}')
    if slide_el.is_visible(timeout=3000):
        text = slide_el.inner_text()
    else:
        # fallback: 전체 페이지
        text = page.inner_text('body')
    
    with open(text_path, 'w') as f:
        f.write(text)
    print(f"  ✅ 텍스트: {text_path} ({len(text)} chars)")
    
    # 텍스트 프리뷰
    for line in text.split('\n')[:5]:
        print(f"    {line[:80]}")
    
    page.close()
    return text

def main():
    parser = argparse.ArgumentParser(description="슬라이드 배포 검증")
    parser.add_argument("--lecture", help="강의 파일명 (예: lecture-02-memory-and-knowledge)")
    parser.add_argument("--slides", help="검증할 slide 인덱스 (쉼표 구분, 예: 22,23)")
    parser.add_argument("--local", help="로컬 HTTP 서버 URL")
    parser.add_argument("--base", default=BASE_URL, help="기본 URL")
    args = parser.parse_args()
    
    if args.local:
        base = args.local.rstrip('/')
    else:
        base = args.base
    
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        
        if args.lecture:
            # 단일 강의 검증
            url = f"{base}/{args.lecture}.html"
            print(f"🔍 {url}")
            
            slides = [int(s.strip()) for s in args.slides.split(',')] if args.slides else [0]
            
            for idx in slides:
                text = verify_screenshot(
                    browser, url, idx,
                    f"/tmp/{args.lecture}-slide{idx}.png",
                    f"/tmp/{args.lecture}-slide{idx}.txt"
                )
                print()
        else:
            # 기본 검증: L02 slide-22, L04 slide-6
            targets = [
                ("lecture-02-memory-and-knowledge", 22),
                ("lecture-04-hermes-core-architecture", 6),
            ]
            
            for lecture, idx in targets:
                url = f"{base}/{lecture}.html"
                print(f"🔍 {url}")
                
                text = verify_screenshot(
                    browser, url, idx,
                    f"/tmp/{lecture}-slide{idx}.png",
                    f"/tmp/{lecture}-slide{idx}.txt"
                )
                print()
        
        browser.close()
    
    print("✅ 검증 완료 — /tmp/ 폴더에서 스크린샷 확인")

if __name__ == "__main__":
    main()
