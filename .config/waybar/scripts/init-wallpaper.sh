#!/usr/bin/env bash
# ==============================================================================
# Initialize awww Wallpaper Daemon & Randomize Wallpaper on Startup
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Start awww-daemon if not already running
if ! pgrep -x awww-daemon > /dev/null; then
    awww-daemon &
    # Wait for awww daemon socket to be responsive (up to 3s)
    for _ in {1..30}; do
        if awww query > /dev/null 2>&1; then
            break
        fi
        sleep 0.1
    done
fi

# Select and apply a randomized wallpaper from the shuffle queue silently
"$SCRIPT_DIR/cycle-wallpaper.sh" --silent
