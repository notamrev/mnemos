#!/usr/bin/env bash
# Installs Mnemos Claude Code commands globally by symlinking them into
# ~/.claude/commands/. Symlinks mean repo updates are reflected immediately
# without re-running this script.
#
# Usage:
#   .claude/install.sh            # install
#   .claude/install.sh --uninstall  # remove symlinks

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COMMANDS_SRC="$REPO_ROOT/.claude/commands"
COMMANDS_DST="$HOME/.claude/commands"
PREFIX="mnemos-"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

uninstall=false
for arg in "$@"; do
  [[ "$arg" == "--uninstall" ]] && uninstall=true
done

mkdir -p "$COMMANDS_DST"

if $uninstall; then
  echo "Uninstalling Mnemos commands from $COMMANDS_DST ..."
  for src in "$COMMANDS_SRC"/${PREFIX}*.md; do
    name="$(basename "$src")"
    dst="$COMMANDS_DST/$name"
    if [[ -L "$dst" ]]; then
      rm "$dst"
      echo -e "  ${YELLOW}removed${NC}  /$name"
    else
      echo -e "  ${YELLOW}skipped${NC}  /$name (not a symlink — not touching it)"
    fi
  done
  echo ""
  echo "Done. Run without --uninstall to reinstall."
  exit 0
fi

echo "Installing Mnemos commands → $COMMANDS_DST"
echo ""

installed=0
skipped=0

for src in "$COMMANDS_SRC"/${PREFIX}*.md; do
  name="$(basename "$src")"
  dst="$COMMANDS_DST/$name"
  command_name="${name%.md}"

  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    echo -e "  ${YELLOW}up-to-date${NC}  /$command_name"
    ((skipped++)) || true
  else
    if [[ -e "$dst" && ! -L "$dst" ]]; then
      echo -e "  ${RED}conflict${NC}    /$command_name — $dst exists and is not a symlink, skipping"
      ((skipped++)) || true
      continue
    fi
    ln -sf "$src" "$dst"
    echo -e "  ${GREEN}installed${NC}   /$command_name → $src"
    ((installed++)) || true
  fi
done

echo ""
echo "────────────────────────────────────────"
echo "$installed installed, $skipped already up-to-date"
echo ""
echo "Available commands:"
for src in "$COMMANDS_SRC"/${PREFIX}*.md; do
  name="$(basename "${src%.md}")"
  echo "  /$name"
done
echo ""
echo "Run with --uninstall to remove all symlinks."
