#!/bin/bash
Y=$(hyprctl cursorpos | cut -d',' -f2 | xargs)
if [ "$Y" -le 32 ]; then
    swaync-client -t -sw
fi
