#!/bin/bash
# Battery readout for waybar, with the pass-through state spelled out.
#
# The stock `battery` module can only report Charging/Discharging/Full, and
# pass-through looks like "Full" from there even though it is a different thing:
# the adapter is holding the charge limit and the cells are idle. This reads the
# same two files battery-charge-limit.sh writes, so the bar shows the truth:
# plugged in and sitting at the limit reads "passthrough" instead of "Full".
#
# Waybar custom module -- emits JSON (see config/waybar/config.jsonc).
set -uo pipefail

SYS="${SYSFS_POWER_SUPPLY:-/sys/class/power_supply}"
BAT="$SYS/BAT0"

if [ ! -r "$BAT/capacity" ]; then
    printf '{"text":"no battery","class":"missing","tooltip":"no BAT0 under %s"}\n' "$SYS"
    exit 0
fi

capacity=$(cat "$BAT/capacity")
status=$(cat "$BAT/status")
threshold=$(cat "$BAT/charge_control_end_threshold" 2>/dev/null || echo 100)

ac=0
for f in "$SYS"/AC*/online "$SYS"/ADP*/online; do
    [ -r "$f" ] || continue
    [ "$(cat "$f")" = "1" ] && ac=1
done

case "$status" in
    Charging)   icons=("󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅") ;;
    *)          icons=("󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹") ;;
esac
idx=$(( capacity * (${#icons[@]} - 1) / 100 ))

# Pass-through is "plugged in and at (or above) the limit": the EC has stopped
# charging and the machine is drawing from the adapter. Below the limit it is
# genuinely charging, and unplugged it is genuinely discharging.
if [ "$ac" -eq 1 ] && [ "$capacity" -ge "$threshold" ]; then
    cls="passthrough"
    # The word replaces the battery glyph here: an icon next to it reads as a
    # charge level, which is not what the readout is saying.
    text="passthrough (${capacity}%)"
    label="pass-through (running off the adapter)"
elif [ "$status" = "Charging" ]; then
    cls="charging"
    text="${icons[$idx]} ${capacity}%"
    label="charging"
elif [ "$ac" -eq 1 ]; then
    cls="plugged-in"
    text="${icons[$idx]} ${capacity}%"
    label="plugged in"
else
    cls="on-battery"
    text="${icons[$idx]} ${capacity}%"
    label="on battery"
fi

printf '{"text":"%s","class":"%s","tooltip":"%s\\nlimit: %s%%\\nstatus: %s"}\n' \
    "$text" "$cls" "$label" "$threshold" "$status"
