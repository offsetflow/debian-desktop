#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
POPUP="$SCRIPT_DIR/notification-center.py"
PYTHON_BIN=${PYTHON_BIN:-/usr/bin/python3}
RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp}
PID_FILE="$RUNTIME_DIR/debian-desktop-notification-center-$(id -u).pid"
LOG_FILE="$RUNTIME_DIR/debian-desktop-notification-center-$(id -u).log"
DUNSTCTL_BIN=${DUNSTCTL_BIN:-/usr/bin/dunstctl}

toggle_running_popup() {
    [ -r "$PID_FILE" ] || return 1

    popup_pid=$(sed -n '1p' "$PID_FILE" 2>/dev/null || true)
    case "$popup_pid" in
        ''|*[!0-9]*)
            rm -f "$PID_FILE"
            return 1
            ;;
    esac

    if kill -0 "$popup_pid" 2>/dev/null \
        && grep -aFq "$POPUP" "/proc/$popup_pid/cmdline" 2>/dev/null
    then
        kill "$popup_pid"
        rm -f "$PID_FILE"
        return 0
    fi

    rm -f "$PID_FILE"
    return 1
}

if toggle_running_popup; then
    exit 0
fi

archive_displayed_notifications() {
    [ -x "$DUNSTCTL_BIN" ] || return 0

    displayed=$("$DUNSTCTL_BIN" count displayed 2>/dev/null || printf '0\n')
    archived=0
    case "$displayed" in
        ''|*[!0-9]*) return 0 ;;
    esac

    # Dunst 1.12 only adds one item to history for close-all. Closing each
    # visible card preserves the complete stack for the notification center.
    while [ "$displayed" -gt 0 ] && [ "$archived" -lt 50 ]; do
        "$DUNSTCTL_BIN" close >/dev/null 2>&1 || break
        archived=$((archived + 1))
        displayed=$("$DUNSTCTL_BIN" count displayed 2>/dev/null || printf '0\n')
        case "$displayed" in
            ''|*[!0-9]*) break ;;
        esac
    done
}

archive_displayed_notifications

if "$PYTHON_BIN" -c 'import cairo, gi; gi.require_version("PangoCairo", "1.0"); from gi.repository import PangoCairo' \
    >/dev/null 2>&1
then
    nohup "$PYTHON_BIN" "$POPUP" "$PID_FILE" </dev/null >>"$LOG_FILE" 2>&1 &
    exit 0
fi

printf '%s\n' \
    'notification-center: install python3-gi, python3-gi-cairo and gir1.2-gtk-3.0' >&2
exit 1
