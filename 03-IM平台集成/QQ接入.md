# QQ机器人接入指南 - 小龙虾(OpenClaw)
> **难度**: ⭐⭐⭐ 复杂
> **时间**: 45分钟
> **推荐度**: ⭐⭐⭐
> **适合**: 国内用户,功能强大

---

## 前置要求
- OpenClaw已安装, QQ账号(建议使用小号), Node.js 18+, 网络连接

## 两种接入方案

### 方案对比
| **NapCat** | ⭐⭐ | ⭐⭐⭐⭐⭐ | 完整 | ⭐⭐⭐⭐⭐ |
| **go-cqhttp** | ⭐⭐⭐ | ⭐⭐⭐ | 完整 | ⭐⭐⭐ |

**推荐**:新用户使用 **NapCat**(更现代,更稳定)

## 方案A:NapCat(推荐)⭐

### 步骤1:安装NapCat(10分钟)
```bash

# 1. 克隆仓库
git clone https://github.com/NapNeko/NapCatQQ.git
cd NapCatQQ

# 2. 安装依赖
npm install

# 3. 验证
npm start --help
```

### 步骤2:配置NapCat(5分钟)
编辑 `NapCatQQ/config.json`:

```json
{
 "qq": "你的QQ号",
 "password": "你的QQ密码",
 "websocket": {
 "address": "ws://127.0.0.1:3001",
 "enabled": true
 },
 "heartbeat": {
 "interval": 5
 }

**配置说明**:

`qq`, 说明=QQ号, 示例=`123456789`
`password`, 说明=QQ密码, 示例=`"yourpassword"`
`websocket.address`, 说明=WebSocket地址, 示例=`"ws://127.0.0.1:3001"`

# 启动NapCat
npm start

# 会显示二维码链接,使用手机QQ扫码
**登录方式**:
- **扫码登录**(推荐):使用手机QQ扫码
- **账号密码登录**:可能需要滑块验证

# 安装OpenClaw QQ channel
npm install -g @openclaw/channel-qq

### 步骤5:配置OpenClaw(3分钟)
编辑 `~/.openclaw/openclaw.json`:

 "channels": {
 "qq": {
 "enabled": true,
 "type": "napcat",
 "websocketUrl": "ws://127.0.0.1:3001",
 "qq": "你的QQ号"

# 2. 启动Gateway
openclaw gateway start

# 应该会回复

## 方案B:go-cqhttp(经典)

# Linux (AMD64)
wget https://github.com/Mrs4s/go-cqhttp/releases/download/v1.2.0/go-cqhttp_linux_amd64.tar.gz
tar -xzf go-cqhttp_linux_amd64.tar.gz
cd go-cqhttp

# macOS
wget https://github.com/Mrs4s/go-cqhttp/releases/download/v1.2.0/go-cqhttp_darwin_amd64.tar.gz
tar -xzf go-cqhttp_darwin_amd64.tar.gz

### 步骤2:首次运行生成配置(5分钟)
./go-cqhttp

# 按 Ctrl+C 停止

### 步骤3:编辑配置(10分钟)
编辑 `config.yml`:

```yaml
account:
 uin: 你的QQ号
 password: '你的QQ密码'

heartbeat:
 interval: 5

message:
 post-format: string
 ignore-invalid-cqcode: false
 force-fragment: false
 fix-url: false
 proxy-rewrite: ''
 report-self-message: false
 remove-reply-at: false
 extra-reply-data: false
 skip-mime-scan: false

output:
 log-level: warn
 log-aging: 15
 log-force-new: true
 log-colorful: true
 debug: false

default-middlewares: &default
 access-token: ''
 filter: ''
 rate-limit:
 enabled: false
 frequency: 1
 bucket: 1

database:
 leveldb:
 enable: true

servers:
 - http:
 host: 127.0.0.1
 port: 5700
 token: 'your-access-token'

**关键配置**:

`uin`, 说明=QQ号, 推荐值=必填
`password`, 说明=QQ密码, 推荐值=必填
`servers.http.port`, 说明=API端口, 推荐值=`5700`
`servers.http.token`, 说明=访问令牌, 推荐值=随机生成

# 启动
./go-cqhttp -d

# 使用手机QQ扫码登录
- **扫码登录**:推荐,避免风控
- **账号密码**:可能需要滑块验证

# 安装go-cqhttp版channel
npm install -g @openclaw/channel-qq-gocq

