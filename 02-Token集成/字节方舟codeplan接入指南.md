# 字节方舟codeplan接入指南

请在 OpenClaw 中接入方舟 Coding Plan，步骤如下：
1. 打开配置文件：~/.openclaw/openclaw.json，如果是windows则找到当前的用户目录
2. 找到或创建以下字段，合并配置（保留原有配置不变，若字段不存在则新增）：
```
{
  "models": {
    "providers": {
      "volcengine-plan": {
        "baseUrl": "https://ark.cn-beijing.volces.com/api/coding/v3",
        "apiKey": "<ARK_API_KEY>",
        "api": "openai-completions",
        "models": [
          {
            "id": "ark-code-latest",
            "name": "ark-code-latest",
            "contextWindow": 256000,
            "maxTokens": 32000,
            "input": [
              "text",
              "image"
            ]
          },
          {
            "id": "doubao-seed-code",
            "name": "doubao-seed-code",
            "contextWindow": 256000,
            "maxTokens": 32000,
            "input": [
              "text",
              "image"
            ]
          },
          {
            "id": "glm-4.7",
            "name": "glm-4.7",
            "contextWindow": 200000,
            "maxTokens": 128000,
            "input": [
              "text"
            ]
          },
          {
            "id": "deepseek-v3.2",
            "name": "deepseek-v3.2",
            "contextWindow": 128000,
            "maxTokens": 32000
          },
          {
            "id": "doubao-seed-2.0-code",
            "name": "doubao-seed-2.0-code",
            "contextWindow": 256000,
            "maxTokens": 128000,
            "input": [
              "text",
              "image"
            ]
          },
          {
            "id": "doubao-seed-2.0-pro",
            "name": "doubao-seed-2.0-pro",
            "contextWindow": 256000,
            "maxTokens": 128000,
            "input": [
              "text",
              "image"
            ]
          },
          {
            "id": "doubao-seed-2.0-lite",
            "name": "doubao-seed-2.0-lite",
            "contextWindow": 256000,
            "maxTokens": 128000,
            "input": [
              "text",
              "image"
            ]
          },
          {
            "id": "minimax-m2.5",
            "name": "minimax-m2.5",
            "contextWindow": 200000,
            "maxTokens": 128000,
            "input": [
              "text"
            ]
          },
          {
            "id": "kimi-k2.5",
            "name": "kimi-k2.5",
            "contextWindow": 256000,
            "maxTokens": 32000,
            "input": [
              "text",
              "image"
            ]
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "volcengine-plan/glm-4.7"
      },
      "models": {
        "volcengine-plan/ark-code-latest": {},
        "volcengine-plan/doubao-seed-2.0-code": {},
        "volcengine-plan/doubao-seed-2.0-pro": {},
        "volcengine-plan/doubao-seed-2.0-lite": {},
        "volcengine-plan/doubao-seed-code": {},
        "volcengine-plan/minimax-m2.5": {},
        "volcengine-plan/glm-4.7": {},
        "volcengine-plan/deepseek-v3.2": {},
        "volcengine-plan/kimi-k2.5": {}
      }
    }
  },
  "gateway": {
    "mode": "local"
  }
}

```

3. 需要的<ARK_API_KEY>询问我，我会告诉你，然后替换<ARK_API_KEY>
4. 保存配置文件
5. 运行 openclaw gateway restart，重启Openclaw的网关，使配置生效。