---
name: ai-html-output
description: Use HTML instead of Markdown as an AI output format for reports, code reviews, technical plans, research summaries, status updates, and similar deliverables. Derived from Thariq Shihipar's "The Unreasonable Effectiveness of HTML" post and examples. Includes a source-faithful summary, practical trigger scenarios, a template skeleton, and color-theme conventions.
version: 1.0.0
metadata:
  hermes:
    tags: [html, output-format, report, code-review, markdown, content]
    related_skills: [huashu-design, claude-design, sketch]
    priority: optional
platforms: [linux, macos, windows]
---

# AI HTML Output

Use HTML instead of Markdown when AI output needs to be interactive, navigable, easy to scan, and easy to share.

> **Core philosophy**: HTML is not just "fancy Markdown". It is a medium for laying out information in space. Markdown is often better for editing; HTML is often better for reading.

## Background

On **May 8, 2026**, **Thariq Shihipar**, an engineering lead on Anthropic Claude Code, published a long-form post on X titled **"Using Claude Code: The Unreasonable Effectiveness of HTML"**, arguing that HTML is often a better output format than Markdown for many AI-generated artifacts.

- First 16 hours: 4.4M+ impressions, 8,200+ likes, 15,700+ bookmarks
- Companion demo site: `thariqs.github.io/html-effectiveness/` with 20 HTML examples
- Sparked major discussion on Hacker News, Simon Willison's blog, Threads, and LinkedIn

## Source-faithful summary of Thariq's post

The original post is structured around these themes:

| Theme | What Thariq argues |
|---|---|
| **Information Density** | HTML can express richer structures than Markdown: tables, CSS-based design, SVG, scripts, interactions, workflows, spatial layouts, and images. |
| **Visual Clarity & Ease of Reading** | Long specs and plans are easier to navigate as HTML with tabs, illustrations, links, and responsive layout. |
| **Ease of Sharing** | HTML is easier to share and read in a browser; Markdown often needs an editor or a special renderer. |
| **Two-way Interaction** | HTML artifacts can include sliders, knobs, previews, and copy-back controls that let the reader manipulate the output. |
| **Data Ingestion** | Claude Code is especially good at producing these artifacts because it can ingest filesystem context, MCP data, browser context, and git history. |
| **It’s Joyful** | HTML output can feel more engaging, involving, and fun to work with. |

Two additional source notes matter:

- Thariq explicitly warns that you do **not** need a heavy `/html` skill to start; often you can just ask for "an HTML file" or "an HTML artifact".
- In the FAQ, he also acknowledges real downsides: **HTML takes longer to generate** and **HTML diffs are noisy and harder to review in version control**.

See `references/thariq-original-claims.md` for a closer source summary.

## Practical guidance derived from the post

The sections below are **operational guidance inspired by Thariq's post**, not a claim that every line is his exact wording.

### Good trigger scenarios for HTML

- **Code reviews / PR summaries** — diff comparison, severity markers, jump links, and review guidance
- **Technical proposals / implementation plans** — timelines, data-flow diagrams, risk tables, and mockups
- **Knowledge explanations / research summaries** — TL;DR boxes, collapsible steps, annotated snippets, and diagrams
- **Status reports / weekly updates** — shipped/slipped work, charts, and skim-friendly layout
- **Comparative analysis** — side-by-side option comparison with trade-off annotations
- **Interactive tuning artifacts** — sliders, knobs, previews, or copy-back controls for prompts, configs, or designs
- **Structured editing interfaces** — triage boards, feature-flag editors, dataset curation views, or approval tools

### Cases where Markdown may still be better

This is practical guidance, not a direct quote from Thariq.

- **Short messages / simple answers** — two or three sentences do not need extra structure
- **Plain code snippets** — when the code stands on its own without explanation
- **User explicitly requests Markdown** — for editing, copying, or pasting into a wiki
- **Version-controlled working docs** — Markdown diffs are often cleaner and easier to review
- **Quick iteration** — HTML often takes longer to generate than Markdown
- **Publicly shareable social content** — Feishu, Xiaohongshu, Weibo, and similar surfaces may have better Markdown compatibility

## Template skeleton

The following is a general-purpose HTML output template that works for many scenarios. Key traits:

1. Single-file and self-contained with inline CSS
2. **Light theme by default**; Thariq's examples are predominantly light themed
3. Automatic dark-mode support through `prefers-color-scheme`; dark mode is not forced by default
4. No external dependencies; opens directly in a browser
5. Support for collapsible sections, inline code highlighting, tables, and SVG charts

Use `templates/default-report.html` as a starting point for copy-and-modify workflows.

### Important color guidance

> **Important**: Thariq's example set is visually dominated by **light themes**: ivory `#FAF9F5` background plus dark gray `#141413` text. The common "dark by default" aesthetic in AI and developer-tool ecosystems is a broader developer-culture convention, **not the main visual takeaway of his examples**.

This skill defaults to a light theme and adapts to dark mode through `@media (prefers-color-scheme: dark)`.

| Role | Light default | Dark adaptive |
|------|---------------|---------------|
| Background | `#FAF9F5` | `#0D1117` |
| Card | `#FFFFFF` | `#161B22` |
| Body text | `#3D3D3A` | `#E6EDF3` |
| Heading | `#141413` | `#F0F6FC` |
| Accent | `#D97757` warm terracotta | `#58A6FF` blue |
| Border | `#D1CFC5` | `#30363D` |

## Scenario decision table

| User request | Output format | Reason |
|--------------|---------------|--------|
| "Explain this PR" | HTML | Benefits from visual diff explanation and annotations |
| "Help me write a weekly report" | HTML | Benefits from charts, sections, and skim-friendly formatting |
| "How does this code work?" | HTML | Benefits from diagrams, annotated snippets, and clearer structure |
| "Compare A and B" | HTML | Side-by-side comparison is easier in HTML |
| "What time is it?" | Markdown | Pure answer, no layout needed |
| "How do I install X?" | HTML if long; Markdown if short | Depends on how much scaffolding the explanation needs |
| "Tune this prompt/config/design" | HTML | Interaction and live preview can help |
| "Post this to a Feishu group" | Markdown | Native Markdown compatibility may be better |

## Common pitfalls

- **Do not use HTML every time**: short answers are often better in Markdown.
- **Do not over-attribute claims**: separate what the source explicitly says from your own derived guidance.
- **Avoid excessive interactivity**: controls should serve a clear reading or editing purpose.
- **Remember the tradeoffs**: HTML can be slower to generate and harder to diff in version control.
- **Watch file size**: very long HTML is often worse than multiple files or a carefully collapsed single file.
- **Do not force dark mode**: dark mode is not the default recommendation implied by Thariq's examples.

## References

- `references/thariq-original-claims.md` — source-faithful summary of the original post, its sections, FAQ tradeoffs, and community discussion
- `references/dark-vs-light-context.md` — background and discussion on dark-vs-light choices for AI-generated HTML
- `templates/default-report.html` — general report template with a light default theme and adaptive dark mode
