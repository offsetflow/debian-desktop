#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CONFIG="$SCRIPT_DIR/dunstrc"
LOG="$HOME/.cache/dunst/dunst.log"
DUNST_BIN=${DUNST_BIN:-/usr/bin/dunst}

pkill -x dunst >/dev/null 2>&1 || true

count=0
while pgrep -x dunst >/dev/null 2>&1 && [ "$count" -lt 30 ]; do
    sleep 0.1
    count=$((count + 1))
done

mkdir -p "$(dirname -- "$LOG")"
"$DUNST_BIN" -config "$CONFIG" >"$LOG" 2>&1 &
