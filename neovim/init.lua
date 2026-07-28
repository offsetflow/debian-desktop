-- Lightweight Neovim configuration for C and Markdown editing.

local config_file = debug.getinfo(1, "S").source:sub(2)
local config_dir = vim.fn.fnamemodify(vim.fn.resolve(config_file), ":h")

vim.g.mapleader = " "

vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.wrap = false
vim.opt.scrolloff = 4
vim.opt.sidescrolloff = 4
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.laststatus = 2
vim.opt.showmode = false
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.autoread = true
vim.opt.confirm = true
vim.opt.undofile = true
vim.opt.updatetime = 250
vim.opt.list = true
vim.opt.listchars = {
    tab = "» ",
    trail = "·",
    nbsp = "␣",
}

vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", { desc = "Save file" })
vim.keymap.set("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit window" })
vim.keymap.set("n", "<leader>m", "<cmd>make<cr>", { desc = "Run make" })
vim.keymap.set("n", "<leader>qo", "<cmd>copen<cr>", { desc = "Open quickfix" })
vim.keymap.set("n", "<leader>qc", "<cmd>cclose<cr>", { desc = "Close quickfix" })
vim.keymap.set("n", "[q", "<cmd>cprevious<cr>", { desc = "Previous quickfix item" })
vim.keymap.set("n", "]q", "<cmd>cnext<cr>", { desc = "Next quickfix item" })
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Focus left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Focus lower window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Focus upper window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Focus right window" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { silent = true })
vim.keymap.set(
    "n",
    "<leader>mp",
    "<cmd>PrevimOpen<cr>",
    { desc = "Open Markdown preview" }
)

-- Treat headers as C files in this deliberately C-only setup.
vim.filetype.add({
    extension = {
        h = "c",
    },
})

-- Use Neovim's built-in syntax support for every detected file type.
vim.cmd("syntax enable")
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "c", "markdown" },
    callback = function(args)
        if args.match == "c" then
            vim.bo.cindent = true
            vim.bo.omnifunc = "ccomplete#Complete"
        elseif args.match == "markdown" then
            vim.wo.wrap = true
            vim.wo.linebreak = true
        end
    end,
})

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local map = function(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, {
                buffer = args.buf,
                desc = desc,
            })
        end

        vim.bo[args.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
        map("gd", vim.lsp.buf.definition, "Go to definition")
        map("gr", vim.lsp.buf.references, "Find references")
        map("K", vim.lsp.buf.hover, "Show documentation")
        map("[d", vim.diagnostic.goto_prev, "Previous diagnostic")
        map("]d", vim.diagnostic.goto_next, "Next diagnostic")
        map("<leader>e", vim.diagnostic.open_float, "Show diagnostic")
    end,
})

vim.diagnostic.config({
    severity_sort = true,
    float = { border = "rounded", source = "if_many" },
    signs = true,
    underline = true,
    virtual_text = false,
})

local palette = {
    bg = "#203139",
    fg = "#b8c4c7",
    muted = "#667a80",
    surface = "#293b42",
    surface_light = "#354b53",
    cyan = "#43a8bd",
    blue = "#4d91bd",
    green = "#7eae83",
    yellow = "#d2a24c",
    orange = "#c98752",
    red = "#d66b6b",
    purple = "#a988b5",
}

-- A readable fallback remains available if plugins have not been downloaded
-- yet or Neovim is started without network access.
vim.opt.statusline = "  %f %m%r %= %y  %l:%c  %p%% "

