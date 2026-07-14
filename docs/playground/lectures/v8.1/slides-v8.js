(() => {
  'use strict';

  const deckFiles = {
    a: 'deck-a-core.html',
    b: 'deck-b-knowledge.html',
    c: 'deck-c-skill.html',
    d: 'deck-d-workflow.html'
  };
  const deckNames = {
    a: 'Core',
    b: 'Knowledge',
    c: 'Skill',
    d: 'Workflow'
  };

  const body = document.body;
  const deck = body.dataset.deck || 'a';
  const slides = Array.from(document.querySelectorAll('.slide'));
  const progressBar = document.getElementById('progressBar');
  const navDots = document.getElementById('navDots');
  let currentSlide = 0;
  let currentFocus = -1;
  let scrolling = false;

  slides.forEach((slide, index) => {
    slide.querySelectorAll('.slide-number').forEach(number => {
      number.textContent = `${String(index + 1).padStart(2, '0')} / ${String(slides.length).padStart(2, '0')}`;
    });
  });

  const seriesNav = document.createElement('nav');
  seriesNav.className = 'series-nav';
  seriesNav.setAttribute('aria-label', 'Hermes 강의 덱');
  seriesNav.innerHTML = `
    <span class="series-mark" aria-hidden="true">H</span>
    <span class="series-name">Hermes Agent Lab</span>
    <span class="series-divider" aria-hidden="true"></span>
    ${Object.entries(deckFiles).map(([key, file]) =>
      `<a href="${file}" class="series-link${key === deck ? ' active' : ''}" ${key === deck ? 'aria-current="page"' : ''}><b>${key.toUpperCase()}</b><span>${deckNames[key]}</span></a>`
    ).join('')}
  `;
  body.appendChild(seriesNav);

  const presenter = document.createElement('div');
  presenter.className = 'presenter-controls';
  presenter.innerHTML = `
    <button type="button" data-action="prev" aria-label="이전 슬라이드">←</button>
    <button type="button" data-action="overview" class="presenter-position" aria-label="슬라이드 전체보기">01 / ${String(slides.length).padStart(2, '0')}</button>
    <button type="button" data-action="next" aria-label="다음 슬라이드">→</button>
    <span class="presenter-divider" aria-hidden="true"></span>
    <button type="button" data-action="fullscreen" aria-label="전체 화면">⛶</button>
  `;
  body.appendChild(presenter);

  const shortcutHint = document.createElement('div');
  shortcutHint.className = 'shortcut-hint';
  shortcutHint.textContent = '↑↓ 슬라이드 · ←→ 요소 · O 전체보기 · F 전체화면';
  body.appendChild(shortcutHint);

  if (navDots) {
    navDots.classList.add('slide-overview');
    navDots.innerHTML = '<div class="overview-head"><div><small>SLIDE MAP</small><strong>전체 슬라이드</strong></div><button type="button" data-overview-close aria-label="전체보기 닫기">×</button></div><div class="overview-grid"></div>';
    const grid = navDots.querySelector('.overview-grid');
    slides.forEach((slide, index) => {
      const titleNode = slide.querySelector('h1, h2, .divider-title, .act-title');
      const title = (titleNode?.textContent || `슬라이드 ${index + 1}`).replace(/\s+/g, ' ').trim();
      const button = document.createElement('button');
      button.type = 'button';
      button.className = 'overview-item';
      button.innerHTML = `<span>${String(index + 1).padStart(2, '0')}</span><strong>${title}</strong>`;
      button.addEventListener('click', () => {
        closeOverview();
        goSlide(index);
      });
      grid.appendChild(button);
    });
    navDots.querySelector('[data-overview-close]').addEventListener('click', closeOverview);
    navDots.addEventListener('click', event => {
      if (event.target === navDots) closeOverview();
    });
  }

  function focusables(slide = slides[currentSlide]) {
    return Array.from(slide.querySelectorAll('button:not([disabled]), input:not([disabled]), select:not([disabled]), [data-focusable]'))
      .filter((item, index, array) => array.indexOf(item) === index && item.offsetParent !== null);
  }

  function updateFocus() {
    document.querySelectorAll('.in-focus').forEach(item => item.classList.remove('in-focus'));
    const items = focusables();
    if (currentFocus >= 0 && currentFocus < items.length) items[currentFocus].classList.add('in-focus');
  }

  function updateSlide(index = currentSlide) {
    currentSlide = Math.max(0, Math.min(index, slides.length - 1));
    slides.forEach((slide, slideIndex) => slide.classList.toggle('active', slideIndex === currentSlide));
    if (progressBar) progressBar.style.width = `${((currentSlide + 1) / slides.length) * 100}%`;
    presenter.querySelector('.presenter-position').textContent = `${String(currentSlide + 1).padStart(2, '0')} / ${String(slides.length).padStart(2, '0')}`;
    presenter.querySelector('[data-action="prev"]').disabled = currentSlide === 0;
    presenter.querySelector('[data-action="next"]').disabled = currentSlide === slides.length - 1;
    navDots?.querySelectorAll('.overview-item').forEach((item, itemIndex) => item.classList.toggle('active', itemIndex === currentSlide));
    currentFocus = -1;
    updateFocus();
  }

  function goSlide(index, behavior = 'smooth') {
    currentSlide = Math.max(0, Math.min(index, slides.length - 1));
    scrolling = true;
    slides[currentSlide].scrollIntoView({ behavior, block: 'start' });
    updateSlide();
    window.setTimeout(() => { scrolling = false; }, behavior === 'smooth' ? 520 : 30);
  }

  function moveFocus(direction) {
    const items = focusables();
    if (!items.length) return;
    currentFocus = currentFocus < 0 ? (direction > 0 ? 0 : items.length - 1) : Math.max(0, Math.min(currentFocus + direction, items.length - 1));
    updateFocus();
    items[currentFocus]?.focus({ preventScroll: true });
  }

  function openOverview() {
    body.classList.add('overview-open');
    navDots?.querySelector('.overview-item.active')?.scrollIntoView({ block: 'center' });
  }

  function closeOverview() {
    body.classList.remove('overview-open');
  }

  function toggleFullscreen() {
    if (!document.fullscreenElement) document.documentElement.requestFullscreen?.();
    else document.exitFullscreen?.();
  }

  presenter.addEventListener('click', event => {
    const action = event.target.closest('button')?.dataset.action;
    if (action === 'prev') goSlide(currentSlide - 1);
    if (action === 'next') goSlide(currentSlide + 1);
    if (action === 'overview') openOverview();
    if (action === 'fullscreen') toggleFullscreen();
  });

  document.addEventListener('keydown', event => {
    const editable = event.target.matches('input, textarea, select');
    if (event.key === 'Escape' && body.classList.contains('overview-open')) { closeOverview(); return; }
    if (editable) return;
    if (event.key === 'ArrowUp' || event.key === 'PageUp') { event.preventDefault(); goSlide(currentSlide - 1); }
    if (event.key === 'ArrowDown' || event.key === 'PageDown' || event.key === ' ') { event.preventDefault(); goSlide(currentSlide + 1); }
    if (event.key === 'ArrowLeft') { event.preventDefault(); moveFocus(-1); }
    if (event.key === 'ArrowRight') { event.preventDefault(); moveFocus(1); }
    if (event.key === 'Home') { event.preventDefault(); goSlide(0); }
    if (event.key === 'End') { event.preventDefault(); goSlide(slides.length - 1); }
    if (event.key.toLowerCase() === 'o') openOverview();
    if (event.key.toLowerCase() === 'f') toggleFullscreen();
  });

  document.addEventListener('click', event => {
    const tab = event.target.closest('.tab-btn');
    if (!tab) return;
    const slide = tab.closest('.slide');
    const tabs = Array.from(slide.querySelectorAll('.tab-btn'));
    const key = tab.dataset.tab ?? String(tabs.indexOf(tab));
    tabs.forEach(button => button.classList.toggle('active', button === tab));
    slide.querySelectorAll('.tab-panel').forEach(panel => panel.classList.toggle('active', panel.dataset.tab === key));
  });

  window.switchTab = value => {
    const slide = slides[currentSlide];
    const tabs = Array.from(slide.querySelectorAll('.tab-btn'));
    const button = typeof value === 'number' ? tabs[value] : value;
    button?.click();
  };

  const observer = new IntersectionObserver(entries => {
    if (scrolling) return;
    const visible = entries.filter(entry => entry.isIntersecting).sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];
    if (visible) updateSlide(slides.indexOf(visible.target));
  }, { threshold: [0.55, 0.75] });
  slides.forEach(slide => observer.observe(slide));

  function renderCoreDemo(root) {
    const toggles = Array.from(root.querySelectorAll('[data-system]'));
    const meter = root.querySelector('[data-core-meter]');
    const value = root.querySelector('[data-core-value]');
    const answer = root.querySelector('[data-core-answer]');
    const risks = root.querySelector('[data-core-risks]');
    const render = () => {
      const active = toggles.filter(toggle => toggle.checked).map(toggle => toggle.dataset.system);
      const scores = { memory: 20, knowledge: 30, skill: 24, workflow: 26 };
      const total = active.reduce((sum, key) => sum + scores[key], 0);
      meter.style.width = `${total}%`;
      value.textContent = `${total}%`;
      const pieces = [];
      if (active.includes('memory')) pieces.push('팀장이 선호하는 1페이지 형식과 지난 회고의 후속 조치를 반영했습니다.');
      if (active.includes('knowledge')) pieces.push('INC-142·INC-145와 최신 장애 대응 문서를 근거로 원인과 영향을 정리했습니다.');
      if (active.includes('skill')) pieces.push('타임라인 → 원인 → 재발 방지 → 담당자 순서의 포스트모템 템플릿을 적용했습니다.');
      if (active.includes('workflow')) pieces.push('외부 공유 전 담당자 검토와 승인 단계에서 멈췄습니다.');
      answer.innerHTML = pieces.length ? pieces.map(piece => `<p>${piece}</p>`).join('') : '<p class="demo-muted">기능을 켜면 답변이 맥락·근거·절차·안전장치를 갖추기 시작합니다.</p>';
      const missing = [
        ['memory', '대상 독자와 이전 결정이 빠짐'],
        ['knowledge', '근거 문서 없이 추정함'],
        ['skill', '보고서 구조와 검증 기준이 흔들림'],
        ['workflow', '검토 없이 바로 배포할 위험']
      ].filter(([key]) => !active.includes(key)).map(([, label]) => `<li>${label}</li>`);
      risks.innerHTML = missing.length ? missing.join('') : '<li class="safe">누락된 안전장치 없음</li>';
    };
    toggles.forEach(toggle => toggle.addEventListener('change', render));
    root.querySelector('[data-core-all]').addEventListener('click', () => { toggles.forEach(toggle => { toggle.checked = true; }); render(); });
    root.querySelector('[data-core-reset]').addEventListener('click', () => { toggles.forEach(toggle => { toggle.checked = false; }); render(); });
    render();
  }

  const knowledgeDocs = [
    { title: '2026 해외출장비 운영 규정', type: '공식 규정', date: '2026-06-30', score: 96, tags: ['출장', '숙박', '한도', '해외'] },
    { title: '싱가포르 출장 정산 사례', type: '검증된 사례', date: '2026-05-12', score: 82, tags: ['출장', '정산', '싱가포르'] },
    { title: '2024 출장비 규정 사본', type: '과거 문서', date: '2024-01-03', score: 71, tags: ['출장', '숙박', '한도'] },
    { title: 'Travel expense policy (Global)', type: '영문 정책', date: '2026-04-18', score: 78, tags: ['travel', 'expense', 'hotel', '출장'] },
    { title: '보안 사고 보고 체계 v3', type: '공식 절차', date: '2026-07-01', score: 94, tags: ['보안', '사고', '보고'] },
    { title: '신규 입사자 첫 주 체크리스트', type: '온보딩', date: '2026-06-05', score: 91, tags: ['온보딩', '입사', '체크리스트'] }
  ];

  function renderKnowledgeDemo(root) {
    const input = root.querySelector('[data-knowledge-query]');
    const result = root.querySelector('[data-knowledge-results]');
    const status = root.querySelector('[data-knowledge-status]');
    const search = () => {
      const query = input.value.trim().toLowerCase();
      const officialOnly = root.querySelector('[data-filter="official"]').checked;
      const freshFirst = root.querySelector('[data-filter="fresh"]').checked;
      const multilingual = root.querySelector('[data-filter="multi"]').checked;
      const terms = query.split(/\s+/).filter(Boolean);
      let docs = knowledgeDocs.map(doc => {
        const haystack = `${doc.title} ${doc.type} ${doc.tags.join(' ')}`.toLowerCase();
        const directMatches = terms.filter(term => term.length > 1 && haystack.includes(term)).length;
        const semanticMatch = multilingual && /출장|숙박|비용/.test(query) && /travel|expense|hotel/.test(haystack) ? 22 : 0;
        let match = directMatches * 30 + semanticMatch;
        if (directMatches === 0 && semanticMatch === 0) match -= 58;
        if (officialOnly && !/공식|규정|정책|절차/.test(doc.type + doc.title)) match -= 28;
        const freshness = Math.max(0, 12 - Math.floor((Date.now() - new Date(doc.date).getTime()) / 86400000 / 30));
        return { ...doc, rank: doc.score * .5 + match + (freshFirst ? freshness : 0) };
      }).filter(doc => doc.rank > 52).sort((a, b) => b.rank - a.rank).slice(0, 3);
      if (!docs.length) docs = knowledgeDocs.slice(0, 3);
      result.innerHTML = docs.map((doc, index) => `
        <article class="search-result ${index === 0 ? 'top' : ''}">
          <span class="result-rank">${index + 1}</span>
          <div><strong>${doc.title}</strong><small>${doc.type} · 갱신 ${doc.date}</small></div>
          <b>${Math.min(98, Math.round(doc.rank))}%</b>
        </article>`).join('');
      status.textContent = `후보 ${knowledgeDocs.length}건 중 관련성·권위·신선도를 반영해 ${docs.length}건을 선택했습니다.`;
    };
    root.querySelector('[data-knowledge-search]').addEventListener('click', search);
    input.addEventListener('keydown', event => { if (event.key === 'Enter') search(); });
    root.querySelectorAll('[data-filter]').forEach(filter => filter.addEventListener('change', search));
    root.querySelectorAll('[data-query]').forEach(button => button.addEventListener('click', () => { input.value = button.dataset.query; search(); }));
    search();
  }

  const skillRecipes = {
    minutes: { label: '고객 회의록', steps: ['참석자·목표 확인', '결정·미결 사항 분리', '담당자와 기한 추출', '공유 전 민감정보 검사'] },
    reply: { label: '고객 답변', steps: ['문의 의도 분류', '근거 문서 확인', '해결 절차 작성', '톤·금칙어 검증'] },
    release: { label: '배포 공지', steps: ['변경 범위 수집', '사용자 영향 요약', '롤백·문의 경로 명시', '배포 책임자 승인'] }
  };

  function renderSkillDemo(root) {
    const task = root.querySelector('[data-skill-task]');
    const risk = root.querySelector('[data-skill-risk]');
    const validate = root.querySelector('[data-skill-validate]');
    const output = root.querySelector('[data-skill-output]');
    const score = root.querySelector('[data-skill-score]');
    const meter = root.querySelector('[data-skill-meter]');
    const run = () => {
      const recipe = skillRecipes[task.value];
      const steps = [...recipe.steps];
      if (risk.value === 'high') steps.splice(3, 0, '고위험 변경: 책임자 승인 대기');
      if (!validate.checked) steps.pop();
      output.innerHTML = steps.map((step, index) => `<li><span>${index + 1}</span><div><strong>${step}</strong><small>${index === steps.length - 1 ? '산출물 검증 후 완료' : '통과하면 다음 단계'}</small></div><b>✓</b></li>`).join('');
      const consistency = 58 + steps.length * 7 + (validate.checked ? 8 : 0) + (risk.value === 'high' ? 4 : 0);
      const result = Math.min(98, consistency);
      score.textContent = `${result}%`;
      meter.style.width = `${result}%`;
      root.querySelector('[data-skill-label]').textContent = `${recipe.label} Skill 실행 결과`;
    };
    root.querySelector('[data-skill-run]').addEventListener('click', run);
    [task, risk, validate].forEach(control => control.addEventListener('change', run));
    run();
  }

  const workflowStages = ['Request', 'Investigation', 'Design', 'Review', 'Approval', 'Execution', 'Test', 'Exe Review', 'Done'];

  function renderWorkflowDemo(root) {
    let stage = 0;
    let approved = false;
    let failed = false;
    const stageList = root.querySelector('[data-workflow-stages]');
    const state = root.querySelector('[data-workflow-state]');
    const note = root.querySelector('[data-workflow-note]');
    const next = root.querySelector('[data-workflow-next]');
    const approve = root.querySelector('[data-workflow-approve]');
    const fail = root.querySelector('[data-workflow-fail]');
    const render = () => {
      stageList.innerHTML = workflowStages.map((label, index) => `<li class="${index < stage ? 'done' : index === stage ? 'current' : ''}"><span>${index + 1}</span><b>${label}</b></li>`).join('');
      state.textContent = `${stage + 1}/9 · ${workflowStages[stage]}`;
      approve.hidden = stage !== 4 || approved;
      fail.hidden = stage < 5 || stage > 7;
      next.disabled = stage === 4 && !approved || stage === 8;
      if (stage === 4 && !approved) note.textContent = '승인 게이트: Agent는 근거를 제시하고 사용자의 결정을 기다립니다.';
      else if (stage === 4 && approved) note.textContent = '사용자 승인 기록이 남았습니다. 이제 Execution으로 진행할 수 있습니다.';
      else if (failed) note.textContent = '실패를 기록하고 마지막 안전 지점인 Design으로 롤백했습니다.';
      else if (stage === 8) note.textContent = '결과·검증·교훈이 모두 남아 Done에 도달했습니다.';
      else note.textContent = `${workflowStages[stage]} 단계의 완료 조건을 확인했습니다. 다음 단계로 전이할 수 있습니다.`;
    };
    next.addEventListener('click', () => { if (stage < 8 && !(stage === 4 && !approved)) { stage += 1; failed = false; render(); } });
    approve.addEventListener('click', () => { approved = true; note.textContent = '사용자 승인 기록이 남았습니다. 이제 Execution으로 진행할 수 있습니다.'; render(); });
    fail.addEventListener('click', () => { stage = 2; approved = false; failed = true; render(); });
    root.querySelector('[data-workflow-reset]').addEventListener('click', () => { stage = 0; approved = false; failed = false; render(); });
    render();
  }

  document.querySelectorAll('[data-demo="core"]').forEach(renderCoreDemo);
  document.querySelectorAll('[data-demo="knowledge"]').forEach(renderKnowledgeDemo);
  document.querySelectorAll('[data-demo="skill"]').forEach(renderSkillDemo);
  document.querySelectorAll('[data-demo="workflow"]').forEach(renderWorkflowDemo);

  updateSlide(0);
})();
