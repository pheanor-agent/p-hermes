#!/bin/bash
#==============================================================================
HERMES_ROOT="${HERMES_ROOT:-$HOME/.hermes}"
# send.sh - IT 뉴스 Telegram 전송 (개선版)
#==============================================================================
# 실행: 09:00, 19:00 (Hermes cron)
# 입력: ~/.openclaw/workspace/memory/tech-news/
# 출력: Telegram AI뭐야 채널 (-1003938942705)
#==============================================================================

set -uo pipefail  # set -e 제거: 에러 핸들링 개선

WORKSPACE="${WORKSPACE:-/home/bot/.openclaw/workspace}"
MEMORY_DIR="$WORKSPACE/memory/tech-news"
LOG_DIR="$WORKSPACE/memory/logs"
LOG_FILE="$LOG_DIR/send.log"

TODAY=$(date '+%Y-%m-%d')
YESTERDAY=$(date -d "yesterday" '+%Y-%m-%d')

# 로깅
log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" >> "$LOG_FILE"
}

# ============================================================================
# 메인
# ============================================================================

log "INFO" "=== send.sh 시작 ($TODAY) ==="

# freshness 체크: 24시간 이내 뉴스 파일 존재 여부
FRESH_COUNT=$(find "$MEMORY_DIR" -maxdepth 1 -type f \( -name "${TODAY}-*.md" -o -name "${YESTERDAY}-*.md" \) 2>/dev/null | wc -l)

if [ "$FRESH_COUNT" -eq 0 ]; then
    log "WARN" "24시간 이내 뉴스 파일 없음 - fetch.sh inline 실행"
    echo "📡 새로운 뉴스 없음, fetch.sh 실행 중..."
    bash "$HERMES_ROOT/core/scripts/fetch.sh" 2>&1 || {
        log "WARN" "fetch.sh 실패 - 전송 skip"
        echo "ℹ️ 뉴스 수집 실패 - 전송 skip"
        exit 0
    }
    # 재체크
    FRESH_COUNT=$(find "$MEMORY_DIR" -maxdepth 1 -type f -name "${TODAY}-*.md" 2>/dev/null | wc -l)
    if [ "$FRESH_COUNT" -eq 0 ]; then
        log "INFO" "fetch 후에도 뉴스 없음 - 전송 skip"
        echo "ℹ️ 뉴스 수집 후에도 전송할 내용 없음"
        exit 0
    fi
fi

# Python으로 뉴스 파일 읽기 + PICK 5 + Telegram 전송
python3 << 'PYEOF'
import os
import glob
import json
import re
import requests
import hashlib
from datetime import datetime, timedelta

# 설정
MEMORY_DIR = os.path.expanduser('~/.openclaw/workspace/memory/tech-news')
LOG_DIR = os.path.expanduser('~/.openclaw/workspace/memory/logs')
LOG_FILE = os.path.join(LOG_DIR, 'send.log')
TELEGRAM_CHAT_ID = -1003938942705  # AI뭐야
SENT_MESSAGES_FILE = os.path.join(MEMORY_DIR, 'sent-messages.txt')

# Bot Token 읽기
env_path = os.path.expanduser('$HERMES_ROOT/.env')
bot_token = ""
with open(env_path) as f:
    for line in f:
        if line.startswith('TELEGRAM_BOT_TOKEN=') and not line.startswith('#'):
            bot_token = line.split('=', 1)[1].strip().strip('"')
            break

if not bot_token:
    log("ERROR", "TELEGRAM_BOT_TOKEN 없음")
    print("❌ TELEGRAM_BOT_TOKEN 없음")
    exit(1)

# 로깅 함수
def log(level, msg):
    ts = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    with open(LOG_FILE, 'a') as f:
        f.write(f"[{ts}] [{level}] {msg}\n")

# 날짜
today = datetime.now().strftime('%Y-%m-%d')
yesterday = (datetime.now() - timedelta(days=1)).strftime('%Y-%m-%d')

# 최신 뉴스 파일 찾기
news_files = sorted(
    glob.glob(f"{MEMORY_DIR}/{today}-*.md") + glob.glob(f"{MEMORY_DIR}/{yesterday}-*.md"),
    key=os.path.getmtime,
    reverse=True
)

if not news_files:
    log("INFO", "뉴스 파일 없음 - 전송 생략")
    print("⚠️ 뉴스 파일 없음 - 전송 생략")
    exit(0)

