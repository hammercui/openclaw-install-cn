# Web Do - CDP网页数据提取

**重要**: 不会关闭浏览器标签页，提取后标签页保持打开状态

---

## 核心原则

**必须使用 CDP（Chrome DevTools Protocol）**：
- ✅ 连接到已开启 9222 端口的浏览器
- ❌ 不使用 HTTP 直接请求（会被反爬拦截）
- ✅ 保持浏览器 session（登录状态）
- ✅ 支持 JavaScript 渲染
- ✅ **不会关闭浏览器标签页**

---

## 工作流程

```
1. 启动浏览器（9222端口）
   └─ msedge.exe --remote-debugging-port=9222

2. 在浏览器中打开目标页面
   └─ 保持登录状态（如需要）

3. CDP脚本提取数据
   ├─ 连接到 localhost:9222
   ├─ 找到目标标签页
   ├─ 执行 JavaScript 提取内容
   └─ 输出纯JSON
   └─ **标签页保持打开** ⚠️

4. OpenClaw/Agent分析
   └─ 接收JSON → 总结/格式化
```

---

## 使用说明

### 方式1：Node.js + chrome-remote-interface

```bash
node fetch-cdp.js github.com
```

**特点**：
- 连接到浏览器
- 提取数据
- **不关闭标签页**
- CDP连接自动释放

### 方式2：Python + websocket-client

```bash
python fetch-github-trending-cdp.py
```

**特点**：
- 通过WebSocket连接
- 提取数据
- **不关闭标签页**
- WebSocket自动断开

---

## 常见问题

**Q: 会关闭我的浏览器标签页吗？**
- A: **不会**。所有脚本都只是关闭CDP/WebSocket连接，不会关闭浏览器标签页

**Q: 需要重新打开页面吗？**
- A: 不需要。页面保持打开，可以重复提取

**Q: CDP连接会一直占用吗？**
- A: 不会。脚本执行完毕后CDP连接会自动释放

---

## 选择器参考

| 网站类型 | 选择器示例 |
|---------|-----------|
| GitHub Trending | `article.Box-row` |
| X/Twitter | `[data-testid="tweet"]` |
| 知乎文章 | `article.Post-Main` |
| 新闻列表 | `div.news-item` |

---

## 安全说明

- ⚠️ CDP端口9222无认证，仅供本地使用
- ⚠️ 不要在公共网络暴露9222端口
- ✅ 所有脚本只读取数据，不修改页面
