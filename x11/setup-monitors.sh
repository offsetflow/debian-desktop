#!/bin/sh

set -eu

position=${1:-left}

case "$position" in
    left|right) ;;
    *)
        echo "usage: $0 [left|right]" >&2
        exit 2
        ;;
esac

if ! command -v xrandr >/dev/null 2>&1; then
    echo "setup-monitors: xrandr is not installed" >&2
    exit 1
fi

connected_outputs=$(xrandr --query | awk '$2 == "connected" { print $1 }')
internal_output=
external_output=

for output in $connected_outputs; do
    case "$output" in
        eDP*|LVDS*|DSI*|DP-*)
            [ -n "$internal_output" ] || internal_output=$output
            ;;
        *)
            [ -n "$external_output" ] || external_output=$output
            ;;
    esac
done

if [ -z "$internal_output" ]; then
    echo "setup-monitors: no connected laptop display found" >&2
    exit 1
fi

if [ -z "$external_output" ]; then
    xrandr --output "$internal_output" --primary --auto
    exit 0
fi

case "$position" in
    left)
        xrandr \
            --output "$external_output" --primary --auto --left-of "$internal_output" \
            --output "$internal_output" --auto
        ;;
    right)
        xrandr \
            --output "$external_output" --primary --auto --right-of "$internal_output" \
            --output "$internal_output" --auto
        ;;
esac
