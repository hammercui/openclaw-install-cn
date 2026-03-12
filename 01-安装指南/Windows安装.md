# Windows 一键安装指南

## 📦 安装脚本说明

| 脚本 | 方式 | 推荐度 | 适用场景 |
|------|------|--------|---------|
| `install-enhanced.bat` | 纯批处理（无需 PowerShell） | ⭐⭐⭐⭐⭐ | **推荐，兼容所有 Windows** |
| `install-enhanced-wrapper.bat` | 批处理调用 PowerShell | ⭐⭐⭐⭐ | PowerShell 可用时 |

---

## 🚀 快速开始

### 方式一：纯批处理（推荐）

无需 PowerShell，兼容 Windows 7/8/10/11。

```cmd
install-enhanced.bat
```

或直接在资源管理器中**双击** `install-enhanced.bat`。

---

### 方式二：PowerShell 版本

需要 PowerShell 5.0+。

```cmd
install-enhanced-wrapper.bat
```

---

## 🎯 安装过程说明

脚本分 7 步完成安装，全程自动执行：

### 第 1 步：测试镜像源速度

自动 ping 测试以下镜像，选择延迟最低的：

| 用途 | 镜像源 |
|------|--------|
| npm | 淘宝、腾讯云、华为云、清华 |
| Node.js 下载 | 淘宝、腾讯云、华为云 |

### 第 2 步：检查 / 安装 Node.js

- 若已安装，跳过
- 若已有 nvm，使用 `nvm install 22`
- 若无，从最快镜像下载 Node.js 22 MSI 安装包并静默安装

### 第 3 步：配置 npm 镜像（永久生效）

同时写入三处，确保重启终端后配置不丢失：

```
%USERPROFILE%\.npmrc
%APPDATA%\npm\etc\npmrc
当前会话 npm config
```

### 第 4 步：配置环境变量（永久生效）

使用 `setx` 将 `%APPDATA%\npm` 加入 PATH，设置 `NODE_MIRROR` 变量。

### 第 5 步：安装 OpenClaw

```cmd
npm install -g openclaw
```

若已安装则自动更新。

### 第 6 步：验证安装

检查 `openclaw` 命令是否可用，输出版本号。

### 第 7 步：配置开机启动（可选，交互询问）

输入 `Y` 启用，脚本优先使用注册表方式，失败则退回启动文件夹方式：

```
注册表路径：HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
启动文件夹：%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\
```

取消开机启动：

```cmd
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OpenClawGateway" /f
```

---

## ✅ 安装完成后

脚本最后会询问是否立即初始化并启动：

```cmd
# 手动初始化
openclaw init

# 启动 Gateway
openclaw gateway start

# 查看运行状态
openclaw gateway status
```

---

## ⚙️ 自定义配置（可选）

如需修改镜像源或 Node.js 版本，可在运行安装前创建本地配置：

```cmd
copy install-config.example.ps1 install-config.local.ps1
notepad install-config.local.ps1
```

---

## 🔍 故障排除

遇到问题请查看 [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)。

### 常见问题

**安装后 `openclaw` 命令找不到**

```cmd
# 手动添加 npm 全局目录到当前会话
set PATH=%PATH%;%APPDATA%\npm

# 或重启命令提示符（setx 已永久写入，重启后自动生效）
```

**Node.js 下载失败**

```cmd
# 手动下载 Node.js 22 安装包
# 淘宝镜像：https://npmmirror.com/mirrors/node/v22.11.0/node-v22.11.0-x64.msi
msiexec /i node-v22.11.0-x64.msi
```

**npm install 失败**

```cmd
# 手动设置镜像源后重试
npm config set registry https://registry.npmmirror.com
npm cache clean --force
npm install -g openclaw
```

**需要管理员权限**

右键 `install-enhanced.bat` → **以管理员身份运行**。
