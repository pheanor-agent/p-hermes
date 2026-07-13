#!/usr/bin/env python3
"""Normalize v8 lecture decks to the Deck A/B Zone and interaction contract."""
from __future__ import annotations

import re
from pathlib import Path

DECK_DIR = Path(__file__).resolve().parents[1] / "docs/playground/lectures/v8"

BASE_CSS = r'''
/* ── Deck A/B shared contract: injected by normalize-lecture-deck-contract.py ── */
.slide { min-height:100vh; display:flex; flex-direction:column; position:relative; overflow:hidden; }
.slide-header { flex:0 0 80px; display:flex; align-items:center; justify-content:space-between; padding:0 48px; z-index:10; }
.slide-body { flex:1 1 auto; min-height:0; display:flex; align-items:center; justify-content:center; padding:32px 48px; position:relative; }
.slide-footer { flex:0 0 48px; display:flex; align-items:center; justify-content:center; padding:0 48px; border-top:1px solid var(--border); }
.slide-footer span { font-size:13px; line-height:1.4; color:var(--text-dim); font-weight:500; text-align:center; }
.hero-slide .slide-footer, .qa-slide .slide-footer, .section-divider .slide-footer { border-top-color:rgba(255,255,255,.12); }
.section-divider { background:var(--bg-dark); color:var(--text-light); }
.section-divider .slide-header, .section-divider .slide-footer { display:none; }
.section-divider .slide-body { padding:0; }
.section-divider .divider-content { display:flex; flex-direction:column; align-items:center; text-align:center; gap:16px; }
.section-divider .divider-label { font-size:11px; font-weight:700; letter-spacing:.12em; text-transform:uppercase; color:var(--accent); }
.section-divider .divider-title { font-size:clamp(36px,5vw,60px); font-weight:900; letter-spacing:-.03em; }
.section-divider .divider-desc { max-width:580px; font-size:20px; color:rgba(255,255,255,.62); line-height:1.6; }
.intro-slide .slide-body, .compare-slide .slide-body, .deep-slide .slide-body { flex-direction:column; }
.intro-slide .intro-content, .compare-slide .compare-content, .deep-slide .deep-content { width:min(100%,1100px); }
.deep-content { display:flex; flex-direction:column; gap:22px; }
.deep-slide .slide-body > .animate > h2 { display:none; }
.deep-header { display:flex; align-items:center; gap:18px; text-align:left; }
.deep-title { font-size:36px; font-weight:900; letter-spacing:-.02em; }
.deep-subtitle { font-size:16px; color:var(--text-dim); line-height:1.5; }
.tab-nav { display:flex; gap:8px; border-bottom:2px solid var(--border); }
.tab-btn { padding:10px 18px; border:0; border-bottom:3px solid transparent; background:none; color:var(--text-dim); font:600 15px var(--font); cursor:pointer; }
.tab-btn:hover, .tab-btn.active, .tab-btn.in-focus { color:var(--accent); border-bottom-color:var(--accent); background:var(--highlight); }
.tab-panel { display:none; padding:18px 22px; background:var(--card); border:1px solid var(--border); border-radius:12px; font-size:15px; line-height:1.6; }
.tab-panel.active { display:block; }
.compare-slide .split-screen, .compare-slide .vs-container { width:min(100%,1100px); }
[data-focusable].in-focus { outline:3px solid var(--accent); outline-offset:4px; }
.slide.mouse-hovering [data-focusable].in-focus { outline:none; box-shadow:none; pointer-events:auto; }
.nav-arrow { display:none !important; }
.combo-counter { display:none !important; }
.click-combo-display { position:fixed; top:16px; right:16px; z-index:9999; background:var(--accent); color:white; padding:8px 16px; border-radius:99px; font-weight:800; opacity:0; transform:scale(.8); transition:.2s; pointer-events:none; }
.click-combo-display.visible { opacity:1; transform:scale(1); }
.click-game-score,.click-game-particle,.click-game-sparkle { position:absolute; pointer-events:none; z-index:20; }
.click-game-score { color:var(--accent); font-size:24px; font-weight:900; animation:score-float 1s ease-out forwards; }
.click-game-particle { width:6px; height:6px; border-radius:50%; animation:particle-fly .8s ease-out forwards; }
.click-game-sparkle { font-size:16px; animation:sparkle-twinkle .6s ease-out forwards; }
@keyframes score-float { to { transform:translateY(-76px); opacity:0; } }
@keyframes particle-fly { to { transform:translate(var(--tx),var(--ty)) scale(0); opacity:0; } }
@keyframes sparkle-twinkle { to { transform:translateY(-32px) rotate(180deg) scale(0); opacity:0; } }
@media (max-width:768px) { .slide-header,.slide-body,.slide-footer { padding-left:24px; padding-right:24px; } .slide-footer { flex-basis:44px; } }
'''

