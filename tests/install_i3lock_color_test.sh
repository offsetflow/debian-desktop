#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

upstream="$tmp_dir/upstream"
test_home="$tmp_dir/home"
stub_dir="$tmp_dir/bin"
command_log="$tmp_dir/commands.log"
mkdir -p "$upstream" "$test_home" "$stub_dir"

cat >"$upstream/configure" <<'EOF'
#!/bin/sh
printf 'configure' >>"$COMMAND_LOG"
printf ' %s' "$@" >>"$COMMAND_LOG"
printf '\n' >>"$COMMAND_LOG"
EOF
chmod +x "$upstream/configure"

git -C "$upstream" init -q
git -C "$upstream" config user.name "Installer Test"
git -C "$upstream" config user.email "installer-test@example.invalid"
git -C "$upstream" add configure
git -C "$upstream" commit -qm "test source"
version=$(git -C "$upstream" rev-parse HEAD)
printf '%s\n' "$version" >"$tmp_dir/version"

cat >"$stub_dir/autoreconf" <<'EOF'
#!/bin/sh
printf 'autoreconf' >>"$COMMAND_LOG"
printf ' %s' "$@" >>"$COMMAND_LOG"
printf '\n' >>"$COMMAND_LOG"
EOF

cat >"$stub_dir/make" <<'EOF'
#!/bin/sh
printf 'make' >>"$COMMAND_LOG"
printf ' %s' "$@" >>"$COMMAND_LOG"
printf '\n' >>"$COMMAND_LOG"
if [ "${*##* install}" != "$*" ]; then
    mkdir -p "$HOME/.local/bin"
    printf '#!/bin/sh\nexit 0\n' >"$HOME/.local/bin/i3lock-color"
    chmod +x "$HOME/.local/bin/i3lock-color"
fi
EOF
chmod +x "$stub_dir/autoreconf" "$stub_dir/make"

HOME="$test_home" \
PATH="$stub_dir:/usr/bin:/bin" \
COMMAND_LOG="$command_log" \
I3LOCK_COLOR_REPOSITORY="$upstream" \
I3LOCK_COLOR_SOURCE_ROOT="$tmp_dir/sources" \
I3LOCK_COLOR_VERSION_FILE="$tmp_dir/version" \
    "$repo_dir/scripts/install-i3lock-color.sh"

grep -Fq 'autoreconf -fiv' "$command_log"
grep -Fq "configure --prefix=$test_home/.local --program-suffix=-color" "$command_log"
grep -Fq ' install' "$command_log"
[[ -x "$test_home/.local/bin/i3lock-color" ]]
[[ $(git -C "$tmp_dir/sources/i3lock-color-$version" rev-parse HEAD) == "$version" ]]

printf '%s\n' "install i3lock-color tests passed"
