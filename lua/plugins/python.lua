return {

    -- ── Depurador: como el de PyCharm ────────────────────────────────
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            {
                "mfussenegger/nvim-dap-python",
                config = function()
                    local dap_python = require("dap-python")
                    -- detecta el python del venv activo, si no usa el global
                    local python = vim.fn.exepath("python")
                    dap_python.setup(python)
                    dap_python.test_runner = "pytest"
                end,
            },
        },
    },

    -- ── UI del depurador ──────────────────────────────────────────────
    {
        "rcarriga/nvim-dap-ui",
        dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
        config = function()
            local dap, dapui = require("dap"), require("dapui")
            dapui.setup()
            -- abre y cierra la UI automáticamente
            dap.listeners.after.event_initialized["dapui_config"] = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated["dapui_config"] = function()
                dapui.close()
            end
            dap.listeners.before.event_exited["dapui_config"] = function()
                dapui.close()
            end
        end,
        keys = {
            {
                "<leader>du",
                function()
                    require("dapui").toggle()
                end,
                desc = "Toggle DAP UI",
            },
        },
    },

    -- ── Tests: como el test runner de PyCharm ────────────────────────
    {
        "nvim-neotest/neotest",
        dependencies = {
            "nvim-neotest/neotest-python",
            "nvim-neotest/nvim-nio",
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
        },
        opts = function(_, opts)
            opts.adapters = opts.adapters or {}
            table.insert(
                opts.adapters,
                require("neotest-python")({
                    dap = { justMyCode = false },
                    runner = "pytest",
                    python = vim.fn.exepath("python"),
                })
            )
        end,
        keys = {
            {
                "<leader>tt",
                function()
                    require("neotest").run.run()
                end,
                desc = "Correr test bajo cursor",
            },
            {
                "<leader>tf",
                function()
                    require("neotest").run.run(vim.fn.expand("%"))
                end,
                desc = "Correr tests del archivo",
            },
            {
                "<leader>ta",
                function()
                    require("neotest").run.run(vim.fn.getcwd())
                end,
                desc = "Correr todos los tests",
            },
            {
                "<leader>ts",
                function()
                    require("neotest").summary.toggle()
                end,
                desc = "Panel de tests",
            },
            {
                "<leader>to",
                function()
                    require("neotest").output_panel.toggle()
                end,
                desc = "Output de tests",
            },
            {
                "<leader>td",
                function()
                    require("neotest").run.run({ strategy = "dap" })
                end,
                desc = "Depurar test bajo cursor",
            },
        },
    },

    -- ── Resalta todas las referencias de la variable bajo el cursor ───
    {
        "RRethy/vim-illuminate",
        event = { "BufReadPost", "BufNewFile" },
        opts = { delay = 100, large_file_cutoff = 2000 },
    },
}
