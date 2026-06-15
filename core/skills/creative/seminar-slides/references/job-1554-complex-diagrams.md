# Complex Diagram Patterns (JOB-1554)

## Cycle Diagram (with feedback loop)
```css
.cycle-diagram { display: flex; flex-direction: column; align-items: center; margin-top: 20px; }
.cycle-top { display: flex; gap: 16px; align-items: center; }
.cycle-arrow-down { font-size: 24px; color: var(--text-dim); margin: 8px 0; }
.cycle-bottom { display: flex; gap: 16px; align-items: center; }
.cycle-feedback { writing-mode: vertical-rl; text-orientation: mixed; color: var(--t1); font-weight: 600; font-size: 13px; padding: 8px; }
```

```html
<div class="cycle-diagram">
  <div class="cycle-top">
    <div class="diagram-node amber">Step 1</div>
    <div class="diagram-arrow">→</div>
    <div class="diagram-node purple">Step 2</div>
    <div class="diagram-arrow">→</div>
    <div class="diagram-node green">Step 3</div>
  </div>
  <div class="cycle-arrow-down">↓</div>
  <div class="flow-condition">Condition for retry</div>
  <div class="flow-arrow">←</div>
</div>
```

## Tree Diagram
```css
.tree-diagram { display: flex; flex-direction: column; align-items: center; gap: 16px; margin-top: 20px; }
.tree-root { background: var(--gradient-start); color: white; padding: 12px 24px; border-radius: var(--radius); font-weight: 700; }
.tree-branches { display: flex; gap: 20px; }
.tree-branch { background: var(--bg-card); border: 2px solid var(--border); border-radius: var(--radius); padding: 16px; text-align: center; min-width: 150px; }
.tree-branch h4 { font-size: 15px; margin-bottom: 8px; }
.tree-branch p { font-size: 12px; color: var(--text-dim); }
```

```html
<div class="tree-diagram">
  <div class="tree-root">Root Node</div>
  <div class="tree-branches">
    <div class="tree-branch">
      <h4>Branch 1</h4>
      <p>Description</p>
    </div>
    <!-- more branches -->
  </div>
</div>
```

## Flow Chart with Branches
```css
.flow-chart { display: flex; flex-direction: column; align-items: center; gap: 8px; margin-top: 20px; }
.flow-row { display: flex; gap: 16px; align-items: center; }
.flow-node { background: var(--bg-card); border: 2px solid var(--border); border-radius: var(--radius); padding: 12px 20px; font-weight: 600; box-shadow: var(--shadow-sm); min-width: 120px; text-align: center; }
.flow-node.start { border-color: #f59e0b; background: #fffbeb; }
.flow-node.process { border-color: #8b5cf6; background: #f5f3ff; }
.flow-node.end { border-color: #22c55e; background: #f0fdf4; }
.flow-branch { display: flex; gap: 24px; margin-top: 8px; }
.flow-condition { background: #fef2f2; border: 2px solid #ef4444; border-radius: 8px; padding: 8px 16px; font-size: 13px; font-weight: 600; }
```

```html
<div class="flow-chart">
  <div class="flow-row">
    <div class="flow-node start">Start</div>
    <div class="flow-arrow">→</div>
    <div class="flow-node process">Process</div>
    <div class="flow-arrow">→</div>
    <div class="flow-node end">End</div>
  </div>
  <div class="flow-branch">
    <div class="flow-condition">Branch 1</div>
    <div class="flow-condition">Branch 2</div>
  </div>
</div>
```

## Two Column Layout
```css
.two-col { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; width: 100%; max-width: 1100px; margin-top: 20px; }
```

## Image Container
```css
.slide-image { max-width: 900px; width: 100%; border-radius: var(--radius); box-shadow: var(--shadow-md); margin-top: 16px; }
```

## Image Prompt Format
Store in `images/prompt-{slide}.md`:
```markdown
# S2 Description - GPT Image 2 Prompt

**프롬프트**:
```
"Detailed description of the image, style, colors, layout..."
```

**파일명**: `s2-desc.png`
**사용 위치**: S2 slide description
```
