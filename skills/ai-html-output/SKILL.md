---
name: ai-html-output
description: Use HTML instead of Markdown as an AI output format for reports, code reviews, technical plans, research summaries, status updates, and similar deliverables. Includes Mermaid diagram support via CDN, interactive zoom/pan, diagram density rules, and a template skeleton with light/dark theme conventions.
version: 2.1.0
---

# AI HTML Output

Use HTML instead of Markdown when AI output needs to be interactive, navigable, easy to scan, and easy to share.

> **Core philosophy**: HTML is not just "fancy Markdown". It is a medium for laying out information in space. Markdown is often better for editing; HTML is often better for reading.

## Why HTML

HTML output trades generation speed for reader experience:

- **Information density** — side-by-side columns, KPI strips, and grid layouts show more per viewport than linear Markdown
- **Visual clarity** — color, spacing, typography, and diagrams make structure immediately apparent
- **Interactivity** — collapsible sections, zoomable diagrams, tabbed views, and live controls let readers explore at their own pace
- **Shareability** — a single self-contained `.html` file opens in any browser, no build step or renderer needed

The tradeoff: HTML takes longer to generate and uses more tokens than Markdown. Use it when the output benefits from layout, visuals, or interaction — not as a default.

## When to Use HTML

| Scenario | Why HTML wins |
|----------|--------------|
| Code reviews / PR summaries | Diff comparison, severity markers, jump links, review guidance |
| Technical proposals / implementation plans | Timelines, data-flow diagrams, risk tables, mockups |
| Knowledge explanations / research summaries | TL;DR boxes, collapsible steps, annotated snippets, diagrams |
| Status reports / weekly updates | Shipped/slipped work, charts, skim-friendly layout |
| Comparative analysis | Side-by-side option comparison with trade-off annotations |
| Interactive tuning artifacts | Sliders, knobs, previews, or copy-back controls for prompts, configs, or designs |
| Structured editing interfaces | Triage boards, feature-flag editors, dataset curation views, or approval tools |
| Data visualization / charting | Chart.js + KPI cards + tables |
| Architecture / system explanations | Mermaid diagrams + annotated component tables |

## When NOT to Use HTML

- **Short messages / simple answers** — two or three sentences do not need extra structure
- **Plain code snippets** — when the code stands on its own without explanation
- **User explicitly requests Markdown** — for editing, copying, or pasting into a wiki
- **Version-controlled working docs** — Markdown diffs are often cleaner and easier to review
- **Quick iteration** — HTML takes longer to generate than Markdown
- **Platform-native sharing** — some social platforms and chat tools render Markdown natively but strip or mangle HTML

## Quick Start

### File output convention

When generating an HTML artifact as a file, save it to an `html/` folder in the current working directory:

```
./html/{descriptive-name}.html
```

If the `html/` directory does not exist, create it. This keeps generated artifacts organized and separate from source files.

### Template skeleton

The following is a general-purpose HTML output template that works for many scenarios. Key traits:

