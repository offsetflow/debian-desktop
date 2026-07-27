#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

cat >"$tmp_dir/example.c" <<'EOF'
#include <stdio.h>

int main(void)
{
    /* C syntax smoke test. */
    return 0;
}
EOF

printf 'local value = true\n' >"$tmp_dir/example.lua"

test_home="$tmp_dir/home"
mkdir -p "$test_home/.local/state" "$test_home/.cache"

HOME="$test_home" \
XDG_STATE_HOME="$test_home/.local/state" \
XDG_CACHE_HOME="$test_home/.cache" \
NVIM_SKIP_PLUGINS=1 \
nvim --headless -n -i NONE -u "$repo_dir/neovim/init.lua" "$tmp_dir/example.c" \
    "+lua assert(vim.bo.filetype == 'c')" \
    "+lua assert(vim.bo.syntax == 'c')" \
    "+lua assert(vim.bo.cindent)" \
    "+lua assert(vim.bo.omnifunc == 'ccomplete#Complete')" \
    "+lua assert(vim.g.colors_name == 'cloudglass')" \
    "+lua assert(vim.api.nvim_get_hl(0, { name = 'Normal' }).bg == 0x203139)" \
    "+lua assert(vim.o.statusline:find('%f', 1, true))" \
    +quit

HOME="$test_home" \
XDG_STATE_HOME="$test_home/.local/state" \
XDG_CACHE_HOME="$test_home/.cache" \
NVIM_SKIP_PLUGINS=1 \
nvim --headless -n -i NONE -u "$repo_dir/neovim/init.lua" "$tmp_dir/example.lua" \
    "+lua assert(vim.bo.filetype == 'lua')" \
    "+lua assert(vim.bo.syntax == '')" \
    +quit

grep -Fq '"lazy.nvim"' "$repo_dir/neovim/lazy-lock.json"
grep -Fq '"lualine.nvim"' "$repo_dir/neovim/lazy-lock.json"

printf '%s\n' "neovim config tests passed"
