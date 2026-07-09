#!/bin/sh
set -eu

case "${0##*/}" in
    dwm-left) position=left ;;
    dwm-right) position=right ;;
    *) position=${1:-left} ;;
esac

case "$position" in
    left|right) ;;
    *)
        echo "usage: ${0##*/} [left|right]" >&2
        exit 2
        ;;
esac

exec startx "$HOME/.xinitrc" "$position"
