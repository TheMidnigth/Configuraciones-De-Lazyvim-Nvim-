return {
    { "nvzone/volt", lazy = true },
    {
        "nvzone/menu",
        lazy = true,
        keys = {
            {
                "<C-t>",
                function()
                    local ft = vim.bo.ft
                    local options
                    if ft == "NvimTree" then
                        options = require("config.nvimtree-menu")
                    else
                        package.loaded["config.default-menu"] = nil
                        options = require("config.default-menu")
                    end
                    if ft == "java" or ft == "dart" then
                        local buf = vim.api.nvim_get_current_buf()
                        local filtered = {}
                        for _, item in ipairs(options) do
                            if item.condition == nil or item.condition(buf) then
                                table.insert(filtered, item)
                            end
                        end
                        options = filtered
                    end
                    require("menu").open(options)
                end,
                desc = "Open Menu",
                mode = { "n", "v" },
            },
            {
                "<RightMouse>",
                function()
                    require("menu.utils").delete_old_menus()
                    vim.cmd.exec('"normal! \\<RightMouse>"')
                    local buf = vim.api.nvim_win_get_buf(vim.fn.getmousepos().winid)
                    local ft = vim.bo[buf].ft
                    local options
                    if ft == "NvimTree" then
                        options = require("config.nvimtree-menu")
                    else
                        package.loaded["config.default-menu"] = nil
                        options = require("config.default-menu")
                    end
                    if ft == "java" or ft == "dart" then
                        local filtered = {}
                        for _, item in ipairs(options) do
                            if item.condition == nil or item.condition(buf) then
                                table.insert(filtered, item)
                            end
                        end
                        options = filtered
                    end
                    require("menu").open(options, { mouse = true })
                end,
                desc = "Open Context Menu",
                mode = { "n", "v" },
            },
        },
    },
}
