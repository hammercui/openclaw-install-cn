# 参考文档

OpenClaw 快速参考和常用资源。

---

##  快速参考卡

命令和配置的快速查询手册。

📖 [快速参考卡](./快速参考卡.md)

**包含内容**:
- ✅ 常用命令速查
- ✅ 配置文件示例
- ✅ 快捷键列表
- ✅ 环境变量说明

---

##  常用资源

### 官方资源
- 📖 [OpenClaw 官方文档](https://docs.openclaw.ai)
- 💻 [GitHub 仓库](https://github.com/openclaw/openclaw)
- 💬 [社区 Discord](https://discord.gg/clawd)
- 🛒 [ClawHub Skill 市场](https://clawhub.com)

### 学习资源
- 🎓 [入门教程](https://docs.openclaw.ai/tutorials)
- 💡 [最佳实践](https://docs.openclaw.ai/best-practices)
- 🔍 [示例项目](https://github.com/openclaw/examples)
- 📝 [API 参考](https://docs.openclaw.ai/api)

### 社区资源
- 🌟 [Awesome OpenClaw](https://github.com/openclaw/awesome-openclaw)
- 🤝 [社区贡献](https://github.com/openclaw/openclaw/contributing)
- 🐛 [问题追踪](https://github.com/openclaw/openclaw/issues)

---

##  常见问题 (FAQ)

### 安装相关
**Q: OpenClaw 支持哪些操作系统？**
A: Linux, macOS, Windows (WSL2)

**Q: 最低系统要求是什么？**
A: Node.js 22+, 2GB RAM, 1GB 磁盘空间

**Q: 可以同时安装多个版本吗？**
A: 可以，使用 nvm 管理不同版本

### 配置相关
**Q: 配置文件在哪里？**
A: `~/.openclaw/openclaw.json`

**Q: 如何重置配置？**
A: 删除配置文件后运行 `openclaw init`

**Q: 支持环境变量吗？**
A: 支持，详见配置文档

### 使用相关
**Q: 支持哪些 IM 平台？**
A: Telegram, 飞书, QQ 等

**Q: 可以同时连接多个平台吗？**
A: 可以，配置多个 channels

**Q: 如何查看运行状态？**
A: `openclaw gateway status`

### 故障排查
**Q: Gateway 启动失败？**
A: 查看日志 `openclaw gateway logs`

**Q: Bot 无响应？**
A: 检查网络、Token 和配置

**Q: 如何调试？**
A: 使用 `--debug` 模式查看详细日志

---

##  词汇表

| 术语 | 说明 |
|------|------|
| **Gateway** | OpenClaw 的核心服务，负责消息路由和处理 |
| **Agent** | AI 代理，负责处理用户请求 |
| **Session** | 会话，一次完整的对话过程 |
| **Skill** | 技能，扩展 OpenClaw 功能的插件 |
| **Channel** | 渠道，IM 平台连接（如 Telegram） |
| **Adapter** | 适配器，连接不同平台的接口 |
| **Embedding** | 向量嵌入，用于语义搜索和记忆 |
| **MCP** | Model Context Protocol，模型上下文协议 |

---

##  版本历史

查看 [CHANGELOG.md](../CHANGELOG.md) 了解详细的版本更新记录。

---

##  贡献指南

欢迎贡献文档！

1. Fork 本仓库
2. 创建特性分支
3. 提交更改
4. 发起 Pull Request

**文档规范**:
- 使用 Markdown 格式
- 保持简洁明了
- 包含实际案例
- 及时更新版本

---

##  许可证

MIT License

---

##  联系方式

- 📧 Email: support@openclaw.ai
- 💬 Discord: https://discord.gg/clawd
- 🐛 Issues: https://github.com/openclaw/openclaw/issues

---

💰 *Powered by OpenClaw - 商业价值最大化*