news_file = news_files[0]
log("INFO", f"뉴스 파일: {news_file}")

# 빈 파일 체크 (100byte 미만이면 skip)
file_size = os.path.getsize(news_file)
if file_size < 100:
    log("INFO", f"빈 파일 감지 ({file_size}byte) - 전송 생략")
    print(f"⚠️ 빈 파일 감지 ({file_size}byte) - 전송 생략")
    exit(0)

# 뉴스 읽기
with open(news_file) as f:
    content = f.read()

# 뉴스 항목 추출 (markdown 링크 형식 + 소스 태그)
items = re.findall(r'- \[([^\]]+)\]\(([^)]+)\)\s*\[(\w+)\]', content)

if not items:
    log("INFO", "뉴스 항목 없음 - 전송 생략")
    print("⚠️ 뉴스 항목 없음 - 전송 생략")
    exit(0)

# 뉴스 수 threshold 체크
if len(items) < 3:
    log("INFO", f"뉴스 {len(items)}개 (threshold 3) - 전송 skip")
    print(f"ℹ️ 뉴스 {len(items)}개 (최소 3개 필요) - 전송 skip")
    exit(0)

# 소스 정규화
def normalize_source(src):
    mapping = {
        'HN': 'hackernews', 'GeekNews': 'geeknews', 'TechCrunch': 'techcrunch',
        'Anthropic': 'anthropic', 'OpenAI': 'openai', 'GoogleAI': 'google-ai',
        'ArsTechnica': 'ars-technica', 'TheVerge': 'the-verge',
        'MITTechReview': 'mit-tech-review', 'ProductHunt': 'product-hunt'
    }
    return mapping.get(src, src.lower())

# 카테고리 분류
CATEGORIES = {
    '🤖 AI·모델': ['ai', 'claude', 'gpt', 'llm', 'transformer', 'anthropic', 
                   'openai', 'google', 'gemini', 'deepseek', 'model'],
    '💻 개발·도구': ['code', 'dev', 'github', 'rust', 'python', 'docker', 
                    'kubernetes', 'devops', 'tool', 'cli', 'vscode', 'jetbrains'],
    '☁️ 인프라': ['aws', 'gcp', 'azure', 'cloud', 'server', 'database', 
                 'postgres', 'mongodb', 'infrastructure', 'deployment'],
    '🔒 보안': ['security', 'hack', 'cyber', 'vulnerability', 'attack', 'exploit'],
    '🚀 스타트업': ['startup', 'funding', 'series', 'venture', 'ipo', 'acquisition'],
    '📢 기타': []  # 기본값
}

def categorize(title):
    title_lower = title.lower()
    for category, keywords in CATEGORIES.items():
        if any(kw in title_lower for kw in keywords):
            return category
    return '📢 기타'

# PICK 5: 중요도/흥미 기반 알고리즘
def calculate_score(item, all_items, picked_items):
    """중요도/흥미 점수 계산"""
    score = 0
    title, url, source = item
    source = normalize_source(source)
    
    # 1. 소스 가중치 (신뢰도 기반)
    source_weights = {
        'anthropic': 1.0, 'openai': 1.0, 'google-ai': 0.9,
        'techcrunch': 0.9, 'ars-technica': 0.8, 'mit-tech-review': 0.8,
        'hackernews': 0.7, 'geeknews': 0.6, 'product-hunt': 0.5,
        'the-verge': 0.6
    }
    score += source_weights.get(source, 0.5) * 20
    
    # 2. 키워드 매칭 (관심도)
    hot_keywords = ['AI', 'Claude', 'GPT', 'OpenAI', 'Anthropic', 
                   'startup', 'funding', 'security', 'release', 'launch']
    title_lower = title.lower()
    score += sum(5 for kw in hot_keywords if kw.lower() in title_lower)
    
    # 3. 시의성 (24시간 이내 뉴스) - 파일명에서 시간 추정
    if 'today' in str(news_file):  # 단순화: 오늘 파일은 +10
        score += 10
    
    # 4. 중복 방지 (제목 유사도)
    for other_title, other_url, _ in all_items:
        if title != other_title and similarity(title, other_title) > 0.85:
            score -= 15  # 중복은 점수 감점
    
    # 5. 카테고리 다양성 보너스
    item_category = categorize(title)
    if not any(categorize(p[0]) == item_category for p in picked_items):
        score += 5
    
    return score

