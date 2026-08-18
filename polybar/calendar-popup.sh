#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
POPUP="$SCRIPT_DIR/calendar-popup.py"
PYTHON_BIN=${PYTHON_BIN:-/usr/bin/python3}
RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp}
PID_FILE="$RUNTIME_DIR/debian-desktop-calendar-$(id -u).pid"
LOG_FILE="$RUNTIME_DIR/debian-desktop-calendar-$(id -u).log"

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

if "$PYTHON_BIN" -c 'import cairo, gi; gi.require_version("PangoCairo", "1.0"); from gi.repository import PangoCairo' \
    >/dev/null 2>&1
then
    nohup "$PYTHON_BIN" "$POPUP" "$PID_FILE" </dev/null >>"$LOG_FILE" 2>&1 &
    exit 0
fi

# 旧环境尚未安装 Python GTK 绑定时，仍能使用原来的轻量日历。
if command -v gsimplecal >/dev/null 2>&1; then
    exec gsimplecal
fi

printf '%s\n' \
    'calendar-popup: install python3-gi, python3-gi-cairo and gir1.2-gtk-3.0' >&2
exit 1
