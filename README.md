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

## License

MIT.