def similarity(s1, s2):
    """단순 문자열 유사도 (Jaccard)"""
    set1 = set(s1.lower().split())
    set2 = set(s2.lower().split())
    if not set1 or not set2:
        return 0
    return len(set1 & set2) / len(set1 | set2)

# PICK 5 실행
picked_items = []
remaining = list(items)
for _ in range(5):
    if not remaining:
        break
    best_score = -1
    best_item = None
    for item in remaining:
        score = calculate_score(item, items, picked_items)
        if score > best_score:
            best_score = score
            best_item = item
    if best_item:
        picked_items.append(best_item)
        remaining.remove(best_item)

# 번역 캐시 (24h TTL)
TRANSLATION_CACHE = os.path.join(MEMORY_DIR, 'translations.json')

def load_cache():
    if os.path.exists(TRANSLATION_CACHE):
        try:
            with open(TRANSLATION_CACHE) as f:
                cache = json.load(f)
                # 24h TTL 적용
                now = datetime.now()
                valid_cache = {}
                for key, value in cache.items():
                    if isinstance(value, dict) and 'ts' in value:
                        ts = datetime.fromisoformat(value['ts'])
                        if (now - ts).total_seconds() < 86400:  # 24h
                            valid_cache[key] = value
                    else:
                        # 레거시 캐시는 무시 (첫 실행 시 자동 갱신)
                        pass
                return valid_cache
        except:
            pass
    return {}

def save_cache(cache):
    with open(TRANSLATION_CACHE, 'w') as f:
        json.dump(cache, f, ensure_ascii=False, indent=2)

cache = load_cache()
def translate_and_summarize(title, url, cache, use_llm=False):
    """airrouter 경유 번역 + 요약 (타임아웃 적용)"""
    import hashlib
    key = hashlib.md5(f"{title}|{url}".encode()).hexdigest()
    
    if key in cache:
        return cache[key]['data']
    
    # LLM 사용이 아니면 키워드 기반 폴백으로 즉시 반환
    if not use_llm:
        why_care = generate_why_care(title, url)
        keywords = generate_keywords(title)
        # 간단한 제목 번역 시도
        simple_title = translate_title_simple(title)
        summary = generate_summary_simple(title, url)
        return {'title': simple_title, 'summary': summary, 'why_care': why_care, 'keywords': keywords}
    
    # airrouter 경유 (auxiliary_client 사용) - 타임아웃 적용
    import sys
    import signal
    sys.path.insert(0, os.path.expanduser('$HERMES_ROOT/hermes-agent'))
    
    def timeout_handler(signum, frame):
        raise TimeoutError("LLM 호출 타임아웃")
    
    # 30초 타임아웃 설정
    signal.signal(signal.SIGALRM, timeout_handler)
    signal.alarm(30)
    
    try:
        from agent.auxiliary_client import call_llm
        
        prompt = f"""당신은 뉴스 에디터다. 아래 뉴스를 일반人也关係될 수 있도록 한글로 번역하고 요약해줘.

제목: {title}
링크: {url}

중요 규칙:
1. summary는 절대 제목을 반복하지 말 것! 제목에는 없는 구체적 정보만 넣을 것 (숫자, 날짜, 원인, 결과)
2. why_care는 이 뉴스를 왜 흥미롭게 봐야 하는지 한 줄로 설명할 것
3. 모든 필드를 반드시 채울 것 (빈 문자열 금지)

반드시 아래 JSON 형식으로 출력:
{{
    "title": "한글로 번역한 제목 (15자 이내, 간결하게)",
    "summary": "제목에 없는 구체적 정보 2-3문장. 무슨 일이 발생했는지, 원인은 무엇인지, 결과가 무엇인지 설명. 기술 용어는 쉬운 말로 설명",
    "why_care": "왜 흥미로운지/중요한지. 일반人也关係될 수 있는 관점. '이게 왜 중요한가'에 대한 답",
    "keywords": ["핵심", "키워드", "3개"]
}}

예시 1:
{{
    "title": "Claude 4 출시",
    "summary": "이전 버전보다 40% 빠르고, 복잡한 문서 분석이나 코드 작성에서 인간 수준에 근접한 성능을 보인다. 기업용으로 즉시 이용 가능할 전망이다.",
    "why_care": "기존 ChatGPT/Claude 사용자라면 곧 더 똑똑한 AI를 쓸 수 있게 됨",
    "keywords": ["AI", "Chatbot", "출시"]
}}

예시 2:
{{
    "title": "앤트로픽, 안전 필터 사과",
    "summary": "롤�플레이 모델에 사용자에게 알리지 않은 숨겨진 필터가 있었다. 전문가들이 보안 연구를 하려 해도 AI가 '위험하다'며 답변을 막았기 때문이다.",
    "why_care": "AI가 '안전'을 이유로 오히려 보안 연구를 방해하는 아이러니 - 더 취약한 시스템이 만들어질 수 있음",
    "keywords": ["AI", "보안", "논란"]
}}

이제 아래 뉴스를 처리해줘:
"""
        
        result = call_llm(
            task='news-translate',
            messages=[{'role': 'user', 'content': prompt}],
            max_tokens=2000
        )
        signal.alarm(0)  # 타임아웃 해제
        
        # ChatCompletion 객체에서 content 추출
        content = ''
        if hasattr(result, 'choices') and result.choices:
            msg = result.choices[0].message
            content = getattr(msg, 'content', '') or ''
        elif isinstance(result, dict):
            content = result.get('content', '') or ''
        
        # JSON 파싱 (멀티라인 지원)
        import re
        json_match = re.search(r'\{[\s\S]*"title"[\s\S]*"summary"[\s\S]*\}', content)
        if json_match:
            data = json.loads(json_match.group())
            cache[key] = {'data': data, 'ts': datetime.now().isoformat()}
            return data
    except TimeoutError:
        log("WARN", f"번역 타임아웃: {title[:50]}...")
    except Exception as e:
        log("WARN", f"번역 실패: {e}")
    finally:
        signal.alarm(0)  # 타임아웃 해제
    
    # 폴백: 원문 유지 (최소한의 처리)
    # 키워드 기반 why_care 자동 생성
    why_care = generate_why_care(title, url)
    keywords = generate_keywords(title)
    return {'title': title, 'summary': f"({url})", 'why_care': why_care, 'keywords': keywords}

