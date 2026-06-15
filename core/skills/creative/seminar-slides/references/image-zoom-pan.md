# Image Zoom/Pan Implementation Pattern

## Trigger
User requests: "이미지 누르면 확대/축소/이동 가능하게 해줘"

## Implementation

### HTML Structure
```html
<!-- Image with zoom trigger -->
<img src="..." class="zoomable" onclick="openZoomModal(this.src)" alt="...">

<!-- Modal Overlay -->
<div class="zoom-modal" id="zoomModal" onclick="closeZoomModal()">
  <div class="zoom-container" onclick="event.stopPropagation()">
    <button class="zoom-close" onclick="closeZoomModal()">×</button>
    <button class="zoom-btn" onclick="zoomIn()">+</button>
    <button class="zoom-btn" onclick="zoomOut()">−</button>
    <div class="zoom-viewport" id="zoomViewport">
      <img id="zoomImage" src="" alt="Zoomed">
    </div>
  </div>
</div>
```

### CSS
```css
.zoom-modal {
  display: none;
  position: fixed;
  top: 0; left: 0;
  width: 100vw; height: 100vh;
  background: rgba(0,0,0,0.9);
  z-index: 1000;
  justify-content: center;
  align-items: center;
}
.zoom-modal.active { display: flex; }

.zoom-container {
  position: relative;
  max-width: 90vw;
  max-height: 90vh;
}

.zoom-viewport {
  overflow: hidden;
  width: 80vw;
  height: 80vh;
  display: flex;
  justify-content: center;
  align-items: center;
  cursor: grab;
}
.zoom-viewport.dragging { cursor: grabbing; }

.zoom-viewport img {
  max-width: 100%;
  max-height: 100%;
  transition: transform 0.1s ease;
  user-select: none;
}

.zoom-close {
  position: absolute;
  top: -40px; right: 0;
  background: none;
  border: none;
  color: white;
  font-size: 32px;
  cursor: pointer;
}

.zoom-btn {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  background: rgba(255,255,255,0.2);
  border: none;
  color: white;
  font-size: 24px;
  padding: 12px 16px;
  cursor: pointer;
  border-radius: 8px;
}
.zoom-btn:hover { background: rgba(255,255,255,0.4); }
.zoom-btn.left { left: -60px; }
.zoom-btn.right { right: -60px; }
```

### JavaScript
```js
let zoomScale = 1;
let zoomX = 0, zoomY = 0;
let isDragging = false;
let startX, startY;

function openZoomModal(src) {
  document.getElementById('zoomImage').src = src;
  document.getElementById('zoomModal').classList.add('active');
  resetZoom();
}

function closeZoomModal() {
  document.getElementById('zoomModal').classList.remove('active');
}

function resetZoom() {
  zoomScale = 1;
  zoomX = 0;
  zoomY = 0;
  applyZoom();
}

function zoomIn() {
  zoomScale = Math.min(zoomScale + 0.2, 5);
  applyZoom();
}

function zoomOut() {
  zoomScale = Math.max(zoomScale - 0.2, 0.5);
  applyZoom();
}

function applyZoom() {
  const img = document.getElementById('zoomImage');
  img.style.transform = `translate(${zoomX}px, ${zoomY}px) scale(${zoomScale})`;
}

// Mouse wheel zoom
document.getElementById('zoomViewport').addEventListener('wheel', (e) => {
  e.preventDefault();
  if (e.deltaY < 0) zoomIn();
  else zoomOut();
});

// Drag to pan
const viewport = document.getElementById('zoomViewport');
viewport.addEventListener('mousedown', (e) => {
  if (zoomScale <= 1) return;
  isDragging = true;
  startX = e.clientX - zoomX;
  startY = e.clientY - zoomY;
  viewport.classList.add('dragging');
});

document.addEventListener('mousemove', (e) => {
  if (!isDragging) return;
  zoomX = e.clientX - startX;
  zoomY = e.clientY - startY;
  applyZoom();
});

document.addEventListener('mouseup', () => {
  isDragging = false;
  viewport.classList.remove('dragging');
});

// ESC to close
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') closeZoomModal();
});
```

## Integration Notes
- Add `.zoomable` class to all images that should be interactive
- Modal should be placed outside `.slides` container to avoid clip issues
- Use `transform: translate() scale()` for GPU-accelerated zoom
- `user-select: none` prevents text selection during drag
- `cursor: grab/grabbing` provides visual feedback during interaction
