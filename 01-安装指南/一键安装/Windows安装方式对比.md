# Windows 安装方式对比

OpenClaw 提供 3 种 Windows 安装方式，根据你的环境选择最适合的。

---

## 安装方式对比

| 方式 | 命令 | 依赖 | 优点 | 缺点 | 推荐度 |
|------|------|------|------|------|--------|
| **纯批处理** | `install-cmd.bat` | 仅 CMD | 兼容性最好，无需 PowerShell | 功能相对简单 | ⭐⭐⭐⭐⭐ |
| **PowerShell** | `install.bat` | PowerShell 5.0+ | 功能强大，错误处理好 | 需要 PowerShell | ⭐⭐⭐⭐ |
| **手动安装** | 逐步执行命令 | 无 | 完全控制 | 步骤多，容易出错 | ⭐⭐ |

---

## 方式一：纯批处理安装（推荐）

### 特点
- ✅ **兼容性最好**：适用于所有 Windows 版本（XP/7/8/10/11）
- ✅ **无需 PowerShell**：完全使用 CMD 命令
- ✅ **轻量级**：脚本简单，执行快速
- ✅ **国内优化**：自动配置淘宝镜像

### 适用场景
- PowerShell 被禁用或版本过低
- 需要最大兼容性
- 追求简单直接

### 使用方法

```cmd
# 1. 进入安装目录
cd D:\moneyProject\openclaw-install-cn\01-安装指南\一键安装

# 2. 运行纯批处理安装脚本
install-cmd.bat

# 3. 等待安装完成
```

### 安装流程
1. 检查 Node.js 是否已安装
2. 如需要，下载并安装 Node.js 22
3. 配置 npm 淘宝镜像
4. 安装 OpenClaw
5. 验证安装
6. 可选：立即初始化配置

### 功能说明
- ✅ 自动检测 Node.js
- ✅ 自动配置国内镜像
- ✅ 支持 nvm 管理 Node.js 版本
- ✅ 完整的错误提示
- ✅ 安装后可选立即初始化

---

## 方式二：PowerShell 安装

### 特点
- ✅ **功能强大**：支持复杂逻辑和错误处理
- ✅ **更好的错误处理**：详细的错误信息
- ✅ **进度显示**：实时显示安装进度
- ✅ **镜像自动检测**：自动选择最快的镜像

### 适用场景
- Windows 7 或更高版本
- PowerShell 可用
- 需要更强大的功能

### 使用方法

```powershell
# 1. 进入安装目录
cd D:\moneyProject\openclaw-install-cn\01-安装指南\一键安装

# 2. 运行 PowerShell 安装脚本
.\install.bat

# 3. 等待安装完成
```

### 额外功能
- ✅ 智能镜像检测（淘宝/腾讯云/华为云）
- ✅ GitHub 下载加速（GHProxy）
- ✅ 自动重试机制（3次）
- ✅ 详细的安装日志
- ✅ 支持 Node.js 多版本管理

---

## 方式三：手动安装

### 适用场景
- 想要完全控制安装过程
- 学习 OpenClaw 的安装原理
- 自动化脚本失败时的备选方案

### 安装步骤

#### 1. 安装 Node.js

**使用 nvm-windows（推荐）**:
```cmd
# 下载 nvm-windows
# https://github.com/coreybutler/nvm-windows/releases

# 安装 Node.js 22
nvm install 22
nvm use 22
```

**或直接安装**:
```cmd
# 下载 Node.js
# https://npmmirror.com/mirrors/node/v22.11.0/
```

#### 2. 配置 npm 镜像
```cmd
npm config set registry https://registry.npmmirror.com
```

#### 3. 安装 OpenClaw
```cmd
npm install -g openclaw
```

#### 4. 验证安装
```cmd
openclaw --version
```

#### 5. 初始化配置
```cmd
openclaw init
```

#### 6. 启动 Gateway
```cmd
openclaw gateway start
```

---

## 常见问题

### Q1: 应该选择哪种安装方式？

**推荐顺序**:
1. **install-cmd.bat**（纯批处理）- 最简单，兼容性最好
2. **install.bat**（PowerShell）- 功能最强
3. **手动安装** - 学习用途

### Q2: 纯批处理版本功能少吗？

不会！纯批处理版本包含：
- ✅ 自动安装 Node.js
- ✅ 自动配置镜像
- ✅ 自动安装 OpenClaw
- ✅ 完整的错误提示
- ✅ 可选的立即初始化

对于大多数用户来说，功能完全够用。

### Q3: PowerShell 版本有什么额外功能？

PowerShell 版本额外提供：
- ✅ 多个镜像源自动检测
- ✅ GitHub 加速下载
- ✅ 智能重试机制
- ✅ 更详细的日志
- ✅ 更好的错误恢复

### Q4: 安装失败怎么办？

1. **检查网络连接**
   ```cmd
   ping registry.npmmirror.com
   ```

2. **手动配置镜像**
   ```cmd
   npm config set registry https://registry.npmmirror.com
   ```

3. **检查 Node.js 版本**
   ```cmd
   node -v
   ```

4. **查看故障排除文档**
   - [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

### Q5: 可以切换安装方式吗？

可以！所有安装方式最终结果相同，可以随时切换：

```cmd
# 如果已用纯批处理安装，想用 PowerShell 版本重装：
npm uninstall -g openclaw
.\install.bat
```

---

## 技术对比

### 纯批处理 vs PowerShell

| 特性 | 纯批处理 | PowerShell |
|------|---------|------------|
| **兼容性** | 所有 Windows 版本 | Windows 7+ |
| **依赖** | 仅 CMD | PowerShell 5.0+ |
| **脚本复杂度** | 简单 | 复杂 |
| **错误处理** | 基本 | 高级 |
| **执行速度** | 快 | 中等 |
| **功能完整性** | 90% | 100% |
| **维护成本** | 低 | 中等 |
| **学习曲线** | 平缓 | 陡峭 |

### 推荐选择

**新手用户**: 纯批处理（`install-cmd.bat`）
**高级用户**: PowerShell（`install.bat`）
**开发者**: 手动安装

---

## 总结

对于大多数 Windows 用户，**推荐使用纯批处理版本**（`install-cmd.bat`）：

- ✅ 最简单
- ✅ 兼容性最好
- ✅ 功能完全够用
- ✅ 不依赖其他工具

如果你需要更多功能或更好的错误处理，可以选择 PowerShell 版本。

---

💰 *Powered by OpenClaw - 商业价值最大化*