local function apply_colors()
    vim.g.colors_name = "cloudglass"

    local set = vim.api.nvim_set_hl
    set(0, "Normal", { fg = palette.fg, bg = palette.bg })
    set(0, "NormalNC", { fg = palette.fg, bg = palette.bg })
    set(0, "NormalFloat", { fg = palette.fg, bg = palette.surface })
    set(0, "FloatBorder", { fg = palette.cyan, bg = palette.surface })
    set(0, "Cursor", { fg = palette.surface, bg = palette.fg })
    set(0, "CursorLine", { bg = palette.surface })
    set(0, "CursorLineNr", { fg = palette.yellow, bold = true })
    set(0, "LineNr", { fg = palette.muted })
    set(0, "SignColumn", { bg = palette.bg })
    set(0, "Visual", { bg = palette.surface_light })
    set(0, "Search", { fg = palette.surface, bg = palette.yellow })
    set(0, "IncSearch", { fg = palette.surface, bg = palette.orange })
    set(0, "MatchParen", { fg = palette.yellow, bold = true })
    set(0, "StatusLine", { fg = palette.fg, bg = palette.surface_light })
    set(0, "StatusLineNC", { fg = palette.muted, bg = palette.surface })
    set(0, "VertSplit", { fg = palette.surface_light, bg = palette.bg })
    set(0, "WinSeparator", { fg = palette.surface_light, bg = palette.bg })
    set(0, "Pmenu", { fg = palette.fg, bg = palette.surface })
    set(0, "PmenuSel", { fg = palette.surface, bg = palette.cyan })
    set(0, "Directory", { fg = palette.cyan })
    set(0, "Title", { fg = palette.cyan, bold = true })
    set(0, "ErrorMsg", { fg = palette.red })
    set(0, "WarningMsg", { fg = palette.yellow })
    set(0, "DiagnosticError", { fg = palette.red })
    set(0, "DiagnosticWarn", { fg = palette.yellow })
    set(0, "DiagnosticInfo", { fg = palette.blue })
    set(0, "DiagnosticHint", { fg = palette.cyan })
    set(0, "GitSignsAdd", { fg = palette.green })
    set(0, "GitSignsChange", { fg = palette.blue })
    set(0, "GitSignsDelete", { fg = palette.red })

    set(0, "Comment", { fg = palette.green, italic = true })
    set(0, "Constant", { fg = palette.orange })
    set(0, "String", { fg = palette.green })
    set(0, "Character", { fg = palette.green })
    set(0, "Number", { fg = palette.orange })
    set(0, "Boolean", { fg = palette.orange })
    set(0, "Identifier", { fg = palette.fg })
    set(0, "Function", { fg = palette.blue })
    set(0, "Statement", { fg = palette.yellow })
    set(0, "Conditional", { fg = palette.yellow })
    set(0, "Repeat", { fg = palette.yellow })
    set(0, "Operator", { fg = palette.yellow })
    set(0, "PreProc", { fg = palette.red })
    set(0, "Type", { fg = palette.cyan })
    set(0, "StorageClass", { fg = palette.cyan })
    set(0, "Structure", { fg = palette.cyan })
    set(0, "Special", { fg = palette.purple })
    set(0, "Todo", { fg = palette.surface, bg = palette.yellow, bold = true })
end

apply_colors()

