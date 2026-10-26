#!/bin/bash
# Creates a persistent virtual HEADLESS display and launches Sunshine.
#
# Sunshine (wlr-capture backend) reads output_name once at process startup and
# caches it — SIGHUP and HTTP API reloads do not refresh the cached value.
# So the HEADLESS monitor must exist AND its name must be written to
# sunshine.conf BEFORE we exec sunshine. Once Sunshine is up the monitor
# stays alive for the lifetime of the session, and the connect/disconnect
# scripts only migrate workspaces in and out of it.
#
# To prevent the persistent HEADLESS from receiving local workspaces between
# remote sessions, this script also pins workspace 11 ("remote") to the
# HEADLESS monitor and sets workspaces 1-10 as defaults on the physical monitor.

LOG="$HOME/.local/share/sunshine-headless.log"
CONF="$HOME/.config/sunshine/sunshine.conf"

mkdir -p "$(dirname "$LOG")" "$(dirname "$CONF")"

# Detect Hyprland config provider
HYPR_CONF_PROVIDER=legacy
if [ "$(hyprctl dispatch 'hl.dsp.no_op()')" = "ok" ] ; then
    HYPR_CONF_PROVIDER=lua
fi

# Detect physical monitor (default to eDP-1 if not found)
PHYSICAL=$(hyprctl monitors -j 2>/dev/null | python3 -c \
    "import sys,json; ms=[m['name'] for m in json.load(sys.stdin) if 'HEADLESS' not in m['name']]; print(ms[0] if ms else 'eDP-1')" 2>/dev/null)
PHYSICAL="${PHYSICAL:-eDP-1}"

# --- Clean any HEADLESS leftovers from a previous Hyprland session ----------
while read -r name; do
    [ -n "$name" ] && hyprctl output remove "$name" >> "$LOG" 2>&1 && sleep 0.3
done < <(hyprctl monitors -j 2>/dev/null | python3 -c \
    "import sys,json; [print(m['name']) for m in json.load(sys.stdin) if 'HEADLESS' in m['name']]")

# --- Create the persistent HEADLESS monitor ---------------------------------
hyprctl output create headless >> "$LOG" 2>&1
sleep 0.8

HEADLESS=$(hyprctl monitors -j | python3 -c \
    "import sys,json; ms=[m['name'] for m in json.load(sys.stdin) if 'HEADLESS' in m['name']]; print(ms[0] if ms else '')")

if [ -z "$HEADLESS" ]; then
    echo "$(date -Iseconds) ERROR: failed to create headless monitor" >> "$LOG"
    exec sunshine
fi

echo "$(date -Iseconds) Headless created: $HEADLESS (Physical: $PHYSICAL)" >> "$LOG"

# 2732x2048@60 (iPad Air 13" M2 ~4:3 aspect ratio), placed far off-screen so it can't be reached with the mouse.
if [ "$HYPR_CONF_PROVIDER" = "lua" ] ; then
    hyprctl eval "hl.monitor({output=\"$HEADLESS\", mode=\"2732x2048@60.00\", position=\"9999x0\", scale=1})" >> "$LOG" 2>&1
else
    hyprctl keyword monitor "$HEADLESS,2732x2048@60,9999x0,1" >> "$LOG" 2>&1
fi
sleep 0.3

# --- Pin workspaces so local windows stay on physical monitor --------------
# Workspaces 1-10 default to physical display; workspace 11 lives on HEADLESS and serves
# as the "remote" workspace that connect.sh migrates into.
if [ "$HYPR_CONF_PROVIDER" = "lua" ] ; then
    hyprctl eval "for ws = 1,10 do hl.workspace_rule({workspace=tostring(ws), monitor=\"$PHYSICAL\", default=true, persistent=false}) end" >> "$LOG" 2>&1
else
    for ws in 1 2 3 4 5 6 7 8 9 10; do
        hyprctl keyword workspace "$ws, monitor:$PHYSICAL, default:true, persistent:false" >> "$LOG" 2>&1
    done
fi

if [ "$HYPR_CONF_PROVIDER" = "lua" ] ; then
    hyprctl eval "hl.workspace_rule({workspace=\"11\", monitor=\"$HEADLESS\", default=true, persistent=true})" >> "$LOG" 2>&1
else
    hyprctl keyword workspace "11, monitor:$HEADLESS, default:true, persistent:true" >> "$LOG" 2>&1
fi

# --- Write the headless name into sunshine.conf BEFORE launching sunshine ---
# Sunshine reads output_name once and caches it for the process lifetime.
if [ -f "$CONF" ]; then
    sed -i "s/^output_name *=.*/output_name = $HEADLESS/" "$CONF"
fi

exec sunshine
