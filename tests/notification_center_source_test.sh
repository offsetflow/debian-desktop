#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
popup="$repo_root/polybar/notification-center.py"
toggle="$repo_root/polybar/notification-center.sh"
dunstrc="$repo_root/dunst/dunstrc"
dunst_launch="$repo_root/dunst/launch.sh"
polybar_config="$repo_root/polybar/config.ini"
polybar_launch="$repo_root/polybar/launch.sh"
xinitrc="$repo_root/x11/xinitrc"
dwm_config="$repo_root/suckless/dwm/config.def.h"
picom_config="$repo_root/picom/picom.conf"
prepare="$repo_root/scripts/prepare-desktop.sh"

fail() {
    printf '%s\n' "FAIL: $*" >&2
    exit 1
}

[[ -x "$popup" ]] || fail "missing executable notification center"
[[ -x "$toggle" ]] || fail "missing executable notification center toggle"
[[ -x "$dunst_launch" ]] || fail "missing executable Dunst launcher"
[[ -f "$dunstrc" ]] || fail "missing Dunst configuration"

grep -Fq '[module/notifications]' "$polybar_config" \
    || fail "Polybar should expose a notifications module"
grep -Fq 'notification-center.sh toggle' "$polybar_config" \
    || fail "notification icon should toggle the center"
grep -Fq 'battery notifications power' "$polybar_launch" \
    || fail "per-monitor Polybar modules should include notifications"
grep -Fq 'set_wmclass("desktop-notification-center", "DesktopNotificationCenter")' "$popup" \
    || fail "notification center should publish a stable X11 class"
grep -Fq 'history-clear' "$popup" \
    || fail "notification center should clear Dunst history"
grep -Fq 'history-rm' "$popup" \
    || fail "notification center should remove one history item"
grep -Fq 'history-pop' "$popup" \
    || fail "notification center should redisplay a history item"
grep -Fq '"$DUNSTCTL_BIN" count displayed' "$toggle" \
    || fail "opening the center should count displayed notifications"
grep -Fq '"$DUNSTCTL_BIN" close' "$toggle" \
    || fail "opening the center should archive displayed notifications individually"

grep -Eq '^[[:space:]]*width[[:space:]]*=[[:space:]]*320$' "$dunstrc" \
    || fail "Dunst notifications should use a compact width"
grep -Eq '^[[:space:]]*height[[:space:]]*=[[:space:]]*\(0,[[:space:]]*130\)$' "$dunstrc" \
    || fail "Dunst notifications should cap long content at a compact height"
grep -Eq '^[[:space:]]*scale[[:space:]]*=[[:space:]]*1$' "$dunstrc" \
    || fail "Dunst should not enlarge notifications with auto-detected DPI scaling"
grep -Eq '^[[:space:]]*corner_radius[[:space:]]*=[[:space:]]*14$' "$dunstrc" \
    || fail "Dunst notifications should use compact rounded cards"
grep -Eq '^[[:space:]]*background[[:space:]]*=[[:space:]]*"#11141ED9"$' "$dunstrc" \
    || fail "Dunst notification background alpha should match st"
grep -Eq '^[[:space:]]*history_length[[:space:]]*=[[:space:]]*50$' "$dunstrc" \
    || fail "Dunst should keep enough history for the center"
grep -Fq '"$DUNST_BIN" -config "$CONFIG"' "$dunst_launch" \
    || fail "Dunst launcher should use the managed config"
grep -Fq 'dunst/launch.sh' "$xinitrc" \
    || fail "X11 session should start Dunst"
grep -Fq '"DesktopNotificationCenter"' "$dwm_config" \
    || fail "dwm should keep the center floating"
grep -Fq "class_g = 'DesktopNotificationCenter'" "$picom_config" \
    || fail "Picom should blur the notification center"
grep -Fq "class_g = 'Dunst'" "$picom_config" \
    || fail "Picom should blur Dunst notification cards"
grep -Eq '^[[:space:]]*dunst[[:space:]]*$' "$prepare" \
    || fail "bootstrap should install Dunst"

PYTHONPYCACHEPREFIX="${TMPDIR:-/tmp}/notification-center-test-pycache" \
    /usr/bin/python3 - "$popup" <<'PY'
import json
import runpy
import sys

module = runpy.run_path(sys.argv[1], run_name="notification_center_test")
payload = json.dumps({
    "type": "aa{sv}",
    "data": [[
        {
            "body": {"type": "s", "data": "<b>Older body</b>"},
            "summary": {"type": "s", "data": "Older summary"},
            "appname": {"type": "s", "data": "Older app"},
            "category": {"type": "s", "data": "system"},
            "id": {"type": "i", "data": 41},
            "timestamp": {"type": "x", "data": 123456},
            "urgency": {"type": "s", "data": "NORMAL"},
        },
        {
            "body": {"type": "s", "data": "<b>Newer body</b>"},
            "summary": {"type": "s", "data": "Newer summary"},
            "appname": {"type": "s", "data": "Newer app"},
            "category": {"type": "s", "data": "image"},
            "id": {"type": "i", "data": 42},
            "timestamp": {"type": "x", "data": 234567},
            "urgency": {"type": "s", "data": "LOW"},
        },
    ]],
})
items = module["parse_dunst_history"](payload)
assert len(items) == 2
assert items[0].notification_id == 42
assert items[0].summary == "Newer summary"
assert items[0].body == "Newer body"
assert items[1].notification_id == 41
assert items[1].summary == "Older summary"
assert items[1].body == "Older body"
PY

printf '%s\n' "notification center source tests passed"
