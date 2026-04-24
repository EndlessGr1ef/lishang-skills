#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# skill-link — manage symlinks, audit, and merge for agent skills
#              across AI coding tools
# ============================================================

AGENTS_DIR="$HOME/.agents"
AGENTS_SKILLS="$AGENTS_DIR/skills"
SOURCE_RULES="$AGENTS_DIR/AGENTS.md"

# Tool skill directories (name:dir:link_style)
# link_style: "relative" or "absolute"
TOOL_SKILLS=(
  "claude:$HOME/.claude/skills:relative"
  "opencode:$HOME/.opencode/skills:absolute"
)

# Agent rules symlink targets: tool:target_path
RULES_LINKS=(
  "claude:$HOME/.claude/CLAUDE.md"
  "opencode:$HOME/.opencode/AGENTS.md"
  "cursor:$HOME/.cursor/rules/AGENTS.md"
)

# ── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; }

# ── Helpers ─────────────────────────────────────────────────

make_link_target() {
  local tool_dir="$1"
  local skill_name="$2"
  local style="$3"

  if [[ "$style" == "relative" ]]; then
    # ~/X/skills/ → ~/.agents/skills/ is always ../../.agents/skills/
    echo "../../.agents/skills/$skill_name"
  else
    echo "$AGENTS_SKILLS/$skill_name"
  fi
}

is_symlink() { [[ -L "$1" ]]; }
is_dir()     { [[ -d "$1" && ! -L "$1" ]]; }
is_broken()  { [[ -L "$1" && ! -e "$1" ]]; }

