#!/usr/bin/env bash
# ==============================================================================
# Smart Wallpaper Shuffler using awww
# Uses a persistent Shuffle-Deck Queue algorithm:
# - Shuffles all wallpapers and plays each one once before any can repeat
# - Seamlessly avoids immediate repeats across deck reshuffles
# - Fast, persistent across sessions & reboots in XDG_STATE_HOME
# ==============================================================================
set -euo pipefail

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/awww"
mkdir -p "$STATE_DIR"
QUEUE_FILE="$STATE_DIR/queue"
CURRENT_FILE="$STATE_DIR/current"

SILENT=false
TRANSITION="random"
DURATION="1.2"

for arg in "$@"; do
    case "$arg" in
        --silent|-s)
            SILENT=true
            ;;
        --simple)
            TRANSITION="simple"
            DURATION="0"
            ;;
    esac
done

# Ensure awww-daemon is running
if ! pgrep -x awww-daemon > /dev/null; then
    awww-daemon &
    sleep 0.3
fi

if [ ! -d "$WALLPAPER_DIR" ]; then
    notify-send -a "Wallpaper" -i dialog-warning "Wallpaper" "Directory $WALLPAPER_DIR not found"
    exit 1
fi

# Discover all wallpapers
shopt -s nullglob nocaseglob
wallpapers=("$WALLPAPER_DIR"/*.jpg "$WALLPAPER_DIR"/*.jpeg "$WALLPAPER_DIR"/*.png "$WALLPAPER_DIR"/*.webp)
shopt -u nullglob nocaseglob

total=${#wallpapers[@]}
if [ "$total" -eq 0 ]; then
    notify-send -a "Wallpaper" -i dialog-warning "Wallpaper" "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

current_wall=""
if [ -f "$CURRENT_FILE" ] && [ -s "$CURRENT_FILE" ]; then
    current_wall="$(<"$CURRENT_FILE")"
fi

# Load valid pending queue
queue=()
if [ -f "$QUEUE_FILE" ]; then
    while IFS= read -r line; do
        if [ -n "$line" ] && [ -f "$line" ]; then
            queue+=("$line")
        fi
    done < "$QUEUE_FILE"
fi

# If queue is empty, generate a fresh shuffled deck of all wallpapers
if [ ${#queue[@]} -eq 0 ]; then
    mapfile -t new_deck < <(printf "%s\n" "${wallpapers[@]}" | shuf)
    
    # Boundary check: Ensure first item of new deck != last displayed wallpaper
    if [ "$total" -gt 1 ] && [ "${new_deck[0]}" = "$current_wall" ]; then
        # Swap with the last item in the new deck
        tmp="${new_deck[0]}"
        new_deck[0]="${new_deck[total - 1]}"
        new_deck[total - 1]="$tmp"
    fi
    queue=("${new_deck[@]}")
fi

# Draw next wallpaper from queue
next_wall="${queue[0]}"
remaining_queue=("${queue[@]:1}")

# Persist state
if [ ${#remaining_queue[@]} -gt 0 ]; then
    printf "%s\n" "${remaining_queue[@]}" > "$QUEUE_FILE"
else
    : > "$QUEUE_FILE"
fi
echo "$next_wall" > "$CURRENT_FILE"

# Apply wallpaper with awww
if [ "$TRANSITION" = "simple" ]; then
    awww img "$next_wall" --transition-type simple
else
    awww img "$next_wall" --transition-type "$TRANSITION" --transition-duration "$DURATION" --transition-fps 60
fi
