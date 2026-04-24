#!/bin/bash
set -euo pipefail

# ============================================================================
# Skill Audit and Merge Tool
# ============================================================================

# Shared Constants
AGENTS_DIR="$HOME/.agents"
AGENTS_SKILLS="$AGENTS_DIR/skills"
SOURCE_RULES="$AGENTS_DIR/AGENTS.md"

# Tool skill directories (name:dir:link_style)
TOOL_SKILLS=(
  "claude:$HOME/.claude/skills:relative"
  "opencode:$HOME/.opencode/skills:absolute"
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# Logging helpers
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; }

# File test helpers
is_symlink() { [[ -L "$1" ]]; }
is_dir()     { [[ -d "$1" && ! -L "$1" ]]; }
is_broken()  { [[ -L "$1" && ! -e "$1" ]]; }

# ============================================================================
# YAML Frontmatter Parsing
# ============================================================================

# Extract YAML frontmatter from SKILL.md and parse name/description
# Usage: parse_skill_md <skill_dir>
# Sets global variables: _skill_name, _skill_desc, _yaml_valid, _yaml_error
parse_skill_md() {
  local skill_dir="$1"
  local skill_md="$skill_dir/SKILL.md"
  
  _skill_name=""
  _skill_desc=""
  _yaml_valid=""
  _yaml_error=""
  
  if [[ ! -f "$skill_md" ]]; then
    _yaml_valid="✗"
    _yaml_error="no SKILL.md"
    return 1
  fi
  
  # Extract frontmatter between --- delimiters
  local frontmatter
  frontmatter=$(awk '/^---$/{if(++count<=2)next} count==1' "$skill_md" 2>/dev/null || true)
  
  if [[ -z "$frontmatter" ]]; then
    _yaml_valid="✗"
    _yaml_error="no frontmatter"
    return 1
  fi
  
  # Parse name field
  _skill_name=$(echo "$frontmatter" | awk -F': ' '/^name:/{print $2; exit}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  
  # Parse description field (handle multi-line)
  local in_desc=0
  local desc_lines=()
  while IFS= read -r line; do
    if [[ "$line" =~ ^description:[[:space:]]*(\>[[:space:]]*-)?[[:space:]]*(.*) ]]; then
      in_desc=1
      if [[ -n "${BASH_REMATCH[2]}" ]]; then
        desc_lines+=("${BASH_REMATCH[2]}")
      fi
    elif [[ $in_desc -eq 1 ]]; then
      if [[ "$line" =~ ^[a-zA-Z_]+: ]]; then
        break
      elif [[ "$line" =~ ^[[:space:]]+(.+) ]]; then
        desc_lines+=("${BASH_REMATCH[1]}")
      elif [[ -z "$line" ]]; then
        desc_lines+=("")
      fi
    fi
  done <<< "$frontmatter"
  
  if [[ ${#desc_lines[@]} -gt 0 ]]; then
    _skill_desc="${desc_lines[*]}"
    _skill_desc=$(echo "$_skill_desc" | sed 's/[[:space:]]+/ /g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  else
    _skill_desc=""
  fi
  
  # Validate
  if [[ -z "$_skill_name" && -z "$_skill_desc" ]]; then
    _yaml_valid="✗"
    _yaml_error="missing name, missing description"
  elif [[ -z "$_skill_name" ]]; then
    _yaml_valid="✗"
    _yaml_error="missing name"
  elif [[ -z "$_skill_desc" ]]; then
    _yaml_valid="✗"
    _yaml_error="missing description"
  else
    _yaml_valid="✓"
  fi
}

# ============================================================================
# Skill Data Collection
# ============================================================================

collect_skill_data() {
  local skill_dir="$1"
  local skill_name=$(basename "$skill_dir")
  
  # Parse SKILL.md
  parse_skill_md "$skill_dir"
  local name="${_skill_name:-$skill_name}"
  local desc="$_skill_desc"
  local yaml_valid="$_yaml_valid"
  local yaml_error="$_yaml_error"
  
  # Size and file count
  local total_size=0
  local file_count=0
  if [[ -d "$skill_dir" ]]; then
    total_size=$(find "$skill_dir" -type f -exec stat -f %z {} + 2>/dev/null | awk '{s+=$1}END{print s}')
    file_count=$(find "$skill_dir" -type f 2>/dev/null | wc -l | tr -d ' ')
  fi
  total_size=${total_size:-0}
  file_count=${file_count:-0}
  
  # SKILL.md lines
  local skill_md_lines=0
  if [[ -f "$skill_dir/SKILL.md" ]]; then
    skill_md_lines=$(wc -l < "$skill_dir/SKILL.md" | tr -d ' ')
  fi
  
  # Mtime (days since modified)
  local mtime=$(stat -f %m "$skill_dir" 2>/dev/null || echo "0")
  local now=$(date +%s)
  local days_since=$(( (now - mtime) / 86400 ))
  
  # Directories
  local has_scripts="✗"
  local has_reference="✗"
  [[ -d "$skill_dir/scripts" ]] && has_scripts="✓"
  [[ -d "$skill_dir/reference" ]] && has_reference="✓"
  
  # Symlink status for each tool
  local symlink_status=""
  for tool_entry in "${TOOL_SKILLS[@]}"; do
    local tool_name="${tool_entry%%:*}"
    local tool_dir="${tool_entry#*:}"
    tool_dir="${tool_dir%%:*}"
    local skill_link="$tool_dir/$skill_name"
    
    if is_broken "$skill_link"; then
      symlink_status+="$tool_name:broken "
    elif is_symlink "$skill_link"; then
      symlink_status+="$tool_name:linked "
    else
      symlink_status+="$tool_name:missing "
    fi
  done
  
  # Output all fields separated by UNIT_SEP (0x1F) for safety
  local sep=$'\x1f'
  printf '%s' "$name${sep}${desc}${sep}${total_size}${sep}${file_count}${sep}${skill_md_lines}${sep}${yaml_valid}${sep}${yaml_error}${sep}${days_since}${sep}${has_scripts}${sep}${has_reference}${sep}${symlink_status}${sep}${skill_name}"
}

# ============================================================================
# Classification Functions
# ============================================================================

classify_size_tier() {
  local size=$1
  if [[ $size -lt 10240 ]]; then
    echo "tiny"
  elif [[ $size -lt 51200 ]]; then
    echo "small"
  elif [[ $size -lt 102400 ]]; then
    echo "medium"
  elif [[ $size -lt 204800 ]]; then
    echo "large"
  else
    echo "huge"
  fi
}

classify_desc_quality() {
  local desc="$1"
  local len=${#desc}
  if [[ $len -eq 0 ]]; then
    echo "missing"
  elif [[ $len -lt 100 ]]; then
    echo "short"
  elif [[ $len -gt 500 ]]; then
    echo "verbose"
  else
    echo "ok"
  fi
}

classify_activity() {
  local days=$1
  if [[ $days -lt 7 ]]; then
    echo "recent"
  elif [[ $days -lt 30 ]]; then
    echo "active"
  elif [[ $days -lt 90 ]]; then
    echo "stale"
  else
    echo "dormant"
  fi
}

# Determine health: ✓ healthy, ⚠ warning, ✗ issues
calculate_health() {
  local yaml_valid="$1"
  local desc_quality="$2"
  local size_tier="$3"
  local activity="$4"
  
  local health="✓"
  local reasons=""
  
  # Check for issues (✗)
  if [[ "$yaml_valid" != "✓" ]]; then
    health="✗"
    reasons+="yaml_invalid "
  fi
  if [[ "$desc_quality" == "missing" ]]; then
    health="✗"
    reasons+="desc_missing "
  fi
  if [[ "$activity" == "dormant" ]]; then
    health="✗"
    reasons+="dormant "
  fi
  
  # If not already issues, check for warnings (⚠)
  if [[ "$health" == "✓" ]]; then
    if [[ "$desc_quality" == "short" || "$desc_quality" == "verbose" ]]; then
      health="⚠"
      reasons+="desc_$desc_quality "
    fi
    if [[ "$size_tier" == "large" || "$size_tier" == "huge" ]]; then
      health="⚠"
      reasons+="size_$size_tier "
    fi
    if [[ "$activity" == "stale" ]]; then
      health="⚠"
      reasons+="stale "
    fi
  fi
  
  echo "$health|$reasons"
}

# Format size for display
format_size() {
  local size=$1
  if [[ $size -lt 1024 ]]; then
    echo "${size}B"
  elif [[ $size -lt 1048576 ]]; then
    echo "$(( (size + 512) / 1024 ))KB"
  else
    echo "$(( (size + 524288) / 1048576 ))MB"
  fi
}

# ============================================================================
# Audit Subcommand
# ============================================================================

cmd_audit() {
  echo ""
  echo "═══ Skill Audit Report ═══"
  echo "Date: $(date +%Y-%m-%d)"
  
  # Collect all skill data
  local skills=()
  local total_size=0
  local healthy_count=0
  local warning_count=0
  local issue_count=0
  local warning_reasons=""
  local issue_reasons=""
  
  # Arrays for heat map
  local huge_skills=()
  local large_skills=()
  local medium_skills=()
  local small_skills=()
  local tiny_skills=()
  
  # Array for stale skills
  declare -a stale_skills=()
  declare -a stale_days=()
  
  # Array for description lengths
  declare -a desc_names=()
  declare -a desc_lengths=()
  
  # Collect data from all skills
  for skill_dir in "$AGENTS_SKILLS"/*/; do
    [[ -d "$skill_dir" ]] || continue
    local skill_name=$(basename "$skill_dir")
    [[ "$skill_name" == "."* ]] && continue
    
    # Read skill data
    local data
    data=$(collect_skill_data "$skill_dir")
    
    # Parse UNIT_SEP delimited output
    local sep=$'\x1f'
    IFS="$sep" read -r -a fields <<< "$data"
    
    local name="${fields[0]:-}"
    local desc="${fields[1]:-}"
    local size="${fields[2]:-0}"
    local file_count="${fields[3]:-0}"
    local skill_md_lines="${fields[4]:-0}"
    local yaml_valid="${fields[5]:-✗}"
    local yaml_error="${fields[6]:-parse error}"
    local days="${fields[7]:-999}"
    local has_scripts="${fields[8]:-✗}"
    local has_reference="${fields[9]:-✗}"
    local symlink_status="${fields[10]:-}"
    local dir_name="${fields[11]:-$(basename "$skill_dir")}"
    
    total_size=$((total_size + size))
    
    # Classifications
    local size_tier=$(classify_size_tier "$size")
    local desc_quality=$(classify_desc_quality "$desc")
    local activity=$(classify_activity "$days")
    local health_result=$(calculate_health "$yaml_valid" "$desc_quality" "$size_tier" "$activity")
    local health="${health_result%%|*}"
    local reasons="${health_result#*|}"
    
    # Update counts
    case "$health" in
      "✓") ((healthy_count++)) ;;
      "⚠") ((warning_count++)); warning_reasons+="$reasons" ;;
      "✗") ((issue_count++)); issue_reasons+="$reasons" ;;
    esac
    
    # Heat map categorization
    local size_human=$(format_size "$size")
    case "$size_tier" in
      "huge") huge_skills+=("$name($size_human)") ;;
      "large") large_skills+=("$name($size_human)") ;;
      "medium") medium_skills+=("$name($size_human)") ;;
      "small") small_skills+=("$name($size_human)") ;;
      "tiny") tiny_skills+=("$name($size_human)") ;;
    esac
    
    # Stale skills
    if [[ "$activity" == "stale" || "$activity" == "dormant" ]]; then
      stale_skills+=("$name")
      stale_days+=("$days")
    fi
    
    # Description lengths
    desc_names+=("$name")
    desc_lengths+=(${#desc})
    
    # Build skill entry for details section
    skills+=("$health|$name|$size_human|$size_tier|$desc_quality|$activity|$days|$has_scripts|$has_reference|$symlink_status|$yaml_valid|$yaml_error|$desc")
  done
  
  local total_skills=${#skills[@]}
  echo "Total: $total_skills skills, $(format_size $total_size)"
  echo ""
  
  # Health Overview
  echo "── Health Overview ──"
  printf "  ✓ Healthy:    %d\n" "$healthy_count"
  
  # Count warning reasons
  local warn_yaml=$(echo "$warning_reasons" | grep -o "yaml_invalid" | wc -l | tr -d ' ')
  local warn_desc=$(echo "$warning_reasons" | grep -oE "desc_short|desc_verbose" | wc -l | tr -d ' ')
  local warn_size=$(echo "$warning_reasons" | grep -oE "size_large|size_huge" | wc -l | tr -d ' ')
  local warn_stale=$(echo "$warning_reasons" | grep -o "stale" | wc -l | tr -d ' ')
  local warn_summary=""
  [[ $warn_desc -gt 0 ]] && warn_summary+="desc:$warn_desc "
  [[ $warn_size -gt 0 ]] && warn_summary+="size:$warn_size "
  [[ $warn_stale -gt 0 ]] && warn_summary+="stale:$warn_stale "
  [[ -n "$warn_summary" ]] && warn_summary="(${warn_summary% })"
  printf "  ⚠ Warning:    %d %s\n" "$warning_count" "$warn_summary"
  
  local issue_yaml=$(echo "$issue_reasons" | grep -o "yaml_invalid" | wc -l | tr -d ' ')
  local issue_desc=$(echo "$issue_reasons" | grep -o "desc_missing" | wc -l | tr -d ' ')
  local issue_dormant=$(echo "$issue_reasons" | grep -o "dormant" | wc -l | tr -d ' ')
  local issue_summary=""
  [[ $issue_yaml -gt 0 ]] && issue_summary+="yaml:$issue_yaml "
  [[ $issue_desc -gt 0 ]] && issue_summary+="desc:$issue_desc "
  [[ $issue_dormant -gt 0 ]] && issue_summary+="dormant:$issue_dormant "
  [[ -n "$issue_summary" ]] && issue_summary="(${issue_summary% })"
  printf "  ✗ Issues:     %d %s\n" "$issue_count" "$issue_summary"
  echo ""
  
  # Per-Skill Details
  echo "── Per-Skill Details ──"
  for skill in "${skills[@]}"; do
    IFS='|' read -r health name size_human size_tier desc_quality activity days has_scripts has_reference symlink_status yaml_valid yaml_error desc <<< "$skill"
    
    # Parse symlink status
    local claude_status="missing"
    local opencode_status="missing"
    for status in $symlink_status; do
      if [[ "$status" == claude:* ]]; then
        claude_status="${status#claude:}"
      elif [[ "$status" == opencode:* ]]; then
        opencode_status="${status#opencode:}"
      fi
    done
    
    # Format flags
    local flags=""
    [[ "$has_scripts" == "✓" ]] && flags+="scripts✓ " || flags+="scripts✗ "
    [[ "$has_reference" == "✓" ]] && flags+="reference✓ " || flags+="reference✗ "
    flags+="symlink:"
    local linked_count=0
    [[ "$claude_status" == "linked" ]] && ((linked_count++))
    [[ "$opencode_status" == "linked" ]] && ((linked_count++))
    local tool_count=${#TOOL_SKILLS[@]}
    if [[ $linked_count -eq $tool_count ]]; then
      flags+="linked"
    elif [[ $linked_count -eq 0 ]]; then
      flags+="missing"
    else
      flags+="partial"
    fi
    
    printf "  %s %-30s %6s %-7s desc:%-7s %s(%dd)  %s\n" \
      "$health" "$name" "$size_human" "$size_tier" "$desc_quality" "$activity" "$days" "$flags"
    
    if [[ "$yaml_valid" != "✓" ]]; then
      echo -e "      ${DIM}yaml: $yaml_error${NC}"
    fi
  done
  echo ""
  
  # Size Heat Map
  echo "── Size Heat Map ──"
  if [[ ${#huge_skills[@]} -gt 0 ]]; then
    echo "  [>200KB]  ${huge_skills[*]}"
  fi
  if [[ ${#large_skills[@]} -gt 0 ]]; then
    echo "  [100-200KB] ${large_skills[*]}"
  fi
  if [[ ${#medium_skills[@]} -gt 0 ]]; then
    echo "  [50-100KB]  ${medium_skills[*]}"
  fi
  if [[ ${#small_skills[@]} -gt 0 ]]; then
    echo "  [10-50KB]   ${small_skills[*]}"
  fi
  if [[ ${#tiny_skills[@]} -gt 0 ]]; then
    echo "  [<10KB]     ${tiny_skills[*]}"
  fi
  echo ""
  
  # Stale Skills
  echo "── Stale Skills (>30d inactive) ──"
  if [[ ${#stale_skills[@]} -gt 0 ]]; then
    for i in "${!stale_skills[@]}"; do
      printf "  %-30s %sd\n" "${stale_skills[$i]}" "${stale_days[$i]}"
    done
  else
    echo "  None"
  fi
  echo ""
  
  # Context Cost Estimate
  echo "── Context Cost Estimate ──"
  local total_desc_chars=0
  for len in "${desc_lengths[@]}"; do
    total_desc_chars=$((total_desc_chars + len))
  done
  local est_tokens=$((total_desc_chars / 4))
  echo "  Skills injected every session via description:"
  echo "    Total description chars: $total_desc_chars"
  echo "    Estimated tokens (chars/4): ~$est_tokens"
  echo "  Top 5 by description length:"
  
  # Sort by length and show top 5
  local sorted_indices=()
  for i in "${!desc_lengths[@]}"; do
    sorted_indices+=($i)
  done
  
  # Simple bubble sort for indices
  for ((i=0; i<${#sorted_indices[@]}-1; i++)); do
    for ((j=i+1; j<${#sorted_indices[@]}; j++)); do
      local idx_i=${sorted_indices[$i]}
      local idx_j=${sorted_indices[$j]}
      if [[ ${desc_lengths[$idx_j]} -gt ${desc_lengths[$idx_i]} ]]; then
        sorted_indices[$i]=$idx_j
        sorted_indices[$j]=$idx_i
      fi
    done
  done
  
  local count=0
  for idx in "${sorted_indices[@]}"; do
    ((count++))
    [[ $count -gt 5 ]] && break
    local tokens=$((desc_lengths[$idx] / 4))
    printf "    %s: %d chars (~%d tokens)\n" "${desc_names[$idx]}" "${desc_lengths[$idx]}" "$tokens"
  done
  echo ""
  
  # LLM Merge Analysis Prompt
  echo "── LLM Merge Analysis Prompt ──"
  echo "Copy the prompt below and paste it to an LLM for merge recommendations:"
  echo ""
  echo "---BEGIN PROMPT---"
  echo "You are a skill consolidation advisor. Analyze these skills and recommend merges."
  echo ""
  echo "Rules:"
  echo "- Merge only skills with strong semantic overlap (same tool family, same workflow chain)"
  echo "- Do NOT merge skills that serve unrelated purposes just because they're small"
  echo "- Consider: merged description must cover all trigger keywords from originals"
  echo "- Large skills (>200KB) should only be merged if they share >50% context domain"
  echo ""
  echo "Skills:"
  echo "| Name | Size | Activity | Description |"
  echo "|------|------|----------|-------------|"
  
  for skill in "${skills[@]}"; do
    IFS='|' read -r health name size_human size_tier desc_quality activity days has_scripts has_reference symlink_status yaml_valid yaml_error desc <<< "$skill"
    local desc_short="${desc:0:120}"
    [[ ${#desc} -gt 120 ]] && desc_short+="..."
    printf "| %s | %s | %s | %s |\n" "$name" "$size_tier" "$activity" "$desc_short"
  done
  
  echo ""
  echo "Output format:"
  echo "For each merge recommendation:"
  echo "1. Group name and suggested merged skill name"
  echo "2. Skills to merge (list)"
  echo "3. Reasoning (1-2 sentences)"
  echo "4. Risk level: LOW / MEDIUM / HIGH"
  echo "5. SKILL.md merge approach: unified / sectioned"
  echo "6. Estimated size after merge"
  echo ""
  echo "Also list skills that should NOT be merged and why."
  echo "---END PROMPT---"
  echo ""
}

# ============================================================================
# Merge Subcommand
# ============================================================================

cmd_merge() {
  local skills_to_merge=("$@")
  
  if [[ ${#skills_to_merge[@]} -lt 2 ]]; then
    err "At least 2 skills required for merge"
    echo "Usage: $0 merge <skill1> <skill2> [skill3...]"
    exit 1
  fi
  
  # Validate all skills exist
  for skill in "${skills_to_merge[@]}"; do
    if [[ ! -d "$AGENTS_SKILLS/$skill" ]]; then
      err "Skill not found: $skill"
      exit 1
    fi
  done
  
  echo ""
  echo "═══ Skill Merge Wizard ═══"
  echo ""
  
  # Step 1: Review Candidates
  echo "── Step 1: Review Candidates ──"
  local total_size=0
  for skill in "${skills_to_merge[@]}"; do
    local skill_dir="$AGENTS_SKILLS/$skill"
    local size=$(find "$skill_dir" -type f -exec stat -f %z {} + 2>/dev/null | awk '{s+=$1}END{print s}')
    total_size=$((total_size + size))
    
    # Get description
    parse_skill_md "$skill_dir" 2>/dev/null || true
    local desc="${_skill_desc:-No description}"
    local desc_short="${desc:0:80}"
    [[ ${#desc} -gt 80 ]] && desc_short+="..."
    
    printf "  %-20s %8s   %s\n" "$skill" "$(format_size $size)" "$desc_short"
  done
  echo ""
  echo "  Total: $(format_size $total_size), ${#skills_to_merge[@]} skills → 1 merged skill"
  echo ""
  
  read -rp "  Proceed with these skills? [Y/n] " proceed
  if [[ "$proceed" =~ ^[Nn]$ ]]; then
    info "Aborted."
    exit 0
  fi
  
  # Step 2: Name the Merged Skill
  echo ""
  echo "── Step 2: Name the Merged Skill ──"
  
  # Find longest common prefix
  local suggested_name=""
  local first_skill="${skills_to_merge[0]}"
  for ((i=1; i<=${#first_skill}; i++)); do
    local prefix="${first_skill:0:i}"
    local all_match=true
    for skill in "${skills_to_merge[@]}"; do
      if [[ ! "$skill" =~ ^"$prefix" ]]; then
        all_match=false
        break
      fi
    done
    if $all_match; then
      suggested_name="$prefix"
    else
      break
    fi
  done
  
  # Strip trailing -
  suggested_name="${suggested_name%%-}"
  [[ -z "$suggested_name" ]] && suggested_name="merged-skill"
  
  read -rp "  Suggested: $suggested_name"$'\n  Enter name (or press Enter to accept): ' new_name
  new_name="${new_name:-$suggested_name}"
  
  # Validate name doesn't exist
  if [[ -d "$AGENTS_SKILLS/$new_name" ]]; then
    err "Skill '$new_name' already exists"
    exit 1
  fi
  
  # Step 3: SKILL.md Merge Strategy
  echo ""
  echo "── Step 3: SKILL.md Merge Strategy ──"
  echo "  How should SKILL.md be structured?"
  echo "    [1] Unified: Single description covering all triggers (recommended)"
  echo "    [2] Sectioned: Keep each original skill as a section within one SKILL.md"
  echo "    [3] Custom: Create placeholder SKILL.md, I'll write it myself"
  read -rp "  Choose [1/2/3]: " strategy
  
  local strategy_name
  case "$strategy" in
    1) strategy_name="unified" ;;
    2) strategy_name="sectioned" ;;
    3) strategy_name="custom" ;;
    *) strategy_name="unified" ;;
  esac
  
  # Step 4: Directory Structure
  echo ""
  echo "── Step 4: Directory Structure ──"
  echo "  How to organize files?"
  echo "    [1] Flat: All files in root (may conflict)"
  echo "    [2] Namespaced: Subdir per original skill (recommended, zero conflict)"
  echo "    [3] By type: scripts/, reference/, templates/"
  read -rp "  Choose [1/2/3] (default: 2): " structure
  structure="${structure:-2}"
  
  local structure_name
  case "$structure" in
    1) structure_name="flat" ;;
    2) structure_name="namespaced" ;;
    3) structure_name="by-type" ;;
    *) structure_name="namespaced" ;;
  esac
  
  # Step 5: File Conflict Scan
  echo ""
  echo "── Step 5: File Conflict Scan ──"
  
  declare -A file_locations
  declare -a conflicts=()
  
  if [[ "$structure" == "1" || "$structure" == "3" ]]; then
    for skill in "${skills_to_merge[@]}"; do
      local skill_dir="$AGENTS_SKILLS/$skill"
      while IFS= read -r -d '' file; do
        local rel_path="${file#$skill_dir/}"
        # Skip SKILL.md
        [[ "$rel_path" == "SKILL.md" ]] && continue
        
        if [[ -n "${file_locations[$rel_path]:-}" ]]; then
          conflicts+=("$rel_path|$skill|${file_locations[$rel_path]}")
        else
          file_locations[$rel_path]="$skill"
        fi
      done < <(find "$skill_dir" -type f -print0 2>/dev/null)
    done
    
    if [[ ${#conflicts[@]} -eq 0 ]]; then
      ok "  No conflicts found"
    else
      declare -A conflict_resolutions
      for conflict in "${conflicts[@]}"; do
        IFS='|' read -r rel_path skill_a skill_b <<< "$conflict"
        echo ""
        warn "  CONFLICT: $rel_path exists in $skill_a and $skill_b"
        echo "    [1] Rename to ${skill_a}-${rel_path##*/} / ${skill_b}-${rel_path##*/}"
        echo "    [2] Keep $skill_a's version"
        echo "    [3] Keep $skill_b's version"
        echo "    [4] Skip this file"
        read -rp "  Choose [1/2/3/4]: " choice
        
        case "$choice" in
          1) conflict_resolutions[$rel_path]="rename" ;;
          2) conflict_resolutions[$rel_path]="$skill_a" ;;
          3) conflict_resolutions[$rel_path]="$skill_b" ;;
          *) conflict_resolutions[$rel_path]="skip" ;;
        esac
      done
    fi
  else
    ok "  No conflicts (namespaced mode)"
  fi
  
  # Step 6: Symlink Update Plan
  echo ""
  echo "── Step 6: Symlink Update Plan ──"
  echo "  Will REMOVE symlinks:"
  for tool_entry in "${TOOL_SKILLS[@]}"; do
    local tool_name="${tool_entry%%:*}"
    local tool_dir="${tool_entry#*:}"
    tool_dir="${tool_dir%%:*}"
    
    local to_remove=""
    for skill in "${skills_to_merge[@]}"; do
      if [[ -L "$tool_dir/$skill" ]]; then
        to_remove+="$skill, "
      fi
    done
    if [[ -n "$to_remove" ]]; then
      echo "    $tool_name: ${to_remove%, }"
    fi
  done
  
  echo ""
  echo "  Will CREATE symlinks:"
  for tool_entry in "${TOOL_SKILLS[@]}"; do
    local tool_name="${tool_entry%%:*}"
    local tool_dir="${tool_entry#*:}"
    local link_style="${tool_entry##*:}"
    tool_dir="${tool_dir%%:*}"
    
    if [[ "$link_style" == "relative" ]]; then
      echo "    $tool_name: $new_name → ../../.agents/skills/$new_name"
    else
      echo "    $tool_name: $new_name → $AGENTS_SKILLS/$new_name"
    fi
  done
  
  echo ""
  read -rp "  Proceed? [y/N]: " proceed_symlinks
  if [[ ! "$proceed_symlinks" =~ ^[Yy]$ ]]; then
    info "Aborted."
    exit 0
  fi
  
  # Step 7: Final Confirm + Backup
  echo ""
  echo "── Step 7: Final Confirm ──"
  echo "  Name: $new_name"
  echo "  SKILL.md: $strategy_name"
  echo "  Structure: $structure_name"
  echo "  Skills to merge: ${#skills_to_merge[@]}"
  echo "  Skills to remove: ${skills_to_merge[*]}"
  
  local tool_list=""
  for tool_entry in "${TOOL_SKILLS[@]}"; do
    tool_list+="${tool_entry%%:*}, "
  done
  echo "  Symlinks updated in: ${tool_list%, }"
  
  echo ""
  echo "  Creating backup before merge..."
  
  # Create backup
  local backup_file="/tmp/skill-hub-merge-$(date +%Y%m%d-%H%M%S).tar.gz"
  local rel_paths=""
  for skill in "${skills_to_merge[@]}"; do
    rel_paths+=".agents/skills/$skill "
  done
  
  if tar -czf "$backup_file" -C "$HOME" $rel_paths 2>/dev/null; then
    ok "  Backup created: $backup_file"
  else
    err "  Failed to create backup"
    exit 1
  fi
  
  echo ""
  read -rp "  Proceed with merge? [y/N]: " final_confirm
  if [[ ! "$final_confirm" =~ ^[Yy]$ ]]; then
    info "Aborted. Backup kept at $backup_file"
    exit 0
  fi
  
  # Step 8: Execute
  echo ""
  local new_dir="$AGENTS_SKILLS/$new_name"
  mkdir -p "$new_dir"
  
  # Collect trigger keywords from original SKILL.md files
  local all_triggers=""
  local section_content=""
  
  for skill in "${skills_to_merge[@]}"; do
    parse_skill_md "$AGENTS_SKILLS/$skill" 2>/dev/null || true
    local skill_desc="$_skill_desc"
    
    # Try to extract trigger keywords (usually in description or comments)
    all_triggers+="# Triggers from $skill: "
    
    if [[ "$strategy" == "2" ]]; then
      section_content+="
## $skill

$skill_desc

"
    fi
  done
  
  # Generate SKILL.md based on strategy
  case "$strategy" in
    1)
      # Unified
      cat > "$new_dir/SKILL.md" << EOF
---
name: $new_name
description: [placeholder - needs manual rewrite to cover all triggers from merged skills]
---

<!--
$all_triggers
-->

# $new_name

This skill was merged from: ${skills_to_merge[*]}

## Overview

[Write a unified description that covers all trigger keywords from the original skills]
EOF
      ;;
    2)
      # Sectioned
      cat > "$new_dir/SKILL.md" << EOF
---
name: $new_name
description: Combined skill covering ${#skills_to_merge[@]} related workflows
---

# $new_name

This skill was merged from: ${skills_to_merge[*]}

$section_content
EOF
      ;;
    3)
      # Custom
      cat > "$new_dir/SKILL.md" << EOF
---
name: $new_name
description: TODO
---

# $new_name

[Write your custom SKILL.md here]
EOF
      ;;
  esac
  
  # Copy files according to structure
  for skill in "${skills_to_merge[@]}"; do
    local src_dir="$AGENTS_SKILLS/$skill"
    
    case "$structure" in
      1)
        # Flat
        while IFS= read -r -d '' file; do
          local rel_path="${file#$src_dir/}"
          [[ "$rel_path" == "SKILL.md" ]] && continue
          
          local dest_name="$rel_path"
          if [[ -n "${conflict_resolutions[$rel_path]:-}" ]]; then
            local resolution="${conflict_resolutions[$rel_path]}"
            if [[ "$resolution" == "rename" ]]; then
              dest_name="${skill}-${rel_path##*/}"
            elif [[ "$resolution" == "$skill" ]]; then
              : # keep as is
            elif [[ "$resolution" == "skip" ]]; then
              continue
            fi
          fi
          
          cp "$file" "$new_dir/$dest_name"
        done < <(find "$src_dir" -type f -print0 2>/dev/null)
        ;;
      2)
        # Namespaced
        mkdir -p "$new_dir/$skill"
        while IFS= read -r -d '' file; do
          local rel_path="${file#$src_dir/}"
          [[ "$rel_path" == "SKILL.md" ]] && continue
          cp "$file" "$new_dir/$skill/$rel_path"
        done < <(find "$src_dir" -type f -print0 2>/dev/null)
        ;;
      3)
        # By type
        while IFS= read -r -d '' file; do
          local rel_path="${file#$src_dir/}"
          [[ "$rel_path" == "SKILL.md" ]] && continue
          
          local type_dir="other"
          if [[ "$rel_path" == scripts/* ]]; then
            type_dir="scripts"
          elif [[ "$rel_path" == reference/* ]]; then
            type_dir="reference"
          elif [[ "$rel_path" == templates/* ]]; then
            type_dir="templates"
          fi
          
          mkdir -p "$new_dir/$type_dir"
          local dest_name="${rel_path##*/}"
          
          if [[ -n "${conflict_resolutions[$rel_path]:-}" ]]; then
            local resolution="${conflict_resolutions[$rel_path]}"
            if [[ "$resolution" == "rename" ]]; then
              dest_name="${skill}-${rel_path##*/}"
            elif [[ "$resolution" == "$skill" ]]; then
              : # keep as is
            elif [[ "$resolution" == "skip" ]]; then
              continue
            fi
          fi
          
          cp "$file" "$new_dir/$type_dir/$dest_name"
        done < <(find "$src_dir" -type f -print0 2>/dev/null)
        ;;
    esac
  done
  
  # Remove original skills
  for skill in "${skills_to_merge[@]}"; do
    rm -rf "$AGENTS_SKILLS/$skill"
  done
  
  # Update symlinks
  for tool_entry in "${TOOL_SKILLS[@]}"; do
    local tool_name="${tool_entry%%:*}"
    local tool_dir="${tool_entry#*:}"
    local link_style="${tool_entry##*:}"
    tool_dir="${tool_dir%%:*}"
    
    # Remove old symlinks
    for skill in "${skills_to_merge[@]}"; do
      if [[ -L "$tool_dir/$skill" ]]; then
        rm "$tool_dir/$skill"
      fi
    done
    
    # Create new symlink
    if [[ "$link_style" == "relative" ]]; then
      ln -s "../../.agents/skills/$new_name" "$tool_dir/$new_name"
    else
      ln -s "$AGENTS_SKILLS/$new_name" "$tool_dir/$new_name"
    fi
  done
  
  # Print summary
  echo "── Merge Complete ──"
  ok "  ✓ Created $new_dir/"
  ok "  ✓ SKILL.md generated ($strategy_name strategy)"
  ok "  ✓ Files organized ($structure_name structure)"
  ok "  ✓ Removed ${#skills_to_merge[@]} original skills"
  ok "  ✓ Symlinks updated"
  ok "  ✓ Backup: $backup_file"
  echo ""
  echo "  To rollback: tar -xzf $backup_file -C ~/ && bash $AGENTS_SKILLS/skill-hub/scripts/sync.sh init"
  echo ""
}

# ============================================================================
# Main
# ============================================================================

main() {
  local cmd="${1:-}"
  
  case "$cmd" in
    audit)
      cmd_audit
      ;;
    merge)
      shift
      cmd_merge "$@"
      ;;
    *)
      echo "Usage: $0 <command>"
      echo ""
      echo "Commands:"
      echo "  audit                    Audit all skills and generate report"
      echo "  merge <skill1> <skill2>  Merge skills into a new combined skill"
      echo ""
      exit 1
      ;;
  esac
}

main "$@"
