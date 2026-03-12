# Chrome DevTools MCP Server 配置指南

## 安装 MCP Server

```bash
npm install -g @modelcontextprotocol/server-chrome-devtools
```

## 配置 OpenClaw

在 `openclaw.json` 中添加 MCP server 配置：

```json
{
  "mcpServers": {
    "chrome-devtools": {
      "command": "npx",
      "args": [
        "@modelcontextprotocol/server-chrome-devtools"
      ],
      "env": {
        "CHROME_PATH": "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe"
      }
    }
  }
}
```

## 启动浏览器

```bash
# Windows Edge
start msedge.exe --remote-debugging-port=9222 --user-data-dir=D:\temp\chrome-debug
```

## MCP 方法

### navigate - 打开页面

```python
result = mcp_call(
    server='chrome-devtools',
    method='navigate',
    params={
        'url': 'https://github.com/trending'
    }
)
```

### evaluate - 执行JavaScript

```python
result = mcp_call(
    server='chrome-devtools',
    method='evaluate',
    params={
        'expression': 'document.title'
    }
)
```

### screenshot - 截图

```python
result = mcp_call(
    server='chrome-devtools',
    method='screenshot',
    params={
        'path': 'screenshot.png'
    }
)
```

### click - 点击元素

```python
result = mcp_call(
    server='chrome-devtools',
    method='click',
    params={
        'selector': 'button.submit'
    }
)
```

### type - 输入文本

```python
result = mcp_call(
    server='chrome-devtools',
    method='type',
    params={
        'selector': 'input[name="q"]',
        'text': 'GitHub trending'
    }
)
```

## 完整示例

```python
# 在OpenClaw中使用MCP server

# 1. 打开页面
mcp_call(
    server='chrome-devtools',
    method='navigate',
    params={'url': 'https://github.com/trending'}
)

# 2. 等待页面加载
import time
time.sleep(2)

# 3. 提取数据
result = mcp_call(
    server='chrome-devtools',
    method='evaluate',
    params={
        'expression': '''
            (function() {
                const items = [];
                document.querySelectorAll('article.Box-row').forEach((el, index) => {
                    items.push({
                        rank: index + 1,
                        title: el.querySelector('h2')?.textContent.trim()
                    });
                });
                return items;
            })();
        '''
    }
)

# 4. 解析结果
data = json.loads(result['value'])

# 5. 传给Agent分析
sessions_spawn(task=f"分析这些数据：{json.dumps(data)}")
```

## 优势

- ✅ 无需手动管理WebSocket连接
- ✅ 自动处理CDP协议
- ✅ 与OpenClaw深度集成
- ✅ 支持所有CDP功能

## 参考

- MCP文档：https://modelcontextprotocol.io
- chrome-devtools server：https://github.com/modelcontextprotocol/servers/tree/main/src/chrome-devtools
