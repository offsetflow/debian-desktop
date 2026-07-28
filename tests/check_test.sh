#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

test_home="$tmp_dir/home"
stub_dir="$tmp_dir/bin"
mkdir -p "$test_home/.config/picom" \
    "$test_home/.config/polybar" \
    "$test_home/.config/fontconfig" \
    "$test_home/.config/nvim" \
    "$test_home/.local/bin" \
    "$test_home/.local/share" \
    "$stub_dir"

for command_name in \
    dwm st dmenu picom polybar startx fcitx5 pipewire wireplumber \
    flameshot feh nsxiv thunar zsh fzf fd rg nvim lua fdfind
do
    printf '#!/bin/sh\nexit 0\n' >"$stub_dir/$command_name"
    chmod +x "$stub_dir/$command_name"
done
printf '#!/bin/sh\nexit 0\n' >"$test_home/.local/bin/picom"
chmod +x "$test_home/.local/bin/picom"
printf '#!/bin/sh\nexit 0\n' >"$test_home/.local/bin/mise"
chmod +x "$test_home/.local/bin/mise"
ln -s "$(command -v dirname)" "$stub_dir/dirname"
ln -s "$(command -v readlink)" "$stub_dir/readlink"
ln -s "$(command -v git)" "$stub_dir/git"
cat >"$stub_dir/getent" <<'EOF'
#!/bin/sh
printf 'dev:x:1000:1000:Dev User:/home/dev:%s\n' "$DEFAULT_SHELL"
EOF
chmod +x "$stub_dir/getent"

ln -s "$repo_dir/x11/xinitrc" "$test_home/.xinitrc"
ln -s "$repo_dir/picom/picom.conf" "$test_home/.config/picom/picom.conf"
ln -s "$repo_dir/polybar/config.ini" "$test_home/.config/polybar/config.ini"
ln -s "$repo_dir/fontconfig/fonts.conf" "$test_home/.config/fontconfig/fonts.conf"
ln -s "$repo_dir/neovim/init.lua" "$test_home/.config/nvim/init.lua"
ln -s "$repo_dir/x11/mimeapps.list" "$test_home/.config/mimeapps.list"
ln -s "$repo_dir/shell/zshrc" "$test_home/.zshrc"
ln -s "$stub_dir/fdfind" "$test_home/.local/bin/fd"

omz_dir="$test_home/.local/share/omz"
git init -q "$omz_dir"
git -C "$omz_dir" config user.name "Check Test"
git -C "$omz_dir" config user.email "check-test@example.invalid"
git -C "$omz_dir" remote add origin "$tmp_dir/upstream.git"
printf 'pinned\n' >"$omz_dir/omz.zsh"
git -C "$omz_dir" add omz.zsh
git -C "$omz_dir" commit -qm "pinned"
omz_version=$(git -C "$omz_dir" rev-parse HEAD)
printf '%s\n' "$omz_version" >"$tmp_dir/omz-version"

HOME="$test_home" \
PATH="$stub_dir" \
USER=dev \
DEFAULT_SHELL="$stub_dir/zsh" \
OMZ_REPOSITORY="$tmp_dir/upstream.git" \
OMZ_VERSION_FILE="$tmp_dir/omz-version" \
GETENT_BIN="$stub_dir/getent" \
ZSH_PATH="$stub_dir/zsh" \
    "$repo_dir/scripts/check.sh"

rm "$test_home/.local/bin/picom"
rm "$test_home/.local/bin/mise"
rm "$test_home/.config/polybar/config.ini"
printf 'local config\n' >"$test_home/.config/polybar/config.ini"
printf 'drift\n' >>"$omz_dir/omz.zsh"
git -C "$omz_dir" commit -qam "drift"

if HOME="$test_home" \
    PATH="$stub_dir" \
    USER=dev \
    DEFAULT_SHELL=/bin/bash \
    OMZ_REPOSITORY="$tmp_dir/upstream.git" \
    OMZ_VERSION_FILE="$tmp_dir/omz-version" \
    GETENT_BIN="$stub_dir/getent" \
    ZSH_PATH="$stub_dir/zsh" \
    "$repo_dir/scripts/check.sh" >"$tmp_dir/check.out" 2>&1
then
    echo "expected missing command and incorrect link to fail" >&2
    exit 1
fi

grep -Fq "check: missing executable: $test_home/.local/bin/picom" "$tmp_dir/check.out"
grep -Fq "check: missing executable: $test_home/.local/bin/mise" "$tmp_dir/check.out"
grep -Fq "check: incorrect link: $test_home/.config/polybar/config.ini" \
    "$tmp_dir/check.out"
grep -Fq 'check: OMZ version mismatch:' "$tmp_dir/check.out"
grep -Fq 'check: default shell is not Zsh:' "$tmp_dir/check.out"

printf '%s\n' "check tests passed"
