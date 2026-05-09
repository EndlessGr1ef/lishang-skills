---
name: twitter-insight-browse
description: 通过 opencli 复用浏览器登录态，自动拉取 Twitter/X 的 For You 时间线、特定话题搜索和讨论线程，并汇总成结构化的热点报告和深度分析。热门趋势（Trending）为可选内容，仅在用户明确要求时拉取。当用户说"查查 Twitter 最新帖子"、"拉取下最新推文"、"看看 X 上有啥热点"、"Twitter 上关于 XXX 的讨论"、"去 Twitter 上查一下"、"最新 tweet"等触发。也适用于需要深入了解某个在 Twitter 上发酵的技术/产品话题。
---

# Twitter/X 热点洞察浏览

## Goal
快速获取 Twitter/X 上的最新个性化推荐、热门趋势和特定话题讨论，以结构化报告形式呈现关键信息和社区观点。

## Prerequisites & Pre-flight Check

每次会话首次执行前跑一次安装/连通性检查：

```bash
bash scripts/check-install.sh
```

脚本会按顺序验证并自动修复：
1. Node.js >= 21
2. `opencli` 已全局安装（缺失时自动 `npm install -g @jackwener/opencli`）
3. `opencli twitter` 适配器可用
4. Browser Bridge 扩展已连接（缺失时给出手动安装指引）

> Browser Bridge 扩展和 x.com 登录态无法自动化，必须用户在浏览器手动完成（脚本会输出具体步骤）。
>
> 后续命令再失败时只需 `opencli doctor` 单独诊断 bridge 状态。

---

## Modes

### Mode 1: 快速热点扫描
**触发**: "最新推文" / "有啥热点" / "For You 推荐"

并行拉取 For You + Following 两个时间线：

```bash
opencli twitter timeline --type for-you --limit 15 -f md 2>&1
opencli twitter timeline --type following --limit 15 -f md 2>&1
```

- timeout: **120s**（首次加载常较慢）
- 失败（Detached/SecurityError）重试一次
- 输出：For You 表格 + Following 表格 + 🔑 推荐要点（3-5 条）

**可选 - Trending**: 仅当用户明确要求"热点趋势""trending"时执行：

```bash
OPENCLI_DIAGNOSTIC=1 opencli twitter trending --limit 15 -f md 2>&1
```

必须加 `OPENCLI_DIAGNOSTIC=1`，否则可能 EMPTY_RESULT。

---

### Mode 2: 话题搜索
**触发**: "Twitter 上关于 XXX 的讨论" / "XXX 咋样"

```bash
opencli twitter search "关键词" --limit 20 -f md 2>&1
```

- timeout: 120s
- 中文失败（SecurityError）或结果不足时改英文关键词
- 同一话题至少尝试 2-3 组近义词，确保覆盖
- 产品/模型类话题可同时用 `tavily_tavily_search` 补官方信息
- 输出：表格（作者/内容/时间/互动）+ 分类总结（官方发布 / 实测分享 / 社区评价）

---

### Mode 3: 线程深挖
**触发**: 某条热门推文（>1000 likes）下需要看真实社区反馈

先用 Mode 2 找到 tweet-id，再拉线程：

```bash
opencli twitter thread "tweet-id" -f md 2>&1
```

- timeout: 60s
- 输出：表格（作者/回复/互动）+ 观点分类（好评 / 中立 / 负面 / 提问）

---

### Mode 4: 深度话题报告
**触发**: "详细了解一下" / "分析一下"（产品发布、收购、模型评测等）

组合：Mode 2 搜索 → 对高互动推文 Mode 3 深挖 → `tavily_tavily_search` 补官方/新闻 → 输出多维度报告。

报告结构：
1. 核心事件概述
2. 官方/权威来源信息
3. 社区观点分类汇总（表格）
4. 关键数据/对比
5. 结论与趋势判断

---

## Output Templates

### 时间线 / 搜索通用
```markdown
## 📱 [For You / 关注列表 / "关键词"] 

| 作者 | 内容要点 | 热度 |
|------|----------|------|
| @author | 摘要 | 🔥 N👍 |

### 🔑 核心要点
1. ...
```

搜索场景在表格里加一列"时间"，深度报告在总结里按"官方/权威"、"实测/案例"、"社区评价"三类组织。

### 线程
```markdown
## 💬 讨论线程分析

| 作者 | 回复内容 | 互动 |
|------|----------|------|
| @author | 摘要 | N👍 |

### 观点分布
| 类型 | 数量 | 代表性观点 |
|------|------|------------|
| 好评 | N | |
| 中立 | N | |
| 负面 | N | |
```

---

## Examples

### Example 1: 快速热点扫描
**User**: "拉取下最新推文，看看有啥新热点"

1. `opencli doctor` 检查
2. 并行：`twitter timeline --type for-you` + `twitter timeline --type following`
3. 输出 For You 表格 + Following 表格 + 要点总结

> Trending 仅在用户明确说"看看热门趋势"时才拉。

### Example 2: 话题深度挖掘
**User**: "ChatGPT Images 2.0 关于这个的几个推文的详细内容是啥，总结一下"

1. `twitter search "ChatGPT Images 2.0" --limit 20`
2. 识别官方推文和高互动推文
3. 对高互动推文执行 `twitter thread "<tweet-id>"`
4. `tavily_tavily_search` 补官方博客
5. 输出：官方能力 + 社区实测 + 评价 + 关键数据

### Example 3: 教程/攻略查找
**User**: "去 Twitter 上查一查怎么注册日本 Apple ID"

1. `twitter search "日本 Apple ID 注册"`
2. 结果不足时换 `"apple id 日本区"`、`"Japan Apple ID register"`
3. 输出：注册步骤表 + 支付方式 + 避坑指南

---

## Best Practices

- **中英文交替**：中文搜索在中文社区往往更稳定；英文适合国际话题
- **timeout**：timeline ≥120s，trending 加 `OPENCLI_DIAGNOSTIC=1`
- **多关键词**：同一话题尝试 2-3 组近义词
- **优先深挖高互动推文**（>1000 likes），社区反馈往往比官方推文有价值
- **区分官方信息与社区观点**，输出时分开标注
- **Don't**：用 `webfetch` 直接抓 x.com（JS 限制几乎不可用）
- **Don't**：单次搜索失败就放弃

---

## Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| `Detached while handling command` | 浏览器页面分离 | 重试一次 |
| `SecurityError: pushState` | 英文搜索特定关键词触发 | 切换中文关键词 |
| `EMPTY_RESULT` (trending) | 页面结构变化或地区问题 | 加 `OPENCLI_DIAGNOSTIC=1` |
| 超时 (timeline) | X.com 加载慢 | timeout 调至 120s |
| Extension not connected | 浏览器扩展未启动 | 打开扩展面板启动 opencli |
| 结果重复/质量差 | 搜索词太宽泛 | 加限定词（"2025"/"最新"/"评测"） |

---

## Command Reference

| Command | Purpose | Key Flags |
|---------|---------|-----------|
| `opencli twitter timeline --type for-you` | 个性化推荐 | `--limit`, `-f md`, timeout=120s |
| `opencli twitter timeline --type following` | 关注列表 | `--limit`, `-f md`, timeout=120s |
| `opencli twitter trending` | 热门趋势 | `--limit`, `-f md`, `OPENCLI_DIAGNOSTIC=1` |
| `opencli twitter search "query"` | 话题搜索 | `--limit`, `-f md`, timeout=120s |
| `opencli twitter thread "id"` | 讨论线程 | `-f md`, timeout=60s |
| `opencli doctor` | 检查连接状态 | — |
