#!/bin/sh
set -eu

case "${1:-get}" in
    get)
        if ! muted=$(pamixer --get-mute 2>/dev/null); then
            printf '%s\n' "  unavailable"
        elif [ "$muted" = "true" ]; then
            printf '%s\n' "  muted"
        else
            if volume=$(pamixer --get-volume 2>/dev/null); then
                printf '  %s%%\n' "$volume"
            else
                printf '%s\n' "  unavailable"
            fi
        fi
        ;;
    toggle)
        pamixer --toggle-mute
        ;;
    up)
        pamixer --increase 5
        ;;
    down)
        pamixer --decrease 5
        ;;
    *)
        printf 'usage: %s {get|toggle|up|down}\n' "$0" >&2
        exit 2
        ;;
esac
