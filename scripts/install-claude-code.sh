#!/bin/bash
# Sigma Protocol Installer for Claude Code
# Installs commands, skills, and agents into ~/.claude/

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GRAY='\033[0;90m'
NC='\033[0m'

# Defaults
FORCE=false
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --force|-f) FORCE=true; shift ;;
        --dry-run|-n) DRY_RUN=true; shift ;;
        --help|-h)
            echo "Usage: install-claude-code.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -f, --force     Override all existing files"
            echo "  -n, --dry-run   Preview only, don't modify files"
            echo "  -h, --help      Show this help message"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(dirname "$SCRIPT_DIR")"

# Claude Code directories
CLAUDE_HOME="$HOME/.claude"
CLAUDE_COMMANDS="$CLAUDE_HOME/commands"
CLAUDE_SKILLS="$CLAUDE_HOME/skills"
CLAUDE_AGENTS="$CLAUDE_HOME/agents"

echo -e "${MAGENTA}\n🚀 Sigma Protocol Installer for Claude Code\n${NC}"
echo -e "${GRAY}Source: $SOURCE_ROOT${NC}"
echo -e "${GRAY}Target: $CLAUDE_HOME${NC}"

# Counters
ADDED=0
UPDATED=0
SKIPPED=0

CANONICAL_SKILLS_DIR="$SOURCE_ROOT/src/skills"
LEGACY_SKILLS_DIR="$SOURCE_ROOT/.claude/skills"
BUNDLED_SKILLS_DIR="$SOURCE_ROOT/.agents/skills"

# Emit directories that are actual skill roots. Support files stay with their
# root when copied; nested Markdown documents never become fake skills.
_find_skill_roots_in() {
    local source_dir="$1"
    ( cd "$source_dir" 2>/dev/null \
        && find . -type f -name "SKILL.md" ! -path './.*' ! -path '*/.*/*' \
            -exec dirname {} \; \
            | sed "s|^\./|$source_dir/|" \
            | sort )
}

_skill_names_in() {
    local source_dir="$1"
    local include_flat="$2"
    _find_skill_roots_in "$source_dir" | while IFS= read -r root; do basename "$root"; done
    if [ "$include_flat" = true ]; then
        find "$source_dir" -maxdepth 1 -type f -name "*.md" -exec basename {} .md \; | sort
    fi
}

validate_skill_source_names() {
    local source_dir="$1"
    local include_flat="$2"
    local duplicates
    duplicates="$(_skill_names_in "$source_dir" "$include_flat" | sort | uniq -d)"
    if [ -n "$duplicates" ]; then
        echo -e "${RED}❌ Duplicate skill names in $source_dir:${NC}" >&2
        echo "$duplicates" >&2
        exit 1
    fi
}

iter_skill_sources() {
    # Overlay order: legacy Claude base, tracked bundled pool, then authored
    # canonical sources. Later sources win by skill name.
    local found=1

    if [ -d "$LEGACY_SKILLS_DIR" ]; then
        _find_skill_roots_in "$LEGACY_SKILLS_DIR"
        # Flat legacy skills are supported only at this root for compatibility.
        find "$LEGACY_SKILLS_DIR" -maxdepth 1 -type f -name "*.md" | sort
        found=0
    fi

    if [ -d "$BUNDLED_SKILLS_DIR" ]; then
        _find_skill_roots_in "$BUNDLED_SKILLS_DIR"
        found=0
    fi

    if [ -d "$CANONICAL_SKILLS_DIR" ]; then
        _find_skill_roots_in "$CANONICAL_SKILLS_DIR"
        find "$CANONICAL_SKILLS_DIR" -maxdepth 1 -type f -name "*.md" | sort
        found=0
    fi

    return $found
}

skill_target_existed_before_install() {
    case "$PREEXISTING_SKILL_NAMES" in
        *$'\n'"$1"$'\n'*) return 0 ;;
        *) return 1 ;;
    esac
}

skill_file_existed_before_install() {
    case "$PREEXISTING_SKILL_FILES" in
        *$'\n'"$1"$'\n'*) return 0 ;;
        *) return 1 ;;
    esac
}

