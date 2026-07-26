#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

for removed_path in \
    scripts/prepare-suckless.sh \
    wallpapers/dark-fluid-ultrawide.png \
    wallpapers/wallhaven-gw2gyq-1920x1080.png \
    wallpapers/wallhaven-xedleo_3000x1687.png
do
    if [[ -e "$repo_dir/$removed_path" ]]; then
        printf 'obsolete path still exists: %s\n' "$removed_path" >&2
        exit 1
    fi
done

[[ -f "$repo_dir/wallpapers/wallhaven-j3qq15_1920x1080.png" ]]

if rg -n \
    'prepare-suckless|dark-fluid-ultrawide|wallhaven-gw2gyq|wallhaven-xedleo' \
    "$repo_dir" \
    --glob '!docs/superpowers/plans/2026-07-26-clean-bootstrap.md' \
    --glob '!docs/superpowers/specs/2026-07-26-clean-bootstrap-design.md' \
    --glob '!tests/repository_hygiene_test.sh'
then
    echo "maintained files reference removed content" >&2
    exit 1
fi

printf '%s\n' "repository hygiene tests passed"
