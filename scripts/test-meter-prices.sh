#!/usr/bin/env bash
# test-meter-prices.sh — fixture gate for muster-meter.py's --prices loading.
# Pins the pricing contract: a --prices file prices ANY vendor's models (no claude- filter —
# the foreign-model port path), claude models still price, LiteLLM's sample_spec schema entry
# and cost-key-less entries are skipped, and longest-prefix matching picks the most specific
# rate. First meter fixture; the meter's session-log rollup itself is out of scope here.
set -uo pipefail
MUSTER="$(cd "$(dirname "$0")/.." && pwd)"
SB="$(mktemp -d "${TMPDIR:-/tmp}/muster-meter-test.XXXXXX")"
trap 'rm -rf "$SB"' EXIT

command -v python3 >/dev/null 2>&1 || { echo "FAIL: python3 required"; exit 1; }

cat > "$SB/prices.json" <<'EOF'
{
  "sample_spec": {"input_cost_per_token": 0.0, "output_cost_per_token": 0.0},
  "claude-opus-4-8": {"input_cost_per_token": 5e-06, "output_cost_per_token": 2.5e-05},
  "gpt-5o": {"input_cost_per_token": 2e-06, "output_cost_per_token": 8e-06},
  "gpt-5o-mini": {"input_cost_per_token": 1e-07, "output_cost_per_token": 4e-07},
  "no-costs-entry": {"max_tokens": 4096}
}
EOF

python3 - "$MUSTER/scripts/muster-meter.py" "$SB/prices.json" <<'EOF'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("meter", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
rates = m.load_prices(sys.argv[2])
keys = [k for k, _ in rates]
fails = 0
def t(name, cond):
    global fails
    print(("PASS: " if cond else "FAIL: ") + name)
    if not cond: fails += 1

t("foreign model loads (no vendor filter)", "gpt-5o" in keys)
t("claude model still loads", "claude-opus-4-8" in keys)
t("sample_spec skipped", "sample_spec" not in keys)
t("entry without cost keys skipped", "no-costs-entry" not in keys)
t("foreign model prices ($ /MTok input=2.0)", (m.rate_for("gpt-5o", rates) or [0])[0] == 2.0)
t("longest prefix wins (gpt-5o-mini-2 -> mini rate)", abs((m.rate_for("gpt-5o-mini-2", rates) or [0])[0] - 0.1) < 1e-9)
t("unknown model stays unpriced (None)", m.rate_for("totally-unknown", rates) is None)
print("----")
print(f"RESULT: {7 - fails}/7 passed" + ("" if fails == 0 else f" — {fails} FAILED"))
sys.exit(1 if fails else 0)
EOF
