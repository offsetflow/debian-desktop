#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd "$script_dir/.." && pwd)
version_file="$repo_dir/shell/omz-version"
omz_repository=${OMZ_REPOSITORY:-https://github.com/yaocccc/omz.git}
omz_dir="$HOME/.local/share/omz"
fd_link="$HOME/.local/bin/fd"

for required_command in git fdfind; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        printf 'install-omz: missing command: %s\n' "$required_command" >&2
        exit 1
    fi
done

if [[ ! -f "$version_file" ]]; then
    printf 'install-omz: missing version file: %s\n' "$version_file" >&2
    exit 1
fi
version=$(<"$version_file")
if [[ ! $version =~ ^[0-9a-f]{40}$ ]]; then
    printf 'install-omz: invalid commit in %s\n' "$version_file" >&2
    exit 1
fi

if [[ -e "$omz_dir" && ! -d "$omz_dir/.git" ]]; then
    printf 'install-omz: refusing to replace non-Git path: %s\n' "$omz_dir" >&2
    exit 1
fi

new_checkout=false
if [[ ! -e "$omz_dir" ]]; then
    mkdir -p "$(dirname "$omz_dir")"
    printf '%s\n' "==> 克隆 OMZ"
    git clone --no-checkout "$omz_repository" "$omz_dir"
    new_checkout=true
fi

origin_url=$(git -C "$omz_dir" remote get-url origin 2>/dev/null || true)
if [[ $origin_url != "$omz_repository" ]]; then
    printf 'install-omz: unexpected origin for %s: %s\n' \
        "$omz_dir" "${origin_url:-<missing>}" >&2
    exit 1
fi
if [[ $new_checkout == false && -n $(git -C "$omz_dir" status --porcelain) ]]; then
    printf 'install-omz: checkout has local changes: %s\n' "$omz_dir" >&2
    exit 1
fi

printf '%s\n' "==> 获取并切换到固定 OMZ 版本 $version"
git -C "$omz_dir" fetch --depth 1 origin "$version"
git -C "$omz_dir" checkout --detach "$version"

installed_version=$(git -C "$omz_dir" rev-parse HEAD)
if [[ $installed_version != "$version" ]]; then
    printf 'install-omz: version mismatch: expected %s, got %s\n' \
        "$version" "$installed_version" >&2
    exit 1
fi

fdfind_path=$(command -v fdfind)
if [[ -L "$fd_link" ]]; then
    current_fd=$(readlink "$fd_link")
    if [[ $current_fd != "$fdfind_path" ]]; then
        printf 'install-omz: conflicting fd symlink: %s -> %s\n' \
            "$fd_link" "$current_fd" >&2
        exit 1
    fi
elif [[ -e "$fd_link" ]]; then
    printf 'install-omz: refusing to replace existing fd: %s\n' "$fd_link" >&2
    exit 1
else
    mkdir -p "$(dirname "$fd_link")"
    ln -s "$fdfind_path" "$fd_link"
fi

printf '%s\n' "OMZ 已安装到 $omz_dir"
