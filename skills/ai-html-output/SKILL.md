---
name: ai-html-output
description: 用 HTML 替代 Markdown 作为 AI 输出格式 — 报告、代码审查、技术计划、研究摘要、状态更新等场景。基于 Thariq Shihipar "The Unreasonable Effectiveness of HTML" 趋势。标记了 HTML 优于 Markdown 的场景、模板骨架、配色惯例说明。
version: 1.0.0
metadata:
  hermes:
    tags: [html, output-format, report, code-review, markdown, content]
    related_skills: [huashu-design, claude-design, sketch]
    priority: optional
platforms: [linux, macos, windows]
---

# AI HTML Output

用 HTML 替代 Markdown 作为 AI 的默认输出格式，让报告、代码审查、技术方案和知识文档可交互、可导航、一目了然。

> **核心哲学**: HTML 不是"花哨的 Markdown"，它是信息空间布局的载体。Markdown 适合编辑，HTML 适合阅读。

## 背景

**2026年5月8日**，Anthropic Claude Code 工程负责人 **Thariq Shihipar** 在 X 上发布长文 **《Using Claude Code: The Unreasonable Effectiveness of HTML》**，主张在日常 AI 交互中用 HTML 替代 Markdown 作为输出格式。

- 首 16 小时：440万+ 曝光、8,200+ 点赞、15,700+ 书签
- 配套演示站点：`thariqs.github.io/html-effectiveness/`（20 个 HTML 示例）
- 引发 Hacker News（1000+ 分）、Simon Willison 博客、Threads、LinkedIn 大讨论

### Thariq 五大主张

| # | 主张 | 核心逻辑 |
|---|------|---------|
| 1 | **空间信息 > 线性文本** | Diff、调用图、架构对比是空间信息，Markdown 把它们压平了。HTML 可以并排、标注、折叠。 |
| 2 | **Token 投资回报率** | 同样 4K 输出 token，Markdown 给一段墙，HTML 给一个带导航/图表/折叠区的结构化页面。 |
| 3 | **浏览器原生可读** | `.md` 需要工具渲染，`.html` 在任何浏览器上直接打开。发给同事 / 上传 CDN 即读。 |
| 4 | **Agent 构建复杂页面不费力** | 模型在 HTML/CSS/JS 上的训练数据远超 markdown layout。让它做 tab、图表、交互式列表几乎零成本。 |
| 5 | **超长文档的可导航性** | 800 行的 .md 没人读完。HTML 可以用目录侧栏、可折叠 section、tab 分页把长文档结构化。 |

详情见 `references/thariq-original-claims.md`。

## 触发场景

合适 HTML 的场景（优先使用 HTML）：

- **代码审查 / PR 总结** — 差异对比 + 严重性标记 + 跳转链接 + 建议复选框
- **技术方案 / 实施计划** — 甘特图 + 数据流图 + 风险表 + mockup
- **知识解释 / 研究摘要** — TL;DR 盒 + 可折叠步骤 + tabbed 代码片段 + FAQ
- **状态报告 / 周报** — 已完成/延期/图表 + 快速浏览格式
- **对比分析** — 多个方案并排对比，trade-off 标注
- **排行榜 / 评分卡** — 富格式表格 + 指标 + 图标
- **多步教程 / 文档** — 侧边导航 + 进度指示

仍用 Markdown 的场景：
- **短消息 / 简单回答** — 2-3 句话的答案
- **纯代码片段** — 无需上下文修饰的代码
- **用户要求 Markdown** — 编辑、复制、粘贴到 Wiki
- **公开可转发内容** — 飞书/小红书/微博，Markdown 兼容性更好

## 模板骨架

以下是通用的 HTML 输出模板，适用大部分场景。核心特征：

1. 单文件自包含（CSS inline）
2. 默认**亮色主题**（Thariq 原始示例采用 light mode）
3. 通过 `prefers-color-scheme` 支持暗色自动切换（不默认暗色）
4. 无外部依赖，浏览器直接打开
5. 可折叠 section、内联代码高亮、表格、SVG 图表

参见 `templates/default-report.html` 用于复制修改。

### 配色关键说明

> **重要**：Thariq 的 20 个原始示例全部使用**亮色主题**（象牙白 `#FAF9F5` 背景 + 深灰 `#141413` 文字）。社区和 AI 开发者生态中流行的"暗色默认"（GitHub dark `#0D1117` 风格）是开发者工具文化的自发产物，**不是 Thariq 的主张**。

本技能默认提供亮色主题，通过 `@media (prefers-color-scheme: dark)` 自适应暗色。

| 角色 | 亮色默认 | 暗色自适应 |
|------|---------|-----------|
| 背景 | `#FAF9F5` | `#0D1117` |
| 卡片 | `#FFFFFF` | `#161B22` |
| 正文 | `#3D3D3A` | `#E6EDF3` |
| 标题 | `#141413` | `#F0F6FC` |
| 强调色 | `#D97757` (暖陶) | `#58A6FF` (蓝) |
| 边框 | `#D1CFC5` | `#30363D` |

## 场景决策表

| 用户需求 | 输出格式 | 理由 |
|---------|---------|------|
| "解释这个 PR" | HTML | 需要 diff + 标注 + 建议复选框 |
| "帮我写周报" | HTML | 表格 + 图表 + 快速浏览 |
| "这个代码怎么工作" | HTML | 调用图 + 可折叠步骤 |
| "对比 A 和 B" | HTML | 并排对比 + tradeoff 标注 |
| "现在几点了" | Markdown | 单纯不需要样式 |
| "怎么安装 X" | HTML（有步骤）或 Markdown（短） | 看步骤数量 |
| "这个概念的原理" | HTML | 交互式 explainer + 图示 |
| 发到飞书群 | Markdown | 飞书原生渲染 Markdown |

## 常见陷阱

- **不要每次都用 HTML**：短回答用 Markdown 更快更省 token
- **不要伪装成手写**：HTML 的设计美学是"Agent 帮您整理好的"风格，标明即可
- **避免过度交互**：checkbox 和按钮在实际阅读时可能没用，评估场景是否需要
- **注意文件大小**：超长 HTML 不如拆成多文件或使用折叠机制
- **Don't force dark mode**：Thariq 本人用 light mode。暗色不是默认方案。

## References

- `references/thariq-original-claims.md` — Thariq 五大主张原文引用 + 社区讨论总结
- `references/dark-vs-light-context.md` — AI 输出 HTML 的暗色/亮色选择背景与讨论
- `templates/default-report.html` — 通用报告模板（亮色默认 + 暗色自适应）
