#!/bin/bash
# Region screenshot (Super + P): pick an area with slurp, then save the PNG to
# ~/Downloads and put the same image on the clipboard. Escape / right-click
# cancels the selection and leaves no file behind.

DIR="$HOME/Downloads"
mkdir -p "$DIR"

# slurp exits non-zero when the selection is cancelled
GEOMETRY=$(slurp -d -b 00000080 -c 88c0d0 2>/dev/null) || exit 0
[ -n "$GEOMETRY" ] || exit 0

FILE="$DIR/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"

grim -g "$GEOMETRY" "$FILE" || exit 1
wl-copy < "$FILE"

notify-send -a Screenshot -i camera-photo "Screenshot saved" "$FILE" 2>/dev/null
