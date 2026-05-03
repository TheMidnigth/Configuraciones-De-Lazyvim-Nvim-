return {
    {
        "nvim-tree/nvim-tree.lua",
        cmd = { "NvimTreeToggle", "NvimTreeFocus" },
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        keys = {
            { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Toggle NvimTree" },
            { "<leader>o", "<cmd>NvimTreeFocus<CR>", desc = "Focus NvimTree" },
        },
        opts = {
            hijack_netrw = true,
            sync_root_with_cwd = true,
            respect_buf_cwd = true,
            on_attach = function(bufnr)
                local api = require("nvim-tree.api")

                -- Cargar todos los keymaps por defecto
                api.config.mappings.default_on_attach(bufnr)

                -- Deshabilitar <C-t> por defecto de nvim-tree
                vim.keymap.del("n", "<C-t>", { buffer = bufnr })

                -- Asignar nuestro menu
                vim.keymap.set("n", "<C-t>", function()
                    local options = require("config.nvimtree-menu")
                    require("menu").open(options)
                end, { buffer = bufnr, desc = "Open NvimTree Menu" })
            end,
            view = {
                width = 35,
                side = "left",
                preserve_window_proportions = true,
                relativenumber = false,
                number = false,
                signcolumn = "no",
            },
            update_focused_file = {
                enable = true,
                update_root = true,
            },
            renderer = {
                root_folder_label = false,
                highlight_git = false,
                indent_width = 2,
                icons = {
                    git_placement = "before",
                    padding = " ",
                    show = {
                        file = true,
                        folder = true,
                        folder_arrow = true,
                        git = false,
                        modified = false,
                    },
                    glyphs = {
                        default = "",
                        folder = {
                            default = "",
                            open = "",
                            empty = "",
                            empty_open = "",
                            arrow_closed = "",
                            arrow_open = "",
                        },
                    },
                },
                indent_markers = {
                    enable = true,
                    icons = {
                        corner = " ",
                        edge = " ",
                        item = " ",
                        none = "  ",
                    },
                },
            },
            git = {
                enable = false,
            },
            actions = {
                open_file = {
                    quit_on_open = false,
                },
            },
        },
        config = function(_, opts)
            vim.g.loaded_netrw = 1
            vim.g.loaded_netrwPlugin = 1
            require("nvim-tree").setup(opts)
        end,
    },
}