local function setup_plugins()
    if vim.env.NVIM_SKIP_PLUGINS == "1" then
        return
    end

    local lazy_path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not (vim.uv or vim.loop).fs_stat(lazy_path) then
        local clone_output = vim.fn.system({
            "git",
            "clone",
            "--filter=blob:none",
            "--branch=stable",
            "https://github.com/folke/lazy.nvim.git",
            lazy_path,
        })

        if vim.v.shell_error ~= 0 then
            vim.notify(
                "状态栏插件安装失败，将使用内置状态栏：\n" .. clone_output,
                vim.log.levels.WARN
            )
            return
        end
    end

    vim.opt.rtp:prepend(lazy_path)

    local theme = {
        normal = {
            a = { fg = palette.bg, bg = palette.blue, gui = "bold" },
            b = { fg = palette.green, bg = palette.surface },
            c = { fg = palette.fg, bg = palette.surface },
        },
        insert = {
            a = { fg = palette.bg, bg = palette.green, gui = "bold" },
        },
        visual = {
            a = { fg = palette.bg, bg = palette.purple, gui = "bold" },
        },
        replace = {
            a = { fg = palette.bg, bg = palette.red, gui = "bold" },
        },
        command = {
            a = { fg = palette.bg, bg = palette.yellow, gui = "bold" },
        },
        inactive = {
            a = { fg = palette.muted, bg = palette.surface },
            b = { fg = palette.muted, bg = palette.surface },
            c = { fg = palette.muted, bg = palette.surface },
        },
    }

    require("lazy").setup({
        {
            "nvim-lualine/lualine.nvim",
            lazy = false,
            opts = {
                options = {
                    theme = theme,
                    globalstatus = true,
                    icons_enabled = true,
                    component_separators = { left = "·", right = "·" },
                    section_separators = { left = "", right = "" },
                    disabled_filetypes = {
                        statusline = { "lazy" },
                    },
                },
                sections = {
                    lualine_a = { "mode" },
                    lualine_b = {
                        { "branch", icon = "" },
                    },
                    lualine_c = {
                        {
                            "filename",
                            path = 1,
                            symbols = {
                                modified = " ●",
                                readonly = " ",
                                unnamed = "[No Name]",
                                newfile = "[New]",
                            },
                        },
                    },
                    lualine_x = {
                        {
                            "encoding",
                            fmt = string.upper,
                        },
                        "filetype",
                    },
                    lualine_y = { "progress" },
                    lualine_z = { "location" },
                },
                inactive_sections = {
                    lualine_a = {},
                    lualine_b = {},
                    lualine_c = { "filename" },
                    lualine_x = { "location" },
                    lualine_y = {},
                    lualine_z = {},
                },
                extensions = { "lazy" },
            },
        },
        {
            "previm/previm",
            ft = { "markdown" },
            cmd = { "PrevimOpen", "PrevimRefresh", "PrevimWipeCache" },
            dependencies = {
                "tyru/open-browser.vim",
            },
            init = function()
                vim.g.previm_enable_realtime = 1
                vim.g.previm_open_cmd = "xdg-open"
            end,
        },
        {
            "ibhagwan/fzf-lua",
            cmd = "FzfLua",
            keys = {
                {
                    "<leader>ff",
                    function()
                        require("fzf-lua").files()
                    end,
                    desc = "Find files",
                },
                {
                    "<leader>fg",
                    function()
                        require("fzf-lua").live_grep()
                    end,
                    desc = "Search project text",
                },
                {
                    "<leader>fb",
                    function()
                        require("fzf-lua").buffers()
                    end,
                    desc = "Find buffers",
                },
            },
            opts = {
                file_icons = false,
                winopts = {
                    border = "rounded",
                    preview = { border = "rounded" },
                },
            },
        },
        {
            "lewis6991/gitsigns.nvim",
            event = { "BufReadPre", "BufNewFile" },
            opts = {
                current_line_blame = false,
                on_attach = function(bufnr)
                    local gitsigns = require("gitsigns")
                    local map = function(lhs, rhs, desc)
                        vim.keymap.set("n", lhs, rhs, {
                            buffer = bufnr,
                            desc = desc,
                        })
                    end

                    map("]h", function()
                        gitsigns.nav_hunk("next")
                    end, "Next Git hunk")
                    map("[h", function()
                        gitsigns.nav_hunk("prev")
                    end, "Previous Git hunk")
                    map("<leader>gp", gitsigns.preview_hunk, "Preview Git hunk")
                    map("<leader>gb", function()
                        gitsigns.blame_line({ full = true })
                    end, "Show Git blame")
                end,
            },
        },
        {
            "neovim/nvim-lspconfig",
            version = "v1.8.0",
            ft = { "c", "cpp" },
            config = function()
                if vim.fn.executable("clangd") == 1 then
                    require("lspconfig").clangd.setup({})
                end
            end,
        },
    }, {
        lockfile = config_dir .. "/lazy-lock.json",
        checker = { enabled = false },
        change_detection = { notify = false },
        rocks = { enabled = false },
        ui = { border = "rounded" },
    })
end

setup_plugins()
