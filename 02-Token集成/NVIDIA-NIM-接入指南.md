# NVIDIA NIM (Nemotron-3-Super) 接入指南

## 📖 简介

本指南介绍如何在 OpenClaw 中接入 NVIDIA Nemotron-3-Super-120B-A12B 模型（通过 NVIDIA NIM API）。

**模型特点：**
- ✅ 支持 1M 上下文长度
- ✅ 原生支持工具调用（function calling）
- ✅ 多步 Agent 规划能力强
- ✅ 免费额度充足
- ✅ 完全兼容 OpenAI 协议

**适用场景：**
- 复杂多步推理任务
- 需要大量工具调用的 Agent
- 长上下文处理（大文件分析）
- 作为主模型配合其他模型使用

---

## 🔑 前提条件

### 1. 已安装 OpenClaw

```bash
# 检查版本（需 ≥ 2026.3.7）
openclaw --version

# 如需升级
npm install -g openclaw@latest
```

### 2. 完成基本初始化

```bash
# 运行初始化向导
openclaw onboard

# 或手动创建配置
openclaw config wizard
```

### 3. 获取 NVIDIA API Key

1. 访问：https://build.nvidia.com
2. 登录账号（推荐 Google 账号）
3. 左上角头像 → **API Keys**
4. 点击 **Create new key**
5. 复制生成的 key（格式：`nvapi-xxx...`）

**⚠️ 重要提示：**
- 妥善保存 API Key，只显示一次
- 日本/美国 IP 通常无访问限制
- 免费额度充足，适合开发和测试

---

## ⚙️ 配置步骤

### 步骤 1：找到 OpenClaw 配置文件

**配置文件位置：**
- Windows: `C:\Users\你的用户名\.openclaw\openclaw.json`
- macOS/Linux: `~/.openclaw/openclaw.json`

**如果文件不存在：**
```bash
# 运行一次初始化生成配置文件
openclaw onboard
```

### 步骤 2：编辑配置文件

用 VS Code 或任何编辑器打开 `openclaw.json`，添加以下配置：

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
        "api_key": "nvapi-你的NVIDIA_API_KEY_粘贴在这里",
        "models": [
          {
            "id": "nvidia/nemotron-3-super-120b-a12b",
            "name": "Nemotron-3-Super 120B-A12B",
            "max_tokens": 131072,
            "context_length": 1048576,
            "supports_tools": true,
            "tool_choice": "auto",
            "recommended": {
              "temperature": 0.6,
              "top_p": 0.95
            }
          },
          {
            "id": "nvidia/nemotron-3-nano-30b-a3b:free",
            "name": "Nemotron-3-Nano 30B (免费备用)",
            "max_tokens": 32768,
            "context_length": 131072,
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
      },
      "temperature": 0.6,
      "top_p": 0.95,
      "max_tokens": 8192,
      "tool_choice": "auto"
    }
  }
}
```

### 关键配置说明

#### 1. API Base
```json
"api_base": "https://integrate.api.nvidia.com/v1"
```
- **必须**使用 NIM 标准 endpoint
- 不要添加其他路径或参数

#### 2. API 协议
```json
"api": "openai-chat"
```
- 兼容 OpenAI tools 格式
- 支持流式输出和工具调用

#### 3. 模型配置
```json
"supports_tools": true,
"tool_choice": "auto"
```
- 强制启用工具调用功能
- 自动选择是否使用工具

#### 4. 推荐参数
```json
"temperature": 0.6,
"top_p": 0.95
```
- **Temperature ≤ 0.6**：确保稳定的工具调用
- **Top_p = 0.95**：平衡创意和准确性

#### 5. 主模型设置
```json
"primary": "nvidia/nemotron-3-super-120b-a12b"
```
- 设为默认主模型
- 可搭配 Nano 免费版作为 fallback

### 步骤 3：重启 OpenClaw

```bash
# 重启 Gateway
openclaw gateway restart

