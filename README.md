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
roll over. In the app, `/usage` in the kimi TUI renders them:

```
Weekly limit  ███░░░░░░  15% used   resets in 4d 13h 51m
5h limit      ████░░░░░  19% used   resets in 1h 51m
Session usage ░░░░░░░░░   0%        (0 / 1M context)
```

### Reading it programmatically

That `/usage` panel is just a client-side render of **one authenticated REST call**:

```
GET https://api.kimi.com/coding/v1/usages     Authorization: Bearer <oauth access token>
```

Note the **plural** `usages` — singular `/usage` `404`s. The token lives in
`~/.kimi-code/credentials/kimi-code.json` (`access_token`); it's short-lived (~15 min) and
the kimi CLI refreshes it, so poll right after using kimi, or handle a `401` by running any
`kimi` command to refresh. The response is server-authoritative (it agrees across machines):

```jsonc
{ "user":   { "membership": { "level": "LEVEL_ADVANCED" } },
  "usage":  { "limit":"100","used":"17","remaining":"83","resetTime":"…" },   // weekly window
  "limits": [{ "window": { "duration":300, "timeUnit":"TIME_UNIT_MINUTE" },   // 5h window (300 min)
               "detail": { "limit":"100","used":"30","remaining":"70","resetTime":"…" } }],
  "parallel": { "limit":"30" } }                                              // max concurrent requests
```

`limit` is normalised to 100, so `used` is already the percentage.

### `scripts/kimi-usage.sh`
Calls that endpoint and prints your 5h + weekly bars — no TUI, no scraping:

```bash
./scripts/kimi-usage.sh
# Kimi Code — ADVANCED
#   5h limit     ██████░░░░░░░░░░░░░░   30% used   resets in 1.1h
#   Weekly limit ███░░░░░░░░░░░░░░░░░   17% used   resets in 4.5d
#   Parallel requests: up to 30
```

Needs `node` (bundled with kimi-code) and a logged-in `~/.kimi-code`.

## License

MIT.
