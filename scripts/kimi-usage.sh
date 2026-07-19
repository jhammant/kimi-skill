#!/usr/bin/env bash
# Prints your Kimi Code 5h + weekly quota by calling the same endpoint the app's
# `/usage` panel uses: GET https://api.kimi.com/coding/v1/usages (plural), with your
# OAuth access token. No TUI, no screen-scraping.
#
# Needs: `node` (bundled with kimi-code) and a logged-in ~/.kimi-code. The access
# token is short-lived (~15min) and refreshed by the kimi CLI — on a 401 just run any
# `kimi` command to refresh, then retry.
set -euo pipefail

node --input-type=module <<'NODE'
import fs from 'node:fs'; import os from 'node:os'; import path from 'node:path';

const creds = path.join(os.homedir(), '.kimi-code', 'credentials', 'kimi-code.json');
let tok; try { tok = JSON.parse(fs.readFileSync(creds, 'utf8')).access_token; } catch { /* handled below */ }
if (!tok) { console.error('kimi-usage: not logged in (no ~/.kimi-code credentials) — run `kimi login`'); process.exit(2); }

const ctrl = new AbortController();
const timer = setTimeout(() => ctrl.abort(), 8000);
let r;
try {
  r = await fetch('https://api.kimi.com/coding/v1/usages', { headers: { Authorization: 'Bearer ' + tok }, signal: ctrl.signal });
} catch (e) { console.error(`kimi-usage: request failed (${e.name})`); process.exit(1); }
finally { clearTimeout(timer); }

if (r.status === 401) { console.error('kimi-usage: token expired — run any `kimi` command to refresh, then retry'); process.exit(3); }
if (!r.ok) { console.error(`kimi-usage: HTTP ${r.status}`); process.exit(1); }
const d = await r.json();

const pct = (u, l) => { const n = Number(u), m = Number(l); return m > 0 ? Math.round((n / m) * 100) : 0; };
const bar = (p) => { const n = Math.max(0, Math.min(20, Math.round(p / 5))); return '█'.repeat(n) + '░'.repeat(20 - n); };
const when = (t) => { const h = (Date.parse(t) - Date.now()) / 3.6e6; return !Number.isFinite(h) ? '?' : h >= 24 ? `${(h / 24).toFixed(1)}d` : `${h.toFixed(1)}h`; };
const line = (label, x) => console.log(`  ${label.padEnd(12)} ${bar(pct(x.used, x.limit))}  ${String(pct(x.used, x.limit)).padStart(3)}% used   resets in ${when(x.resetTime)}`);

console.log(`Kimi Code — ${(d.user?.membership?.level || '').replace(/^LEVEL_/, '') || '?'}`);
const five = (d.limits || []).find((l) => { const w = l.window || {}; const m = w.timeUnit === 'TIME_UNIT_HOUR' ? w.duration * 60 : w.duration; return m && m <= 360; });
if (five?.detail) line('5h limit', five.detail);
if (d.usage) line('Weekly limit', d.usage);
if (d.parallel?.limit) console.log(`  Parallel requests: up to ${d.parallel.limit}`);
NODE
