#!/usr/bin/env bash
#
# SpecKitLite installer
#
# Installs SpecKitLite into the current project:
#   - Templates into docs/features/_template/
#   - Commands into .claude/commands/
#   - Adds docs/features/*/.plan/ to .gitignore
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/<org>/spec-kit-lite/main/install.sh | bash
#
# Or locally from a clone of the repo:
#   cd /path/to/your/project && /path/to/spec-kit-lite/install.sh

set -euo pipefail

# ──────────────────────────────────────────────────────────────
# Configuration
# ──────────────────────────────────────────────────────────────

REPO_URL="${SPECKITLITE_REPO:-https://github.com/<org>/spec-kit-lite}"
REPO_BRANCH="${SPECKITLITE_BRANCH:-main}"
RAW_BASE="${REPO_URL/github.com/raw.githubusercontent.com}/${REPO_BRANCH}"

TEMPLATES_DIR="docs/features/_template"
COMMANDS_DIR=".claude/commands"
GITIGNORE_LINE="docs/features/*/.plan/"

TEMPLATE_FILES=(
    "spec.md"
    "tech.md"
    "plan.md"
)

COMMAND_FILES=(
    "specl-take.md"
    "specl-plan.md"
    "specl-go.md"
    "specl-sync.md"
)

# ──────────────────────────────────────────────────────────────
# Local vs remote mode
# ──────────────────────────────────────────────────────────────
#
# If the script runs from a cloned repo (templates/ and commands/
# sit next to it) — copy files locally. Otherwise (curl | bash) —
# fetch over HTTP from RAW_BASE.

SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

LOCAL_MODE=false
if [ -n "$SCRIPT_DIR" ] \
    && [ -d "$SCRIPT_DIR/templates" ] \
    && [ -d "$SCRIPT_DIR/commands" ]; then
    LOCAL_MODE=true
fi

# ──────────────────────────────────────────────────────────────
# Output
# ──────────────────────────────────────────────────────────────

say() {
    printf '%s\n' "$1"
}

step() {
    printf '\n→ %s\n' "$1"
}

ok() {
    printf '  ✓ %s\n' "$1"
}

skip() {
    printf '  · %s\n' "$1"
}

fail() {
    printf '\n✗ %s\n' "$1" >&2
    exit 1
}

# ──────────────────────────────────────────────────────────────
# Prerequisites
# ──────────────────────────────────────────────────────────────

check_prerequisites() {
    step "Checking prerequisites"

    if $LOCAL_MODE; then
        ok "local source: $SCRIPT_DIR"
    else
        if ! command -v curl >/dev/null 2>&1; then
            fail "curl is required but not installed"
        fi
        ok "curl found"
    fi

    if [ ! -d ".git" ] && [ ! -f ".git" ]; then
        say "  · warning: not a git repository (SpecKitLite works best in a git repo)"
    else
        ok "git repository detected"
    fi
}

# ──────────────────────────────────────────────────────────────
# Install a file
# ──────────────────────────────────────────────────────────────

install_file() {
    local remote_rel="$1"
    local local_dst="$2"

    if [ -f "$local_dst" ]; then
        skip "exists: $local_dst (skipped)"
        return 0
    fi

    mkdir -p "$(dirname "$local_dst")"

    if $LOCAL_MODE; then
        local src="$SCRIPT_DIR/$remote_rel"
        if [ ! -f "$src" ]; then
            fail "missing in source tree: $src"
        fi
        cp "$src" "$local_dst"
        ok "installed: $local_dst (local)"
    else
        local url="${RAW_BASE}/${remote_rel}"
        if curl -fsSL "$url" -o "$local_dst"; then
            ok "installed: $local_dst"
        else
            fail "failed to download: $url"
        fi
    fi
}

# ──────────────────────────────────────────────────────────────
# Install templates
# ──────────────────────────────────────────────────────────────

install_templates() {
    step "Installing templates to ${TEMPLATES_DIR}/"

    for file in "${TEMPLATE_FILES[@]}"; do
        install_file "templates/${file}" "${TEMPLATES_DIR}/${file}"
    done
}

# ──────────────────────────────────────────────────────────────
# Install commands
# ──────────────────────────────────────────────────────────────

install_commands() {
    step "Installing commands to ${COMMANDS_DIR}/"

    for file in "${COMMAND_FILES[@]}"; do
        install_file "commands/${file}" "${COMMANDS_DIR}/${file}"
    done
}

# ──────────────────────────────────────────────────────────────
# .gitignore
# ──────────────────────────────────────────────────────────────

install_gitignore() {
    step "Updating .gitignore"

    if [ -f .gitignore ] && grep -qFx "$GITIGNORE_LINE" .gitignore; then
        skip "already has: $GITIGNORE_LINE"
        return 0
    fi

    if [ -f .gitignore ] && [ -n "$(tail -c1 .gitignore 2>/dev/null || true)" ]; then
        printf '\n' >> .gitignore
    fi
    printf '%s\n' "$GITIGNORE_LINE" >> .gitignore
    ok "added: $GITIGNORE_LINE"
}

# ──────────────────────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────────────────────

print_summary() {
    cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SpecKitLite installed.

Templates:  ${TEMPLATES_DIR}/
Commands:   ${COMMANDS_DIR}/
Gitignore:  ${GITIGNORE_LINE}

Available commands in Claude Code:
  /specl-take   — take a ticket / description (create or extend feature)
  /specl-plan   — create an implementation plan
  /specl-go     — execute a plan
  /specl-sync   — sync docs with code state

Next steps:
  Take a ticket or describe a feature: /specl-take <description>

Docs: ${REPO_URL}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# ──────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────

main() {
    say "SpecKitLite installer"
    if $LOCAL_MODE; then
        say "Source: ${SCRIPT_DIR} (local)"
    else
        say "Source: ${REPO_URL} (${REPO_BRANCH}, remote)"
    fi

    check_prerequisites
    install_templates
    install_commands
    install_gitignore
    print_summary
}

main "$@"
