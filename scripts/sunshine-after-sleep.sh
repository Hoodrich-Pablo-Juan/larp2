#!/bin/bash
# Runs from hypridle's after_sleep_cmd. Recovers display state so a Moonlight
# client connecting right after S3 resume sees real frames, not a black screen.

LOG="$HOME/.local/share/sunshine-headless.log"

mkdir -p "$(dirname "$LOG")"

# Give Hyprland a beat to finish reattaching outputs after resume.
sleep 1

# Detect Hyprland config provider
HYPR_CONF_PROVIDER=legacy
if [ "$(hyprctl dispatch 'hl.dsp.no_op()')" = "ok" ] ; then
    HYPR_CONF_PROVIDER=lua
fi

# Detect physical monitor (default to eDP-1)
PHYSICAL=$(hyprctl monitors -j 2>/dev/null | python3 -c \
    "import sys,json; ms=[m['name'] for m in json.load(sys.stdin) if 'HEADLESS' not in m['name']]; print(ms[0] if ms else 'eDP-1')" 2>/dev/null)
PHYSICAL="${PHYSICAL:-eDP-1}"

# 1. dpms on for everything (defensive — both physical and virtual).
if [ "$HYPR_CONF_PROVIDER" = "lua" ] ; then
    hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })' >> "$LOG" 2>&1
else
    hyprctl dispatch dpms on >> "$LOG" 2>&1
fi

# 2. Locate the persistent HEADLESS monitor. If missing, nothing else to do
#    here: sunshine-connect.sh's self-heal path will recreate it on next
#    client connect.
HEADLESS=$(hyprctl monitors -j | python3 -c \
    "import sys,json; ms=[m['name'] for m in json.load(sys.stdin) if 'HEADLESS' in m['name']]; print(ms[0] if ms else '')")

if [ -z "$HEADLESS" ]; then
    echo "$(date -Iseconds) after_sleep: no HEADLESS present (connect.sh will recreate)" >> "$LOG"
    exit 0
fi

# 3. Repaint kick — bounce focus onto HEADLESS and back to physical monitor. Cheap and
#    forces Hyprland to commit a new frame to the headless scanout.
if [ "$HYPR_CONF_PROVIDER" = "lua" ] ; then
    hyprctl dispatch "hl.dsp.focus({ monitor=\"$HEADLESS\"})" >> "$LOG" 2>&1
    sleep 0.2
    hyprctl dispatch "hl.dsp.focus({ monitor=\"$PHYSICAL\"})" >> "$LOG" 2>&1
else
    hyprctl dispatch focusmonitor "$HEADLESS" >> "$LOG" 2>&1
    sleep 0.2
    hyprctl dispatch focusmonitor "$PHYSICAL" >> "$LOG" 2>&1
fi

echo "$(date -Iseconds) after_sleep: dpms-on + repaint kick on $HEADLESS (Physical: $PHYSICAL)" >> "$LOG"
