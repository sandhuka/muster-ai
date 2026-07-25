#!/usr/bin/env python3
"""muster-meter — what did this build actually cost? Project-lifetime telemetry from
Claude Code session logs.

Tokens are the currency; this measures them. The sprint driver already meters autonomous
runs per-step (`.muster-sprint-logs/*.metrics`); muster-meter is the whole-project rollup —
interactive sessions AND autonomous runs, across the main checkout and its sprint worktrees:

  - ACTIVE BUILD TIME  = sum of gaps between consecutive session-log events across all
                         given project dirs, each gap capped (default 300 s). Machine+human
                         working time; report it as *active build*, never as elapsed time.
  - OPERATOR ATTENTION = same gap math over human-typed prompts only — the human-time metric.
  - TOKENS by model    = assistant API calls deduped by message id (resumed sessions replay
                         history into new files; dedupe prevents double counting).
  - COST               = API list price from the embedded rate table (source: LiteLLM
                         model_prices_and_context_window.json, snapshot 2026-07-24).
                         Override/refresh with --prices <litellm.json>.
  - ELAPSED            = distinct git commit-days when --repo is given (the conservative,
                         trivially-checkable fallback).

Honest-reporting rules: state measured values exactly (a $147 reads as measured; a $150
reads as marketing); label the time "active build", never "built in N hours"; costs are
list-price cost-to-replicate, not subscription spend. Session logs are pruned after
`cleanupPeriodDays` — snapshot `--json` output periodically if the numbers must outlive them.

Usage:
  muster-meter.py <project-path> [<project-path-or-glob> ...] [--repo <git-dir>]
                  [--gap 300] [--prices litellm.json] [--json]

Project paths are real folders (globs OK — include sprint worktrees):
  muster-meter.py ~/Desktop/my-app '~/Desktop/my-app-sprint-auto-*' --repo ~/Desktop/my-app
"""

import argparse, glob, json, os, subprocess, sys
from datetime import datetime, timezone

PROJECTS_ROOT = os.path.expanduser("~/.claude/projects")

# $/MTok: (input, cache_write_5m, cache_write_1h, cache_read, output) — prefix-matched, first wins.
RATES = [
    ("claude-fable-5",   (10.0, 12.5, 20.0, 1.0, 50.0)),
    ("claude-mythos-5",  (10.0, 12.5, 20.0, 1.0, 50.0)),
    ("claude-sonnet-5",  (2.0, 2.5, 4.0, 0.2, 10.0)),
    ("claude-opus-5",    (5.0, 6.25, 10.0, 0.5, 25.0)),
    ("claude-opus-4-8",  (5.0, 6.25, 10.0, 0.5, 25.0)),
    ("claude-opus-4-5",  (5.0, 6.25, 10.0, 0.5, 25.0)),
    ("claude-opus-4",    (15.0, 18.75, 30.0, 1.5, 75.0)),   # 4.0/4.1 legacy pricing
    ("claude-sonnet-4-5",(3.0, 3.75, 6.0, 0.3, 15.0)),
    ("claude-sonnet-4",  (3.0, 3.75, 6.0, 0.3, 15.0)),
    ("claude-haiku-4-5", (1.0, 1.25, 2.0, 0.1, 5.0)),
    ("claude-haiku-3-5", (0.8, 1.0, 1.6, 0.08, 4.0)),
]

def encode(path):
    """Real project path -> ~/.claude/projects dir name (/ and . become -)."""
    return path.rstrip("/").replace("/", "-").replace(".", "-")

def load_prices(path):
    rates = []
    d = json.load(open(path))
    for k, v in d.items():
        if not k.startswith("claude-"):
            continue
        try:
            rates.append((k, (v["input_cost_per_token"] * 1e6,
                              v.get("cache_creation_input_token_cost", v["input_cost_per_token"] * 1.25) * 1e6,
                              v.get("cache_creation_input_token_cost_above_1hr", v["input_cost_per_token"] * 2) * 1e6,
                              v.get("cache_read_input_token_cost", v["input_cost_per_token"] * 0.1) * 1e6,
                              v["output_cost_per_token"] * 1e6)))
        except KeyError:
            continue
    rates.sort(key=lambda r: -len(r[0]))  # longest prefix first
    return rates

def rate_for(model, rates):
    for prefix, r in rates:
        if model.startswith(prefix):
            return r
    return None

def parse_ts(s):
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp()
    except (ValueError, AttributeError):
        return None

def gap_sum(stamps, cap):
    stamps = sorted(stamps)
    return sum(min(b - a, cap) for a, b in zip(stamps, stamps[1:]))

