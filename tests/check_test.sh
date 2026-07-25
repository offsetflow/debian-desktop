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
    "$stub_dir"

for command_name in dwm st dmenu picom polybar startx fcitx5 pipewire wireplumber; do
    printf '#!/bin/sh\nexit 0\n' >"$stub_dir/$command_name"
    chmod +x "$stub_dir/$command_name"
done
ln -s "$(command -v dirname)" "$stub_dir/dirname"
ln -s "$(command -v readlink)" "$stub_dir/readlink"

ln -s "$repo_dir/x11/xinitrc" "$test_home/.xinitrc"
ln -s "$repo_dir/picom/picom.conf" "$test_home/.config/picom/picom.conf"
ln -s "$repo_dir/polybar/config.ini" "$test_home/.config/polybar/config.ini"
ln -s "$repo_dir/fontconfig/fonts.conf" "$test_home/.config/fontconfig/fonts.conf"

HOME="$test_home" PATH="$stub_dir" "$repo_dir/scripts/check.sh"

rm "$stub_dir/picom"
rm "$test_home/.config/polybar/config.ini"
printf 'local config\n' >"$test_home/.config/polybar/config.ini"

if HOME="$test_home" PATH="$stub_dir" \
    "$repo_dir/scripts/check.sh" >"$tmp_dir/check.out" 2>&1
then
    echo "expected missing command and incorrect link to fail" >&2
    exit 1
fi

grep -Fq 'check: missing command: picom' "$tmp_dir/check.out"
grep -Fq "check: incorrect link: $test_home/.config/polybar/config.ini" \
    "$tmp_dir/check.out"

printf '%s\n' "check tests passed"
