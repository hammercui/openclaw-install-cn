# Web-Do Skill 更新日志

## 2026-03-12 - 重大更新：强制使用CDP

### 核心变更

**强制使用 CDP（Chrome DevTools Protocol）**：
- ❌ 去掉所有HTTP直接请求方式
- ✅ 必须通过CDP连接到浏览器（9222端口）
- ✅ 支持chrome-devtools MCP server
- ✅ 保持浏览器session（登录状态）

### 变更原因

**为什么必须用CDP**：
1. **反爬绕过**：HTTP请求会被403/404拦截
2. **Session保持**：使用真实浏览器的登录状态
3. **JS渲染**：支持JavaScript动态内容
4. **Token优化**：只返回JSON，节省99%

### 文件变更

**删除文件**：
- `test.py` - 旧版测试脚本（HTTP方式）
- `examples/fetch-github-trending.py` - HTTP版本示例

**新增文件**：
- `MCP-GUIDE.md` - chrome-devtools MCP server配置指南
- `test-cdp.py` - CDP连接测试脚本
- `examples/fetch-github-trending-cdp.py` - Python CDP示例

**完全重写**：
- `SKILL.md` - 强调CDP优先，去掉HTTP方式
- `README.md` - 突出CDP优势
- `QUICKSTART.md` - 更新为CDP快速上手

---

## 使用对比

### 旧版本（HTTP方式）

```python
# ❌ 会被反爬拦截
response = requests.get('https://github.com/trending')
# 403 Forbidden
```

### 新版本（CDP方式）

```javascript
// ✅ 使用真实浏览器
const data = await Runtime.evaluate({
    expression: 'document.querySelectorAll("article")'
});
// 成功获取数据
```

---

## 三种使用方式

### 方式1：Node.js + chrome-remote-interface

```bash
node examples/fetch-cdp.js github.com
```

### 方式2：Python + websocket-client

```bash
python examples/fetch-github-trending-cdp.py
```

### 方式3：chrome-devtools MCP Server（推荐）

```python
mcp_call(
    server='chrome-devtools',
    method='navigate',
    params={'url': 'https://github.com/trending'}
)
```

---

## 测试验证

运行新的测试脚本：
```bash
python test-cdp.py
```

测试内容：
1. ✅ 浏览器CDP连接（9222端口）
2. ✅ GitHub Trending标签页检测
3. ✅ 数据提取功能
4. ✅ 纯JSON输出验证

---

## 迁移指南

如果你在使用旧版本：

1. **启动浏览器**（必须）
   ```bash
   start msedge.exe --remote-debugging-port=9222 --user-data-dir=D:\temp\chrome-debug
   ```

2. **在浏览器中打开目标页面**
   ```
   https://github.com/trending
   ```

3. **使用新的CDP脚本**
   ```bash
   # Node.js版本
   node examples/fetch-cdp.js github.com

   # Python版本
   python examples/fetch-github-trending-cdp.py
   ```

4. **移除HTTP调用**
   - 删除所有 `requests.get()` 调用
   - 改用CDP `Runtime.evaluate`

---

## 核心优势

| 特性 | HTTP方式 | CDP方式 |
|------|---------|---------|
| 反爬绕过 | ❌ | ✅ |
| Session保持 | ❌ | ✅ |
| JS渲染 | ❌ | ✅ |
| Token占用 | 低 | 低(~500) |
| 成功率 | 低（易被拦截） | 高（使用真实浏览器） |

---

## 依赖要求

### Node.js版本
```bash
npm install chrome-remote-interface
```

### Python版本
```bash
pip install websocket-client
```

### MCP Server
```bash
npm install -g @modelcontextprotocol/server-chrome-devtools
```

---

## 最佳实践

1. **必须用CDP**：不要尝试HTTP请求
2. **保持session**：使用 `--user-data-dir`
3. **先打开页面**：在浏览器中打开目标页面
4. **纯JSON输出**：脚本只提取，Agent负责分析

---

## 未来计划

- [ ] 添加自动重连机制
- [ ] 支持多标签页并发提取
- [ ] 添加更多MCP方法封装
- [ ] 支持WebSocket连接池
