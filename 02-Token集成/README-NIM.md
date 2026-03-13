# NVIDIA NIM 接入 - 快速参考

## 📦 文件清单

本目录包含 NVIDIA NIM (Nemotron-3-Super) 接入 OpenClaw 的完整配置：

```
02-Token集成/
├── NVIDIA-NIM-接入指南.md       # 详细配置文档（推荐先读这个）
├── providers/
│   └── nvidia.example.json      # 配置示例文件
└── README-NIM.md                # 本文件（快速参考）
```

## 🚀 快速开始（3步）

### 1. 获取 API Key

访问：https://build.nvidia.com/account/api-keys

创建并复制 API Key（格式：`nvapi-xxx...`）

### 2. 配置 OpenClaw

编辑配置文件：
- Windows: `C:\Users\你的用户名\.openclaw\openclaw.json`
- macOS/Linux: `~/.openclaw/openclaw.json`

添加以下内容（或参考 `providers/nvidia.example.json`）：

```json
{
  "models": {
    "mode": "merge",
    "providers": [
      {
        "id": "nvidia-nim",
        "name": "NVIDIA NIM",
        "api": "openai-chat",
        "api_base": "https://integrate.api.nvidia.com/v1",
        "api_key": "nvapi-你的API_KEY",
        "models": [
          {
            "id": "nvidia/nemotron-3-super-120b-a12b",
            "name": "Nemotron-3-Super 120B-A12B",
            "max_tokens": 131072,
            "context_length": 1048576,
            "supports_tools": true,
            "tool_choice": "auto"
          }
        ]
      }
    ]
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "nvidia/nemotron-3-super-120b-a12b"
      },
      "temperature": 0.6,
      "top_p": 0.95,
      "tool_choice": "auto"
    }
  }
}
```

### 3. 重启 OpenClaw

```bash
openclaw gateway restart
```

## ✅ 验证配置

发送测试消息：

```
你好！请帮我查一下当前的比特币价格，并换算成日元。
```

**预期结果：**
- 模型调用搜索工具
- 获取实时数据
- 准确计算并回复

## 📊 关键参数

| 参数 | 推荐值 | 说明 |
|------|--------|------|
| `temperature` | 0.6 | 工具调用最稳定 |
| `top_p` | 0.95 | 平衡准确性 |
| `max_tokens` | 8192 | 默认输出长度 |
| `tool_choice` | "auto" | 自动使用工具 |
| `supports_tools` | true | 启用工具调用 |

## 🎯 适用场景

✅ **推荐：**
- 复杂多步推理
- 工具链调用
- 长文档分析（1M 上下文）
- 代码生成和审查

❌ **不推荐：**
- 图像识别（不支持）
- 实时音频处理

## 🔧 常见问题

### Q: 工具调用不工作？
**A:** 检查：
1. `temperature` ≤ 0.6
2. `supports_tools: true`
3. Prompt 中明确要求"使用工具"

### Q: API Rate Limit？
**A:**
1. 等待几分钟后重试
2. 切换到 Nano 免费模型
3. 添加本地模型 fallback

### Q: 回答质量下降？
**A:**
1. 降低 temperature（0.4-0.6）
2. 清理历史记录
3. 优化 System Prompt

## 📚 详细文档

完整配置和高级用法，请参阅：
- **[NVIDIA-NIM-接入指南.md](./NVIDIA-NIM-接入指南.md)** - 详细教程

## 🌐 相关资源

- NVIDIA NIM: https://build.nvidia.com
- OpenClaw 文档: https://docs.openclaw.ai
- 社区 Discord: https://discord.com/invite/clawd

---

**快速提示** 🚀
- 复制 `providers/nvidia.example.json` 的内容
- 替换 `api_key` 为你的 NVIDIA API Key
- 粘贴到 `openclaw.json`
- 重启 OpenClaw
- 开始使用！