def generate_why_care(title, url):
    """키워드 기반 why_care 자동 생성 (다양성 확보, 중복 최소화)"""
    title_lower = title.lower()
    
    # 더 구체적 매핑 (우선순위 기반)
    if 'claude' in title_lower:
        return "내가 sehari로 쓰는 AI 도구가 어떻게 변하는지 알 수 있음"
    elif 'chatgpt' in title_lower:
        return "대중적 AI 어시스턴트의 방향성을 파악할 수 있음"
    elif 'openai' in title_lower or 'gpt' in title_lower:
        return "OpenAI의 방향성은 전 세계 AI 서비스 트렌드를 주도"
    elif 'google' in title_lower and 'ai' in title_lower:
        return "구글의 AI 움직임은 검색, 클라우드, 스마트폰까지 영향"
    elif 'security' in title_lower or 'hack' in title_lower or 'cyber' in title_lower:
        return "보안 문제는 우리 모든 사람의 개인정보와 직결된 문제"
    elif 'funding' in title_lower or 'invest' in title_lower:
        return "스타트업 동향은 미래 일자리와 시장 변화를 예측할 수 있는 지표"
    elif 'startup' in title_lower:
        return "신규 서비스 트렌드를 파악하면 일상에 활용할 수 있음"
    elif 'opensource' in title_lower or 'github' in title_lower:
        return "오픈소스 기술은 누구나 무료로 활용 가능하고, 개발 생태계에 영향"
    elif 'fire' in title_lower or 'layoff' in title_lower or 'sued' in title_lower:
        return "테크 업계 인사 변동은 기업 문화와 미래 방향성을 보여줌"
    elif 'release' in title_lower or 'launch' in title_lower:
        return "새로운 기술 출시 경쟁은 소비자에게 더 좋은 서비스 제공으로 연결"
    elif 'safety' in title_lower or 'guardrail' in title_lower:
        return "AI 안전 장치는 내가 쓰는 AI 서비스의 한계를 결정"
    elif 'outsource' in title_lower or 'india' in title_lower:
        return "글로벌 아웃소싱 변화는 일자리와 기업 전략에 영향"
    else:
        return "기술 트렌드를 파악하면 비즈니스와 일상에 활용할 수 있는 기회 발견"

