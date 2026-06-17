return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        opts = {
            flavour = "mocha",
            transparent_background = true,
            term_colors = true,
            styles = {
                comments = { "italic" },
                keywords = { "italic" },
                functions = {},
                strings = {},
                variables = {},
                numbers = {},
                booleans = {},
                properties = {},
                types = {},
                operators = {},
            },
        },
    },
    {
        "Gentleman-Programming/gentleman-kanagawa-blur",
        name = "gentleman-kanagawa-blur",
        priority = 1000,
    },
    {
        "Alan-TheGentleman/oldworld.nvim",
        lazy = false,
        priority = 1000,
        opts = {},
    },
    {
        "rebelot/kanagawa.nvim",
        priority = 1000,
        lazy = true,
        config = function()
            require("kanagawa").setup({
                compile = false,
                undercurl = true,
                commentStyle = { italic = true },
                functionStyle = {},
                keywordStyle = { italic = true },
                statementStyle = { bold = true },
                typeStyle = {},
                transparent = true,
                dimInactive = false,
                terminalColors = true,
                colors = {
                    palette = {},
                    theme = {
                        wave = {},
                        lotus = {},
                        dragon = {},
                        all = {
                            ui = {
                                bg_gutter = "none",
                                bg_sidebar = "none",
                                bg_float = "none",
                            },
                        },
                    },
                },
                overrides = function(_colors)
                    return {
                        LineNr = { bg = "none" },
                        NormalFloat = { bg = "none" },
                        FloatBorder = { bg = "none" },
                        FloatTitle = { bg = "none" },
                        TelescopeNormal = { bg = "none" },
                        TelescopeBorder = { bg = "none" },
                        LspInfoBorder = { bg = "none" },
                    }
                end,
                theme = "wave",
                background = { dark = "wave", light = "lotus" },
            })
        end,
    },
    {
        "olimorris/onedarkpro.nvim",
        priority = 1000,
        config = function()
            require("onedarkpro").setup({
                options = {
                    transparency = true,
                },
                styles = {
                    comments = "italic",
                    keywords = "italic",
                    functions = "NONE",
                    strings = "NONE",
                    variables = "NONE",
                    types = "italic",
                    parameters = "italic",
                    constants = "NONE",
                    operators = "NONE",
                },
                highlights = {
                    FloatBorder = { fg = "NONE", bg = "NONE" },
                    NormalFloat = { bg = "NONE" },
                },
            })
        end,
    },
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "onedark", -- ← activo
        },
    },
}