skill_name_from_source() {
    local source="$1"
    if [ -d "$source" ]; then
        basename "$source"
    else
        basename "$source" .md
    fi
}

copy_canonical_skill_tree() {
    local source="$1"
    local target="$2"
    local source_file relative target_file
    while IFS= read -r source_file; do
        relative="${source_file#$source/}"
        target_file="$target/$relative"
        mkdir -p "$(dirname "$target_file")"
        if [ "$relative" != "SKILL.md" ] && skill_file_existed_before_install "$target_file" && [ "$FORCE" = false ]; then
            echo -e "  ${YELLOW}⏭️  Preserved existing support file: $relative${NC}"
            continue
        fi
        cp "$source_file" "$target_file"
    done < <(find "$source" -type f)
}

# Reject ambiguous same-pool identities before the installer writes anything.
[ ! -d "$LEGACY_SKILLS_DIR" ] || validate_skill_source_names "$LEGACY_SKILLS_DIR" true
[ ! -d "$BUNDLED_SKILLS_DIR" ] || validate_skill_source_names "$BUNDLED_SKILLS_DIR" false
[ ! -d "$CANONICAL_SKILLS_DIR" ] || validate_skill_source_names "$CANONICAL_SKILLS_DIR" true

if [ "$DRY_RUN" = false ]; then
    mkdir -p "$CLAUDE_COMMANDS" "$CLAUDE_SKILLS" "$CLAUDE_AGENTS"
    echo -e "${GREEN}✅ Created ~/.claude directory structure${NC}"
else
    echo -e "${YELLOW}📋 DRY RUN: Would create ~/.claude directory structure${NC}"
fi

# =============================================================================
# Install Enforcement Hooks (step-skill-gate + step-verify-gate) + idempotent wiring
# =============================================================================
echo -e "${CYAN}\n📦 Installing enforcement hooks...${NC}"
CLAUDE_HOOKS="$CLAUDE_HOME/hooks"
SETTINGS="$CLAUDE_HOME/settings.json"
for GATE in step-skill-gate step-verify-gate; do
    HOOK_SRC="$SOURCE_ROOT/.claude/hooks/$GATE.cjs"
    if [ ! -f "$HOOK_SRC" ]; then
        echo -e "  ${GRAY}⏭️  $GATE.cjs not found in source${NC}"
        continue
    fi
    if [ -L "$CLAUDE_HOOKS/$GATE.cjs" ]; then
        echo -e "  ${YELLOW}⏭️  Refused symlinked hook target: hooks/$GATE.cjs${NC}"
        ((SKIPPED++)) || true
        continue
    fi
    PRESERVE_HOOK=false
    if [ -f "$CLAUDE_HOOKS/$GATE.cjs" ] && [ "$FORCE" = false ]; then
        PRESERVE_HOOK=true
        echo -e "  ${GRAY}Preserved existing: hooks/$GATE.cjs${NC}"
        if ! cmp -s "$HOOK_SRC" "$CLAUDE_HOOKS/$GATE.cjs"; then
            echo -e "  ${YELLOW}Existing hook differs from source; review the diff before explicitly replacing it.${NC}"
        fi
    fi
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$CLAUDE_HOOKS"
        HOOK_CANDIDATE="$CLAUDE_HOOKS/$GATE.cjs"
        HOOK_CANDIDATE_DIR=""
        if [ "$PRESERVE_HOOK" = false ]; then
            HOOK_CANDIDATE_DIR="$(mktemp -d "$CLAUDE_HOOKS/.sigma-hook.XXXXXX")"
            HOOK_CANDIDATE="$HOOK_CANDIDATE_DIR/$GATE.cjs"
            cp "$HOOK_SRC" "$HOOK_CANDIDATE"
            chmod +x "$HOOK_CANDIDATE"
        fi
        # Validate the candidate before replacing a hook that may already be wired.
        SMOKE="$(printf '{"transcript_path":"/no/such/file","session_id":"install-smoke"}' | node "$HOOK_CANDIDATE" 2>/dev/null; echo "rc=$?")"
        if echo "$SMOKE" | grep -q '"decision":"block"' || ! echo "$SMOKE" | grep -q 'rc=0'; then
            echo -e "  ${RED}$GATE failed the fail-open smoke test ($SMOKE) — NOT replacing or wiring${NC}"
            if [ -n "$HOOK_CANDIDATE_DIR" ]; then rm -rf "$HOOK_CANDIDATE_DIR"; fi
            continue
        fi
        if [ -n "$HOOK_CANDIDATE_DIR" ]; then
            mv "$HOOK_CANDIDATE" "$CLAUDE_HOOKS/$GATE.cjs"
            rmdir "$HOOK_CANDIDATE_DIR"
        fi
        # Idempotent wire into settings.json Stop chain (backs up once, fail-open).
        if [ -f "$SETTINGS" ]; then
            GATE="$GATE" node -e '
              const fs=require("fs"), p=process.argv[1], gate=process.env.GATE;
              try {
                const d=JSON.parse(fs.readFileSync(p,"utf8"));
                d.hooks=d.hooks||{}; d.hooks.Stop=d.hooks.Stop||[];
                if (JSON.stringify(d.hooks.Stop).includes(gate+".cjs")) { console.log("  "+gate+" already wired in Stop chain"); process.exit(0); }
                if (!fs.existsSync(p+".bak-stepgate")) fs.copyFileSync(p, p+".bak-stepgate");
                const cmd="node \""+process.env.HOME+"/.claude/hooks/"+gate+".cjs\"";
                d.hooks.Stop.unshift({matcher:"",hooks:[{type:"command",command:cmd,timeout:10}]});
                fs.writeFileSync(p, JSON.stringify(d,null,2));
                console.log("  wired "+gate+" into Stop chain (backup: settings.json.bak-stepgate)");
              } catch(e) { console.log("  (skipped "+gate+" wiring — wire manually: "+e.message+")"); }
            ' "$SETTINGS"
        else
            echo -e "  ${GRAY}(no settings.json yet — wire $GATE.cjs into a Stop hook manually)${NC}"
        fi
    fi
    if [ "$DRY_RUN" = true ]; then
        echo -e "  ${YELLOW}Would install or preserve and verify wiring: hooks/$GATE.cjs${NC}"
    else
        echo -e "  ${GREEN}✅ Installed: hooks/$GATE.cjs${NC}"
    fi
    ((ADDED++)) || true