get_source_skills() {
  local skills=()
  if [[ -d "$AGENTS_SKILLS" ]]; then
    for d in "$AGENTS_SKILLS"/*/; do
      [[ -d "$d" ]] || continue
      local name
      name=$(basename "$d")
      [[ "$name" == .* ]] && continue
      skills+=("$name")
    done
  fi
  echo "${skills[@]}"
}

# ── Rules commands ─────────────────────────────────────────

cmd_link_rules() {
  info "Setting up agent rules symlinks..."
  echo ""

  if [[ ! -f "$SOURCE_RULES" ]]; then
    err "Source rules file not found: $SOURCE_RULES"
    return 1
  fi

  for entry in "${RULES_LINKS[@]}"; do
    IFS=':' read -r tool target <<< "$entry"
    local dir
    dir=$(dirname "$target")
    mkdir -p "$dir"

    if is_symlink "$target"; then
      local current
      current=$(readlink "$target")
      if [[ "$current" == "$SOURCE_RULES" ]]; then
        ok "$tool: $(basename "$target") → AGENTS.md"
      else
        warn "$tool: $(basename "$target") → $current (expected AGENTS.md)"
        read -rp "  Fix? [y/N] " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
          rm "$target"
          ln -s "$SOURCE_RULES" "$target"
          ok "$tool: fixed → $SOURCE_RULES"
        fi
      fi
    elif [[ -f "$target" ]]; then
      warn "$tool: $(basename "$target") is a real file (not symlinked)"
      local size
      size=$(wc -c < "$target" | tr -d ' ')
      info "  File size: ${size} bytes at $target"
      read -rp "  Replace with symlink to $SOURCE_RULES? [y/N] " ans
      if [[ "$ans" =~ ^[Yy]$ ]]; then
        rm "$target"
        ln -s "$SOURCE_RULES" "$target"
        ok "$tool: $(basename "$target") → $SOURCE_RULES"
      fi
    else
      ln -s "$SOURCE_RULES" "$target"
      ok "$tool: created $(basename "$target") → $SOURCE_RULES"
    fi
  done
}

cmd_unlink_rules() {
  info "Removing agent rules symlinks..."
  echo ""

  for entry in "${RULES_LINKS[@]}"; do
    IFS=':' read -r tool target <<< "$entry"

    if is_symlink "$target"; then
      rm "$target"
      ok "$tool: removed $(basename "$target")"
    elif [[ -f "$target" ]]; then
      warn "$tool: $(basename "$target") is a real file, not touching"
    else
      info "$tool: $(basename "$target") does not exist"
    fi
  done

  echo ""
  warn "Rules file still exists at: $SOURCE_RULES"
}

# ── Skill commands ──────────────────────────────────────────

cmd_link_skill() {
  local skill_name="${1:?Usage: sync.sh link <skill-name>}"
  
  if [[ ! -d "$AGENTS_SKILLS/$skill_name" ]]; then
    local found_in="" found_style=""
    for entry in "${TOOL_SKILLS[@]}"; do
      IFS=':' read -r tool dir style <<< "$entry"
      if is_dir "$dir/$skill_name"; then
        found_in="$dir/$skill_name"
        found_style="$style"
        break
      fi
    done

    if [[ -n "$found_in" ]]; then
      info "Skill '$skill_name' not in source, found at $found_in"
      read -rp "Move to $AGENTS_SKILLS/$skill_name and symlink back? [y/N] " ans
      if [[ "$ans" =~ ^[Yy]$ ]]; then
        mv "$found_in" "$AGENTS_SKILLS/$skill_name"
        ok "Moved to $AGENTS_SKILLS/$skill_name"
        local target
        target=$(make_link_target "$(dirname "$found_in")" "$skill_name" "$found_style")
        ln -s "$target" "$found_in"
        ok "Symlink: $found_in → $target"
      else
        err "Aborted"
        return 1
      fi
    else
      err "Skill '$skill_name' not found anywhere"
      return 1
    fi
  fi

  for entry in "${TOOL_SKILLS[@]}"; do
    IFS=':' read -r tool dir style <<< "$entry"
    local link_path="$dir/$skill_name"

    if is_symlink "$link_path"; then
      if is_broken "$link_path"; then
        warn "$tool: broken symlink, recreating"
        rm "$link_path"
      else
        info "$tool: already linked, skipping"
        continue
      fi
    elif is_dir "$link_path"; then
      warn "$tool: real directory exists at $link_path"
      read -rp "  Replace with symlink? [y/N] " ans
      if [[ ! "$ans" =~ ^[Yy]$ ]]; then
        info "$tool: skipped"
        continue
      fi
      rm -rf "$link_path"
    fi

    local target
    target=$(make_link_target "$dir" "$skill_name" "$style")
    ln -s "$target" "$link_path"
    ok "$tool: $skill_name → $target"
  done
}

cmd_unlink_skill() {
  local skill_name="${1:?Usage: sync.sh unlink <skill-name>}"

  for entry in "${TOOL_SKILLS[@]}"; do
    IFS=':' read -r tool dir style <<< "$entry"
    local link_path="$dir/$skill_name"

    if is_symlink "$link_path"; then
      rm "$link_path"
      ok "$tool: removed symlink for $skill_name"
    elif is_dir "$link_path"; then
      warn "$tool: $skill_name is a real directory, not touching"
    else
      info "$tool: $skill_name does not exist"
    fi
  done
}

cmd_consolidate() {
  info "Scanning for skill duplicates..."
  echo ""

  local -A seen=()
  for entry in "${TOOL_SKILLS[@]}"; do
    IFS=':' read -r tool dir style <<< "$entry"
    [[ -d "$dir" ]] || continue
    for d in "$dir"/*/; do
      [[ -d "$d" ]] || continue
      local name
      name=$(basename "$d")
      [[ "$name" == .* ]] && continue
      seen["$name"]=1
    done
  done

  for name in "${!seen[@]}"; do
    if [[ -d "$AGENTS_SKILLS/$name" ]]; then
      local has_real=0
      for entry in "${TOOL_SKILLS[@]}"; do
        IFS=':' read -r tool dir style <<< "$entry"
        if is_dir "$dir/$name"; then
          has_real=1
          break
        fi
      done
      if [[ $has_real -eq 0 ]]; then
        continue
      fi
    fi

    echo -e "${CYAN}$name${NC}"
    local source_exists=0
    if [[ -d "$AGENTS_SKILLS/$name" ]]; then
      echo "  Source: $AGENTS_SKILLS/$name (exists)"
      source_exists=1
    else
      echo "  Source: $AGENTS_SKILLS/$name (missing)"
    fi

    for entry in "${TOOL_SKILLS[@]}"; do
      IFS=':' read -r tool dir style <<< "$entry"
      local path="$dir/$name"
      if is_symlink "$path"; then
        if is_broken "$path"; then
          err "  $tool: broken symlink → $(readlink "$path")"
        else
          echo -e "  $tool: ${DIM}symlink → $(readlink "$path")${NC}"
        fi
      elif is_dir "$path"; then
        warn "  $tool: REAL DIR at $path"
        local file_count
        file_count=$(find "$path" -type f 2>/dev/null | wc -l | tr -d ' ')
        info "  Contains $file_count files"
        if [[ $source_exists -eq 0 ]]; then
          read -rp "  Move to source and symlink? [y/N] " ans
          if [[ "$ans" =~ ^[Yy]$ ]]; then
            mv "$path" "$AGENTS_SKILLS/$name"
            source_exists=1
            local target
            target=$(make_link_target "$dir" "$name" "$style")
            ln -s "$target" "$path"
            ok "  Moved and linked: $path → $target"
          fi
        else
          read -rp "  DELETE $file_count files and replace with symlink? [y/N] " ans
          if [[ "$ans" =~ ^[Yy]$ ]]; then
            rm -rf "$path"
            local target
            target=$(make_link_target "$dir" "$name" "$style")
            ln -s "$target" "$path"
            ok "  Replaced with symlink: $path → $target"
          fi
        fi
      fi
    done
    echo ""
  done
}

