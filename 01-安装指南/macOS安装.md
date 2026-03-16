# macOS 安装指南

> 支持：macOS 12+ (Monterey) / 13 (Ventura) / 14 (Sonoma)，Apple Silicon (M1/M2/M3) 和 Intel 均支持

## 前置要求

确保 Xcode 命令行工具已安装（脚本需要 git）：

```bash
xcode-select --install
```

## 快速开始

```bash
bash install-mac.sh
```

脚本全程自动完成，无需手动操作。

---

## 安装过程说明

共 7 步，全程自动：

| 步骤 | 内容 |
|------|------|
| 1 | 测试镜像速度，选择最快的 npm / Node.js 镜像源 |
| 2 | 检查 / 安装 Node.js 22.22.1+（通过 nvm，从 Gitee 镜像） |
| 3 | 配置 npm 和 git（写入 `~/.npmrc`，git 强制使用 HTTPS） |
| 4 | 配置 Shell 环境变量（写入 `~/.zshrc` 或 `~/.bashrc`） |
| 5 | 安装 OpenClaw（pnpm 优先，npm 备用） |
| 6 | 验证安装 |
| 7 | 配置开机自启动（launchd，可选，询问） |

**镜像源**：自动从淘宝、腾讯云、华为云中选最快的。

---

## 安装完成后

```bash
source ~/.zshrc            # 重载 Shell 环境
openclaw init              # 初始化配置
openclaw gateway start     # 启动 Gateway
openclaw gateway status    # 查看状态
openclaw --help            # 查看所有命令
```

**开机自启动管理**（安装时选 Y 自动配置）：

```bash
# 卸载自启动
launchctl unload ~/Library/LaunchAgents/com.openclaw.gateway.plist
rm ~/Library/LaunchAgents/com.openclaw.gateway.plist
```

---

## 故障排除

**`openclaw` 命令未找到**

```bash
source ~/.zshrc
# 或重新打开终端
```

**权限错误 `EACCES`（Apple Silicon 常见）**

```bash
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc
source ~/.zshrc
npm install -g openclaw
```

**git 未找到**

```bash
xcode-select --install
```

**查看完整日志**

```bash
cat /tmp/openclaw-install-mac.log
```
