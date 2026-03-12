# IM 平台集成指南

OpenClaw 多平台 IM 集成配置指南。

---

##  支持的平台

| 平台 | 时间 | 难度 | 推荐度 |
|------|------|------|--------|
| [Telegram](./Telegram接入.md) | 5分钟 | ⭐ | ⭐⭐⭐⭐⭐ |
| [飞书](./飞书接入.md) | 30分钟 | ⭐⭐ | ⭐⭐⭐⭐ |
| [QQ](./QQ接入.md) | 45分钟 | ⭐⭐⭐ | ⭐⭐⭐ |

---

##  快速选择

### 个人使用
推荐 **Telegram** - 最简单，5分钟搞定。

👉 [Telegram 接入指南](./Telegram接入.md)

### 企业团队
推荐 **飞书** - 企业级功能，权限管理完善。

👉 [飞书接入指南](./飞书接入.md)

### 开发测试
推荐 **QQ** - 功能强大，适合二次开发。

👉 [QQ 接入指南](./QQ接入.md)

---

##  基本流程

### 1. 创建应用/Bot

不同平台的创建方式：

- **Telegram**: 使用 @BotFather
- **飞书**: 企业自建应用
- **QQ**: NapCat 或 go-cqhttp

### 2. 获取凭证

- Bot Token / App ID / App Secret
- Webhook URL
- 权限配置

### 3. 配置 OpenClaw

编辑 `~/.openclaw/openclaw.json`:

```json
{
  "channels": {
    "telegram": {
      "botToken": "YOUR_BOT_TOKEN"
    },
    "feishu": {
      "appId": "YOUR_APP_ID",
      "appSecret": "YOUR_APP_SECRET"
    }
  }
}
```

### 4. 重启服务

```bash
openclaw gateway restart
```

### 5. 测试连接

向你的 Bot 发送消息，测试是否正常响应。

---

##  高级配置

### Webhook 模式
适合生产环境，实时性更好。

### 轮询模式
适合开发测试，配置简单。

### 多平台同时使用
OpenClaw 支持同时连接多个平台。

---

##  安全建议

### 1. Token 管理
- ✅ 使用环境变量
- ✅ 不要提交到 Git
- ✅ 定期更换 Token

### 2. 权限控制
- ✅ 最小权限原则
- ✅ IP 白名单（如果支持）
- ✅ 消息加密

### 3. 限流保护
- ✅ 配置合理的速率限制
- ✅ 监控异常请求
- ✅ 日志审计

---

##  故障排查

### Bot 无响应？
1. 检查 Gateway 是否运行: `openclaw gateway status`
2. 查看日志: `openclaw gateway logs`
3. 验证 Token 是否正确

### 消息接收延迟？
1. 检查网络连接
2. 切换到 Webhook 模式
3. 优化配置参数

### 权限错误？
1. 检查 Bot/App 权限设置
2. 重新配置 scopes
3. 联系平台管理员

---

##  参考资源

### 官方文档
- [Telegram Bot API](https://core.telegram.org/bots/api)
- [飞书开放平台](https://open.feishu.cn/)
- [QQ 机器人](https://bot.q.qq.com/)

### 示例项目
- [OpenClaw Examples](https://github.com/openclaw/examples)
- [社区项目](https://clawhub.com)

---

##  下一步

配置完 IM 平台后，可以：

- ⚙️ [配置 Embedding 向量库](../03-高级配置/Embedding向量数据库.md)
- 🌐 [配置浏览器自动化](../03-高级配置/浏览器自动化.md)
- 📚 [查看快速参考卡](../04-参考文档/快速参考卡.md)

---

##  获取帮助

- 🔧 [故障排除指南](../01-安装指南/一键安装/TROUBLESHOOTING.md)
- 📖 [完整文档](../README.md)
- 💬 [社区 Discord](https://discord.gg/clawd)

---

💰 *Powered by OpenClaw - 商业价值最大化*
