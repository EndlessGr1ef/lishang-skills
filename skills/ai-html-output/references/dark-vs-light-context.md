# Dark vs Light Theme Choices for AI-Generated HTML

> Record date: 2026-05-13
> Source: conversation prompted by the user's question, "Why should HTML use a dark background?"

## Conclusion

**Thariq Shihipar never recommended dark mode.** The 20 examples on his companion site, `thariqs.github.io/html-effectiveness/`, all use a light theme: ivory `#FAF9F5` background plus dark gray `#141413` text.

Dark mode became the "default aesthetic" for AI-generated HTML through conventions that emerged organically in the developer ecosystem.

## Three reasons dark mode became popular

### 1. Developer tools have broadly moved to dark themes

The tools developers use every day are mostly dark:

- VS Code, such as the default Dark Modern theme
- Terminals with black backgrounds
- GitHub, where dark mode has become a mainstream preference
- Claude Code CLI, which runs in a terminal and is naturally dark
- X/Twitter, where many developer users prefer dark mode

When AI is asked to generate "developer-friendly HTML", the strong training-data association between "developer tools" and "dark mode" naturally pushes output toward dark themes.

### 2. Dark mode implies "professional" in developer-tool contexts

Terminals, IDEs, database clients, and monitoring dashboards are often dark. In model training data, this creates an implicit association:

- Dark theme -> professional developer tool
- Light theme -> ordinary website or document

This hidden association makes AI models proactively choose dark palettes when generating technical HTML outputs.

### 3. Code highlighting is easier to control on dark backgrounds

AI-generated HTML often contains a lot of syntax-highlighted code. A dark background plus bright highlights such as blue, green, and orange tends to produce more consistent contrast than a white background. Models are less likely to fail visually on dark themes; light themes are more prone to inconsistent contrast.

## Correct choice

| Scenario | Recommended baseline | Reason |
|----------|----------------------|--------|
| Code review / PR summary | Light theme, or user preference | Thariq's examples are all light themed |
| Technical proposal / plan | Light first, adaptive dark mode | Long-form documents are often easier to read on light backgrounds |
| Data report / weekly update | Light first | Charts are usually more readable on light backgrounds |
| Terminal/CLI tool output | Dark theme | Matches the surrounding usage context |
| Developer-tool documentation | Follow the user's system preference | Use `prefers-color-scheme` |
| Internal developer-only artifact | Dark theme is acceptable | Matches the surrounding toolchain context |

**Best practice**: Support both modes with `@media (prefers-color-scheme: dark)` and default to light. This respects the user's system setting while avoiding a dark background that may feel jarring to readers who are not used to developer-tool aesthetics.

## CSS example: dual-theme approach

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

## References

- Thariq's example site: https://thariqs.github.io/html-effectiveness/
- Simon Willison's link-blog analysis: https://simonwillison.net/2026/May/8/unreasonable-effectiveness-of-html/
- Hacker News discussion thread: search for "The Unreasonable Effectiveness of HTML"
