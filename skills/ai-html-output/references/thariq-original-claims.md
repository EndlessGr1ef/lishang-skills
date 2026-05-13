# Thariq Shihipar 原文主张与社区讨论

> 记录日期：2026-05-13
> 原文：Thariq Shihipar (trq212) 在 X 发布的《Using Claude Code: The Unreasonable Effectiveness of HTML》
> 链接：https://x.com/trq212/status/2011523109871108570（推文链）

## 五大主张（详细版）

### 1. 空间信息 > 线性文本

Markdown 本质上是一种线性格式。代码 diff、调用图、架构对比、设计方向并排对比——这些都是**空间信息**，Markdown 把它们压成一条线。

HTML 可以做：
- 并排对比（grid / flexbox）
- 复杂表格
- 有 margin 标注的 diff
- 框图 + 箭头
- 可折叠区域

> 原文示例：PR 审查页面，diff 嵌入 inline margin 标注 + 严重性颜色编码

### 2. Token 投资回报率

同样的输出 token，HTML 能承载远比 Markdown 多的信息：
- Markdown：纯文本 + 代码块 + 列表 + 表格
- HTML：导航栏 + 侧边目录 + tab 页 + 折叠区 + 内联 SVG 图 + 表格 + 列表 + 代码高亮 + 交互控件

Thariq 认为：**用 4K token 生成的 Markdown 是一面墙，用 4K token 生成的 HTML 是一个可直接发布的页面。**

### 3. 浏览器原生可读

- `.md` 文件：需要 IDE/工具渲染，不可直接浏览器打开，或打开后只有纯文本
- `.html` 文件：任何浏览器直接打开，URL 可分享，S3/CDN 直接托管

> 实际体会：发一个 `.md` 给同事，对方要下载 -> 打开编辑器 -> 才能看。
> 发一个 `.html`，对方双击浏览器打开，或者上传到内网 CDN 分享链接。

### 4. Agent 构建复杂页面不费力

模型在 HTML/CSS/JS 上的训练数据远多于 Markdown 的 layout/template 惯例：
- 让模型写一个带 tab 的 HTML 页面：几乎零成本
- 让模型用 Markdown "对齐三栏"：做不到

模型天生擅长 HTML，这是它的"母语"之一。

### 5. 超长文档的可导航性

800 行的 Markdown 文档几乎没人能读完。但 800 行 HTML 可以通过以下方式变成可浏览的：
- 固定侧边目录
- `<details>/<summary>` 折叠 section
- tab 分页（按主题拆分）
- 返回顶部按钮
- 引导式 "Next →" 导航

> 核心洞察：**人们不读长文档是因为没法扫读，HTML 解决了扫读问题。**

## 20 个示例分类

| # | 分类 | 示例数 | 代表 |
|---|------|--------|------|
| 01 | 探索与规划 | 3 | 三种代码方案并排对比、视觉设计方向、实施计划 |
| 02 | 代码审查 | 3 | 带标注的 PR、PR 描述、模块地图 |
| 03 | 设计 | 2 | 活的 Design System、组件变体 |
| 04 | 原型 | 2 | 动画沙箱、可点击流程 |
| 05 | 图示 | 2 | SVG 图形表、带注释的流程图 |
| 06 | 演示 | 1 | 键盘导航的 HTML 幻灯片 |
| 07 | 研究与学习 | 2 | Feature 解释、概念解释 |
| 08 | 报告 | 2 | 周报、事故时间线 |
| 09 | 自定义编辑器 | 3 | 工单看板、Feature Flag 编辑器、Prompt 调参器 |

所有示例见：https://thariqs.github.io/html-effectiveness/

## 社区反应

### Simon Willison

在《Using Claude Code: The Unreasonable Effectiveness of HTML》链接博客中写道：
> "I've been defaulting to asking for most things in Markdown since the GPT-4 days... Thariq's piece here has caused me to reconsider that, especially for output."

他亲自测试了让 GPT-5.5 用 HTML 格式解释 `copy.fail` 的安全漏洞 PoC。

### Hacker News

HN 讨论超 1000 分，主要争议点：
- **支持方**：确实，Markdown 的线性结构限制了很多输出，HTML 能承载更丰富的信息
- **反对方**：(a) HTML 混杂了大量格式 token，降低了输出效率 (b) 可编辑性差，不能直接作为代码注释 (c) 看起来太像成品，人们不敢修改
- **折中**：`markdown` → `html` 转换作为后处理步骤，不是替换原始输出

### 通用共识

1. HTML 更适合**给人类阅读**的终端产物（报告、方案、PR 审查）
2. Markdown 仍然是更适合**给 AI 编辑**的工作格式
3. 最佳实践是混合使用：Markdown 作为工作流格式，HTML 作为交付格式
