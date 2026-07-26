#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

grep -Fq 'XK_w,      spawn,          {.v = wallpaperselectcmd }' \
    "$repo_dir/suckless/dwm/config.def.h"
grep -Fq '| `Alt + Shift + W` | 预览并选择桌面壁纸 |' \
    "$repo_dir/KEYBINDINGS.md"

stub_dir="$tmp_dir/bin"
state_dir="$tmp_dir/state"
command_log="$tmp_dir/commands.log"
selected_wallpaper="$repo_dir/wallpapers/wallhaven-o5zmwm_1920x1080.png"
mkdir -p "$stub_dir"

cat >"$stub_dir/feh" <<'EOF'
#!/bin/sh
printf 'feh' >>"$COMMAND_LOG"
printf ' %s' "$@" >>"$COMMAND_LOG"
printf '\n' >>"$COMMAND_LOG"
EOF

cat >"$stub_dir/nsxiv" <<'EOF'
#!/bin/sh
printf 'nsxiv' >>"$COMMAND_LOG"
printf ' %s' "$@" >>"$COMMAND_LOG"
printf '\n' >>"$COMMAND_LOG"
cat >"$NSXIV_INPUT_LOG"
printf '%s\n' "$SELECTED_WALLPAPER"
EOF

chmod +x "$stub_dir/feh" "$stub_dir/nsxiv"

PATH="$stub_dir:$PATH" \
COMMAND_LOG="$command_log" \
NSXIV_INPUT_LOG="$tmp_dir/nsxiv-input.log" \
SELECTED_WALLPAPER="$selected_wallpaper" \
XDG_STATE_HOME="$state_dir" \
    "$repo_dir/wallpapers/select-wallpaper.sh"

grep -Fqx 'nsxiv -t -o -i' "$command_log"
grep -Fqx "feh --no-fehbg --bg-fill $selected_wallpaper" "$command_log"
grep -Fqx "$selected_wallpaper" "$state_dir/debian-desktop/wallpaper"
grep -Fqx "$selected_wallpaper" "$tmp_dir/nsxiv-input.log"
if grep -Fq "$repo_dir/wallpapers/1.sh" "$tmp_dir/nsxiv-input.log"; then
    printf '%s\n' "non-image file was sent to nsxiv" >&2
    exit 1
fi

: >"$command_log"
PATH="$stub_dir:$PATH" \
COMMAND_LOG="$command_log" \
XDG_STATE_HOME="$state_dir" \
    "$repo_dir/wallpapers/set-wallpaper.sh"

grep -Fqx "feh --no-fehbg --bg-fill $selected_wallpaper" "$command_log"

printf '%s\n' "wallpaper selector tests passed"