# ── Combined commands ───────────────────────────────────────

cmd_init() {
  echo -e "${CYAN}═══ Agent Link Init ═══${NC}"
  echo ""

  # 1. Rules
  cmd_link_rules
  echo ""

  # 2. Link all source skills
  info "Linking all source skills to all tools..."
  local skills
  skills=$(get_source_skills)
  if [[ -z "$skills" ]]; then
    warn "No source skills found in $AGENTS_SKILLS"
    return
  fi

  for skill_name in $skills; do
    echo ""
    info "Processing: $skill_name"
    for entry in "${TOOL_SKILLS[@]}"; do
      IFS=':' read -r tool dir style <<< "$entry"
      local link_path="$dir/$skill_name"

      if is_symlink "$link_path" && ! is_broken "$link_path"; then
        ok "$tool: $skill_name already linked"
        continue
      fi

      if is_symlink "$link_path" && is_broken "$link_path"; then
        rm "$link_path"
      elif is_dir "$link_path"; then
        warn "$tool: $skill_name is a real dir, skipping (use 'consolidate' to fix)"
        continue
      fi

      local target
      target=$(make_link_target "$dir" "$skill_name" "$style")
      mkdir -p "$dir"
      ln -s "$target" "$link_path"
      ok "$tool: $skill_name → $target"
    done
  done
  echo ""
  ok "Init complete"
}

