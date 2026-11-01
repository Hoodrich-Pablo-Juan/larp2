#!/bin/bash
# Docked-panel policy for the laptop panel.
#
# While an external monitor is attached the laptop panel is switched off with
# DPMS — the same mechanism sunshine-connect.sh uses to darken the physical
# screen during a stream. DPMS is chosen over disabling the output entirely
# because it is instantly reversible and cannot strand the session: a disabled
# output takes its workspaces (and the cursor) with it, which is how you end up
# looking at a wallpaper with no pointer and windows opening somewhere you
# cannot see.
#
#   panel.sh sync     apply the policy (config load, monitor hotplug)
#   panel.sh toggle   keybind: panel back on / panel away again
#   panel.sh on|off   force a state
#
# Every path ends by focusing a *lit* output. Focusing an output warps the
# cursor into it, so the pointer is never left parked on a dark screen.

set -u

INTERNAL="eDP-1"
INTERNAL_MODE="preferred"
INTERNAL_SCALE=1.5
FLAG="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/panel-forced-on"

# External outputs that are currently active (HEADLESS is Sunshine's, not ours).
externals() {
    hyprctl monitors -j 2>/dev/null | python3 -c '
import json, sys
try:
    monitors = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for m in monitors:
    name = m["name"]
    if "HEADLESS" in name or name == sys.argv[1]:
        continue
    print(name)
' "$INTERNAL"
}

# 1 when the panel exists and its backlight is on.
panel_lit() {
    hyprctl monitors -j 2>/dev/null | python3 -c '
import json, sys
try:
    monitors = json.load(sys.stdin)
except Exception:
    print(0); sys.exit(0)
for m in monitors:
    if m["name"] == sys.argv[1]:
        print(1 if m.get("dpmsStatus") else 0); sys.exit(0)
print(0)
' "$INTERNAL"
}

# Park the panel to the right of the external output, or at the origin when it
# is alone. Hyprland positions are explicit here, never "auto": auto places an
# output beyond whatever is currently right-most, and HEADLESS sits at 9999x0.
place_panel() {
    local pos="$1"
    hyprctl eval "hl.monitor({output=\"$INTERNAL\", disabled=false, mode=\"$INTERNAL_MODE\", position=\"$pos\", scale=$INTERNAL_SCALE})" >/dev/null 2>&1
}

focus_lit() {
    local target
    target=$(externals | head -n1)
    [ -z "$target" ] && target="$INTERNAL"
    hyprctl dispatch "hl.dsp.focus({monitor=\"$target\"})" >/dev/null 2>&1
}

panel_on() { # $1 = position
    place_panel "${1:-0x0}"
    hyprctl dispatch "hl.dsp.dpms({action=\"enable\", monitor=\"$INTERNAL\"})" >/dev/null 2>&1
}

panel_off() {
    hyprctl dispatch "hl.dsp.dpms({action=\"disable\", monitor=\"$INTERNAL\"})" >/dev/null 2>&1
}

notify() {
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send -a "monitors" "$1" "$2" >/dev/null 2>&1
}

# Width of the external output in logical pixels, used to place the panel
# beside it instead of on top of it.
external_right_edge() {
    hyprctl monitors -j 2>/dev/null | python3 -c '
import json, sys
try:
    monitors = json.load(sys.stdin)
except Exception:
    print(0); sys.exit(0)
for m in monitors:
    if "HEADLESS" in m["name"] or m["name"] == sys.argv[1]:
        continue
    print(int(m["x"] + m["width"] / m["scale"])); sys.exit(0)
print(0)
' "$INTERNAL"
}

case "${1:-sync}" in
sync)
    # Give Hyprland a beat to finish applying monitors.lua's static rules.
    sleep 0.3
    if [ -n "$(externals)" ]; then
        if [ -e "$FLAG" ]; then
            panel_on "$(external_right_edge)x0"
        else
            # Park the panel beside the monitor before darkening it, so a later
            # "bring it back" does not drop it on top of the live screen.
            place_panel "$(external_right_edge)x0"
            panel_off
        fi
        focus_lit
    else
        rm -f "$FLAG"
        panel_on "0x0"
        focus_lit
    fi
    ;;
toggle)
    if [ "$(panel_lit)" = "1" ]; then
        rm -f "$FLAG"
        panel_off
        focus_lit
        notify "Laptop panel off" "SUPER + ALT + E brings it back"
    else
        mkdir -p "$(dirname "$FLAG")"
        : >"$FLAG"
        panel_on "$(external_right_edge)x0"
        hyprctl dispatch "hl.dsp.focus({monitor=\"$INTERNAL\"})" >/dev/null 2>&1
        notify "Laptop panel on" "SUPER + ALT + E hides it again"
    fi
    ;;
on)
    mkdir -p "$(dirname "$FLAG")"
    : >"$FLAG"
    panel_on "$(external_right_edge)x0"
    focus_lit
    ;;
off)
    rm -f "$FLAG"
    panel_off
    focus_lit
    ;;
*)
    echo "usage: $0 [sync|toggle|on|off]" >&2
    exit 2
    ;;
esac
