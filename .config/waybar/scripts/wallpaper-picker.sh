#!/usr/bin/env bash
# ==============================================================================
# Interactive Wallpaper Picker using Fuzzel & awww
# Displays thumbnails and allows selecting wallpapers
# ==============================================================================
set -euo pipefail

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/awww"
mkdir -p "$STATE_DIR"
QUEUE_FILE="$STATE_DIR/queue"
CURRENT_FILE="$STATE_DIR/current"

# Toggle Fuzzel if already open
if pkill -x fuzzel; then
    exit 0
fi

# Ensure daemon is running
if ! pgrep -x awww-daemon > /dev/null; then
    awww-daemon &
    sleep 0.3
fi

if [ ! -d "$WALLPAPER_DIR" ]; then
    notify-send -a "Wallpaper" -i dialog-warning "Wallpaper" "Directory $WALLPAPER_DIR not found"
    exit 1
fi

shopt -s nullglob nocaseglob
wallpapers=("$WALLPAPER_DIR"/*.jpg "$WALLPAPER_DIR"/*.jpeg "$WALLPAPER_DIR"/*.png "$WALLPAPER_DIR"/*.webp)
shopt -u nullglob nocaseglob

if [ ${#wallpapers[@]} -eq 0 ]; then
    notify-send -a "Wallpaper" -i dialog-warning "Wallpaper" "No wallpapers found in $WALLPAPER_DIR"
    exit 0
fi

# Build menu with icon previews for Fuzzel: <path>\t<display_name>\0icon\x1f<path>
selected_line="$(
    for path in "${wallpapers[@]}"; do
        file="${path##*/}"
        name="${file%.*}"
        printf "%s\t%s\0icon\x1f%s\n" "$path" "$name" "$path"
    done | fuzzel -d \
        --placeholder "Select wallpaper..." \
        --with-nth 2 \
        --counter \
        --width 60 \
        --lines 8 \
        --minimal-lines \
        --horizontal-pad 16
)"

if [ -z "$selected_line" ]; then
    exit 0
fi

selected="${selected_line%%$'\t'*}"

if [ -n "$selected" ] && [ -f "$selected" ]; then
    echo "$selected" > "$CURRENT_FILE"
    if [ -f "$QUEUE_FILE" ]; then
        grep -v -F -x "$selected" "$QUEUE_FILE" > "${QUEUE_FILE}.tmp" || true
        mv "${QUEUE_FILE}.tmp" "$QUEUE_FILE"
    fi
    awww img "$selected" --transition-type wipe --transition-angle 30 --transition-duration 1.2 --transition-fps 60
fi
