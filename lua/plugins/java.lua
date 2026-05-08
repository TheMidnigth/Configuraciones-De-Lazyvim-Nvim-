-- ~/.config/nvim/lua/plugins/java.lua (VERSIÓN CORRECTA)
return {
    -- Plugin de DAP
    {
        "mfussenegger/nvim-dap",
        lazy = true,
    },

    -- Plugin de DAP UI
    {
        "rcarriga/nvim-dap-ui",
        dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
        lazy = true,
    },

    -- Plugin JDTLS
    {
        "mfussenegger/nvim-jdtls",
        dependencies = {
            "mfussenegger/nvim-dap",
            "rcarriga/nvim-dap-ui",
        },
        ft = "java",
    },
}
