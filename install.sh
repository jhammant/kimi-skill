#!/usr/bin/env bash
# Install the /kimi skill into Claude Code (~/.claude/skills/kimi/SKILL.md).
set -euo pipefail

DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}/kimi"
SRC="$(cd "$(dirname "$0")" && pwd)/SKILL.md"

if [ ! -x "$HOME/.kimi-code/bin/kimi" ] && ! command -v kimi >/dev/null 2>&1; then
  echo "!! kimi-code isn't installed (looked for ~/.kimi-code/bin/kimi and 'kimi' on PATH)."
  echo "   Install it + run 'kimi login' first: https://moonshotai.github.io/kimi-code/"
  echo "   (installing the skill anyway — it just won't work until kimi is available)"
fi

mkdir -p "$DEST"
cp "$SRC" "$DEST/SKILL.md"
echo "✓ Installed /kimi → $DEST/SKILL.md"
echo "  Start a new Claude Code session, then try:  /kimi write tests for <file>"