cmd_status() {
  echo ""
  echo -e "${CYAN}═══ Agent Link Status ═══${NC}"
  echo ""

  # 1. Rules files
  echo -e "${CYAN}── Agent Rules ──${NC}"
  local rules_ok=0 rules_warn=0 rules_err=0
  for entry in "${RULES_LINKS[@]}"; do
    IFS=':' read -r tool target <<< "$entry"
    if [[ ! -e "$target" && ! -L "$target" ]]; then
      err "$tool: $(basename "$target") — MISSING"
      ((rules_err++))
    elif is_symlink "$target"; then
      local dest
      dest=$(readlink "$target")
      if is_broken "$target"; then
        err "$tool: $(basename "$target") → $dest — BROKEN"
        ((rules_err++))
      elif [[ "$dest" == "$SOURCE_RULES" ]]; then
        ok "$tool: $(basename "$target") → AGENTS.md"
        ((rules_ok++))
      else
        warn "$tool: $(basename "$target") → $dest (expected AGENTS.md)"
        ((rules_warn++))
      fi
    else
      local size
      size=$(wc -c < "$target" 2>/dev/null | tr -d ' ' || echo "?")
      warn "$tool: $(basename "$target") — REAL FILE (${size}B, not symlinked)"
      ((rules_warn++))
    fi
  done
  echo -e "  ${DIM}Rules: $rules_ok ok, $rules_warn warnings, $rules_err errors${NC}"
  echo ""

  # 2. Source skills (collected once, reused in step 4)
  echo -e "${CYAN}── Source Skills (~/.agents/skills/) ──${NC}"
  local source_skills=()
  if [[ ! -d "$AGENTS_SKILLS" ]]; then
    err "Source skills dir does not exist: $AGENTS_SKILLS"
  else
    for d in "$AGENTS_SKILLS"/*/; do
      [[ -d "$d" ]] || continue
      local name
      name=$(basename "$d")
      [[ "$name" == .* ]] && continue
      source_skills+=("$name")
      echo "  $name"
    done
    echo -e "  ${DIM}$((${#source_skills[@]})) shared skills${NC}"
  fi
  echo ""

  # 3. Per-tool skills
  for entry in "${TOOL_SKILLS[@]}"; do
    IFS=':' read -r tool dir style <<< "$entry"
    echo -e "${CYAN}── $tool ($dir) ──${NC}"
    if [[ ! -d "$dir" ]]; then
      warn "  Directory does not exist"
      echo ""
      continue
    fi

    local symlinks=0 reals=0 broken=0 tool_specific=0 duplicates=0
    for d in "$dir"/*/; do
      [[ -e "$d" || -L "${d%/}" ]] || continue
      local name
      name=$(basename "$d")
      [[ "$name" == .* ]] && continue
      local path="${d%/}"

      if is_symlink "$path"; then
        local dest
        dest=$(readlink "$path")
        if is_broken "$path"; then
          err "  $name → $dest — BROKEN"
          ((broken++))
        else
          ok "  $name → $(basename "$dest")/"
          ((symlinks++))
        fi
      else
        if [[ -d "$AGENTS_SKILLS/$name" ]]; then
          warn "  $name — DUPLICATE of source (real dir)"
          ((duplicates++))
        else
          echo -e "  $name — ${DIM}tool-specific${NC}"
          ((tool_specific++))
        fi
        ((reals++))
      fi
    done
    echo -e "  ${DIM}$symlinks linked, $tool_specific tool-specific, $duplicates duplicates, $broken broken${NC}"
    echo ""
  done

  # 4. Unlinked source skills (reuses source_skills from step 2)
  echo -e "${CYAN}── Unlinked Source Skills ──${NC}"
  local found_unlinked=0
  for s in "${source_skills[@]}"; do
    local missing_tools=()
    for entry in "${TOOL_SKILLS[@]}"; do
      IFS=':' read -r tool dir style <<< "$entry"
      if [[ ! -L "$dir/$s" && ! -d "$dir/$s" ]]; then
        missing_tools+=("$tool")
      fi
    done
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
      warn "  $s — missing in ${missing_tools[*]}"
      found_unlinked=1
    fi
  done
  if [[ $found_unlinked -eq 0 ]]; then
    ok "All source skills are linked everywhere"
  fi
  echo ""
}

