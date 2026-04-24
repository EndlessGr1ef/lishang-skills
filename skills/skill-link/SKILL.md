---
name: skill-link
description: Manage symlinks, audit health, and merge skills across AI coding tools. Triggers on "symlink", "skill link", "skill audit", "merge skills", "skill health", "符号连接", "skill 审计", "skill 合并", "skill 健康", or any mention of consolidating/sharing skills or agent rules between tools.
---

# Skill Link

Centralized management for **agent rules**, **skill symlinks**, **health auditing**, and **merge consolidation** across AI coding tools. One source of truth, all tools in sync.

## Why

AI coding tools each read agent rules and skills from their own directories. Without symlinks, you maintain N copies. With symlinks, one edit propagates everywhere. As skills accumulate, audit and merge keep them lean and relevant.

## Architecture

```
~/.agents/                    ← Source of truth
├── AGENTS.md                 ← Real rules file (all tools read this)
├── skills/
│   ├── skill-a/              ← Real skill directory
│   └── skill-b/              ← Real skill directory
│
~/.claude/                    ← Claude Code
├── CLAUDE.md → ~/.agents/AGENTS.md          ← rules symlink
├── skills/
│   ├── skill-a → ../../.agents/skills/skill-a   ← skill symlink
│   └── claude-only-skill/     ← tool-specific (real dir)
│
~/.opencode/                  ← OpenCode
├── AGENTS.md → ~/.agents/AGENTS.md          ← rules symlink
├── skills/
│   └── skill-a → /abs/path/.agents/skills/<name>
```

**Source of truth:** `~/.agents/` holds both the canonical AGENTS.md and shared skills. Tool-specific items remain as real files/dirs in their own location.

## Rules file mapping

Each tool reads a differently-named rules file. This skill maps them all to `~/.agents/AGENTS.md`:

| Tool | Rules path | Symlink target |
|------|-----------|----------------|
| Claude Code | `~/.claude/CLAUDE.md` | `~/.agents/AGENTS.md` |
| OpenCode | `~/.opencode/AGENTS.md` | `~/.agents/AGENTS.md` |

## Default Behavior

When the user mentions skill-hub topics (symlink, skill link, audit, etc.) but **does not specify a subcommand**, follow this flow:

1. **Run `sync.sh status`** — show current state (rules links, skills, per-tool breakdown)
2. **Based on status output, guide the user:**
   - If **broken links or unlinked skills found** → suggest `doctor` or `link <name>`
   - If **duplicate real dirs found** → suggest `consolidate`
   - If **stale/dormant skills present** → suggest `audit`
   - If everything looks healthy → ask what they want to do: "Everything looks good. Want to audit, merge skills, or check something else?"

Never silently execute write operations (init, link, unlink, merge, consolidate) without explicit user confirmation.

## Commands

Run: `bash ~/.agents/skills/skill-hub/scripts/sync.sh <command>`

### Symlink Management

#### `status` — Full overview

Shows both rules and skill state:
- Rules symlinks: linked / broken / missing / real file
- Source skills and which tools have them
- Per-tool breakdown: symlinks vs real dirs vs broken links
- Unlinked source skills (exist in `~/.agents/skills/` but missing in some tools)
- Duplicate real dirs (same skill name in multiple tool dirs)

#### `init` — First-time setup

Sets up all rules symlinks + links all source skills to all tools. Idempotent — skips anything already correctly linked.

#### `link <name>` — Link one skill across all tools

If the skill exists in `~/.agents/skills/<name>`, creates symlinks in each tool's skills dir. If it only exists in a tool dir, offers to move it to source first.

#### `unlink <name>` — Remove skill symlinks

Removes symlinks for the given skill from all tool dirs. Source in `~/.agents/skills/` is preserved.

#### `link-rules` — Set up agent rules symlinks

Creates the rules file symlinks listed in the mapping table above. Idempotent — skips if already correct.

#### `unlink-rules` — Remove agent rules symlinks

Removes all rules file symlinks. The source `~/.agents/AGENTS.md` is preserved.

#### `consolidate` — Deduplicate skills

Scans all tool skill dirs for real directories that duplicate source skills. For each duplicate:
1. If `~/.agents/skills/<name>` doesn't exist: move real dir to source, create symlink
2. If source exists: offer to remove the tool's real dir and replace with symlink

Interactive — asks for confirmation before each change.

