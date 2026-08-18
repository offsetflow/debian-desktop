#!/bin/sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
config="$repo_root/gsimplecal/config"
polybar_config="$repo_root/polybar/config.ini"
popup="$repo_root/polybar/calendar-popup.py"
toggle="$repo_root/polybar/calendar-popup.sh"
dwm_config="$repo_root/suckless/dwm/config.def.h"
picom_config="$repo_root/picom/picom.conf"
prepare="$repo_root/scripts/prepare-desktop.sh"

fail() {
    printf '%s\n' "FAIL: $*" >&2
    exit 1
}

[ -f "$config" ] || fail "missing gsimplecal config"
[ -x "$popup" ] || fail "missing executable custom calendar popup"
[ -x "$toggle" ] || fail "missing executable calendar toggle helper"
grep -Fq 'calendar-popup.sh toggle:}%date%  %time%%{A}' "$polybar_config" \
    || fail "date label should toggle the custom calendar popup"
grep -Fq 'set_wmclass("desktop-calendar", "DesktopCalendar")' "$popup" \
    || fail "custom popup should publish a stable X11 class"
grep -Fq 'display_date = self.selected' "$popup" \
    || fail "calendar header should follow the selected date"
grep -Fq 'date_status = "今天" if display_date == self.today else "已选择"' "$popup" \
    || fail "calendar header should distinguish today from another selection"
sed -n '/elif is_selected:/,+3p' "$popup" | grep -Fq 'cr.new_path()' \
    || fail "selected-day outline should start a fresh Cairo path"
grep -Fq 'cr.set_source_rgba(0.045, 0.048, 0.078, 0.78)' "$popup" \
    || fail "calendar card should keep a translucent glass background"
grep -Fq 'grep -aFq "$POPUP" "/proc/$popup_pid/cmdline"' "$toggle" \
    || fail "toggle helper should validate a stored process before stopping it"
grep -Fq 'exec gsimplecal' "$toggle" \
    || fail "custom popup should retain the lightweight fallback"
grep -Eq '^close_on_unfocus[[:space:]]*=[[:space:]]*0$' "$config" \
    || fail "calendar should stay open when skip-taskbar prevents focus"
grep -Eq '^mainwindow_position[[:space:]]*=[[:space:]]*mouse$' "$config" \
    || fail "calendar should open by the clicked date module"
grep -Eq '^mainwindow_resizable[[:space:]]*=[[:space:]]*0$' "$config" \
    || fail "calendar should advertise itself as a popup"
grep -Fq '"Gsimplecal"' "$dwm_config" \
    || fail "dwm should keep the fallback calendar floating"
grep -Fq '"DesktopCalendar"' "$dwm_config" \
    || fail "dwm should keep the custom calendar floating"
grep -Fq "class_g = 'Gsimplecal'" "$picom_config" \
    || fail "Picom should style the fallback calendar popup"
grep -Fq "class_g = 'DesktopCalendar'" "$picom_config" \
    || fail "Picom should style the custom calendar popup"
grep -Eq '^[[:space:]]*gsimplecal[[:space:]]*$' "$prepare" \
    || fail "bootstrap should install the fallback calendar"
grep -Eq '^[[:space:]]*python3-gi[[:space:]]*$' "$prepare" \
    || fail "bootstrap should install Python GTK bindings"
grep -Eq '^[[:space:]]*python3-gi-cairo[[:space:]]*$' "$prepare" \
    || fail "bootstrap should install the GTK drawing bridge"
grep -Eq '^[[:space:]]*gir1\.2-gtk-3\.0[[:space:]]*$' "$prepare" \
    || fail "bootstrap should install GTK3 introspection data"

printf '%s\n' "calendar popup source tests passed"
