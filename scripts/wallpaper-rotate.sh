#!/bin/bash
# Cycle the desktop wallpaper through the rotation set once an hour.
#
# hyprpaper reads its wallpaper once at startup and only ever changes it over
# IPC, so no config can re-time a wallpaper by itself -- this watcher is what
# makes the set rotate.
#
# The list is explicit rather than a directory scan: wallpapers/ also holds
# images that are deliberately not part of the rotation. Index 0 is the static
# wallpaper hyprpaper starts with, so the first change lands one interval after
# login rather than at login.
#
# Started from the Hyprland session (see modules/autostart.lua). One instance
# only, guarded by a pidfile.
set -uo pipefail

INTERVAL="${WALLPAPER_INTERVAL:-3600}"   # seconds between wallpapers
RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"
STATE="$RUNTIME/wallpaper-rotate.idx"
PIDFILE="$RUNTIME/wallpaper-rotate.pid"

if [ -s "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    exit 0
fi
echo $$ > "$PIDFILE"
# A TERM handler that only cleans up would be ignored: the shell resumes the
# loop after the trap runs, so the watcher could never be stopped.
trap 'rm -f "$PIDFILE"' EXIT
trap 'exit 0' INT TERM

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
WALLPAPERS=(
    "$WALLPAPER_DIR/wp14952209-4k-abstract-oled-wallpapers.webp"
    "$WALLPAPER_DIR/blue-abstract-5120x2880-25119.jpg"
    "$WALLPAPER_DIR/geometric-gradient-5120x5120-25120.jpg"
    "$WALLPAPER_DIR/blue-abstract-5120x5120-25121.jpg"
    "$WALLPAPER_DIR/grey-abstract-5120x5120-26349.jpg"
)

# hyprpaper takes one monitor per wallpaper request, and each has to be named:
# its "all outputs" form (empty monitor) skips an output that is currently
# dark, so the panel -- DPMS-off whenever the monitor is connected -- would
# keep the old image until the output came back. Naming every monitor covers
# the panel, the monitor and the HEADLESS streaming display alike.
apply() {
    local path="$1" mon
    [ -r "$path" ] || return 1
    pgrep -x hyprpaper >/dev/null 2>&1 || return 1

    while read -r mon; do
        [ -n "$mon" ] && hyprctl hyprpaper wallpaper "$mon,$path" >/dev/null 2>&1
    done < <(hyprctl monitors 2>/dev/null | awk '/^Monitor /{print $2}')

    # Only report success if the switch actually took: the index must not move
    # while hyprpaper is down or still loading. Compared by file name --
    # hyprpaper reports the path it was handed at startup, which may be the
    # symlinked ~/Pictures/Wallpapers or the real directory behind it.
    hyprctl hyprpaper listactive 2>/dev/null | grep -Fq "$(basename "$path")"
}

idx=0
[ -s "$STATE" ] && idx="$(cat "$STATE" 2>/dev/null)"
case "$idx" in ''|*[!0-9]*) idx=0 ;; esac
idx=$(( idx % ${#WALLPAPERS[@]} ))

# Adopt whatever hyprpaper already shows instead of asserting index 0, so a
# restarted watcher continues the rotation where it was.
current="$(basename "$(hyprctl hyprpaper listactive 2>/dev/null | head -n1 | sed 's/^[^:]*: //')")"
if [ -n "$current" ]; then
    for i in "${!WALLPAPERS[@]}"; do
        if [ "$(basename "${WALLPAPERS[$i]}")" = "$current" ]; then
            idx=$i
            break
        fi
    done
fi

while :; do
    sleep "$INTERVAL"
    next=$(( (idx + 1) % ${#WALLPAPERS[@]} ))
    if apply "${WALLPAPERS[$next]}"; then
        idx=$next
        echo "$idx" > "$STATE"
    fi
done