done

# =============================================================================
# Install slash commands from the canonical commands/ surface
# (steps, run-track, workflow commands — everything rendered/authored there)
# =============================================================================
COMMANDS_SOURCE="$SOURCE_ROOT/commands"

if [ -d "$COMMANDS_SOURCE" ]; then
    echo -e "${CYAN}\n📦 Installing commands/ slash commands...${NC}"

    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$CLAUDE_COMMANDS"
    fi

    for file in "$COMMANDS_SOURCE"/*.md; do
        [ -f "$file" ] || continue
        FILENAME=$(basename "$file")
        TARGET="$CLAUDE_COMMANDS/$FILENAME"

        if [ -L "$TARGET" ]; then
            echo -e "  ${YELLOW}⏭️  Refused symlinked command target: $FILENAME${NC}"
            ((SKIPPED++)) || true
            continue
        fi

        if [ -f "$TARGET" ] && [ "$FORCE" = false ]; then
            ((SKIPPED++)) || true
        else
            if [ "$DRY_RUN" = false ]; then
                cp "$file" "$TARGET"
            fi
            ((ADDED++)) || true
        fi
    done
    echo -e "  ${GREEN}✅ commands/*.md installed to $CLAUDE_COMMANDS${NC}"
fi

# =============================================================================
# Install skills: .claude base, .agents bundled pool, then src overlay.
# =============================================================================
echo -e "${CYAN}\n📦 Installing Claude Code skills...${NC}"

# Snapshot user-installed names before this run. This lets the bundled pool
# override the legacy base just copied above, without replacing an existing
# user skill unless --force was requested.
PREEXISTING_SKILL_NAMES=$'\n'
PREEXISTING_SKILL_FILES=$'\n'
if [ -d "$CLAUDE_SKILLS" ]; then
    for target_dir in "$CLAUDE_SKILLS"/*; do
        [ -f "$target_dir/SKILL.md" ] || continue
        PREEXISTING_SKILL_NAMES+="$(basename "$target_dir")"$'\n'
    done
    while IFS= read -r target_file; do
        PREEXISTING_SKILL_FILES+="$target_file"$'\n'
    done < <(find "$CLAUDE_SKILLS" \( -type f -o -type l \))
fi

if iter_skill_sources >/dev/null 2>&1; then
    while IFS= read -r source; do
        [ -e "$source" ] || continue

        SKILL_NAME=$(skill_name_from_source "$source")
        TARGET_SKILL="$CLAUDE_SKILLS/$SKILL_NAME"
        TARGET_FILE="$TARGET_SKILL/SKILL.md"

        if [ -L "$TARGET_SKILL" ]; then
            echo -e "  ${YELLOW}⏭️  Refused symlinked skill target: $SKILL_NAME${NC}"
            ((SKIPPED++)) || true
            continue
        fi
        if [ -d "$TARGET_SKILL" ] && find "$TARGET_SKILL" -type l -print -quit | grep -q .; then
            echo -e "  ${YELLOW}⏭️  Refused skill target containing symlinks: $SKILL_NAME${NC}"
            ((SKIPPED++)) || true
            continue
        fi

        if [ -f "$TARGET_FILE" ] && [ "$FORCE" = false ] && \
            { skill_target_existed_before_install "$SKILL_NAME" || [[ "$source" == "$LEGACY_SKILLS_DIR"/* ]]; }; then
            ((SKIPPED++)) || true
            continue
        fi

        if [ "$DRY_RUN" = false ]; then
            mkdir -p "$TARGET_SKILL"
            if [ -d "$source" ]; then
                if [[ "$source" == "$CANONICAL_SKILLS_DIR"/* ]]; then
                    copy_canonical_skill_tree "$source" "$TARGET_SKILL"
                else
                    cp -R "$source/." "$TARGET_SKILL/"
                fi
            else
                cp "$source" "$TARGET_FILE"
            fi
        fi

        echo -e "  ${GREEN}✅ Skill: $SKILL_NAME${NC}"
        ((ADDED++)) || true
    done < <(iter_skill_sources)
else
    echo -e "${RED}❌ No skill source found at $CANONICAL_SKILLS_DIR, $BUNDLED_SKILLS_DIR or $LEGACY_SKILLS_DIR${NC}"
fi

# =============================================================================
# Install Agents (MERGE: legacy .claude/agents base + src/agents overlay)
# =============================================================================
echo -e "${CYAN}\n📦 Installing agents...${NC}"

CANONICAL_AGENTS_DIR="$SOURCE_ROOT/src/agents"
LEGACY_AGENTS_DIR="$SOURCE_ROOT/.claude/agents"

# Emit agent .md files under a dir (recursive — agents are organized by
# department subfolder, e.g. sales/, security/), dot-filter applied relative to
# the source root so an absolute `.claude` root segment is never excluded. The
# install target is flat (~/.claude/agents/<name>.md), matching agent-name
# uniqueness across departments.
_find_agent_files_in() {
    local source_dir="$1"
    ( cd "$source_dir" 2>/dev/null \
        && find . -type f -name "*.md" ! -path "*/.*" \
            | sed "s|^\./|$source_dir/|" \
            | sort )
}

