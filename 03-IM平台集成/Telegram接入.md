# Telegram Bot接入指南 - 小龙虾(OpenClaw)
> **难度**: ⭐ 最简单
> **时间**: 5分钟
> **推荐度**: ⭐⭐⭐⭐⭐
> **适合**: 个人使用,快速测试

---

## 前置要求
- OpenClaw已安装, Telegram账号, 网络连接(如果在国内需要VPN)

## 5分钟快速接入

### 步骤1:创建Telegram Bot(2分钟)
1. 在Telegram中搜索 `@BotFather`
2. 发送 `/newbot`
3. 按提示设置bot名称:
 ```
 Bot name: OpenClaw Assistant
 Bot username: MyOpenClawBot (必须以bot结尾)
4. 保存生成的 **Bot Token**(格式:`123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

**示例对话**:
You: /newbot
BotFather: Alright, a new bot. How are we going to call it? Please choose a name for your bot.

You: OpenClaw Assistant
BotFather: Good. Now let's choose a username for your bot. It must end in `bot`. Like this, for example: TetrisBot or tetris_bot.

You: MyOpenClawBot
BotFather: Done! Congratulations on your new bot. You will find it at t.me/MyOpenClawBot. You can now add a description, about section and profile picture for your bot, see /help for a list of commands.

Use this token to access the HTTP API:
123456789:ABCdefGHIjklMNOpqrsTUVwxyz

Keep your token secure and store it safely, it can be used by anyone to control your bot.

### 步骤2:配置OpenClaw(2分钟)
编辑配置文件:

```bash

# 编辑配置
vim ~/.openclaw/openclaw.json

在 `channels` 部分添加:

```json
{
 "channels": {
 "telegram": {
 "enabled": true,
 "token": "你的Bot Token",
 "streamMode": "partial",
 "blockStreaming": false
 }

**配置项说明**:

`enabled`, 说明=是否启用, 推荐值=`true`
`token`, 说明=Bot Token(从BotFather获取), 推荐值=必填
`streamMode`, 说明=流式输出模式, 推荐值=`partial`(平衡)
`blockStreaming`, 说明=是否阻塞流式, 推荐值=`false`(允许流式)

# 启动或重启Gateway
openclaw gateway restart

# 查看日志(确认无错误)
tail -f ~/.openclaw/logs/gateway.log

**成功标志**:
[INFO] Telegram channel initialized
[INFO] Listening for messages...

### 步骤4:测试Bot
1. 在Telegram中找到你的bot(搜索用户名)
2. 点击"START"或发送 `/start`
3. 发送测试消息:`hello`
4. Bot应该会回复你

## ️ 高级配置

### 1. 设置Bot描述
让Bot更专业:

发送给 @BotFather:
/setdescription

我的OpenClaw AI智能助手,可以帮我写代码,查资料,做计划.

/setabouttext

Powered by OpenClaw

### 2. 设置Bot头像
/setuserpic

[上传图片]

### 3. 配置命令列表
/setcommands

start - 开始使用
help - 获取帮助
status - 查看状态

### 4. 启用隐私模式
/setprivacy

Disabled

**说明**:禁用隐私模式后,Bot可以读取群组中所有消息(不仅仅是命令).

## 使用场景

### 场景1:个人助手
**配置**:单人聊天

**用途**:
- 写代码, 查资料, 做计划, 学习辅导

### 场景2:群组助手
**配置**:添加到群组

**步骤**:
1. 在群组中点击群名称
2. 点击"添加成员" → "添加机器人"
3. 搜索你的bot
4. 添加到群组

- 群组AI问答, 代码审查, 资料查询

### 场景3:频道推送
**配置**:使用channel webhook

- 自动发布内容, 定时推送, 消息广播

## 故障排查

### 问题1:Bot不回复消息
**检查清单**:

# 1. 确认Token正确
cat ~/.openclaw/openclaw.json | grep token

# 2. 确认Gateway运行
openclaw gateway status

# 3. 查看日志
tail -f ~/.openclaw/logs/gateway.log | grep telegram

**常见原因**:
- Token错误(重新从BotFather获取)
- Gateway未启动(运行 `openclaw gateway start`)
- 网络问题(Telegram在国内需要VPN)

### 问题2:Token无效
Error: Unauthorized (401)

**解决**:
1. 访问 @BotFather
2. 发送 `/token`
3. 选择你的bot
4. 重新生成token
5. 更新 `openclaw.json`

### 问题3:无法访问Telegram
**原因**:Telegram在某些地区被封锁

**解决方案**:

**方案1:使用代理**

# 设置代理
export HTTP_PROXY=http://127.0.0.1:7890
export HTTPS_PROXY=http://127.0.0.1:7890

# 重启Gateway
**方案2:配置OpenClaw使用代理**

编辑 `~/.openclaw/openclaw.json`:
 "token": "YOUR_TOKEN",
 "proxy": "http://127.0.0.1:7890"

### 问题4:Bot响应慢
**优化**:

1. **调整流式输出**
 "streamMode": "full" // 更快但分块更多

2. **使用更快的模型**
 "agents": {
 "defaults": {
 "model": "google-antigravity/gemini-3-flash"

3. **调整思考级别**
 "thinking": "low"

## Bot定制

### 1. 自定义欢迎消息
当用户第一次使用 `/start` 时,Bot可以发送自定义欢迎消息.

在Telegram中发送给 @BotFather:
/setstart

欢迎使用OpenClaw智能助手!我可以帮你:
- 写代码, 查资料, 提供建议, 分析数据

直接发送消息即可开始!

### 2. 自定义帮助消息
/sethelp

OpenClaw智能助手使用指南:

基础命令:
/start - 开始使用
/help - 显示帮助

功能:
- 发送代码片段,我会帮你审查, 发送问题,我会帮你解答, 发送任务,我会帮你规划

更多帮助:https://docs.openclaw.ai

### 3. 设置命令菜单
start- 开始使用
help- 获取帮助
status- 系统状态
about- 关于

这样用户在输入框旁会看到命令菜单.

## 安全建议

### 1. 保护Token
**不要做的事**:
- 提交到公开仓库, 分享给他人, 在不安全的地方存储

**应该做的事**:
- 使用环境变量, 定期更换token, 限制Bot权限

**使用环境变量**:

# 在 ~/.bashrc 中添加
export OPENCLAW_TELEGRAM_TOKEN="your-bot-token"

在 `openclaw.json` 中引用:
 "token": "${OPENCLAW_TELEGRAM_TOKEN}"

### 2. 限制Bot使用
**方式1:白名单**

只允许特定用户使用:

 "allowedUsers": [123456789, 987654321]

**方式2:群组限制**

只在特定群组中工作:

 "allowedGroups": [-1001234567890]

### 3. 启用隐私模式
推荐启用隐私模式,Bot只能收到命令:

Enabled

## 功能对比
接收所有消息, 个人聊天=, 群组=️ 需关闭隐私模式, 频道=
命令交互, 个人聊天=, 群组=, 频道=
主动推送, 个人聊天=, 群组=, 频道=
群组@提及, 个人聊天=, 群组=, 频道=
流式输出, 个人聊天=, 群组=, 频道=

## 最佳实践

### 1. Bot命名
- 使用描述性名称:`OpenClaw Assistant`, Username以bot结尾:`OpenClawBot`, 避免使用通用名称:`AI Bot`

### 2. Bot描述
写清楚Bot的功能:

OpenClaw AI智能助手

- 代码审查和生成, 资料查询和分析, 创意和规划建议, 数据处理和可视化

 powered by OpenClaw

### 3. 命令设计
- 简单明了:`/help`, `/status`, 一致性:使用前缀, 避免过长:`/getSystemStatusAndInfo`

### 4. 错误处理
配置友好的错误消息:

 "errorMessage": "抱歉,我遇到了问题.请稍后再试.\n\n如需帮助,访问:https://docs.openclaw.ai"

## 参考资料
- [Telegram Bot官方文档](https://core.telegram.org/bots/api), [BotFather命令列表](https://core.telegram.org/bots#botfather), [OpenClaw Telegram集成](https://docs.openclaw.ai/channels/telegram)

## 完成!
现在你的Telegram Bot已经配置完成!

**下一步**:
- 接入其他IM:[飞书](./飞书接入指南.md) | [QQ](./QQ接入指南.md), 学习更多:[快速参考卡](./OpenClaw快速参考卡.md), ️ 安装Skills:[Skills推荐](./Skills推荐列表.md)

**更新时间**: 2026-03-10
**维护者**: Zandar
**难度**: ⭐ 新手友好