cmd_doctor() {
  echo ""
  echo -e "${CYAN}═══ Agent Link Doctor ═══${NC}"
  echo ""

  local issues=0

  # 1. Broken symlinks
  echo -e "${CYAN}── Broken Symlinks ──${NC}"
  local broken_found=0

  for entry in "${RULES_LINKS[@]}"; do
    IFS=':' read -r tool target <<< "$entry"
    if is_broken "$target"; then
      err "$tool rules: $(basename "$target") → $(readlink "$target") — TARGET MISSING"
      ((broken_found++))
    fi
  done

  for entry in "${TOOL_SKILLS[@]}"; do
    IFS=':' read -r tool dir style <<< "$entry"
    [[ -d "$dir" ]] || continue
    for d in "$dir"/*/; do
      local path="${d%/}"
      if is_broken "$path"; then
        err "$tool skill: $(basename "$path") → $(readlink "$path") — TARGET MISSING"
        ((broken_found++))
      fi
    done
  done

  if [[ $broken_found -eq 0 ]]; then
    ok "No broken symlinks"
  else
    issues=$((issues + broken_found))
  fi
  echo ""

  # 2. Wrong rules targets
  echo -e "${CYAN}── Rules Target Correctness ──${NC}"
  local wrong_found=0
  for entry in "${RULES_LINKS[@]}"; do
    IFS=':' read -r tool target <<< "$entry"
    if is_symlink "$target"; then
      local current
      current=$(readlink "$target")
      if [[ "$current" != "$SOURCE_RULES" ]]; then
        warn "$tool: $(basename "$target") → $current (should be $SOURCE_RULES)"
        wrong_found=1
      fi
    fi
  done
  if [[ $wrong_found -eq 0 ]]; then
    ok "All rules symlinks point to correct target"
  else
    ((issues++))
  fi
  echo ""

  # 3. Circular symlinks
  echo -e "${CYAN}── Circular Symlink Check ──${NC}"
  local circular_found=0
  for entry in "${TOOL_SKILLS[@]}"; do
    IFS=':' read -r tool dir style <<< "$entry"
    [[ -d "$dir" ]] || continue
    for d in "$dir"/*/; do
      local path="${d%/}"
      if is_symlink "$path"; then
        local target
        target=$(readlink "$path")
        # Check if target points back into the same dir
        case "$target" in
          "$dir/"*|"$dir")
            err "$tool: $(basename "$path") → $target — CIRCULAR (points into same dir)"
            circular_found=1
            ;;
        esac
      fi
    done
  done
  if [[ $circular_found -eq 0 ]]; then
    ok "No circular symlinks"
  else
    ((issues++))
  fi
  echo ""

  # 4. Source rules file exists
  echo -e "${CYAN}── Source Rules ──${NC}"
  if [[ -f "$SOURCE_RULES" ]]; then
    local size
    size=$(wc -c < "$SOURCE_RULES" | tr -d ' ')
    ok "AGENTS.md exists (${size} bytes)"
  else
    err "AGENTS.md missing at $SOURCE_RULES"
    ((issues++))
  fi
  echo ""

  # Summary
  if [[ $issues -eq 0 ]]; then
    ok "All checks passed"
  else
    err "$issues issue(s) found — run 'sync.sh status' for details"
  fi
}

# ── Main ────────────────────────────────────────────────────

cmd="${1:-status}"
shift || true

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

case "$cmd" in
  status)        cmd_status ;;
  init)          cmd_init ;;
  link)          cmd_link_skill "$@" ;;
  unlink)        cmd_unlink_skill "$@" ;;
  link-rules)    cmd_link_rules ;;
  unlink-rules)  cmd_unlink_rules ;;
  consolidate)   cmd_consolidate ;;
  doctor)        cmd_doctor ;;
  audit)         bash "$SCRIPT_DIR/audit.sh" audit "$@" ;;
  merge)         bash "$SCRIPT_DIR/audit.sh" merge "$@" ;;
  *)
    echo "Usage: sync.sh <command> [args]"
    echo ""
    echo "Commands:"
    echo "  status              Show rules + skill symlink state"
    echo "  init                First-time setup: rules symlinks + link all skills"
    echo "  link <name>         Link one skill from source to all tools"
    echo "  unlink <name>       Remove skill symlinks from all tools"
    echo "  link-rules          Set up AGENTS.md/CLAUDE.md agent rules symlinks"
    echo "  unlink-rules        Remove agent rules symlinks"
    echo "  consolidate         Move real dirs to source, create symlinks back"
    echo "  doctor              Diagnose broken/wrong symlinks"
    echo "  audit               Scan, classify, evaluate skills + generate merge prompt"
    echo "  merge <s1> <s2>..   Interactive merge wizard for skills"
    exit 1
    ;;
esac