#### `doctor` — Diagnose problems

Checks for:
- Broken symlinks (target doesn't exist)
- Rules symlinks pointing to wrong target
- Orphan symlinks (skill removed from source but symlink remains)
- Circular symlink chains

### Auditing

#### `audit` — Scan, classify, evaluate skills

Analyzes all skills in `~/.agents/skills/` and produces a comprehensive health report:

**Data collected per skill:**
- Size, file count, SKILL.md line count
- YAML frontmatter validity (name + description fields)
- Description quality (missing / short / ok / verbose)
- Size tier (tiny / small / medium / large / huge)
- Activity level (recent / active / stale / dormant) based on mtime
- Symlink status across tools
- Presence of scripts/ and reference/ directories

**Report sections:**
1. **Health Overview** — count of healthy / warning / issue skills
2. **Per-Skill Details** — one-line status with all metrics
3. **Size Heat Map** — skills grouped by size bracket
4. **Stale Skills** — skills inactive >30 days
5. **Context Cost Estimate** — total description tokens injected per session
6. **LLM Merge Analysis Prompt** — pre-built prompt to paste into an LLM for merge recommendations

**Example:**
```bash
bash ~/.agents/skills/skill-hub/scripts/sync.sh audit
```

### Merging

#### `merge <s1> <s2> [s3...]` — Interactive merge wizard

Merges multiple skills into one with a guided interactive process. Minimum 2 skills required.

**Wizard steps:**

1. **Review Candidates** — list all skills to merge with size and description summary
2. **Name the Merged Skill** — auto-suggest based on common prefix, or enter custom name
3. **SKILL.md Merge Strategy** — choose how descriptions are combined:
   - `[1] Unified` — single description covering all triggers (recommended)
   - `[2] Sectioned` — each original skill as a section within one SKILL.md
   - `[3] Custom` — placeholder SKILL.md, write it yourself
4. **Directory Structure** — choose how files are organized:
   - `[1] Flat` — all files in root (simple, may conflict)
   - `[2] Namespaced` — subdir per original skill (recommended, zero conflict)
   - `[3] By type` — scripts/, reference/, templates/
5. **File Conflict Scan** — detect and resolve filename conflicts interactively
6. **Symlink Update Plan** — show which symlinks will be removed and created
7. **Final Confirm + Backup** — review all decisions, auto-backup before execution
8. **Execute** — create merged skill, remove originals, update symlinks

**Rollback:** Every merge creates a tar backup in `/tmp/`. The rollback command is printed after execution.

**Example:**
```bash
bash ~/.agents/skills/skill-hub/scripts/sync.sh merge opencli-explorer opencli-oneshot opencli-operate opencli-repair opencli-usage
```

## Typical workflows

### First-time setup on a new machine

```bash
bash ~/.agents/skills/skill-hub/scripts/sync.sh init
```

### After creating a new shared skill

```bash
# 1. Create in source
mkdir -p ~/.agents/skills/my-new-skill
# ... write SKILL.md ...

# 2. Link everywhere
bash ~/.agents/skills/skill-hub/scripts/sync.sh link my-new-skill
```

### After editing AGENTS.md

No action needed — all tools read the same file via symlinks.

### Check everything is healthy

```bash
bash ~/.agents/skills/skill-hub/scripts/sync.sh doctor
```

### Audit skill health and find merge candidates

```bash
bash ~/.agents/skills/skill-hub/scripts/sync.sh audit
# Then paste the LLM Merge Analysis Prompt into a chat for recommendations
```

### Merge related skills

```bash
bash ~/.agents/skills/skill-hub/scripts/sync.sh merge skill-a skill-b
# Follow the interactive wizard steps
```

### Adding a tool-specific skill

Create it directly in that tool's skills dir. No symlink needed.

## Symlink path conventions

- `~/.claude/skills/`: **relative** paths (`../../.agents/skills/<name>`)
- `~/.opencode/skills/`: **absolute** paths
- Rules files: **absolute** paths (simpler and more reliable)

## Safety

- `consolidate` is interactive — never deletes without confirmation
- `merge` creates tar backup before any changes — always recoverable
- Broken symlinks are reported but not auto-deleted
- Tool-specific items (only in one tool's dir) are never touched by `link` or `consolidate`
- `init` and `link-rules` skip if symlink already correct — won't overwrite
- `unlink` only removes symlinks, never real directories
