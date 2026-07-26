#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

for project in dwm st dmenu; do
    config_def="$repo_dir/suckless/$project/config.def.h"
    config_generated="suckless/$project/config.h"

    [[ -f "$config_def" ]]
    if [[ -e "$repo_dir/$config_generated" ]]; then
        printf 'generated config exists before build: %s\n' "$config_generated" >&2
        exit 1
    fi
    git -C "$repo_dir" check-ignore --no-index -q "$config_generated"
    grep -Fq 'cp "$target/config.def.h" "$target/config.h"' \
        "$repo_dir/scripts/install-suckless.sh"
done

printf '%s\n' "suckless config tests passed"
