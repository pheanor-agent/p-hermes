#!/usr/bin/env python3
"""표현력 시스템 통합 테스트"""

import json
import os
import sys
import unittest
import importlib.util

SKILL_DIR = os.path.dirname(os.path.abspath(__file__))
ENGINE_DIR = os.path.join(SKILL_DIR, '..', 'engine')
MODELS_DIR = os.path.join(SKILL_DIR, '..', 'models')


def load_module(name, filepath):
    """파일 경로에서 모듈 동적 로드 (하이픈 포함 파일명 대응)"""
    spec = importlib.util.spec_from_file_location(name, filepath)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


# 모듈 미리 로드
validator = load_module('validator', os.path.join(ENGINE_DIR, 'validator.py'))
tier_generator = load_module('tier_generator', os.path.join(ENGINE_DIR, 'tier-generator.py'))
tone_adapter = load_module('tone_adapter', os.path.join(ENGINE_DIR, 'tone-adapter.py'))
scoring = load_module('scoring', os.path.join(MODELS_DIR, 'scoring.py'))
template_filler = load_module('template_filler', os.path.join(ENGINE_DIR, 'template-filler.py'))
analogy_builder = load_module('analogy_builder', os.path.join(ENGINE_DIR, 'analogy-builder.py'))
image_prompt_builder = load_module('image_prompt_builder', os.path.join(ENGINE_DIR, 'image-prompt-builder.py'))


class TestValidator(unittest.TestCase):
    """Validator 테스트"""

    def test_t1_cjk_detection(self):
        """T1: 한중일 문자 검증"""
        content = "이름: 中文テスト (한중일 문자 포함)"
        result, issues = validator.validate_t1(content, 'D1')
        self.assertFalse(result)

    def test_t1_length_check(self):
        """T1: 분량 검증"""
        content = "짧음"  # 200자 미만
        result, issues = validator.validate_t1(content, 'D1')
        self.assertFalse(result)

    def test_t2_domain_check(self):
        """T2: 도메인별 검증"""
        content = "소설 콘텐츠" * 100  # 500자 이상
        result = validator.validate_t2(content, 'D2')
        # validate_t2 returns (pass, issues, warning) tuple
        self.assertIsInstance(result, tuple)


class TestTierGenerator(unittest.TestCase):
    """Tier Generator 테스트"""

    def test_d1_tiers(self):
        """D1: 계층 구조 생성"""
        tiers = tier_generator.generate_tiers('D1', 'README', '도커 컨테이너 설명')
        self.assertIsInstance(tiers, dict)
        self.assertIn('L1', tiers)
        self.assertIn('L2', tiers)
        self.assertIn('L3', tiers)

    def test_d2_tiers(self):
        """D2: 계층 구조 생성"""
        tiers = tier_generator.generate_tiers('D2', '소설', '소설 1화')
        self.assertIsInstance(tiers, dict)
        self.assertIn('L1', tiers)
        self.assertIn('L2', tiers)
        self.assertIn('L3', tiers)


class TestToneAdapter(unittest.TestCase):
    """Tone Adapter 테스트"""

    def test_d1_explain_tone(self):
        """D1 explain 어조"""
        tone = tone_adapter.adapt_tone('explain', 'D1')
        self.assertIn('tone', tone)

    def test_d2_narrate_tone(self):
        """D2 narrate 어조"""
        tone = tone_adapter.adapt_tone('narrate', 'D2')
        self.assertIn('tone', tone)


class TestModelSelector(unittest.TestCase):
    """Model Selector 테스트"""

    def test_explain_intent(self):
        """explain 의도 모델 선택"""
        result = scoring.select_model('explain', 'D1')
        # select_model returns (model_name, details) tuple
        self.assertIsInstance(result, tuple)
        self.assertEqual(len(result), 2)
        self.assertIn('score', str(result))

    def test_persuade_intent(self):
        """persuade 의도 모델 선택"""
        result = scoring.select_model('persuade', 'D1')
        self.assertIsInstance(result, tuple)
        self.assertEqual(len(result), 2)


class TestTemplateFiller(unittest.TestCase):
    """Template Filler 테스트"""

    def test_d1_template(self):
        """D1 템플릿 렌더링"""
        content = {
            'title': '테스트',
            'summary': '요약',
            'overview': '개요 내용',
            'concepts': '개념 내용',
            'examples': '예시 내용',
            'references': '참고 자료'
        }
        result = template_filler.fill_template('D1', 'explain', content)
        self.assertIn('rendered', result)
        # 템플릿 렌더링 확인
        self.assertIn('테스트', result['rendered'])
        self.assertIn('요약', result['rendered'])

    def test_d2_template(self):
        """D2 템플릿 렌더링"""
        content = {'title': '소설', 'setting': '카페'}
        result = template_filler.fill_template('D2', 'narrate', content)
        self.assertIn('rendered', result)


class TestAnalogyBuilder(unittest.TestCase):
    """Analogy Builder 테스트"""

    def test_library_load(self):
        """라이브러리 로드"""
        analogies = analogy_builder.load_library()
        self.assertIsInstance(analogies, list)
        self.assertGreater(len(analogies), 0)

    def test_find_analogy(self):
        """아날로지 검색"""
        result = analogy_builder.find_analogy('docker', 'non-technical', 'D1')
        self.assertIsNotNone(result)
        self.assertIn('analogy', result)

    def test_generate_prompt(self):
        """프롬프트 생성"""
        prompt = analogy_builder.generate_analogy_prompt('Kubernetes', '', 'non-technical')
        self.assertIn('Kubernetes', prompt)

    def test_count_pending(self):
        """pending 카운트"""
        count = analogy_builder.count_pending()
        self.assertIsInstance(count, int)