BASE_JS = r'''<script>
/* Deck A/B shared navigation + focus + click interaction contract. */
const slides = Array.from(document.querySelectorAll('.slide'));
const navDots = document.getElementById('navDots');
const progressBar = document.getElementById('progressBar');
let currentSlide = 0;
let currentFocus = -1;
let clickCombo = 0;
let comboTimer = null;

slides.forEach((slide, index) => {
  const dot = document.createElement('button');
  dot.className = 'nav-dot' + (index === 0 ? ' active' : '');
  dot.type = 'button'; dot.setAttribute('aria-label', `슬라이드 ${index + 1}`);
  dot.addEventListener('click', () => goSlide(index));
  navDots.appendChild(dot);
});
const dots = Array.from(document.querySelectorAll('.nav-dot'));
const focusables = slide => Array.from(slide.querySelectorAll('[data-focusable]'));
function updateFocus() {
  document.querySelectorAll('.in-focus').forEach(el => el.classList.remove('in-focus'));
  const items = focusables(slides[currentSlide]);
  if (currentFocus >= 0 && currentFocus < items.length) items[currentFocus].classList.add('in-focus');
}
function updateSlide() {
  currentSlide = Math.max(0, Math.min(currentSlide, slides.length - 1));
  progressBar.style.width = `${((currentSlide + 1) / slides.length) * 100}%`;
  slides.forEach((slide, index) => slide.classList.toggle('active', index === currentSlide));
  dots.forEach((dot, index) => dot.classList.toggle('active', index === currentSlide));
  currentFocus = focusables(slides[currentSlide]).length ? 0 : -1;
  updateFocus();
}
function goSlide(index) {
  currentSlide = index;
  window.scrollTo({top: slides[index].offsetTop, behavior:'auto'});
  updateSlide();
}
function moveFocus(direction) {
  const items = focusables(slides[currentSlide]);
  if (!items.length) return;
  currentFocus = Math.max(0, Math.min(currentFocus + direction, items.length - 1));
  updateFocus();
  const focused = items[currentFocus];
  if (focused.classList.contains('tab-btn')) switchTab(focused);
}
function switchTab(button) {
  const slide = button.closest('.slide');
  const key = button.dataset.tab;
  slide.querySelectorAll('.tab-btn').forEach(item => item.classList.toggle('active', item === button));
  slide.querySelectorAll('.tab-panel').forEach(panel => panel.classList.toggle('active', panel.dataset.tab === key));
}
document.addEventListener('keydown', event => {
  const key = event.key;
  if (key === 'ArrowLeft' || key === 'ArrowRight') { event.stopImmediatePropagation(); event.preventDefault(); moveFocus(key === 'ArrowLeft' ? -1 : 1); }
  if (key === 'ArrowUp' || key === 'PageUp') { event.stopImmediatePropagation(); event.preventDefault(); goSlide(Math.max(0,currentSlide-1)); }
  if (key === 'ArrowDown' || key === 'PageDown') { event.stopImmediatePropagation(); event.preventDefault(); goSlide(Math.min(slides.length-1,currentSlide+1)); }
}, true);
const slideObserver = new IntersectionObserver(entries => entries.forEach(entry => {
  if (entry.isIntersecting) { currentSlide = slides.indexOf(entry.target); updateSlide(); }
}), {threshold:.5});
slides.forEach(slide => slideObserver.observe(slide));
function triggerClickGame(slide, x, y) {
  const rect = slide.getBoundingClientRect(), left = x - rect.left, top = y - rect.top;
  clickCombo++; clearTimeout(comboTimer);
  const display = document.getElementById('comboDisplay');
  document.getElementById('comboCount').textContent = clickCombo;
  display.classList.toggle('visible', clickCombo > 1);
  comboTimer = setTimeout(() => { clickCombo=0; display.classList.remove('visible'); }, 2000);
  const score = document.createElement('div'); score.className='click-game-score'; score.textContent=`+${Math.min(clickCombo,5)}`; score.style.left=`${left}px`; score.style.top=`${top}px`; slide.appendChild(score); setTimeout(()=>score.remove(),1000);
  for(let i=0;i<8;i++) { const node=document.createElement('div'); node.className='click-game-particle'; const a=(Math.PI*2*i)/8; node.style.left=`${left}px`; node.style.top=`${top}px`; node.style.background='var(--accent)'; node.style.setProperty('--tx',`${Math.cos(a)*(36+Math.random()*42)}px`); node.style.setProperty('--ty',`${Math.sin(a)*(36+Math.random()*42)}px`); slide.appendChild(node); setTimeout(()=>node.remove(),800); }
}
slides.forEach(slide => {
  const items = focusables(slide); let lastHovered = -1;
  items.forEach((item,index) => { item.addEventListener('mouseenter',()=>{lastHovered=index;slide.classList.add('mouse-hovering');}); item.addEventListener('mouseleave',()=>{slide.classList.remove('mouse-hovering'); if(lastHovered>=0){currentFocus=lastHovered;updateFocus();}}); item.addEventListener('click', event => { if(item.classList.contains('tab-btn')) switchTab(item); triggerClickGame(slide,event.clientX,event.clientY); }); });
  slide.addEventListener('click', event => { if (!event.target.closest('[data-focusable]')) triggerClickGame(slide,event.clientX,event.clientY); });
});
updateSlide();
</script>'''

