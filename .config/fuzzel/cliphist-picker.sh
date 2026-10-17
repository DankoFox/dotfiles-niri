#!/usr/bin/env bash
# ==============================================================================
# Cliphist + Fuzzel Clipboard History Picker with Image Previews
# ==============================================================================

set -euo pipefail

# 1. Toggle: if Fuzzel is already open, close it and exit
if pkill -x fuzzel; then
    exit 0
fi

# 2. Cache directory for thumbnail previews
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist/thumbnails"
mkdir -p "$cache_dir"

# 3. Retrieve raw cliphist list
cliphist_list="$(cliphist list)"
if [ -z "$cliphist_list" ]; then
    fuzzel -d --prompt-only "Clipboard is empty" --width 30 --lines 1
    exit 0
fi

# 4. Stream through awk to extract image thumbnails and format with icons for Fuzzel
#    Fuzzel receives input with \0icon\x1f<path_to_thumbnail>
selected="$(
    printf "%s\n" "$cliphist_list" | awk -F'\t' -v dir="$cache_dir" '
    {
        id = $1
        text = $0
        sub(/^[0-9]+\t/, "", text)

        # Detect binary image formats in cliphist preview
        if (text ~ /^\[\[ binary data .* (png|jpg|jpeg|webp) /) {
            ext = "png"
            if (text ~ /jpg|jpeg/) ext = "jpg"
            else if (text ~ /webp/) ext = "webp"

            thumb = dir "/" id "." ext
            # Extract image thumbnail if not already cached
            system("[ -f \"" thumb "\" ] || cliphist decode " id " > \"" thumb "\" 2>/dev/null")
            printf "%s\t%s\0icon\x1f%s\n", id, text, thumb
        } else {
            printf "%s\t%s\n", id, text
        }
    }' | fuzzel -d \
        --placeholder "Search clipboard..." \
        --with-nth 2 \
        --no-sort \
        --counter \
        --width 75 \
        --lines 8 \
        --minimal-lines \
        --horizontal-pad 16
)"

# 5. Decode selected item and copy to clipboard
if [ -n "$selected" ]; then
    echo "$selected" | cliphist decode | wl-copy
fi
