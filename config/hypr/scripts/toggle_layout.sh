#!/bin/bash
current=$(hyprctl getoption general:layout -j 2>/dev/null | python3 -c 'import sys,json; print(json.load(sys.stdin).get("str","scrolling"))')
if [ "$current" = "scrolling" ]; then
    hyprctl eval "hl.config({ general = { layout = 'dwindle' } })"
    notify-send -t 1500 "Hyprland Layout" "Switched to Dwindle" 2>/dev/null || true
else
    hyprctl eval "hl.config({ general = { layout = 'scrolling' } })"
    notify-send -t 1500 "Hyprland Layout" "Switched to Scrolling" 2>/dev/null || true
fi
