#!/bin/sh

xrandr_bin="${XRANDR_BIN:-xrandr}"
monitor="${MONITOR:-}"

current_brightness() {
    [ -n "$monitor" ] || return 1
    "$xrandr_bin" --verbose 2>/dev/null | awk -v target="$monitor" '
        $1 == target && $2 == "connected" {
            active = 1
            next
        }
        active && /^[[:space:]]+Brightness:/ {
            print $2
            exit
        }
        active && /^[^[:space:]]/ {
            active = 0
        }
    '
}

current="$(current_brightness)"
case "$current" in
    ''|*[!0-9.]*)
        [ "${1:-get}" = "get" ] && printf '%s\n' "☀ --"
        exit 0
        ;;
	esac
case "${1:-get}" in
    get)
        percentage="$(awk -v value="$current" 'BEGIN { printf "%d", value * 100 + 0.5 }')"
        printf '☀ %s%%\n' "$percentage"
        ;;
    up|down)
        if [ "$1" = "up" ]; then
            delta="0.05"
        else
            delta="-0.05"
        fi
        next="$(awk -v value="$current" -v delta="$delta" 'BEGIN {
            value += delta
            if (value > 1.0) value = 1.0
            if (value < 0.4) value = 0.4
            printf "%.2f", value
        }')"
        "$xrandr_bin" --output "$monitor" --brightness "$next" >/dev/null 2>&1 || true
        ;;
esac
