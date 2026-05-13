# AI 输出 HTML 的暗色 vs 亮色选择背景

> 记录日期：2026-05-13
> 来源：用户质疑"为什么 HTML 要以暗色为基底"的对话

## 结论

**Thariq Shihipar 从未推荐暗色。** 他的 companion site `thariqs.github.io/html-effectiveness/` 上 20 个示例全部使用亮色主题（象牙白 `#FAF9F5` 背景 + 深灰 `#141413` 文字）。

暗色成为 AI 输出 HTML 的"默认审美"是开发者生态自发生成的惯例。

## 暗色流行的三个成因

### 1. 开发者工具的全体暗色化

开发者日常使用的工具几乎全部暗色：
- VS Code（默认 Dark Modern）
- 终端（黑色背景）
- GitHub（Dark Mode 已成为主流选择）
- Claude Code CLI（终端内运行，天然暗色）
- X/Twitter（多数开发者用户使用暗色模式）

当 AI 被要求生成"对开发者友好的 HTML"，训练数据中"开发者工具 = 暗色"的强关联导致输出自然偏向暗色。

### 2. "专业感"的心理暗示

终端、IDE、数据库客户端、监控面板几乎全是暗色。AI 模型在训练数据中看到的是：
- 暗色 → 专业开发工具
- 亮色 → 普通网页/文档

这种隐性关联使得 AI 在生成"技术类 HTML 输出"时主动选择暗色方案。

### 3. 代码高亮在暗色上更可控

AI 生成的 HTML 通常包含大量语法高亮的代码块。深色背景+亮色高亮（蓝、绿、橙）的对比度一致性比白底更容易掌控。模型在暗色上翻车的概率更低，白色背景更容易出现对比度不一致的问题。

## 正确选择

| 场景 | 推荐基调 | 理由 |
|------|---------|------|
| 代码审查 / PR 总结 | 亮色（或按用户偏好） | Thariq 示例均为亮色 |
| 技术方案 / 计划 | 亮色优先，自适应暗色 | 阅读量大的文档亮色更护眼 |
| 数据报告 / 周报 | 亮色优先 | 图表在亮色下可读性更好 |
| 终端/CLI 工具输出 | 暗色 | 匹配使用上下文 |
| 开发者工具文档 | 按用户系统偏好自适应 | `prefers-color-scheme` |
| 仅限内部开发者观看 | 暗色可接受 | 匹配工具链语境 |

**最佳实践**：使用 `@media (prefers-color-scheme: dark)` 同时支持两种模式，默认亮色。这既尊重用户系统设置，又不会让不熟悉暗色背景的读者感到突兀。

## CSS 示例：双主题方案

```css
:root {
  --bg: #FAF9F5;
  --bg-card: #FFFFFF;
  --text: #3D3D3A;
  --heading: #141413;
  --accent: #D97757;
  --border: #D1CFC5;
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg: #0D1117;
    --bg-card: #161B22;
    --text: #E6EDF3;
    --heading: #F0F6FC;
    --accent: #58A6FF;
    --border: #30363D;
  }
}
```

## 参考

- Thariq 示例站：https://thariqs.github.io/html-effectiveness/
- Simon Willison 转载分析：https://simonwillison.net/2026/May/8/unreasonable-effectiveness-of-html/
- Hacker News 讨论线程（搜索 "The Unreasonable Effectiveness of HTML"）
