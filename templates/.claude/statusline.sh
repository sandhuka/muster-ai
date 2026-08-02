#!/bin/bash
# Muster status-line stub — framework-owned; overwritten on every muster update. The logic
# lives in muster/scripts/muster-statusline.sh (updates on submodule bump — never edit here).
# Custom statusline? Compose with muster/scripts/muster-bound-role.sh instead of editing this.
if [ -f "muster/scripts/muster-statusline.sh" ]; then
    exec bash muster/scripts/muster-statusline.sh
fi
echo "[muster: submodule missing]"
