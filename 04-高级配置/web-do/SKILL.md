---
name: web-do
description: CDP网页数据提取。连接已有浏览器(9222端口)，提取页面内容，返回纯JSON。只负责数据清洗，不做总结。由OpenClaw/Agent完成后续分析。
---

# Web Do - CDP网页数据提取Skill

## 核心原则

**必须使用 CDP（Chrome DevTools Protocol）**：
- ✅ 连接到已开启 9222 端口的浏览器
- ❌ 不使用 HTTP 直接请求（会被反爬拦截）
- ✅ 保持浏览器 session（登录状态）
- ✅ 支持 JavaScript 渲染

---

## 职责边界

**✅ Python/Node脚本负责**：
- 通过 CDP 连接到浏览器
- 从浏览器获取页面内容（DOM/HTML）
- 提取有用信息，清洗数据
- 输出纯JSON（不总结，不分析）

**❌ 不负责**：
- 不发起 HTTP 请求（绕过反爬）
- 不调用外部 API 做总结
- 不发送消息/通知
- 不做语义分析

**✅ OpenClaw/Agent负责**：
- 接收输出的 JSON
- 进行总结、分析、格式化
- 决定如何使用数据

---

## 为什么必须用 CDP

| 方案 | 反爬绕过 | Session保持 | JS渲染 | Token |
|------|---------|------------|--------|-------|
| HTTP请求 | ❌ 会被拦截 | ❌ | ❌ | 低 |
| Puppeteer | ✅ | ❌ 新浏览器 | ✅ | 高(~50k) |
| **CDP连接** | **✅** | **✅** | **✅** | **低(~500)** |

**CDP 优势**：
- 使用真实浏览器（有你的登录状态）
- 绕过反爬检测（不是 Python requests）
- 支持 JavaScript 渲染页面
- 节省 99% tokens（只给 JSON）

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

4. OpenClaw/Agent分析
   └─ 接收JSON → 总结/格式化
```

---

## 方式1：使用 chrome-devtools MCP Server（推荐）

### 安装 MCP Server

```bash
npm install -g @modelcontextprotocol/server-chrome-devtools
```

### 在 OpenClaw 中使用

```python
# MCP server 自动连接到浏览器
result = mcp_call(
    server='chrome-devtools',
    method='navigate',
    params={'url': 'https://github.com/trending'}
)

# 提取页面内容
data = mcp_call(
    server='chrome-devtools',
    method='evaluate',
    params={'expression': 'document.querySelector("h1").textContent'}
)
```

### MCP 方法列表

| 方法 | 说明 | 示例 |
|------|------|------|
| `navigate` | 打开页面 | `{'url': 'https://example.com'}` |
| `screenshot` | 截图 | `{'path': 'screenshot.png'}` |
| `evaluate` | 执行JS | `{'expression': 'document.title'}` |
| `click` | 点击元素 | `{'selector': 'button.submit'}` |
| `type` | 输入文本 | `{'selector': 'input', 'text': 'hello'}` |

---

## 方式2：使用 Node.js + chrome-remote-interface

### 安装依赖

```bash
npm install chrome-remote-interface
```

### CDP 提取模板

```javascript
// fetch-cdp.js
const CDP = require('chrome-remote-interface');

async function fetchViaCDP(targetUrl) {
    // 1. 列出所有标签页
    const targets = await CDP.List({});

    // 2. 找到目标标签页
    const target = targets.find(t => t.url.includes(targetUrl));

    if (!target) {
        throw new Error('未找到目标标签页，请先在浏览器中打开页面');
    }

    // 3. 连接到标签页
    const { Runtime, Page } = await CDP({ target });

    // 4. 执行 JavaScript 提取数据
    const result = await Runtime.evaluate({
        expression: `
            (function() {
                const items = [];

                // 在这里编写提取逻辑
                document.querySelectorAll('article').forEach((el, index) => {
                    items.push({
                        rank: index + 1,
                        title: el.querySelector('h2')?.textContent.trim(),
                        url: el.querySelector('a')?.href,
                    });
                });

                return items;
            })();
        `,
        returnByValue: true
    });

    // 5. 输出纯JSON
    console.log(JSON.stringify(result.result.value, null, 2));

    await CDP.Close({ id: target.id });
}

// 从命令行获取目标URL
const targetUrl = process.argv[2] || 'github.com';
fetchViaCDP(targetUrl);
```

### 使用步骤

```bash
# 1. 启动浏览器（9222端口）
start msedge.exe --remote-debugging-port=9222 --user-data-dir=D:\temp\chrome-debug

