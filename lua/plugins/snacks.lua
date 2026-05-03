return {
    {
        "folke/snacks.nvim",
        opts = {
            indent = { enabled = false },
            explorer = { enabled = false },
            picker = {
                enabled = true,
                sources = {
                    explorer = {
                        enabled = false,
                    },
                },
            },
        },
        keys = {
            { "<leader>e", false },  -- 👈 deshabilita el keymap de snacks
            { "<leader>E", false },  -- 👈 deshabilita el keymap de snacks
        },
    },
}
