return {
    {
        "HiPhish/rainbow-delimiters.nvim",
        event = "BufReadPost",
        config = function()
            local rainbow = require("rainbow-delimiters")

            -- Definir los colores exactos de Rainbow Brackets VSCode
            vim.api.nvim_set_hl(0, "RainbowDelimiterTeal",   { fg = "#008080" })
            vim.api.nvim_set_hl(0, "RainbowDelimiterYellow", { fg = "#ffd700" })
            vim.api.nvim_set_hl(0, "RainbowDelimiterTomato", { fg = "#ff6347" })

            vim.api.nvim_create_autocmd("ColorScheme", {
                callback = function()
                    vim.api.nvim_set_hl(0, "RainbowDelimiterTeal",   { fg = "#008080" })
                    vim.api.nvim_set_hl(0, "RainbowDelimiterYellow", { fg = "#ffd700" })
                    vim.api.nvim_set_hl(0, "RainbowDelimiterTomato", { fg = "#ff6347" })
                end,
            })

            require("rainbow-delimiters.setup").setup({
                strategy = {
                    [""] = rainbow.strategy["global"],
                    vim = rainbow.strategy["local"],
                },
                query = {
                    [""] = "rainbow-delimiters",
                    lua = "rainbow-blocks",
                },
                priority = {
                    [""] = 110,
                    lua = 210,
                },
                highlight = {
                    "RainbowDelimiterTeal",
                    "RainbowDelimiterYellow",
                    "RainbowDelimiterTomato",
                },
            })
        end,
    },
}
