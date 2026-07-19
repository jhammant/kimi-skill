# kimi-skill

A [Claude Code](https://claude.com/claude-code) skill that delegates a self-contained
coding task to **[Kimi Code](https://moonshotai.github.io/kimi-code/)** (Moonshot's CLI
agent, **K3** model) — running it in the background on its **own quota pool** while you
keep working in Claude, then handing you the diff to review.

Three coding agents (Claude, Codex, Kimi), one terminal, three separate quotas. Hand
well-scoped units to whichever pool has idle headroom.

## Why

- **Parallelism.** K3 churns on a hand-off-able task while you keep moving in Claude.
- **Separate quota.** Kimi runs on your Moonshot/Kimi subscription — doesn't touch Claude
  (or Codex) quota, and spends Kimi capacity that would otherwise sit idle.
- **Verified, not trusted.** After Kimi finishes, Claude runs the tests and, if they fail,
  sends the failures back to Kimi to fix (bounded retries) before you see it.
- **Reviewed.** Work lands on a `kimi/<slug>` branch and the skill never auto-commits.

> ⚠️ Kimi has **no filesystem sandbox** (unlike codex). It runs with `--yolo`
> (auto-approved actions), confined only by the working dir — so the skill **always
> branches first** and reviews the diff. For risky work, run it in a clone.

## Install

Requires [kimi-code](https://moonshotai.github.io/kimi-code/) installed and signed in
(`kimi login`; binary at `~/.kimi-code/bin/kimi`).

```bash
git clone <this repo> kimi-skill && cd kimi-skill
./install.sh          # copies SKILL.md to ~/.claude/skills/kimi/SKILL.md
```

Start a new Claude Code session, then:

```
/kimi write tests for src/parser.ts covering the empty-input and unicode cases
```

## Model & effort

`-m kimi-code/k3` selects **K3** (newest, runs at `max` reasoning effort by default).
For a lighter/faster run use `-m kimi-code/kimi-for-coding` (K2.7) or
`kimi-code/kimi-for-coding-highspeed`. Aliases live in `~/.kimi-code/config.toml`.
Reasoning effort accepts `none | minimal | low | medium | high | max` (K3's default is `max`).

## Seeing your quota / limits

Kimi Code has **two rolling limits** (a Codex-style split): a **5-hour** window and a
**weekly (7-day)** window that refreshes from your subscription date; unused quota does not
roll over. **The only way to see them is `/usage` in the kimi TUI**, which renders:

```
Weekly limit  ███░░░░░░  15% used   resets in 4d 13h 51m
5h limit      ████░░░░░  19% used   resets in 1h 51m
Session usage ░░░░░░░░░   0%        (0 / 1M context)
```

### Why there is no programmatic quota readout
Reverse-engineered thoroughly — the CLI respects `HTTPS_PROXY` and does **not** pin certs,
so a local MITM sees everything, and the finding is that **nothing carries the plan quota**:

- No usage/limits HTTP endpoint — `/usage`, `/me`, `/limits`, `/quota`, `/balance` all `404`.
- `chat/completions` and `/models` responses carry token `usage` only — **no** rate-limit % or reset.
- No rate-limit response headers; no WebSocket frame carries quota.
- The panel numbers are computed/cached opaquely (hashed blobs), surfaced only by `/usage`.

So unlike Claude (OAuth `/usage` endpoint) or Codex (`rate_limits` in every rollout), **Kimi
exposes no pollable quota** — the `/usage` panel is the single source of truth.

### `scripts/kimi-usage.sh` (experimental)
Drives the TUI via `tmux`, types `/usage`, and prints the panel — the only programmatic read
available. It **works but is fragile**: it depends on `tmux`, TUI boot timing, and the panel
layout, so treat it as best-effort, not a stable API. Usage: `./scripts/kimi-usage.sh`.

## License

MIT.
