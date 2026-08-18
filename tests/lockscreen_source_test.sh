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
grep -Fq -- '--force-clock' "$lock_script"
grep -Fq -- '--refresh-rate=1' "$lock_script"
grep -Fq -- '--time-str="%I:%M %p"' "$lock_script"
grep -Fq -- '--date-str="%Y | %A"' "$lock_script"
grep -Fq -- '--no-unlock-indicator' "$lock_script"
grep -Fq -- '--time-font="Comfortaa:style=Bold"' "$lock_script"
grep -Fq -- '--date-font="Comfortaa:style=Bold"' "$lock_script"
if grep -Eq -- '--(indicator|avatar|username)|LOCKSCREEN_(AVATAR|DISPLAY_NAME)' "$lock_script"; then
    echo "avatar, username or indicator configuration remains in the lock script" >&2
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
