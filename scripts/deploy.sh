#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

link_config() {
    source=$1
    target=$2

    if [ -L "$target" ]; then
        current=$(readlink "$target")
        if [ "$current" = "$source" ]; then
            printf 'deploy: already linked: %s\n' "$target"
            return 0
        fi
        printf 'deploy: conflict: %s is a symlink to %s\n' "$target" "$current" >&2
        return 1
    fi

    if [ -e "$target" ]; then
        printf 'deploy: conflict: %s already exists\n' "$target" >&2
        return 1
    fi

    mkdir -p "$(dirname -- "$target")"
    ln -s "$source" "$target"
    printf 'deploy: linked: %s -> %s\n' "$target" "$source"
}

link_config "$REPO_DIR/x11/xinitrc" "$HOME/.xinitrc"
link_config "$REPO_DIR/picom/picom.conf" "$HOME/.config/picom/picom.conf"
link_config "$REPO_DIR/polybar/config.ini" "$HOME/.config/polybar/config.ini"
link_config "$REPO_DIR/fontconfig/fonts.conf" "$HOME/.config/fontconfig/fonts.conf"
link_config "$REPO_DIR/shell/zshrc" "$HOME/.zshrc"
