Chrome 146原生支持MCP，一个开关，AI 即可以直接控制你当前浏览器会话，无需再装插件、配headless了。

chrome://inspect/[#remote](https://x.com/hashtag/remote?src=hashtag_click)-debugging 

页面在Remote debugging 打开 Allow remote debugging for this browser instance

Server running at: `127.0.0.1:9222`

或者直接打开

chrome://inspect/#remote-debugging



然后

打开 chrome://flags/[#enable](https://x.com/hashtag/enable?src=hashtag_click)-webmcp-testing 设为 Enabled



安装 agent-browser skill 或 chrome-devtools-mcp，都支持自动连接到已有的Chrome实例





### 方案一：用 OpenClaw 内置的 `user` 模式直连 Chrome（推荐）

很多人不知道，OpenClaw 其实已经内置了对 Chrome DevTools MCP 的支持。它有一个叫 `user` 的内置 profile，底层走的就是 Chrome DevTools MCP 的 `--autoConnect` 流程，能直接连上你正在用的 Chrome，带着所有登录状态。

不需要手动配 MCP 服务器，不需要装 Chrome 扩展，开箱就能用。

**第一步：开启 Chrome 远程调试**

在 Chrome 地址栏输入 `chrome://inspect/#remote-debugging`，勾选「Allow remote debugging for this browser instance」：

![](https://api.ibos.cn/v4/weapparticle/accesswximg?aid=135725&url=aHR0cHM6Ly9tbWJpei5xcGljLmNuL3N6X21tYml6X3BuZy9CSHg4d2tpYnJWMkVBSzBPWmljaDBPZ09UVGFNdFRZU2VOSmlhYkVTbjNzcU0yOEtpY0pOTG0zdnZtYTBFMklqUlE4aWFVSkFRODlwUXNDamZHQ0hrTGFKZ1ppYnMyZEtDWTdjVmd5a1JvTFNhMTdiOC82NDA/d3hfZm10PXBuZw==)

**第二步：在 OpenClaw 中启动 user 模式**

终端里依次运行：

```bash
# 启动 user profile（自动通过 Chrome DevTools MCP 连接）
openclaw browser --browser-profile user start
# 检查连接状态
openclaw browser --browser-profile user status
```

这时 Chrome 会弹出授权对话框，问你是否允许远程调试，点「Allow」：

![](https://api.ibos.cn/v4/weapparticle/accesswximg?aid=135725&url=aHR0cHM6Ly9tbWJpei5xcGljLmNuL21tYml6X3BuZy9CSHg4d2tpYnJWMkZ2aDZSNWljTWZHQnZVTk51NjVzZWljZThEMU8wYzR1bXhTWjdzSm9GcEYzMWYyVW5UeVJFU0c1THNuOTJKRDJKeWNHMGZ0TklTb2NvUkdLczJ6OUlGQUh1ZkR6TnEwVnJHYy82NDA/d3hfZm10PXBuZw==)

**第三步：验证连接是否成功**

运行下面的命令，如果能看到你 Chrome 里正在打开的标签页列表，就说明连上了：

```bash
# 列出当前 Chrome 所有标签页
openclaw browser --browser-profile user tabs
# 对当前页面做一次快照
openclaw browser --browser-profile user snapshot --format ai
```

连接成功后 `status` 会显示 `driver: existing-session`、`transport: chrome-mcp`、`running: true`。

**第四步：日常使用**

连上之后，你可以在 OpenClaw 对话中让 AI 用 `profile="user"` 来操控你的真实浏览器。比如让它帮你查看某个已登录网站的数据、填表、做自动化操作，都不需要重新登录。

跟之前的 Extension Relay 模式比，`user` 模式的好处是：

- • 不用装 Chrome 扩展，不用手动点扩展图标 attach
- • 连接走 Chrome DevTools MCP，比 CDP 中继更稳定
- • 不会出现之前 Extension Relay 动不动断连的问题

需要注意的是，这个模式需要你人在电脑前点授权弹窗，适合有人值守的场景。如果你需要无人值守的自动化，还是用隔离的 `openclaw` profile 更合适。



### 方案二：单独配置 Chrome DevTools MCP（适合 Claude Code / Cursor）

如果你不用 OpenClaw，而是用 Claude Code、Cursor 这类编码工具，可以单独配置 Chrome DevTools MCP。

**环境要求：**

- • Node.js v20.19+
- • Chrome 146 稳定版

同样先在 Chrome 里开启远程调试（`chrome://inspect/#remote-debugging`），然后：

Claude Code 用户，终端跑一行：

```bash
claude mcp add chrome-devtools -- npx chrome-devtools-mcp@latest --autoConnect
```

Cursor、Windsurf 等编辑器，在 MCP 配置文件里加：

```json
{
  "mcpServers": {
    "chrome-devtools": {
      "command": "npx",
      "args": ["-y", "chrome-devtools-mcp@latest", "--autoConnect"]
    }
  }
}
```

配好后让 AI 试试「帮我检查 https://developers.chrome.com 的性能」，能返回 LCP、FCP 等指标就说明成功了。

你可以用它做性能检查、控制台报错排查、网络请求分析、模拟用户操作测试、截图审查样式问题这些事。

### 方案三：尝鲜 WebMCP

WebMCP 还在早期预览阶段，但值得试试看未来的方向。

1. 1. 下载 Chrome Canary
2. 2. 地址栏输入 `chrome://flags`，搜「WebMCP for testing」，打开，重启
3. 3. 在 Chrome 应用商店装「Model Context Tool Inspector」扩展
4. 4. 访问 travel-demo.bandarra.me 体验官方 demo

这个 demo 是一个旅行预订网站，通过 WebMCP 向 AI Agent 暴露了搜索航班、预订酒店等工具。你能直观地看到 AI 不再需要「看图找按钮」，而是直接调用网站提供的功能。

---

## 05 几点提醒

**安全问题必须重视。** AI Agent 连上你的浏览器后，能读取所有标签页内容，包括已登录的网站。用的时候把银行、支付相关的页面关掉。OpenClaw 之前已经出过好几起安全事故，这方面不能大意。

**WebMCP 离普及还有段距离。** 目前只在 Chrome Canary 的 flag 里能用，而且得网站开发者主动接入才有意义。但方向很明确，Google 和 Microsoft 一起推，W3C 在走标准化。

**Chrome DevTools MCP 现在就能用。** 不用等 WebMCP 普及，Chrome DevTools MCP 作为补充方案已经很实用了。特别是做 Web 开发的同学，让 AI 帮你查性能、排 bug，体验提升很明显。

---

最后总结几点：

1. 1. OpenClaw 操控浏览器的核心问题在于连接不稳定、Token 消耗大、安全风险高
2. 2. 根本原因是 AI 和浏览器之间缺少标准化的对话方式，只能靠截图猜
3. 3. Chrome 146 的原生 MCP 支持和 WebMCP，分别从连接层和协议层解决了这两个问题
4. 4. OpenClaw 已内置 `user` profile 支持 Chrome DevTools MCP，几行命令就能直连你的 Chrome


