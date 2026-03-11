# oh-my-opencode Agent 模型分配设计方案

> 版本：v1.0  
> 日期：2026-03-11  
> 约束：仅使用 anthropic / openai / zhipuai-coding-plan / github-copilot（优先级从高到低）

---

## 一、供应商优先级原则

| 优先级 | Provider | 定位 | 说明 |
|--------|----------|------|------|
| ① 最优先 | `anthropic/` | 直连官方 API | 工具调用最强、代码能力顶尖、Claude 系列首选 |
| ② 其次 | `openai/` | 直连官方 API | Codex 系列专为代码优化，适合纯代码生成任务 |
| ③ 兜底便宜 | `zhipuai-coding-plan/` | 按量计费，价格极低 | 适合轻量、高频、低要求任务 |
| ④ 最后兜底 | `github-copilot/` | 订阅制 | 仅在以上三个 Provider 均不合适时使用 |

---

## 二、可用模型速查

### Anthropic（首选）
| 模型 | 定位 | 适用场景 |
|------|------|----------|
| `anthropic/claude-opus-4-6` | 顶级，最强推理 | 架构决策、深度分析、规划、调试 |
| `anthropic/claude-sonnet-4-6` | 均衡，编码最强 | 主 Agent、代码实现、任务分析 |
| `anthropic/claude-haiku-4-5` | 快速，成本低 | 搜索、探索、轻量任务 |

### OpenAI（代码专项）
| 模型 | 定位 | 适用场景 |
|------|------|----------|
| `openai/gpt-5.4` | 最新旗舰，通用 ★ | **重型代码生成**（hephaestus）、高难度推理、创意任务 |
| `openai/gpt-5.3-codex` | 代码专用，最新 | 重型代码生成 |
| `openai/gpt-5.2` | 均衡通用 | 中等难度分析 |
| `openai/gpt-5.1-codex-max` | 代码专用，高配 | 代码生成备选 |
| `openai/codex-mini-latest` | 代码专用，轻量 | 轻量代码任务 |

### ZhipuAI（廉价兜底）
| 模型 | 定位 | 适用场景 |
|------|------|----------|
| `zhipuai-coding-plan/glm-5` | 最新，能力最强 | ZhipuAI 中最强 |
| `zhipuai-coding-plan/glm-4.7` | 稳定中配 | 轻量任务 |
| `zhipuai-coding-plan/glm-4.5-air` | 最便宜 | 超轻量任务 |
| `zhipuai-coding-plan/glm-4.5-flash` | 最快 | 极速响应 |

---

## 三、Agent 模型设计

### 🧭 sisyphus — 主调度 Agent

| 项目 | 内容 |
|------|------|
| **功能** | 系统主 Agent（即当前对话的 AI），负责理解用户意图、编写/修改代码、调用工具、分派 subagent、管理 todo 进度、最终交付结果 |
| **特点** | 使用频率最高，需要极强的工具调用能力、代码理解与生成能力、长上下文处理能力 |
| **推荐模型** | `anthropic/claude-sonnet-4-6` |
| **候选模型** | `anthropic/claude-opus-4-6`（追求最高质量时）、`github-copilot/claude-sonnet-4.6`（节省直连费用时） |
| **选型理由** | Sonnet 4.6 是编码+工具调用综合能力最强的"工作马"，Opus 虽更聪明但成本是 Sonnet 的 1.7x，且主 Agent 持续运行，成本敏感；当前实际运行模型已是此选项 |

---

### 🔨 hephaestus — 代码实施 subagent