def generate_keywords(title):
    """키워드 기반 자동 태그 생성"""
    title_lower = title.lower()
    keywords = []
    
    if any(kw in title_lower for kw in ['ai', 'claude', 'gpt', 'llm', 'anthropic', 'openai']):
        keywords.append("AI")
    if any(kw in title_lower for kw in ['security', 'hack', 'cyber', 'safety']):
        keywords.append("보안")
    if any(kw in title_lower for kw in ['startup', 'funding', 'investment', 'series']):
        keywords.append("스타트업")
    if any(kw in title_lower for kw in ['opensource', 'open source', 'github', 'rust', 'python']):
        keywords.append("오픈소스")
    if any(kw in title_lower for kw in ['apple', 'google', 'microsoft', 'amazon']):
        keywords.append("테크기업")
    if any(kw in title_lower for kw in ['release', 'launch', '출시', '발표']):
        keywords.append("출시")
    
    return keywords[:3] if keywords else ["기술"]

# 간단한 제목 번역 매핑
TITLE_TRANSLATIONS = {
    'Anthropic': '앤트로픽', 'OpenAI': 'OpenAI', 'Google': '구글',
    'Microsoft': '마이크로소프트', 'Apple': '애플', 'Claude': '클로드',
    'GPT': 'GPT', 'Grok': '구로크', 'xAI': '엑스AI',
    'releases': '출시', 'launches': '출시', 'apologizes': '사과',
    'fired': '해고', 'hacked': '해킹', 'acquired': '인수',
    'DiffusionGemma': '디퓨전제마', 'DeepMind': '딥마인드',
}

def translate_title_simple(title):
    """단어 치환 기반 간단 제목 번역 (truncation 제거)"""
    result = title
    for en, ko in TITLE_TRANSLATIONS.items():
        result = result.replace(en, ko)
    # truncation 제거 - 원문 길이 유지
    return result

def generate_summary_simple(title, url):
    """키워드 기반 간단 요약 생성 (구체적)"""
    title_lower = title.lower()
    
    # 더 구체적 패턴 매칭
    if 'diffusion' in title_lower or 'gemma' in title_lower:
        return "로컬 환경에서 AI 모델을 4배 빠르게 실행할 수 있는 오픈소스 모델을 발표했다. 개인 컴퓨터에서도 고성능 AI를 돌릴 수 있게 되면서, 클라우드 비용 부담이 줄어들 전망이다."
    elif 'fable' in title_lower or 'guardrail' in title_lower:
        return "AI 모델에 사용자에게 알리지 않은 숨겨진 안전 필터가 있었다. 전문가들이 보안 연구를 하려 해도 AI가 '위험하다'며 답변을 막았기 때문이다."
    elif 'india' in title_lower and 'exit' in title_lower:
        return "인도 아웃소싱 센터를 철수하면서 AI 기술 발전이 기존 인력 아웃소싱 모델에 미칠 영향과 한계에 대한 업계의 광범위한 논의가 촉발되고 있다."
    elif 'dario' in title_lower or 'report' in title_lower:
        return "CEO가 직속 보고 대상을 단 한 명으로만 유지하며 조직의 민첩성과 효율적인 의사결정을 추구하는 독특한 경영 스타일을 보이고 있다."
    elif 'sued' in title_lower or 'lawsuit' in title_lower:
        return "새로운 소송이 AI 모델의 안전성 문제를 경고했던 엔지니어를 해고했다는 사실을 주장하며業界의 관심을 끌고 있다."
    elif 'release' in title_lower or 'launch' in title_lower or 'announce' in title_lower:
        return "새로운 제품/서비스가 출시되었습니다. 자세한 내용은 링크에서 확인하세요."
    elif 'apologize' in title_lower or 'sorry' in title_lower:
        return "관련 사안에 대해 공식 사과를 발표했습니다."
    elif 'fire' in title_lower or 'layoff' in title_lower:
        return "인사 변동이 발생했습니다. 업계에 파장을 일으킬 수 있는 소식입니다."
    elif 'hack' in title_lower or 'breach' in title_lower or 'security' in title_lower:
        return "보안 관련 사건이 발생했습니다. 개인정보 보호에 주의가 필요합니다."
    elif 'funding' in title_lower or 'invest' in title_lower:
        return "투자/자금 조달 소식이 전파되었습니다. 시장 동향에 주목할 만합니다."
    else:
        return "기술 업계에서 주목할 만한 동향입니다. 링크에서 자세한 내용을 확인하세요."

