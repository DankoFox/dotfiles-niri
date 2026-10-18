#!/usr/bin/env bash
# ==============================================================================
# Toggle wlogout (opens if closed, closes if already open)
# ==============================================================================
set -euo pipefail

# If wlogout is currently active, toggle it off
if pgrep -x "wlogout" >/dev/null; then
    pkill -x "wlogout"
    exit 0
fi

# Detect current display geometry to calculate compact center margins
read -r screen_w screen_h <<< "$(niri msg focused-output 2>/dev/null | grep "Logical size" | sed -E 's/.*Logical size: ([0-9]+)x([0-9]+).*/\1 \2/' || echo "1920 1080")"

screen_w="${screen_w:-1920}"
screen_h="${screen_h:-1080}"

# Target button cluster: compact dimensions (~105px high, ~750px wide)
target_h=105
target_w=750

v_margin=$(( (screen_h - target_h) / 2 ))
h_margin=$(( (screen_w - target_w) / 2 ))

# Clamp margins to safe bounds
(( v_margin < 40 )) && v_margin=40
(( h_margin < 40 )) && h_margin=40

exec wlogout -b 6 -c 12 -r 12 -T "$v_margin" -B "$v_margin" -L "$h_margin" -R "$h_margin"