# 或带详细日志启动
openclaw gateway start --verbose
```

---

## ✅ 验证配置

### 测试 1：基本对话

在已绑定的 Telegram/WhatsApp 等频道发送：

```
你好！请用中文自我介绍，并说明你的主要能力。
```

**预期结果：**
- 流畅的中文回复
- 响应速度 < 5 秒
- 无错误提示

### 测试 2：工具调用

发送复杂多步任务：

```
现在是2026年3月，帮我：
1. 查当前比特币价格（USD）
2. 换算成日元（用最新汇率）
3. 告诉我如果有0.1 BTC值多少日元
```

**预期结果：**
- 模型先思考 → 调用搜索工具 → 获取数据 → 计算 → 回答
- 日志中看到 `"tool_calls"` 输出
- 最终答案准确

### 测试 3：浏览器技能

```bash
# 先安装浏览器技能
clawhub install browser web-fetch

# 或手动安装
cd ~/.openclaw/skills
git clone https://github.com/your-repo/browserwing
```

然后发送：

```
用浏览器打开 https://build.nvidia.com，
总结 Nemotron-3-Super 的最新 benchmark 分数。
```

**预期结果：**
- 成功打开网页
- 提取关键信息
- 总结 benchmark 数据

### 检查日志

如果工具调用不工作，检查日志：

```bash
# 查看详细日志
openclaw gateway logs --tail 50

# 或重启时使用 --verbose 模式
openclaw gateway restart --verbose
```

**关键日志标识：**
- ✅ 成功：看到 `"tool_calls"` delta 输出
- ❌ 失败：卡在文本伪调用（模型假装调用工具）

---

## 🎯 优化建议

### 1. System Prompt 优化

编辑 `~/.openclaw/souls/default/SOUL.md`（或你的 persona）：

```markdown
# NVIDIA Nemotron-3-Super 专属配置

你是一个精确的、优先使用工具的 AI Agent，由 Nemotron-3-Super 驱动。

## 工作原则

- 始终使用 <thinking> 标签进行逐步推理
- 只在必要时调用工具，优先使用内置技能
- 计算/数学任务使用 code-interpreter
- Temperature=0.6, top_p=0.95 时工具调用最稳定
- 最终答案用用户语言清晰输出（中文/英文/日文）

## 工具使用规则

1. **搜索任务** → 优先用 web_search / web-fetch
2. **浏览器操作** → 使用 browserwing / browser
3. **代码执行** → 使用 code-interpreter
4. **文件操作** → 使用 read / write / exec

## 输出格式

- 先在 <thinking> 中规划步骤
- 调用工具时说明目的
- 最终答案简洁明了
```

### 2. 多模型 Fallback

在配置中添加备用模型：

```json
{
  "id": "nvidia/nemotron-3-nano-30b-a3b:free",
  "name": "Nemotron-3-Nano 30B (免费备用)",
  "fallback": true,
  "max_tokens": 32768
}
```

**好处：**
- 超限时自动切换
- 降低成本
- 提高可用性

### 3. 长上下文优化

```json
{
  "agents": {
    "defaults": {
      "max_context": 524288,
      "max_tokens": 16384
    }
  }
}
```

**说明：**
- 模型支持 1M 上下文
- Gateway 默认限制 128k
- 可适当提高（需足够内存）

### 4. 性能调优

**温度设置指南：**
- 0.2-0.4：精确任务（代码、数学）
- 0.5-0.7：工具调用（推荐 0.6）
- 0.8-1.0：创意写作（慎用，工具不稳定）

**Top_p 设置：**
- 0.9-0.95：平衡准确性和多样性
- 0.95：工具调用推荐值

---

## 🔧 常见问题

### Q1: 工具调用不触发？

**可能原因：**
1. Temperature 过高（>0.7）
2. Prompt 中没有强调"使用工具"
3. 模型配置中 `supports_tools` 未设置

**解决方案：**
```json
{
  "temperature": 0.6,
  "supports_tools": true,
  "tool_choice": "auto"
}
```

Prompt 中明确要求：
```
请使用工具帮我完成以下任务...
```

### Q2: API Rate Limit？

**症状：**
- 日志显示 `429 Too Many Requests`
- 响应变慢或失败

**解决方案：**
1. 等待几分钟后重试
2. 切换到 Nano 免费模型
3. 添加本地模型作为 fallback

### Q3: 日本网络访问慢？

**通常不需要代理**，但如果遇到问题：

```json
{
  "api_base": "https://integrate.api.nvidia.com/v1",
  "timeout": 30000,
  "retries": 3
}
```

或使用反向代理（如有）。

### Q4: 模型回答质量下降？

**检查项：**
1. Temperature 是否过高
2. Context 是否超出限制
3. Prompt 是否清晰

**优化：**
- 降低 temperature 到 0.4-0.6
- 清理不必要的历史记录
- 优化 System Prompt

### Q5: 如何查看实际使用的 Token？

```bash
# 查看统计
openclaw stats