| 项目 | 内容 |
|------|------|
| **功能** | 重型代码生成 subagent，被 sisyphus 委派去执行实际文件编写、重构、测试编写等代码密集型任务 |
| **特点** | 纯代码输出，不需要复杂推理，需要高质量、低错误率的代码生成 |
| **推荐模型** | `openai/gpt-5.4` |
| **候选模型** | `openai/gpt-5.3-codex`（代码专用备选）、`anthropic/claude-sonnet-4-6`（Claude 备选） |
| **选型理由** | gpt-5.4 是 OpenAI 当前旗舰，AIME 2025 满分（100%），数学/算法推理极强，代码生成质量全面超越 codex 专用版；OpenAI 额度充足时优先用最强版本 |

---

### 🔮 oracle — 高智商只读顾问

| 项目 | 内容 |
|------|------|
| **功能** | 昂贵但精准的只读咨询顾问。只在：架构决策、2次以上 fix 失败、安全/性能分析、复杂 debug 时被调用。只读，不修改任何文件 |
| **特点** | 调用频率极低，但每次调用都是关键节点，需要全系最强推理能力 |
| **推荐模型** | `anthropic/claude-opus-4-6` |
| **候选模型** | `openai/gpt-5.4`（GPT 系列最强）、`github-copilot/claude-opus-4.6`（订阅制节省费用） |
| **选型理由** | Oracle 应该是全系最强推理模型——Claude Opus 4.6 是 SWE-Bench 最高分（80.8%），Agent 规划和深度分析领先；低频高值，成本完全可接受 |

---

### 📚 librarian — 外部参考检索 Agent

| 项目 | 内容 |
|------|------|
| **功能** | 搜索外部资源：官方文档、npm/pypi 包用法、GitHub 开源示例、最佳实践、库的 quirks。通过 Web Search、Context7、WebFetch 等 MCP 工具完成 |
| **特点** | 高频调用（每遇到陌生库就触发），任务难度中等，关键是工具调用可靠性和速度 |
| **推荐模型** | `anthropic/claude-haiku-4-5` |
| **候选模型** | `openai/gpt-5.2`（更强的综合理解）、`zhipuai-coding-plan/glm-4.7`（极省成本） |
| **选型理由** | Haiku 工具调用能力足够、速度快、成本低；librarian 高频运行，用 Sonnet 级别成本会显著累积；如果遇到需要深度合成多源文档的场景，升级为 gpt-5.2 |

---

### 🔍 explore — 代码库内部搜索 Agent

| 项目 | 内容 |
|------|------|
| **功能** | 快速搜索当前代码库，找 patterns、实现位置、模块关系、命名规范。通过 Grep、Glob、Read、AST 等工具完成，不修改任何内容 |
| **特点** | 高频并行运行，只需 grep/read 能力，追求极速和极低成本 |
| **推荐模型** | `anthropic/claude-haiku-4-5` |
| **候选模型** | `zhipuai-coding-plan/glm-4.5-flash`（更便宜的极速选项）、`github-copilot/claude-haiku-4.5`（Copilot 订阅省直连费用） |
| **选型理由** | Haiku 已是完美的"搜索工具"——速度快、理解代码能力足够、成本最低；explore 常以 background 模式并行运行，Haiku 的低延迟是关键优势 |

---

### 🖼️ multimodal-looker — 多模态视觉分析 Agent

| 项目 | 内容 |
|------|------|
| **功能** | 分析图片、截图、PDF、设计稿等视觉内容，提取关键信息或描述内容 |
| **特点** | 需要视觉理解能力（Vision），任务频率较低 |
| **推荐模型** | `anthropic/claude-sonnet-4-6` |
| **候选模型** | `anthropic/claude-haiku-4-5`（简单图片描述）、`anthropic/claude-opus-4-6`（复杂视觉推理） |
| **选型理由** | Claude Sonnet 4.6 原生支持视觉输入，图片理解质量优于 Haiku；不再使用 Google Gemini 后，Claude 是视觉任务最合适的替代 |

---

### 📐 prometheus — 战略规划 Agent

