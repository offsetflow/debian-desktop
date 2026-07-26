#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
OMZ_VERSION_FILE=${OMZ_VERSION_FILE:-"$REPO_DIR/shell/omz-version"}
OMZ_REPOSITORY=${OMZ_REPOSITORY:-https://github.com/yaocccc/omz.git}
GETENT_BIN=${GETENT_BIN:-getent}
TARGET_USER=${TARGET_USER:-${SUDO_USER:-$USER}}
failed=0
picom_bin="$HOME/.local/bin/picom"
mise_bin="$HOME/.local/bin/mise"

for command_name in \
    dwm \
    st \
    dmenu \
    picom \
    polybar \
    startx \
    fcitx5 \
    pipewire \
    wireplumber \
    feh \
    nsxiv \
    thunar \
    git \
    zsh \
    fzf \
    fd \
    fdfind \
    lua
do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf 'check: missing command: %s\n' "$command_name" >&2
        failed=1
    fi
done

if [ ! -x "$picom_bin" ]; then
    printf 'check: missing executable: %s\n' "$picom_bin" >&2
    failed=1
fi

if [ ! -x "$mise_bin" ]; then
    printf 'check: missing executable: %s\n' "$mise_bin" >&2
    failed=1
fi

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
check_link "$REPO_DIR/x11/mimeapps.list" "$HOME/.config/mimeapps.list"
check_link "$REPO_DIR/shell/zshrc" "$HOME/.zshrc"

fdfind_path=$(command -v fdfind 2>/dev/null || true)
if [ -n "$fdfind_path" ]; then
    check_link "$fdfind_path" "$HOME/.local/bin/fd"
fi

check_executable "$REPO_DIR/x11/start-dwm.sh"
check_executable "$REPO_DIR/picom/launch.sh"
check_executable "$REPO_DIR/polybar/launch.sh"
check_executable "$REPO_DIR/wallpapers/set-wallpaper.sh"
check_executable "$REPO_DIR/wallpapers/select-wallpaper.sh"
check_executable "$REPO_DIR/scripts/install-omz.sh"
check_executable "$REPO_DIR/scripts/set-default-shell.sh"

omz_dir="$HOME/.local/share/omz"
if ! git -C "$omz_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf 'check: OMZ is not a Git checkout: %s\n' "$omz_dir" >&2
    failed=1
else
    expected_origin=$OMZ_REPOSITORY
    installed_origin=$(git -C "$omz_dir" remote get-url origin 2>/dev/null || true)
    if [ "$installed_origin" != "$expected_origin" ]; then
        printf 'check: OMZ origin mismatch: expected %s, got %s\n' \
            "$expected_origin" "${installed_origin:-<missing>}" >&2
        failed=1
    fi

    expected_version=
    if [ -r "$OMZ_VERSION_FILE" ]; then
        IFS= read -r expected_version <"$OMZ_VERSION_FILE" || true
    fi
    installed_version=$(git -C "$omz_dir" rev-parse HEAD 2>/dev/null || true)
    if [ -z "$expected_version" ] || [ "$installed_version" != "$expected_version" ]; then
        printf 'check: OMZ version mismatch: expected %s, got %s\n' \
            "${expected_version:-<missing>}" "${installed_version:-<missing>}" >&2
        failed=1
    fi
fi

zsh_path=${ZSH_PATH:-$(command -v zsh 2>/dev/null || true)}
passwd_record=$("$GETENT_BIN" passwd "$TARGET_USER" 2>/dev/null || true)
current_shell=${passwd_record##*:}
if [ -z "$zsh_path" ] || [ "$current_shell" != "$zsh_path" ]; then
    printf 'check: default shell is not Zsh: expected %s, got %s\n' \
        "${zsh_path:-<missing>}" "${current_shell:-<missing>}" >&2
    failed=1
fi

if [ "$failed" -eq 0 ]; then
    printf '%s\n' "check: base desktop installation is ready"
fi

exit "$failed"