# 或查看日志
openclaw gateway logs | grep "tokens"
```

---

## 📊 性能对比

### Nemotron-3-Super vs 其他模型

| 特性 | Nemotron-3-Super | Claude 3.5 Sonnet | GPT-4o |
|------|------------------|-------------------|--------|
| 上下文长度 | 1M | 200K | 128K |
| 工具调用 | ✅ 优秀 | ✅ 优秀 | ✅ 良好 |
| 中文能力 | ✅ 流利 | ✅ 优秀 | ✅ 优秀 |
| 多步推理 | ✅ 强 | ✅ 强 | ✅ 中 |
| 免费额度 | ✅ 充足 | ❌ 有限 | ❌ 有限 |
| 日本访问 | ✅ 快 | ⚠️ 需代理 | ⚠️ 需代理 |

**社区反馈：**
- 工具调用能力接近 Claude 3.5 Sonnet
- 长上下文处理优于 GPT-4o
- 完全免费，额度高

---

## 🚀 高级用法

### 1. 自定义技能集成

```bash
# 安装技能
clawhub install browser web-fetch code-interpreter

# 或手动克隆到 ~/.openclaw/skills/
```

### 2. 多模型协作

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "nvidia/nemotron-3-super-120b-a12b",
        "fallback": ["nvidia/nemotron-3-nano-30b-a3b:free", "local-model"]
      }
    }
  }
}
```

### 3. 场景化配置

**代码生成场景：**
```json
{
  "temperature": 0.2,
  "max_tokens": 16384,
  "tool_choice": "none"
}
```

**工具调用场景：**
```json
{
  "temperature": 0.6,
  "top_p": 0.95,
  "tool_choice": "auto"
}
```

---

## 📚 参考资源

### 官方文档
- NVIDIA NIM: https://build.nvidia.com
- API 文档: https://build.nvidia.com/api
- 模型列表: https://build.nvidia.com/models

### OpenClaw 文档
- 官方文档: https://docs.openclaw.ai
- GitHub: https://github.com/openclaw/openclaw
- Discord: https://discord.com/invite/clawd

### 社区资源
- ClawHub: https://clawhub.com
- 技能市场: https://clawhub.com/skills
- 配置示例: https://github.com/openclaw/configs

---

## 🆘 获取帮助

遇到问题？

1. **检查日志**：`openclaw gateway logs --tail 50`
2. **验证配置**：确认 API Key 正确
3. **测试连接**：尝试简化 prompt
4. **社区求助**：Discord / GitHub Issues

**常见调试命令：**
```bash
# 重启并查看详细日志
openclaw gateway restart --verbose

# 测试 API 连接
curl -H "Authorization: Bearer nvapi-你的key" \
  https://integrate.api.nvidia.com/v1/models

# 查看模型列表
openclaw models list

# 查看统计
openclaw stats
```

---

**配置完成后，Nemotron-3-Super 在 OpenClaw 上的工具调用能力非常强大**，特别适合：
- 多步规划任务
- 并行工具调用
- 错误自愈和重试
- 长上下文分析

祝你使用愉快！🚀

---

**文档版本**: v1.0
**更新时间**: 2026-03-12
**维护者**: OpenClaw 社区
