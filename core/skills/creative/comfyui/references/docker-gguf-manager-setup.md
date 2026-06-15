# Docker GGUF + ComfyUI Manager Setup (JOB-1167)

## Context
When running ComfyUI in Docker (ai-dock images), custom nodes and Python packages require manual dependency installation because ai-dock uses isolated Python virtualenvs.

## ComfyUI-GGUF Installation in Docker

### Step 1: Clone Custom Node
```bash
# On Windows host (PowerShell)
cd C:\AI\docker_comfyui\custom_nodes
git clone https://github.com/city96/ComfyUI-GGUF.git
```

### Step 2: Install Python Dependencies (Critical)
The `gguf` Python package is NOT auto-installed. Must install in ComfyUI's virtualenv:

```bash
# ai-dock Python env path:
docker exec <container> bash -c "source /opt/environments/python/comfyui/bin/activate && pip install gguf"
```

### Step 3: Restart & Verify
```bash
docker restart <container>

# Verify in logs:
# SUCCESS: "0.X seconds: /opt/ComfyUI/custom_nodes/ComfyUI-GGUF"
# FAILURE: "IMPORT FAILED: /opt/ComfyUI/custom_nodes/ComfyUI-GGUF" + "No module named 'gguf'"
```

### Step 4: Check API
```bash
curl http://HOST:8188/object_info | python3 -c "
import sys, json
data = json.load(sys.stdin)
gguf_nodes = [k for k in data.keys() if 'GGUF' in k]
print('GGUF nodes:', gguf_nodes)
"
```
Expected: `UnetLoaderGGUF`, `CLIPLoaderGGUF`, `DualCLIPLoaderGGUF`, `UnetLoaderGGUFAdvanced`

## ComfyUI Manager Installation in Docker

### Step 1: Clone
```bash
cd C:\AI\docker_comfyui\custom_nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager.git
```

### Step 2: Install Requirements (Critical)
Manager fails with `No module named 'toml'` or `folder_paths.get_user_directory` without this:

```bash
docker exec <container> bash -c "source /opt/environments/python/comfyui/bin/activate && cd /opt/ComfyUI/custom_nodes/ComfyUI-Manager && pip install -r requirements.txt"
```

### Step 3: Restart & Verify
```bash
docker restart <container>
Start-Sleep -Seconds 30

# Check logs:
docker exec <container> cat /var/log/supervisor/comfyui.log | Select-String -Pattern "Manager"
# SUCCESS: "0.X seconds: /opt/ComfyUI/custom_nodes/ComfyUI-Manager"
# Manager button appears in ComfyUI web UI
```

### Step 4: Use Manager for Node Version Control
- Open ComfyUI web UI → Manager → Custom Node Manager
- Search for any custom node (e.g., ComfyUI-GGUF)
- Use **Version Switch** or **Changelog** to rollback to compatible versions
- Click **Switch** → **Restart All**

## Common Errors & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `No module named 'gguf'` | Python package not installed in venv | `pip install gguf` in ComfyUI venv |
| `No module named 'toml'` | Manager requirements not installed | `pip install -r requirements.txt` in ComfyUI venv |
| `folder_paths.get_user_directory` | ComfyUI-Manager prestartup script incompatibility | Usually resolves after requirements install + restart |
| `IMPORT FAILED` on custom node | Dependencies missing or Python path wrong | Activate correct venv before pip install |

## ai-dock Python Virtualenv Path
- ComfyUI env: `/opt/environments/python/comfyui/bin/activate`
- Always source this before running pip inside container
- Standard `pip install` fails because it installs to system Python, not ComfyUI's env

## WSL → Docker Communication Note
- WSL cannot run `docker` commands directly (Docker runs on Windows host)
- Use `docker exec` / `docker cp` from Windows PowerShell
- Or use `docker context set default` in WSL if Docker Desktop WSL integration is enabled
