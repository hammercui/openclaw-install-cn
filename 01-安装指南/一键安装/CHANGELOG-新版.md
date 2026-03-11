# 更新日志

## [2.0.0] - 2026-03-11

### 🎉 重大更新 - 增强版安装脚本

#### 新增功能

**增强版安装脚本** (`install-enhanced.bat` / `install-enhanced.ps1`)
- ✨ **智能镜像选择** - 自动测试并选择最快的镜像源
  - 支持 4 个国内镜像源：淘宝、腾讯云、华为云、清华
  - 使用 ping 测试延迟，自动选择最优镜像
  - npm 和 Node.js 可选择不同的镜像源

- 💾 **永久配置** - 配置永久保存，重启终端不丢失
  - 使用 `setx` 命令设置永久环境变量
  - 创建多个配置文件确保生效：
    - `%USERPROFILE%\.npmrc` - 用户级配置
    - `%APPDATA%\npm\etc\npmrc` - 全局配置
  - PATH 和 NODE_MIRROR 永久生效

- 🔄 **开机启动配置** - 一键配置 Gateway 开机自启
  - 支持注册表方式（推荐）
  - 支持启动文件夹方式（备选）
  - 提供取消开机启动的方法

- 🎯 **更好的用户体验**
  - 详细的进度提示
  - 清晰的错误信息和建议
  - 可选立即初始化和启动
  - 完整的安装总结

#### 新增文档

- `增强版安装说明.md` - 增强版详细功能说明
  - 镜像源列表和特点
  - 安装流程详解
  - 配置文件位置
  - 开机启动管理
  - 常见问题解答
  - 性能对比数据

- `README-新版.md` - 一键安装完整指南
  - 安装方式对比表
  - 推荐方式和快速开始
  - 配置说明和常见问题

#### 改进

- **标准版批处理脚本** (`install-cmd.bat`)
  - 完全使用 CMD 命令，无需 PowerShell
  - 更好的兼容性
  - 详细的错误提示

#### 新增镜像源

- ✅ 淘宝镜像（npm + Node.js）
- ✅ 腾讯云镜像（npm + Node.js）
- ✅ 华为云镜像（npm + Node.js）
- ✅ 清华大学镜像（通过淘宝）

---

## [1.0.0] - 2026-03-11

### 初始版本

#### 功能

- ✅ 一键安装脚本（Windows PowerShell）
- ✅ 多镜像源支持（淘宝、腾讯云、华为云）
- ✅ 自动重试机制
- ✅ GitHub 加速下载（GHProxy）
- ✅ 完整的错误处理
- ✅ 国内网络优化

#### 文档

- `README.md` - 项目总体说明
- `QUICKSTART.md` - 快速开始
- `CHANGELOG.md` - 更新日志
- `TROUBLESHOOTING.md` - 故障排除
- `Windows安装方式对比.md` - 安装方式对比
- `为什么提供纯CMD安装.md` - 设计思路说明

---

## 版本对照表

| 版本 | 发布日期 | 主要特性 | 推荐度 |
|------|---------|---------|--------|
| **2.0.0** | 2026-03-11 | 增强版：智能镜像 + 永久配置 + 开机启动 | ⭐⭐⭐⭐⭐ |
| 1.0.0 | 2026-03-11 | 标准版：多镜像 + 自动重试 | ⭐⭐⭐⭐ |

---

## 升级指南

### 从 1.0.0 升级到 2.0.0

**方法 1: 重新运行增强版安装（推荐）**

```cmd
cd 01-安装指南\一键安装
install-enhanced.bat
```

这会：
- 测试并选择最快的镜像
- 重新配置永久环境变量
- 可选配置开机启动

**方法 2: 手动配置新功能**

1. 手动测试镜像速度并选择
2. 设置永久环境变量：
   ```cmd
   setx NODE_MIRROR "your-best-mirror"
   setx PATH "%PATH%;%APPDATA%\npm"
   ```
3. 配置开机启动：
   ```cmd
   reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OpenClawGateway" /t REG_SZ /d "openclaw gateway start" /f
   ```

---

## 即将发布

### [2.1.0] - 计划中

- [ ] 图形界面安装程序
- [ ] 离线安装包
- [ ] 自动更新检测
- [ ] 多版本共存管理

---

## 贡献指南

欢迎提交 Issue 和 Pull Request！

**文档规范**:
1. 使用 Markdown 格式
2. 保持简洁明了
3. 包含实际案例
4. 及时更新版本

---

## 反馈渠道

- 📖 [文档](https://docs.openclaw.ai)
- 💬 [Discord 社区](https://discord.gg/clawd)
- 🐛 [Issue 追踪](https://github.com/openclaw/openclaw/issues)

---

💰 *Powered by OpenClaw - 商业价值最大化*
