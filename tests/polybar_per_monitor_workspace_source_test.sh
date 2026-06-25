#!/bin/sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
config="$repo_root/polybar/config.ini"
dwm_c="$repo_root/suckless/dwm/dwm.c"

fail() {
    printf '%s\n' "FAIL: $*" >&2
    exit 1
}

[ -f "$config" ] || fail "missing polybar/config.ini"
[ -f "$dwm_c" ] || fail "missing suckless/dwm/dwm.c"

# 每个显示器启动自己的 polybar，需要让 workspace 固定在各自 monitor，
# 否则两个屏幕会显示/点击同一套全局标签。
grep -Eq '^[[:space:]]*pin-workspaces[[:space:]]*=[[:space:]]*true[[:space:]]*$' "$config" \
    || fail "polybar should pin workspaces to each monitor"

# dwm 原生是每个 monitor 各有 1~9 tag。暴露给 polybar/EWMH 时也应表达成
# monitor × tag，而不是一套全局 1~9。
grep -Fq 'countmonitors(void)' "$dwm_c" \
    || fail "dwm should count monitors for per-monitor EWMH desktops"
grep -Fq 'monitortodesktop(Monitor *target)' "$dwm_c" \
    || fail "dwm should map a monitor to an EWMH desktop offset"
grep -Fq 'desktoptomonitor(unsigned long desktop)' "$dwm_c" \
    || fail "dwm should map a clicked EWMH desktop back to a monitor"
grep -Fq 'TAGSLENGTH * countmonitors()' "$dwm_c" \
    || fail "dwm should expose TAGSLENGTH desktops per monitor"
grep -Fq 'desktop / TAGSLENGTH' "$dwm_c" \
    || fail "dwm should derive the target monitor from the clicked desktop"
grep -Fq 'desktop % TAGSLENGTH' "$dwm_c" \
    || fail "dwm should derive the target tag from the clicked desktop"

printf '%s\n' "OK: polybar workspaces are scoped per monitor"
