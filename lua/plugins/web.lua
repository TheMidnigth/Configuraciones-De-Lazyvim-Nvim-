return {
    -- Auto close + Auto rename tag
    {
        "windwp/nvim-ts-autotag",
        event = "InsertEnter",
        opts = {
            enable_close = true,
            enable_rename = true,
            enable_close_on_slash = true,
        },
    },

    -- Color Highlight
    {
        "NvChad/nvim-colorizer.lua",
        event = "BufReadPre",
        opts = {
            filetypes = { "html", "css", "scss", "javascript", "typescript", "lua" },
            user_default_options = {
                RGB = true,
                RRGGBB = true,
                names = true,
                css = true,
            },
        },
    },

    -- Live Server (WSL2)
    {
        "barrett-ruth/live-server.nvim",
        build = "npm install -g live-server",
        lazy = false,
        config = function()
            local live_server_bin = "/home/eyner_eyes/.nvm/versions/node/v20.20.0/bin/live-server"

            local function start_live_server()
                local file_abs = vim.fn.expand("%:p")
                local server_root = vim.fn.expand("%:p:h")

                local roots = { "resources", "public", "static", "src", "www" }
                for _, root in ipairs(roots) do
                    local match = file_abs:match("^(.*/" .. root .. "/)")
                    if match then
                        server_root = match:gsub("/$", "")
                        break
                    end
                end

                local relative = file_abs:sub(#server_root + 2)
                local wsl_ip = vim.fn.system("hostname -I | awk '{print $1}'"):gsub("%s+", "")

                -- Matar instancia previa
                vim.fn.system("pkill -f live-server 2>/dev/null")
                vim.fn.system("sleep 1")

                -- Actualizar portproxy (requiere que ya tengas la regla creada como admin)
                local proxy_cmd = string.format(
                    'powershell.exe -Command "netsh interface portproxy delete v4tov4 listenport=8080 listenaddress=0.0.0.0 2>$null; netsh interface portproxy add v4tov4 listenport=8080 listenaddress=0.0.0.0 connectport=8080 connectaddress=%s"',
                    wsl_ip
                )
                vim.fn.jobstart({ "bash", "-c", proxy_cmd })

                -- Arrancar live-server
                vim.fn.jobstart({
                    "bash",
                    "-c",
                    live_server_bin
                        .. " "
                        .. vim.fn.shellescape(server_root)
                        .. " --port=8080 --host=0.0.0.0 --no-browser >> /tmp/live-server.log 2>&1",
                }, { detach = true })

                vim.defer_fn(function()
                    local url = "http://localhost:8080/" .. relative
                    vim.fn.jobstart({ "cmd.exe", "/c", "start", url }, { detach = true })
                    vim.notify("🌐 Live Server: " .. url, vim.log.levels.INFO)
                end, 2000)
            end

            local function stop_live_server()
                vim.fn.system("pkill -f live-server 2>/dev/null")
                vim.notify("🛑 Live Server detenido", vim.log.levels.INFO)
            end

            vim.keymap.set("n", "<leader>ws", start_live_server, { desc = "Live Server Start" })
            vim.keymap.set("n", "<leader>wx", stop_live_server, { desc = "Live Server Stop" })

            _G.StartLiveServer = start_live_server
            _G.StopLiveServer = stop_live_server
        end,
    },
}
