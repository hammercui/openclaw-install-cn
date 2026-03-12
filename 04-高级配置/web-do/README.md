# Web Do - CDP网页数据提取

**必须使用 CDP（Chrome DevTools Protocol）**连接到浏览器（9222端口）

---

## 核心优势

| 方案 | 反爬绕过 | Session | JS渲染 | Token |
|------|---------|---------|--------|-------|
| HTTP请求 | ❌ | ❌ | ❌ | 低 |
| Puppeteer | ✅ | ❌ | ✅ | 高(~50k) |
| **CDP连接** | **✅** | **✅** | **✅** | **低(~500)** |

---

## 快速开始

### 1. 启动浏览器

```bash
# Windows Edge
start msedge.exe --remote-debugging-port=9222 --user-data-dir=D:\temp\chrome-debug

# Windows Chrome
start chrome.exe --remote-debugging-port=9222 --user-data-dir=C:\temp\chrome-debug
```

### 2. 在浏览器中打开目标页面

```
https://github.com/trending
```

### 3. 运行提取脚本

**Node.js版本**：
```bash
node fetch-cdp.js github.com
```

**Python版本**：
```bash
python fetch-github-trending-cdp.py
```

### 4. 获取纯JSON输出

```json
[
  {
    "rank": 1,
    "name": "owner/repo",
    "url": "https://github.com/owner/repo",
    "description": "...",
    "language": "TypeScript",
    "stars": "1.2k"
  }
]
```

---

## 为什么必须用CDP

### ❌ HTTP请求的问题

```python
# 会被反爬拦截
response = requests.get('https://github.com/trending')
# 403 Forbidden
```

### ✅ CDP的优势

```javascript
// 使用真实浏览器，绕过反爬
const data = await Runtime.evaluate({
    expression: 'document.querySelectorAll("article")'
});
// 成功获取数据
```

**核心原因**：
- 使用真实浏览器（有你的登录状态）
- 绕过反爬检测（不是Python requests）
- 支持JavaScript渲染页面
- 节省99% tokens（只给JSON）

---

## 文件说明

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 完整使用指南（必须阅读） |
| `examples/fetch-cdp.js` | Node.js CDP模板 |
| `examples/fetch-github-trending-cdp.py` | Python CDP示例 |

---

## 使用方式

### 方式1：Node.js + chrome-remote-interface（推荐）

```bash
# 安装依赖
npm install chrome-remote-interface

# 运行脚本
node fetch-cdp.js github.com
```

### 方式2：Python + websocket-client

```bash
# 安装依赖
pip install websocket-client

# 运行脚本
python fetch-github-trending-cdp.py
```

### 方式3：chrome-devtools MCP Server

```bash
# 安装MCP server
npm install -g @modelcontextprotocol/server-chrome-devtools

# 在OpenClaw中使用
mcp_call(server='chrome-devtools', method='navigate', ...)
```

---

## 故障排查

**问题：无法连接到浏览器**
```bash
# 检查端口
curl http://localhost:9222/json

# 重启浏览器
taskkill /f /im msedge.exe
start msedge.exe --remote-debugging-port=9222 --user-data-dir=D:\temp\chrome-debug
```

**问题：未找到目标标签页**
```
请先在浏览器中打开目标页面
```

**问题：提取数据为空**
```javascript
// 在浏览器控制台测试选择器
document.querySelectorAll('article.Box-row')
```

---

## 更多信息

详见 `SKILL.md`
