return {
    "neovim/nvim-lspconfig",
    opts = {
        diagnostics = {
            underline = true,
            virtual_text = false,
            update_in_insert = false,
            severity_sort = true,
            signs = {
                text = {
                    [vim.diagnostic.severity.ERROR] = LazyVim.config.icons.diagnostics.Error,
                    [vim.diagnostic.severity.WARN]  = LazyVim.config.icons.diagnostics.Warn,
                    [vim.diagnostic.severity.INFO]  = LazyVim.config.icons.diagnostics.Info,
                    [vim.diagnostic.severity.HINT]  = LazyVim.config.icons.diagnostics.Hint,
                },
            },
            float = {
                border = "rounded",
                source = "if_many",
            },
        },
    },
}
