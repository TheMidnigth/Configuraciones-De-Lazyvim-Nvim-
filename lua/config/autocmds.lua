-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--

vim.api.nvim_set_hl(0, "ExBlue", { fg = "#61afef" })
vim.api.nvim_set_hl(0, "ExRed", { fg = "#e06c75" })

vim.api.nvim_set_hl(0, "NvimTreeFolderIcon", { fg = "#77bbf2" })
vim.api.nvim_set_hl(0, "NvimTreeFolderArrowOpen", { fg = "#77bbf2", bold = true })
vim.api.nvim_set_hl(0, "NvimTreeFolderArrowClosed", { fg = "#3c4145" })
vim.api.nvim_set_hl(0, "NvimTreeFolderName", { fg = "#77bbf2" })
vim.api.nvim_set_hl(0, "NvimTreeOpenedFolderName", { fg = "#77bbf2", bold = true })
vim.api.nvim_set_hl(0, "NvimTreeEmptyFolderName", { fg = "#77bbf2" })
vim.api.nvim_set_hl(0, "NvimTreeCursorLine", { bg = "#1e2832" })

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client then
            client.server_capabilities.semanticTokensProvider = nil
            vim.lsp.semantic_tokens.stop(args.buf, args.data.client_id)
        end
        vim.schedule(function()
            -- Types
            vim.api.nvim_set_hl(0, "@type.builtin",              { italic = true,  fg = vim.api.nvim_get_hl(0, { name = "@type.builtin",          link = false }).fg })
            vim.api.nvim_set_hl(0, "@type.builtin.java",         { italic = true,  fg = vim.api.nvim_get_hl(0, { name = "@type.builtin.java",      link = false }).fg })
            vim.api.nvim_set_hl(0, "@type.java",                 { italic = false, fg = vim.api.nvim_get_hl(0, { name = "Type",                    link = false }).fg })
            -- Variables
            vim.api.nvim_set_hl(0, "@variable.java",             { italic = false, fg = vim.api.nvim_get_hl(0, { name = "@variable",               link = false }).fg })
            vim.api.nvim_set_hl(0, "@variable",                  { italic = false, fg = vim.api.nvim_get_hl(0, { name = "@variable",               link = false }).fg })
            vim.api.nvim_set_hl(0, "@variable.builtin.java",     { italic = true,  fg = vim.api.nvim_get_hl(0, { name = "@variable.builtin",        link = false }).fg })
            vim.api.nvim_set_hl(0, "@variable.builtin",          { italic = true,  fg = vim.api.nvim_get_hl(0, { name = "@variable.builtin",        link = false }).fg })
            -- Keywords de control
            vim.api.nvim_set_hl(0, "@keyword.conditional.java",  { italic = true,  fg = vim.api.nvim_get_hl(0, { name = "@keyword.conditional",     link = false }).fg })
            vim.api.nvim_set_hl(0, "@keyword.conditional",       { italic = true,  fg = vim.api.nvim_get_hl(0, { name = "@keyword.conditional",     link = false }).fg })
            vim.api.nvim_set_hl(0, "@keyword.loop.java",         { italic = true,  fg = vim.api.nvim_get_hl(0, { name = "@keyword.loop",            link = false }).fg })
            vim.api.nvim_set_hl(0, "@keyword.loop",              { italic = true,  fg = vim.api.nvim_get_hl(0, { name = "@keyword.loop",            link = false }).fg })
            vim.api.nvim_set_hl(0, "@keyword.return.java",       { italic = true,  fg = vim.api.nvim_get_hl(0, { name = "@keyword.return",          link = false }).fg })
            vim.api.nvim_set_hl(0, "@keyword.return",            { italic = true,  fg = vim.api.nvim_get_hl(0, { name = "@keyword.return",          link = false }).fg })
            vim.api.nvim_set_hl(0, "@keyword.exception.java",    { italic = true,  fg = vim.api.nvim_get_hl(0, { name = "@keyword.exception",       link = false }).fg })
            vim.api.nvim_set_hl(0, "@keyword.exception",         { italic = true,  fg = vim.api.nvim_get_hl(0, { name = "@keyword.exception",       link = false }).fg })
        end)
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "java",
    callback = function()
        vim.defer_fn(function()
            -- Types
            vim.api.nvim_set_hl(0, "@type.builtin",              { italic = true,  fg = vim.api.nvim_get_hl(0, { name = "@type.builtin",          link = false }).fg })
            vim.api.nvim_set_hl(0, "@type.builtin.java",         { italic = true,  fg = vim.api.nvim_get_hl(0, { name = "@type.builtin.java",      link = false }).fg })
            vim.api.nvim_set_hl(0, "@type.java",                 { italic = false, fg = vim.api.nvim_get_hl(0, { name = "Type",                    link = false }).fg })
            -- Variables
            vim.api.nvim_set_hl(0, "@variable.java",             { italic = false, fg = vim.api.nvim_get_hl(0, { name = "@variable",               link = false }).fg })
            vim.api.nvim_set_hl(0, "@variable",                  { italic = false, fg = vim.api.nvim_get_hl(0, { name = "@variable",               link = false }).fg })
            vim.api.nvim_set_hl(0, "@variable.builtin.java",     { italic = true,  fg = vim.api.nvim_get_hl(0, { name = "@variable.builtin",        link = false }).fg })
            vim.api.nvim_set_hl(0, "@variable.builtin",          { italic = true,  fg = vim.api.nvim_get_hl(0, { name = "@variable.builtin",        link = false }).fg })
            -- Keywords de control
            vim.api.nvim_set_hl(0, "@keyword.conditional.java",  { italic = true,  fg = vim.api.nvim_get_hl(0, { name = "@keyword.conditional",     link = false }).fg })
            vim.api.nvim_set_hl(0, "@keyword.conditional",       { italic = true,  fg = vim.api.nvim_get_hl(0, { name = "@keyword.conditional",     link = false }).fg })
            vim.api.nvim_set_hl(0, "@keyword.loop.java",         { italic = true,  fg = vim.api.nvim_get_hl(0, { name = "@keyword.loop",            link = false }).fg })
            vim.api.nvim_set_hl(0, "@keyword.loop",              { italic = true,  fg = vim.api.nvim_get_hl(0, { name = "@keyword.loop",            link = false }).fg })
            vim.api.nvim_set_hl(0, "@keyword.return.java",       { italic = true,  fg = vim.api.nvim_get_hl(0, { name = "@keyword.return",          link = false }).fg })
            vim.api.nvim_set_hl(0, "@keyword.return",            { italic = true,  fg = vim.api.nvim_get_hl(0, { name = "@keyword.return",          link = false }).fg })
            vim.api.nvim_set_hl(0, "@keyword.exception.java",    { italic = true,  fg = vim.api.nvim_get_hl(0, { name = "@keyword.exception",       link = false }).fg })
            vim.api.nvim_set_hl(0, "@keyword.exception",         { italic = true,  fg = vim.api.nvim_get_hl(0, { name = "@keyword.exception",       link = false }).fg })
        end, 100)
    end,
})

-- Dart y Flutter → 2 espacios
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "dart" },
    callback = function()
        vim.opt_local.shiftwidth = 2
        vim.opt_local.tabstop = 2
    end,
})

