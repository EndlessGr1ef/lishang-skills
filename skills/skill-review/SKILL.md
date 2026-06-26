---
name: skill-review
description: Review a skill file (SKILL.md) and remove no-op instructions that do not change agent behavior. Use when asked to review a skill file, audit a skill's instructions for effectiveness, clean up vague instructions, or ensure every rule in a skill is behavior-changing and testable. Also use when creating or editing skills to verify they only contain concrete, actionable instructions.
---

# Skill Review

Use this skill to review another skill file and remove instructions that do not change agent behavior.

## Goal

Find no-op instructions and rewrite them into concrete, testable rules.

A no-op is an instruction that sounds good but would not noticeably change the agent's output.

Examples:

* "Be thorough"
* "Write clearly"
* "Make it easy to read"
* "Use good judgment"
* "Create a detailed commit message"

Agents already try to do these things. Keep an instruction only if it changes a decision, adds a constraint, or defines a checkable output.

## Review Tests

For each suspicious line, ask:

1. **Deletion test**
   If this line is removed, would the output likely change?

2. **Behavior test**
   What specific behavior does this line cause or prevent?

3. **Verification test**
   Can a reviewer tell whether the instruction was followed?

If the answer is unclear, flag the line.

## What to Flag

Flag:

* vague quality words: "clear", "robust", "thorough", "simple", "high quality"
* default behavior: "answer the user", "avoid mistakes", "be helpful"
* motivational text
* repeated rules
* conflicting goals with no priority
* long explanations that do not add execution rules

## How to Rewrite

Replace vague goals with observable requirements.

Bad:

```md
Make the commit message very detailed.
```

Good:

```md
Commit messages must include: summary, motivation, changed files, tests run, and known risks.
```

Bad:

```md
Be thorough when reviewing code.
```

Good:

```md
When reviewing code, check correctness, error handling, security, performance, tests, and API clarity.
```

Bad:

```md
Make the implementation easy to read.
```

Good:

```md
Use descriptive names, avoid nesting deeper than 2 levels, and split functions over 60 lines unless splitting reduces clarity.
```

## Output Format

```md
## Skill Review

Overall verdict: [Good / Needs cleanup / No-op heavy]

## No-op Findings

### 1. [quote the line]

Problem:
[why it does not change behavior]

Recommendation:
[Delete it or replace it with a concrete rule]

Suggested rewrite:
[exact replacement text]

## Keep

- [rules that are specific, useful, and behavior-changing]

## Cleaned-up Version

[rewrite the reviewed section with no-ops removed]
```

## Final Rule

Do not tell the skill author to "be clearer" or "be more specific".

Show the exact line to delete or the exact replacement to use.
