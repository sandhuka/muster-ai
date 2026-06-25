# Config Knobs — The `.muster/config` Contract

User control is a feature: great platforms let users tune the system to their way of working,
and the Guide amortizes the learning curve knobs used to cost. This skill is the contract plus
the resolution flow.

## The Contract

- **File**: `./.muster/config` at the project root. Plain `KNOB=value` lines, bash-sourced by
  the sprint driver at start. Template ships at setup with everything commented out.
- **Committed, not gitignored** — worktrees inherit it, so autonomous runs see it. This is the
  durable layer: never edit `muster/` scripts, never rely on remembering an env prefix.
- **Precedence**: explicit env at invocation > `.muster/config` > built-in default. The driver
  enforces this; a config value never overrides what the user typed on the command line.

## Day-One Knobs

Every variable the driver reads from the environment is a knob — they exist, so exposing them
is free:

| Knob | Default | What it tunes |
|---|---|---|
| `MAX_STEPS` | 30 | Run budget — cost circuit-breaker per driver run |
| `MAX_TURNS` | 150 | Per-step model-turn budget — raise for heavy-but-cohesive steps |
| `ANTHROPIC_MODEL` | account default | Session-default model (per-step `Model:` queue lines still win for their step) |
| `KEEP_RUNS` | 20 | How many runs of logs the driver keeps |
| `LIMIT_RESUME_AT` | unset | `HH:MM` fallback resume time when a usage-limit reset isn't parseable |
| `CTX_WARN_PCT` | 80 | Peak-ctx % above which a step is flagged as running hot (a step-sizing signal); `0` disables the warning |
| `MUSTER_COLOR` | 0 | `1` colors the agent name + bolds key figures in the live trail (terminal only — auto-off when output isn't a TTY, so `.log` files stay plain) |

**No speculative knobs.** New knobs arrive only through the knob-ify disposition — recurring
field reports proving real demand for varying a behavior. Control without sprawl.

## The One-Tap Resolution Flow

When a friction is knob-shaped ("runs keep dying at the cap", "routine steps are burning my
window"):

1. **AskUserQuestion** — concrete options, tradeoffs in the descriptions. E.g.:
   *"Raise the run budget?"* → `MAX_STEPS=15` ("longer walk-away runs; more spend per run") /
   `keep 8` ("runs stay inside one Pro window") / custom.
2. **Write the file** — add or update the line in `.muster/config` (create the file from the
   template shape if missing). You may write this file (the Guide's write boundary allows
   framework plumbing).
3. **Commit it** — `git add .muster/config && git commit -m "tune .muster/config"`. This is
   load-bearing, not optional: sprint worktrees are created with `git worktree add`, which checks
   out the **committed** tip — an uncommitted edit never reaches the autonomous run, so the knob
   silently wouldn't apply and your "it rides into worktrees" promise would be false. (No git repo?
   Then say so plainly: the edit applies to in-place runs but there are no worktree sprints to ride
   into — git is what autonomous mode is built on.)
4. **Confirm** — echo the new line and when it takes effect (next driver start; running steps
   are unaffected). Now "it's committed — the change rides into future worktrees" is true.

The whole exchange is still two messages (the commit is silent plumbing). If you've written a
paragraph about what `MAX_STEPS` means, you're explaining, not resolving.
