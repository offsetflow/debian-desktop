#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if ! command -v apt-get >/dev/null 2>&1; then
    echo "prepare: this bootstrap requires Debian with apt-get" >&2
    exit 1
fi

printf '%s\n' "==> 1/5 安装基础桌面依赖"
"$repo_dir/scripts/prepare-desktop.sh"

printf '%s\n' "==> 2/5 编译并安装 dwm、st、dmenu"
"$repo_dir/scripts/install-suckless.sh"

printf '%s\n' "==> 3/5 编译并安装 Picom"
"$repo_dir/scripts/install-picom.sh"

printf '%s\n' "==> 4/5 部署桌面配置"
"$repo_dir/scripts/deploy.sh"

printf '%s\n' "==> 5/5 检查安装结果"
"$repo_dir/scripts/check.sh"

printf '\n%s\n' "基础桌面安装完成。运行 startx 进入 dwm。"
