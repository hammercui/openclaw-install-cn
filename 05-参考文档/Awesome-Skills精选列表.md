# Awesome OpenClaw Skills - 精选技能列表

> 从官方 OpenClaw Skills Registry 精选的 **5,400+** 技能集合，按类别整理。

**GitHub**: [VoltAgent/awesome-openclaw-skills](https://github.com/VoltAgent/awesome-openclaw-skills)

---

## 📊 概览

### 规模统计

| 指标 | 数量 |
|------|------|
| **官方注册技能总数** | 13,729 |
| **精选技能数量** | 5,366 |
| **过滤排除** | 7,060 |

### 过滤标准

以下类型的技能**未被**收录：
- ❌ 垃圾/测试内容 (4,065)
- ❌ 重复或相似名称 (1,040)
- ❌ 低质量或非英语描述 (851)
- ❌ 加密货币/区块链/金融交易 (731)
- ❌ 恶意代码 (373)

---

## 📦 技能分类

### 🏆 主要分类（按数量）

| 分类 | 技能数 |
|------|--------|
| **[Coding Agents & IDEs](#coding-agents--ides)** | 1,222 |
| **[Web & Frontend Development](#web--frontend-development)** | 938 |
| **[DevOps & Cloud](#devops--cloud)** | 409 |
| **[Browser & Automation](#browser--automation)** | 335 |
| **[Search & Research](#search--research)** | 352 |
| **[Git & GitHub](#git--github)** | 170 |
| **[Marketing & Sales](#marketing--sales)** | 105 |
| **[Communication](#communication)** | 149 |
| **[Productivity & Tasks](#productivity--tasks)** | 206 |
| **[AI & LLMs](#ai--llms)** | 197 |

### 📱 其他分类

- **Speech & Transcription** (45)
- **Smart Home & IoT** (43)
- **Image & Video Generation** (169)
- **Media & Streaming** (85)
- **PDF & Documents** (111)
- **Apple Apps & Services** (44)
- **Notes & PKM** (71)
- **Calendar & Scheduling** (65)
- **Security & Passwords** (54)
- **Shopping & E-commerce** (55)
- **Health & Fitness** (88)
- **Gaming** (36)
- **Transportation** (109)
- **CLI Utilities** (186)

---

## 🚀 如何安装技能

### 方法1: 使用 ClawHub

```bash
clawhub install <skill-slug>
```

**示例**:
```bash
# 安装 slack 集成
clawhub install steipete/slack
```

### 方法2: 手动安装

将技能文件夹复制到以下位置之一：

| 位置 | 路径 |
|------|------|
| **全局** | `~/.openclaw/skills/` |
| **工作区** | `<project>/skills/` |

**优先级**: 工作区 > 本地 > 内置

### 方法3: 直接链接安装

在聊天中直接粘贴 GitHub 链接，OpenClaw 会自动处理安装。

**示例**:
```
请帮我安装这个技能：https://github.com/openclaw/skills/tree/main/skills/steipete/slack
```

---

## 🔐 安全建议

### ⚠️ 重要提示

技能列表是**精选的，但未经过审核**。它们可能在被添加后由原始维护者更新、修改或替换。

### ✅ 安装前检查

1. **审查源代码** - 在安装前检查技能的源代码
2. **查看 VirusTotal 报告** - 在 ClawHub 上查看技能的安全扫描报告
3. **使用安全扫描工具**:
   - [Snyk Skill Security Scanner](https://github.com/snyk/agent-scan)
   - [Agent Trust Hub](https://ai.gendigital.com/agent-trust-hub)

### 🛡️ 风险类型

Agent 技能可能包含：
- Prompt 注入
- 工具污染
- 隐藏的恶意负载
- 不安全的数据处理模式

**使用技能时请自行判断风险！**

---

## 💡 推荐技能

### Coding Agents & IDEs (1,222)

- **[agent-commons](https://github.com/openclaw/skills/tree/main/skills/zanblayde/agent-commons)** - 咨询、提交、扩展和挑战推理链
- **[agent-team-orchestration](https://github.com/openclaw/skills/tree/main/skills/arminnaimi/agent-team-orchestration)** - 编排多代理团队，定义角色、任务生命周期、交接协议和工作流
- **[auto-pr-merger](https://github.com/openclaw/skills/tree/main/skills/autogame-17/auto-pr-merger)** - 自动化 GitHub PR 工作流

### Browser & Automation (335)

- **[airadar](https://github.com/openclaw/skills/tree/main/skills/lopushok9/airadar)** - 追踪 AI 原生工具/应用及其 GitHub 仓库的信号
- **[arc-agent-lifecycle](https://github.com/openclaw/skills/tree/main/skills/trypto1019/arc-agent-lifecycle)** - 管理自主代理的生命周期

### Security & Auditing

- **[arc-security-audit](https://github.com/openclaw/skills/tree/main/skills/trypto1019/arc-security-audit)** - 全面安全审计代理的技能栈
- **[azhua-skill-vetter](https://github.com/openclaw/skills/tree/main/skills/fatfingererr/azhua-skill-vetter)** - 安全优先的技能审查
- **[arc-trust-verifier](https://github.com/openclaw/skills/tree/main/skills/trypto1019/arc-trust-verifier)** - 验证技能来源并建立信任评分

---

## 🔗 相关资源

### 官方资源

- **[OpenClaw 官方文档](https://docs.openclaw.ai)**
- **[ClawHub - OpenClaw Skills Registry](https://clawhub.ai)**
- **[OpenClaw GitHub](https://github.com/openclaw/openclaw)**

### 社区资源

- **[Awesome OpenClaw Skills](https://github.com/VoltAgent/awesome-openclaw-skills)** - 本列表的 GitHub 仓库
- **[Discord 社区](https://s.voltagent.dev/discord)** - 加入讨论

### 集成服务

- **[Composio](https://composio.dev/claw)** - 管理 OAuth、权限和 API 认证（支持 1000+ 应用）

---

## 📈 项目影响力

- **📊 +1M 月浏览量** - 官方资源外访问量第一的社区资源
- **📅 最后更新** - 2026-02-28
- **👨‍💻 维护者** - [VoltAgent](https://github.com/VoltAgent)

---

## 🤝 贡献指南

### 提交技能

1. 确保技能已发布在 `github.com/openclaw/skills` 仓库
2. 提供 ClawHub 链接和 GitHub 链接
3. 提交 Pull Request

**不接受**:
- ❌ 个人仓库链接
- ❌ Gist 链接
- ❌ 任何外部来源

详细指南请查看 [CONTRIBUTING.md](https://github.com/VoltAgent/awesome-openclaw-skills/blob/main/CONTRIBUTING.md)

---

## 📮 反馈与问题

如果发现列表中的技能有问题或安全隐患，请：
1. [提交 Issue](https://github.com/VoltAgent/awesome-openclaw-skills/issues)
2. 描述具体问题
3. 提供证据（如适用）

---

**祝你在 OpenClaw 生态中探索愉快！** 🦞

---

> **注意**: 本文档总结了 [VoltAgent/awesome-openclaw-skills](https://github.com/VoltAgent/awesome-openclaw-skills) GitHub 仓库的内容。
>
> 更新时间: 2026-03-14
> 数据来源: GitHub (推文 ID: 2032395291731898562)
