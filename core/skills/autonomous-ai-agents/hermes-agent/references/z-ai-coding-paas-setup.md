# Z.AI Coding PaaS Provider Setup

**Last Updated:** 2026-05-17
**Trigger:** Configuring Z.AI (GLM) provider for subscriptions that cover the "Coding PaaS" service.

## Context
Standard Z.AI API configuration (`https://api.z.ai/v1` or `https://open.bigmodel.cn/api/paas/v4`) uses models like `glm-4-plus`. However, some subscriptions (e.g., "Z.AI Coding" plans) provide credits specifically for the **Coding PaaS** endpoint.

## Symptoms
- **Standard Endpoints**: Return `429 Too Many Requests` with message `"Insufficient balance or no resource package."`
- **Standard Models**: `glm-4-plus`, `glm-4-air` return `400 Unknown Model` on the Coding PaaS endpoint.

## Solution
Point the provider to the **Coding PaaS** endpoint and use the specific model IDs provided by that service.

### Configuration
**`~/.hermes/config.yaml`**
```yaml
providers:
  zai:
    apiKey: env.GLM_API_KEY
    # MUST use the Coding PaaS endpoint
    baseUrl: https://api.z.ai/api/coding/paas/v4/
    models:
      glm-4.7:
        name: GLM-4.7
      glm-5.1:
        name: GLM-5.1
      glm-4.5-air:
        name: GLM-4.5-Air
```

**`~/.hermes/.env`**
```env
GLM_API_KEY=your_key_here
GLM_BASE_URL=https://api.z.ai/api/coding/paas/v4/
```

## Verification
Test with `glm-4.7`:
```bash
curl -X POST https://api.z.ai/api/coding/paas/v4/chat/completions \
  -H "Authorization: Bearer $GLM_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "glm-4.7", "messages": [{"role": "user", "content": "Test"}], "max_tokens": 10}'
```

## Pitfalls
- **Model ID Mismatch**: Standard GLM-4 models (`glm-4-plus`) DO NOT work on this endpoint. You MUST use `glm-4.7` or `glm-5.1`.
- **Base URL Path**: The path `/api/coding/paas/v4/` is critical. The standard `/api/paas/v4/` will fail for these subscriptions.
- **OpenClaw Sync**: If migrating from OpenClaw, ensure the `baseUrl` matches exactly (OpenClaw often uses this endpoint for coding agents).
