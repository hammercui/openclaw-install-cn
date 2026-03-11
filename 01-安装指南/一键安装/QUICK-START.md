# OpenClaw 快速开始指南

## 🚀 5 分钟快速上手

### 步骤 1: 安装 OpenClaw

选择你的系统并运行对应的安装脚本：

#### Windows

```powershell
# 双击运行，或在 PowerShell 中运行
install.bat
```

#### macOS

```bash
# 在 Terminal 中运行
chmod +x install.sh
./install.sh
```

#### Linux

```bash
# 在终端中运行
chmod +x install.sh
./install.sh
```

等待安装完成（通常 40-90 秒）。

### 步骤 2: 验证安装

```bash
# 检查版本
openclaw --version

# 应该显示类似：
# OpenClaw v2026.3.2
```

如果提示命令未找到，**重启终端**即可。

### 步骤 3: 初始化配置

```bash
# 初始化配置文件
openclaw init
```

这会：
- 创建配置目录 `~/.openclaw`
- 生成配置文件 `openclaw.json`
- 设置默认模型和通道

### 步骤 4: 启动 Gateway

```bash
# 启动 OpenClaw Gateway
openclaw gateway start
```

Gateway 是 OpenClaw 的核心服务，负责：
- 处理消息路由
- 管理 AI 模型调用
- 处理定时任务和提醒
- 运行 Skills 和插件

### 步骤 5: 查看状态

```bash
# 查看 Gateway 运行状态
openclaw gateway status

# 应该显示类似：
# 🦞 OpenClaw 2026.3.2
# ✅ Gateway is running
# ✅ Session: agent:main:main
```

## 🎉 恭喜！

你已经成功安装并启动了 OpenClaw！

## 📱 接下来做什么？

### 选项 1: 连接 Telegram Bot（推荐）

1. 创建 Telegram Bot
2. 配置 OpenClaw 连接
3. 开始在 Telegram 中使用 AI

详细指南: [Telegram接入指南](../../03-IM平台集成/Telegram接入.md)

### 选项 2: 命令行交互

```bash
# 直接在命令行中对话
echo "你好" | openclaw chat

# 或进入交互模式
openclaw chat
```

### 选项 3: 使用 Web 界面

```bash
# 启动 Web 界面（如果支持）
openclaw web start
```

## 💡 常用命令

```bash
# Gateway 管理
openclaw gateway start    # 启动
openclaw gateway stop     # 停止
openclaw gateway restart  # 重启
openclaw gateway status   # 状态

# 配置管理
openclaw init             # 初始化配置
openclaw config           # 查看配置
openclaw status           # 查看状态

# 帮助
openclaw help             # 查看帮助
openclaw --version        # 查看版本
```

## 🔧 配置文件位置

配置文件位于：`~/.openclaw/openclaw.json`

### 修改默认模型

编辑配置文件：

```json
{
  "agents": {
    "defaults": {
      "model": "zai/glm-4.7"
    }
  }
}
```

### 可用的模型别名

```bash
# Gemini 系列
Flash                # gemini-3-flash
Gemini               # gemini-3-pro
Gemini-2.5-Flash     # gemini-2.5-flash
Gemini-2.5-Pro       # gemini-2.5-pro

# Claude 系列
AG-Claude-Sonnet     # claude-sonnet-4
AG-Claude-Opus       # claude-opus-4

# GPT 系列
AG-GPT-4o            # gpt-4o
AG-GPT-4o-Mini       # gpt-4o-mini

# 本地模型（需要配置）
Local-4o             # localhost/gpt-4o
Local-Gemini-Pro     # localhost/gemini-2.5-pro
```

## 🌐 国内网络优化

### 已自动配置的镜像

安装脚本已自动配置：

```bash
# npm 镜像（淘宝）
npm config get registry
# https://registry.npmmirror.com

# Node.js 镜像（淘宝）
# nvm 下载 Node.js 时会自动使用
```

### 切换镜像源

如果需要切换到其他镜像：

```bash
# 腾讯云
npm config set registry https://mirrors.cloud.tencent.com/npm

# 华为云
npm config set registry https://mirrors.huaweicloud.com/repository/npm/

# 官方源
npm config set registry https://registry.npmjs.org
```

## 🔄 更新 OpenClaw

```bash
# 更新到最新版本
npm update -g openclaw

# 或重新安装
npm install -g openclaw@latest

# 验证更新
openclaw --version
```

## 📚 下一步学习

- 📖 [完整安装指南](./README.md)
- 🔌 [平台集成指南](../../03-IM平台集成/Telegram接入.md)
- ⚙️ [高级配置](../../04-高级配置/README.md)
- 🔧 [故障排除](./TROUBLESHOOTING.md)

## 🆘 遇到问题？

### 常见问题

**Q: 安装成功但 `openclaw` 命令未找到**

A: 重启终端，或运行：
```bash
# Windows
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# macOS/Linux
source ~/.bashrc  # 或 source ~/.zshrc
```

**Q: Gateway 启动失败**

A: 检查日志：
```bash
# 查看 Gateway 日志
openclaw gateway logs

# 或查看配置
openclaw config
```

**Q: 如何卸载？**

A: 完整卸载指南: [TROUBLESHOOTING.md](./TROUBLESHOOTING.md#卸载与重装)

### 获取帮助

- 📖 [故障排除指南](./TROUBLESHOOTING.md)
- 💬 Discord: https://discord.com/invite/clawd
- 🐛 GitHub: https://github.com/openclaw/openclaw/issues
- 📧 Email: support@openclaw.ai

## 🎊 开始探索吧！

现在你可以：

1. 连接 Telegram Bot，随时随地使用 AI
2. 创建自定义 Skills，扩展 OpenClaw 功能
3. 配置定时任务和提醒
4. 集成更多平台（QQ、飞书等）

详细文档: [README.md](../../README.md)

---

💰 *Powered by OpenClaw - 商业价值最大化*
