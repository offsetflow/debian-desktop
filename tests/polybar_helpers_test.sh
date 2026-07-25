#!/bin/sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
brightness="$repo_root/polybar/brightness.sh"
input_method="$repo_root/polybar/input-method.sh"
power_menu="$repo_root/polybar/power-menu.sh"

fail() {
    printf '%s\n' "FAIL: $*" >&2
    exit 1
}

for script in "$brightness" "$input_method" "$power_menu"; do
    [ -x "$script" ] || fail "missing executable helper: $script"
    sh -n "$script" || fail "invalid shell syntax: $script"
done

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM
log="$tmpdir/actions.log"
: >"$log"

cat >"$tmpdir/xrandr" <<'FAKE_XRANDR'
#!/bin/sh
if [ "$1" = "--verbose" ]; then
    printf '%s\n' "HDMI-0 connected primary 1920x1080+0+0"
    printf '\tBrightness: %s\n' "${XRANDR_BRIGHTNESS:-0.75}"
    printf '%s\n' "DP-2 connected 1920x1080+1920+0"
    printf '\tBrightness: 1.0\n'
    exit 0
fi
printf '%s\n' "$*" >>"$ACTION_LOG"
FAKE_XRANDR
chmod +x "$tmpdir/xrandr"

output="$(MONITOR=HDMI-0 XRANDR_BIN="$tmpdir/xrandr" ACTION_LOG="$log" "$brightness" get)"
[ "$output" = "☀ 75%" ] || fail "unexpected brightness label: $output"

MONITOR=HDMI-0 XRANDR_BIN="$tmpdir/xrandr" ACTION_LOG="$log" "$brightness" up
grep -Fq -- '--output HDMI-0 --brightness 0.80' "$log"     || fail "brightness up should add five percent"

: >"$log"
MONITOR=HDMI-0 XRANDR_BIN="$tmpdir/xrandr" XRANDR_BRIGHTNESS=1.0 ACTION_LOG="$log" "$brightness" up
grep -Fq -- '--output HDMI-0 --brightness 1.00' "$log"     || fail "brightness should clamp at one hundred percent"

: >"$log"
MONITOR=HDMI-0 XRANDR_BIN="$tmpdir/xrandr" XRANDR_BRIGHTNESS=0.4 ACTION_LOG="$log" "$brightness" down
grep -Fq -- '--output HDMI-0 --brightness 0.40' "$log"     || fail "brightness should clamp at forty percent"

cat >"$tmpdir/fcitx5-remote" <<'FAKE_FCITX'
#!/bin/sh
if [ "${1:-}" = "-t" ]; then
    printf '%s\n' "toggle" >>"$ACTION_LOG"
    exit 0
fi
printf '%s\n' "${FCITX_STATE:-1}"
FAKE_FCITX
chmod +x "$tmpdir/fcitx5-remote"

output="$(FCITX_REMOTE_BIN="$tmpdir/fcitx5-remote" FCITX_STATE=1 ACTION_LOG="$log" "$input_method" status)"
[ "$output" = "EN" ] || fail "inactive fcitx should show EN"
output="$(FCITX_REMOTE_BIN="$tmpdir/fcitx5-remote" FCITX_STATE=2 ACTION_LOG="$log" "$input_method" status)"
[ "$output" = "中" ] || fail "active fcitx should show Chinese indicator"
FCITX_REMOTE_BIN="$tmpdir/fcitx5-remote" ACTION_LOG="$log" "$input_method" toggle
grep -Fq 'toggle' "$log" || fail "input-method toggle should call fcitx5-remote -t"

cat >"$tmpdir/dmenu" <<'FAKE_DMENU'
#!/bin/sh
printf '%s\n' "${POWER_CHOICE:-}"
FAKE_DMENU
cat >"$tmpdir/systemctl" <<'FAKE_SYSTEMCTL'
#!/bin/sh
printf 'systemctl %s\n' "$*" >>"$ACTION_LOG"
FAKE_SYSTEMCTL
cat >"$tmpdir/pkill" <<'FAKE_PKILL'
#!/bin/sh
printf 'pkill %s\n' "$*" >>"$ACTION_LOG"
FAKE_PKILL
chmod +x "$tmpdir/dmenu" "$tmpdir/systemctl" "$tmpdir/pkill"

: >"$log"
POWER_CHOICE=Reboot DMENU_BIN="$tmpdir/dmenu" SYSTEMCTL_BIN="$tmpdir/systemctl" PKILL_BIN="$tmpdir/pkill" ACTION_LOG="$log" "$power_menu"
grep -Fq 'systemctl reboot' "$log" || fail "Reboot should call systemctl reboot"

: >"$log"
POWER_CHOICE=Logout DMENU_BIN="$tmpdir/dmenu" SYSTEMCTL_BIN="$tmpdir/systemctl" PKILL_BIN="$tmpdir/pkill" ACTION_LOG="$log" "$power_menu"
grep -Fq 'pkill -TERM -x dwm' "$log" || fail "Logout should terminate dwm"

: >"$log"
POWER_CHOICE= DMENU_BIN="$tmpdir/dmenu" SYSTEMCTL_BIN="$tmpdir/systemctl" PKILL_BIN="$tmpdir/pkill" ACTION_LOG="$log" "$power_menu"
[ ! -s "$log" ] || fail "cancelled power menu should not execute an action"

printf '%s\n' "OK: polybar helper scripts behave correctly"
