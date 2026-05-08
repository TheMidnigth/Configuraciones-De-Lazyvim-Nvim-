-- Forzar keymaps de DAP después de que todo esté cargado
return {
    {
        "mfussenegger/nvim-dap",
        lazy = false,
        config = function()
            -- Esperar a que DAP esté completamente listo
            vim.defer_fn(function()
                local dap = require("dap")
                local dapui = require("dapui")

                -- Keymaps básicos
                vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
                vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue" })
                vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step Into" })
                vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "Step Over" })
                vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Toggle DAP UI" })

            end, 200)
        end,
    },
}
