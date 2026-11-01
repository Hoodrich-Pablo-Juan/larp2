#!/bin/sh
# Put the Bluetooth adapter into a state where a phone can find it, pair with
# it and stream audio to it.
#
# The adapter already advertises the A2DP *Sink* role by default (WirePlumber
# builds the media endpoints), so nothing about the role needs configuring.
# What BlueZ does *not* restore on boot is Pairability and Discoverability:
# those live in the adapter's runtime state, so after every boot the machine is
# invisible to phones until something turns them back on. That is all this
# script does.
#
# DiscoverableTimeout is set to 0 (never time out): the machine is meant to be
# a permanently available audio target, not something you have to poke awake.
#
# Never fails the boot: no adapter (or no bluez-utils) just means there is
# nothing to do.
set -eu

if ! command -v bluetoothctl >/dev/null 2>&1; then
    echo "bluetooth-audio-ready: bluetoothctl not found (bluez-utils missing?)" >&2
    exit 0
fi

# bluetoothd may still be bringing the adapter up when this runs.
i=0
while [ "$i" -lt 20 ]; do
    if bluetoothctl show >/dev/null 2>&1; then
        break
    fi
    i=$((i + 1))
    sleep 1
done

if ! bluetoothctl show >/dev/null 2>&1; then
    echo "bluetooth-audio-ready: no adapter available, nothing to do" >&2
    exit 0
fi

bluetoothctl power on                >/dev/null 2>&1 || true
bluetoothctl pairable on             >/dev/null 2>&1 || true
bluetoothctl discoverable-timeout 0  >/dev/null 2>&1 || true
bluetoothctl discoverable on         >/dev/null 2>&1 || true

echo "bluetooth-audio-ready: adapter powered, pairable and discoverable" >&2
