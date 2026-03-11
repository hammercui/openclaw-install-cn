# macOS安装指南 - 小龙虾(OpenClaw)
> **适用**: macOS 12+ (Monterey), macOS 13+ (Ventura), macOS 14+ (Sonoma)
> **难度**: ⭐ 简单
> **时间**: 10分钟
> **推荐度**: ⭐⭐⭐⭐

---

## 前置要求

### 系统要求
macOS版本, 最低=12.0 (Monterey), 推荐=14.0 (Sonoma)
CPU, 最低=Intel i5 / Apple M1, 推荐=Intel i7 / Apple M2/M3
内存, 最低=4GB, 推荐=8GB+
磁盘, 最低=10GB, 推荐=20GB+ SSD

### 检查系统
```bash

# 检查macOS版本
sw_vers

# 检查Homebrew(如果已安装)
brew --version

# 检查Node.js
node --version

# 检查npm
npm --version
```

## 安装步骤

# 安装Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

/bin/zsh -c "$(curl -fsSL https://gitee.com/cunkai/HomebrewCN/raw/master/Homebrew.sh)"

# 添加Homebrew到PATH(Apple Silicon)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# 验证

# 使用Homebrew安装
brew install node@18

node --version # 应显示 v18.x.x

# 全局安装
sudo npm install -g openclaw

openclaw --version
openclaw help

# 运行初始化向导
openclaw init

# - 默认模型: zai/glm-4.7

# 启动
openclaw gateway start

# 检查状态
openclaw gateway status

# 查看日志
tail -f ~/.openclaw/logs/gateway.log

## ️ macOS特定配置

### 配置开机自启动(推荐)
**使用launchd**:

# 创建plist文件
vim ~/Library/LaunchAgents/com.openclaw.gateway.plist

内容:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
 <key>Label</key>
 <string>com.openclaw.gateway</string>
 <key>ProgramArguments</key>
 <array>
 <string>/usr/local/bin/openclaw</string>
 <string>gateway</string>
 <string>start</string>
 </array>
 <key>RunAtLoad</key>
 <true/>
 <key>KeepAlive</key>
 <key>StandardOutPath</key>
 <string>/tmp/openclaw.out.log</string>
 <key>StandardErrorPath</key>
 <string>/tmp/openclaw.err.log</string>
</dict>
</plist>

加载:

# 加载服务
launchctl load ~/Library/LaunchAgents/com.openclaw.gateway.plist

# 启动服务
launchctl start com.openclaw.gateway

# 查看状态
launchctl list | grep openclaw

### 配置防火墙
如果启用了防火墙:

# 允许 "node" 或 "openclaw" 接受传入连接

## Apple Silicon特定说明

### M1/M2/M3芯片
**Homebrew路径**:

# Apple Silicon
/opt/homebrew/

# Intel
/usr/local/

**npm全局路径**:

# 创建目录
mkdir ~/.npm-global

# 配置npm
npm config set prefix '~/.npm-global'

# 添加到PATH(zsh)
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc
source ~/.zshrc

# 重新安装
npm install -g openclaw

### Rosetta 2(如果需要)
某些Intel依赖可能需要Rosetta:

# 安装Rosetta 2
softwareupdate --install-rosetta

## 故障排查

### 问题1:权限错误
EACCES: permission denied

**解决**:

# 修复npm权限
sudo chown -R $(whoami) ~/.npm
sudo chown -R $(who.nodeName) /usr/local/lib/node_modules

# 或使用sudo

### 问题2:命令未找到
openclaw: command not found

# 查找npm全局路径
npm config get prefix

echo 'export PATH=/usr/local/bin:$PATH' >> ~/.zshrc

# 或(bash)
echo 'export PATH=/usr/local/bin:$PATH' >> ~/.bash_profile
source ~/.bash_profile

# 查看详细日志
openclaw gateway logs

# 检查端口占用
lsof -i :18789

# 重置配置
mv ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak

## 开发者友好功能

# 安装Xcode命令行工具
xcode-select --install

# 安装VS Code
brew install --cask visual-studio-code

# 安装OpenClaw扩展
code --install-extension openclaw.openclaw

## 快速接入IM

# 3. 配置
vim ~/.openclaw/openclaw.json

添加:
```json
{
 "channels": {
 "telegram": {
 "enabled": true,
 "token": "YOUR_BOT_TOKEN"
 }

# 4. 重启
openclaw gateway restart

详见:[Telegram接入指南](./Telegram接入指南.md)

## 下一步
1. 安装完成
2. [接入IM](./00-总索引.md#按im平台分类)
3. [常用命令](./OpenClaw快速参考卡.md)

## 获取帮助
- [完整文档](https://docs.openclaw.ai)
- [社区Discord](https://discord.gg/clawd)

**更新时间**: 2026-03-10
**维护者**: Zandar