MAP = {
 "deck-c-skill.html": {
  "tag":"Deck C", "topic":"Skill 심화", "accent":"var(--skill)",
  "classes": {1:"intro-slide",2:"intro-slide",3:"compare-slide",4:"compare-slide",8:"deep-slide",14:"deep-slide",23:"compare-slide",30:"compare-slide",34:"content-slide"},
  "dividers": {6:("01", "Skill의 본질", "반복 가능한 절차가 결과의 일관성을 만듭니다"),12:("02", "Skill의 구조", "SKILL.md와 지원 파일이 실행 가능한 지식을 구성합니다"),18:("03", "Skill의 실행", "탐색·매개변수·분기·복구를 하나의 절차로 묶습니다"),24:("04", "Skill의 진화", "패치·버전·검증으로 절차를 신뢰 가능한 자산으로 만듭니다"),29:("05", "시스템 통합", "Skill은 Memory·Knowledge·Workflow와 연결될 때 완성됩니다")},
  "tabs": {8:[("structure","SKILL.md", "하나의 Skill은 트리거, 단계, 주의사항, 검증 기준을 갖는 실행 계약입니다."),("metadata","Frontmatter", "이름·설명·태그는 Agent가 적합한 Skill을 찾고 선택하는 기준입니다."),("body","본문", "단계와 예외 처리는 사람이 이해하고 Agent가 재현할 수 있는 순서로 기록합니다.")],14:[("discover","발견", "도메인과 설명을 기준으로 후보 Skill을 좁힙니다."),("select","선택", "작업 조건과 위험도를 비교해 한 개의 절차를 선택합니다."),("verify","검증", "실행 전후 조건을 확인해 잘못된 적용을 막습니다.")]},
 },
 "deck-d-workflow.html": {
  "tag":"Deck D", "topic":"Workflow 심화", "accent":"var(--workflow)",
  "classes": {1:"intro-slide",2:"intro-slide",3:"compare-slide",4:"compare-slide",5:"compare-slide",9:"deep-slide",14:"deep-slide",19:"compare-slide",24:"compare-slide",43:"compare-slide",44:"content-slide"},
  "dividers": {7:("01", "계획", "요청을 조사·설계·검토하고 사용자 승인으로 실행 범위를 고정합니다"),18:("02", "실행", "허용된 전이와 검증으로 작업을 통제 가능한 상태로 진행합니다"),23:("03", "승인과 복구", "Agent는 승인자가 아니며 실패는 추적 가능한 롤백으로 다룹니다"),28:("04", "추적", "JOB은 작업의 근거·산출물·검증을 한 곳에 남깁니다"),36:("05", "협업", "서브에이전트도 상태·소유권·결과를 가진 작업 단위입니다")},
  "tabs": {9:[("plan","계획", "Request → Investigation → Design → Review → Approval은 실행 전 불확실성을 줄이는 구간입니다."),("execute","실행", "Execution → Test → Execution Review는 승인된 설계를 구현하고 검증하는 구간입니다."),("close","완료", "Done은 결과·검증·교훈이 남았을 때만 도달합니다.")],14:[("authority","권한", "Approval은 사용자만 결정하며 Agent는 근거와 선택지를 제공합니다."),("evidence","근거", "검토 가능한 설계·리스크·산출물이 승인 판단의 입력입니다."),("rollback","복구", "실패 시 현재 상태와 변경 범위를 기록하고 안전한 지점으로 되돌립니다.")]},
 }
}

