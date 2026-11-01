#!/bin/bash
# Play Bluetooth audio received from a phone out of the current default output.
#
# This machine advertises the A2DP *Sink* role, so a phone can pair and stream
# to it. PipeWire presents such an incoming stream as an audio *source*
# (bluez_input.<MAC>) — and a source is never auto-linked to any output, so the
# phone connects, reports success, and produces silence. This watcher links each
# bluez source to the default sink with a loopback, which is what turns
# "phone -> laptop -> speaker" into sound.
#
# Also re-creates the loopback when the default sink changes (e.g. the Bluetooth
# speaker connects mid-stream) and drops it when the phone disconnects.
#
# Started from the Hyprland session (see modules/autostart.lua). One instance
# only, guarded by a pidfile; it polls because there is no reliable "A2DP source
# appeared" hook that works the same across PipeWire versions.
set -uo pipefail

RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"
PIDFILE="$RUNTIME/bt-audio-bridge.pid"

if [ -s "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    exit 0
fi
echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT INT TERM

declare -A LOOPBACK=()   # source name -> pactl module id
declare -A LOOPBACK_SINK=()  # source name -> sink it was created against

unload() {
    local src="$1"
    if [ -n "${LOOPBACK[$src]:-}" ]; then
        pactl unload-module "${LOOPBACK[$src]}" 2>/dev/null
    fi
    unset 'LOOPBACK[$src]' 'LOOPBACK_SINK[$src]'
}

while :; do
    if ! pactl info >/dev/null 2>&1; then
        sleep 5
        continue
    fi

    default_sink=$(pactl get-default-sink 2>/dev/null)
    mapfile -t sources < <(
        pactl list short sources 2>/dev/null | awk '$2 ~ /^bluez_input\./ {print $2}'
    )

    # Drop loopbacks whose phone went away or whose target sink changed.
    for src in "${!LOOPBACK[@]}"; do
        present=0
        for s in "${sources[@]:-}"; do
            if [ "$s" = "$src" ]; then
                present=1
                break
            fi
        done
        if [ "$present" -eq 0 ] || [ "${LOOPBACK_SINK[$src]}" != "$default_sink" ]; then
            unload "$src"
        fi
    done

    if [ -n "$default_sink" ]; then
        for src in "${sources[@]:-}"; do
            [ -z "$src" ] && continue
            [ -n "${LOOPBACK[$src]:-}" ] && continue
            id=$(pactl load-module module-loopback \
                    source="$src" sink="$default_sink" latency_msec=50 \
                    source_dont_move=true sink_dont_move=true 2>/dev/null)
            if [ -n "$id" ]; then
                LOOPBACK[$src]="$id"
                LOOPBACK_SINK[$src]="$default_sink"
            fi
        done
    fi

    sleep 2
done
