return {
    {
        "folke/snacks.nvim",
        opts = {
            indent = {
                enabled = false,
            },
        },
    },
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        event = "LazyFile",
        opts = {},
        config = function()
            local hooks = require("ibl.hooks")
            local highlight = {
                "RainbowIndent1",
                "RainbowIndent2",
                "RainbowIndent3",
                "RainbowIndent4",
            }
            local rainbow_colors = {
                { 255, 255, 64, 0.05 },
                { 127, 255, 127, 0.05 },
                { 255, 127, 255, 0.05 },
                { 79, 236, 236, 0.05 },
            }
            local function hex_to_rgb(hex)
                hex = hex:gsub("#", "")
                return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
            end
            local function mix_with_bg(r, g, b, a)
                local bg_color = vim.api.nvim_get_hl(0, { name = "Normal" }).bg
                local bg_hex = bg_color and string.format("%06x", bg_color) or "1e1e2e"
                local br, bg, bb = hex_to_rgb("#" .. bg_hex)
                return string.format(
                    "#%02x%02x%02x",
                    math.floor(r * a + br * (1 - a)),
                    math.floor(g * a + bg * (1 - a)),
                    math.floor(b * a + bb * (1 - a))
                )
            end
            local function setup_highlights()
                for i, c in ipairs(rainbow_colors) do
                    vim.api.nvim_set_hl(0, "RainbowIndent" .. i, {
                        bg = mix_with_bg(c[1], c[2], c[3], c[4]),
                    })
                end
                vim.api.nvim_set_hl(0, "IblScope", { fg = "NONE", bg = "NONE", nocombine = true })
            end
            hooks.register(hooks.type.HIGHLIGHT_SETUP, setup_highlights)
            require("ibl").setup({
                indent = {
                    char = " ",
                    highlight = highlight,
                },
                whitespace = {
                    highlight = highlight,
                    remove_blankline_trail = false,
                },
                scope = {
                    enabled = false,
                    show_start = false,
                    show_end = false,
                },
                exclude = {
                    filetypes = {
                        "Trouble",
                        "alpha",
                        "dashboard",
                        "help",
                        "lazy",
                        "mason",
                        "neo-tree",
                        "notify",
                        "snacks_dashboard",
                        "snacks_notif",
                        "snacks_terminal",
                        "snacks_win",
                        "toggleterm",
                        "trouble",
                    },
                },
            })
            vim.api.nvim_create_autocmd("ColorScheme", {
                callback = function()
                    setup_highlights()
                    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                        if vim.api.nvim_buf_is_loaded(buf) then
                            require("ibl").setup_buffer(buf, {})
                        end
                    end
                end,
            })
        end,
    },
    {
        "nvim-mini/mini.indentscope",
        enabled = false,
    },
}
