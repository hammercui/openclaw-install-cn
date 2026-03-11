# OpenClaw 一键安装 - 完整指南

## 📦 安装方式总览

OpenClaw 提供多种安装方式，满足不同需求：

| 安装方式 | 脚本文件 | 特点 | 推荐度 | 适用场景 |
|---------|---------|------|--------|---------|
| **增强版批处理** | `install-enhanced.bat` | 🚀 自动测试镜像 + 💾 永久配置 + 🔄 开机启动 | ⭐⭐⭐⭐⭐ | **推荐！适用于所有用户** |
| **增强版 PowerShell** | `install-enhanced-wrapper.bat` | 同上，PowerShell 实现 | ⭐⭐⭐⭐⭐ | Windows 用户 |
| **标准版批处理** | `install-cmd.bat` | 纯批处理，固定淘宝镜像 | ⭐⭐⭐ | 兼容性优先 |
| **标准版 PowerShell** | `install.bat` | 多镜像自动重试 | ⭐⭐⭐⭐ | 功能优先 |
| **手动安装** | 逐步执行 | 完全控制 | ⭐⭐ | 学习用途 |

---

## 🚀 推荐方式：增强版一键安装

### Windows 用户（推荐）

```cmd
# 进入安装目录
cd D:\moneyProject\openclaw-install-cn\01-安装指南\一键安装

# 运行增强版安装
install-enhanced.bat
```

**功能亮点**:
- ✅ 自动测试并选择最快的镜像源（淘宝/腾讯云/华为云/清华）
- ✅ 永久配置环境变量（重启终端不丢失）
- ✅ 可选配置开机启动
- ✅ 完整的错误提示和建议

**预计时间**: 3-8 分钟（取决于网络速度）

### Linux/macOS 用户

```bash
cd 01-安装指南/一键安装
chmod +x install.sh && ./install.sh
```

---

## 🎯 增强版 vs 标准版

### 增强版（推荐）

**新增功能**:
1. **智能镜像选择** - 自动测试延迟，选择最快镜像
2. **永久配置** - 使用 `setx` 和配置文件，重启不丢失
3. **开机启动** - 一键配置 Gateway 开机自启
4. **更好的体验** - 详细的进度提示和错误处理

**适用场景**:
- ✅ 所有 Windows 用户
- ✅ 服务器环境（需要开机启动）
- ✅ 追求最佳性能
- ✅ 不想重复配置

### 标准版

**特点**:
- 脚本简单，易于理解
- 固定使用淘宝镜像
- 临时配置（重启终端可能丢失）

**适用场景**:
- ⚠️ PowerShell 被禁用
- ⚠️ 网络环境简单（无需测试）
- ⚠️ 临时使用

---

## 📖 详细文档

### 增强版文档

