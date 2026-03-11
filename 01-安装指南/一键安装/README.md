# OpenClaw 一键安装脚本

> 📍 位置：`01-平台安装/一键安装/`

## 🚀 快速开始

### Windows

```powershell
# 方法 1：双击运行
双击 install.bat

# 方法 2：命令行运行
install.bat
```

### macOS/Linux

```bash
# 方法 1：直接运行
chmod +x install.sh
./install.sh

# 方法 2：使用 bash
bash install.sh
```

## ✨ 特性

### 国内网络优化

- ✅ **自动选择最佳镜像源**（淘宝、腾讯云、华为云）
- ✅ **GitHub 下载加速**（使用 GHProxy 镜像）
- ✅ **nvm 安装优化**（使用 Gitee 镜像）
- ✅ **自动重试机制**（网络不稳定时自动重试）

### 智能检测

- 🔍 自动检测 nvm 是否已安装
- 🔍 自动检测 Node.js 22 是否已安装
- 🔍 自动检测镜像源可用性
- 🔍 自动选择最快的镜像源

### 用户友好

- 🎨 彩色输出（Windows/macOS/Linux）
- 📊 详细的安装进度
- ✅ 完整的错误提示
- 📝 安装后环境信息展示

## 📋 系统要求

### Windows

- Windows 10/11 或 Windows Server 2016+
- PowerShell 5.0 或更高版本
- 管理员权限（安装 nvm-windows 需要）

### macOS

- macOS 10.15 (Catalina) 或更高版本
- Xcode Command Line Tools
- Homebrew（可选，用于安装 nvm）

### Linux

- 任何主流发行版（Ubuntu、CentOS、Debian、Fedora 等）
- curl 或 wget
- bash 4.0 或更高版本

## 🔧 自定义配置

### 创建本地配置文件

#### Bash (macOS/Linux)

```bash
# 1. 复制示例配置
cp install-config.sh install-config.local.sh

# 2. 编辑配置文件
nano install-config.local.sh

# 3. 运行安装脚本（会自动加载配置）
./install.sh
```

#### PowerShell (Windows)

```powershell
# 1. 复制示例配置
cp install-config.example.ps1 install-config.local.ps1

# 2. 编辑配置文件
notepad install-config.local.ps1

# 3. 运行安装脚本（会自动加载配置）
.\install.bat
```

### 可配置选项

```bash
# npm 镜像源
NPM_MIRRORS=(
    "https://registry.npmmirror.com"    # 淘宝镜像
    "https://mirrors.cloud.tencent.com/npm"   # 腾讯云
    "https://mirrors.huaweicloud.com/repository/npm/"  # 华为云
)

# Node.js 镜像源
NVM_NODE_MIRRORS=(
    "https://npmmirror.com/mirrors/node"
    "https://mirrors.cloud.tencent.com/npm/"
)

# Node.js 版本
NODE_VERSION="22"

# 下载重试次数
DOWNLOAD_MAX_RETRIES=3
```

## 📦 安装内容

安装脚本会自动完成：

1. **安装 nvm**（如果未安装）
   - Windows: nvm-windows
   - macOS/Linux: nvm (via Gitee mirror)

2. **安装 Node.js 22 LTS**
   - 使用 nvm 安装
   - 设置为默认版本

3. **配置国内镜像源**
   - npm registry（淘宝镜像）
   - nvm Node 镜像
   - nvm npm 镜像

4. **全局安装 OpenClaw**
   - 使用 npm install -g
   - 自动重试机制

5. **验证安装**
   - 显示版本信息
   - 显示环境信息

## 🔍 故障排除

### 常见问题

#### 1. Windows: nvm-windows 安装失败

**问题**: 无法下载 nvm-setup.exe

**解决方案**:
```powershell
# 手动下载并安装
# 访问: https://github.com/coreybutler/nvm-windows/releases
# 或使用国内镜像: https://gitee.com/mirrors/nvm-windows/releases
```

#### 2. macOS/Linux: nvm 安装失败

**问题**: curl/wget 无法连接

**解决方案**:
```bash
# 使用 Gitee 镜像安装 nvm
curl -o- https://gitee.com/mirrors/nvm/raw/master/install.sh | bash

# 或手动下载安装脚本
wget https://gitee.com/mirrors/nvm/raw/master/install.sh
bash install.sh
```

#### 3. Node.js 22 安装失败

**问题**: 无法下载 Node.js

**解决方案**:
```bash
# 手动配置镜像源
export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node
nvm install 22
```

#### 4. OpenClaw 安装失败

**问题**: npm install 失败

**解决方案**:
```bash
# 检查镜像源
npm config get registry

# 手动设置镜像源
npm config set registry https://registry.npmmirror.com

# 清理缓存后重试
npm cache clean --force
npm install -g openclaw
```

#### 5. 网络检测不准确

**问题**: 镜像检测全部失败

**解决方案**:
```bash
# 创建本地配置文件，跳过网络检测
cp install-config.sh install-config.local.sh

# 编辑 install-config.local.sh
# 添加: SKIP_NETWORK_CHECK=true
```

### 日志文件

如果安装失败，查看日志文件：

- Windows: `%TEMP%\openclaw-install.log`
- macOS/Linux: `/tmp/openclaw-install.log`

## 📚 下一步

安装完成后，运行以下命令开始使用：

```bash
# 1. 初始化配置
openclaw init

# 2. 启动 Gateway
openclaw gateway start

# 3. 查看状态
openclaw gateway status

# 4. 查看帮助
openclaw help
```

详细文档：[\.\.\/\.\.\/\.\.\/../README.md](\.\.\/\.\.\/\.\.\/../README.md)

## 🆘 获取帮助

- 查看故障排除指南：[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
- 查看快速开始指南：[QUICK-START.md](./QUICK-START.md)
- 访问 OpenClaw 文档：https://docs.openclaw.ai
- 加入社区：https://discord.com/invite/clawd

## 📝 更新日志

### v1.0.0 (2026-03-11)

- ✅ 初始版本
- ✅ 支持国内网络优化
- ✅ 自动镜像源选择
- ✅ GitHub 下载加速
- ✅ 自动重试机制
- ✅ 完整的错误处理

---

💰 *Powered by OpenClaw - 商业价值最大化*
