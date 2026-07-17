---
name: kimi
description: >-
  Delegate a self-contained coding task to Kimi Code (Moonshot's CLI agent, K3 model) so
  it runs in the background on its own quota pool while you keep working in Claude Code,
  then Claude verifies the result (runs the tests, fixes failures) and hands you the diff.
  Use when asked to "send this to kimi", "use k3", "spawn a kimi task", run models in
  parallel, or hand off a well-scoped unit (write tests, implement a module, refactor a
  file) — especially when Claude's quota is tight. Supports fan-out across several files.
---

# /kimi — delegate a task to Kimi Code (K3)

Hand a **self-contained** coding task to the `kimi` CLI (kimi-code), running the **K3**
model. Kimi runs on its own (Moonshot/Kimi subscription) quota pool, so it's ideal for
parallelising work or conserving Claude quota. Requires kimi-code installed and signed in
(`kimi login`; binary at `~/.kimi-code/bin/kimi`).

> **Safety note — Kimi has no filesystem sandbox.** In headless `-p` mode kimi
> **auto-executes tools with no approval prompts** (it can't ask), confined only by the
> working directory + your care. (`--yolo`/`--auto` are interactive-only and *error* if
> combined with `-p`.) So **branch-by-default is not optional here** — always work on a
> throwaway branch (or a clone) and review the diff before anything lands.

## 1. Scope it — Kimi has NONE of this conversation's context

Write ONE self-contained prompt per task: the exact files/paths to touch, what to change,
the acceptance criteria, an explicit "run the tests and report results", and "stay inside
this directory — do not touch anything outside it". Resolve any `@file` mentions to
absolute paths. If the task is vague, sharpen it with the user first — a fuzzy spec wastes
a whole run. (K3 runs at its `max` reasoning effort by default; for a quicker/cheaper run
use `-m kimi-code/kimi-for-coding-highspeed` instead of `-m kimi-code/k3`.)

## 2. Safety — always branch first (there is no sandbox)

```bash
git -C "<dir>" switch -c "kimi/<slug>" 2>/dev/null || git -C "<dir>" switch "kimi/<slug>"
```
For anything risky, work in a **clone** instead so the original is untouchable.

## 3. Dispatch

**Single task** (background if it's more than a quick job — you keep working in Claude and
get re-invoked when it finishes). Run FROM the target dir so Kimi is scoped there:

```bash
cd "<dir>" && kimi -p "<self-contained prompt, incl. 'stay in this directory'>" \
  -m kimi-code/k3 --output-format text > "/tmp/kimi-<slug>.log" 2>&1
```
- `-m kimi-code/k3` selects K3 (the newest, 1M context, `max` effort). No permission flag
  is needed — headless `-p` auto-executes tools directly. Do NOT pass `--yolo`/`--auto`
  (they error with `-p`).
- To **spawn it off** and keep working in Claude, run it in the **background** (Bash
  `run_in_background: true`); you'll be re-invoked when it finishes.
- Kimi's text output includes its reasoning; the deliverable you care about is the **file
  changes**, which you review via `git diff` (step 5) — the log is just for context.

**Fan-out** — for independent units, dispatch several background runs (each in its own
dir/branch/slug), then collect. Many Kimi runs at once cost zero Claude quota.

## 4. Verify-and-fix (don't just trust it)

After it finishes, **Claude** verifies — don't take Kimi's word for it:
1. `git -C "<dir>" status` + `git -C "<dir>" diff` — see exactly what changed (and that it
   stayed in-dir; if it touched anything outside, flag it and stop).
2. Run the project's tests yourself (`npm test`, `pytest`, etc.).
3. **If they fail**, re-dispatch to Kimi with the failure output appended
   (`"Your change left these tests failing: <paste>. Fix them and re-run."`) — same
   branch/dir. Cap at **2 fix passes**; if still red, stop and report with the failures.

## 5. Review — never auto-commit

Summarise what changed + the test result, show the diff, and let the **user** decide to
keep, tweak, or discard. Only commit/merge if they ask. If Kimi reports an auth/login
problem, tell the user to run `kimi login` — don't silently retry.

## Good vs bad tasks

**Good** (hand-off-able, self-contained, checkable): "Write tests for `src/foo.mjs`; run
them." · "Implement the parser in `parser.ts` so `parser.test.ts` passes." · "Refactor
`X` into `Y`; keep the tests green."

**Bad** (keep on Claude): anything needing this conversation's context or tight
back-and-forth · iterative exploration · cross-repo orchestration · no clear acceptance check.

## Why this pattern

Kimi, Codex, and Claude each draw from **separate quota pools**, so delegating parallelises
work and spends Kimi/Moonshot quota that would otherwise sit idle. Complements the Task
tool (Claude subagents) and `/codex` (Codex): pick the pool with the most idle headroom.
