return {
    {
        "saghen/blink.cmp",
        version = "1.*",
        dependencies = { "rafamadriz/friendly-snippets" },
        opts = {
            keymap = {
                preset = "default",
                ["<Tab>"] = { "accept", "fallback" },
                ["<CR>"] = { "accept", "fallback" },
                ["<C-Space>"] = { "show", "fallback" },
                ["<C-e>"] = { "hide", "fallback" },
                ["<Up>"] = { "select_prev", "fallback" },
                ["<Down>"] = { "select_next", "fallback" },
            },
            appearance = {
                nerd_font_variant = "mono",
                kind_icons = {
                    Text = "󰉿",
                    Method = "󰆧",
                    Function = "󰆧",
                    Constructor = "",
                    Field = "󰜢",
                    Variable = "󰀫",
                    Class = "󰆦",
                    Interface = "󰆩",
                    Module = "",
                    Property = "󰜢",
                    Unit = "󰑭",
                    Value = "󰎠",
                    Enum = "󰾍",
                    Keyword = "󰌋",
                    Snippet = "",
                    Color = "󰏘",
                    File = "󰈙",
                    Reference = "󰈇",
                    Folder = "",
                    EnumMember = "",
                    Constant = "󰏿",
                    Struct = "󰙅",
                    Event = "",
                    Operator = "󰆕",
                    TypeParameter = "",
                },
            },
            sources = {
                default = { "lsp", "path", "snippets", "buffer" },
                providers = {
                    lsp = {
                        name = "LSP",
                        module = "blink.cmp.sources.lsp",
                        transform_items = function(_, items)
                            return vim.tbl_filter(function(item)
                                return not item.label:match("~$")
                            end, items)
                        end,
                    },
                },
            },
            snippets = {
                preset = "default",
            },
            completion = {
                documentation = {
                    auto_show = true,
                    auto_show_delay_ms = 200,
                    window = {
                        border = "single",
                        winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
                    },
                },
                trigger = {
                    show_on_insert_on_trigger_character = true,
                },
                list = {
                    selection = {
                        auto_insert = false,
                    },
                },
                accept = {
                    auto_brackets = {
                        enabled = true,
                    },
                },
                menu = {
                    border = "single",
                    winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
                    draw = {
                        gap = 1,
                        columns = {
                            { "label", "label_description", gap = 1 },
                            { "kind_icon", "kind", gap = 1 },
                        },
                        components = {
                            kind_icon = {
                                ellipsis = false,
                                text = function(ctx)
                                    return " " .. ctx.kind_icon .. " "
                                end,
                                highlight = function(ctx)
                                    return "BlinkCmpKind" .. ctx.kind
                                end,
                            },
                            kind = {
                                ellipsis = false,
                                width = { fill = true },
                                text = function(ctx)
                                    return ctx.kind
                                end,
                                highlight = function(ctx)
                                    return "BlinkCmpKind" .. ctx.kind
                                end,
                            },
                            label = {
                                width = { fill = true, max = 30 },
                            },
                            label_description = {
                                width = { max = 20 },
                                text = function(ctx)
                                    return ctx.label_description
                                end,
                                highlight = "BlinkCmpLabelDescription",
                            },
                        },
                    },
                },
            },
            signature = { enabled = false },
            fuzzy = { implementation = "prefer_rust_with_warning" },
        },
        opts_extend = { "sources.default" },
        config = function(_, opts)
            require("blink.cmp").setup(opts)

            local function set_hl()
                vim.api.nvim_set_hl(0, "BlinkCmpKindSnippet", { fg = "#e06c75" }) -- rojo
                vim.api.nvim_set_hl(0, "BlinkCmpKindFunction", { fg = "#61afef" }) -- azul
                vim.api.nvim_set_hl(0, "BlinkCmpKindMethod", { fg = "#61afef" }) -- azul
                vim.api.nvim_set_hl(0, "BlinkCmpKindConstructor", { fg = "#61afef" }) -- azul
                vim.api.nvim_set_hl(0, "BlinkCmpKindField", { fg = "#e06c75" }) -- rojo/salmon
                vim.api.nvim_set_hl(0, "BlinkCmpKindKeyword", { fg = "#c678dd" }) -- morado
                vim.api.nvim_set_hl(0, "BlinkCmpKindText", { fg = "#98c379" }) -- verde
                vim.api.nvim_set_hl(0, "BlinkCmpKindVariable", { fg = "#e06c75" }) -- rojo/salmon
                vim.api.nvim_set_hl(0, "BlinkCmpKindClass", { fg = "#e5c07b" }) -- amarillo
                vim.api.nvim_set_hl(0, "BlinkCmpKindInterface", { fg = "#e5c07b" }) -- amarillo
                vim.api.nvim_set_hl(0, "BlinkCmpKindModule", { fg = "#e5c07b" }) -- amarillo
                vim.api.nvim_set_hl(0, "BlinkCmpKindProperty", { fg = "#e06c75" }) -- rojo/salmon
                vim.api.nvim_set_hl(0, "BlinkCmpKindUnit", { fg = "#e5c07b" }) -- amarillo
                vim.api.nvim_set_hl(0, "BlinkCmpKindValue", { fg = "#98c379" }) -- verde
                vim.api.nvim_set_hl(0, "BlinkCmpKindEnum", { fg = "#e5c07b" }) -- amarillo
                vim.api.nvim_set_hl(0, "BlinkCmpKindColor", { fg = "#e06c75" }) -- rojo
                vim.api.nvim_set_hl(0, "BlinkCmpKindFile", { fg = "#98c379" }) -- verde
                vim.api.nvim_set_hl(0, "BlinkCmpKindReference", { fg = "#e06c75" }) -- rojo
                vim.api.nvim_set_hl(0, "BlinkCmpKindFolder", { fg = "#e5c07b" }) -- amarillo
                vim.api.nvim_set_hl(0, "BlinkCmpKindEnumMember", { fg = "#98c379" }) -- verde
                vim.api.nvim_set_hl(0, "BlinkCmpKindConstant", { fg = "#e5c07b" }) -- amarillo
                vim.api.nvim_set_hl(0, "BlinkCmpKindStruct", { fg = "#e5c07b" }) -- amarillo
                vim.api.nvim_set_hl(0, "BlinkCmpKindEvent", { fg = "#e5c07b" }) -- amarillo
                vim.api.nvim_set_hl(0, "BlinkCmpKindOperator", { fg = "#98c379" }) -- verde
                vim.api.nvim_set_hl(0, "BlinkCmpKindTypeParameter", { fg = "#e5c07b" }) -- amarillo
                vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#3d3f41", bg = "NONE" })
                vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
                vim.api.nvim_set_hl(0, "BlinkCmpMenu", { bg = "NONE" })
                vim.api.nvim_set_hl(0, "BlinkCmpDoc", { bg = "NONE" })
            end

            set_hl()

            vim.api.nvim_create_autocmd("ColorScheme", {
                pattern = "*",
                callback = set_hl,
            })
        end,
    },
}
