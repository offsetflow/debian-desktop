#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

lock_script="$repo_dir/lockscreen/lock.sh"
renderer="$repo_dir/lockscreen/render.py"
dwm_config="$repo_dir/suckless/dwm/config.def.h"
xinitrc="$repo_dir/x11/xinitrc"
installer="$repo_dir/scripts/install-i3lock-color.sh"
version_file="$repo_dir/lockscreen/i3lock-color-version"

[[ -x "$lock_script" ]]
[[ -x "$renderer" ]]
[[ -x "$installer" ]]
grep -Eq '^[0-9a-f]{40}$' "$version_file"
grep -Fq 'XK_l,      spawn,          {.v = lockcmd }' "$dwm_config"
grep -Fq 'xss-lock --transfer-sleep-lock -- "$HOME/.local/bin/lock-screen"' "$xinitrc"
grep -Fq 'I3LOCK_BIN=${I3LOCK_BIN:-i3lock-color}' "$lock_script"
grep -Fq 'DEBIAN_LOGO=${DEBIAN_LOGO:-/usr/share/pixmaps/debian-logo.png}' "$lock_script"
grep -Fq -- '--logo "$DEBIAN_LOGO"' "$lock_script"
grep -Fq -- '--force-clock' "$lock_script"
grep -Fq -- '--refresh-rate=1' "$lock_script"
grep -Fq -- '--time-str="%I:%M %p"' "$lock_script"
grep -Fq -- '--date-str="%Y | %A"' "$lock_script"
grep -Fq -- '--time-font="Comfortaa:style=Bold"' "$lock_script"
grep -Fq -- '--date-font="Comfortaa:style=Bold"' "$lock_script"
grep -Fq -- '--indicator' "$lock_script"
grep -Fq -- '--keyhl-color="FFF0D6FF"' "$lock_script"
grep -Fq -- '--bshl-color="FF8C94FF"' "$lock_script"
grep -Fq -- '--verif-text="正在验证"' "$lock_script"
grep -Fq -- '--wrong-text="密码错误，请重试"' "$lock_script"
grep -Fq -- '--noinput-text="尚未输入"' "$lock_script"
grep -Fq -- '--greeter-text="请输入密码解锁"' "$lock_script"
grep -Fq -- '--show-failed-attempts' "$lock_script"
if grep -Fq -- '--no-unlock-indicator' "$lock_script"; then
    echo "unlock indicator is disabled in the lock script" >&2
    exit 1
fi
if grep -Eq -- 'avatar|username|LOCKSCREEN_(AVATAR|DISPLAY_NAME)' "$lock_script"; then
    echo "avatar or username configuration remains in the lock script" >&2
    exit 1
fi
if grep -Eq -- 'avatar|username|user_pill' "$renderer"; then
    echo "avatar or username rendering remains in the background renderer" >&2
    exit 1
fi
if grep -Fq 'strftime' "$renderer"; then
    echo "static clock rendering remains in the background renderer" >&2
    exit 1
fi
grep -Fq 'logo_size = min(width, height) * 0.09' "$renderer"
grep -Fq 'y + height * 0.50 - logo.get_height() * logo_scale / 2' "$renderer"

preview="$tmp_dir/preview.png"
mkdir -p "$tmp_dir/bin"
ln -s "$lock_script" "$tmp_dir/bin/lock-screen"
LOCKSCREEN_WALLPAPER="$repo_dir/wallpapers/wallhaven-o5zmwm_1920x1080.png" \
LOCKSCREEN_MONITORS='640x360+0+0' \
XDG_RUNTIME_DIR="$tmp_dir" \
    "$tmp_dir/bin/lock-screen" --preview "$preview" >/dev/null

[[ -s "$preview" ]]
dimensions=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=width,height -of csv=s=x:p=0 "$preview")
[[ "$dimensions" == "640x360" ]]

printf '%s\n' "lockscreen source tests passed"
