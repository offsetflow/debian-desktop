#!/bin/sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
config="$repo_root/polybar/config.ini"
launch="$repo_root/polybar/launch.sh"
prepare="$repo_root/scripts/prepare-suckless.sh"

fail() {
    printf '%s\n' "FAIL: $*" >&2
    exit 1
}

grep -Eq '^[[:space:]]*height[[:space:]]*=[[:space:]]*36px[[:space:]]*$' "$config"     || fail "bar should match the approved 36px visual height"
grep -Eq '^[[:space:]]*modules-left[[:space:]]*=[[:space:]]*system-mark xworkspaces[[:space:]]*$' "$config"     || fail "left modules should contain only the system mark and workspaces"
grep -Eq '^[[:space:]]*modules-center[[:space:]]*=[[:space:]]*date[[:space:]]*$' "$config"     || fail "date should remain centered"
grep -Fq 'modules-right = ${env:POLYBAR_RIGHT_MODULES:input-method brightness pulseaudio wlan battery power}' "$config"     || fail "right modules should be injected per monitor"
! grep -Eq '^[[:space:]]*modules-left.*xwindow' "$config"     || fail "window title module should not duplicate dynamic workspace names"

for module in system-mark xworkspaces date tray input-method brightness pulseaudio wlan battery power; do
    grep -Fq "[module/$module]" "$config" || fail "missing module: $module"
done

grep -Fq 'type = internal/tray' "$config"     || fail "primary bar should use the native tray"
grep -Fq 'pin-workspaces = true' "$config"     || fail "workspaces must remain monitor-local"
grep -Fq 'label-active-background = ${colors.active}' "$config"     || fail "active app tab should use the wallpaper-following overlay"
grep -Fq 'polybar/brightness.sh get' "$config"     || fail "brightness module should use the helper"
grep -Fq 'polybar/input-method.sh status' "$config"     || fail "input module should use the helper"
grep -Fq 'polybar/power-menu.sh' "$config"     || fail "power module should open the dmenu helper"

grep -Eq '^[[:space:]]*label-empty[[:space:]]*=[[:space:]]*$' "$config" \
    || fail "empty dwm tags should be hidden"
grep -Fq 'FontAwesome' "$config" \
    || fail "status icons should use Font Awesome instead of text abbreviations"
if grep -Fq '${env:HOME}' "$config"; then
    fail "module shell commands must not contain unexpanded Polybar HOME expressions"
fi
grep -Fq 'label-volume =   %percentage%%' "$config" \
    || fail "volume should use an icon"
grep -Fq 'label-connected =   %signal%%' "$config" \
    || fail "Wi-Fi should use an icon"
grep -Fq 'label-discharging =   %percentage%%' "$config" \
    || fail "battery should use an icon"

grep -Fq 'primary_monitor=' "$launch"     || fail "launcher should choose a deterministic primary monitor"
grep -Fq 'right_modules="tray $right_modules"' "$launch"     || fail "only the primary monitor should receive the tray"
grep -Fq 'POLYBAR_RIGHT_MODULES="$right_modules"' "$launch"     || fail "launcher should pass right modules to each bar"

grep -Fq 'x11-xserver-utils' "$prepare"     || fail "bootstrap should install xrandr"
grep -Fq 'fcitx5-chinese-addons' "$prepare"     || fail "bootstrap should install the managed Chinese input method"

printf '%s\n' "OK: polybar matches the approved compact app-tab design"
