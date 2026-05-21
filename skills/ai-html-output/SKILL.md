---
name: ai-html-output
description: Use HTML instead of Markdown as an AI output format for reports, code reviews, technical plans, research summaries, status updates, and similar deliverables. Includes Mermaid diagram support via CDN. Derived from Thariq Shihipar's "The Unreasonable Effectiveness of HTML" post and examples. Includes a source-faithful summary, practical trigger scenarios, a template skeleton, and color-theme conventions.
version: 2.0.0
---

# AI HTML Output

Use HTML instead of Markdown when AI output needs to be interactive, navigable, easy to scan, and easy to share.

> **Core philosophy**: HTML is not just "fancy Markdown". It is a medium for laying out information in space. Markdown is often better for editing; HTML is often better for reading.

## Background

Derived from Thariq Shihipar's post *"Using Claude Code: The Unreasonable Effectiveness of HTML"* (May 2026). Core idea: HTML is a medium for laying out information in space — richer than Markdown for reading, though not always better for editing.

Key takeaways:

- HTML excels at information density, visual clarity, sharing, and two-way interaction
- You often don't need a heavy `/html` skill — just ask for "an HTML file"
- Tradeoffs: slower generation (~2-4x), noisy diffs, higher token usage

For the full source summary, see `references/thariq-original-claims.md`.

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
- **Platform-native sharing** — some social platforms and chat tools render Markdown natively but strip or mangle HTML

## File output convention

When generating an HTML artifact as a file, save it to an `html/` folder in the current working directory:

```
./html/{descriptive-name}.html
```

If the `html/` directory does not exist, create it. This keeps generated artifacts organized and separate from source files.

## Template skeleton

The following is a general-purpose HTML output template that works for many scenarios. Key traits:

