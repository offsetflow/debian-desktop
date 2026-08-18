#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd "$script_dir/.." && pwd)
version_file=${I3LOCK_COLOR_VERSION_FILE:-"$repo_dir/lockscreen/i3lock-color-version"}
upstream=${I3LOCK_COLOR_REPOSITORY:-https://github.com/Raymo111/i3lock-color.git}
source_root=${I3LOCK_COLOR_SOURCE_ROOT:-"${XDG_CACHE_HOME:-$HOME/.cache}/debian-desktop/sources"}

if [[ ! -r "$version_file" ]]; then
    printf 'install-i3lock-color: missing version file: %s\n' "$version_file" >&2
    exit 1
fi
IFS= read -r version <"$version_file"
if [[ ! "$version" =~ ^[0-9a-f]{40}$ ]]; then
    printf 'install-i3lock-color: invalid version: %s\n' "$version" >&2
    exit 1
fi

for command_name in git autoreconf make pkg-config; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf 'install-i3lock-color: missing command: %s\n' "$command_name" >&2
        exit 1
    fi
done

source_dir="$source_root/i3lock-color-$version"
if [[ ! -d "$source_dir/.git" ]]; then
    mkdir -p "$source_root"
    git clone --filter=blob:none --no-checkout --depth 1 "$upstream" "$source_dir"
fi

installed_origin=$(git -C "$source_dir" remote get-url origin 2>/dev/null || true)
if [[ "$installed_origin" != "$upstream" ]]; then
    printf 'install-i3lock-color: origin mismatch: expected %s, got %s\n' \
        "$upstream" "${installed_origin:-<missing>}" >&2
    exit 1
fi

if ! git -C "$source_dir" cat-file -e "$version^{commit}" 2>/dev/null; then
    git -C "$source_dir" fetch --depth 1 origin "$version"
fi
git -C "$source_dir" checkout --detach "$version"

printf '%s\n' "==> 生成 i3lock-color 构建文件"
(
    cd "$source_dir"
    autoreconf -fiv
)

build_dir="$source_dir/build-local"
mkdir -p "$build_dir"

printf '%s\n' "==> 配置 i3lock-color"
(
    cd "$build_dir"
    ../configure \
        --prefix="$HOME/.local" \
        --program-suffix=-color
)

jobs=$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '1\n')
printf '%s\n' "==> 编译 i3lock-color"
make -C "$build_dir" -j"$jobs"

printf '%s\n' "==> 安装 i3lock-color 到 $HOME/.local"
make -C "$build_dir" install

installed_bin="$HOME/.local/bin/i3lock-color"
if [[ ! -x "$installed_bin" ]]; then
    printf 'install-i3lock-color: missing installed executable: %s\n' "$installed_bin" >&2
    exit 1
fi

printf 'install-i3lock-color: installed %s at %s\n' "$version" "$installed_bin"
