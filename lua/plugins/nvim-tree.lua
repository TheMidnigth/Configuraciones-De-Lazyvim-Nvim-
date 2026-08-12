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
            -- ── Filtros: ocultar basura de Windows/WSL y carpetas de build ──
            filters = {
                dotfiles = false,
                git_ignored = false,
                custom = {
                    "Identifier$", -- captura todo lo que termine en Identifier
                    "^target$",
                    "^build$",
                    "^%.settings$",
                    "^%.classpath$",
                    "^%.factorypath$",
                    "^%.project$",
                },
                exclude = {},
            },

            view = {
                width = 35,
                side = "left",
                preserve_window_proportions = true,
                relativenumber = false,
                number = false,
                signcolumn = "no",
                -- agrega esto:
                float = {
                    enable = false,
                },
                winhl = "WinSeparator:NvimTreeWinSeparator",
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

            -- ── Highlight groups estilo IntelliJ (persisten entre reinicios) ──
            local function setup_java_highlights()
                vim.api.nvim_set_hl(0, "JavaIconClass", { fg = "#4FC3F7" }) -- Azul
                vim.api.nvim_set_hl(0, "JavaIconInterface", { fg = "#C3E88D" }) -- Verde
                vim.api.nvim_set_hl(0, "JavaIconRecord", { fg = "#FDD835" }) -- Naranja
                vim.api.nvim_set_hl(0, "JavaIconEnum", { fg = "#F78C6C" }) -- Amarillo
                vim.api.nvim_set_hl(0, "JavaIconAnnotation", { fg = "#C792EA" }) -- Morado
                vim.api.nvim_set_hl(0, "JavaIconException", { fg = "#FFCB6B" }) -- Dorado
            end

            setup_java_highlights()
            vim.api.nvim_set_hl(0, "NvimTreeNormal", { bg = "#12171b" })
            vim.api.nvim_set_hl(0, "NvimTreeNormalNC", { bg = "#12171b" })
            vim.api.nvim_set_hl(0, "NvimTreeEndOfBuffer", { bg = "#12171b" })
            vim.api.nvim_create_autocmd("ColorScheme", {
                pattern = "*",
                callback = setup_java_highlights,
            })

            -- ── Setup base de mini.icons ───────────────────────────────
            local ok_mini, mini_icons = pcall(require, "mini.icons")
            if ok_mini then
                mini_icons.setup({
                    extension = {
                        java = { glyph = "󰆦", hl = "JavaIconClass" },
                    },
                })

                -- ── Override del getter para archivos .java ────────────
                local orig_get = mini_icons.get
                mini_icons.get = function(category, name, ...)
                    if category == "file" and type(name) == "string" and name:match("%.java$") then
                        local abs = nil

                        -- 1. Buscar en buffers abiertos
                        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                            local bufname = vim.api.nvim_buf_get_name(buf)
                            if bufname:match(vim.pesc(name) .. "$") then
                                abs = bufname
                                break
                            end
                        end

                        -- 2. Si no está en buffers, buscar en el proyecto
                        if not abs or abs == "" then
                            local found = vim.fn.findfile(name, vim.fn.getcwd() .. "/**")
                            if found and found ~= "" then
                                abs = vim.fn.fnamemodify(found, ":p")
                            end
                        end

                        -- 3. Aplicar icono según tipo (cache en disco)
                        if abs and abs ~= "" then
                            local ok_ji, java_icons = pcall(require, "config.java-icons")
                            if ok_ji then
                                local icon = java_icons.get_icon(abs)
                                return icon.glyph, icon.hl, false
                            end
                        end
                    end
                    return orig_get(category, name, ...)
                end
            end

            -- ── Escaneo de archivos Java ───────────────────────────────
            local function scan_java_files()
                local ok_ji, java_icons = pcall(require, "config.java-icons")
                if not ok_ji then
                    return
                end
                local files = vim.fn.glob(vim.fn.getcwd() .. "/**/*.java", false, true)
                for _, filepath in ipairs(files) do
                    java_icons.get_icon(filepath)
                end
                local ok_api, api = pcall(require, "nvim-tree.api")
                if ok_api then
                    pcall(api.tree.reload)
                end
            end

            -- Escanear al abrir nvim-tree
            vim.api.nvim_create_autocmd("BufEnter", {
                pattern = "NvimTree_*",
                callback = function()
                    vim.defer_fn(scan_java_files, 0)
                end,
            })

            -- Escanear al cambiar de directorio
            vim.api.nvim_create_autocmd("DirChanged", {
                callback = function()
                    vim.defer_fn(scan_java_files, 100)
                end,
            })

            require("nvim-tree").setup(opts)
        end,
    },
}
