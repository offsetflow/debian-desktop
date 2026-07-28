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
printf '# Markdown heading\n\n- preview item\n' >"$tmp_dir/example.md"

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
    "+lua assert(vim.o.autoread and vim.o.confirm and vim.o.undofile and vim.o.list and vim.o.updatetime == 250)" \
    "+lua assert(vim.fn.maparg('<leader>m', 'n') ~= '' and vim.fn.maparg('<leader>qo', 'n') ~= '' and vim.fn.maparg(']q', 'n') ~= '' and vim.fn.maparg('<C-h>', 'n') ~= '')" \
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
    "+lua assert(vim.bo.syntax == 'lua' or vim.b.ts_highlight)" \
    +quit

HOME="$test_home" \
XDG_STATE_HOME="$test_home/.local/state" \
XDG_CACHE_HOME="$test_home/.cache" \
NVIM_SKIP_PLUGINS=1 \
nvim --headless -n -i NONE -u "$repo_dir/neovim/init.lua" "$tmp_dir/example.md" \
    "+lua assert(vim.bo.filetype == 'markdown')" \
    "+lua assert(vim.bo.syntax == 'markdown')" \
    "+lua assert(vim.wo.wrap)" \
    "+lua assert(vim.wo.linebreak)" \
    "+lua assert(vim.fn.maparg('<leader>mp', 'n') ~= '')" \
    +quit

grep -Fq '"lazy.nvim"' "$repo_dir/neovim/lazy-lock.json"
grep -Fq '"lualine.nvim"' "$repo_dir/neovim/lazy-lock.json"
grep -Fq '"fzf-lua"' "$repo_dir/neovim/lazy-lock.json"
grep -Fq '"gitsigns.nvim"' "$repo_dir/neovim/lazy-lock.json"
grep -Fq '"nvim-lspconfig"' "$repo_dir/neovim/lazy-lock.json"
grep -Fq '"previm/previm"' "$repo_dir/neovim/init.lua"
grep -Fq '"tyru/open-browser.vim"' "$repo_dir/neovim/init.lua"
grep -Fq '"ibhagwan/fzf-lua"' "$repo_dir/neovim/init.lua"
grep -Fq '"lewis6991/gitsigns.nvim"' "$repo_dir/neovim/init.lua"
grep -Fq '"neovim/nvim-lspconfig"' "$repo_dir/neovim/init.lua"
grep -Fq 'version = "v1.8.0"' "$repo_dir/neovim/init.lua"

printf '%s\n' "neovim config tests passed"
