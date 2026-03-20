# OpenClaw 飞书 (Feishu/Lark) 接入配置指南

> 本文档汇总 OpenClaw 接入飞书时的完整配置说明，包括群聊、私聊可见范围、权限控制等功能配置。

---

## 📋 目录

- [快速开始](#快速开始)
- [飞书应用创建](#飞书应用创建)
- [OpenClaw 配置](#openclaw-配置)
- [群聊配置](#群聊配置)
- [私聊配置](#私聊配置)
- [权限控制](#权限控制)
- [多机器人管理](#多机器人管理)
- [高级配置](#高级配置)
- [故障排查](#故障排查)

---

## 🚀 快速开始

### 方法一：使用向导（推荐）

```bash
openclaw onboard
```

向导会引导你完成：
1. 创建飞书应用并收集凭证
2. 在 OpenClaw 中配置应用凭证
3. 启动 Gateway

### 方法二：CLI 配置

```bash
openclaw channels add
```

选择 **Feishu**，然后输入 App ID 和 App Secret。

---

## 📱 飞书应用创建

### 1. 打开飞书开放平台

访问 [飞书开放平台](https://open.feishu.cn/app) 并登录。

> **注意**：Lark（国际版）租户应使用 [https://open.larksuite.com/app](https://open.larksuite.com/app) 并在配置中设置 `domain: "lark"`。

### 2. 创建企业自建应用

1. 点击 **创建企业自建应用**
2. 填写应用名称 + 描述
3. 选择应用图标

### 3. 复制凭证

从 **凭证与基础信息** 中复制：
- **App ID**（格式：`cli_xxx`）
- **App Secret**

⚠️ **重要**：请妥善保管 App Secret，不要泄露。

### 4. 配置权限

在 **权限管理** 中，点击 **批量导入** 并粘贴：

```json
{
  "scopes": {
    "tenant": [
      "aily:file:read",
      "aily:file:write",
      "application:application.app_message_stats.overview:readonly",
      "application:application:self_manage",
      "application:bot.menu:write",
      "cardkit:card:read",
      "cardkit:card:write",
      "contact:user.employee_id:readonly",
      "corehr:file:download",
      "event:ip_list",
      "im:chat.access_event.bot_p2p_chat:read",
      "im:chat.members:bot_access",
      "im:message",
      "im:message.group_at_msg:readonly",
      "im:message.p2p_msg:readonly",
      "im:message:readonly",
      "im:message:send_as_bot",
      "im:resource"
    ],
    "user": ["aily:file:read", "aily:file:write", "im:chat.access_event.bot_p2p_chat:read"]
  }
}
```

### 5. 启用机器人能力

在 **应用能力** > **机器人** 中：
1. 启用机器人能力
2. 设置机器人名称

### 6. 配置事件订阅

⚠️ **重要**：在设置事件订阅前，请确保：
1. 已经运行 `openclaw channels add` 添加飞书频道
2. Gateway 正在运行（`openclaw gateway status`）

在 **事件订阅** 中：
1. 选择 **使用长连接接收事件**（WebSocket）
2. 添加事件：`im.message.receive_v1`

⚠️ 如果 Gateway 未运行，长连接设置可能无法保存。

### 7. 发布应用

1. 在 **版本管理与发布** 中创建版本
2. 提交审核并发布
3. 等待管理员批准（企业应用通常会自动批准）

---

## ⚙️ OpenClaw 配置

### 使用向导配置（推荐）

```bash
openclaw channels add
```

选择 **Feishu** 并粘贴 App ID + App Secret。

### 通过配置文件配置

编辑 `~/.openclaw/openclaw.json`：

```json5
{
  channels: {
    feishu: {
      enabled: true,
      dmPolicy: "pairing",
      accounts: {
        main: {
          appId: "cli_xxx",
          appSecret: "xxx",
          botName: "我的AI助手",
        },
      },
    },
  },
}
```

### 使用环境变量配置

```bash
export FEISHU_APP_ID="cli_xxx"
export FEISHU_APP_SECRET="xxx"
```

### Lark（国际版）域名配置

如果你的租户使用 Lark（国际版），设置域名为 `lark`（或完整的域名字符串）。可以在 `channels.feishu.domain` 或每个账户级别设置（`channels.feishu.accounts.<id>.domain`）。

```json5
{
  channels: {
    feishu: {
      domain: "lark",
      accounts: {
        main: {
          appId: "cli_xxx",
          appSecret: "xxx",
        },
      },
    },
  },
}
```

---

## 👥 群聊配置

### 群聊策略（groupPolicy）

`channels.feishu.groupPolicy` 控制群聊访问权限：

- `"open"` - 允许所有人在群聊中访问（默认）
- `"allowlist"` - 仅允许 `groupAllowFrom` 中的群
- `"disabled"` - 禁用群聊消息

### @提及要求（requireMention）

`channels.feishu.groups.<chat_id>.requireMention`：
- `true` - 需要 @提及机器人（默认）
- `false` - 无需提及即可响应

### 群聊配置示例

#### 1. 允许所有群聊，要求 @提及（默认）

```json5
{
  channels: {
    feishu: {
      groupPolicy: "open",
      // 默认 requireMention: true
    },
  },
}
```

#### 2. 允许所有群聊，无需 @提及

```json5
{
  channels: {
    feishu: {
      groups: {
        oc_xxx: { requireMention: false },
      },
    },
  },
}
```

#### 3. 仅允许特定群聊

```json5
{
  channels: {
    feishu: {
      groupPolicy: "allowlist",
      // 飞书群 ID (chat_id) 格式：oc_xxx
      groupAllowFrom: ["oc_xxx", "oc_yyy"],
    },
  },
}
```

#### 4. 限制群聊中哪些用户可以发消息（发送者白名单）

除了允许群聊本身，该群聊中的**所有消息**都会受到发送者 open_id 的限制：只有列在 `groups.<chat_id>.allowFrom` 中的用户的消息会被处理；其他成员的消息将被忽略（这是完整的发送者级别限制，不仅限于 /reset 或 /new 等控制命令）。

```json5
{
  channels: {
    feishu: {
      groupPolicy: "allowlist",
      groupAllowFrom: ["oc_xxx"],
      groups: {
        oc_xxx: {
          // 飞书用户 ID (open_id) 格式：ou_xxx
          allowFrom: ["ou_user1", "ou_user2"],
        },
      },
    },
  },
}
```

---

## 💬 私聊配置

### 私聊策略（dmPolicy）

- **默认**：`dmPolicy: "pairing"`（未知用户会收到配对码）
- **allowlist**：仅 `allowFrom` 中的用户可以聊天
- **open**：允许所有用户（需要 `allowFrom` 包含 `"*"`）
- **disabled**：禁用私聊

### 配对审批

使用配对模式时：

```bash
openclaw pairing list feishu
openclaw pairing approve feishu <CODE>
```

### 白名单模式

设置 `channels.feishu.allowFrom` 包含允许的 Open ID：

```json5
{
  channels: {
    feishu: {
      dmPolicy: "allowlist",
      allowFrom: ["ou_user1", "ou_user2"],
    },
  },
}
```

---

## 🔐 权限控制

### 获取群组/用户 ID

#### 群组 ID (chat_id)

群组 ID 格式为 `oc_xxx`。

**方法 1（推荐）**
1. 启动 Gateway 并在群聊中 @提及机器人
2. 运行 `openclaw logs --follow` 并查找 `chat_id`

**方法 2**
使用飞书 API 调试工具列出群聊。

#### 用户 ID (open_id)

用户 ID 格式为 `ou_xxx`。

**方法 1（推荐）**
1. 启动 Gateway 并私信机器人
2. 运行 `openclaw logs --follow` 并查找 `open_id`

**方法 2**
检查配对请求以获取用户 Open ID：

```bash
openclaw pairing list feishu
```

---

## 🤖 多机器人管理

### 多账户配置

```json5
{
  channels: {
    feishu: {
      defaultAccount: "main",
      accounts: {
        main: {
          appId: "cli_xxx",
          appSecret: "xxx",
          botName: "主机器人",
        },
        backup: {
          appId: "cli_yyy",
          appSecret: "yyy",
          botName: "备用机器人",
          enabled: false,
        },
      },
    },
  },
}
```

`defaultAccount` 控制当出站 API 未显式指定 `accountId` 时使用哪个飞书账户。

---

## 🔧 高级配置

### 配额优化标志

可以使用两个可选标志减少飞书 API 使用量：

- `typingIndicator`（默认 `true`）：设为 `false` 时跳过正在输入反应调用。
- `resolveSenderNames`（默认 `true`）：设为 `false` 时跳过发送者资料查找调用。

在顶层或每个账户设置：

```json5
{
  channels: {
    feishu: {
      typingIndicator: false,
      resolveSenderNames: false,
      accounts: {
        main: {
          appId: "cli_xxx",
          appSecret: "xxx",
          typingIndicator: true,
          resolveSenderNames: false,
        },
      },
    },
  },
}
```

### 流式响应

飞书支持通过交互卡片实现流式响应。启用后，机器人在生成文本时会更新卡片。

```json5
{
  channels: {
    feishu: {
      streaming: true, // 启用流式卡片输出（默认 true）
      blockStreaming: true, // 启用块级流式传输（默认 true）
    },
  },
}
```

设置 `streaming: false` 可以等待完整回复后再发送。

### 消息限制

- `textChunkLimit`：出站文本分块大小（默认：2000 字符）
- `mediaMaxMb`：媒体上传/下载限制（默认：30MB）

---

## 🧪 启动和测试

### 1. 启动 Gateway

```bash
openclaw gateway
```

### 2. 发送测试消息

在飞书中找到你的机器人并发送消息。

### 3. 批准配对

默认情况下，机器人会回复一个配对码。批准它：

```bash
openclaw pairing approve feishu <CODE>
```

批准后，你可以正常聊天。

---

## 🛠️ 故障排查

### 机器人在群聊中不响应

1. 确保机器人已添加到群聊
2. 确保你 @提及了机器人（默认行为）
3. 检查 `groupPolicy` 未设置为 `"disabled"`
4. 检查日志：`openclaw logs --follow`

### 机器人接收不到消息

1. 确保应用已发布并批准
2. 确保事件订阅包含 `im.message.receive_v1`
3. 确保启用了**长连接**
4. 确保应用权限完整
5. 确保 Gateway 正在运行：`openclaw gateway status`
6. 检查日志：`openclaw logs --follow`

### App Secret 泄露

1. 在飞书开放平台重置 App Secret
2. 更新配置中的 App Secret
3. 重启 Gateway

### 消息发送失败

1. 确保应用具有 `im:message:send_as_bot` 权限
2. 确保应用已发布
3. 检查日志获取详细错误信息

---

## 📚 参考命令

### Gateway 管理命令

| 命令 | 描述 |
|------|------|
| `openclaw gateway status` | 显示 Gateway 状态 |
| `openclaw gateway install` | 安装/启动 Gateway 服务 |
| `openclaw gateway stop` | 停止 Gateway 服务 |
| `openclaw gateway restart` | 重启 Gateway 服务 |
| `openclaw logs --follow` | 跟踪 Gateway 日志 |

### 常用机器人命令

| 命令 | 描述 |
|------|------|
| `/status` | 显示机器人状态 |
| `/reset` | 重置会话 |
| `/model` | 显示/切换模型 |

> 注意：飞书尚不支持原生命令菜单，因此命令必须作为文本发送。

---

## 📖 完整配置参考

完整配置：[Gateway 配置](https://docs.openclaw.ai/gateway/configuration)

### 关键配置选项

| 设置 | 描述 | 默认值 |
|------|------|--------|
| `channels.feishu.enabled` | 启用/禁用频道 | `true` |
| `channels.feishu.domain` | API 域名（`feishu` 或 `lark`） | `feishu` |
| `channels.feishu.connectionMode` | 事件传输模式 | `websocket` |
| `channels.feishu.defaultAccount` | 出站路由的默认账户 ID | `default` |
| `channels.feishu.accounts.<id>.appId` | App ID | - |
| `channels.feishu.accounts.<id>.appSecret` | App Secret | - |
| `channels.feishu.dmPolicy` | 私聊策略 | `pairing` |
| `channels.feishu.allowFrom` | 私聊白名单（open_id 列表） | - |
| `channels.feishu.groupPolicy` | 群聊策略 | `open` |
| `channels.feishu.groupAllowFrom` | 群聊白名单 | - |
| `channels.feishu.groups.<chat_id>.requireMention` | 要求 @提及 | `true` |
| `channels.feishu.groups.<chat_id>.enabled` | 启用群聊 | `true` |
| `channels.feishu.textChunkLimit` | 消息分块大小 | `2000` |
| `channels.feishu.mediaMaxMb` | 媒体大小限制 | `30` |
| `channels.feishu.streaming` | 启用流式卡片输出 | `true` |
| `channels.feishu.blockStreaming` | 启用块级流式传输 | `true` |

---

## 🔗 相关资源

- [OpenClaw 官方文档](https://docs.openclaw.ai)
- [飞书开放平台](https://open.feishu.cn/app)
- [Lark 开放平台](https://open.larksuite.com/app)
- [Feishu Channel 文档](https://docs.openclaw.ai/channels/feishu)

---

**最后更新**：2026-03-17
**文档版本**：1.0