# 2. 在浏览器中打开目标页面（如需要登录，先登录）

# 3. 运行脚本
node fetch-cdp.js github.com
```

---

## 方式3：使用 Python + websocket-client

### 安装依赖

```bash
pip install websocket-client
```

### CDP 提取模板

```python
#!/usr/bin/env python3
import websocket
import json
import subprocess

def get_cdp_tabs():
    """获取所有浏览器标签页"""
    response = subprocess.run(
        ['curl', '-s', 'http://localhost:9222/json'],
        capture_output=True,
        text=True
    )
    return json.loads(response.stdout)

def find_tab(url):
    """找到包含指定URL的标签页"""
    tabs = get_cdp_tabs()
    for tab in tabs:
        if url in tab.get('url', ''):
            return tab
    return None

def send_cdp_command(ws, method, params={}):
    """发送CDP命令"""
    message = {
        'id': 1,
        'method': method,
        'params': params
    }
    ws.send(json.dumps(message))
    result = ws.recv()
    return json.loads(result)

def fetch_via_cdp(target_url):
    """通过CDP获取页面内容"""
    # 1. 找到标签页
    tab = find_tab(target_url)
    if not tab:
        raise Exception(f'未找到包含 {target_url} 的标签页')

    # 2. 连接到CDP WebSocket
    ws_url = tab['webSocketDebuggerUrl']
    ws = websocket.create_connection(ws_url)

    try:
        # 3. 启用Runtime
        send_cdp_command(ws, 'Runtime.enable')

        # 4. 执行JavaScript提取数据
        result = send_cdp_command(ws, 'Runtime.evaluate', {
            'expression': f'''
                (function() {{
                    const items = [];

                    // 在这里编写提取逻辑
                    document.querySelectorAll('article').forEach((el, index) => {{
                        items.push({{
                            rank: index + 1,
                            title: el.querySelector('h2')?.textContent.trim(),
                            url: el.querySelector('a')?.href
                        }});
                    }});

                    return items;
                }})();
            ''',
            'returnByValue': True
        })

        # 5. 返回数据
        data = result['result']['result']['value']
        print(json.dumps(data, ensure_ascii=False, indent=2))

    finally:
        ws.close()

if __name__ == '__main__':
    import sys
    url = sys.argv[1] if len(sys.argv) > 1 else 'github.com'
    fetch_via_cdp(url)
```

---

## 启动浏览器

### Windows

```bash
# Edge
start "" "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --remote-debugging-port=9222 --user-data-dir=D:\temp\chrome-debug

# Chrome
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222 --user-data-dir=C:\temp\chrome-debug
```

### macOS/Linux

```bash
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-debug
```

**重要参数**：
- `--remote-debugging-port=9222` - 启用CDP
- `--user-data-dir=...` - 保持session（不用重复登录）

---

## 常见选择器

| 网站类型 | 选择器示例 |
|---------|-----------|
| GitHub Trending | `article.Box-row` |
| 知乎文章 | `article.Post-Main` |
| 新闻列表 | `div.news-item` |
| 微博 | `div.WB_detail` |
| 商品列表 | `div.product-item` |

---

## 调试技巧

### 1. 查看所有标签页

```bash
curl http://localhost:9222/json
```

### 2. 在浏览器控制台测试选择器

```javascript
// 在浏览器F12控制台执行
document.querySelectorAll('article.Box-row').length
```

### 3. 保存提取结果

```javascript
// 在脚本中保存
const fs = require('fs');
fs.writeFileSync('output.json', JSON.stringify(data, null, 2));
```

---

## 常见问题

**Q: 为什么必须用CDP，不能用HTTP？**
- A: HTTP会被反爬拦截（403/404），CDP使用真实浏览器，绕过反爬

**Q: 如何保持登录状态？**
- A: 使用 `--user-data-dir` 参数，浏览器会保存cookies

**Q: 如何找到目标标签页？**
- A: 先在浏览器中打开页面，然后通过URL匹配找到

**Q: 提取的数据为空？**
- A: 在浏览器控制台测试选择器，确认页面结构

---

## 最佳实践

1. **必须用CDP**：不要用HTTP直接请求
2. **保持session**：使用user-data-dir
3. **纯JSON输出**：不要混入日志
4. **职责清晰**：脚本只提取，Agent负责分析
