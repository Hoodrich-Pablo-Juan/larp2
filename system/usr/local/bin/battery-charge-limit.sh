#!/bin/sh
# Pass-through charging: while plugged in, stop putting charge into the battery
# so the machine runs straight off the adapter; on battery, allow a full charge
# again so the laptop leaves the house full.
#
# The lever is `charge_control_end_threshold`. Set it *at or above* the current
# capacity and the EC stops charging immediately without discharging anything:
# the laptop draws from AC and the cells sit idle. Pinning it to the current
# capacity (rather than a fixed 80) matters at the top end -- with the battery
# already at 100 a limit of 80 does nothing, because there is nothing left to
# charge; matching the capacity is what records "stop here".
#
# Run by battery-charge-limit.service at boot and by the udev rule on every
# AC plug/unplug. `--status` prints what the firmware currently reports.
set -eu

FLOOR="${CHARGE_FLOOR:-80}"          # charge up to this much when plugged in
# Overridable so the logic can be exercised against a scratch tree.
SYS="${SYSFS_POWER_SUPPLY:-/sys/class/power_supply}"
BAT="$SYS/BAT0"

[ -d "$BAT" ] || { echo "battery-charge-limit: no battery at $BAT" >&2; exit 1; }
[ -w "$BAT/charge_control_end_threshold" ] || {
    echo "battery-charge-limit: $BAT/charge_control_end_threshold is not writable" >&2
    exit 1
}

ac_online() {
    for f in "$SYS"/AC*/online "$SYS"/ADP*/online; do
        [ -r "$f" ] || continue
        [ "$(cat "$f")" = "1" ] && return 0
    done
    return 1
}

capacity=$(cat "$BAT/capacity")
threshold=$(cat "$BAT/charge_control_end_threshold")

if [ "${1:-}" = "--status" ]; then
    printf 'capacity:  %s%%\nstatus:    %s\nthreshold: %s%%\nac:        %s\n' \
        "$capacity" "$(cat "$BAT/status")" "$threshold" \
        "$(ac_online && echo online || echo offline)"
    exit 0
fi

if ac_online; then
    if [ "$capacity" -gt "$FLOOR" ]; then
        target="$capacity"          # already above the floor: stop where it is
    else
        target="$FLOOR"             # below it: charge up to the floor, no further
    fi
    state="pass-through (AC), charge stops at ${target}%"
else
    target=100                      # unplugged: next plug may fill it
    state="on battery, charge limit restored to 100%"
fi

if [ "$target" != "$threshold" ]; then
    echo "$target" > "$BAT/charge_control_end_threshold"
fi
echo "battery-charge-limit: $state"
