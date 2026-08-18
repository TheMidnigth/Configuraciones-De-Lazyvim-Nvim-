return {
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        keys = {
            {
                "<leader>ft",
                function()
                    require("toggleterm").toggle()
                end,
                desc = "Toggle Terminal",
            },
        },
        cmd = { "ToggleTerm" },
        config = function()
            require("toggleterm").setup({
                size = function(term)
                    if term.direction == "horizontal" then
                        return 20
                    elseif term.direction == "vertical" then
                        return math.floor(vim.o.columns * 0.5)
                    end
                end,
                open_mapping = [[<leader>ft]],
                hide_numbers = true,
                shade_terminals = false,
                start_in_insert = true,
                insert_mappings = true,
                terminal_mappings = true,
                persist_size = true,
                persist_mode = true,
                direction = "float",
                close_on_exit = true,
                shell = vim.o.shell,
                auto_scroll = true,
                float_opts = {
                    border = "curved",
                    width = math.floor(vim.o.columns * 0.92),
                    height = math.floor(vim.o.lines * 0.88),
                    winblend = 0,
                    title_pos = "center",
                },
                highlights = {
                    Normal = { link = "Normal" },
                    NormalFloat = { link = "NormalFloat" },
                    FloatBorder = { link = "FloatBorder" },
                },
            })

            -- Salir del modo insert con Esc
            function _G.set_terminal_keymaps()
                local opts = { buffer = 0 }
                vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], opts)
            end

            vim.api.nvim_create_autocmd("TermOpen", {
                pattern = "term://*toggleterm#*",
                callback = function()
                    set_terminal_keymaps()
                end,
            })
        end,
    },
}
