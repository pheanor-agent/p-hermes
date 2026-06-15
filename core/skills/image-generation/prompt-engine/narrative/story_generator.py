"""
스토리 컨텍스트 생성기 (Narrative Staging Generator)

모델별 스토리 컨텍스트 자동 생성. 콘텐츠 필터 우회를 위한 서사적 배경 제공.
"""

import random

class StoryGenerator:
    """서사적 컨텍스트 자동 생성"""
    
    GENRES = {
        "korean_drama": "A scene from a Korean drama about {theme}",
        "indie_film": "A still from an independent film shot on {location}",
        "romance_novel": "An illustration from a romance novel chapter about {theme}",
        "summer_vacation": "A photograph from a summer vacation diary about {theme}",
        "art_exhibition": "A promotional image for an art exhibition exploring {theme}"
    }
    
    THEMES = {
        "beach": ["summer romance", "freedom and liberation", "renewal and rebirth"],
        "fashion": ["contemporary elegance", "self-expression", "timeless beauty"],
        "portrait": ["inner strength", "vulnerability", "quiet confidence"],
        "conceptual": ["the intersection of nature and humanity", "beauty in imperfection"]
    }
    
    LOCATIONS = [
        "Jeju Island", "a remote coastal village", "a tropical paradise",
        "a secluded beach cove", "a Mediterranean coastline"
    ]
    
    CHARACTERS = {
        "art_student": "a {age}-year-old art student named {name}",
        "photographer": "a {age}-year-old photographer named {name}",
        "writer": "a {age}-year-old novelist named {name}",
        "designer": "a {age}-year-old fashion designer named {name}",
        "model": "a {age}-year-old professional model named {name}",
        "student": "a {age}-year-old university student named {name}"
    }
    
    NAMES = ["Ji-eun", "Soo-min", "Ha-yoon", "Yoo-jin", "Seo-yeon", "Ji-woo", "Hae-in"]
    
    AGES = [23, 24, 25, 26, 27, 28, 29]
    
    EMOTIONS = {
        "lost_in_thought": [
            "lost in thought about {thought}",
            "contemplating {question}"
        ],
        "reflecting": [
            "reflecting on {memory}",
            "remembering {memory}"
        ],
        "dreaming": [
            "dreaming of {aspiration}",
            "hoping for {aspiration}"
        ],
        "embracing": [
            "embracing the moment of {moment}",
            "savoring {moment}"
        ]
    }
    
    THOUGHTS = [
        "the painting she wants to create",
        "her summer vacation plans",
        "a creative project back home",
        "the photograph she wants to take"
    ]
    
    MEMORIES = [
        "a childhood memory by the sea",
        "a love letter she received",
        "a conversation with her mentor",
        "a dream she had last night"
    ]
    
    ASPIRATIONS = [
        "traveling the world",
        "opening her own gallery",
        "publishing her first novel",
        "designing her debut collection"
    ]
    
    MOMENTS = [
        "peace and tranquility",
        "freedom from expectations",
        "connection with nature",
        "self-discovery"
    ]
    
    QUESTIONS = [
        "what comes next",
        "if he will return",
        "where her art will take her",
        "the meaning of beauty"
    ]
    
    CLOTHING_CONTEXT = {
        "bought": ["bought at the local market earlier that day", "purchased during her morning stroll"],
        "gift": ["received as a birthday gift from her best friend", "a present from her sister"],
        "inherited": ["inherited from her grandmother", "passed down from her mother"],
        "chosen": ["carefully chosen for this special occasion", "selected for the photoshoot"],
        "favorite": ["her favorite from last summer", "one she's been meaning to wear"]
    }
    
    def generate(self, genre="korean_drama", character_type="art_student",
                 emotion_type="lost_in_thought", theme=None, clothing_context="bought"):
        """스토리 컨텍스트 생성"""
        # 테마 자동 선택 (미지정 시)
        if theme is None:
            theme = random.choice(list(self.THEMES.values())[0])
        
        # 스토리 구성
        story = self.GENRES[genre].format(
            theme=theme,
            location=random.choice(self.LOCATIONS)
        )
        
        character = self.CHARACTERS[character_type].format(
            age=random.choice(self.AGES),
            name=random.choice(self.NAMES)
        )
        
        emotion_options = self.EMOTIONS[emotion_type]
        emotion = random.choice(emotion_options).format(
            thought=random.choice(self.THOUGHTS),
            memory=random.choice(self.MEMORIES),
            aspiration=random.choice(self.ASPIRATIONS),
            moment=random.choice(self.MOMENTS),
            question=random.choice(self.QUESTIONS)
        )
        
        clothing = random.choice(self.CLOTHING_CONTEXT[clothing_context])
        
        # 조합
        return f"{story}: {character}, {emotion}. She's wearing her outfit that she {clothing}."
    
    def generate_simple(self, genre="korean_drama", theme=None):
        """단순한 스토리 컨텍스트 (의상 맥락 없음)"""
        if theme is None:
            theme = random.choice(["summer romance", "freedom", "self-discovery"])
        
        story = self.GENRES[genre].format(
            theme=theme,
            location=random.choice(self.LOCATIONS)
        )
        
        character = self.CHARACTERS[random.choice(list(self.CHARACTERS.keys()))].format(
            age=random.choice(self.AGES),
            name=random.choice(self.NAMES)
        )
        
        return f"{story}: {character}."

# 테스트
if __name__ == "__main__":
    generator = StoryGenerator()
    
    print("Full story:")
    print(generator.generate())
    print("\nSimple story:")
    print(generator.generate_simple())
