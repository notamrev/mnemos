#!/usr/bin/env bash
# Sets up the Mnemos development environment:
#   1. Symlinks Claude Code commands into ~/.claude/commands/
#   2. Configures git to use .githooks/ (branch protection, commit format)
#
# Usage:
#   .claude/install.sh            # install
#   .claude/install.sh --uninstall  # remove

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COMMANDS_SRC="$REPO_ROOT/.claude/commands"
COMMANDS_DST="$HOME/.claude/commands"
PREFIX="mnemos-"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

uninstall=false
for arg in "$@"; do
  [[ "$arg" == "--uninstall" ]] && uninstall=true
done

# ── Uninstall ──────────────────────────────────────────────────────────────
if $uninstall; then
  echo "Uninstalling Mnemos..."
  echo ""

  echo "Removing Claude commands from $COMMANDS_DST ..."
  for src in "$COMMANDS_SRC"/${PREFIX}*.md; do
    name="$(basename "$src")"
    dst="$COMMANDS_DST/$name"
    if [[ -L "$dst" ]]; then
      rm "$dst"
      echo -e "  ${YELLOW}removed${NC}  /${name%.md}"
    fi
  done

  echo "Restoring default git hooks path..."
  git -C "$REPO_ROOT" config --unset core.hooksPath 2>/dev/null || true

  echo ""
  echo "Done. Run without --uninstall to reinstall."
  exit 0
fi

# ── Install Claude commands ────────────────────────────────────────────────
mkdir -p "$COMMANDS_DST"
echo -e "${BOLD}1. Claude Code commands${NC} → $COMMANDS_DST"
echo ""

cmd_installed=0
cmd_skipped=0

for src in "$COMMANDS_SRC"/${PREFIX}*.md; do
  name="$(basename "$src")"
  dst="$COMMANDS_DST/$name"
  command_name="${name%.md}"

  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    echo -e "   ${YELLOW}up-to-date${NC}  /$command_name"
    ((cmd_skipped++)) || true
  elif [[ -e "$dst" && ! -L "$dst" ]]; then
    echo -e "   ${RED}conflict${NC}    /$command_name — file exists and is not a symlink, skipping"
    ((cmd_skipped++)) || true
  else
    ln -sf "$src" "$dst"
    echo -e "   ${GREEN}installed${NC}   /$command_name"
    ((cmd_installed++)) || true
  fi
done

echo ""
echo -e "   $cmd_installed installed, $cmd_skipped already up-to-date"

# ── Configure git hooks ────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}2. Git hooks${NC} → .githooks/"
echo ""

git -C "$REPO_ROOT" config core.hooksPath .githooks
echo -e "   ${GREEN}configured${NC}  core.hooksPath = .githooks"

hooks=(pre-commit commit-msg prepare-commit-msg pre-push)
for hook in "${hooks[@]}"; do
  hook_path="$REPO_ROOT/.githooks/$hook"
  if [[ -x "$hook_path" ]]; then
    echo -e "   ${GREEN}active${NC}      $hook"
  else
    echo -e "   ${RED}missing${NC}     $hook — run: chmod +x .githooks/$hook"
  fi
done

# ── Summary ────────────────────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────────────────────"
echo ""
echo -e "${BOLD}Branch rules enforced:${NC}"
echo "  • No commits directly to main (pre-commit)"
echo "  • Conventional commit messages (commit-msg)"
echo "  • Branch naming: feat|fix|test|chore/<issue#>-<desc> (pre-push)"
echo "  • No direct pushes to main (pre-push)"
echo ""
echo -e "${BOLD}Workflow:${NC}"
echo "  1. Pick a task from the board"
echo "  2. git checkout -b feat/<issue#>-<description>"
echo "  3. Write tests first (TDD), then implement"
echo "  4. /mnemos-pr <issue#> to open PR"
echo "  5. /mnemos-done <issue#> after merge"
echo ""
echo "Run with --uninstall to remove."
