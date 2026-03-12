# OpenClaw 中文安装指南

> **一站式 OpenClaw 安装配置指南** | 国内网络优化 | 快速上手

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![OpenClaw](https://img.shields.io/badge/OpenClaw-latest-green.svg)](https://github.com/openclaw/openclaw)
[![中文文档](https://img.shields.io/badge/lang-中文-red.svg)](README.md)



---

##  快速开始

### 一键安装（推荐）

**Windows:**
```powershell
cd 01-安装指南\一键安装
.\install.bat
```

**Linux/macOS:**
```bash
cd 01-安装指南/一键安装
chmod +x install.sh && ./install.sh
```

**⏱️ 预计时间**: 5-10分钟
**✨ 特性**:
- ✅ 国内网络优化（淘宝/腾讯云/华为云镜像）
- ✅ GitHub 下载加速（GHProxy）
- ✅ 自动镜像检测和重试
- ✅ 完整的故障排除指南

详细说明：[一键安装文档](./01-安装指南/一键安装/README.md) | [快速开始](./01-安装指南/一键安装/QUICK-START.md)

---

##  文档导航

### 📦 安装指南

| 文档 | 说明 | 时间 | 难度 |
|------|------|------|------|
| [一键安装](./01-安装指南/一键安装/README.md) | **推荐方式** | 5-10分钟 | ⭐ |
| [Linux安装](./01-安装指南/Linux安装.md) | Ubuntu/Debian/CentOS | 10-15分钟 | ⭐ |
| [macOS安装](./01-安装指南/macOS安装.md) | Intel/Apple Silicon | 10-15分钟 | ⭐ |
| [故障排除](./01-安装指南/一键安装/TROUBLESHOOTING.md) | 常见问题解决 | - | - |

### 🔑 Token 配置

| 文档 | 说明 |
|------|------|
| [Token 集成](./02-Token集成/README.md) | 供应商 API 配置 |

### 🔌 平台集成

| 平台 | 说明 | 时间 | 难度 |
|------|------|------|------|
| [Telegram](./03-平台集成/Telegram接入.md) | **最简单** | 5分钟 | ⭐ |
| [飞书](./03-平台集成/飞书接入.md) | **企业推荐** | 30分钟 | ⭐⭐ |
| [QQ](./03-平台集成/QQ接入.md) | 功能强大 | 45分钟 | ⭐⭐⭐ |

### ⚙️ 高级配置

| 文档 | 说明 |
|------|------|
| [Embedding向量数据库](./04-高级配置/Embedding向量数据库.md) | 本地向量数据库配置 |
| [浏览器自动化](./04-高级配置/浏览器自动化.md) | 浏览器+Session+AI分析架构 |
| [平台适配器机制](./04-高级配置/平台适配器机制.md) | 平台适配器选择器更新机制 |

### 📚 参考文档

| 文档 | 说明 |
|------|------|
| [快速参考卡](./05-参考文档/快速参考卡.md) | 命令快速查询 |

---

##  根据场景选择

### 个人使用
- **操作系统**: Linux 或 macOS
- **IM平台**: Telegram
- **预计时间**: 15分钟

**路径**: [一键安装](./01-安装指南/一键安装/README.md) → [Telegram接入](./03-平台集成/Telegram接入.md)

### 小团队
- **操作系统**: Linux (服务器)
- **IM平台**: 飞书 或 企业微信
- **预计时间**: 40分钟

**路径**: [一键安装](./01-安装指南/一键安装/README.md) → [飞书接入](./03-平台集成/飞书接入.md)

### 开发测试
- **操作系统**: macOS
- **IM平台**: 多平台测试
- **预计时间**: 2小时

**路径**: [macOS安装](./01-安装指南/macOS安装.md) → [各平台接入指南](./03-平台集成/)

---

##  核心特性

### 国内网络优化
- ✅ **npm镜像**: 淘宝 → 腾讯云 → 华为云 → 官方源
- ✅ **GitHub加速**: GHProxy镜像服务（自动重试）
- ✅ **智能选择**: 自动检测并选择最快的镜像

### 一键安装
- ✅ **自动依赖检查**: Node.js 22, npm, nvm
- ✅ **自动配置**: 国内镜像源和代理
- ✅ **自动重试**: 网络不稳定时自动重试3次

### 完整文档
- ✅ **从安装到集成**: 覆盖全流程
- ✅ **故障排除**: 详细的错误诊断
- ✅ **最佳实践**: 安全和性能优化

---

##  目录结构

```
openclaw-install-cn/
├── README.md                          # 本文档
├── QUICKSTART.md                      # 快速开始
├── CHANGELOG.md                       # 更新日志
│
├── 01-安装指南/                       # 📦 安装相关
│   ├── 一键安装/                      #    ⭐ 推荐方式
│   │   ├── README.md
│   │   ├── QUICK-START.md
│   │   ├── TROUBLESHOOTING.md
│   │   ├── install.bat
│   │   ├── install.sh
│   │   ├── install.ps1
│   │   └── install-config.*
│   ├── Linux安装.md
│   └── macOS安装.md
│
├── 02-Token集成/                      # 🔑 供应商配置
│   ├── README.md
│   ├── .env.example
│   └── providers/
│       ├── anthropic.example.json
│       ├── openai.example.json
│       ├── google.example.json
│       └── zhipuai.example.json
│
├── 03-平台集成/                       # 🔌 IM平台集成
│   ├── Telegram接入.md
│   ├── 飞书接入.md
│   └── QQ接入.md
│
├── 04-高级配置/                       # ⚙️ 高级配置
│   ├── Embedding向量数据库.md
│   ├── 浏览器自动化.md
│   └── 平台适配器机制.md
│
└── 05-参考文档/                       # 📚 参考文档
    └── 快速参考卡.md
```

---

##  官方资源

- 📖 [OpenClaw 官方文档](https://docs.openclaw.ai)
- 💻 [GitHub 仓库](https://github.com/openclaw/openclaw)
- 💬 [社区 Discord](https://discord.gg/clawd)
- 🛒 [ClawHub Skill 市场](https://clawhub.com)

---

##  贡献指南

欢迎提交 Issue 和 Pull Request！

**文档规范**:
1. 使用 Markdown 格式
2. 保持简洁明了
3. 包含实际案例
4. 及时更新版本

---

##  许可证

MIT License - 详见 [LICENSE](LICENSE)

---

##  更新日志

查看 [CHANGELOG.md](./CHANGELOG.md)

---

**文档维护**: Zandar (第一位天才)
**最后更新**: 2026-03-11
**版本**: 2.0.0

---

💰 *Powered by OpenClaw - 商业价值最大化*
