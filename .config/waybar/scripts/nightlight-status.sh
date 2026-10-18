#!/usr/bin/env bash
# ==============================================================================
# Night Light (wlsunset) Status Helper for Waybar
# Returns JSON for Waybar custom module
# ==============================================================================
set -euo pipefail

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/wlsunset_state_${UID}"
CURRENT_STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "auto")

if ! pgrep -x wlsunset > /dev/null; then
    printf '{"text":"󰖨","alt":"off","tooltip":"Night Light: Off (Not running)\\nClick to start","class":"off"}\n'
    exit 0
fi

case "$CURRENT_STATE" in
    "night")
        printf '{"text":"󰖔","alt":"night","tooltip":"Night Light: Night (4000K Forced)\\nClick to cycle mode","class":"night"}\n'
        ;;
    "day")
        printf '{"text":"󰖙","alt":"day","tooltip":"Night Light: Day (Disabled)\\nClick to cycle mode","class":"day"}\n'
        ;;
    "auto"|*)
        printf '{"text":"󰖚","alt":"auto","tooltip":"Night Light: Auto (Location Schedule)\\nClick to cycle mode","class":"auto"}\n'
        ;;
esac
