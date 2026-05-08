-- =============================================================================
-- DAP (Debug Adapter Protocol) - Configuración Completa para LazyVim
-- Soporta: Java, Python, JS/TS, PHP, Go, Rust, C/C++, Bash, y más
-- =============================================================================

local function get_args(config)
    local args = type(config.args) == "function" and (config.args() or {}) or config.args or {}
    config = vim.deepcopy(config)
    config.args = function()
        local new_args = vim.fn.input("Run with args: ", table.concat(args, " "))
        return vim.split(vim.fn.expand(new_args), " ")
    end
    return config
end

return {

    -- ===========================================================================
    -- 1. CORE: nvim-dap
    -- ===========================================================================
    {
        "mfussenegger/nvim-dap",
        lazy = false,
        dependencies = {
            "rcarriga/nvim-dap-ui",
            "nvim-neotest/nvim-nio",
            "theHamsta/nvim-dap-virtual-text",
        },

        -- stylua: ignore
        keys = {
            { "<leader>db", function() require("dap").toggle_breakpoint() end,                                     desc = "Toggle Breakpoint" },
            { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end,  desc = "Breakpoint Condition" },
            { "<leader>dl", function() require("dap").set_breakpoint(nil, nil, vim.fn.input("Log message: ")) end, desc = "Logpoint" },
            { "<leader>dc", function() require("dap").continue() end,                                              desc = "Run / Continue" },
            { "<leader>da", function() require("dap").continue({ before = get_args }) end,                         desc = "Run with Args" },
            { "<leader>dC", function() require("dap").run_to_cursor() end,                                         desc = "Run to Cursor" },
            { "<leader>dg", function() require("dap").goto_() end,                                                 desc = "Go to Line (No Execute)" },
            { "<leader>di", function() require("dap").step_into() end,                                             desc = "Step Into" },
            { "<leader>do", function() require("dap").step_out() end,                                              desc = "Step Out" },
            { "<leader>dO", function() require("dap").step_over() end,                                             desc = "Step Over" },
            { "<leader>dp", function() require("dap").pause() end,                                                 desc = "Pause" },
            { "<leader>dr", function() require("dap").repl.toggle() end,                                           desc = "Toggle REPL" },
            { "<leader>ds", function() require("dap").session() end,                                               desc = "Session" },
            { "<leader>dt", function() require("dap").terminate() end,                                             desc = "Terminate" },
            { "<leader>dR", function() require("dap").restart() end,                                               desc = "Restart" },
            { "<leader>dw", function() require("dap.ui.widgets").hover() end,                                      desc = "Widgets / Hover" },
            { "<leader>dj", function() require("dap").down() end,                                                  desc = "Down (Frame)" },
            { "<leader>dk", function() require("dap").up() end,                                                    desc = "Up (Frame)" },
            { "<F5>",  function() require("dap").continue() end,          desc = "Debug: Continue" },
            { "<F9>",  function() require("dap").toggle_breakpoint() end, desc = "Debug: Toggle Breakpoint" },
            { "<F10>", function() require("dap").step_over() end,         desc = "Debug: Step Over" },
            { "<F11>", function() require("dap").step_into() end,         desc = "Debug: Step Into" },
            { "<F12>", function() require("dap").step_out() end,          desc = "Debug: Step Out" },
        },

        config = function()
            local dap = require("dap")

            -- Signos visuales en el gutter
            vim.fn.sign_define("DapBreakpoint", {
                text = "",
                texthl = "DapBreakpoint",
                linehl = "",
                numhl = "",
            })
            vim.fn.sign_define(
                "DapBreakpointCondition",
                { text = "󰓏", texthl = "DapBreakpointCondition", linehl = "", numhl = "" }
            )
            vim.fn.sign_define("DapLogPoint", {
                text = "󰻂",
                texthl = "DapLogPoint",
                linehl = "",
                numhl = "",
            })
            vim.fn.sign_define(
                "DapStopped",
                { text = "", texthl = "DapStopped", linehl = "DapStoppedLine", numhl = "" }
            )
            vim.fn.sign_define(
                "DapBreakpointRejected",
                { text = "", texthl = "DapBreakpointRejected", linehl = "", numhl = "" }
            )

            vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#e06c75" })
            vim.api.nvim_set_hl(0, "DapBreakpointCondition", { fg = "#e5c07b" })
            vim.api.nvim_set_hl(0, "DapLogPoint", { fg = "#61afef" })
            vim.api.nvim_set_hl(0, "DapStopped", { fg = "#98c379" })
            vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#2e3a2e" })
            vim.api.nvim_set_hl(0, "DapBreakpointRejected", { fg = "#abb2bf" })

            -- PHP (via XDebug)
            dap.adapters.php = {
                type = "executable",
                command = vim.fn.stdpath("data") .. "/mason/bin/php-debug-adapter",
            }
            dap.configurations.php = {
                {
                    type = "php",
                    request = "launch",
                    name = "PHP: Listen for XDebug",
                    port = 9003,
                    pathMappings = {},
                },
            }

            -- Bash / Shell
            dap.adapters.bashdb = {
                type = "executable",
                command = vim.fn.stdpath("data") .. "/mason/packages/bash-debug-adapter/bash-debug-adapter",
                name = "bashdb",
            }
            dap.configurations.sh = {
                {
                    type = "bashdb",
                    request = "launch",
                    name = "Bash: Launch file",
                    showDebugOutput = true,
                    pathBashdb = vim.fn.stdpath("data")
                        .. "/mason/packages/bash-debug-adapter/extension/bashdb_dir/bashdb",
                    pathBashdbLib = vim.fn.stdpath("data") .. "/mason/packages/bash-debug-adapter/extension/bashdb_dir",
                    trace = true,
                    file = "${file}",
                    program = "${file}",
                    cwd = "${workspaceFolder}",
                    pathCat = "cat",
                    pathBash = "/bin/bash",
                    pathMkfifo = "mkfifo",
                    pathPkill = "pkill",
                    args = {},
                    env = {},
                    terminalKind = "integrated",
                },
            }
        end,
    },

    -- ===========================================================================
    -- 2. UI: nvim-dap-ui
    -- ===========================================================================
    {
        "rcarriga/nvim-dap-ui",
        lazy = false,
        dependencies = { "nvim-neotest/nvim-nio" },

        -- stylua: ignore
        keys = {
            { "<leader>du", function() require("dapui").toggle({}) end, desc = "Toggle DAP UI" },
            { "<leader>de", function() require("dapui").eval() end,      desc = "Eval Expression", mode = { "n", "x" } },
        },

        opts = {
            icons = { expanded = "󰁊", collapsed = "󰁙", current_frame = "󰁙" },
            controls = {
                enabled = true,
                element = "repl",
                icons = {
                    pause = "",
                    play = "",
                    step_into = "󰁏",
                    step_over = "󰙡",
                    step_out = "󰙣",
                    step_back = "󰯯",
                    run_last = "󰁙󰁙",
                    terminate = "󰙦",
                    disconnect = "󰁢",
                },
            },
            layouts = {
                {
                    elements = {
                        { id = "scopes", size = 0.30 },
                        { id = "breakpoints", size = 0.20 },
                        { id = "stacks", size = 0.30 },
                        { id = "watches", size = 0.20 },
                    },
                    size = 45,
                    position = "left",
                },
                {
                    elements = {
                        { id = "repl", size = 0.50 },
                        { id = "console", size = 0.50 },
                    },
                    size = 10,
                    position = "bottom",
                },
            },
            floating = {
                max_height = 0.9,
                max_width = 0.5,
                border = "rounded",
                mappings = { close = { "q", "<Esc>" } },
            },
        },

        config = function(_, opts)
            local dap = require("dap")
            local dapui = require("dapui")
            dapui.setup(opts)

            dap.listeners.after.event_initialized["dapui_config"] = function()
                dapui.open({})
            end
            dap.listeners.before.event_terminated["dapui_config"] = function()
                dapui.close({})
            end
            dap.listeners.before.event_exited["dapui_config"] = function()
                dapui.close({})
            end
        end,
    },

    -- ===========================================================================
    -- 3. VIRTUAL TEXT: nvim-dap-virtual-text
    -- Tiene su propio config = function() para garantizar que setup() corre
    -- correctamente y se engancha a los eventos DAP desde el inicio.
    -- ===========================================================================
    {
        "theHamsta/nvim-dap-virtual-text",
        lazy = false,
        config = function()
            require("nvim-dap-virtual-text").setup({
                enabled = true,
                enabled_commands = true,
                highlight_changed_variables = true,
                highlight_new_as_changed = true, -- resalta vars que cambiaron (como IntelliJ)
                show_stop_reason = true,
                commented = false,
                only_first_definition = true,
                all_references = false,
                clear_on_continue = false,
                display_callback = function(variable, buf, stackframe, node, options)
                    if options.virt_text_pos == "inline" then
                        return " = " .. variable.value
                    else
                        return variable.name .. " = " .. variable.value
                    end
                end,
                virt_text_pos = "inline", -- inline: al lado del código, como IntelliJ
                all_frames = false,
                virt_lines = false,
                virt_text_win_col = nil,
            })
        end,
    },

    -- ===========================================================================
    -- 4. MASON: instalación automática de adapters
    -- ===========================================================================
    {
        "jay-babu/mason-nvim-dap.nvim",
        dependencies = {
            "mason-org/mason.nvim",
            "mfussenegger/nvim-dap",
        },
        opts = {
            ensure_installed = {
                "python", -- debugpy
                "js", -- js-debug-adapter
                "php", -- php-debug-adapter
                "bash", -- bash-debug-adapter
                "codelldb", -- Rust / C / C++
            },
            handlers = {},
            automatic_installation = {
                exclude = { "delve" },
            },
        },
    },

    -- ===========================================================================
    -- 5. GO: nvim-dap-go (usa Delve)
    -- ===========================================================================
    {
        "leoluz/nvim-dap-go",
        ft = "go",
        dependencies = { "mfussenegger/nvim-dap" },
        -- stylua: ignore
        keys = {
            { "<leader>dgt", function() require("dap-go").debug_test() end,      desc = "Go: Debug Test" },
            { "<leader>dgl", function() require("dap-go").debug_last_test() end,  desc = "Go: Debug Last Test" },
        },
        opts = {
            dap_configurations = {
                {
                    type = "go",
                    name = "Go: Attach to Process",
                    mode = "local",
                    request = "attach",
                    processId = require("dap.utils").pick_process,
                },
            },
            delve = {
                path = "dlv",
                initialize_timeout_sec = 20,
                port = "${port}",
                args = {},
                build_flags = "",
                detached = vim.fn.has("win32") == 0,
                cwd = nil,
            },
            tests = { verbose = false },
        },
    },

    -- ===========================================================================
    -- 6. PYTHON: nvim-dap-python (usa debugpy via Mason)
    -- ===========================================================================
    {
        "mfussenegger/nvim-dap-python",
        ft = "python",
        dependencies = { "mfussenegger/nvim-dap" },
        -- stylua: ignore
        keys = {
            { "<leader>dpt", function() require("dap-python").test_method() end,     desc = "Python: Debug Test Method" },
            { "<leader>dpc", function() require("dap-python").test_class() end,      desc = "Python: Debug Test Class" },
            { "<leader>dps", function() require("dap-python").debug_selection() end, desc = "Python: Debug Selection", mode = "v" },
        },
        config = function()
            local debugpy_path = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
            require("dap-python").setup(debugpy_path)

            local dap = require("dap")
            table.insert(dap.configurations.python, {
                type = "python",
                request = "launch",
                name = "Python: Django",
                program = "${workspaceFolder}/manage.py",
                args = { "runserver", "--noreload" },
                django = true,
                console = "integratedTerminal",
            })
            table.insert(dap.configurations.python, {
                type = "python",
                request = "launch",
                name = "Python: Flask",
                module = "flask",
                env = { FLASK_APP = "${workspaceFolder}/app.py", FLASK_DEBUG = "1" },
                args = { "run", "--no-debugger", "--no-reload" },
                jinja = true,
                console = "integratedTerminal",
            })
            table.insert(dap.configurations.python, {
                type = "python",
                request = "attach",
                name = "Python: Attach to Remote",
                connect = { host = "127.0.0.1", port = 5678 },
                pathMappings = {
                    { localRoot = "${workspaceFolder}", remoteRoot = "." },
                },
            })
        end,
    },

    -- ===========================================================================
    -- 7. RUST: rustaceanvim (LSP + DAP integrado, usa codelldb)
    -- ===========================================================================
    {
        "mrcjkb/rustaceanvim",
        version = "^5",
        ft = "rust",
        dependencies = { "mfussenegger/nvim-dap" },
        -- stylua: ignore
        keys = {
            { "<leader>dr", function() vim.cmd.RustLsp("debuggables") end, desc = "Rust: Debuggables", ft = "rust" },
            { "<leader>dR", function() vim.cmd.RustLsp("runnables") end,    desc = "Rust: Runnables",   ft = "rust" },
        },
        opts = {
            server = {
                on_attach = function(_, bufnr)
                    vim.keymap.set("n", "<leader>cR", function()
                        vim.cmd.RustLsp("codeAction")
                    end, { desc = "Code Action (Rust)", buffer = bufnr })
                end,
                default_settings = {
                    ["rust-analyzer"] = {
                        cargo = { allFeatures = true, loadOutDirsFromCheck = true, buildScripts = { enable = true } },
                        procMacro = { enable = true },
                        checkOnSave = true,
                    },
                },
            },
            dap = {
                adapter = require("rustaceanvim.config").get_codelldb_adapter(
                    vim.fn.stdpath("data") .. "/mason/bin/codelldb",
                    vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/lldb/lib/liblldb.so"
                ),
            },
        },
        config = function(_, opts)
            vim.g.rustaceanvim = opts
        end,
    },

    -- ===========================================================================
    -- 8. JAVA: gestionado por ftplugin/java.lua + nvim-jdtls
    -- ===========================================================================
    {
        "mfussenegger/nvim-jdtls",
        ft = { "java" },
        dependencies = {
            "mfussenegger/nvim-dap",
            "rcarriga/nvim-dap-ui",
        },
        -- La config real está en ftplugin/java.lua
    },

    -- ===========================================================================
    -- 9. JAVASCRIPT / TYPESCRIPT / NODE (js-debug-adapter via Mason)
    -- ===========================================================================
    {
        "mfussenegger/nvim-dap",
        ft = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
        config = function()
            local dap = require("dap")

            local js_configs = {
                {
                    type = "pwa-node",
                    request = "launch",
                    name = "Node: Launch file",
                    program = "${file}",
                    cwd = "${workspaceFolder}",
                },
                {
                    type = "pwa-node",
                    request = "attach",
                    name = "Node: Attach to Process",
                    processId = require("dap.utils").pick_process,
                    cwd = "${workspaceFolder}",
                },
                {
                    type = "pwa-node",
                    request = "launch",
                    name = "Node: Jest (current file)",
                    runtimeExecutable = "node",
                    runtimeArgs = { "--inspect-brk", "${workspaceFolder}/node_modules/.bin/jest", "--runInBand" },
                    rootPath = "${workspaceFolder}",
                    cwd = "${workspaceFolder}",
                    console = "integratedTerminal",
                    internalConsoleOptions = "neverOpen",
                },
                {
                    type = "pwa-node",
                    request = "launch",
                    name = "Node: Vitest (current file)",
                    runtimeExecutable = "node",
                    runtimeArgs = {
                        "--inspect-brk",
                        "${workspaceFolder}/node_modules/vitest/vitest.mjs",
                        "--reporter=verbose",
                        "--testPathPattern=${file}",
                    },
                    cwd = "${workspaceFolder}",
                    console = "integratedTerminal",
                },
                {
                    type = "pwa-chrome",
                    request = "launch",
                    name = "Chrome: Launch localhost:3000",
                    url = "http://localhost:3000",
                    webRoot = "${workspaceFolder}",
                },
            }

            for _, ft in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
                dap.configurations[ft] = dap.configurations[ft] or {}
                for _, cfg in ipairs(js_configs) do
                    table.insert(dap.configurations[ft], cfg)
                end
            end
        end,
    },

    -- ===========================================================================
    -- Mason: asegurar herramientas instaladas
    -- ===========================================================================
    {
        "mason-org/mason.nvim",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, {
                "debugpy",
                "js-debug-adapter",
                "php-debug-adapter",
                "bash-debug-adapter",
                "codelldb",
                "java-debug-adapter",
                "jdtls",
            })
        end,
    },
}
