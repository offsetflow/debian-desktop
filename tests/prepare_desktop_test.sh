#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

command_log="$tmp_dir/commands.log"
stub_dir="$tmp_dir/bin"
mkdir -p "$stub_dir"

cat >"$stub_dir/sudo" <<'EOF'
#!/bin/sh
printf 'sudo' >>"$COMMAND_LOG"
printf ' %s' "$@" >>"$COMMAND_LOG"
printf '\n' >>"$COMMAND_LOG"
exec "$@"
EOF

cat >"$stub_dir/apt-get" <<'EOF'
#!/bin/sh
printf 'apt-get' >>"$COMMAND_LOG"
printf ' %s' "$@" >>"$COMMAND_LOG"
printf '\n' >>"$COMMAND_LOG"
EOF

chmod +x "$stub_dir/sudo" "$stub_dir/apt-get"

PATH="$stub_dir:$PATH" COMMAND_LOG="$command_log" \
    "$repo_dir/scripts/prepare-desktop.sh"

grep -Fqx 'sudo apt-get update' "$command_log"
grep -Fqx 'apt-get update' "$command_log"
grep -Fq 'sudo apt-get install --no-install-recommends -y' "$command_log"

for package_name in \
    xserver-xorg-core \
    dbus-x11 \
    libx11-dev \
    polybar \
    fcitx5-chinese-addons \
    pipewire-pulse \
    fonts-font-awesome \
    fonts-noto-color-emoji \
    feh \
    nsxiv \
    thunar \
    gvfs \
    tumbler \
    git \
    curl \
    ca-certificates \
    zsh \
    fzf \
    fd-find \
    lua5.4 \
    meson \
    libdbus-1-dev \
    libepoxy-dev
do
    grep -Fq " $package_name" "$command_log"
done

if grep -Eqi 'mise|docker|mihomo|mysql|redis' "$command_log"; then
    echo "optional software leaked into the base desktop install" >&2
    exit 1
fi

printf '%s\n' "prepare-desktop tests passed"
