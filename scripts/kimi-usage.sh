#!/usr/bin/env bash
# EXPERIMENTAL / FRAGILE. Reads Kimi Code's 5h + weekly plan quota by driving the
# app's `/usage` panel via tmux. Kimi exposes NO quota API (see README "Seeing your
# quota / limits"), so this screen-scrapes the TUI. It depends on tmux, TUI boot
# timing, and the panel layout — treat it as best-effort, not a stable interface.
#
# Env: KIMI_BIN (default ~/.kimi-code/bin/kimi), KIMI_BOOT (default 16s).
set -euo pipefail

KIMI="${KIMI_BIN:-$HOME/.kimi-code/bin/kimi}"
command -v tmux >/dev/null 2>&1 || { echo "kimi-usage: needs tmux" >&2; exit 2; }
[ -x "$KIMI" ] || { echo "kimi-usage: kimi not found at $KIMI" >&2; exit 2; }

S="kimiusage_$$"
cleanup() { tmux kill-session -t "$S" 2>/dev/null || true; }
trap cleanup EXIT
tmux kill-session -t "$S" 2>/dev/null || true
# Run a persistent shell, then launch kimi into it — so the session survives even
# if kimi exits (we detect that as "no panel" rather than a dead tmux server).
tmux new-session -d -s "$S" -x 200 -y 50
tmux send-keys -t "$S" "cd /tmp && '$KIMI'" Enter

attempt_read() {
  tmux send-keys -t "$S" "/usage"; sleep 1; tmux send-keys -t "$S" Enter
  for _ in $(seq 1 12); do
    sleep 1
    pane="$(tmux capture-pane -t "$S" -p 2>/dev/null || true)"
    if printf '%s' "$pane" | grep -qiE "weekly limit|5h limit"; then
      printf '%s' "$pane"; return 0
    fi
  done
  return 1
}

sleep "${KIMI_BOOT:-16}"   # let the TUI boot (varies; may show a load progress bar)
for _ in 1 2 3; do
  if pane="$(attempt_read)"; then
    printf '%s\n' "$pane" \
      | grep -iE "weekly limit|5h limit|session usage|resets in|% used" \
      | sed -E 's/[│]//g; s/^[[:space:]]*//; s/[[:space:]]*$//'
    exit 0
  fi
  sleep 3
done

echo "kimi-usage: couldn't read the /usage panel (TUI timing). Run /usage manually in kimi, or retry." >&2
exit 1
