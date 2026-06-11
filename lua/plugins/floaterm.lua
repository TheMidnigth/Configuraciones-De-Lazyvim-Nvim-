-- lua/plugins/floaterm.lua
return {
    {
        "nvzone/floaterm",
        dependencies = { "nvzone/volt" },
        keys = {
            {
                "<leader>ft",
                function()
                    require("floaterm").toggle()
                end,
                desc = "Toggle Floaterm",
            },
        },
        cmd = { "Floaterm" },
        config = function()
            require("floaterm").setup({
                border = true,
                size = { h = 80, w = 85 },
                mappings = { sidebar = nil, term = nil },
                terminals = {
                    { name = "Terminal" },
                },
            })
        end,
    },
}