| 项目 | 内容 |
|------|------|
| **功能** | 根据用户需求生成详细的项目执行计划（/start-work 触发），将复杂需求分解为可执行步骤，产出 Plan 文档 |
| **特点** | 调用频率低（每个大项目一次），需要最强的全局理解和推理能力，一次规划好比多次修正更经济 |
| **推荐模型** | `anthropic/claude-opus-4-6` |
| **候选模型** | `openai/gpt-5.4`（GPT 系规划能力强）、`github-copilot/claude-opus-4.6`（订阅节省费用） |
| **选型理由** | 规划是高价值低频操作，Opus 的深度推理能力让规划更全面、减少后续返工；一次规划成本远低于多次迭代修正 |

---

### 🎯 metis — 需求前置分析 Agent

| 项目 | 内容 |
|------|------|
| **功能** | 在执行前分析请求，识别隐藏意图、歧义、潜在 AI 失败点，为后续规划提供清晰的需求文档 |
| **特点** | 属于"分析层"，不需要写代码，需要良好的自然语言理解和意图推断 |
| **推荐模型** | `anthropic/claude-sonnet-4-6` |
| **候选模型** | `openai/gpt-5.2`（GPT 备选）、`anthropic/claude-opus-4-6`（高度复杂需求场景） |
| **选型理由** | Metis 职责是意图分析而非深度推理，Sonnet 完全胜任；与 Prometheus 都用 Opus 相比，Metis 降级为 Sonnet 能节省成本而质量不明显下降 |

---

### ⚖️ momus — 计划审查批评者 Agent

| 项目 | 内容 |
|------|------|
| **功能** | 评审 sisyphus/prometheus 制定的工作计划，找出漏洞、歧义、缺失条件、不可验证的步骤，在执行前把关 |
| **特点** | 需要批判性思维，擅长发现细微问题，审查完即结束 |
| **推荐模型** | `anthropic/claude-sonnet-4-6` |
| **候选模型** | `openai/gpt-5.2`（GPT 视角的批评）、`github-copilot/claude-sonnet-4.6`（节省直连费用） |
| **选型理由** | Claude 在批判性分析和识别细微逻辑漏洞方面优于 GPT；Sonnet 级别对于"评审"任务已绰绰有余 |

---

### ⚡ atlas — 轻量级辅助 Agent

| 项目 | 内容 |
|------|------|
| **功能** | 极简辅助任务：快速建议、简单问答、title 生成、summary 生成、compaction 等系统级内部任务 |
| **特点** | 任务极简单，追求极低延迟和极低成本，质量要求低 |
| **推荐模型** | `zhipuai-coding-plan/glm-4.7` |
| **候选模型** | `anthropic/claude-haiku-4-5`（更稳定可靠）、`zhipuai-coding-plan/glm-4.5-flash`（更快） |
| **选型理由** | Atlas 承载最轻量的任务，ZhipuAI 是成本最低的 Provider，glm-4.7 在简单任务上完全够用；节省 Anthropic API 用量 |

---

## 四、Category 模型设计

