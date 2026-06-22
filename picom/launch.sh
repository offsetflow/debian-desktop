#!/bin/sh

CONFIG="$HOME/workspace/personal/debian-desktop/picom/picom.conf"
LOG="$HOME/.cache/picom/picom.log"

# Avoid duplicate compositor instances when X is restarted.
pkill -x picom >/dev/null 2>&1 || true

# Wait for the previous compositor to release the X11 selection.
count=0
while pgrep -x picom >/dev/null 2>&1 && [ "$count" -lt 30 ]; do
    sleep 0.1
    count=$((count + 1))
done

mkdir -p "$(dirname "$LOG")"
/usr/local/bin/picom --config "$CONFIG" >"$LOG" 2>&1 &
