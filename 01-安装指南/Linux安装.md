# Linux安装指南 - 小龙虾(OpenClaw)
> **适用**: Ubuntu 20.04/22.04, Debian 11/12, Arch Linux, CentOS/Rocky Linux
> **难度**: ⭐ 简单
> **时间**: 10分钟
> **推荐度**: ⭐⭐⭐⭐⭐

---

## 前置要求

### 系统要求
CPU, 最低=2核心, 推荐=4核心+
内存, 最低=4GB, 推荐=8GB+
磁盘, 最低=10GB, 推荐=20GB+ SSD
网络, 最低=稳定, 推荐=宽带

### 检查系统
```bash
# 检查操作系统
cat /etc/os-release

# 检查Node.js(需要22+)
node --version

# 检查npm
npm --version

# 检查Python(某些skills需要)
python3 --version
```

## 安装步骤

### 步骤1:安装Node.js 22+

**Ubuntu/Debian**:
```bash
# 使用NodeSource仓库
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# 验证
node --version # 应显示 v22.x.x
```

**Arch Linux**:
```bash
sudo pacman -S nodejs npm
```

**CentOS/Rocky Linux**:
```bash
curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
sudo yum install -y nodejs
```

### 步骤2:安装OpenClaw

```bash
# 全局安装
sudo npm install -g openclaw

# 验证安装
openclaw --version
openclaw help
```

### 步骤3:初始化配置

```bash
# 运行初始化向导
openclaw init

# - 默认模型: zai/glm-4.7
```

### 步骤4:启动Gateway

```bash
# 启动Gateway
openclaw gateway start

# 检查状态
openclaw gateway status

# 查看日志
tail -f ~/.openclaw/logs/gateway.log
```

## ⚙️ 系统配置

### 配置开机自启动(推荐)
**使用systemd**:

```bash
# 创建service文件
sudo vim /etc/systemd/system/openclaw.service
```

内容:
```ini
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
User=YOUR_USERNAME
WorkingDirectory=/home/YOUR_USERNAME/.openclaw
ExecStart=/usr/bin/openclaw gateway start
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

启用:
```bash
# 重载systemd
sudo systemctl daemon-reload

# 启用开机自启
sudo systemctl enable openclaw

# 启动服务
sudo systemctl start openclaw

# 查看状态
sudo systemctl status openclaw
```

### 配置防火墙
如果使用远程访问:

```bash
# Ubuntu/Debian
sudo ufw allow 18789/tcp

# CentOS/Rocky Linux
sudo firewall-cmd --permanent --add-port=18789/tcp
sudo firewall-cmd --reload
```

### 常用命令

```bash
# Gateway管理
openclaw gateway status  # 状态
openclaw gateway start   # 启动
openclaw gateway stop    # 停止
openclaw gateway restart # 重启
openclaw gateway logs    # 日志

# 配置管理
openclaw config get    # 查看配置
openclaw config schema # 配置schema

# Session管理
openclaw sessions list
openclaw sessions history
```

## 发行版特定说明

### Ubuntu/Debian
**安装依赖**:
```bash
sudo apt update
sudo apt install -y build-essential git python3 python3-pip
```

**安装时遇到问题?**
```bash
# 清理npm缓存
sudo npm cache clean --force

# 重新安装
sudo npm install -g openclaw --unsafe-perm=true
```

### Arch Linux
**使用yay安装**:
```bash
yay -S openclaw
```

**或使用AUR helper**:
```bash
git clone https://aur.archlinux.org/openclaw.git
cd openclaw
makepkg -si
```

### CentOS/Rocky Linux
**安装开发工具**:
```bash
sudo yum groupinstall "Development Tools"
sudo yum install git python3
```

## 接入IM

```bash
# 编辑配置
vim ~/.openclaw/openclaw.json
```

添加:
```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "token": "YOUR_BOT_TOKEN"
    }
  }
}
```

```bash
# 重启
openclaw gateway restart
```

详细步骤:[Telegram接入指南](../03-IM平台集成/Telegram接入.md)

### 飞书(企业推荐)
详见:[飞书接入指南](../03-IM平台集成/飞书接入.md)

### QQ机器人
详见:[QQ接入指南](../03-IM平台集成/QQ接入.md)

## 故障排查

### 问题1:命令未找到

```
openclaw: command not found
```

```bash
# 卸载旧版本
sudo apt remove nodejs npm

# 安装NodeSource 22.x
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### 问题2:权限错误

```
EACCES: permission denied
```

```bash
# 解决:配置npm prefix
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'

# 添加到PATH
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

npm install -g openclaw
```

### 问题3:端口占用

```
Error: Port 18789 already in use
```

```bash
# 查找占用进程
sudo lsof -i :18789

# 杀掉进程
sudo kill -9 <PID>

# 重启Gateway
openclaw gateway restart
```

### 通用调试

```bash
# 查看详细日志
openclaw gateway logs

# 检查配置文件
cat ~/.openclaw/openclaw.json | python3 -m json.tool

# 重置配置
mv ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak
```

## 下一步
1. 安装完成
2. [接入IM平台](../03-IM平台集成/README.md)
3. [学习常用命令](../05-参考文档/快速参考卡.md)

## 获取帮助
- [完整文档](https://docs.openclaw.ai), [社区Discord](https://discord.gg/clawd), [报告问题](https://github.com/openclaw/openclaw/issues)

**更新时间**: 2026-03-11
**维护者**: Zandar
