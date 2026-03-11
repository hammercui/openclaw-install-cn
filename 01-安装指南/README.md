# 安装指南

OpenClaw 多平台安装指南和一键安装脚本。

---

##  快速开始

### ⭐ 推荐方式：一键安装

**最简单的安装方式，自动配置国内镜像优化。**

- 📖 [一键安装文档](./一键安装/README.md)
- 🚀 [快速开始](./一键安装/QUICK-START.md)
- 🔧 [故障排除](./一键安装/TROUBLESHOOTING.md)

**Windows:**
```powershell
cd 一键安装
.\install.bat
```

**Linux/macOS:**
```bash
cd 一键安装
chmod +x install.sh && ./install.sh
```

---

##  手动安装

### Linux

支持 Ubuntu/Debian、CentOS/Rocky Linux、Arch Linux 等主流发行版。

📖 [Linux 安装指南](./Linux安装.md)

### macOS

支持 Intel Mac 和 Apple Silicon (M1/M2/M3)。

📖 [macOS 安装指南](./macOS安装.md)

### Windows

推荐使用一键安装脚本或 WSL2 方式安装。

📖 [Windows 一键安装](./一键安装/README.md)

---

##  安装方式对比

| 方式 | 时间 | 难度 | 推荐度 |
|------|------|------|--------|
| **一键安装** | 5-10分钟 | ⭐ | ⭐⭐⭐⭐⭐ |
| **手动安装** | 10-20分钟 | ⭐⭐ | ⭐⭐⭐ |

---

##  前置要求

### 最低要求
- **Node.js**: 22.x 或更高
- **npm**: 10.x 或更高
- **操作系统**:
  - Linux: Ubuntu 20.04+, CentOS 8+, Arch Linux
  - macOS: 12.0+ (Monterey)
  - Windows: 10/11 (推荐一键安装脚本或 WSL2)

### 推荐配置
- **内存**: 2GB+
- **磁盘**: 1GB 可用空间
- **网络**: 能够访问 npm registry 或使用镜像

---

##  国内网络优化

### 镜像源优先级
1. **淘宝镜像** (registry.npmmirror.com) - 主力
2. **腾讯云镜像** (mirrors.cloud.tencent.com) - 备用
3. **华为云镜像** (mirrors.huaweicloud.com) - 备用
4. **官方源** (registry.npmjs.org) - 最后

### GitHub 下载加速
- **GHProxy**: https://mirror.ghproxy.com
- 自动检测和重试机制

---

##  下一步

安装完成后，配置 IM 平台：

- [Telegram 接入](../03-IM平台集成/Telegram接入.md) - 5分钟
- [飞书接入](../03-IM平台集成/飞书接入.md) - 30分钟
- [QQ 接入](../03-IM平台集成/QQ接入.md) - 45分钟

---

##  获取帮助

遇到问题？

- 🔧 [故障排除指南](./一键安装/TROUBLESHOOTING.md)
- 📖 [完整文档](../README.md)
- 💬 [社区 Discord](https://discord.gg/clawd)

---

💰 *Powered by OpenClaw - 商业价值最大化*
