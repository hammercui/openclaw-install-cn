# Linux 安装指南

> 支持：Ubuntu 20.04+、Debian 11+、CentOS/Rocky Linux、Arch Linux、openSUSE 等主流发行版

## 快速开始

```bash
bash install-linux.sh
```

脚本全程自动完成，无需手动操作。

---

## 安装过程说明

共 7 步，全程自动：

| 步骤 | 内容 |
|------|------|
| 1 | 测试镜像速度，选择最快的 npm / Node.js 镜像源 |
| 2 | 检查 / 安装 Node.js 22.22.1+（通过 nvm，从 Gitee 镜像） |
| 3 | 配置 npm（写入 `~/.npmrc`） |
| 4 | 配置 Shell 环境变量（写入 `~/.bashrc` 或 `~/.zshrc`） |
| 5 | 安装 OpenClaw（pnpm 优先，npm 备用） |
| 6 | 验证安装 |
| 7 | 配置开机自启动（systemd 用户服务或 crontab，可选，询问） |

**镜像源**：自动从淘宝、腾讯云、华为云中选最快的。

---

## 安装完成后

```bash
source ~/.bashrc           # 重载 Shell 环境（bash 用户）
source ~/.zshrc            # 重载 Shell 环境（zsh 用户）
openclaw init              # 初始化配置
openclaw gateway start     # 启动 Gateway
openclaw gateway status    # 查看状态
openclaw --help            # 查看所有命令
```

**开机自启动管理**（安装时选 Y 自动配置）：

```bash
systemctl --user status openclaw-gateway    # 查看状态
systemctl --user stop openclaw-gateway      # 停止
systemctl --user disable openclaw-gateway   # 取消自启
```

---

## 故障排除

**`openclaw` 命令未找到**

```bash
source ~/.bashrc
# 或重新打开终端
```

**权限错误 `EACCES`**

```bash
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
npm install -g openclaw
```

**端口 18789 被占用**

```bash
sudo lsof -i :18789
sudo kill -9 <PID>
openclaw gateway restart
```

**查看完整日志**

```bash
cat /tmp/openclaw-install-linux.log
```
