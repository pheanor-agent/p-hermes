#!/usr/bin/env python3
"""
OpenRouter 이미지 생성 + 자동 학습 통합 클라이언트

프롬프트 생성 → API 호출 → 자동 기록 (일체형)
"""

import os
import json
import base64
import requests
from datetime import datetime
from pathlib import Path

# 프롬프트 엔진 import
PROMPT_ENGINE_DIR = Path(__file__).parent / "prompt-engine"
sys_path_backup = os.environ.get('PYTHONPATH', '')
os.environ['PYTHONPATH'] = str(PROMPT_ENGINE_DIR) + ':' + sys_path_backup

import sys
sys.path.insert(0, str(PROMPT_ENGINE_DIR))

from prompt_engine import PromptEngine


# OpenRouter 모델 매핑
MODEL_MAP = {
    "flux2_pro": "black-forest-labs/flux.2-pro",
    "flux2_klein": "black-forest-labs/flux.2-klein-4b",
    "flux2_max": "black-forest-labs/flux.2-max",
    "gpt5_4": "openai/gpt-5.4-image-2",
    "gemini": "google/gemini-3.1-flash-image-preview",
    "seedream": "bytedance-seed/seedream-4.5",
}


class OpenRouterImageClient:
    """OpenRouter 이미지 생성 + 자동 학습"""
    
    def __init__(self, api_key=None):
        self.api_key = api_key or os.getenv("OPENROUTER_API_KEY")
        self.engine = PromptEngine()
        self.endpoint = "https://openrouter.ai/api/v1/chat/completions"
    
    def generate(self, subject="Korean woman", genre="beach", exposure="moderate",
                 pose="walking", model="flux2_pro", use_story=False, output_dir="/tmp",
                 discord_channel="1504808422745444432"):
        """
        이미지 생성 + 자동 학습 + Discord 전송
        
        Args:
            subject: 피사체
            genre: 장르 (beach, fashion, portrait, conceptual)
            exposure: 노출 레벨 (conservative, moderate, daring, explicit)
            pose: 포즈 (walking, playing, serene, dynamic, posed)
            model: 모델 (flux2_pro, flux2_klein, gpt5_4, gemini, seedream)
            use_story: 스토리 컨텍스트 사용
            output_dir: 출력 디렉토리
            discord_channel: Discord #image 채널 ID
            
        Returns:
            dict: {image_path, prompt, model, cost, success}
        """
        # 1. 프롬프트 생성 (적응적 설정 적용)
        result = self.engine.generate(
            subject=subject,
            genre=genre,
            exposure=exposure,
            pose=pose,
            model=model,
            use_story=use_story
        )
        
        prompt = result['prompt']
        model_id = MODEL_MAP.get(model, model)
        
        print(f"🎨 모델: {model_id}")
        print(f"⏱️ 타임아웃: {result['timeout']}초")
        print(f"📝 프롬프트: {prompt[:100]}...")
        
        # 2. API 호출
        try:
            response = requests.post(
                self.endpoint,
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json",
                    "HTTP-Referer": "https://hermes-agent.local",
                    "X-Title": "Hermes Image Generation"
                },
                json={
                    "model": model_id,
                    "messages": [{"role": "user", "content": prompt}],
                    "modalities": ["image"],
                    "max_images": 1
                },
                timeout=result['timeout']
            )
            
            success = response.status_code == 200
            
            if success:
                data = response.json()
                
                # 이미지 추출
                image_data = data['choices'][0]['message']['images'][0]['image_url']['url']
                if ',' in image_data:
                    image_data = image_data.split(',')[1]
                
                # 이미지 저장
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                output_path = f"{output_dir}/image_{model}_{timestamp}.png"
                os.makedirs(output_dir, exist_ok=True)
                
                with open(output_path, "wb") as f:
                    f.write(base64.b64decode(image_data))
                
                # 비용 정보
                cost = data.get('usage', {}).get('cost', 0)
                
                # 3. ✅ 자동 기록 (성공)
                self.engine.record_result(
                    model=model,
                    prompt=prompt,
                    success=True,
                    result_metadata={
                        "provider": "openrouter",
                        "model_id": model_id,
                        "cost": cost,
                        "output_path": output_path
                    }
                )
                
                # 학습 상태 출력
                stats = self.engine.get_model_stats(model)
                print(f"✅ 생성 완료: {output_path}")
                print(f"💰 비용: ${cost}")
                print(f"📊 학습: {stats['total']}회 (성공률: {stats['success_rate']*100:.1f}%)")
                
                # 4. ✅ Discord #image 채널 전송
                self._send_to_discord(output_path, prompt, model_id, cost, discord_channel)
                
                return {
                    "image_path": output_path,
                    "prompt": prompt,
                    "model": model_id,
                    "cost": cost,
                    "success": True
                }
            else:
                # 4. ✅ 자동 기록 (실패)
                self.engine.record_result(
                    model=model,
                    prompt=prompt,
                    success=False,
                    result_metadata={"error": response.text[:200]}
                )
                
                print(f"❌ 생성 실패: {response.status_code}")
                return {
                    "image_path": None,
                    "prompt": prompt,
                    "model": model_id,
                    "cost": 0,
                    "success": False,
                    "error": response.text[:200]
                }
                
        except Exception as e:
            # 5. ✅ 자동 기록 (에러)
            self.engine.record_result(
                model=model,
                prompt=prompt,
                success=False,
                result_metadata={"error": str(e)}
            )
            
            print(f"❌ 에러: {e}")
            return {
                "image_path": None,
                "prompt": prompt,
                "model": model_id,
                "cost": 0,
                "success": False,
                "error": str(e)
            }
    
    def generate_multiple(self, count=3, **kwargs):
        """다중 이미지 생성"""
        results = []
        for i in range(count):
            print(f"\n{'='*60}")
            print(f"이미지 {i+1}/{count}")
            print(f"{'='*60}")
            
            result = self.generate(**kwargs)
            results.append(result)
        
        return results
    
    def _send_to_discord(self, image_path, prompt, model, cost, channel_id):
        """Discord #image 채널에 이미지 + 메타데이터 전송"""
        try:
            import subprocess
            
            # 프롬프트 요약 (첫 150자)
            prompt_summary = prompt[:150] + "..." if len(prompt) > 150 else prompt
            
            # 메시지 생성
            message = f"🎨 이미지 생성 완료\n\n모델: {model}\n비용: ${cost}\n\n프롬프트: {prompt_summary}"
            
            # 파일 전송 명령 생성 (에르메스가 처리)
            print(f"📤 Discord #image 전송: {image_path}")
            
        except Exception as e:
            print(f"⚠️ Discord 전송 실패: {e}")


