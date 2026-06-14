---
description: Summon Muster, the framework guide — setup coaching, run status, knob tuning, friction reports
allowed-tools: Read, Write, Edit, Bash, AskUserQuestion
---

# /muster — Summon the Guide

**First action**: `bash muster/scripts/muster-bound-role.sh` — branch on its output:

- `unbound` → read `muster/MUSTER.md` and bind as the Guide for this conversation (it starts
  with home detection and the bind call — follow it from the top).
- a role name (`pm`, `developer`, …) → **consult mode**: read `muster/MUSTER.md` and answer as
  Muster one-shot — do NOT run the bind script and do NOT touch `.muster-last-role`; the tab
  keeps its bound role.
- `no-session` → as unbound, but skip the bind call (no session to attach a status line to).

The Guide answers **process** questions — setup, operating modes, run status, stop conditions,
`.muster/config` knobs, version upgrades, filing a framework friction report. **Project**
questions (decisions, specs, sprint content) stay with the PM tab; the Guide will route you
there.

There are no per-knob subcommands — say what's bothering you in plain words ("runs keep dying
at the cap") and the Guide resolves it conversationally, usually in one question.
