---
name: x-news
description: 通过 opencli 复用浏览器登录态，默认自动拉取 Twitter/X 最新推文时间线（For You + Following），也支持特定话题搜索和讨论线程深挖，并统一用 answer-me-with-html 生成单页 HTML 报告。用户只说"用 x-news"、"查 Twitter"、"拉最新"、"看看 X"等未指定话题的模糊请求时，直接执行最新推文扫描，不要只回复技能已加载。热门趋势（Trending）为可选内容，仅在用户明确要求时拉取。当用户说"查查 Twitter 最新帖子"、"拉取下最新推文"、"看看 X 上有啥热点"、"Twitter 上关于 XXX 的讨论"、"去 Twitter 上查一下"、"最新 tweet"等触发。也适用于需要深入了解某个在 Twitter 上发酵的技术/产品话题。
---

# X 热点洞察（x-news）

## Goal

拉取 Twitter/X 的最新推荐、关注流、话题搜索和讨论线程，用 `answer-me-with-html` 输出单页 HTML 报告。

## Default Behavior

当用户只是要求应用/使用这个 skill，或笼统要求"查 Twitter"、"看看 X"、"拉最新"，但没有给出具体话题、推文 ID 或深度分析目标时，默认执行 **Mode 1: 快速热点扫描**：拉取最新 For You + Following 时间线并总结。

不要在这种默认场景中只回复"技能已加载"；应直接进行安装/连通性检查，然后拉取最新推文。

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
**触发**: 默认模式；"最新推文" / "有啥热点" / "For You 推荐" / "拉最新" / "看看 X"

并行拉取 For You + Following 两个时间线：

```bash
opencli twitter timeline --type for-you --limit 30 -f md 2>&1
opencli twitter timeline --type following --limit 30 -f md 2>&1
```

- timeout: **120s**（首次加载常较慢）
- 失败（Detached/SecurityError）重试一次
- 输出见「HTML 输出」

**可选 - Trending**: 仅当用户明确要求"热点趋势""trending"时执行：

```bash
OPENCLI_DIAGNOSTIC=1 opencli twitter trending --limit 30 -f md 2>&1
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

---

### Mode 3: 线程深挖
**触发**: 某条热门推文（>1000 likes）下需要看真实社区反馈

先用 Mode 2 找到 tweet-id，再拉线程：

```bash
opencli twitter thread "tweet-id" -f md 2>&1
```

- timeout: 60s

---

### Mode 4: 深度话题报告
**触发**: "详细了解一下" / "分析一下"（产品发布、收购、模型评测等）

组合：Mode 2 搜索 → 对高互动推文 Mode 3 深挖 → `tavily_tavily_search` 补官方/新闻。

---

## HTML 输出（统一走 answer-me-with-html）

**不要手写 HTML / CSS / SVG。** 只写 Markdown 草稿，交给 `am render` 生成页面。

CLI 路径：

```bash
node ~/.agents/skills/answer-me-with-html/scripts/am.mjs
```

一次 heredoc 出页。下面是最小可用骨架，按实际数据替换数值：

````bash
node ~/.agents/skills/answer-me-with-html/scripts/am.mjs render - <<'AM_EOF'
---
template: sheet
title: Twitter/X 热点洞察 · 2026-10-21
subtitle: 一句话概括本轮主线
cols: 2
source: opencli twitter timeline
---
本轮抓取 N 条原始推文，去重后 M 条，覆盖时间区间。

## A 核心结论 {span=2}
```callout info 一句话结论标题
支撑结论的第一个数字。第二个数字。第三个数字。
```

## B 话题簇互动量
```chart bar horizontal unit=次
新闻速览 | 29142
Codex 计费 | 21175
```
互动量为点赞、转发、回复之和。

## C 两条相反的主线
| 主线 | 代表推文 | 点赞 | 主张 |
|---|---|---|---|
| 替代焦虑 | @author 说了什么 | 1103 | 关键细节 |
| 规则与评审 | @author 说了什么 | 6630 | 关键细节 |

## D 值得手动读完的几条
- @author 一句话理由，附互动量
AM_EOF
````

### 面板配方

按模式选 3-7 个面板，一个面板只回答一个问题：

| 模式 | 面板 |
|------|------|
| Mode 1 | 核心结论 `callout` → 话题簇互动量 `chart bar` → 相反主线对比 `table` → 值得深挖 `list` |
| Mode 2 | 结论 `callout` → 分类表（官方 / 实测 / 社区评价）`table` → 代表推文 `list` |
| Mode 3 | 观点分布 `chart pie`（好评/中立/负面/提问）→ 代表回复 `table` |
| Mode 4 | 事件概述 `callout` → 官方信息 `kv` → 社区观点分类 `table` → 关键数据 `chart` |

### 硬规则

- **只用真实数据**：数字必须来自 `opencli` 输出，不要编造浏览量和点赞。
- **图表必须有真实数值**：没有数字就用 `table` 或 `list`，不要画 `chart`。
- **STE 警告必须修**：`am render` 报 `STE n warnings` 时页面不会自动打开；按提示改写后加 `--replace <上一个页面路径>` 重渲染。
- **改单页只改面板**：已存在的页面用 `am patch page.html --panel "面板标题"`，不要整页重写。

### 交付

1. 渲染成功后调用 `present`，传绝对路径，让用户从卡片打开。
2. 终端回复 2-3 行：一句核心结论 + 页面链接。不要把草稿或 HTML 贴回终端。

---

## Examples

### Example 1: 快速热点扫描
**User**: "拉取下最新推文，看看有啥新热点"

1. `opencli doctor` 检查
2. 并行：`twitter timeline --type for-you` + `twitter timeline --type following`
3. 按 Mode 1 面板配方渲染页面
4. 回复：本轮的绝对主角是谁 + 页面链接

> Trending 仅在用户明确说"看看热门趋势"时才拉。

### Example 2: 话题深度挖掘
**User**: "ChatGPT Images 2.0 关于这个的几个推文的详细内容是啥，总结一下"

1. `twitter search "ChatGPT Images 2.0" --limit 20`
2. 识别官方推文和高互动推文
3. 对高互动推文执行 `twitter thread "<tweet-id>"`
4. `tavily_tavily_search` 补官方博客
5. 按 Mode 2 面板配方出页

### Example 3: 教程/攻略查找
**User**: "去 Twitter 上查一查怎么注册日本 Apple ID"

1. `twitter search "日本 Apple ID 注册"`
2. 结果不足时换 `"apple id 日本区"`、`"Japan Apple ID register"`
3. 用 `flow` 画步骤，用 `callout` 标避坑点

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
| `am render` 未自动打开 | 有 STE 或代码警告 | 按提示改写后 `--replace` 重跑 |
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
| `am render - <<'AM_EOF'` | 出单页 HTML | `--replace <page>` 覆盖上一版 |
| `am patch page.html --panel "标题"` | 只改一个面板 | 保持原主题与样式 |
