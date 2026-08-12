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
                dart = { "dart_format" },
            },
            formatters = {
                ["google-java-format"] = {
                    args = { "--aosp", "-" },
                },
                dart_format = {
                    command = vim.fn.expand("~/flutter/bin/dart"),
                    args = { "format", "--indent", "4", "--output=show", "--summary=none", "-" },
                    stdin = true,
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
