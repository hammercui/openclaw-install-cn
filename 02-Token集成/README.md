# 🔑 Token 集成指南

本目录包含各种 LLM 提供商的 API Key 配置指南。

---

## 📋 可用的提供商

### 1. NVIDIA NIM ⭐ NEW

**模型**: Nemotron-3-Super 120B-A12B

**特点**:
- ✅ 1M 超长上下文
- ✅ 强大的工具调用能力
- ✅ 免费额度充足
- ✅ 日本网络友好

**文档**: [NVIDIA-NIM-接入指南.md](./NVIDIA-NIM-接入指南.md)
**配置**: [providers/nvidia.example.json](./providers/nvidia.example.json)

**快速开始**:
1. 访问 https://build.nvidia.com/account/api-keys
2. 创建 API Key
3. 复制配置到 `openclaw.json`
4. 重启 OpenClaw

---

### 2. Anthropic (Claude)

**模型**: Claude 3.5 Sonnet, Claude 3 Opus

**特点**:
- ✅ 优秀的推理能力
- ✅ 强大的工具调用
- ✅ 长上下文支持

**配置**: [providers/anthropic.example.json](./providers/anthropic.example.json)

---

### 3. OpenAI

**模型**: GPT-4o, GPT-4o-mini

**特点**:
- ✅ 强大的多模态能力
- ✅ 工具调用支持
- ✅ 快速响应

**配置**: [providers/openai.example.json](./providers/openai.example.json)

---

### 4. Google (Gemini)

**模型**: Gemini 2.5 Pro, Gemini 2.0 Flash

**特点**:
- ✅ 超长上下文（1M+）
- ✅ 多模态支持
- ✅ 价格竞争力

**配置**: [providers/google.example.json](./providers/google.example.json)

---

### 5. 智谱 AI (GLM)

**模型**: GLM-4.7, GLM-4.5-Air

**特点**:
- ✅ 中文优化
- ✅ 国内访问友好
- ✅ 价格实惠

**配置**: [providers/zhipuai.example.json](./providers/zhipuai.example.json)

---

## 🚀 快速开始

### 选择合适的提供商

| 需求 | 推荐提供商 |
|------|-----------|
| **复杂多步推理** | NVIDIA NIM / Anthropic |
| **长文档分析** | NVIDIA NIM / Google |
| **多模态任务** | OpenAI / Google |
| **国内访问** | 智谱 AI |
| **免费额度** | NVIDIA NIM |
| **最佳性价比** | NVIDIA NIM / 智谱 AI |

### 配置步骤

1. **获取 API Key**
   - 访问对应提供商官网
   - 创建并复制 API Key

2. **编辑配置**
   ```bash
   # Windows
   notepad C:\Users\你的用户名\.openclaw\openclaw.json

   # macOS/Linux
   vim ~/.openclaw/openclaw.json
   ```

3. **添加提供商配置**
   ```json
   {
     "models": {
       "mode": "merge",
       "providers": [
         // 复制对应提供商的配置
       ]
     }
   }
   ```

4. **重启 OpenClaw**
   ```bash
   openclaw gateway restart
   ```

---

## 📖 配置示例

### 最小化配置（NVIDIA NIM）

```json
{
  "models": {
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
            "name": "Nemotron-3-Super",
            "supports_tools": true
          }
        ]
      }
    ]
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "nvidia/nemotron-3-super-120b-a12b"
      }
    }
  }
}
```

### 多提供商配置

```json
{
  "models": {
    "providers": [
      {
        "id": "nvidia-nim",
        "name": "NVIDIA NIM",
        "api_key": "nvapi-xxx"
      },
      {
        "id": "anthropic",
        "name": "Anthropic",
        "api_key": "sk-ant-xxx"
      },
      {
        "id": "openai",
        "name": "OpenAI",
        "api_key": "sk-xxx"
      }
    ]
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "nvidia/nemotron-3-super-120b-a12b",
        "fallback": ["claude-3-5-sonnet-20241022", "gpt-4o"]
      }
    }
  }
}
```

---

## 🔧 高级配置

### 主备切换

```json
{
  "model": {
    "primary": "主模型",
    "fallback": ["备用1", "备用2"]
  }
}
```

### 场景化配置

```json
{
  "agents": {
    "coding": {
      "model": "主模型",
      "temperature": 0.2
    },
    "chat": {
      "model": "备用模型",
      "temperature": 0.7
    }
  }
}
```

---

## 📊 性能对比

| 提供商 | 上下文 | 工具调用 | 速度 | 成本 |
|--------|--------|---------|------|------|
| **NVIDIA NIM** | 1M | ⭐⭐⭐⭐⭐ | 快 | 免费额度多 |
| **Anthropic** | 200K | ⭐⭐⭐⭐⭐ | 中 | 高 |
| **OpenAI** | 128K | ⭐⭐⭐⭐ | 快 | 高 |
| **Google** | 1M+ | ⭐⭐⭐⭐ | 快 | 低 |
| **智谱 AI** | 128K | ⭐⭐⭐ | 快 | 低 |

---

## ✅ 验证配置

### 测试命令

```bash
# 查看已配置的模型
openclaw models list

# 测试对话
echo "你好，请自我介绍" | openclaw chat

# 查看统计
openclaw stats
```

### 预期结果

- ✅ 正常回复（无错误）
- ✅ 响应速度 < 10 秒
- ✅ 工具调用正常（如需要）

---

## 🆘 常见问题

### Q: 如何选择主模型？

**A: 根据主要任务选择：**
- 复杂推理 → NVIDIA NIM / Anthropic
- 快速响应 → OpenAI / Google
- 成本优先 → NVIDIA NIM / 智谱 AI

### Q: 支持多少个提供商？

**A:** 无限制，建议：
- 1-2 个主提供商
- 2-3 个备用提供商
- 根据需求调整

### Q: 如何切换提供商？

**A:** 修改 `primary` 字段：
```json
{
  "primary": "新提供商的模型ID"
}
```

### Q: API Key 泄露怎么办？

**A:**
1. 立即到提供商官网撤销旧 Key
2. 生成新 Key
3. 更新配置文件
4. 重启 OpenClaw

---

## 📚 更多资源

- **OpenClaw 文档**: https://docs.openclaw.ai
- **提供商官网**:
  - NVIDIA: https://build.nvidia.com
  - Anthropic: https://www.anthropic.com
  - OpenAI: https://www.openai.com
  - Google: https://ai.google.dev
  - 智谱 AI: https://open.bigmodel.cn
- **社区 Discord**: https://discord.com/invite/clawd

---

## 🎯 推荐配置

### 个人开发

```json
{
  "primary": "nvidia/nemotron-3-super-120b-a12b",
  "fallback": ["nvidia/nemotron-3-nano-30b-a3b:free"]
}
```

### 小团队

```json
{
  "primary": "nvidia/nemotron-3-super-120b-a12b",
  "fallback": ["claude-3-5-sonnet-20241022", "gpt-4o"]
}
```

### 企业级

```json
{
  "primary": "claude-3-5-sonnet-20241022",
  "fallback": ["nvidia/nemotron-3-super-120b-a12b", "gpt-4o"],
  "load_balancing": true
}
```

---

**提示**: 所有配置文件都在 `providers/` 目录下有示例，可以直接复制修改！

**快速开始**: 推荐 NVIDIA NIM（免费、强大、易用）→ [查看详细指南](./NVIDIA-NIM-接入指南.md)
