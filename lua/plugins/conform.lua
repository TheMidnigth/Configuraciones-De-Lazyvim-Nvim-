return {
    {
        "stevearc/conform.nvim",
        opts = {
            format_on_save = nil,
            formatters_by_ft = {
                java = { "google-java-format" },
                html = { "prettierd" },
                css = { "prettierd" },
                scss = { "prettierd" },
                javascript = { "prettierd" },
                typescript = { "prettierd" },
                javascriptreact = { "prettierd" },
                typescriptreact = { "prettierd" },
                json = { "prettierd" },
                jsonc = { "prettierd" },
                python = { "black", "isort" }, -- nuevo
            },
            formatters = {
                ["google-java-format"] = {
                    args = { "--aosp", "-" },
                },
                -- nuevo
                black = {
                    args = { "--line-length", "88", "--quiet", "-" },
                },
                isort = {
                    args = { "--profile", "black", "-" },
                },
            },
        },
    },
}
