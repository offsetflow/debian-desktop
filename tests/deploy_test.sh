#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_home=$(mktemp -d)
trap 'rm -rf "$test_home"' EXIT

HOME="$test_home" "$repo_dir/scripts/deploy.sh"

assert_link() {
    target=$1
    expected=$2

    if [[ ! -L "$target" ]]; then
        printf 'expected symlink: %s\n' "$target" >&2
        exit 1
    fi
    if [[ $(readlink "$target") != "$expected" ]]; then
        printf 'wrong link target: %s\n' "$target" >&2
        exit 1
    fi
}

assert_link "$test_home/.xinitrc" "$repo_dir/x11/xinitrc"
assert_link "$test_home/.config/picom/picom.conf" "$repo_dir/picom/picom.conf"
assert_link "$test_home/.config/polybar/config.ini" "$repo_dir/polybar/config.ini"
assert_link "$test_home/.config/fontconfig/fonts.conf" "$repo_dir/fontconfig/fonts.conf"

# A second run must leave already-correct links untouched.
HOME="$test_home" "$repo_dir/scripts/deploy.sh"

# An existing user-owned file must never be overwritten.
rm "$test_home/.xinitrc"
printf 'personal config\n' >"$test_home/.xinitrc"
if HOME="$test_home" "$repo_dir/scripts/deploy.sh" >"$test_home/deploy.out" 2>&1; then
    echo "expected an existing-file conflict to fail" >&2
    exit 1
fi
grep -Fq "deploy: conflict: $test_home/.xinitrc already exists" "$test_home/deploy.out"
[[ $(cat "$test_home/.xinitrc") == "personal config" ]]

printf '%s\n' "deploy tests passed"
