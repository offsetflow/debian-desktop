#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

test_home="$tmp_dir/home"
stub_dir="$tmp_dir/bin"
mkdir -p "$test_home" "$stub_dir"
ln -s "$(command -v bash)" "$stub_dir/bash"
ln -s "$(command -v curl)" "$stub_dir/curl"

if HOME="$test_home" PATH="$stub_dir" \
    "$repo_dir/scripts/prepare-mihomo.sh" >"$tmp_dir/output" 2>&1
then
    echo "prepare-mihomo unexpectedly succeeded without jq" >&2
    exit 1
fi

grep -Fqx 'prepare-mihomo: missing command: jq' "$tmp_dir/output"
if [[ -e "$test_home/.config/mihomo" ]]; then
    echo "prepare-mihomo wrote configuration before prerequisite checks" >&2
    exit 1
fi

printf '%s\n' "prepare-mihomo tests passed"
