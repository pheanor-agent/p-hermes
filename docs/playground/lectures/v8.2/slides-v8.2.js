(() => {
  'use strict';

  const deckFiles = {
    a: 'deck-a-core-v8.2.html',
    b: 'deck-b-knowledge-v8.2.html',
    c: 'deck-c-skill-v8.2.html',
    d: 'deck-d-workflow-v8.2.html'
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
  let wheelTotal = 0;
  let wheelLock = false;
  let touchStartY = null;

  function normaliseSlideStructure() {
    slides.forEach((slide, index) => {
      const header = slide.querySelector(':scope > .slide-header');
      const heading = slide.querySelector('h1, h2, .divider-title, .act-title');
      slide.dataset.slideIndex = String(index + 1);

      if (!header || header.querySelector(':scope > div')) return;
      const tag = header.querySelector('.lecture-tag');
      if (!tag) return;

      const context = document.createElement('div');
      context.className = 'header-context';
      context.append(tag);
      const sectionTitle = document.createElement('span');
      sectionTitle.className = 'section-title';
      sectionTitle.textContent = (heading?.textContent || '').replace(/\s+/g, ' ').trim();
      context.append(sectionTitle);
      header.insertBefore(context, header.querySelector('.slide-number'));
    });
  }

  normaliseSlideStructure();

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

  function isEditableTarget(target) {
    return Boolean(target.closest('input, textarea, select, button, [contenteditable="true"]'));
  }

  function hasLocalScroll(target, delta) {
    const panel = target.closest('.lab-panel');
    if (!panel || panel.scrollHeight <= panel.clientHeight + 2) return false;
    if (delta > 0) return panel.scrollTop + panel.clientHeight < panel.scrollHeight - 2;
    return panel.scrollTop > 2;
  }

  function moveByScroll(delta) {
    wheelTotal += delta;
    if (wheelLock || Math.abs(wheelTotal) < 34) return;
    const direction = wheelTotal > 0 ? 1 : -1;
    wheelTotal = 0;
    wheelLock = true;
    goSlide(currentSlide + direction);
    window.setTimeout(() => { wheelLock = false; }, 560);
  }

  window.addEventListener('wheel', event => {
    if (isEditableTarget(event.target) || hasLocalScroll(event.target, event.deltaY)) return;
    event.preventDefault();
    moveByScroll(event.deltaY);
  }, { passive: false });

  window.addEventListener('touchstart', event => {
    if (isEditableTarget(event.target)) return;
    touchStartY = event.touches[0]?.clientY ?? null;
  }, { passive: true });

  window.addEventListener('touchend', event => {
    if (touchStartY === null || isEditableTarget(event.target)) return;
    const endY = event.changedTouches[0]?.clientY ?? touchStartY;
    const distance = touchStartY - endY;
    touchStartY = null;
    if (Math.abs(distance) >= 48) moveByScroll(distance);
  }, { passive: true });

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

  function fitSlide(slide) {
    const body = slide.querySelector(':scope > .slide-body');
    if (!body) return;
    slide.classList.remove('is-tight');
    slide.style.removeProperty('--slide-fit');
    const ratio = body.clientHeight / Math.max(body.clientHeight, body.scrollHeight);
    if (ratio < .985) {
      slide.classList.add('is-tight');
      slide.style.setProperty('--slide-fit', String(Math.max(.80, Math.min(.98, ratio))));
    }
  }

  function fitAllSlides() { slides.forEach(fitSlide); }
  window.addEventListener('resize', () => requestAnimationFrame(fitAllSlides));
  document.fonts?.ready?.then(() => requestAnimationFrame(fitAllSlides));

  function renderCoreDemo(root) {
    const toggles = Array.from(root.querySelectorAll('[data-system]'));
    const status = root.querySelector('[data-core-status]');
    const risks = root.querySelector('[data-core-risks]');
    const contributions = {
      memory: '팀장이 선호하는 1페이지 형식과 지난 회고의 후속 조치를 반영합니다.',
      knowledge: 'INC-142·INC-145와 최신 장애 대응 문서를 근거로 인용합니다.',
      skill: '타임라인 → 원인 → 재발 방지 → 담당자 순서와 완료 기준을 적용합니다.',
      workflow: '외부 공유 전에 담당자 검토와 사용자 승인 단계에서 멈춥니다.'
    };
    const empty = {
      memory: '팀장 선호 형식과 이전 결정이 없습니다.',
      knowledge: '인용할 장애 기록과 최신 문서가 없습니다.',
      skill: '회고 자료의 순서와 완료 기준이 없습니다.',
      workflow: '검토 없이 외부 공유될 수 있습니다.'
    };
    const render = () => {
      const active = toggles.filter(toggle => toggle.checked).map(toggle => toggle.dataset.system);
      Object.keys(contributions).forEach(key => {
        const slot = root.querySelector(`[data-core-slot="${key}"]`);
        const enabled = active.includes(key);
        slot.classList.toggle('is-active', enabled);
        slot.querySelector('p').textContent = enabled ? contributions[key] : empty[key];
      });
      status.textContent = active.includes('workflow')
        ? '검토 대기 · 승인 후 공유'
        : '초안 생성 가능 · 공유 금지';
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
    { title: '2026 해외출장비 운영 규정', type: '공식 규정', date: '2026-06-30', topic: 'travel', relevance: 88, official: true, freshness: 18, language: 'ko' },
    { title: '싱가포르 출장 정산 사례', type: '검증된 사례', date: '2026-05-12', topic: 'travel', relevance: 104, official: false, freshness: 15, language: 'ko' },
    { title: '2024 출장비 규정 사본', type: '과거 공식 문서', date: '2024-01-03', topic: 'travel', relevance: 82, official: true, freshness: 1, language: 'ko' },
    { title: 'Travel expense policy (Global)', type: '영문 공식 정책', date: '2026-04-18', topic: 'travel', relevance: 72, official: true, freshness: 12, language: 'en' },
    { title: '보안 사고 보고 체계 v3', type: '공식 절차', date: '2026-07-01', topic: 'security', relevance: 98, official: true, freshness: 19, language: 'ko' },
    { title: '신규 입사자 첫 주 체크리스트', type: '검증된 운영 문서', date: '2026-06-05', topic: 'onboarding', relevance: 98, official: true, freshness: 17, language: 'ko' }
  ];

  function renderKnowledgeDemo(root) {
    const input = root.querySelector('[data-knowledge-query]');
    const result = root.querySelector('[data-knowledge-results]');
    const status = root.querySelector('[data-knowledge-status]');
    const decision = root.querySelector('[data-knowledge-decision]');
    const search = () => {
      const query = input.value.trim().toLowerCase();
      const officialOnly = root.querySelector('[data-filter="official"]').checked;
      const freshFirst = root.querySelector('[data-filter="fresh"]').checked;
      const multilingual = root.querySelector('[data-filter="multi"]').checked;
      const topic = /보안|사고|보고/.test(query) ? 'security' : /입사|온보딩|체크리스트/.test(query) ? 'onboarding' : 'travel';
      const docs = knowledgeDocs.map(doc => {
        const related = doc.topic === topic;
        const relevance = related ? doc.relevance : 8;
        const languageBridge = related && doc.language === 'en' && multilingual ? 22 : 0;
        const languagePenalty = related && doc.language === 'en' && !multilingual ? -58 : 0;
        const authority = officialOnly ? (doc.official ? 30 : 0) : (doc.official ? 8 : 0);
        const freshness = freshFirst ? doc.freshness : 0;
        const reasons = [`질문 일치 ${relevance}`];
        if (authority) reasons.push(`권위 +${authority}`);
        if (freshness) reasons.push(`최신 +${freshness}`);
        if (languageBridge) reasons.push(`한↔영 +${languageBridge}`);
        return { ...doc, rank: relevance + authority + freshness + languageBridge + languagePenalty, reasons };
      }).filter(doc => doc.rank > 30).sort((a, b) => b.rank - a.rank).slice(0, 3);
      result.innerHTML = docs.map((doc, index) => `
        <article class="search-result ${index === 0 ? 'top' : ''}">
          <span class="result-rank">${index + 1}</span>
          <div><strong>${doc.title}</strong><small>${doc.type} · 갱신 ${doc.date}</small><span class="result-reasons">${doc.reasons.join(' · ')}</span></div>
          <b>${Math.round(doc.rank)}</b>
        </article>`).join('');
      decision.textContent = docs[0]?.title || '사용 가능한 근거 없음';
      const activeRules = [officialOnly && '공식성', freshFirst && '신선도', multilingual && '한↔영 의미 확장'].filter(Boolean);
      status.textContent = `관련성${activeRules.length ? ` + ${activeRules.join(' + ')}` : ''}을 순위 근거로 사용했습니다. 숫자는 신뢰도가 아니라 공개된 정렬 점수입니다.`;
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
    const contract = root.querySelector('[data-skill-contract]');
    const decision = root.querySelector('[data-skill-decision]');
    const run = () => {
      const recipe = skillRecipes[task.value];
      const steps = [...recipe.steps];
      if (risk.value === 'high') steps.splice(3, 0, '고위험 변경: 책임자 승인 대기');
      if (!validate.checked) steps.pop();
      output.innerHTML = steps.map((step, index) => {
        const isGate = step.includes('승인 대기');
        const isFinal = index === steps.length - 1 && validate.checked;
        const detail = isGate ? '조건부 단계 · 승인 전 실행 금지' : isFinal ? '고정 완료 조건 · 생략 불가' : '업무별 절차 · 통과하면 다음 단계';
        return `<li class="${isGate ? 'is-gate' : isFinal ? 'is-contract' : ''}"><span>${index + 1}</span><div><strong>${step}</strong><small>${detail}</small></div><b>${isGate ? '!' : '✓'}</b></li>`;
      }).join('');
      contract.innerHTML = validate.checked
        ? '<b>실행 계약 충족</b><span>입력 확인 · 업무별 구조 · 최종 검증이 모두 남아 있습니다.</span>'
        : '<b>실행 계약 위반</b><span>최종 검증을 끄면 결과는 생성되어도 완료 처리할 수 없습니다.</span>';
      contract.classList.toggle('is-invalid', !validate.checked);
      decision.textContent = validate.checked
        ? (risk.value === 'high' ? '승인 대기 · 아직 완료 아님' : '검증 통과 후 완료 가능')
        : '완료 처리 불가';
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
    let history = ['Request에서 작업을 접수했습니다.'];
    const stageList = root.querySelector('[data-workflow-stages]');
    const state = root.querySelector('[data-workflow-state]');
    const note = root.querySelector('[data-workflow-note]');
    const historyList = root.querySelector('[data-workflow-history]');
    const next = root.querySelector('[data-workflow-next]');
    const approve = root.querySelector('[data-workflow-approve]');
    const fail = root.querySelector('[data-workflow-fail]');
    const log = message => { history = [message, ...history].slice(0, 3); };
    const render = () => {
      stageList.innerHTML = workflowStages.map((label, index) => `<li class="${index < stage ? 'done' : index === stage ? 'current' : ''}"><span>${index + 1}</span><b>${label}</b></li>`).join('');
      state.textContent = `${stage + 1}/9 · ${workflowStages[stage]}`;
      approve.hidden = stage !== 4 || approved;
      fail.hidden = stage < 5 || stage > 7;
      next.disabled = stage === 8;
      next.textContent = stage === 4 && !approved ? '승인 없이 실행 시도' : '다음 단계';
      if (stage === 4 && !approved) note.textContent = '승인 게이트: Agent는 근거를 제시하고 사용자의 결정을 기다립니다.';
      else if (stage === 4 && approved) note.textContent = '사용자 승인 기록이 남았습니다. 이제 Execution으로 진행할 수 있습니다.';
      else if (failed) note.textContent = '실패를 기록하고 마지막 안전 지점인 Design으로 롤백했습니다.';
      else if (stage === 8) note.textContent = '결과·검증·교훈이 모두 남아 Done에 도달했습니다.';
      else note.textContent = `${workflowStages[stage]} 단계의 완료 조건을 확인했습니다. 다음 단계로 전이할 수 있습니다.`;
      historyList.innerHTML = history.map(item => `<li>${item}</li>`).join('');
    };
    next.addEventListener('click', () => {
      if (stage === 4 && !approved) {
        log('차단: Approval 기록 없이 Execution으로 갈 수 없습니다.');
        note.textContent = '전이 차단: 사용자 승인 기록이 없어서 Execution을 시작하지 않았습니다.';
        historyList.innerHTML = history.map(item => `<li>${item}</li>`).join('');
        return;
      }
      if (stage < 8) {
        const from = workflowStages[stage];
        stage += 1;
        failed = false;
        log(`${from} → ${workflowStages[stage]} 전이가 기록되었습니다.`);
        render();
      }
    });
    approve.addEventListener('click', () => { approved = true; log('사용자가 실행 범위를 승인했습니다.'); render(); });
    fail.addEventListener('click', () => {
      const from = workflowStages[stage];
      stage = 2;
      approved = false;
      failed = true;
      log(`${from} 실패 → Design으로 롤백하고 승인 기록을 초기화했습니다.`);
      render();
    });
    root.querySelector('[data-workflow-reset]').addEventListener('click', () => { stage = 0; approved = false; failed = false; history = ['Request에서 작업을 접수했습니다.']; render(); });
    render();
  }

  document.querySelectorAll('[data-demo="core"]').forEach(renderCoreDemo);
  document.querySelectorAll('[data-demo="knowledge"]').forEach(renderKnowledgeDemo);
  document.querySelectorAll('[data-demo="skill"]').forEach(renderSkillDemo);
  document.querySelectorAll('[data-demo="workflow"]').forEach(renderWorkflowDemo);

  updateSlide(0);
  requestAnimationFrame(fitAllSlides);
})();
