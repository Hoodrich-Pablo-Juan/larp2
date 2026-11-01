#!/bin/bash
# Stop a Bluetooth speaker from powering itself off while nothing is playing.
#
# Most A2DP speakers drop into standby after 10-20 minutes of silence, so the
# machine has to be re-connected by hand the moment you want sound. This streams
# a continuous, inaudible tone into the speaker while it is connected: a 25 Hz
# sine at about -66 dBFS. 25 Hz is below the passband of any speaker this size
# and -66 dBFS is under the noise floor of the room, so nothing is audible — but
# it is a non-silent digital stream, and that is what the speaker's auto-standby
# watches for. (Silence itself does not keep them awake; all-zero samples look
# exactly like "no audio" to most firmware.)
#
# Only ever targets a bluez_output.* sink, so the laptop's own speakers are never
# fed, and it simply idles while no Bluetooth output is connected.
#
# One instance only (pidfile). Started from modules/autostart.lua.
set -uo pipefail

RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"
PIDFILE="$RUNTIME/bt-keepalive.pid"
WAV="${XDG_DATA_HOME:-$HOME/.local/share}/bt-keepalive.wav"
FREQ=25           # Hz — far below what the speaker can reproduce
AMPLITUDE=0.0005  # ~-66 dBFS — inaudible, but not digital silence
SECONDS_PER_FILE=30

if [ -s "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    exit 0
fi
echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT INT TERM

# One period is generated and tiled, so the file has no click at the seam and
# generation stays instant.
generate() {
    mkdir -p "$(dirname "$WAV")"
    python3 - "$WAV" "$FREQ" "$AMPLITUDE" "$SECONDS_PER_FILE" <<'PY'
import math, struct, sys, wave

path, freq, amp, secs = sys.argv[1], float(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4])
rate = 48000
period = int(round(rate / freq))
peak = amp * 32767
cycle = b"".join(struct.pack("<hh", int(peak * math.sin(2 * math.pi * i / period)),
                                  int(peak * math.sin(2 * math.pi * i / period)))
                 for i in range(period))
frames = int(rate * secs)
reps = frames // period

with wave.open(path, "wb") as w:
    w.setnchannels(2)
    w.setsampwidth(2)
    w.setframerate(rate)
    w.writeframes(cycle * reps)
PY
}

bluetooth_sink() {
    pactl list short sinks 2>/dev/null | awk '$2 ~ /^bluez_output\./ {print $2; exit}'
}

[ -s "$WAV" ] || generate

while :; do
    if ! pactl info >/dev/null 2>&1; then
        sleep 5
        continue
    fi

    sink=$(bluetooth_sink)
    if [ -z "$sink" ]; then
        sleep 5
        continue
    fi

    # paplay blocks for the length of the file; a disconnect or a sink switch
    # just makes it exit, and the next iteration picks up the new sink.
    paplay --device="$sink" "$WAV" 2>/dev/null || sleep 2
done