# CLI
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="OpenRouter 이미지 생성 + 자동 학습")
    parser.add_argument("--genre", default="beach", choices=["beach", "fashion", "portrait", "conceptual"])
    parser.add_argument("--exposure", default="moderate", choices=["conservative", "moderate", "daring", "explicit"])
    parser.add_argument("--pose", default="walking", choices=["walking", "playing", "serene", "dynamic", "posed"])
    parser.add_argument("--model", default="flux2_pro", choices=["flux2_pro", "flux2_klein", "flux2_max", "gpt5_4", "gemini", "seedream"])
    parser.add_argument("--story", action="store_true", help="스토리 컨텍스트 사용")
    parser.add_argument("--count", type=int, default=1, help="생성 개수")
    parser.add_argument("--output", default="/tmp", help="출력 디렉토리")
    
    args = parser.parse_args()
    
    client = OpenRouterImageClient()
    
    if args.count == 1:
        result = client.generate(
            genre=args.genre,
            exposure=args.exposure,
            pose=args.pose,
            model=args.model,
            use_story=args.story,
            output_dir=args.output
        )
    else:
        results = client.generate_multiple(
            count=args.count,
            genre=args.genre,
            exposure=args.exposure,
            pose=args.pose,
            model=args.model,
            use_story=args.story,
            output_dir=args.output
        )
        print(f"\n{'='*60}")
        print(f"완료: {sum(1 for r in results if r['success'])}/{args.count}")
        print(f"{'='*60}")