# Overlay sources (src/agents) always WIN on a name collision, layering the
# canonical agent on top of the legacy base. Legacy base is never reduced.
is_overlay_agent_source() {
    case "$1" in
        "$CANONICAL_AGENTS_DIR"/*) return 0 ;;
        *) return 1 ;;
    esac
}

iter_agent_sources() {
    local found=1
    if [ -d "$LEGACY_AGENTS_DIR" ]; then
        _find_agent_files_in "$LEGACY_AGENTS_DIR"
        found=0
    fi
    if [ -d "$CANONICAL_AGENTS_DIR" ]; then
        _find_agent_files_in "$CANONICAL_AGENTS_DIR"
        found=0
    fi
    return $found
}

PREEXISTING_AGENT_NAMES=$'\n'
if [ -d "$CLAUDE_AGENTS" ]; then
    while IFS= read -r target_file; do
        PREEXISTING_AGENT_NAMES+="$(basename "$target_file")"$'\n'
    done < <(find "$CLAUDE_AGENTS" -maxdepth 1 -type f -name "*.md")
fi

if iter_agent_sources >/dev/null 2>&1; then
    while IFS= read -r source_file; do
        [ -f "$source_file" ] || continue
        FILENAME=$(basename "$source_file")
        TARGET="$CLAUDE_AGENTS/$FILENAME"

        if [ -L "$TARGET" ]; then
            echo -e "  ${YELLOW}⏭️  Refused symlinked agent target: $FILENAME${NC}"
            ((SKIPPED++)) || true
            continue
        fi

        if [ -f "$TARGET" ] && [ "$FORCE" = false ] && \
            { [[ "$PREEXISTING_AGENT_NAMES" == *$'\n'"$FILENAME"$'\n'* ]] || ! is_overlay_agent_source "$source_file"; }; then
            ((SKIPPED++)) || true
            continue
        fi

        if [ "$DRY_RUN" = false ]; then
            cp "$source_file" "$TARGET"
        fi
        echo -e "  ${GREEN}✅ Agent: $FILENAME${NC}"
        ((ADDED++)) || true
    done < <(iter_agent_sources)
fi

# =============================================================================
# Optional: RTK Token Optimizer
# =============================================================================
echo -e "${CYAN}\n📦 Checking RTK (Token Optimizer)...${NC}"

if command -v rtk &> /dev/null; then
    RTK_VERSION=$(rtk --version 2>/dev/null || echo "unknown")
    echo -e "  ${GREEN}✅ RTK already installed ($RTK_VERSION)${NC}"
else
    echo -e "  ${YELLOW}⚠️  RTK not found. RTK compresses CLI output by 60-90%, saving tokens.${NC}"
    echo -e "  ${GRAY}Install with: brew install rtk && rtk init --global${NC}"
fi

# =============================================================================
# Install Global AI Brain (optional — set SIGMA_SKIP_BRAIN=1 if you already
# run your own memory layer and don't want the bundled one installed)
# =============================================================================
echo -e "${CYAN}\n📦 Installing global AI Brain...${NC}"

BRAIN_INSTALLER="$SCRIPT_DIR/install-brain.sh"
if [ "${SIGMA_SKIP_BRAIN:-0}" = "1" ]; then
    echo -e "  ${YELLOW}⏭  SIGMA_SKIP_BRAIN=1 — skipping bundled AI Brain (using your existing memory layer)${NC}"
elif [ -x "$BRAIN_INSTALLER" ] || [ -f "$BRAIN_INSTALLER" ]; then
    BRAIN_ARGS=("--yes")
    if [ "$FORCE" = true ]; then
        BRAIN_ARGS+=("--force")
    fi
    if [ "$DRY_RUN" = true ]; then
        BRAIN_ARGS+=("--dry-run")
    fi
    bash "$BRAIN_INSTALLER" "${BRAIN_ARGS[@]}"
else
    echo -e "  ${YELLOW}⚠️  install-brain.sh not found; skipped global AI Brain setup${NC}"
fi

# =============================================================================
# Summary
# =============================================================================
echo -e "${MAGENTA}\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${MAGENTA}📊 Installation Summary${NC}"
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}   Added:   $ADDED files${NC}"
echo -e "${GRAY}   Skipped: $SKIPPED files (use --force to override)${NC}"

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}\n⚠️  DRY RUN - No files were modified${NC}"
fi

echo -e "${MAGENTA}\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Next steps
echo -e "${CYAN}\n🎯 Next Steps:${NC}"
echo -e "   1. Restart Claude Code to load new commands"
echo -e "   2. Open your project and run: /step-0-environment-setup"
echo -e "   3. Or paste the guided-tour prompt from GETTING-STARTED.md"
echo -e ""
echo -e "${CYAN}📁 Installed locations:${NC}"
echo -e "   Commands: ~/.claude/commands/"
echo -e "   Skills:   ~/.claude/skills/"
echo -e "   Agents:   ~/.claude/agents/"

echo -e "${GREEN}\n✅ Sigma Protocol installed for Claude Code!${NC}\n"
