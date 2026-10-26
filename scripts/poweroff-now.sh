#!/bin/bash
# Power the machine off for real.
#
# The repo policy (system/etc/systemd/system/systemd-*.service.d/) sets
# SuccessAction=reboot-force, so a plain `systemctl poweroff` runs the normal
# shutdown sequence and then comes back up — that keeps the machine reachable
# over Tailscale. This script is the deliberate escape hatch (SUPER + SHIFT + Q).
#
# SuccessAction comes from the drop-in that is read last, and "override.conf"
# sorts before "zz-*", so a runtime drop-in in /run wins over the /etc one.
# /run is a tmpfs: the override disappears at the next boot, so the
# reboot-instead-of-poweroff policy comes back on its own and this script stays
# the only way to really cut power.
#
# Usage: poweroff-now.sh [-n | --dry-run]
#   --dry-run writes the override, confirms systemd picked it up, then removes
#   it and reloads. Nothing is powered off.

set -euo pipefail

DROPIN_DIR=/run/systemd/system/systemd-poweroff.service.d
DROPIN="$DROPIN_DIR/zz-real-poweroff.conf"
UNIT=systemd-poweroff.service

usage() {
    echo "usage: $(basename "$0") [-n | --dry-run]" >&2
    exit 2
}

dry_run=false
while [ $# -gt 0 ]; do
    case "$1" in
        -n|--dry-run) dry_run=true ;;
        -h|--help) usage ;;
        *) usage ;;
    esac
    shift
done

# Root is needed to write the runtime drop-in. Non-interactive on purpose: this
# runs from a keybind, so an interactive sudo prompt would just hang.
if [ "$(id -u)" -eq 0 ]; then
    SUDO=()
elif sudo -n true 2>/dev/null; then
    SUDO=(sudo -n)
else
    echo "poweroff-now: need root or passwordless sudo to override the reboot policy" >&2
    exit 1
fi

revert() {
    "${SUDO[@]}" rm -f "$DROPIN"
    "${SUDO[@]}" rmdir "$DROPIN_DIR" 2>/dev/null || true
    "${SUDO[@]}" systemctl daemon-reload
}

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
printf '[Unit]\nSuccessAction=poweroff-force\n' > "$tmp"
"${SUDO[@]}" install -Dm644 "$tmp" "$DROPIN"
"${SUDO[@]}" systemctl daemon-reload

action=$(systemctl show -p SuccessAction --value "$UNIT")
if [ "$action" != "poweroff-force" ]; then
    echo "poweroff-now: override did not take effect (SuccessAction=$action); leaving the reboot policy intact" >&2
    revert
    exit 1
fi

if [ "$dry_run" = true ]; then
    revert
    echo "dry run ok: SuccessAction=poweroff-force took effect and was reverted"
    exit 0
fi

# Normal shutdown sequence (services stopped, filesystems unmounted); the
# override only changes what happens at the very end.
exec "${SUDO[@]}" systemctl poweroff
