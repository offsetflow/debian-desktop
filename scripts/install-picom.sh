#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd "$script_dir/.." && pwd)
source_dir="$repo_dir/picom"
build_dir=${PICOM_BUILD_DIR:-"$source_dir/build"}

if [[ ! -f "$source_dir/meson.build" ]]; then
    printf 'install-picom: missing source file: %s\n' "$source_dir/meson.build" >&2
    exit 1
fi
if ! command -v meson >/dev/null 2>&1; then
    echo "install-picom: missing command: meson" >&2
    exit 1
fi

setup_args=(
    setup
    "$build_dir"
    "$source_dir"
    --prefix "$HOME/.local"
    --buildtype release
)
if [[ -f "$build_dir/meson-private/coredata.dat" ]]; then
    setup_args+=(--reconfigure)
fi

printf '%s\n' "==> 配置 Picom"
meson "${setup_args[@]}"

printf '%s\n' "==> 编译 Picom"
meson compile -C "$build_dir"

printf '%s\n' "==> 安装 Picom 到 $HOME/.local"
meson install -C "$build_dir"
