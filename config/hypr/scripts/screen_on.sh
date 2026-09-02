#!/bin/bash
hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })' 2>/dev/null || hyprctl dispatch dpms on 2>/dev/null || true
notify-send -t 1500 "Display" "All displays enabled (DPMS ON)" 2>/dev/null || true