# 메시지 구성 (보고서 스타일)
translated = []
for i, (title, url, source) in enumerate(picked_items):
    # 모든 뉴스에 LLM 번역 적용 (최적 품질)
    result = translate_and_summarize(title, url, cache, use_llm=True)
    category = categorize(title)
    translated.append((result.get('title', title), result.get('summary', ''), result.get('why_care', ''), result.get('keywords', []), url, source, category))

# 캐시 저장 (전체 번역 후 한 번에 저장)
save_cache(cache)

# 보고서 스타일 메시지 (설명만, 한글, 고유명사 원어)
message = f"📰 오늘의 IT 뉴스 PICK 5\n"
message += f"━━━━━━━━━━━━━━━━━━━━━━\n"
message += f"📅 {today} • {len(translated)}개 뉴스 선정\n\n"

for i, (title, summary, why_care, keywords, url, source, category) in enumerate(translated, 1):
    # 설명 (요약 + why_care 병합)
    desc = ""
    if summary:
        desc += summary
    if why_care:
        if desc:
            desc += "\n\n"
        desc += why_care
    
    if desc:
        # 줄바꿈 정리
        desc_lines = desc.strip().split('\n')
        message += f"{i}. {desc_lines[0].strip()}\n"
        for line in desc_lines[1:]:
            if line.strip():
                message += f"   {line.strip()}\n"
            else:
                message += "\n"
    
    # 링크
    message += f"\n   🔗 {url}\n"
    
    # 구분선 (마지막 항목 제외)
    if i < len(translated):
        message += f"\n   ────────────────────────\n\n"

message += f"\n━━━━━━━━━━━━━━━━━━━━━━\n"
message += f"🤖 에르메스 자동 수집 • {datetime.now().strftime('%H:%M')}"

# Idempotency 체크: 이미 보낸 메시지인지 확인
def is_already_sent(content_hash):
    if not os.path.exists(SENT_MESSAGES_FILE):
        return False
    with open(SENT_MESSAGES_FILE) as f:
        return content_hash in f.read()

def record_sent(content_hash):
    with open(SENT_MESSAGES_FILE, 'a') as f:
        f.write(f"{content_hash}\n")

# 메시지 해시 계산 (중복 체크)
content_hash = hashlib.md5('\n'.join([t for t, u, s in picked_items]).encode()).hexdigest()

if is_already_sent(content_hash):
    log("INFO", "이미 전송된 메시지 - 중복 전송 방지")
    print("ℹ️ 이미 전송된 메시지 - 중복 전송 방지")
    exit(0)

# Telegram 전송 (plain text) - 길이 체크
if len(message) > 4000:  # Telegram 4096자 제한 여유
    log("WARN", f"메시지 길이 초과 ({len(message)}자) - 요약문 축소")
    # 단순화: 각 항목의 summary를 1줄로 제한
    message = message[:3900] + "\n\n... (자르기)"

# 테스트 모드: stdout에 출력 (Telegram 전송 건너뜀)
if os.environ.get('TEST_MODE') == '1':
    print("=" * 60)
    print("📰 TEST OUTPUT")
    print("=" * 60)
    print(message)
    print("=" * 60)
    print("✅ 테스트 완료 (Telegram 전송 안함)")
    exit(0)

url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
data = {
    "chat_id": TELEGRAM_CHAT_ID,
    "text": message
}

try:
    resp = requests.post(url, json=data, timeout=30)
    result = resp.json()
    if result.get('ok'):
        msg_id = result['result']['message_id']
        record_sent(content_hash)
        log("INFO", f"Telegram 전송 완료 (message_id: {msg_id})")
        print(f"✅ Telegram 전송 완료 (message_id: {msg_id})")
    else:
        error_desc = result.get('description', 'Unknown error')
        log("ERROR", f"Telegram 전송 실패: {error_desc}")
        print(f"❌ Telegram 전송 실패: {error_desc}")
        exit(1)
except requests.exceptions.RequestException as e:
    log("ERROR", f"네트워크 에러: {str(e)}")
    print(f"❌ 네트워크 에러: {str(e)}")
    exit(1)
except json.JSONDecodeError as e:
    log("ERROR", f"JSON 파싱 에러: {str(e)}")
    print(f"❌ JSON 파싱 에러: {str(e)}")
    exit(1)
except Exception as e:
    log("ERROR", f"알 수 없는 에러: {str(e)}")
    print(f"❌ 알 수 없는 에러: {str(e)}")
    exit(1)
PYEOF

log "INFO" "=== send.sh 종료 ==="
echo "✅ send.sh 완료"
