#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
config="$repo_dir/suckless/dwm/config.def.h"
keybindings="$repo_dir/KEYBINDINGS.md"
docs="$repo_dir/docs/mihomo.md"

grep -Fq 'mihomo/select.sh' "$config"
grep -Eq 'MODKEY\\|ShiftMask,[[:space:]]*XK_p,[[:space:]]*spawn' "$config"
grep -Fq 'arg->v == dmenucmd || arg->v == mihomoselectcmd' "$repo_dir/suckless/dwm/dwm.c"
grep -Fq 'Alt + Shift + P' "$keybindings"
grep -Fq 'mihomo/select.sh' "$docs"
grep -Fq 'select.sh PROXY "节点名称"' "$docs"
grep -Fq '不会修改订阅 YAML' "$docs"

printf '%s\n' "mihomo integration tests passed"
