#!/usr/bin/env bash
# ==============================================================================
# Night Light (wlsunset) Toggle Script for Niri
# Cycles between: Automatic -> Day (Forced High) -> Night (Forced Low)
# ==============================================================================
set -euo pipefail

LAT="10.8"
LON="106.6"
NIGHT_TEMP="4000"
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/wlsunset_state_${UID}"

if ! pgrep -x wlsunset > /dev/null; then
    wlsunset -l "$LAT" -L "$LON" -t "$NIGHT_TEMP" &
    echo "auto" > "$STATE_FILE"
    notify-send -a "Night Light" -i display "Night Light" "Started wlsunset (Auto: ${LAT}°N, ${LON}°E)" -t 2500
    exit 0
fi

# Send SIGUSR1 to cycle wlsunset mode (Auto -> Day -> Night -> Auto)
pkill -USR1 -x wlsunset

CURRENT_STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "auto")

case "$CURRENT_STATE" in
    "auto")
        echo "day" > "$STATE_FILE"
        notify-send -a "Night Light" -i display "Night Light" "Mode: Day (6500K / Disabled)" -t 2000
        ;;
    "day")
        echo "night" > "$STATE_FILE"
        notify-send -a "Night Light" -i weather-clear-night "Night Light" "Mode: Night (${NIGHT_TEMP}K / Active)" -t 2000
        ;;
    "night"|*)
        echo "auto" > "$STATE_FILE"
        notify-send -a "Night Light" -i weather-sunset "Night Light" "Mode: Auto (Location Schedule)" -t 2000
        ;;
esac