- [增强版安装说明](./增强版安装说明.md) - **必读！详细功能说明**
- [镜像源列表](./增强版安装说明.md#-镜像源列表) - 支持的镜像源
- [开机启动配置](./增强版安装说明.md#-开机启动管理) - 如何管理开机启动
- [常见问题](./增强版安装说明.md#-常见问题) - 故障排除

### 标准版文档

- [Windows 安装方式对比](./Windows安装方式对比.md) - CMD vs PowerShell
- [为什么提供纯CMD安装](./为什么提供纯CMD安装.md) - 设计思路

### 其他文档

- [QUICKSTART](./QUICK-START.md) - 快速开始指南
- [TROUBLESHOOTING](./TROUBLESHOOTING.md) - 故障排除
- [安装配置说明](./安装配置说明.md) - 高级配置

---

## 🚀 快速开始

### 1. 增强版安装（推荐）

```cmd
install-enhanced.bat
```

**安装流程**:
1. 测试镜像源速度（淘宝/腾讯云/华为云）
2. 自动选择最快的镜像
3. 安装 Node.js（如需要）
4. 配置 npm 和环境变量（永久生效）
5. 安装 OpenClaw
6. 验证安装
7. 可选：配置开机启动
8. 可选：立即初始化并启动

### 2. 验证安装

```cmd
# 查看 OpenClaw 版本
openclaw --version

# 查看帮助
openclaw --help

# 查看 Gateway 状态
openclaw gateway status
```

### 3. 初始化配置

```cmd
openclaw init
```

### 4. 启动 Gateway

```cmd
openclaw gateway start
```

---

## 🔧 配置说明

### 镜像源配置

增强版会自动选择最快的镜像，但也可以手动修改：

**查看当前配置**:
```cmd
npm config get registry
```

**手动修改**:
```cmd
# 淘宝镜像
npm config set registry https://registry.npmmirror.com

# 腾讯云镜像
npm config set registry https://mirrors.cloud.tencent.com/npm/

# 华为云镜像
npm config set registry https://mirrors.huaweicloud.com/repository/npm/
```

### 环境变量

增强版已永久配置环境变量，查看方式：

**命令行**:
```cmd
echo %NODE_MIRROR%
echo %PATH%
```

**图形界面**:
```
控制面板 → 系统 → 高级系统设置 → 环境变量
```

### 开机启动

**查看开机启动项**:
```cmd
reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
```

**取消开机启动**:
```cmd
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OpenClawGateway" /f
```

---

## ❓ 常见问题

### Q: 应该选择哪个安装脚本？

**A: 推荐使用 `install-enhanced.bat`**（增强版批处理）

**理由**:
- ✅ 自动选择最快的镜像
- ✅ 配置永久保存
- ✅ 支持开机启动
- ✅ 最好的用户体验

### Q: 增强版和标准版有什么区别？

| 功能 | 增强版 | 标准版 |
|------|--------|--------|
| 镜像测试 | ✅ 自动测试 | ❌ 固定淘宝 |
| 永久配置 | ✅ 使用 setx | ❌ 仅当前会话 |
| 开机启动 | ✅ 可选配置 | ❌ 无 |
| 镜像数量 | 4 个 | 1-3 个 |
| 适用场景 | 所有用户 | 兼容性优先 |

### Q: 重启终端后配置丢失怎么办？

**原因**: 使用了标准版（临时配置）

**解决方案**:
1. 重新运行增强版脚本：`install-enhanced.bat`
2. 或手动设置永久环境变量：
   ```cmd
   setx NODE_MIRROR "your-mirror-url"
   setx PATH "%PATH%;%APPDATA%\npm"
   ```

### Q: 如何更换镜像源？

**方法 1: 重新运行增强版**
```cmd
install-enhanced.bat
# 会重新测试并选择最快镜像
```

**方法 2: 手动修改**
```cmd
npm config set registry https://your-preferred-mirror
```

### Q: 开机启动不工作？

**检查**:
1. 是否以管理员权限运行脚本
2. 注册表项是否存在：
   ```cmd
   reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
   ```
3. 启动文件夹是否有快捷方式：
   ```
   %APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
   ```

**解决**: 查看详细故障排除：[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

---

## 🎯 安装后操作

### 1. 初始化配置

```cmd
openclaw init
```

### 2. 配置 IM 平台

选择一个平台接入：

- **Telegram**（最简单）: [Telegram 接入指南](../../03-平台集成/Telegram接入.md)
- **飞书**（企业推荐）: [飞书接入指南](../../03-平台集成/飞书接入.md)
- **QQ**（功能强大）: [QQ 接入指南](../../03-平台集成/QQ接入.md)

### 3. 启动服务

```cmd
# 启动 Gateway
openclaw gateway start

# 查看状态
openclaw gateway status

# 查看日志
openclaw gateway logs
```

### 4. 测试功能

向配置的 IM 平台发送消息测试。

---

## 📚 更多文档

- [项目 README](../../README.md) - 项目总体说明
- [QUICKSTART](../../QUICKSTART.md) - 快速开始
- [故障排除](./TROUBLESHOOTING.md) - 问题解决
- [增强版详细说明](./增强版安装说明.md) - 增强版功能详解

---

## 🆘 获取帮助

如果遇到问题：

1. 查看 [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
2. 查看日志：`openclaw gateway logs`
3. 访问 [OpenClaw 文档](https://docs.openclaw.ai)
4. 加入 [Discord 社区](https://discord.gg/clawd)

---

💰 *Powered by OpenClaw - 商业价值最大化*
