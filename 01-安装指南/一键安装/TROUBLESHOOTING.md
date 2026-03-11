# OpenClaw 安装故障排除指南

## 🔍 快速诊断

### 检查清单

在报告问题前，请先检查：

- [ ] 网络连接正常
- [ ] 有管理员/Root 权限
- [ ] 防火墙/杀毒软件允许安装程序运行
- [ ] 磁盘空间充足（至少 500MB）
- [ ] 没有其他 Node.js 版本管理工具冲突（如 n、fnm）

## 🪟 Windows 问题

### 问题 1: PowerShell 执行策略错误

**错误信息**:
```
无法加载文件 install.ps1，因为在此系统上禁止运行脚本
```

**解决方案**:
```powershell
# 临时允许脚本执行（推荐）
powershell -ExecutionPolicy Bypass -File install.ps1

# 或永久修改执行策略
powershell Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 问题 2: nvm-windows 安装失败

**错误信息**:
```
[错误] nvm-windows 安装失败
```

**解决方案 A** - 自动重试:
```powershell
# 脚本会自动重试 3 次，使用不同的 GitHub 代理
# 如果仍然失败，尝试手动安装
```

**解决方案 B** - 手动安装:
```powershell
# 1. 访问 GitHub Releases
https://github.com/coreybutler/nvm-windows/releases

# 2. 或使用国内镜像
https://gitee.com/mirrors/nvm-windows/releases

# 3. 下载 nvm-setup.exe 并运行
# 4. 重新运行安装脚本
install.bat
```

**解决方案 C** - 使用离线安装:
```powershell
# 如果网络完全无法访问 GitHub
# 可以从其他电脑复制已安装的 nvm-windows
# 路径: %APPDATA%\nvm
```

### 问题 3: Node.js 22 安装失败

**错误信息**:
```
[错误] Node.js 22 安装失败
```

**解决方案**:
```powershell
# 1. 检查 nvm 配置
nvm node_mirror
nvm npm_mirror

# 2. 手动设置镜像源
nvm node_mirror https://npmmirror.com/mirrors/node
nvm npm_mirror https://npmmirror.com/mirrors/npm

# 3. 清理缓存后重试
nvm uninstall 22
nvm install 22

# 4. 如果仍然失败，尝试官方源
nvm node_mirror https://nodejs.org/dist
nvm install 22
```

### 问题 4: 环境变量未生效

**现象**: 安装成功但 `openclaw` 命令未找到

**解决方案**:
```powershell
# 1. 重启终端（最简单）

# 2. 或手动刷新环境变量
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# 3. 验证
node -v
npm -v
openclaw --version
```

### 问题 5: 权限不足

**错误信息**:
```
访问被拒绝
```

**解决方案**:
```powershell
# 以管理员身份运行 PowerShell
# 1. 右键点击 PowerShell
# 2. 选择"以管理员身份运行"
# 3. 重新运行安装脚本
```

## 🍎 macOS 问题

### 问题 1: nvm 安装失败

**错误信息**:
```
[错误] nvm 安装失败
```

**解决方案 A** - 使用 Homebrew:
```bash
# 如果已安装 Homebrew（推荐）
brew install nvm

# 添加到 shell 配置
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# 重新运行安装脚本
./install.sh
```

**解决方案 B** - 使用 Gitee 镜像:
```bash
# 如果 GitHub 访问慢，使用 Gitee 镜像
curl -o- https://gitee.com/mirrors/nvm/raw/master/install.sh | bash

# 重新加载 shell
source ~/.bashrc  # 或 source ~/.zshrc

# 重新运行安装脚本
./install.sh
```

**解决方案 C** - 手动下载:
```bash
# 下载安装脚本
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
# 或
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
```

### 问题 2: Xcode Command Line Tools 未安装

**错误信息**:
```
xcrun: error: invalid active developer path
```

**解决方案**:
```bash
# 安装 Xcode Command Line Tools
xcode-select --install

# 等待安装完成后，重新运行安装脚本
./install.sh
```

### 问题 3: shell 配置问题

**现象**: 安装成功但 `openclaw` 命令未找到

**解决方案**:
```bash
# 1. 检查使用的 shell
echo $SHELL

# 2. 根据不同的 shell，加载配置
# Bash
source ~/.bashrc

# Zsh (macOS Catalina 及更高版本默认)
source ~/.zshrc

# 3. 验证安装
node -v
npm -v
openclaw --version
```

### 问题 4: SIP (System Integrity Protection) 问题

**现象**: 无法修改系统文件

**解决方案**:
```bash
# 通常不需要关闭 SIP
# 如果确实遇到 SIP 问题，请检查：
# 1. 不要安装到 /System 或 /usr 目录
# 2. nvm 安装到用户目录 $HOME/.nvm
# 3. OpenClaw 全局安装到 $HOME/.npm-global
```

## 🐧 Linux 问题

### 问题 1: 权限不足

**错误信息**:
```
EACCES: permission denied
```

**解决方案 A** - 使用 sudo（推荐）:
```bash
# 某些操作需要 Root 权限
sudo ./install.sh
```

**解决方案 B** - 配置 npm 全局目录:
```bash
# 创建目录
mkdir ~/.npm-global

# 配置 npm
npm config set prefix '~/.npm-global'

