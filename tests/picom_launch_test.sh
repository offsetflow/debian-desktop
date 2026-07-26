#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
launch_script="$repo_dir/picom/launch.sh"

grep -Fq 'PICOM_BIN=${PICOM_BIN:-"$HOME/.local/bin/picom"}' "$launch_script"
grep -Fq '"$PICOM_BIN" --config "$CONFIG"' "$launch_script"

if grep -Fq '/usr/local/bin/picom' "$launch_script"; then
    echo "picom launcher still uses /usr/local/bin" >&2
    exit 1
fi

printf '%s\n' "picom launch tests passed"