1. Single-file and self-contained with inline CSS
2. **Light theme by default** with automatic dark-mode support through `prefers-color-scheme`
3. No build-time dependencies; opens directly in a browser (Mermaid is loaded from CDN at runtime)
4. Support for collapsible sections, inline code highlighting, tables, and SVG charts
5. Built-in [Mermaid](https://mermaid.js.org) diagram rendering via CDN import

Use `templates/default-report.html` as a starting point for copy-and-modify workflows.

**Template placeholders** — the template uses these variables that must be replaced with actual content:

| Placeholder | Purpose | Example |
|-------------|---------|---------|
| `{TITLE}` | Page `<title>` and top-level `<h1>` heading | "Q1 2026 Status Report" |
| `{CATEGORY}` | Pill label in the topbar — describes the artifact type | "Code Review" |
| `{DATE}` | Display date in the header meta row | "May 15, 2026" |
| `{CONTENT}` | The entire main body — HTML content that replaces this placeholder inside `<main class="content">` | Full sections, tables, diagrams, etc. |

### Color scheme

Light theme is the default. Dark mode adapts automatically via `@media (prefers-color-scheme: dark)`.

| Role | Light default | Dark adaptive |
|------|---------------|---------------|
| Background | `#FAF9F5` | `#0D1117` |
| Card | `#FFFFFF` | `#161B22` |
| Body text | `#3D3D3A` | `#E6EDF3` |
| Heading | `#141413` | `#F0F6FC` |
| Accent | `#D97757` warm terracotta | `#58A6FF` blue |
| Border | `#D1CFC5` | `#30363D` |

## Data Visualization

**Diagram density rule**: HTML output is for human eyes — it must be visually rich. Every HTML artifact should contain **at least 1 diagram per major section** (Mermaid or Chart.js). If a section has 3+ paragraphs of prose describing a process, architecture, data flow, comparison, or sequence, it almost certainly needs a diagram. Common patterns that demand diagrams:

| Prose pattern | Diagram type | Example |
|--------------|-------------|---------|
| "X calls Y, then Y calls Z…" | Mermaid sequence diagram | Service call chain |
| "The flow goes from A to B to C…" | Mermaid flowchart | Pipeline / workflow |
| "There are N phases/stages…" | Mermaid flowchart or state diagram | Phase overview |
| "X consists of these components…" | Mermaid flowchart or C4 diagram | Architecture overview |
| "Compared to the old system…" | Mermaid flowchart (before/after) or comparison table | Migration diff |
| "The formula / algorithm works as…" | Mermaid flowchart for logic + formula box for math | Computation pipeline |
| "Numbers increased / decreased…" | Chart.js line or bar chart | Trends, metrics |
| "Breakdown by category…" | Chart.js pie / doughnut / bar | Distribution |
| "X has these dimensions…" | Chart.js radar | Multi-axis comparison |

**Visual-first principle**: HTML is for human consumption. When information can be expressed visually — flows, relationships, sequences, hierarchies, trends, proportions — always prefer charts and diagrams over paragraphs. A single visual often carries more meaning and is faster to parse than several paragraphs of text. Default to visual structures for architecture, processes, comparisons, and data distributions; use text only for what cannot be shown visually.

The templates support two primary visualization tools:

- **Mermaid** — flowcharts, sequence diagrams, state diagrams, Gantt charts, and more
- **Chart.js** — bar charts, line charts, pie charts, radar charts, and data-driven graphics

### Mermaid diagrams

The template includes [Mermaid](https://mermaid.js.org) loaded from CDN (`https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs`, ~3.3MB, browser-cached across pages) plus [mermaid-enhancements](https://www.npmjs.com/package/@mostlylucid/mermaid-enhancements) for interactive zoom/pan and fullscreen lightbox. Export buttons and mouse-wheel zoom are intentionally disabled — use toolbar +/- buttons to zoom. Use `<pre class="mermaid">` or `<div class="mermaid">` to render diagrams:

```html
<pre class="mermaid">
graph LR
  A[Start] --> B{Decision}
  B -->|Yes| C[Action]
  B -->|No| D[End]
</pre>
```

#### Interactive features (via mermaid-enhancements)

Every rendered diagram automatically gets a toolbar with:

| Feature | Description |
|---------|-------------|
| **Zoom in/out** | Toolbar +/− buttons only — mouse-wheel zoom is disabled so page scrolling works naturally when hovering over diagrams |
| **Pan** | Drag to pan around large diagrams; toggle pan mode via toolbar |
| **Reset zoom** | One-click return to fit-to-view |
| **Fullscreen lightbox** | Opens diagram in an immersive overlay for maximum readability |

Export (PNG/SVG) buttons are disabled by default. Touch support: pinch-to-zoom and swipe-to-pan work on mobile/tablet.

#### When to use Mermaid

- **Flowcharts**, **sequence diagrams**, **state diagrams**, **class diagrams** — any structural/behavioral visualization
- **Gantt charts**, **pie charts**, **timelines** — quantitative or temporal data
- **C4 architecture diagrams**, **ER diagrams**, **mindmaps** — architecture and data modeling
- **Git graphs**, **user journeys**, **quadrant charts** — process and analysis views

Prefer Mermaid over ASCII art, text descriptions, or static SVG mockups.

#### Theme adaptation

The template auto-detects `prefers-color-scheme` and sets Mermaid's theme to `default` (light) or `dark` accordingly. On OS-level theme change, the page reloads to re-render diagrams. The enhancement toolbar also adapts to the active theme via CSS custom properties.

#### Node click interactions

For diagrams that need click-to-navigate or click-to-expand behavior, `securityLevel` is set to `'loose'` by default in the templates. Use Mermaid's built-in `click` directive:

```
graph TD
  A[Service A] --> B[Service B]
  click A "/details/service-a" "View Service A details"
  click B callback "Click for details"
```

The `callback` function must be defined in a `<script>` block on the page. This works alongside the zoom/pan toolbar — clicks on nodes trigger the callback, while clicks on empty space allow panning.

#### Technical notes

The initialization uses a three-step approach:

1. **Mermaid renders SVGs** — `mermaid.initialize()` + `mermaid.run()` renders all `.mermaid` elements
2. **Enhancement wraps SVGs** — `configure({ controls: { export: false } })` disables export buttons, then `enhanceMermaidDiagrams()` adds zoom/pan toolbar and fullscreen lightbox
3. **Wheel event interception** — a capture-phase `wheel` listener on `.mermaid-wrapper` elements calls `stopImmediatePropagation()` to prevent svg-pan-zoom from intercepting scroll, so normal page scrolling works when the cursor is over a diagram

This is necessary because `@mostlylucid/mermaid-enhancements` bundles its own dependencies (svg-pan-zoom, html-to-image) but does not bundle mermaid itself. The ESM module scope means `init()` cannot access a separately-imported mermaid instance, so we render first and enhance after.

#### Limitations

- **CDN dependency**: Mermaid JS (~3.3MB) + mermaid-enhancements (~51KB) are loaded from CDN at first open. Subsequent HTML files sharing the same CDN URLs reuse the browser cache.
- **No node collapse/expand**: mermaid-enhancements provides zoom/pan/fullscreen but does not support collapsing subgraphs or folding node groups. For that level of interaction, consider Path B (custom svg-pan-zoom + DOM manipulation) or a different diagram engine.
- **Mouse-wheel zoom disabled by design**: The library ties mouse-wheel zoom to pan state with no independent toggle. A capture-phase `wheel` event interceptor prevents svg-pan-zoom from handling scroll, keeping normal page scroll behavior. Zoom is available only via toolbar +/− buttons.
- **Export disabled by design**: PNG/SVG export buttons are removed via `configure({ controls: { export: false } })` to keep the toolbar minimal.
- **Dynamic content**: If diagram definitions are inserted via `innerHTML` after page load, call `await init()` again or call `enhanceMermaidDiagrams()` separately. You must also re-attach the wheel event interceptor on any new `.mermaid-wrapper` elements.
- Not suitable for very short replies or pure-code outputs — only use Mermaid when a diagram genuinely improves understanding.

### Chart.js

The `data-report.html` template uses [Chart.js](https://www.chartjs.org/) loaded from CDN (`https://cdn.jsdelivr.net/npm/chart.js@4/dist/chart.umd.min.js`).

#### Container height rule (critical)

Every `<canvas>` used by Chart.js **must** be wrapped in a container with an explicit height:

```html
<div style="position:relative;height:240px">
  <canvas id="myChart"></canvas>
</div>
```

Without explicit container height, Chart.js `responsive: true` triggers a ResizeObserver infinite loop that freezes the browser tab. This is a hard rule — no exceptions.

#### When to use Chart.js

- **Bar charts** — category comparisons, rankings, volume distributions
- **Line charts** — trends over time, metrics history
- **Pie / doughnut charts** — proportional breakdown, market share, composition
- **Radar charts** — multi-dimensional comparisons (framework scores, skill matrices)

Prefer Chart.js over static images or ASCII charts for data reports.

## Design Constraints

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
| 8 | **Page max-width ≥ 1280px when sidebar TOC is used** — Sidebar layouts (220px TOC + content) need more room: at 1080px the content column is only ~860px, which crushes wide tables and code blocks. Use `max-width: 1280px` on `.page` and add `overflow-x: auto` on `.content` at the sidebar breakpoint so tables scroll horizontally instead of wrapping | Long tables, code blocks, and Mermaid diagrams need horizontal breathing room |

### Self-critique checklist

Run this before finalizing any HTML output:

1. Are fonts CJK-first if content contains Chinese?
2. Does every spacing value fall on an 8px (or 4px) multiple?
3. Is the contrast between every text/background pair ≥ 4.5?
4. Is all data real (no lorem ipsum, no fabricated numbers)?
5. Does every button/link/input have a visible `:focus` style?
6. Is the output readable at 320px viewport width?
7. Is the file self-contained (no external CSS files, all inline)?
8. Does every major section have at least 1 diagram? If any section has 3+ paragraphs of process/flow/comparison prose without a diagram, add one.

## Common Pitfalls

- **Do not use HTML every time**: short answers are often better in Markdown.
- **Avoid excessive interactivity**: controls should serve a clear reading or editing purpose.
- **Watch file size**: very long HTML is often worse than multiple files or a carefully collapsed single file.
- **Do not force dark mode**: light theme is the default; dark mode adapts via `prefers-color-scheme`.
- **Consider accessibility**: the default template looks polished but does not include focus-visible styles, skip-to-content links, ARIA landmarks, or `prefers-reduced-motion` adaptation. Add these when the output is intended for public or diverse audiences.

## References

- `templates/default-report.html` — general report template with a light default theme and adaptive dark mode
- `templates/data-report.html` — Chart.js-powered data visualization with KPI cards and insight blocks
- `templates/code-review.html` — PR review template with diff display, severity markers, and risk matrix
- `templates/deck-simple.html` — horizontal-slide presentation with keyboard navigation and progress bar
- `templates/comparison.html` — side-by-side option comparison with tradeoff callouts
- `templates/interactive-tuner.html` — interactive controls with live preview and copy-back
