return {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    cond = vim.g.neovide == nil, -- no aplica si usas Neovide (ya lo tiene nativo)
    opts = {
        hide_target_hack = true,
        cursor_color = "none", -- usa el color de tu cursor actual
    },
}
