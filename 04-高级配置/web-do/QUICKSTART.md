# Web-Do Skill 快速上手

**重要**：必须使用 CDP 连接到浏览器（9222端口）

---

## 5分钟快速开始

### 步骤1：启动浏览器

```bash
# Windows Edge
start msedge.exe --remote-debugging-port=9222 --user-data-dir=D:\temp\chrome-debug

# Windows Chrome
start chrome.exe --remote-debugging-port=9222 --user-data-dir=C:\temp\chrome-debug
```

**重要参数**：
- `--remote-debugging-port=9222` - 启用CDP
- `--user-data-dir=...` - 保持session（不用重复登录）

### 步骤2：在浏览器中打开目标页面

```
https://github.com/trending
```

### 步骤3：运行提取脚本

**Node.js版本**：
```bash
cd examples
node fetch-cdp.js github.com
```

**Python版本**：
```bash
cd examples
python fetch-github-trending-cdp.py
```

### 步骤4：获取JSON数据

输出示例：
```json
[
  {
    "rank": 1,
    "name": "owner/repo",
    "url": "https://github.com/owner/repo",
    "description": "项目描述",
    "language": "TypeScript",
    "stars": "1.2k"
  }
]
```

---

## 三种使用方式

### 方式1：Node.js + chrome-remote-interface

```bash
# 安装依赖
npm install chrome-remote-interface

# 运行示例
node fetch-cdp.js github.com
```

**优势**：
- 简单直接
- 无需额外配置
- 适合快速脚本

### 方式2：Python + websocket-client

```bash
# 安装依赖
pip install websocket-client

# 运行示例
python fetch-github-trending-cdp.py
```

**优势**：
- Python生态丰富
- 适合数据处理
- 易于集成

### 方式3：chrome-devtools MCP Server（推荐）

```bash
# 安装MCP server
npm install -g @modelcontextprotocol/server-chrome-devtools

# 在OpenClaw中使用
mcp_call(server='chrome-devtools', method='navigate', params={'url': '...'})
```

**优势**：
- 与OpenClaw深度集成
- 自动处理CDP协议
- 支持所有浏览器操作

详见 `MCP-GUIDE.md`

---

## 常见场景

### 场景1：GitHub Trending监控

```python
# 运行脚本
data = exec('python examples/fetch-github-trending-cdp.py')

# 发送到Telegram
message(
    action='send',
    channel='telegram',
    message=f"今日GitHub Trending:\n{data.stdout}"
)
```

### 场景2：需要登录的页面

```bash
# 1. 启动浏览器（带session）
start msedge.exe --remote-debugging-port=9222 --user-data-dir=D:\temp\chrome-debug

# 2. 在浏览器中手动登录

# 3. 运行脚本（CDP会保持登录状态）
node fetch-cdp.js example.com
```

### 场景3：JavaScript渲染的页面

```javascript
// CDP自动处理JavaScript渲染
const data = await Runtime.evaluate({
    expression: 'document.querySelector(".dynamic-content").textContent'
});
```

---

## 故障排查

### 问题1：无法连接到浏览器

```bash
# 检查端口
curl http://localhost:9222/json

# 应该返回标签页列表
[{"id": "...", "url": "https://...", ...}]
```

如果返回空数组：
```bash
# 浏览器没有启动，重新启动
start msedge.exe --remote-debugging-port=9222 --user-data-dir=D:\temp\chrome-debug
```

### 问题2：未找到目标标签页

```
错误：未找到包含 github.com 的标签页
```

**解决**：在浏览器中打开目标页面

### 问题3：提取数据为空

```javascript
// 在浏览器控制台测试选择器
// 按F12打开开发者工具，在Console中执行
document.querySelectorAll('article.Box-row').length

// 如果返回0，说明选择器错误或页面结构变化
```

### 问题4：Python脚本报错

```
ModuleNotFoundError: No module named 'websocket'
```

**解决**：
```bash
pip install websocket-client
```

---

## 选择器参考

在浏览器控制台测试这些选择器：

```javascript
// GitHub Trending
document.querySelectorAll('article.Box-row')

// 知乎文章
document.querySelectorAll('article.Post-Main')

// 新闻列表
document.querySelectorAll('div.news-item')

// 微博
document.querySelectorAll('div.WB_detail')

// 商品列表
document.querySelectorAll('div.product-item')
```

---

## 下一步

1. 阅读 `SKILL.md` - 完整使用指南
2. 阅读 `MCP-GUIDE.md` - MCP server配置
3. 查看 `examples/` - 示例脚本
4. 修改脚本选择器 - 适配你的目标网站

---

## 核心原则

记住这三点：

1. **必须用CDP**：不要用HTTP请求（会被反爬拦截）
2. **保持session**：使用 `--user-data-dir`
3. **纯JSON输出**：脚本只提取，Agent负责分析