# 添加到 PATH
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 重新安装 OpenClaw
npm install -g openclaw
```

### 问题 2: nvm 安装失败

**解决方案**:
```bash
# 使用 Gitee 镜像（推荐，国内更快）
curl -o- https://gitee.com/mirrors/nvm/raw/master/install.sh | bash

# 或使用 wget
wget -qO- https://gitee.com/mirrors/nvm/raw/master/install.sh | bash

# 重新加载配置
source ~/.bashrc

# 验证 nvm 安装
nvm --version
```

### 问题 3: 依赖包缺失

**错误信息**:
```
error: build error
```

**解决方案**:

**Ubuntu/Debian**:
```bash
sudo apt-get update
sudo apt-get install build-essential libssl-dev
```

**CentOS/RHEL**:
```bash
sudo yum groupinstall "Development Tools"
sudo yum install openssl-devel
```

**Fedora**:
```bash
sudo dnf groupinstall "Development Tools"
sudo dnf install openssl-devel
```

### 问题 4: Python/Make 未找到

**错误信息**:
```
gyp ERR! stack Error: `make` failed with exit code: 2
```

**解决方案**:
```bash
# Ubuntu/Debian
sudo apt-get install python3 make g++

# CentOS/RHEL
sudo yum install python3 make gcc-c++

# 重新安装 OpenClaw
npm install -g openclaw
```

## 🌐 网络问题

### 问题 1: 镜像源全部不可用

**现象**: 所有镜像检测失败

**解决方案 A** - 跳过网络检测:
```bash
# 创建本地配置文件
cp install-config.sh install-config.local.sh

# 编辑配置，添加
echo "SKIP_NETWORK_CHECK=true" >> install-config.local.sh

# 重新运行安装脚本
./install.sh
```

**解决方案 B** - 使用代理:
```bash
# 设置代理
export HTTP_PROXY=http://127.0.0.1:7890
export HTTPS_PROXY=http://127.0.0.1:7890

# 运行安装
./install.sh
```

**解决方案 C** - 使用移动热点:
```
临时切换到手机热点，完成安装后再切换回来
```

### 问题 2: GitHub 下载失败

**解决方案 A** - 使用镜像加速（已内置）:
```bash
# 安装脚本已自动使用 GHProxy 镜像
# 如果仍然失败，可以手动下载后放到指定位置
```

**解决方案 B** - 离线安装:
```bash
# 从其他可访问 GitHub 的设备下载
# 复制到目标设备
# 手动安装
```

### 问题 3: npm install 非常慢

**解决方案**:
```bash
# 1. 检查当前镜像源
npm config get registry

# 2. 切换到淘宝镜像
npm config set registry https://registry.npmmirror.com

# 3. 清理缓存
npm cache clean --force

# 4. 重新安装
npm install -g openclaw
```

## 🔧 卸载与重装

### 完全卸载

**Windows**:
```powershell
# 1. 卸载 OpenClaw
npm uninstall -g openclaw

# 2. 卸载 nvm-windows
# 控制面板 -> 程序和功能 -> nvm-windows

# 3. 删除配置文件
# %APPDATA%\nvm
# %APPDATA%\npm
```

**macOS/Linux**:
```bash
# 1. 卸载 OpenClaw
npm uninstall -g openclaw

# 2. 卸载 nvm
rm -rf $NVM_DIR

# 3. 删除配置
# 编辑 ~/.bashrc 或 ~/.zshrc
# 删除 NVM 相关行
```

### 清理重装

```bash
# 1. 完全卸载（见上）

# 2. 清理缓存
npm cache clean --force

# 3. 重新安装
# Windows: install.bat
# Unix/Linux: ./install.sh
```

## 📋 获取安装日志

### Windows

```powershell
# 查看日志
type %TEMP%\openclaw-install.log

# 或复制到当前目录
copy %TEMP%\openclaw-install.log .
```

### macOS/Linux

```bash
# 查看日志
cat /tmp/openclaw-install.log

# 或复制到当前目录
cp /tmp/openclaw-install.log .
```

## 🆘 仍然无法解决？

### 收集诊断信息

**Windows**:
```powershell
# 系统信息
systeminfo | selectstring /C:"OS" /C:"Version"

# PowerShell 版本
$PSVersionTable

# Node.js 版本（如果已安装）
node -v
npm -v

# nvm 版本（如果已安装）
nvm version
```

**macOS/Linux**:
```bash
# 系统信息
uname -a

# Shell 版本
bash --version
zsh --version

# Node.js 版本（如果已安装）
node -v
npm -v

# nvm 版本（如果已安装）
nvm --version
```

### 获取帮助

- 📖 查看文档: [\.\.\/\.\.\/\.\.\/README.md](\.\.\/\.\.\/\.\.\/README.md)
- 🐛 报告问题: https://github.com/openclaw/openclaw/issues
- 💬 加入社区: https://discord.com/invite/clawd
- 📧 联系支持: support@openclaw.ai

## 💡 预防措施

### 定期更新

```bash
# 更新 OpenClaw
npm update -g openclaw

# 更新 npm
npm install -g npm@latest

# 检查 Node.js 版本
nvm list
```

### 备份配置

```bash
# 备份 OpenClaw 配置
cp -r ~/.openclaw ~/.openclaw.backup.$(date +%Y%m%d)

# 备份 npm 配置
npm config list > npm-config-backup.txt
```

---

💰 *Powered by OpenClaw - 商业价值最大化*