| Category | 功能 | 推荐模型 | 候选模型 | 选型理由 |
|----------|------|----------|----------|----------|
| **visual-engineering** | 前端、UI/UX、样式、动画开发 | `anthropic/claude-sonnet-4-6` | `openai/gpt-5.4`、`anthropic/claude-opus-4-6` | Claude Sonnet 原生支持视觉输入，前端代码生成能力强；替代原 Gemini |
| **ultrabrain** | 真正困难的逻辑推理任务，慎用 | `anthropic/claude-opus-4-6` | `openai/gpt-5.4`、`github-copilot/claude-opus-4.6` | 最难任务必须最强推理模型；原 gpt-5.3-codex 偏代码专用，不适合纯推理 |
| **deep** | 深度自主研究型问题，行动前充分调研 | `anthropic/claude-sonnet-4-6` | `openai/gpt-5.2`、`anthropic/claude-opus-4-6` | 深度研究需综合能力（代码+推理+工具），Sonnet 比 Codex 更平衡 |
| **artistry** | 非常规创意解决方案，超越标准模式 | `anthropic/claude-sonnet-4-6` | `openai/gpt-5.4`、`anthropic/claude-opus-4-6` | Claude Sonnet 创意表达出色；原 Gemini 的创意优势由 Sonnet 接替 |
| **quick** | 单文件改动、错别字修复等极简任务 | `anthropic/claude-haiku-4-5` | `zhipuai-coding-plan/glm-4.5-flash`、`github-copilot/claude-haiku-4.5` | 最快最便宜，已是最优选择 |
| **unspecified-low** | 低复杂度的未分类任务 | `anthropic/claude-haiku-4-5` | `zhipuai-coding-plan/glm-4.7` | 低强度任务降级到 Haiku，从 Sonnet 节省成本 |
| **unspecified-high** | 高复杂度的未分类任务 | `anthropic/claude-sonnet-4-6` | `openai/gpt-5.2`、`anthropic/claude-opus-4-6` | 未明确但高复杂度，Sonnet 是最均衡选择；从 Opus 降级节省成本 |
| **writing** | 文档、技术写作、注释、README | `anthropic/claude-sonnet-4-6` | `openai/gpt-5.2`、`github-copilot/claude-sonnet-4.6` | Claude 写作质量极高，是替换原 Gemini 最合适的选项 |
| **code-review** | 代码审查、Bug 排查、安全漏洞分析 | `anthropic/claude-opus-4-6` (max) | `openai/gpt-5.4`、`anthropic/claude-sonnet-4-6` | 代码审查是最难的推理任务之一，错误判断代价极高，必须用全系最强模型 |

---

## 五、完整配置（oh-my-opencode.json）

```json
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/assets/oh-my-opencode.schema.json",
  "agents": {
    "sisyphus": {
      "model": "anthropic/claude-sonnet-4-6"
    },
    "hephaestus": {
      "model": "openai/gpt-5.3-codex",
      "variant": "medium"
    },
    "oracle": {
      "model": "anthropic/claude-opus-4-6",
      "variant": "max"
    },
    "librarian": {
      "model": "anthropic/claude-haiku-4-5"
    },
    "explore": {
      "model": "anthropic/claude-haiku-4-5"
    },
    "multimodal-looker": {
      "model": "anthropic/claude-sonnet-4-6"
    },
    "prometheus": {
      "model": "anthropic/claude-opus-4-6",
      "variant": "max"
    },
    "metis": {
      "model": "anthropic/claude-sonnet-4-6"
    },
    "momus": {
      "model": "anthropic/claude-sonnet-4-6",
      "variant": "medium"
    },
    "atlas": {
      "model": "zhipuai-coding-plan/glm-4.7"
    }
  },
  "categories": {
    "visual-engineering": {
      "model": "anthropic/claude-sonnet-4-6"
    },
    "ultrabrain": {
      "model": "anthropic/claude-opus-4-6",
      "variant": "max"
    },
    "deep": {
      "model": "anthropic/claude-sonnet-4-6",
      "variant": "medium"
    },
    "artistry": {
      "model": "anthropic/claude-sonnet-4-6",
      "variant": "high"
    },
    "quick": {
      "model": "anthropic/claude-haiku-4-5"
    },
    "unspecified-low": {
      "model": "anthropic/claude-haiku-4-5"
    },
    "unspecified-high": {
      "model": "anthropic/claude-sonnet-4-6"
    },
    "writing": {
      "model": "anthropic/claude-sonnet-4-6"
    },
    "code-review": {
      "model": "anthropic/claude-opus-4-6",
      "variant": "max"
    }
  }
}
```

---

## 六、模型分层架构图

