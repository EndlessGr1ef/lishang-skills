# Thariq Shihipar's Original Post and Community Discussion

> Record date: 2026-05-13
> Original: Thariq Shihipar (`trq212`) on X, "Using Claude Code: The Unreasonable Effectiveness of HTML"
> Link: https://x.com/trq212/status/2052809885763747935

## Important note on scope

This file aims to stay close to the structure and wording of Thariq's original post. It separates:

- **What Thariq explicitly argues in the post**
- **What is later interpretation, synthesis, or community reaction**

## Intro framing from the post

Thariq starts by acknowledging why Markdown became dominant for agent output:

- simple
- portable
- somewhat rich
- easy for humans to edit

He then argues that as agents become more powerful, Markdown increasingly feels restrictive for artifacts such as specs, reference files, brainstorming outputs, and explainers. He specifically says he finds Markdown files over roughly 100 lines difficult to read, wants richer visualizations and diagrams, and increasingly edits through Claude rather than by hand.

## The post's actual argument structure

The original post is organized around the following sections.

### 1. Information Density

Thariq argues that HTML can convey much richer information than Markdown. He lists examples such as:

- tabular data using tables
- design data with CSS
- illustrations with SVG
- code snippets with script tags
- interactions using HTML elements with JavaScript + CSS
- workflows using SVG and HTML
- spatial data using absolute positioning and canvases
- images using image tags

He goes so far as to argue that there is almost no information Claude can read that cannot be represented fairly efficiently with HTML.

He also contrasts this with Markdown workarounds such as ASCII diagrams and even Unicode-based color approximation. One of the attached images is explicitly captioned:

> "Claude Code trying to show color in markdown"

### 2. Visual Clarity & Ease of Reading

Thariq argues that long HTML documents are much easier to read than long Markdown documents because Claude can structure them visually with:

- tabs
- illustrations
- links
- responsive layout

A key point here is personal and practical, not universal: he says that in practice he tends not to read Markdown files longer than about 100 lines and cannot get many others in his organization to read them either.

### 3. Ease of Sharing

Thariq argues that HTML is easier to share because browsers render it natively. By contrast, Markdown often needs an editor, renderer, or attachment workflow.

His concrete sharing model is:

- generate an HTML file
- upload it somewhere such as S3
- share a link that colleagues can open directly

He explicitly claims that the chance of someone actually reading a spec, report, or PR writeup is much higher if it is in HTML.

### 4. Two-way Interaction

This is one of the most important parts of the post and is easy to understate.

Thariq is not only talking about prettier documents. He is also talking about **interactive artifacts** that let the user manipulate parameters and then feed those edits back into the workflow.

Examples he gives or implies include:

- sliders or knobs to adjust a design
- controls to tweak algorithm options and see what happens
- ways to copy those changes back into a prompt for Claude Code

He links to a separate playgrounds post as an example of this two-way interaction.

### 5. Data Ingestion

This is another distinctive part of the post.

Thariq asks why someone would use Claude Code for HTML generation instead of other Claude surfaces, and answers: because Claude Code can ingest so much context.

He specifically mentions:

- the file system
- MCPs such as Slack and Linear
- browser context
- git history

He gives an example from the post itself: asking Claude Code to scan his code folder, find generated HTML files, group and categorize them, and then create an HTML file with diagrams representing each type.

### 6. It’s Joyful

This section is short but real. Thariq says making HTML documents with Claude is simply more fun and makes him feel more involved and invested in the creation process.

This is not a technical argument so much as a workflow-affect argument.

## How to Get Started

Thariq explicitly says people do **not** need to over-formalize this immediately.

He even says he is a little afraid people will turn the post into a `/html` skill. His advice is that people can often start simply by asking for:

- "make an HTML file"
- "make an HTML artifact"

His suggested starting point is to learn what you want the artifact to do, prompt from scratch for a while, and only later formalize reusable patterns if needed.

## Use-case structure in the post

Thariq groups his examples into these buckets:

| # | Category | Examples |
|---|---|---|
| 01 | Exploration & Planning | explorations of options, visual design directions, implementation plans |
| 02 | Code Review & Understanding | annotated PRs, PR explanations, code understanding |
| 03 | Design | design systems, component variants |
| 04 | Prototyping | animation sandboxes, clickable flows |
| 05 | Illustrations & Diagrams | SVG figure sheets, annotated flowcharts |
| 06 | Decks | HTML slide decks |
| 07 | Research & Learning | feature explainers, concept explainers |
| 08 | Reports | weekly status, incident timelines |
| 09 | Custom Editing Interfaces | triage boards, feature-flag editors, prompt tuners |

All examples are available at: https://thariqs.github.io/html-effectiveness/

## FAQ tradeoffs from the original post

The FAQ matters because it tempers the enthusiasm of the rest of the post.

### Isn't HTML less token efficient?

Thariq acknowledges that Markdown often uses fewer tokens, but argues that HTML's added expressiveness and higher likelihood of being read make the tradeoff worthwhile for him.

### When do you still use Markdown?

He says he has honestly stopped using Markdown for almost everything and describes himself, implicitly, as being far on the HTML-maximalist side.

This is important because many downstream summaries are more moderate than the original stance.

### Does HTML take longer to generate?

Yes. Thariq explicitly says HTML does take longer, estimating roughly **2-4x longer than Markdown**, but says he finds the results worth it.

### What about version control?

He calls this one of HTML's biggest downsides:

- HTML diffs are noisy
- HTML is harder to review in diff form than Markdown

### How do you get good taste instead of ugly HTML?

He suggests using a design-system reference file derived from the codebase so Claude has a stylistic anchor for future HTML outputs.

## Community reaction

### Simon Willison

In his link-blog post, Simon Willison highlighted the piece as a reason to reconsider defaulting to Markdown for output. He emphasized the benefits of SVG diagrams, in-page navigation, and richer HTML explanations.

### Hacker News

The Hacker News discussion broadly split into three positions:

- **Supportive**: Markdown really does flatten many outputs, while HTML can better carry spatial or highly structured information.
- **Critical**: HTML may be less token-efficient, less editable, and too visually "finished".
- **Compromise**: Markdown may still be useful as a working format, with HTML as a delivery format.

## Bottom-line interpretation

A careful reading of the post suggests:

1. Thariq's strongest explicit themes are **information density, readability, sharing, interactivity, context ingestion, and workflow enjoyment**.
2. He is personally much more HTML-maximalist than many later summaries.
3. The post is enthusiastic but not cost-free: it explicitly admits **slower generation** and **poor diff ergonomics**.
4. Many practical team guidelines derived from the post are reasonable, but they should not be mistaken for Thariq's exact wording.
