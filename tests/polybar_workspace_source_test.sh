#!/bin/sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
config="$repo_root/polybar/config.ini"

fail() {
    printf '%s\n' "FAIL: $*" >&2
    exit 1
}

[ -f "$config" ] || fail "missing polybar/config.ini"

# 每个显示器都会启动一个 polybar 实例；workspace 必须固定到各自 monitor，
# 才能让外接屏和笔记本屏各自切换自己的 dwm tags。
grep -Eq '^[[:space:]]*pin-workspaces[[:space:]]*=[[:space:]]*true[[:space:]]*$' "$config" \
    || fail "polybar xworkspaces should be pinned per monitor: set pin-workspaces = true"

printf '%s\n' "OK: polybar pins dwm tags per monitor"