class TestImagePromptBuilder(unittest.TestCase):
    """Image Prompt Builder 테스트"""

    def test_intent_analysis(self):
        """의도 분석"""
        result = image_prompt_builder.analyze_intent('왜 도커가 좋은지 설명해줘')
        self.assertEqual(result['intent'], 'persuade')

    def test_visual_mapping(self):
        """시각 요소 매핑"""
        result = image_prompt_builder.map_visual_elements('explain', 'neutral')
        self.assertIn('style', result)
        self.assertIn('palette', result)

    def test_build_prompt(self):
        """프롬프트 빌딩"""
        result = image_prompt_builder.build_image_prompt('도커 컨테이너 아키텍처 설명')
        self.assertIn('image_prompt', result)
        self.assertIn('optimized_prompt', result)
        self.assertIn('model', result)


class TestPipeline(unittest.TestCase):
    """전체 파이프라인 테스트"""

    def test_run_sh(self):
        """run.sh 전체 파이프라인"""
        import subprocess
        result = subprocess.run(
            ['bash', os.path.join(SKILL_DIR, '..', 'run.sh'), 'D1', 'explain',
             '도커 컨테이너는 애플리케이션을 격리하여 실행하는 기술입니다. 어떤 서버에 실행하든 동일한 환경을 보장합니다.'],
            capture_output=True,
            text=True,
            timeout=30
        )
        self.assertEqual(result.returncode, 0)
        # JSON 결과 확인
        self.assertIn('domain', result.stdout)
        self.assertIn('model', result.stdout)


class TestDomainWrappers(unittest.TestCase):
    """Domain Wrappers 테스트 (Phase 4)"""

    @classmethod
    def setUpClass(cls):
        """도메인 wrapper 모듈 로드"""
        WRAPPER_DIR = os.path.join(SKILL_DIR, '..', 'domain_wrappers')
        cls.d4 = load_module('d4', os.path.join(WRAPPER_DIR, 'd4-slides.py'))
        cls.d2 = load_module('d2', os.path.join(WRAPPER_DIR, 'd2-novel.py'))
        cls.d3 = load_module('d3', os.path.join(WRAPPER_DIR, 'd3-visual.py'))
        cls.d5 = load_module('d5', os.path.join(WRAPPER_DIR, 'd5-comfyui.py'))

    def test_d4_seminar_slides(self):
        """D4: 세미나 슬라이드 래핑"""
        result = self.d4.wrap_seminar_slides(
            title="테스트 슬라이드",
            content="세미나 내용입니다. " * 30,
            target="non-technical"
        )
        self.assertIn('tiers', result)
        self.assertIn('tone', result)
        self.assertIn('validation', result)
        self.assertIn('slides', result)

    def test_d2_novel_writing(self):
        """D2: 소설 집필 래핑"""
        result = self.d2.wrap_novel_writing(
            episode_title="테스트 화",
            content="소설 내용입니다. " * 50,
            chapter_number=1
        )
        self.assertIn('tiers', result)
        self.assertIn('tone', result)
        self.assertIn('validation', result)
        self.assertIn('episode', result)

    def test_d3_comic(self):
        """D3: 만화 래핑"""
        result = self.d3.wrap_comic(
            title="테스트 만화",
            content="만화 내용입니다. " * 30
        )
        self.assertIn('tiers', result)
        self.assertIn('template', result)
        self.assertIn('validation', result)

    def test_d3_infographic(self):
        """D3: 인포그래픽 래핑"""
        result = self.d3.wrap_infographic(
            title="테스트 인포그래픽",
            content="인포그래픽 내용입니다. " * 30
        )
        self.assertIn('tiers', result)
        self.assertIn('template', result)

    def test_d3_diagram(self):
        """D3: 다이어그램 래핑"""
        result = self.d3.wrap_diagram(
            title="테스트 다이어그램",
            content="아키텍처 내용입니다. " * 30
        )
        self.assertIn('tiers', result)
        self.assertIn('image_prompt', result)

    def test_d5_comfyui(self):
        """D5: ComfyUI 래핑"""
        result = self.d5.wrap_comfyui(
            prompt="A beautiful landscape with mountains and rivers",
            model="flux-dev"
        )
        self.assertIn('tiers', result)
        self.assertIn('optimized_prompt', result)
        self.assertIn('validation', result)
        self.assertIn('comfyui_workflow', result)


if __name__ == '__main__':
    print("=" * 60)
    print("표현력 시스템 통합 테스트")
    print("=" * 60)
    print()

    suite = unittest.TestLoader().loadTestsFromTestCase(TestValidator)
    suite.addTests(unittest.TestLoader().loadTestsFromTestCase(TestTierGenerator))
    suite.addTests(unittest.TestLoader().loadTestsFromTestCase(TestToneAdapter))
    suite.addTests(unittest.TestLoader().loadTestsFromTestCase(TestModelSelector))
    suite.addTests(unittest.TestLoader().loadTestsFromTestCase(TestTemplateFiller))
    suite.addTests(unittest.TestLoader().loadTestsFromTestCase(TestAnalogyBuilder))
    suite.addTests(unittest.TestLoader().loadTestsFromTestCase(TestImagePromptBuilder))
    suite.addTests(unittest.TestLoader().loadTestsFromTestCase(TestPipeline))
    suite.addTests(unittest.TestLoader().loadTestsFromTestCase(TestDomainWrappers))

    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)

    print()
    print("=" * 60)
    print(f"테스트 결과: {result.testsRun} PASS, {len(result.failures)} FAIL, {len(result.errors)} ERROR")
    print("=" * 60)

    if result.failures or result.errors:
        sys.exit(1)
