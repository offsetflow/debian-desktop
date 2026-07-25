#!/bin/sh

remote_bin="${FCITX_REMOTE_BIN:-fcitx5-remote}"

case "${1:-status}" in
    status)
        state="$("$remote_bin" 2>/dev/null || true)"
        case "$state" in
            1) printf '%s\n' "EN" ;;
            2) printf '%s\n' "中" ;;
            *) printf '%s\n' "--" ;;
        esac
        ;;
    toggle)
        "$remote_bin" -t >/dev/null 2>&1 || true
        ;;
esac