def fmt_h(seconds):
    h, m = int(seconds // 3600), int(seconds % 3600 // 60)
    return f"{h}h {m:02d}m"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("paths", nargs="+", help="project folders (globs OK, include sprint worktrees)")
    ap.add_argument("--gap", type=int, default=300, help="gap cap in seconds (default 300)")
    ap.add_argument("--repo", help="git repo for distinct commit-days")
    ap.add_argument("--prices", help="LiteLLM model-prices JSON to override the embedded table")
    ap.add_argument("--json", action="store_true", dest="as_json")
    args = ap.parse_args()

    rates = load_prices(args.prices) if args.prices else RATES

    # Resolve real-path args/globs -> encoded session-log dirs that actually exist.
    dirs = []
    for p in args.paths:
        p = os.path.expanduser(p)
        matches = glob.glob(p) or [p]           # glob may match nothing if worktree was deleted…
        for m in matches:
            enc = os.path.join(PROJECTS_ROOT, encode(m))
            if os.path.isdir(enc) and enc not in dirs:
                dirs.append(enc)
        # …but its session logs survive deletion: glob the encoded name too.
        for enc in glob.glob(os.path.join(PROJECTS_ROOT, encode(p))):
            if os.path.isdir(enc) and enc not in dirs:
                dirs.append(enc)
    if not dirs:
        sys.exit("no session-log dirs found under ~/.claude/projects for the given paths")

    stamps, human_stamps = [], []
    seen_msg, models = set(), {}
    files = calls_raw = human_prompts = 0
    for d in dirs:
        for f in glob.glob(os.path.join(d, "*.jsonl")):
            files += 1
            for line in open(f, errors="replace"):
                try:
                    e = json.loads(line)
                except json.JSONDecodeError:
                    continue
                ts = parse_ts(e.get("timestamp", ""))
                if ts:
                    stamps.append(ts)
                    if (e.get("type") == "user"
                            and (e.get("origin") or {}).get("kind") == "human"):
                        human_stamps.append(ts)
                        human_prompts += 1
                if e.get("type") != "assistant":
                    continue
                m = e.get("message") or {}
                mid = m.get("id")
                calls_raw += 1
                if mid:
                    if mid in seen_msg:
                        continue
                    seen_msg.add(mid)
                u = m.get("usage") or {}
                cc = u.get("cache_creation") or {}
                row = models.setdefault(m.get("model", "?"), [0, 0, 0, 0, 0, 0])
                row[0] += u.get("input_tokens", 0)
                cw5 = cc.get("ephemeral_5m_input_tokens")
                cw1 = cc.get("ephemeral_1h_input_tokens", 0)
                if cw5 is None:                       # old logs: no split -> price all at 5m
                    cw5, cw1 = u.get("cache_creation_input_tokens", 0), 0
                row[1] += cw5
                row[2] += cw1
                row[3] += u.get("cache_read_input_tokens", 0)
                row[4] += u.get("output_tokens", 0)
                row[5] += 1

    active = gap_sum(stamps, args.gap)
    attention = gap_sum(human_stamps, args.gap)
    days = sorted({datetime.fromtimestamp(t, tz=timezone.utc).date().isoformat() for t in stamps})

    total_cost, unpriced, rows = 0.0, [], []
    for model, r in sorted(models.items(), key=lambda kv: -kv[1][4]):
        if model in ("?", "<synthetic>"):
            continue
        rt = rate_for(model, rates)
        cost = None
        if rt:
            cost = (r[0]*rt[0] + r[1]*rt[1] + r[2]*rt[2] + r[3]*rt[3] + r[4]*rt[4]) / 1e6
            total_cost += cost
        else:
            unpriced.append(model)
        rows.append((model, r, cost))

    commit_days = None
    if args.repo:
        try:
            out = subprocess.run(["git", "-C", os.path.expanduser(args.repo), "log",
                                  "--format=%ad", "--date=short"],
                                 capture_output=True, text=True, check=True).stdout.split()
            commit_days = len(set(out))
        except subprocess.CalledProcessError:
            commit_days = None

    if args.as_json:
        print(json.dumps({
            "dirs": dirs, "files": files,
            "active_build_seconds": round(active), "operator_attention_seconds": round(attention),
            "human_prompts": human_prompts, "active_days": days,
            "gap_cap_seconds": args.gap, "git_commit_days": commit_days,
            "models": {m: dict(zip(["input", "cache_w_5m", "cache_w_1h", "cache_r", "output", "calls"], r))
                       for m, r, _ in rows},
            "cost_usd_list_price": round(total_cost, 2), "unpriced_models": unpriced,
        }, indent=2))
        return

    print(f"── muster-meter · {len(dirs)} dir(s) · {files} session file(s) ──")
    for d in dirs:
        print(f"   {d}")
    print(f"window:            {days[0]} → {days[-1]}  ({len(days)} distinct active days, UTC)")
    if commit_days is not None:
        print(f"git commit-days:   {commit_days}")
    print(f"active build:      {fmt_h(active)}   (gaps ≤ {args.gap}s over {len(stamps):,} events)")
    print(f"operator attention:{fmt_h(attention):>9}   ({human_prompts:,} typed prompts)")
    print(f"{'model':<24}{'calls':>6}{'input':>10}{'cache-w':>12}{'cache-r':>14}{'output':>10}{'cost':>10}")
    for model, r, cost in rows:
        print(f"{model:<24}{r[5]:>6}{r[0]:>10,}{r[1]+r[2]:>12,}{r[3]:>14,}{r[4]:>10,}"
              + (f"{cost:>10,.2f}" if cost is not None else "  UNPRICED"))
    print(f"{'TOTAL (API list price)':<66}${total_cost:,.2f}")
    if calls_raw != sum(r[5] for _, r, _ in rows):
        print(f"note: {calls_raw - sum(r[5] for _, r, _ in rows)} duplicate/synthetic assistant events excluded")
    if unpriced:
        print(f"⚠ UNPRICED models (excluded from total): {', '.join(unpriced)} — add rates or pass --prices")

if __name__ == "__main__":
    main()