1. Single-file and self-contained with inline CSS
2. **Light theme by default**; Thariq's examples are predominantly light themed
3. Automatic dark-mode support through `prefers-color-scheme`; dark mode is not forced by default
4. No build-time dependencies; opens directly in a browser (Mermaid is loaded from CDN at runtime)
5. Support for collapsible sections, inline code highlighting, tables, and SVG charts
6. Built-in [Mermaid](https://mermaid.js.org) diagram rendering via CDN import

Use `templates/default-report.html` as a starting point for copy-and-modify workflows.

**Template placeholders** — the template uses these variables that must be replaced with actual content:

| Placeholder | Purpose | Example |
|-------------|---------|---------|
| `{TITLE}` | Page `<title>` and top-level `<h1>` heading | "Q1 2026 Status Report" |
| `{CATEGORY}` | Pill label in the topbar — describes the artifact type | "Code Review" |
| `{DATE}` | Display date in the header meta row | "May 15, 2026" |
| `{CONTENT}` | The entire main body — HTML content that replaces this placeholder inside `<main class="content">` | Full sections, tables, diagrams, etc. |

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

## Data visualization

**Visual-first principle**: HTML is for human consumption. When information can be expressed visually — flows, relationships, sequences, hierarchies, trends, proportions — always prefer charts and diagrams over paragraphs. A single visual often carries more meaning and is faster to parse than several paragraphs of text. Default to visual structures for architecture, processes, comparisons, and data distributions; use text only for what cannot be shown visually.

The templates support two primary visualization tools:

- **Mermaid** — flowcharts, sequence diagrams, state diagrams, Gantt charts, and more
- **Chart.js** — bar charts, line charts, pie charts, radar charts, and data-driven graphics

## Mermaid diagrams in HTML

The template includes [Mermaid](https://mermaid.js.org) loaded from CDN (`https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs`, ~3.3MB, browser-cached across pages). Use `<pre class="mermaid">` to render diagrams directly in HTML:

```html
<pre class="mermaid">
graph LR
  A[Start] --> B{Decision}
  B -->|Yes| C[Action]
  B -->|No| D[End]
</pre>
```

### When to use Mermaid

- **Flowcharts**, **sequence diagrams**, **state diagrams**, **class diagrams** — any structural/behavioral visualization
- **Gantt charts**, **pie charts**, **timelines** — quantitative or temporal data
- **C4 architecture diagrams**, **ER diagrams**, **mindmaps** — architecture and data modeling
- **Git graphs**, **user journeys**, **quadrant charts** — process and analysis views

Prefer Mermaid over ASCII art, text descriptions, or static SVG mockups.

### Theme adaptation

The template auto-detects `prefers-color-scheme` and sets Mermaid's theme to `default` (light) or `dark` accordingly. On OS-level theme change, the page reloads to re-render diagrams.

### Limitations

- **CDN dependency**: Mermaid JS (~3.3MB) is loaded from jsDelivr at first open. Subsequent HTML files sharing the same CDN URL reuse the browser cache.
- **`securityLevel: strict`** is the default — click/hover interactions on diagram nodes are disabled. Change to `"loose"` if user-trusted diagrams need interactivity.
- **Dynamic content**: If diagram definitions are inserted via `innerHTML` after page load, call `await mermaid.run()` manually instead of relying on `startOnLoad`.
- Not suitable for very short replies or pure-code outputs — only use Mermaid when a diagram genuinely improves understanding.

## Chart.js in HTML

The `data-report.html` template uses [Chart.js](https://www.chartjs.org/) loaded from CDN (`https://cdn.jsdelivr.net/npm/chart.js@4/dist/chart.umd.min.js`).

### Container height rule (critical)

Every `<canvas>` used by Chart.js **must** be wrapped in a container with an explicit height:

```html
<div style="position:relative;height:240px">
  <canvas id="myChart"></canvas>
</div>
```

Without explicit container height, Chart.js `responsive: true` triggers a ResizeObserver infinite loop that freezes the browser tab. This is a hard rule — no exceptions.

### When to use Chart.js

- **Bar charts** — category comparisons, rankings, volume distributions
- **Line charts** — trends over time, metrics history
- **Pie / doughnut charts** — proportional breakdowns, market share, composition
- **Radar charts** — multi-dimensional comparisons (framework scores, skill matrices)

Prefer Chart.js over static images or ASCII charts for data reports.

## Design constraints (all templates)

These constraints apply to every HTML output, regardless of which template is used:

| # | Constraint | Rationale |
|---|-----------|-----------|
| 1 | **CJK-first font stack** — `"Noto Sans SC"`, `"Source Han Sans SC"` must appear before Latin fonts in `font-family` when content contains Chinese | Better CJK character rendering; essential for Chinese content |
| 2 | **8px baseline grid** — Every `margin`, `padding`, `gap`, `line-height`, and `font-size` should align to multiples of 8px or 4px | Visual rhythm and alignment consistency |
| 3 | **Color contrast ≥ 4.5:1** per WCAG AA — text on background must pass; use a contrast checker mindset | Accessibility baseline |
| 4 | **No pure black; use pure white sparingly** — Use `#141413` instead of `#000000`. Prefer `#FAF9F5` for page backgrounds; `#FFFFFF` is acceptable for card surfaces when it improves readability | Softer, more natural reading experience without sacrificing contrast |
| 5 | **Must use real data** — No lorem ipsum, no placeholder text that doesn't come from user input | The whole point of HTML output is clarity of real information |
| 6 | **Every interactive element has :focus state** — Buttons, links, and inputs must have visible focus indicators | Keyboard accessibility |
| 7 | **No gratuitous 3D / shadow excess** — Avoid excessive box-shadows, perspective transforms, and bevels unless the specific template calls for them | Keeps output clean and professional |

### Self-critique checklist

Run this before finalizing any HTML output:

1. Are fonts CJK-first if content contains Chinese?
2. Does every spacing value fall on an 8px (or 4px) multiple?
3. Is the contrast between every text/background pair ≥ 4.5?
4. Is all data real (no lorem ipsum, no fabricated numbers)?
5. Does every button/link/input have a visible `:focus` style?
6. Is the output readable at 320px viewport width?
7. Is the file self-contained (no external CSS files, all inline)?

## Scenario decision table

| User request | Output format | Reason |
|--------------|---------------|--------|
| "Explain this PR" | HTML | Benefits from visual diff explanation and annotations |
| "Help me write a weekly report" | HTML | Benefits from charts, sections, and skim-friendly formatting |
| "How does this code work?" | HTML | Benefits from diagrams, annotated snippets, and clearer structure |
| "Compare A and B" | HTML | Side-by-side comparison is easier in HTML |
| "What time is it?" | Markdown | Pure answer, no layout needed |
| "How do I install X?" | HTML if long; Markdown if short | Depends on how much scaffolding the explanation needs |
| "Tune this prompt/config/design" | HTML (interactive-tuner) | Interaction and live preview can help |
| "Chart this data" / "Visualize this CSV" | HTML (data-report) | Chart.js + KPI cards + table |
| "Turn this spreadsheet into a report" | HTML (data-report) | Structured data visualization |
| "Post this to a chat platform" | Markdown | Native Markdown rendering is more reliable on most platforms |

## Common pitfalls

- **Do not use HTML every time**: short answers are often better in Markdown.
- **Do not over-attribute claims**: separate what the source explicitly says from your own derived guidance.
- **Avoid excessive interactivity**: controls should serve a clear reading or editing purpose.
- **Remember the tradeoffs**: HTML can be slower to generate and harder to diff in version control.
- **Watch file size**: very long HTML is often worse than multiple files or a carefully collapsed single file.
- **Do not force dark mode**: dark mode is not the default recommendation implied by Thariq's examples.
- **Expect higher token usage**: HTML generation is typically 2-4x slower and uses significantly more tokens than Markdown (Thariq's own estimate). For frequent or batch artifact generation, this cost compounds.
- **Consider accessibility**: the default template looks polished but does not include focus-visible styles, skip-to-content links, ARIA landmarks, or `prefers-reduced-motion` adaptation. Add these when the output is intended for public or diverse audiences.

## References

- `references/thariq-original-claims.md` — source-faithful summary of the original post, its sections, FAQ tradeoffs, and community discussion
- `templates/default-report.html` — general report template with a light default theme and adaptive dark mode
- `templates/data-report.html` — Chart.js-powered data visualization with KPI cards and insight blocks
- `templates/code-review.html` — PR review template with diff display, severity markers, and risk matrix
- `templates/deck-simple.html` — horizontal-slide presentation with keyboard navigation and progress bar
- `templates/comparison.html` — side-by-side option comparison with tradeoff callouts
- `templates/interactive-tuner.html` — interactive controls with live preview and copy-back
