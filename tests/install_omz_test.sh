#!/usr/bin/env bash
set -euo pipefail

source_repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

upstream_work="$tmp_dir/upstream-work"
upstream_bare="$tmp_dir/upstream.git"
fixture_repo="$tmp_dir/fixture-repo"
stub_dir="$tmp_dir/bin"
mkdir -p "$upstream_work" "$fixture_repo/scripts" "$fixture_repo/shell" "$stub_dir"

git -C "$upstream_work" init -q
git -C "$upstream_work" config user.name "OMZ Test"
git -C "$upstream_work" config user.email "omz-test@example.invalid"
printf 'first\n' >"$upstream_work/omz.zsh"
git -C "$upstream_work" add omz.zsh
git -C "$upstream_work" commit -qm "first"
pinned_commit=$(git -C "$upstream_work" rev-parse HEAD)
printf 'second\n' >"$upstream_work/omz.zsh"
git -C "$upstream_work" commit -qam "second"
git clone -q --bare "$upstream_work" "$upstream_bare"

cp "$source_repo/scripts/install-omz.sh" "$fixture_repo/scripts/install-omz.sh"
printf '%s\n' "$pinned_commit" >"$fixture_repo/shell/omz-version"

cat >"$stub_dir/fdfind" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$stub_dir/fdfind"

run_installer() {
    test_home=$1
    HOME="$test_home" PATH="$stub_dir:$PATH" OMZ_REPOSITORY="$upstream_bare" \
        "$fixture_repo/scripts/install-omz.sh"
}

test_home="$tmp_dir/home"
mkdir -p "$test_home"
run_installer "$test_home"
run_installer "$test_home"

omz_dir="$test_home/.local/share/omz"
[[ $(git -C "$omz_dir" rev-parse HEAD) == "$pinned_commit" ]]
[[ -z $(git -C "$omz_dir" symbolic-ref -q HEAD || true) ]]
[[ $(readlink "$test_home/.local/bin/fd") == "$stub_dir/fdfind" ]]

unknown_home="$tmp_dir/unknown-home"
mkdir -p "$unknown_home/.local/share/omz"
printf 'keep me\n' >"$unknown_home/.local/share/omz/personal.txt"
if run_installer "$unknown_home" >"$tmp_dir/unknown.out" 2>&1; then
    echo "expected a non-Git OMZ directory to be rejected" >&2
    exit 1
fi
[[ $(cat "$unknown_home/.local/share/omz/personal.txt") == "keep me" ]]

fd_home="$tmp_dir/fd-home"
mkdir -p "$fd_home/.local/bin"
printf 'personal fd\n' >"$fd_home/.local/bin/fd"
if run_installer "$fd_home" >"$tmp_dir/fd.out" 2>&1; then
    echo "expected a conflicting fd file to be rejected" >&2
    exit 1
fi
[[ $(cat "$fd_home/.local/bin/fd") == "personal fd" ]]

printf '%s\n' "install-omz tests passed"
