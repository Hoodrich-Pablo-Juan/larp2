#!/bin/bash
# Keep a code-free ("Just Works") Bluetooth agent registered as the default.
#
# Without an agent on the session bus, a phone-initiated pairing deadlocks: the
# phone shows a passkey prompt and nothing on this machine ever answers it, so
# the pairing can never be completed from both sides. Registering an agent with
# the NoInputNoOutput capability makes BlueZ fall back to Just Works pairing —
# no passkey appears on either side, and the phone only asks you to confirm the
# device.
#
# bluetoothctl unregisters its agent the moment it exits, so it is kept alive on
# a FIFO rather than being re-run in a loop (which would leave gaps where the
# agent is missing). One instance only, guarded by a pidfile.
set -uo pipefail

RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"
PIDFILE="$RUNTIME/bt-agent.pid"
FIFO="$RUNTIME/bt-agent.fifo"
LOG="$HOME/.cache/bt-agent.log"

if [ -s "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    exit 0
fi
echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE" "$FIFO"' EXIT INT TERM

if ! command -v bluetoothctl >/dev/null 2>&1; then
    echo "bt-agent: bluetoothctl not found (bluez-utils missing?)" >&2
    exit 0
fi

mkdir -p "$(dirname "$LOG")"
rm -f "$FIFO"
mkfifo "$FIFO"

bluetoothctl --agent NoInputNoOutput <"$FIFO" >"$LOG" 2>&1 &
BT=$!

# The write end has to stay open for bluetoothctl's stdin, which is what keeps
# the agent registered for as long as this script runs.
exec 3>"$FIFO"
echo "default-agent" >&3

# Re-assert the default slot periodically: blueman-applet registers an agent of
# its own, and whichever registers last becomes the default.
while kill -0 "$BT" 2>/dev/null; do
    sleep 30
    echo "default-agent" >&3 2>/dev/null || break
done

wait "$BT" 2>/dev/null
