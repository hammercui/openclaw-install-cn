# 快速开始 - OpenClaw 5分钟上手指南

> 适合新手和快速体验的用户

---

##  前置要求

- **操作系统**: Linux / macOS / Windows (WSL2)
- **网络**: 能够访问 GitHub 或使用代理
- **时间**: 5-10分钟

---

##  方式一：一键安装（推荐）

### Windows

```powershell
# 1. 进入安装目录
cd D:\moneyProject\openclaw-install-cn\01-安装指南\一键安装

# 2. 运行安装脚本
.\install.bat

# 3. 等待安装完成
```

### Linux / macOS

```bash
# 1. 进入安装目录
cd openclaw-install-cn/01-安装指南/一键安装

# 2. 运行安装脚本
chmod +x install.sh && ./install.sh

# 3. 等待安装完成
```

### 安装完成后

```bash
# 1. 初始化配置
openclaw init

# 2. 启动 Gateway
openclaw gateway start

# 3. 查看状态
openclaw gateway status
```

**✅ 完成！** OpenClaw 已经运行。

---

##  方式二：手动安装（适合开发者）

### 1. 安装 Node.js 22

**使用 nvm (推荐):**

```bash
# 安装 nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# 安装 Node.js 22
nvm install 22
nvm use 22
```

**Windows:**

```powershell
# 下载 nvm-windows
# https://github.com/coreybutler/nvm-windows/releases
nvm install 22
nvm use 22
```

### 2. 安装 OpenClaw

```bash
# 使用国内镜像（推荐）
npm config set registry https://registry.npmmirror.com

# 全局安装 OpenClaw
npm install -g openclaw

# 验证安装
openclaw --version
```

### 3. 初始化配置

```bash
# 创建配置文件
openclaw init

# 编辑配置
vim ~/.openclaw/openclaw.json
```

### 4. 启动服务

```bash
# 启动 Gateway
openclaw gateway start

# 查看日志
openclaw gateway logs

# 查看状态
openclaw gateway status
```

---

##  配置 IM 平台

### Telegram（最简单，5分钟）

1. **创建 Bot**:
   - 在 Telegram 搜索 `@BotFather`
   - 发送 `/newbot`
   - 按提示创建 Bot
   - 获取 Token

2. **配置 OpenClaw**:
   ```bash
   # 编辑配置
   vim ~/.openclaw/openclaw.json
   ```

   添加 Telegram 配置：
   ```json
   {
     "channels": {
       "telegram": {
         "botToken": "YOUR_BOT_TOKEN"
       }
     }
   }
   ```

3. **重启 Gateway**:
   ```bash
   openclaw gateway restart
   ```

4. **开始使用**:
   - 在 Telegram 中找到你的 Bot
   - 发送 `/help` 开始对话

**详细指南**: [Telegram 接入指南](./02-平台集成/Telegram接入.md)

---

##  常见问题

### Q1: 安装失败，提示网络错误？
**A**: 使用国内镜像源

```bash
npm config set registry https://registry.npmmirror.com
```

### Q2: Node.js 版本不对？
**A**: 使用 nvm 安装 Node.js 22

```bash
nvm install 22
nvm use 22
```

### Q3: Gateway 启动失败？
**A**: 查看日志诊断问题

```bash
openclaw gateway logs
```

### Q4: 找不到命令？
**A**: 检查环境变量或重新打开终端

```bash
# Linux/macOS
source ~/.bashrc  # 或 ~/.zshrc

# Windows
# 重新打开 PowerShell
```

---

##  下一步

### 学习基础操作
- 📖 [快速参考卡](./04-参考文档/快速参考卡.md)
- 🔧 [故障排除指南](./01-安装指南/一键安装/TROUBLESHOOTING.md)

### 配置其他平台
- 🔌 [飞书接入](./02-平台集成/飞书接入.md) - 企业推荐
- 🔌 [QQ 接入](./02-平台集成/QQ接入.md) - 功能强大

### 高级配置
- ⚙️ [Embedding 向量数据库](./03-高级配置/Embedding向量数据库.md)
- ⚙️ [浏览器自动化](./03-高级配置/浏览器自动化.md)

---

##  获取帮助

- 📖 [完整文档](./README.md)
- 💬 [社区 Discord](https://discord.gg/clawd)
- 🐛 [提交问题](https://github.com/openclaw/openclaw/issues)

---

**祝你使用愉快！** 🎉

---

💰 *Powered by OpenClaw - 商业价值最大化*