```
┌─────────────────────────────────────────────────────────────┐
│  Tier 1 · 顶级推理（按需，低频，高值）                        │
│  anthropic/claude-opus-4-6                                  │
│  → oracle (max), prometheus (max), ultrabrain (max)         │
├─────────────────────────────────────────────────────────────┤
│  Tier 2 · 主力均衡（高频，核心任务）                          │
│  anthropic/claude-sonnet-4-6                                │
│  → sisyphus, metis, momus, multimodal-looker                │
│  → visual-engineering, deep, artistry, unspecified-high     │
│  → writing                                                  │
├─────────────────────────────────────────────────────────────┤
│  Tier 3 · 代码专项（中频，纯代码场景）                        │
│  openai/gpt-5.3-codex                                       │
│  → hephaestus (medium)                                      │
├─────────────────────────────────────────────────────────────┤
│  Tier 4 · 快速轻量（高频，搜索/探索）                         │
│  anthropic/claude-haiku-4-5                                 │
│  → librarian, explore, quick, unspecified-low               │
├─────────────────────────────────────────────────────────────┤
│  Tier 5 · 极廉价兜底（极轻量内部任务）                        │
│  zhipuai-coding-plan/glm-4.7                                │
│  → atlas                                                    │
└─────────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────────┐
  │  ★ 特殊 Tier · 代码审查专用（按需，高值）                    │
  │  anthropic/claude-opus-4-6 (max)                           │
  │  → code-review category                                    │
  └─────────────────────────────────────────────────────────────┘
```

---

## 七、与原方案关键变动说明

| Agent/Category | 原模型 | 新模型 | 变动原因 |
|----------------|--------|--------|----------|
| sisyphus | `openai/gpt-5.4` *(Provider 未配置)* | `anthropic/claude-sonnet-4-6` | 修复无效 ID，明确使用当前实际运行的模型 |
| hephaestus | `github-copilot/gpt-5.3-codex` | `openai/gpt-5.4` | 升级到直连 OpenAI 旗舰，5.4 全面超越 codex 专用版 |
| oracle | `github-copilot/gpt-5.2` ⚠️ | `anthropic/claude-opus-4-6` | Oracle 应是全系最强，gpt-5.2 级别严重不足 |
| librarian | `zhipuai/glm-4.7` ⚠️ | `anthropic/claude-haiku-4-5` | 中文模型搜索英文文档差；换 Haiku 工具调用更可靠 |
| multimodal-looker | `google/gemini-3-flash-preview` | `anthropic/claude-sonnet-4-6` | 去掉 Google 供应商，Claude Sonnet 原生支持视觉 |
| prometheus | `github-copilot/claude-opus-4.6` | `anthropic/claude-opus-4-6` | 改为直连 Anthropic，更稳定 |
| metis | `github-copilot/claude-opus-4.6` | `anthropic/claude-sonnet-4-6` | Metis 不需要 Opus 级别，省成本 |
| momus | `github-copilot/gpt-5.2` | `anthropic/claude-sonnet-4-6` | Claude 批判性分析更细腻 |
| visual-engineering | `google/gemini-3-pro-preview` | `anthropic/claude-sonnet-4-6` | 去掉 Google 供应商 |
| ultrabrain | `github-copilot/gpt-5.3-codex` | `anthropic/claude-opus-4-6` | 最难推理用最强推理模型，而非代码专用模型 |
| deep | `github-copilot/gpt-5.3-codex` | `anthropic/claude-sonnet-4-6` | 深度研究需综合能力 |
| artistry | `google/gemini-3-pro-preview` | `anthropic/claude-sonnet-4-6` | 去掉 Google 供应商 |
| unspecified-low | `github-copilot/claude-sonnet-4.5` | `anthropic/claude-haiku-4-5` | 低强度任务降级，省成本 |
| unspecified-high | `github-copilot/claude-opus-4.6` | `anthropic/claude-sonnet-4-6` | 未明确任务不值得上 Opus |
| writing | `google/gemini-3-flash-preview` | `anthropic/claude-sonnet-4-6` | 去掉 Google 供应商，Claude 写作同样出色 |
