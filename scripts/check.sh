#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
failed=0

for command_name in \
    dwm \
    st \
    dmenu \
    picom \
    polybar \
    startx \
    fcitx5 \
    pipewire \
    wireplumber
do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf 'check: missing command: %s\n' "$command_name" >&2
        failed=1
    fi
done

check_link() {
    source=$1
    target=$2

    if [ ! -L "$target" ] || [ "$(readlink "$target" 2>/dev/null || true)" != "$source" ]; then
        printf 'check: incorrect link: %s (expected %s)\n' "$target" "$source" >&2
        failed=1
    fi
}

check_executable() {
    path=$1

    if [ ! -x "$path" ]; then
        printf 'check: script is not executable: %s\n' "$path" >&2
        failed=1
    fi
}

check_link "$REPO_DIR/x11/xinitrc" "$HOME/.xinitrc"
check_link "$REPO_DIR/picom/picom.conf" "$HOME/.config/picom/picom.conf"
check_link "$REPO_DIR/polybar/config.ini" "$HOME/.config/polybar/config.ini"
check_link "$REPO_DIR/fontconfig/fonts.conf" "$HOME/.config/fontconfig/fonts.conf"

check_executable "$REPO_DIR/x11/start-dwm.sh"
check_executable "$REPO_DIR/picom/launch.sh"
check_executable "$REPO_DIR/polybar/launch.sh"
check_executable "$REPO_DIR/wallpapers/set-wallpaper.sh"

if [ "$failed" -eq 0 ]; then
    printf '%s\n' "check: base desktop installation is ready"
fi

exit "$failed"
