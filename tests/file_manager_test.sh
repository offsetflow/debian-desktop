#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
config="$repo_dir/suckless/dwm/config.def.h"
keybindings="$repo_dir/KEYBINDINGS.md"

grep -Fq 'static const char *filecmd[]  = { "thunar", NULL };' "$config"
grep -Fq 'XK_e,      spawn,          {.v = filecmd }' "$config"
grep -Fqx 'inode/directory=thunar.desktop;' "$repo_dir/x11/mimeapps.list"
grep -Fq '| `Alt + E` | 打开 `Thunar` 文件管理器 |' "$keybindings"

printf '%s\n' "file manager tests passed"