### 步骤6:配置OpenClaw(3分钟)
"qq-gocq": {
 "apiUrl": "http://127.0.0.1:5700",
 "token": "your-access-token"

# 3. 在QQ中给机器人发消息测试

## 高级配置

### 1. 配置自动重启
**NapCat**:

# 使用PM2
npm install -g pm2
pm2 start npm --name "napcat" -- start
pm2 save
pm2 startup

**go-cqhttp**:

# 使用systemd
sudo vim /etc/systemd/system/go-cqhttp.service

内容:
```ini
[Unit]
Description=go-cqhttp
After=network.target

[Service]
Type=simple
User=YOUR_USERNAME
WorkingDirectory=/path/to/go-cqhttp
ExecStart=/path/to/go-cqhttp -d
Restart=on-failure

[Install]
WantedBy=multi-user.target

启用:
sudo systemctl enable go-cqhttp
sudo systemctl start go-cqhttp

# 创建多个实例目录
cp -r NapCatQQ NapCatQQ-account2
cd NapCatQQ-account2

# 修改 config.json 中的QQ号
vim config.json

# 复制配置
cp config.yml config-account2.yml

# 修改端口号和QQ号
vim config-account2.yml

# 启动第二个实例
./go-cqhttp -d -c config-account2.yml

### 3. 配置代理
如果需要代理:

 "proxy": "http://127.0.0.1:7890"

 proxy: http://127.0.0.1:7890

## 故障排查

### 问题1:登录失败
**症状**:无法登录,提示错误

**可能原因**:
- QQ号被风控, 网络问题, 密码错误

**解决**:
1. 更换QQ号(建议使用小号)
2. 检查网络连接
3. 使用扫码登录
4. 等待一段时间后重试

### 问题2:无法发送消息
**症状**:收到消息但不回复

**检查**:

# 查看 NapCat 日志
tail -f NapCatQQ/logs/*.log

# 查看日志
tail -f go-cqhttp/logs/*.log

# OpenClaw
tail -f ~/.openclaw/logs/gateway.log | grep qq

- 确认Gateway运行, 检查WebSocket/HTTP连接, 验证配置文件

### 问题3:频繁掉线
**症状**:机器人频繁下线

1. 增加心跳间隔
2. 使用更好的网络
3. 启用自动重连

**NapCat配置**:
 "interval": 3

**go-cqhttp配置**:
 interval: 3

### 问题4:消息收不到
**症状**:群组消息接收不到

**原因**:隐私模式或权限问题

- 检查群组设置, 确认机器人权限, 尝试私聊测试

## 使用场景

### 场景1:个人助手
- 单聊对话, 功能测试, 学习使用

### 场景2:群组机器人
- 添加到QQ群, 群组问答, 自动管理

### 场景3:多账号
- 多个QQ机器人, 不同群组, 功能分工

## 三方案对比
难度, NapCat=⭐⭐, go-cqhttp=⭐⭐⭐, QQ官方=⭐⭐⭐⭐⭐
稳定性, NapCat=⭐⭐⭐⭐⭐, go-cqhttp=⭐⭐⭐, QQ官方=⭐⭐⭐⭐⭐
功能, NapCat=⭐⭐⭐⭐⭐, go-cqhttp=⭐⭐⭐⭐, QQ官方=⭐⭐
维护, NapCat=⭐⭐⭐⭐, go-cqhttp=⭐⭐⭐, QQ官方=⭐⭐⭐⭐⭐
推荐, NapCat=⭐⭐⭐⭐⭐, go-cqhttp=⭐⭐⭐, QQ官方=⭐

## 安全建议

### 1. 使用小号
- 不要使用主账号, 专门注册小号, 不要绑定重要信息

### 2. 定期更换密码
- 每月更换一次, 使用强密码, 不要共享

# 统计使用量
grep "qq" ~/.openclaw/logs/gateway.log | wc -l

## 完成!
你的QQ机器人已经配置完成!

**下一步**:
- 接入其他IM:[Telegram](./Telegram接入指南.md) | [飞书](./飞书接入指南.md)
- [快速参考卡](./OpenClaw快速参考卡.md)

## 参考资料
- [NapCat GitHub](https://github.com/NapNeko/NapCatQQ), [go-cqhttp GitHub](https://github.com/Mrs4s/go-cqhttp), [QQ机器人官方文档](https://bot.q.qq.com)

**更新时间**: 2026-03-10
**维护者**: Zandar
**难度**: ⭐⭐⭐ 需要一定技术基础