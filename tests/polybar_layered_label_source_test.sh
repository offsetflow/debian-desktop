#!/bin/sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
polybar_config="$repo_root/polybar/config.ini"
picom_config="$repo_root/picom/picom.conf"
prepare_script="$repo_root/scripts/prepare-desktop.sh"

fail() {
    printf '%s\n' "FAIL: $*" >&2
    exit 1
}

grep -Eq '^[[:space:]]*pseudo-transparency[[:space:]]*=[[:space:]]*false[[:space:]]*$' "$polybar_config" \
    || fail "Polybar must use real ARGB transparency"
grep -Eq '^[[:space:]]*active[[:space:]]*=[[:space:]]*#30ffffff[[:space:]]*$' "$polybar_config" \
    || fail "active label must use a neutral overlay that follows the wallpaper"
grep -Eq '^[[:space:]]*border-top-size[[:space:]]*=[[:space:]]*0[[:space:]]*$' "$polybar_config" \
    || fail "Polybar must not leave an inset above the status bar"
grep -Eq '^[[:space:]]*border-bottom-size[[:space:]]*=[[:space:]]*4px[[:space:]]*$' "$polybar_config" \
    || fail "active label must keep the bottom inset"

grep -Eq '^[[:space:]]*label-active[[:space:]]*=[[:space:]]*%name%[[:space:]]*$' "$polybar_config" \
    || fail "active label must be one plain rectangular layer"
grep -Fq 'label-active-background = ${colors.active}' "$polybar_config" \
    || fail "active label background must be drawn directly by Polybar"
grep -Eq '^[[:space:]]*label-active-padding[[:space:]]*=[[:space:]]*1[[:space:]]*$' "$polybar_config" \
    || fail "active label must keep compact horizontal padding"

if grep -Eq '||Polybar Rounded Caps' "$polybar_config"; then
    fail "rectangular labels must not retain rounded-cap markup or fonts"
fi
if grep -Fq 'install-polybar-fonts.sh' "$prepare_script"; then
    fail "prepare must not install the obsolete rounded-cap font"
fi
if [ -e "$repo_root/scripts/install-polybar-fonts.sh" ]; then
    fail "obsolete rounded-cap font installer must be removed"
fi
if find "$repo_root/polybar/fonts" -maxdepth 1 -name 'PolybarRoundedCaps*' -print -quit 2>/dev/null | grep -q .; then
    fail "obsolete rounded-cap font artifacts must be removed"
fi

grep -Fq "match = \"class_g = 'Polybar'\";" "$picom_config" \
    || fail "Picom must have a Polybar-specific rule"
polybar_rule="$(sed -n '/match = "class_g = '\''Polybar'\''";/,/^[[:space:]]*},/p' "$picom_config")"
printf '%s\n' "$polybar_rule" | grep -Fq 'blur-background = true;' \
    || fail "Polybar-specific Picom rule must keep the frosted background"

printf '%s\n' "OK: Polybar uses one rectangular active layer over the frosted bar"
