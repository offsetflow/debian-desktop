#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

test_home="$tmp_dir/home"
stub_dir="$tmp_dir/bin"
command_log="$tmp_dir/meson.log"
build_dir="$tmp_dir/picom-build"
mkdir -p "$test_home" "$stub_dir"

cat >"$stub_dir/meson" <<'EOF'
#!/bin/sh
printf 'meson' >>"$COMMAND_LOG"
printf ' %s' "$@" >>"$COMMAND_LOG"
printf '\n' >>"$COMMAND_LOG"
if [ "${1:-}" = setup ]; then
    mkdir -p "$2/meson-private"
    : >"$2/meson-private/coredata.dat"
fi
EOF
chmod +x "$stub_dir/meson"

run_installer() {
    (
        cd "$tmp_dir"
        HOME="$test_home" \
        PATH="$stub_dir:$PATH" \
        COMMAND_LOG="$command_log" \
        PICOM_BUILD_DIR="$build_dir" \
            "$repo_dir/scripts/install-picom.sh"
    )
}

run_installer
run_installer

expected_prefix="$test_home/.local"
grep -Fqx \
    "meson setup $build_dir $repo_dir/picom --prefix $expected_prefix --buildtype release" \
    "$command_log"
grep -Fqx \
    "meson setup $build_dir $repo_dir/picom --prefix $expected_prefix --buildtype release --reconfigure" \
    "$command_log"

if [[ $(grep -Fxc "meson compile -C $build_dir" "$command_log") -ne 2 ]]; then
    echo "expected Picom to compile on both runs" >&2
    exit 1
fi
if [[ $(grep -Fxc "meson install -C $build_dir" "$command_log") -ne 2 ]]; then
    echo "expected Picom to install on both runs" >&2
    exit 1
fi

printf '%s\n' "install-picom tests passed"
