return {
    -- ── Flutter Tools ─────────────────────────────────────────────────────────
    {
        "akinsho/flutter-tools.nvim",
        lazy = false,
        dependencies = {
            "nvim-lua/plenary.nvim",
            "stevearc/dressing.nvim",
        },
        config = function()
            require("flutter-tools").setup({
                ui = {
                    border = "rounded",
                    notification_style = "nvim-notify",
                },
                decorations = {
                    statusline = {
                        app_version = true,
                        device = true,
                        project_config = true,
                    },
                },
                debugger = {
                    enabled = true,
                    run_via_dap = true,
                    exception_breakpoints = {},
                    register_configurations = function(_)
                        require("dap").configurations.dart = {}
                        require("dap").ext = require("dap").ext or {}
                        require("dap.ext.vscode").load_launchjs(nil, { dart = { "dart", "flutter" } })
                    end,
                },
                flutter_path = vim.fn.expand("~/flutter/bin/flutter"),
                flutter_lookup_cmd = nil,
                fvm = false,
                widget_guides = {
                    enabled = true,
                },
                closing_tags = {
                    highlight = "Comment",
                    prefix = "// ",
                    priority = 10,
                    enabled = true,
                },
                dev_log = {
                    enabled = true,
                    filter = nil,
                    notify_errors = true,
                    open_cmd = "tabedit",
                },
                dev_tools = {
                    autostart = false,
                    auto_open_browser = false,
                },
                outline = {
                    open_cmd = "30vnew",
                    auto_open = false,
                },
                lsp = {
                    color = {
                        enabled = true,
                        background = false,
                        background_color = { r = 19, g = 17, b = 24 },
                        foreground = false,
                        virtual_text = true,
                        virtual_text_str = "■",
                    },
                    on_attach = function(client, bufnr)
                        -- Keymaps LSP
                        local map = function(keys, func, desc)
                            vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
                        end
                        map("gd", vim.lsp.buf.definition, "Go to Definition")
                        map("gr", vim.lsp.buf.references, "Go to References")
                        map("gi", vim.lsp.buf.implementation, "Go to Implementation")
                        map("K", vim.lsp.buf.hover, "Hover Documentation")
                        map("<leader>rn", vim.lsp.buf.rename, "Rename")
                        map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
                        map("<leader>ds", vim.lsp.buf.document_symbol, "Document Symbols")
                    end,
                    capabilities = require("blink.cmp").get_lsp_capabilities(),
                    settings = {
                        showTodos = true,
                        completeFunctionCalls = true,
                        enableSnippets = true,
                        updateImportsOnRename = true,
                        renameFilesWithClasses = "prompt",
                        analysisExcludedFolders = {
                            vim.fn.expand("$HOME/flutter/"),
                        },
                        inlayHints = {
                            variableTypes = false,
                            parameterNames = false,
                            parameterTypes = false,
                            functionReturnTypes = false,
                        },
                    },
                },
            })
        end,
    },

    -- ── Telescope extension para Flutter ──────────────────────────────────────
    {
        "nvim-telescope/telescope.nvim",
        optional = true,
        opts = function()
            require("telescope").load_extension("flutter")
        end,
    },
    -- ── Comando FlutterCreate ─────────────────────────────────────────────────────
    {
        "nvim-lua/plenary.nvim",
        lazy = true,
        init = function()
            vim.api.nvim_create_user_command("FlutterCreate", function(opts)
                local name = opts.args
                if name == "" then
                    name = vim.fn.input("Nombre del proyecto Flutter: ")
                end
                if name == "" then
                    vim.notify("Nombre vacío, cancelado", vim.log.levels.WARN)
                    return
                end

                local cwd = vim.fn.getcwd()
                local project_path = cwd .. "/" .. name

                vim.notify("Creando proyecto Flutter: " .. name .. "...")

                vim.fn.jobstart({ "flutter", "create", name }, {
                    cwd = cwd,
                    on_exit = function(_, code)
                        if code == 0 then
                            vim.notify("✓ Proyecto Flutter '" .. name .. "' creado correctamente")
                            -- Abre el proyecto en nvim-tree y va al main.dart
                            vim.schedule(function()
                                vim.cmd("cd " .. project_path)
                                vim.cmd("NvimTreeOpen")
                                vim.cmd("edit " .. project_path .. "/lib/main.dart")
                            end)
                        else
                            vim.notify("✗ Error al crear el proyecto", vim.log.levels.ERROR)
                        end
                    end,
                })
            end, { nargs = "?" })
        end,
    },
}
