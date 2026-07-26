#!/usr/bin/env bash
set -euo pipefail

# 只安装 mise 本体；PATH 与 Shell 激活由仓库管理的 shell/zshrc 提供。
mise_bin="$HOME/.local/bin/mise"
install_url=${MISE_INSTALL_URL:-https://mise.run}

if ! command -v curl >/dev/null 2>&1; then
    echo "prepare-mise: missing command: curl" >&2
    exit 1
fi

mkdir -p "$HOME/.local/bin" "$HOME/.config/mise"

if [[ -x "$mise_bin" ]]; then
    printf 'prepare-mise: already installed: %s\n' "$mise_bin"
else
    printf '%s\n' "==> 安装 mise 到 $mise_bin"
    curl -fsSL "$install_url" | MISE_INSTALL_PATH="$mise_bin" sh
fi

"$mise_bin" --version