def section_replacer(config: dict, number: int, attrs: str, content: str) -> str:
    classes = re.search(r'class="([^"]+)"', attrs).group(1).split()
    if number in config['dividers']:
        for value in ('act-slide','section-divider'):
            if value not in classes: classes.append(value)
        index, title, description = config['dividers'][number]
        content = f'''\n  <div class="slide-header"></div>\n  <div class="slide-body"><div class="divider-content animate" data-delay="1"><div class="divider-label">Part {index}</div><h2 class="divider-title">{title}</h2><p class="divider-desc">{description}</p></div></div>\n  <div class="slide-footer"></div>\n'''
    else:
        new_class = config['classes'].get(number)
        if new_class and new_class not in classes: classes.append(new_class)
        if 'slide-footer' not in content:
            heading = re.search(r'<h[1-3][^>]*>(.*?)</h[1-3]>', content, re.S)
            heading_html = heading.group(1) if heading else config['topic']
            title = re.sub('<[^>]+>', '', re.sub(r'<br\s*/?>', ' ', heading_html, flags=re.I)).strip().replace('\n',' ')
            takeaway = f"{config['topic']} · {title}"
            content += f'\n  <div class="slide-footer"><span class="animate" data-delay="5">{takeaway}</span></div>\n'
        if number in config['tabs'] and 'class="tab-nav"' not in content:
            tabs = config['tabs'][number]
            controls = ''.join(f'<button class="tab-btn{" active" if i == 0 else ""}" type="button" data-focusable data-tab="{key}">{label}</button>' for i,(key,label,_) in enumerate(tabs))
            panels = ''.join(f'<div class="tab-panel{" active" if i == 0 else ""}" data-tab="{key}">{text}</div>' for i,(key,_,text) in enumerate(tabs))
            title = re.search(r'<h[1-3][^>]*>(.*?)</h[1-3]>', content, re.S)
            clean_title = re.sub('<[^>]+>','',title.group(1)).strip().replace('\n',' ') if title else config['topic']
            component = f'<div class="deep-content animate" data-delay="2"><div class="deep-header"><div><h2 class="deep-title">{clean_title}</h2><p class="deep-subtitle">핵심 개념을 선택해 살펴보세요</p></div></div><div class="tab-nav">{controls}</div>{panels}</div>'
            body_end = content.find('</div>', content.find('class="slide-body'))
            if body_end != -1: content = content[:body_end] + component + content[body_end:]
    attrs = re.sub(r'class="[^"]+"', f'class="{" ".join(classes)}"', attrs)
    return f'<section{attrs}>{content}</section>'

def transform(name: str, config: dict) -> None:
    path = DECK_DIR / name
    text = path.read_text()
    # The injected stylesheet is intentionally identified by its first comment.
    # Accept whitespace after <style> so repeated runs stay idempotent.
    text = re.sub(
        r'<style>\s*/\* ── Deck A/B shared contract: injected by normalize-lecture-deck-contract.py ── \*/.*?</style>',
        '',
        text,
        flags=re.S,
    )
    text = re.sub(r'<div class="combo-counter"[^>]*>.*?</div>\s*', '', text, flags=re.S)
    text = re.sub(r'<button[^>]*class="nav-arrow"[^>]*>.*?</button>\s*', '', text, flags=re.S)
    text = text.replace('</head>', f'<style>{BASE_CSS}</style></head>')
    text = re.sub(r'<section([^>]*) id="slide-(\d+)"([^>]*)>(.*?)</section>', lambda m: section_replacer(config, int(m.group(2)), m.group(1) + f' id="slide-{m.group(2)}"' + m.group(3), m.group(4)), text, flags=re.S)
    text = re.sub(r'<script>.*?</script>\s*</body>', BASE_JS + '\n</body>', text, flags=re.S)
    text = text.replace('<div class="nav-dots" id="navDots"></div>', '<div class="nav-dots" id="navDots" aria-label="슬라이드 탐색"></div><div class="click-combo-display" id="comboDisplay"><span id="comboCount">0</span> COMBO</div>')
    text = re.sub(r'(<(?:div|section) class="(?:feature-card|concept-card|problem-card|solution-card|before-panel|after-panel|scenario-card|flow-step|process-step|protocol-step|conn-node)[^"]*")', r'\1 data-focusable', text)
    # Attribute injection must be idempotent: normalizing an already-normalized
    # deck keeps one focus marker per interactive component.
    text = re.sub(r'(?:\sdata-focusable){2,}', ' data-focusable', text)
    path.write_text(text)

for filename, config in MAP.items():
    transform(filename, config)
    print(f'normalized {filename}')
