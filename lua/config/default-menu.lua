local function get_buf()
    return vim.api.nvim_get_current_buf()
end

local function get_ft()
    return vim.bo[get_buf()].filetype
end

local function get_bufname()
    return vim.api.nvim_buf_get_name(get_buf())
end

local function has_main_method(buf)
    local ok, parser = pcall(vim.treesitter.get_parser, buf, "java")
    if not ok then
        return false
    end
    local tree = parser:parse()[1]
    local query = vim.treesitter.query.parse(
        "java",
        [[
        (method_declaration
            name: (identifier) @name
            parameters: (formal_parameters
                (formal_parameter
                    type: (array_type
                        element: (type_identifier) @param_type))))
    ]]
    )
    for _, match in query:iter_matches(tree:root(), buf, nil, nil, { all = true }) do
        local name_node = match[1] and match[1][1]
        local param_node = match[2] and match[2][1]
        if name_node and param_node then
            if
                vim.treesitter.get_node_text(name_node, buf) == "main"
                and vim.treesitter.get_node_text(param_node, buf) == "String"
            then
                return true
            end
        end
    end
    return false
end

local function has_dart_main(buf)
    local ok, parser = pcall(vim.treesitter.get_parser, buf, "dart")
    if not ok then
        return false
    end
    local tree = parser:parse()[1]
    if not tree then
        return false
    end
    local query = vim.treesitter.query.parse(
        "dart",
        [[
        (function_signature
            name: (identifier) @name)
        ]]
    )
    for _, match in query:iter_matches(tree:root(), buf, nil, nil, { all = true }) do
        local name_node = match[1] and match[1][1]
        if name_node then
            if vim.treesitter.get_node_text(name_node, buf) == "main" then
                return true
            end
        end
    end
    return false
end

local function filter_items(items, buf)
    local result = {}
    for _, item in ipairs(items) do
        if item.condition == nil or item.condition(buf) then
            table.insert(result, item)
        end
    end
    return result
end

local function open_terminal()
    local dir = vim.fn.fnamemodify(get_bufname(), ":h")
    vim.cmd("enew")
    vim.fn.termopen({ vim.o.shell, "-c", "cd " .. dir .. " ; " .. vim.o.shell })
end

local html_items = {
    -- 1
    {
        name = "  Go to Definition",
        cmd = vim.lsp.buf.definition,
        rtxt = "F12",
    },
    -- 2
    {
        name = "  Go to References",
        cmd = vim.lsp.buf.references,
        rtxt = "Shift+F12",
    },
    -- 3
    {
        name = "  Peek",
        items = {
            { name = "Peek Definition", cmd = vim.lsp.buf.definition, rtxt = "Alt+F12" },
            { name = "Peek References", cmd = vim.lsp.buf.references },
        },
    },
    { name = "separator" },
    -- 5
    {
        name = "  Find All References",
        cmd = vim.lsp.buf.references,
        rtxt = "Shift+Alt+F12",
    },
    { name = "separator" },
    -- 7
    {
        name = "  Rename Symbol",
        cmd = vim.lsp.buf.rename,
        rtxt = "F2",
    },
    -- 8
    {
        name = "  Change All Occurrences",
        cmd = vim.lsp.buf.rename,
        rtxt = "Ctrl+F2",
    },
    -- 9
    {
        name = "  Format Document",
        cmd = function()
            local ok, conform = pcall(require, "conform")
            if ok then
                conform.format({ lsp_fallback = true })
            else
                vim.lsp.buf.format()
            end
        end,
        rtxt = "<leader>cf",
    },
    -- 10
    {
        name = "  Refactor...",
        cmd = vim.lsp.buf.code_action,
        rtxt = "Ctrl+Shift+R",
    },
    -- 11
    {
        name = "  Source Action...",
        cmd = vim.lsp.buf.code_action,
    },
    { name = "separator" },
    -- 13
    {
        name = "  Open Changes",
        items = {
            {
                name = "Compare with Previous",
                cmd = function()
                    vim.cmd("Git diff HEAD~1")
                end,
            },
            {
                name = "Compare with HEAD",
                cmd = function()
                    vim.cmd("Git diff HEAD")
                end,
            },
        },
    },
    { name = "separator" },
    -- 15
    {
        name = "  Cut",
        cmd = function()
            vim.cmd('normal! "+d')
        end,
        rtxt = "Ctrl+X",
    },
    -- 16
    {
        name = "  Copy",
        cmd = function()
            vim.cmd('normal! "+y')
        end,
        rtxt = "Ctrl+C",
    },
    -- 17
    {
        name = "  Copy As",
        items = {
            {
                name = "Copy Relative Path",
                cmd = function()
                    local rel = vim.fn.fnamemodify(get_bufname(), ":~:.")
                    vim.fn.setreg("+", rel)
                    vim.notify("Copied: " .. rel)
                end,
            },
            {
                name = "Copy Link to File",
                cmd = function()
                    local path = get_bufname()
                    local link = "file://" .. path
                    vim.fn.setreg("+", link)
                    vim.notify("Copied: " .. link)
                end,
            },
        },
    },
    -- 18
    {
        name = "  Paste",
        cmd = function()
            vim.cmd('normal! "+p')
        end,
        rtxt = "Ctrl+V",
    },
    { name = "separator" },
    -- 20
    {
        name = "  Open with Live Server",
        hl = "ExBlue",
        cmd = function()
            if _G.StartLiveServer then
                _G.StartLiveServer()
            else
                vim.notify("Live Server no está disponible", vim.log.levels.ERROR)
            end
        end,
        rtxt = "<leader>ws",
    },

    {
        name = "  Stop Live Server",
        hl = "ExRed",
        cmd = function()
            if _G.StopLiveServer then
                _G.StopLiveServer()
            end
        end,
        rtxt = "<leader>wx",
    },
}

local default_items = {
    {
        name = "Format Buffer",
        cmd = function()
            local ok, conform = pcall(require, "conform")

            if ok then
                conform.format({ lsp_fallback = true })
            else
                vim.lsp.buf.format()
            end
        end,
        rtxt = "<leader>fm",
    },

    {
        name = "Code Actions",
        cmd = vim.lsp.buf.code_action,
        rtxt = "<leader>ca",
    },

    { name = "separator" },

    {
        name = "  Lsp Actions",
        hl = "Exblue",
        items = "lsp",
    },

    { name = "separator" },

    {
        name = "Edit Config",
        cmd = function()
            vim.cmd("tabnew")
            local conf = vim.fn.stdpath("config")
            vim.cmd("tcd " .. conf .. " | e init.lua")
        end,
        rtxt = "ed",
    },

    {
        name = "Copy Content",
        cmd = "%y+",
        rtxt = "<C-c>",
    },

    {
        name = "Delete Content",
        cmd = "%d",
        rtxt = "dc",
    },

    { name = "separator" },

    {
        name = "  Open in terminal",
        hl = "ExRed",
        cmd = function()
            local old_buf = require("menu.state").old_data.buf
            local old_bufname = vim.api.nvim_buf_get_name(old_buf)
            local old_buf_dir = vim.fn.fnamemodify(old_bufname, ":h")

            local cmd = "cd " .. old_buf_dir

            -- base46_cache var is an indicator of nvui user!
            if vim.g.base46_cache then
                require("nvchad.term").new({ cmd = cmd, pos = "sp" })
            else
                vim.cmd("enew")
                vim.fn.termopen({ vim.o.shell, "-c", cmd .. " ; " .. vim.o.shell })
            end
        end,
    },

    { name = "separator" },

    {
        name = "  Color Picker",
        cmd = function()
            require("minty.huefy").open()
        end,
    },
}

local css_items = {
    -- 1
    {
        name = "  Go to Definition",
        cmd = vim.lsp.buf.definition,
        rtxt = "F12",
    },
    -- 2
    {
        name = "  Go to References",
        cmd = vim.lsp.buf.references,
        rtxt = "Shift+F12",
    },
    -- 3
    {
        name = "  Peek",
        items = {
            { name = "Peek Definition", cmd = vim.lsp.buf.definition, rtxt = "Alt+F12" },
            { name = "Peek References", cmd = vim.lsp.buf.references },
        },
    },
    { name = "separator" },
    -- 5
    {
        name = "  Find All References",
        cmd = vim.lsp.buf.references,
        rtxt = "Shift+Alt+F12",
    },
    { name = "separator" },
    -- 7
    {
        name = "  Rename Symbol",
        cmd = vim.lsp.buf.rename,
        rtxt = "F2",
    },
    -- 8
    {
        name = "  Change All Occurrences",
        cmd = vim.lsp.buf.rename,
        rtxt = "Ctrl+F2",
    },
    -- 9
    {
        name = "  Format Document",
        cmd = function()
            local ok, conform = pcall(require, "conform")
            if ok then
                conform.format({ lsp_fallback = true })
            else
                vim.lsp.buf.format()
            end
        end,
        rtxt = "<leader>cf",
    },
    -- 10
    {
        name = "  Refactor...",
        cmd = vim.lsp.buf.code_action,
        rtxt = "Ctrl+Shift+R",
    },
    -- 11
    {
        name = "  Source Action...",
        cmd = vim.lsp.buf.code_action,
    },
    { name = "separator" },
    -- 13
    {
        name = "  Open Changes",
        items = {
            {
                name = "Compare with Previous",
                cmd = function()
                    vim.cmd("Git diff HEAD~1")
                end,
            },
            {
                name = "Compare with HEAD",
                cmd = function()
                    vim.cmd("Git diff HEAD")
                end,
            },
        },
    },
    { name = "separator" },
    -- 15
    {
        name = "  Cut",
        cmd = function()
            vim.cmd('normal! "+d')
        end,
        rtxt = "Ctrl+X",
    },
    -- 16
    {
        name = "  Copy",
        cmd = function()
            vim.cmd('normal! "+y')
        end,
        rtxt = "Ctrl+C",
    },
    -- 17
    {
        name = "  Copy As",
        items = {
            {
                name = "Copy Relative Path",
                cmd = function()
                    local rel = vim.fn.fnamemodify(get_bufname(), ":~:.")
                    vim.fn.setreg("+", rel)
                    vim.notify("Copied: " .. rel)
                end,
            },
            {
                name = "Copy Link to File",
                cmd = function()
                    local link = "file://" .. get_bufname()
                    vim.fn.setreg("+", link)
                    vim.notify("Copied: " .. link)
                end,
            },
        },
    },
    -- 18
    {
        name = "  Paste",
        cmd = function()
            vim.cmd('normal! "+p')
        end,
        rtxt = "Ctrl+V",
    },
}

local javascript_items = {
    -- 1
    {
        name = "  Go to Definition",
        cmd = vim.lsp.buf.definition,
        rtxt = "F12",
    },
    -- 2
    {
        name = "  Go to Type Definition",
        cmd = vim.lsp.buf.type_definition,
    },
    -- 3
    {
        name = "  Go to Source Definition",
        cmd = vim.lsp.buf.definition,
    },
    -- 4
    {
        name = "  Go to Implementations",
        cmd = vim.lsp.buf.implementation,
        rtxt = "Ctrl+F12",
    },
    -- 5
    {
        name = "  Go to References",
        cmd = vim.lsp.buf.references,
        rtxt = "Shift+F12",
    },
    -- 6
    {
        name = "  Peek",
        items = {
            { name = "Peek Definition", cmd = vim.lsp.buf.definition, rtxt = "Alt+F12" },
            { name = "Peek Type Definition", cmd = vim.lsp.buf.type_definition },
            { name = "Peek Implementations", cmd = vim.lsp.buf.implementation },
            { name = "Peek References", cmd = vim.lsp.buf.references },
        },
    },
    { name = "separator" },
    -- 8
    {
        name = "  Find All References",
        cmd = vim.lsp.buf.references,
        rtxt = "Shift+Alt+F12",
    },
    -- 9
    {
        name = "  Find All Implementations",
        cmd = vim.lsp.buf.implementation,
    },
    -- 10
    {
        name = "  Show Call Hierarchy",
        cmd = vim.lsp.buf.incoming_calls,
        rtxt = "Shift+Alt+H",
    },
    { name = "separator" },
    -- 12
    {
        name = "  Rename Symbol",
        cmd = vim.lsp.buf.rename,
        rtxt = "F2",
    },
    -- 13
    {
        name = "  Change All Occurrences",
        cmd = vim.lsp.buf.rename,
        rtxt = "Ctrl+F2",
    },
    -- 14
    {
        name = "  Format Document",
        cmd = function()
            local ok, conform = pcall(require, "conform")
            if ok then
                conform.format({ lsp_fallback = true })
            else
                vim.lsp.buf.format()
            end
        end,
        rtxt = "<leader>cf",
    },
    -- 15
    {
        name = "  Refactor...",
        cmd = vim.lsp.buf.code_action,
        rtxt = "Ctrl+Shift+R",
    },
    -- 16
    {
        name = "  Source Action...",
        cmd = vim.lsp.buf.code_action,
    },
    { name = "separator" },
    -- 18
    {
        name = "  Open Changes",
        items = {
            {
                name = "Compare with Previous",
                cmd = function()
                    vim.cmd("Git diff HEAD~1")
                end,
            },
            {
                name = "Compare with HEAD",
                cmd = function()
                    vim.cmd("Git diff HEAD")
                end,
            },
        },
    },
    { name = "separator" },
    -- 20
    {
        name = "  Cut",
        cmd = function()
            vim.cmd('normal! "+d')
        end,
        rtxt = "Ctrl+X",
    },
    -- 21
    {
        name = "  Copy",
        cmd = function()
            vim.cmd('normal! "+y')
        end,
        rtxt = "Ctrl+C",
    },
    -- 22
    {
        name = "  Copy As",
        items = {
            {
                name = "Copy Relative Path",
                cmd = function()
                    local rel = vim.fn.fnamemodify(get_bufname(), ":~:.")
                    vim.fn.setreg("+", rel)
                    vim.notify("Copied: " .. rel)
                end,
            },
            {
                name = "Copy Link to File",
                cmd = function()
                    local link = "file://" .. get_bufname()
                    vim.fn.setreg("+", link)
                    vim.notify("Copied: " .. link)
                end,
            },
        },
    },
    -- 23
    {
        name = "  Paste",
        cmd = function()
            vim.cmd('normal! "+p')
        end,
        rtxt = "Ctrl+V",
    },
}

local java_items = {
    {
        name = "  Show Context Actions",
        cmd = vim.lsp.buf.code_action,
        rtxt = "Ctrl+.",
    },
    {
        name = "  Reformat Code",
        cmd = function()
            local filepath = vim.fn.expand("%:p")
            local buf = vim.api.nvim_get_current_buf()
            vim.fn.jobstart({ "google-java-format", "--aosp", "--replace", filepath }, {
                on_exit = function(_, code)
                    if code == 0 then
                        vim.cmd("checktime")
                        vim.notify("✓ Código formateado correctamente")
                    else
                        vim.notify("✗ Error al formatear", vim.log.levels.ERROR)
                    end
                end,
            })
        end,
        rtxt = "Ctrl+Alt+L",
    },
    { name = "separator" },
    {
        name = "  Paste",
        cmd = function()
            vim.cmd('normal! "+p')
        end,
        rtxt = "Ctrl+V",
    },
    {
        name = "  Copy / Paste Special",
        items = {
            {
                name = "Paste from History",
                cmd = function()
                    vim.cmd('normal! "+p')
                end,
            },
            {
                name = "Paste without Formatting",
                cmd = function()
                    vim.cmd("normal! p")
                end,
            },
            {
                name = "Copy Reference",
                cmd = function()
                    local rel = vim.fn.fnamemodify(get_bufname(), ":~:.")
                    vim.fn.setreg("+", rel)
                    vim.notify("Copied: " .. rel)
                end,
            },
            {
                name = "Copy Absolute Path",
                cmd = function()
                    vim.fn.setreg("+", get_bufname())
                    vim.notify("Copied: " .. get_bufname())
                end,
            },
        },
    },
    {
        name = "  Column Selection Mode",
        cmd = function()
            vim.cmd("normal! \22")
        end,
        rtxt = "Alt+Shift+Insert",
    },
    { name = "separator" },
    {
        name = "  Find Usages",
        cmd = vim.lsp.buf.references,
        rtxt = "Alt+Shift+F12",
    },
    {
        name = "  Go To",
        items = {
            { name = "Definition", cmd = vim.lsp.buf.definition, rtxt = "F12" },
            { name = "Type Definition", cmd = vim.lsp.buf.type_definition },
            { name = "Implementation", cmd = vim.lsp.buf.implementation, rtxt = "Ctrl+F12" },
            { name = "References", cmd = vim.lsp.buf.references, rtxt = "Shift+F12" },
            { name = "Declaration", cmd = vim.lsp.buf.declaration },
            { name = "Super Method", cmd = vim.lsp.buf.implementation },
        },
    },
    {
        name = "  Folding",
        items = {
            {
                name = "Expand",
                cmd = function()
                    vim.cmd("normal! zo")
                end,
                rtxt = "Ctrl+NumPad+",
            },
            {
                name = "Collapse",
                cmd = function()
                    vim.cmd("normal! zc")
                end,
                rtxt = "Ctrl+NumPad-",
            },
            {
                name = "Expand All",
                cmd = function()
                    vim.cmd("normal! zR")
                end,
                rtxt = "Ctrl+Shift+NumPad+",
            },
            {
                name = "Collapse All",
                cmd = function()
                    vim.cmd("normal! zM")
                end,
                rtxt = "Ctrl+Shift+NumPad-",
            },
        },
    },
    {
        name = "  Analyze",
        items = {
            {
                name = "Inspect Code",
                cmd = vim.lsp.buf.code_action,
            },
            {
                name = "Show Error Description",
                cmd = vim.diagnostic.open_float,
            },
            {
                name = "Next Problem",
                cmd = function()
                    vim.diagnostic.goto_next()
                end,
                rtxt = "F2",
            },
            {
                name = "Previous Problem",
                cmd = function()
                    vim.diagnostic.goto_prev()
                end,
                rtxt = "Shift+F2",
            },
        },
    },
    { name = "separator" },
    {
        name = "  Rename...",
        cmd = vim.lsp.buf.rename,
        rtxt = "F2",
    },
    {
        name = "  Refactor",
        items = {
            { name = "Rename", cmd = vim.lsp.buf.rename, rtxt = "Shift+F6" },
            { name = "Extract Method", cmd = vim.lsp.buf.code_action },
            { name = "Extract Variable", cmd = vim.lsp.buf.code_action },
            { name = "Inline", cmd = vim.lsp.buf.code_action, rtxt = "Ctrl+Alt+N" },
            { name = "Move", cmd = vim.lsp.buf.code_action, rtxt = "F6" },
        },
    },
    {
        name = "  Generate...",
        rtxt = "Alt+Insert",
        items = {
            -- Constructor
            {
                name = "Constructor",
                cmd = function()
                    local source_buf = vim.api.nvim_get_current_buf()
                    local parser = vim.treesitter.get_parser(source_buf, "java")
                    local tree = parser:parse()[1]

                    local field_query = vim.treesitter.query.parse(
                        "java",
                        [[
            (field_declaration
                type: (_) @type
                declarator: (variable_declarator name: (identifier) @name))
        ]]
                    )

                    local class_query = vim.treesitter.query.parse(
                        "java",
                        [[
            (class_declaration name: (identifier) @classname)
        ]]
                    )

                    local fields = {}
                    for _, match in field_query:iter_matches(tree:root(), source_buf, nil, nil, { all = true }) do
                        local type_node = match[1] and match[1][1]
                        local name_node = match[2] and match[2][1]
                        if type_node and name_node then
                            table.insert(fields, {
                                type = vim.treesitter.get_node_text(type_node, source_buf),
                                name = vim.treesitter.get_node_text(name_node, source_buf),
                            })
                        end
                    end

                    if #fields == 0 then
                        vim.notify("No se encontraron campos en la clase", vim.log.levels.WARN)
                        return
                    end

                    local class_name = "MyClass"
                    for _, match in class_query:iter_matches(tree:root(), source_buf, nil, nil, { all = true }) do
                        local node = match[1] and match[1][1]
                        if node then
                            class_name = vim.treesitter.get_node_text(node, source_buf)
                            break
                        end
                    end

                    local items = {}
                    for i, f in ipairs(fields) do
                        table.insert(items, {
                            idx = i,
                            text = f.name .. ": " .. f.type,
                            field = f,
                        })
                    end

                    local selected_map = {}

                    Snacks.picker({
                        title = "Generate Constructor",
                        items = items,
                        format = function(item)
                            local check = selected_map[item.idx] and " [x] " or " [ ] "
                            return {
                                { check, hl = selected_map[item.idx] and "DiagnosticOk" or "Comment" },
                                { item.field.name, hl = selected_map[item.idx] and "DiagnosticOk" or "Normal" },
                                { ": ", hl = "Comment" },
                                { item.field.type, hl = "Type" },
                            }
                        end,
                        actions = {
                            toggle_select = function(picker, item)
                                if item then
                                    selected_map[item.idx] = not selected_map[item.idx]
                                    picker:refresh()
                                end
                            end,
                            select_all = function(picker)
                                local all = true
                                for _, it in ipairs(items) do
                                    if not selected_map[it.idx] then
                                        all = false
                                        break
                                    end
                                end
                                for _, it in ipairs(items) do
                                    selected_map[it.idx] = not all
                                end
                                picker:refresh()
                            end,
                            confirm_generate = function(picker)
                                local chosen = {}
                                for _, it in ipairs(items) do
                                    if selected_map[it.idx] then
                                        table.insert(chosen, it.field)
                                    end
                                end
                                picker:close()

                                local buf_lines = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)
                                local insert_at = #buf_lines - 1
                                for i = #buf_lines, 1, -1 do
                                    if buf_lines[i]:match("^}") then
                                        insert_at = i - 1
                                        break
                                    end
                                end

                                if #chosen == 0 then
                                    local body = { "" }
                                    table.insert(body, "    public " .. class_name .. "() {")
                                    table.insert(body, "    }")
                                    vim.api.nvim_buf_set_lines(source_buf, insert_at, insert_at, false, body)
                                    vim.notify("✓ Constructor vacío generado para " .. class_name)
                                    return
                                end

                                local params = {}
                                for _, f in ipairs(chosen) do
                                    table.insert(params, f.type .. " " .. f.name)
                                end

                                local body = { "" }
                                table.insert(
                                    body,
                                    "    public " .. class_name .. "(" .. table.concat(params, ", ") .. ") {"
                                )
                                for _, f in ipairs(chosen) do
                                    table.insert(body, "        this." .. f.name .. " = " .. f.name .. ";")
                                end
                                table.insert(body, "    }")

                                vim.api.nvim_buf_set_lines(source_buf, insert_at, insert_at, false, body)
                                vim.notify("✓ Constructor generado para " .. class_name)
                            end,
                        },
                        win = {
                            input = {
                                keys = {
                                    ["<Space>"] = { "toggle_select", mode = { "n", "i" } },
                                    ["<CR>"] = { "confirm_generate", mode = { "n", "i" } },
                                    ["<C-a>"] = { "select_all", mode = { "n", "i" } },
                                },
                            },
                            list = {
                                keys = {
                                    ["<Space>"] = { "toggle_select" },
                                    ["<CR>"] = { "confirm_generate" },
                                    ["<C-a>"] = { "select_all" },
                                },
                            },
                        },
                        layout = { preset = "select" },
                    })
                end,
            },
            -- Getter
            {
                name = "Getter",
                cmd = function()
                    local source_buf = vim.api.nvim_get_current_buf()
                    local parser = vim.treesitter.get_parser(source_buf, "java")
                    local tree = parser:parse()[1]

                    local field_query = vim.treesitter.query.parse(
                        "java",
                        [[
            (field_declaration
                type: (_) @type
                declarator: (variable_declarator name: (identifier) @name))
        ]]
                    )

                    local class_query = vim.treesitter.query.parse(
                        "java",
                        [[
            (class_declaration name: (identifier) @classname)
        ]]
                    )

                    local method_query = vim.treesitter.query.parse(
                        "java",
                        [[
            (method_declaration name: (identifier) @method_name)
        ]]
                    )

                    local existing_methods = {}
                    for _, match in method_query:iter_matches(tree:root(), source_buf, nil, nil, { all = true }) do
                        local node = match[1] and match[1][1]
                        if node then
                            existing_methods[vim.treesitter.get_node_text(node, source_buf)] = true
                        end
                    end

                    local all_fields = {}
                    for _, match in field_query:iter_matches(tree:root(), source_buf, nil, nil, { all = true }) do
                        local type_node = match[1] and match[1][1]
                        local name_node = match[2] and match[2][1]
                        if type_node and name_node then
                            table.insert(all_fields, {
                                type = vim.treesitter.get_node_text(type_node, source_buf),
                                name = vim.treesitter.get_node_text(name_node, source_buf),
                            })
                        end
                    end

                    local fields = {}
                    for _, f in ipairs(all_fields) do
                        local prefix = (f.type == "boolean") and "is" or "get"
                        local getter_name = prefix .. f.name:sub(1, 1):upper() .. f.name:sub(2)
                        if not existing_methods[getter_name] then
                            table.insert(fields, f)
                        end
                    end

                    if #fields == 0 then
                        vim.notify("✓ Todos los campos ya tienen Getter", vim.log.levels.INFO)
                        return
                    end

                    local class_name = "MyClass"
                    for _, match in class_query:iter_matches(tree:root(), source_buf, nil, nil, { all = true }) do
                        local node = match[1] and match[1][1]
                        if node then
                            class_name = vim.treesitter.get_node_text(node, source_buf)
                            break
                        end
                    end

                    local items = {}
                    for i, f in ipairs(fields) do
                        table.insert(items, {
                            idx = i,
                            text = f.name .. ": " .. f.type,
                            field = f,
                        })
                    end

                    local selected_map = {}

                    Snacks.picker({
                        title = "Generate Getter",
                        items = items,
                        format = function(item)
                            local check = selected_map[item.idx] and " [x] " or " [ ] "
                            return {
                                { check, hl = selected_map[item.idx] and "DiagnosticOk" or "Comment" },
                                { item.field.name, hl = selected_map[item.idx] and "DiagnosticOk" or "Normal" },
                                { ": ", hl = "Comment" },
                                { item.field.type, hl = "Type" },
                            }
                        end,
                        actions = {
                            toggle_select = function(picker, item)
                                if item then
                                    selected_map[item.idx] = not selected_map[item.idx]
                                    picker:refresh()
                                end
                            end,
                            select_all = function(picker)
                                local all = true
                                for _, it in ipairs(items) do
                                    if not selected_map[it.idx] then
                                        all = false
                                        break
                                    end
                                end
                                for _, it in ipairs(items) do
                                    selected_map[it.idx] = not all
                                end
                                picker:refresh()
                            end,
                            confirm_generate = function(picker)
                                local chosen = {}
                                for _, it in ipairs(items) do
                                    if selected_map[it.idx] then
                                        table.insert(chosen, it.field)
                                    end
                                end
                                picker:close()

                                if #chosen == 0 then
                                    vim.notify("No seleccionaste ningún campo", vim.log.levels.WARN)
                                    return
                                end

                                local body = { "" }
                                for _, f in ipairs(chosen) do
                                    local prefix = (f.type == "boolean") and "is" or "get"
                                    local method_name = prefix .. f.name:sub(1, 1):upper() .. f.name:sub(2)
                                    table.insert(body, "    public " .. f.type .. " " .. method_name .. "() {")
                                    table.insert(body, "        return this." .. f.name .. ";")
                                    table.insert(body, "    }")
                                    table.insert(body, "")
                                end
                                if body[#body] == "" then
                                    table.remove(body)
                                end

                                local buf_lines = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)
                                local insert_at = #buf_lines - 1
                                for i = #buf_lines, 1, -1 do
                                    if buf_lines[i]:match("^}") then
                                        insert_at = i - 1
                                        break
                                    end
                                end
                                vim.api.nvim_buf_set_lines(source_buf, insert_at, insert_at, false, body)
                                vim.notify("✓ Getter(s) generados para " .. class_name)
                            end,
                        },
                        win = {
                            input = {
                                keys = {
                                    ["<Space>"] = { "toggle_select", mode = { "n", "i" } },
                                    ["<CR>"] = { "confirm_generate", mode = { "n", "i" } },
                                    ["<C-a>"] = { "select_all", mode = { "n", "i" } },
                                },
                            },
                            list = {
                                keys = {
                                    ["<Space>"] = { "toggle_select" },
                                    ["<CR>"] = { "confirm_generate" },
                                    ["<C-a>"] = { "select_all" },
                                },
                            },
                        },
                        layout = { preset = "select" },
                    })
                end,
            },
            --Setter
            {
                name = "Setter",
                cmd = function()
                    local source_buf = vim.api.nvim_get_current_buf()
                    local parser = vim.treesitter.get_parser(source_buf, "java")
                    local tree = parser:parse()[1]

                    local field_query = vim.treesitter.query.parse(
                        "java",
                        [[
            (field_declaration
                type: (_) @type
                declarator: (variable_declarator name: (identifier) @name))
        ]]
                    )

                    local class_query = vim.treesitter.query.parse(
                        "java",
                        [[
            (class_declaration name: (identifier) @classname)
        ]]
                    )

                    local method_query = vim.treesitter.query.parse(
                        "java",
                        [[
            (method_declaration name: (identifier) @method_name)
        ]]
                    )

                    local existing_methods = {}
                    for _, match in method_query:iter_matches(tree:root(), source_buf, nil, nil, { all = true }) do
                        local node = match[1] and match[1][1]
                        if node then
                            existing_methods[vim.treesitter.get_node_text(node, source_buf)] = true
                        end
                    end

                    local all_fields = {}
                    for _, match in field_query:iter_matches(tree:root(), source_buf, nil, nil, { all = true }) do
                        local type_node = match[1] and match[1][1]
                        local name_node = match[2] and match[2][1]
                        if type_node and name_node then
                            table.insert(all_fields, {
                                type = vim.treesitter.get_node_text(type_node, source_buf),
                                name = vim.treesitter.get_node_text(name_node, source_buf),
                            })
                        end
                    end

                    local fields = {}
                    for _, f in ipairs(all_fields) do
                        local setter_name = "set" .. f.name:sub(1, 1):upper() .. f.name:sub(2)
                        if not existing_methods[setter_name] then
                            table.insert(fields, f)
                        end
                    end

                    if #fields == 0 then
                        vim.notify("✓ Todos los campos ya tienen Setter", vim.log.levels.INFO)
                        return
                    end

                    local class_name = "MyClass"
                    for _, match in class_query:iter_matches(tree:root(), source_buf, nil, nil, { all = true }) do
                        local node = match[1] and match[1][1]
                        if node then
                            class_name = vim.treesitter.get_node_text(node, source_buf)
                            break
                        end
                    end

                    local items = {}
                    for i, f in ipairs(fields) do
                        table.insert(items, {
                            idx = i,
                            text = f.name .. ": " .. f.type,
                            field = f,
                        })
                    end

                    local selected_map = {}

                    Snacks.picker({
                        title = "Generate Setter",
                        items = items,
                        format = function(item)
                            local check = selected_map[item.idx] and " [x] " or " [ ] "
                            return {
                                { check, hl = selected_map[item.idx] and "DiagnosticOk" or "Comment" },
                                { item.field.name, hl = selected_map[item.idx] and "DiagnosticOk" or "Normal" },
                                { ": ", hl = "Comment" },
                                { item.field.type, hl = "Type" },
                            }
                        end,
                        actions = {
                            toggle_select = function(picker, item)
                                if item then
                                    selected_map[item.idx] = not selected_map[item.idx]
                                    picker:refresh()
                                end
                            end,
                            select_all = function(picker)
                                local all = true
                                for _, it in ipairs(items) do
                                    if not selected_map[it.idx] then
                                        all = false
                                        break
                                    end
                                end
                                for _, it in ipairs(items) do
                                    selected_map[it.idx] = not all
                                end
                                picker:refresh()
                            end,
                            confirm_generate = function(picker)
                                local chosen = {}
                                for _, it in ipairs(items) do
                                    if selected_map[it.idx] then
                                        table.insert(chosen, it.field)
                                    end
                                end
                                picker:close()

                                if #chosen == 0 then
                                    vim.notify("No seleccionaste ningún campo", vim.log.levels.WARN)
                                    return
                                end

                                local body = { "" }
                                for _, f in ipairs(chosen) do
                                    local method_name = "set" .. f.name:sub(1, 1):upper() .. f.name:sub(2)
                                    table.insert(
                                        body,
                                        "    public void " .. method_name .. "(" .. f.type .. " " .. f.name .. ") {"
                                    )
                                    table.insert(body, "        this." .. f.name .. " = " .. f.name .. ";")
                                    table.insert(body, "    }")
                                    table.insert(body, "")
                                end
                                if body[#body] == "" then
                                    table.remove(body)
                                end

                                local buf_lines = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)
                                local insert_at = #buf_lines - 1
                                for i = #buf_lines, 1, -1 do
                                    if buf_lines[i]:match("^}") then
                                        insert_at = i - 1
                                        break
                                    end
                                end
                                vim.api.nvim_buf_set_lines(source_buf, insert_at, insert_at, false, body)
                                vim.notify("✓ Setter(s) generados para " .. class_name)
                            end,
                        },
                        win = {
                            input = {
                                keys = {
                                    ["<Space>"] = { "toggle_select", mode = { "n", "i" } },
                                    ["<CR>"] = { "confirm_generate", mode = { "n", "i" } },
                                    ["<C-a>"] = { "select_all", mode = { "n", "i" } },
                                },
                            },
                            list = {
                                keys = {
                                    ["<Space>"] = { "toggle_select" },
                                    ["<CR>"] = { "confirm_generate" },
                                    ["<C-a>"] = { "select_all" },
                                },
                            },
                        },
                        layout = { preset = "select" },
                    })
                end,
            },
            -- Getter and Setter
            {
                name = "Getter and Setter",
                cmd = function()
                    local source_buf = vim.api.nvim_get_current_buf()
                    local parser = vim.treesitter.get_parser(source_buf, "java")
                    local tree = parser:parse()[1]

                    local field_query = vim.treesitter.query.parse(
                        "java",
                        [[
            (field_declaration
                type: (_) @type
                declarator: (variable_declarator name: (identifier) @name))
        ]]
                    )

                    local class_query = vim.treesitter.query.parse(
                        "java",
                        [[
            (class_declaration name: (identifier) @classname)
        ]]
                    )

                    local method_query = vim.treesitter.query.parse(
                        "java",
                        [[
            (method_declaration name: (identifier) @method_name)
        ]]
                    )

                    local existing_methods = {}
                    for _, match in method_query:iter_matches(tree:root(), source_buf, nil, nil, { all = true }) do
                        local node = match[1] and match[1][1]
                        if node then
                            existing_methods[vim.treesitter.get_node_text(node, source_buf)] = true
                        end
                    end

                    local all_fields = {}
                    for _, match in field_query:iter_matches(tree:root(), source_buf, nil, nil, { all = true }) do
                        local type_node = match[1] and match[1][1]
                        local name_node = match[2] and match[2][1]
                        if type_node and name_node then
                            table.insert(all_fields, {
                                type = vim.treesitter.get_node_text(type_node, source_buf),
                                name = vim.treesitter.get_node_text(name_node, source_buf),
                            })
                        end
                    end

                    -- Filtrar campos que NO tienen getter NI setter
                    local fields = {}
                    for _, f in ipairs(all_fields) do
                        local getter_prefix = (f.type == "boolean") and "is" or "get"
                        local getter_name = getter_prefix .. f.name:sub(1, 1):upper() .. f.name:sub(2)
                        local setter_name = "set" .. f.name:sub(1, 1):upper() .. f.name:sub(2)
                        if not existing_methods[getter_name] or not existing_methods[setter_name] then
                            table.insert(fields, {
                                type = f.type,
                                name = f.name,
                                needs_getter = not existing_methods[getter_name],
                                needs_setter = not existing_methods[setter_name],
                            })
                        end
                    end

                    if #fields == 0 then
                        vim.notify("✓ Todos los campos ya tienen Getter y Setter", vim.log.levels.INFO)
                        return
                    end

                    local class_name = "MyClass"
                    for _, match in class_query:iter_matches(tree:root(), source_buf, nil, nil, { all = true }) do
                        local node = match[1] and match[1][1]
                        if node then
                            class_name = vim.treesitter.get_node_text(node, source_buf)
                            break
                        end
                    end

                    local items = {}
                    for i, f in ipairs(fields) do
                        -- indicar en el texto si falta solo getter, solo setter, o ambos
                        local missing = ""
                        if f.needs_getter and f.needs_setter then
                            missing = " [get+set]"
                        elseif f.needs_getter then
                            missing = " [get]"
                        elseif f.needs_setter then
                            missing = " [set]"
                        end
                        table.insert(items, {
                            idx = i,
                            text = f.name .. ": " .. f.type .. missing,
                            field = f,
                            missing = missing,
                        })
                    end

                    local selected_map = {}

                    Snacks.picker({
                        title = "Generate Getter and Setter",
                        items = items,
                        format = function(item)
                            local check = selected_map[item.idx] and " [x] " or " [ ] "
                            return {
                                { check, hl = selected_map[item.idx] and "DiagnosticOk" or "Comment" },
                                { item.field.name, hl = selected_map[item.idx] and "DiagnosticOk" or "Normal" },
                                { ": ", hl = "Comment" },
                                { item.field.type, hl = "Type" },
                                { item.missing, hl = "WarningMsg" },
                            }
                        end,
                        actions = {
                            toggle_select = function(picker, item)
                                if item then
                                    selected_map[item.idx] = not selected_map[item.idx]
                                    picker:refresh()
                                end
                            end,
                            select_all = function(picker)
                                local all = true
                                for _, it in ipairs(items) do
                                    if not selected_map[it.idx] then
                                        all = false
                                        break
                                    end
                                end
                                for _, it in ipairs(items) do
                                    selected_map[it.idx] = not all
                                end
                                picker:refresh()
                            end,
                            confirm_generate = function(picker)
                                local chosen = {}
                                for _, it in ipairs(items) do
                                    if selected_map[it.idx] then
                                        table.insert(chosen, it.field)
                                    end
                                end
                                picker:close()

                                if #chosen == 0 then
                                    vim.notify("No seleccionaste ningún campo", vim.log.levels.WARN)
                                    return
                                end

                                local body = { "" }
                                for _, f in ipairs(chosen) do
                                    if f.needs_getter then
                                        local getter_prefix = (f.type == "boolean") and "is" or "get"
                                        local getter_name = getter_prefix .. f.name:sub(1, 1):upper() .. f.name:sub(2)
                                        table.insert(body, "    public " .. f.type .. " " .. getter_name .. "() {")
                                        table.insert(body, "        return this." .. f.name .. ";")
                                        table.insert(body, "    }")
                                        table.insert(body, "")
                                    end
                                    if f.needs_setter then
                                        local setter_name = "set" .. f.name:sub(1, 1):upper() .. f.name:sub(2)
                                        table.insert(
                                            body,
                                            "    public void " .. setter_name .. "(" .. f.type .. " " .. f.name .. ") {"
                                        )
                                        table.insert(body, "        this." .. f.name .. " = " .. f.name .. ";")
                                        table.insert(body, "    }")
                                        table.insert(body, "")
                                    end
                                end
                                if body[#body] == "" then
                                    table.remove(body)
                                end

                                local buf_lines = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)
                                local insert_at = #buf_lines - 1
                                for i = #buf_lines, 1, -1 do
                                    if buf_lines[i]:match("^}") then
                                        insert_at = i - 1
                                        break
                                    end
                                end
                                vim.api.nvim_buf_set_lines(source_buf, insert_at, insert_at, false, body)
                                vim.notify("✓ Getter(s) y Setter(s) generados para " .. class_name)
                            end,
                        },
                        win = {
                            input = {
                                keys = {
                                    ["<Space>"] = { "toggle_select", mode = { "n", "i" } },
                                    ["<CR>"] = { "confirm_generate", mode = { "n", "i" } },
                                    ["<C-a>"] = { "select_all", mode = { "n", "i" } },
                                },
                            },
                            list = {
                                keys = {
                                    ["<Space>"] = { "toggle_select" },
                                    ["<CR>"] = { "confirm_generate" },
                                    ["<C-a>"] = { "select_all" },
                                },
                            },
                        },
                        layout = { preset = "select" },
                    })
                end,
            },
            -- equals and hashcode
            {
                name = "equals() and hashCode()",
                cmd = function()
                    local source_buf = vim.api.nvim_get_current_buf()
                    local parser = vim.treesitter.get_parser(source_buf, "java")
                    local tree = parser:parse()[1]

                    local field_query = vim.treesitter.query.parse(
                        "java",
                        [[
            (field_declaration
                type: (_) @type
                declarator: (variable_declarator name: (identifier) @name))
        ]]
                    )

                    local class_query = vim.treesitter.query.parse(
                        "java",
                        [[
            (class_declaration name: (identifier) @classname)
        ]]
                    )

                    local method_query = vim.treesitter.query.parse(
                        "java",
                        [[
            (method_declaration name: (identifier) @method_name)
        ]]
                    )

                    local existing_methods = {}
                    for _, match in method_query:iter_matches(tree:root(), source_buf, nil, nil, { all = true }) do
                        local node = match[1] and match[1][1]
                        if node then
                            existing_methods[vim.treesitter.get_node_text(node, source_buf)] = true
                        end
                    end

                    if existing_methods["equals"] and existing_methods["hashCode"] then
                        vim.notify("✓ equals() y hashCode() ya existen en la clase", vim.log.levels.INFO)
                        return
                    end

                    local all_fields = {}
                    for _, match in field_query:iter_matches(tree:root(), source_buf, nil, nil, { all = true }) do
                        local type_node = match[1] and match[1][1]
                        local name_node = match[2] and match[2][1]
                        if type_node and name_node then
                            table.insert(all_fields, {
                                type = vim.treesitter.get_node_text(type_node, source_buf),
                                name = vim.treesitter.get_node_text(name_node, source_buf),
                            })
                        end
                    end

                    if #all_fields == 0 then
                        vim.notify("No se encontraron campos en la clase", vim.log.levels.WARN)
                        return
                    end

                    local class_name = "MyClass"
                    for _, match in class_query:iter_matches(tree:root(), source_buf, nil, nil, { all = true }) do
                        local node = match[1] and match[1][1]
                        if node then
                            class_name = vim.treesitter.get_node_text(node, source_buf)
                            break
                        end
                    end

                    local items = {}
                    for i, f in ipairs(all_fields) do
                        table.insert(items, {
                            idx = i,
                            text = f.name .. ": " .. f.type,
                            field = f,
                        })
                    end

                    local selected_map = {}

                    Snacks.picker({
                        title = "Generate equals() and hashCode()",
                        items = items,
                        format = function(item)
                            local check = selected_map[item.idx] and " [x] " or " [ ] "
                            return {
                                { check, hl = selected_map[item.idx] and "DiagnosticOk" or "Comment" },
                                { item.field.name, hl = selected_map[item.idx] and "DiagnosticOk" or "Normal" },
                                { ": ", hl = "Comment" },
                                { item.field.type, hl = "Type" },
                            }
                        end,
                        actions = {
                            toggle_select = function(picker, item)
                                if item then
                                    selected_map[item.idx] = not selected_map[item.idx]
                                    picker:refresh()
                                end
                            end,
                            select_all = function(picker)
                                local all = true
                                for _, it in ipairs(items) do
                                    if not selected_map[it.idx] then
                                        all = false
                                        break
                                    end
                                end
                                for _, it in ipairs(items) do
                                    selected_map[it.idx] = not all
                                end
                                picker:refresh()
                            end,
                            confirm_generate = function(picker)
                                local chosen = {}
                                for _, it in ipairs(items) do
                                    if selected_map[it.idx] then
                                        table.insert(chosen, it.field)
                                    end
                                end
                                picker:close()

                                if #chosen == 0 then
                                    vim.notify("No seleccionaste ningún campo", vim.log.levels.WARN)
                                    return
                                end

                                local body = { "" }

                                -- equals()
                                if not existing_methods["equals"] then
                                    local var_name = class_name:sub(1, 1):lower() .. class_name:sub(2)
                                    table.insert(body, "    @Override")
                                    table.insert(body, "    public boolean equals(Object o) {")
                                    table.insert(
                                        body,
                                        "        if (o == null || getClass() != o.getClass()) return false;"
                                    )
                                    table.insert(
                                        body,
                                        "        " .. class_name .. " " .. var_name .. " = (" .. class_name .. ") o;"
                                    )

                                    local conditions = {}
                                    for _, f in ipairs(chosen) do
                                        if f.type == "double" then
                                            table.insert(
                                                conditions,
                                                "Double.compare("
                                                    .. f.name
                                                    .. ", "
                                                    .. var_name
                                                    .. "."
                                                    .. f.name
                                                    .. ") == 0"
                                            )
                                        elseif f.type == "float" then
                                            table.insert(
                                                conditions,
                                                "Float.compare("
                                                    .. f.name
                                                    .. ", "
                                                    .. var_name
                                                    .. "."
                                                    .. f.name
                                                    .. ") == 0"
                                            )
                                        elseif
                                            f.type == "int"
                                            or f.type == "long"
                                            or f.type == "boolean"
                                            or f.type == "char"
                                            or f.type == "byte"
                                            or f.type == "short"
                                        then
                                            table.insert(conditions, f.name .. " == " .. var_name .. "." .. f.name)
                                        else
                                            table.insert(
                                                conditions,
                                                "Objects.equals(" .. f.name .. ", " .. var_name .. "." .. f.name .. ")"
                                            )
                                        end
                                    end

                                    table.insert(body, "        return " .. table.concat(conditions, " && ") .. ";")
                                    table.insert(body, "    }")
                                    table.insert(body, "")
                                end

                                -- hashCode()
                                if not existing_methods["hashCode"] then
                                    local hash_fields = {}
                                    for _, f in ipairs(chosen) do
                                        table.insert(hash_fields, f.name)
                                    end
                                    table.insert(body, "    @Override")
                                    table.insert(body, "    public int hashCode() {")
                                    table.insert(
                                        body,
                                        "        return Objects.hash(" .. table.concat(hash_fields, ", ") .. ");"
                                    )
                                    table.insert(body, "    }")
                                    table.insert(body, "")
                                end

                                if body[#body] == "" then
                                    table.remove(body)
                                end

                                local buf_lines = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)
                                local insert_at = #buf_lines - 1
                                for i = #buf_lines, 1, -1 do
                                    if buf_lines[i]:match("^}") then
                                        insert_at = i - 1
                                        break
                                    end
                                end
                                vim.api.nvim_buf_set_lines(source_buf, insert_at, insert_at, false, body)

                                local has_import = false
                                for _, line in ipairs(buf_lines) do
                                    if line:match("import java%.util%.Objects") then
                                        has_import = true
                                        break
                                    end
                                end
                                if not has_import then
                                    local import_line = 0
                                    for i, line in ipairs(buf_lines) do
                                        if line:match("^import ") then
                                            import_line = i
                                        end
                                    end
                                    vim.api.nvim_buf_set_lines(
                                        source_buf,
                                        import_line,
                                        import_line,
                                        false,
                                        { "import java.util.Objects;" }
                                    )
                                end

                                vim.notify("✓ equals() y hashCode() generados para " .. class_name)
                            end,
                        },
                        win = {
                            input = {
                                keys = {
                                    ["<Space>"] = { "toggle_select", mode = { "n", "i" } },
                                    ["<CR>"] = { "confirm_generate", mode = { "n", "i" } },
                                    ["<C-a>"] = { "select_all", mode = { "n", "i" } },
                                },
                            },
                            list = {
                                keys = {
                                    ["<Space>"] = { "toggle_select" },
                                    ["<CR>"] = { "confirm_generate" },
                                    ["<C-a>"] = { "select_all" },
                                },
                            },
                        },
                        layout = { preset = "select" },
                    })
                end,
            },
            -- toString
            {
                name = "toString()",
                cmd = function()
                    local source_buf = vim.api.nvim_get_current_buf()
                    local parser = vim.treesitter.get_parser(source_buf, "java")
                    local tree = parser:parse()[1]

                    local field_query = vim.treesitter.query.parse(
                        "java",
                        [[
            (field_declaration
                type: (_) @type
                declarator: (variable_declarator name: (identifier) @name))
        ]]
                    )

                    local class_query = vim.treesitter.query.parse(
                        "java",
                        [[
            (class_declaration name: (identifier) @classname)
        ]]
                    )

                    local method_body_query = vim.treesitter.query.parse(
                        "java",
                        [[
            (method_declaration
                name: (identifier) @method_name
                body: (block) @body)
        ]]
                    )

                    -- Detectar si toString ya existe y su ubicación
                    local toString_start = nil
                    local toString_end = nil
                    for _, match in method_body_query:iter_matches(tree:root(), source_buf, nil, nil, { all = true }) do
                        local name_node = match[1] and match[1][1]
                        local body_node = match[2] and match[2][1]
                        if name_node and body_node then
                            if vim.treesitter.get_node_text(name_node, source_buf) == "toString" then
                                toString_start = body_node:start()
                                toString_end = body_node:end_()
                                break
                            end
                        end
                    end

                    local all_fields = {}
                    for _, match in field_query:iter_matches(tree:root(), source_buf, nil, nil, { all = true }) do
                        local type_node = match[1] and match[1][1]
                        local name_node = match[2] and match[2][1]
                        if type_node and name_node then
                            table.insert(all_fields, {
                                type = vim.treesitter.get_node_text(type_node, source_buf),
                                name = vim.treesitter.get_node_text(name_node, source_buf),
                            })
                        end
                    end

                    if #all_fields == 0 then
                        vim.notify("No se encontraron campos en la clase", vim.log.levels.WARN)
                        return
                    end

                    local class_name = "MyClass"
                    for _, match in class_query:iter_matches(tree:root(), source_buf, nil, nil, { all = true }) do
                        local node = match[1] and match[1][1]
                        if node then
                            class_name = vim.treesitter.get_node_text(node, source_buf)
                            break
                        end
                    end

                    -- Detectar campos ya presentes en toString existente
                    local buf_lines = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)
                    local fields_in_tostring = {}
                    if toString_start then
                        for i = toString_start, toString_end do
                            local line = buf_lines[i + 1] or ""
                            for _, f in ipairs(all_fields) do
                                local escaped = f.name:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
                                if
                                    line:match('"' .. escaped .. "=")
                                    or line:match('"' .. escaped .. "='")
                                    or line:match(", " .. escaped .. "=")
                                    or line:match(", " .. escaped .. "='")
                                then
                                    fields_in_tostring[f.name] = true
                                end
                            end
                        end
                    end

                    -- Solo mostrar campos que faltan
                    local items = {}
                    for i, f in ipairs(all_fields) do
                        if not fields_in_tostring[f.name] then
                            table.insert(items, {
                                idx = i,
                                text = f.name .. ": " .. f.type,
                                field = f,
                            })
                        end
                    end

                    if #items == 0 then
                        vim.notify("✓ Todos los campos ya están en toString()", vim.log.levels.INFO)
                        return
                    end

                    local selected_map = {}

                    Snacks.picker({
                        title = "Generate toString()",
                        items = items,
                        format = function(item)
                            local check = selected_map[item.idx] and " [x] " or " [ ] "
                            return {
                                { check, hl = selected_map[item.idx] and "DiagnosticOk" or "Comment" },
                                { item.field.name, hl = selected_map[item.idx] and "DiagnosticOk" or "Normal" },
                                { ": ", hl = "Comment" },
                                { item.field.type, hl = "Type" },
                            }
                        end,
                        actions = {
                            toggle_select = function(picker, item)
                                if item then
                                    selected_map[item.idx] = not selected_map[item.idx]
                                    picker:refresh()
                                end
                            end,
                            select_all = function(picker)
                                local all = true
                                for _, it in ipairs(items) do
                                    if not selected_map[it.idx] then
                                        all = false
                                        break
                                    end
                                end
                                for _, it in ipairs(items) do
                                    selected_map[it.idx] = not all
                                end
                                picker:refresh()
                            end,
                            confirm_generate = function(picker)
                                local chosen = {}
                                for _, it in ipairs(items) do
                                    if selected_map[it.idx] then
                                        table.insert(chosen, it.field)
                                    end
                                end
                                picker:close()

                                if #chosen == 0 then
                                    vim.notify("No seleccionaste ningún campo", vim.log.levels.WARN)
                                    return
                                end

                                buf_lines = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)

                                if toString_start then
                                    -- toString existe — insertar campos antes del cierre '}';
                                    local close_line = nil
                                    for i = toString_start + 1, toString_end + 1 do
                                        if buf_lines[i] and buf_lines[i]:match("'}'") then
                                            close_line = i
                                            break
                                        end
                                    end

                                    if close_line then
                                        local new_lines = {}
                                        for _, f in ipairs(chosen) do
                                            local part
                                            if f.type == "String" then
                                                part = '                ", '
                                                    .. f.name
                                                    .. "='\" + "
                                                    .. f.name
                                                    .. " + '\\'' +"
                                            else
                                                part = '                ", ' .. f.name .. '=" + ' .. f.name .. " +"
                                            end
                                            table.insert(new_lines, part)
                                        end
                                        vim.api.nvim_buf_set_lines(
                                            source_buf,
                                            close_line - 1,
                                            close_line - 1,
                                            false,
                                            new_lines
                                        )
                                        vim.notify("✓ toString() actualizado para " .. class_name)
                                    end
                                else
                                    -- toString no existe — crear desde cero
                                    local body = { "" }
                                    table.insert(body, "    @Override")
                                    table.insert(body, "    public String toString() {")
                                    table.insert(body, '        return "' .. class_name .. '{" +')

                                    for i, f in ipairs(chosen) do
                                        local prefix = i == 1 and "" or ", "
                                        local part
                                        if f.type == "String" then
                                            part = '                "'
                                                .. prefix
                                                .. f.name
                                                .. "='\" + "
                                                .. f.name
                                                .. " + '\\'' +"
                                        else
                                            part = '                "' .. prefix .. f.name .. '=" + ' .. f.name .. " +"
                                        end
                                        table.insert(body, part)
                                    end

                                    table.insert(body, "                '}';")
                                    table.insert(body, "    }")

                                    local insert_at = #buf_lines - 1
                                    for i = #buf_lines, 1, -1 do
                                        if buf_lines[i]:match("^}") then
                                            insert_at = i - 1
                                            break
                                        end
                                    end
                                    vim.api.nvim_buf_set_lines(source_buf, insert_at, insert_at, false, body)
                                    vim.notify("✓ toString() generado para " .. class_name)
                                end
                            end,
                        },
                        win = {
                            input = {
                                keys = {
                                    ["<Space>"] = { "toggle_select", mode = { "n", "i" } },
                                    ["<CR>"] = { "confirm_generate", mode = { "n", "i" } },
                                    ["<C-a>"] = { "select_all", mode = { "n", "i" } },
                                },
                            },
                            list = {
                                keys = {
                                    ["<Space>"] = { "toggle_select" },
                                    ["<CR>"] = { "confirm_generate" },
                                    ["<C-a>"] = { "select_all" },
                                },
                            },
                        },
                        layout = { preset = "select" },
                    })
                end,
            },
            { name = "separator" },
            {
                name = "Override Methods...",
                cmd = function()
                    vim.lsp.buf.code_action({
                        filter = function(a)
                            return a.title:lower():match("override")
                        end,
                        apply = true,
                    })
                end,
            },
            {
                name = "Delegate Methods...",
                cmd = function()
                    vim.lsp.buf.code_action({
                        filter = function(a)
                            return a.title:lower():match("delegate")
                        end,
                        apply = true,
                    })
                end,
            },
            { name = "separator" },
            {
                name = "Test...",
                cmd = function()
                    require("jdtls").test_class()
                end,
            },
            { name = "separator" },
            {
                name = "Copyright",
                cmd = function()
                    local fname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
                    local header = "// Copyright (c) " .. os.date("%Y") .. "\n// File: " .. fname .. "\n\n"
                    vim.api.nvim_buf_set_lines(0, 0, 0, false, vim.split(header, "\n"))
                end,
            },
        },
    },
    { name = "separator", condition = has_main_method },
    {
        name = "  Run 'Main.main()'",
        hl = "ExGreen",
        condition = has_main_method,
        cmd = function()
            local cwd = vim.fn.getcwd()
            local current_file = vim.fn.expand("%:t:r")
            local project_name = vim.fn.fnamemodify(cwd, ":t")
            local out_dir = "out/production/" .. project_name
            -- Detecta si la clase tiene package
            local lines = vim.api.nvim_buf_get_lines(0, 0, 10, false)
            local package_name = nil
            for _, line in ipairs(lines) do
                local pkg = line:match("^package%s+([%w%.]+)%s*;")
                if pkg then
                    package_name = pkg
                    break
                end
            end
            -- Si tiene package lo incluye, si no lo omite
            local class_path = package_name and (package_name .. "." .. current_file) or current_file
            local java_cmd = "clear; cd '"
                .. cwd
                .. "' && javac -d "
                .. out_dir
                .. " $(find src -name '*.java') && java -cp "
                .. out_dir
                .. " "
                .. class_path
                .. "; "
                .. 'code=$?; echo; echo "Process finished with exit code $code"; read'
            local Terminal = require("toggleterm.terminal").Terminal
            local run_term = Terminal:new({
                cmd = java_cmd,
                hidden = true,
                direction = "float",
                close_on_exit = false,
                display_name = "Run " .. current_file,
                float_opts = {
                    border = "curved",
                    width = math.floor(vim.o.columns * 0.85),
                    height = math.floor(vim.o.lines * 0.80),
                },
            })
            run_term:toggle()
        end,
        rtxt = "Ctrl+Shift+F10",
    },
    {
        name = "  Debug 'Main.main()'",
        hl = "ExRed",
        condition = has_main_method,
        cmd = function()
            require("dap").continue()
        end,
    },
    {
        name = "  More Run/Debug",
        condition = has_main_method,
        items = {
            {
                name = "Run with Arguments",
                cmd = function()
                    local cwd = vim.fn.getcwd()
                    local args = vim.fn.input("Program arguments: ", "")
                    require("snacks").terminal({
                        "bash",
                        "-c",
                        "cd '"
                            .. cwd
                            .. "' && mkdir -p out && javac src/*.java -d out"
                            .. " && java -cp out Main "
                            .. args
                            .. "; echo; echo '--- Process finished ---'; read",
                    }, { win = { position = "bottom", height = 0.3 } })
                end,
            },
            {
                name = "Debug with Arguments",
                cmd = function()
                    local args_str = vim.fn.input("Debug arguments: ", "")
                    local args = vim.split(args_str, " ", { trimempty = true })
                    local dap = require("dap")
                    local cfgs = dap.configurations.java
                    if cfgs and #cfgs > 0 then
                        local cfg = vim.deepcopy(cfgs[1])
                        cfg.args = args
                        dap.run(cfg)
                    else
                        require("jdtls").start_debugging()
                    end
                end,
            },
            {
                name = "Run Tests",
                cmd = function()
                    require("jdtls").test_class()
                end,
            },
            {
                name = "Debug Tests",
                cmd = function()
                    require("jdtls").test_nearest_method()
                end,
            },
            {
                name = "Stop",
                cmd = function()
                    require("dap").terminate()
                    pcall(require("dapui").close)
                end,
            },
        },
    },
    { name = "separator", condition = has_main_method },
    {
        name = "  Open In",
        items = {
            {
                name = "Terminal",
                cmd = function()
                    local dir = vim.fn.fnamemodify(get_bufname(), ":h")
                    vim.cmd("enew")
                    vim.fn.termopen({ vim.o.shell, "-c", "cd " .. dir .. " ; " .. vim.o.shell })
                end,
            },
            {
                name = "File Manager",
                cmd = function()
                    local dir = vim.fn.fnamemodify(get_bufname(), ":h")
                    vim.fn.system("xdg-open " .. dir)
                end,
            },
        },
    },
    {
        name = "  Local History",
        items = {
            {
                name = "Show History",
                cmd = function()
                    vim.cmd("Git log --follow " .. get_bufname())
                end,
            },
            {
                name = "Put Active Changelist",
                cmd = function()
                    vim.cmd("Git diff HEAD")
                end,
            },
        },
    },
    { name = "separator" },
    {
        name = "  Compare with Clipboard",
        cmd = function()
            local clipboard = vim.fn.getreg("+")
            local tmp = vim.fn.tempname()
            local f = io.open(tmp, "w")
            if f then
                f:write(clipboard)
                f:close()
            end
            vim.cmd("diffsplit " .. tmp)
        end,
        rtxt = "Ctrl+K, C",
    },
    {
        name = "  Create Gist...",
        cmd = function()
            vim.cmd("%y+")
            vim.notify("Content copied — paste to gist.github.com")
        end,
    },
}

local dart_items = {
    {
        name = "  Go to Definition",
        cmd = vim.lsp.buf.definition,
        rtxt = "F12",
    },
    {
        name = "  Go to Type Definition",
        cmd = vim.lsp.buf.type_definition,
    },
    {
        name = "  Go to Implementations",
        cmd = vim.lsp.buf.implementation,
        rtxt = "Ctrl+F12",
    },
    {
        name = "  Go to References",
        cmd = vim.lsp.buf.references,
        rtxt = "Shift+F12",
    },
    {
        name = "  Peek",
        items = {
            { name = "Peek Definition", cmd = vim.lsp.buf.definition, rtxt = "Alt+F12" },
            { name = "Peek Type Definition", cmd = vim.lsp.buf.type_definition },
            { name = "Peek Implementations", cmd = vim.lsp.buf.implementation },
            { name = "Peek References", cmd = vim.lsp.buf.references },
        },
    },
    { name = "separator" },
    {
        name = "  Find All References",
        cmd = vim.lsp.buf.references,
        rtxt = "Shift+Alt+F12",
    },
    {
        name = "  Find All Implementations",
        cmd = vim.lsp.buf.implementation,
    },
    {
        name = "  Show Call Hierarchy",
        cmd = vim.lsp.buf.incoming_calls,
        rtxt = "Shift+Alt+H",
    },
    { name = "separator" },
    {
        name = "  Rename Symbol",
        cmd = vim.lsp.buf.rename,
        rtxt = "F2",
    },
    {
        name = "  Change All Occurrences",
        cmd = vim.lsp.buf.rename,
        rtxt = "Ctrl+F2",
    },
    {
        name = "  Format Document",
        cmd = function()
            local ok, conform = pcall(require, "conform")
            if ok then
                conform.format({ lsp_fallback = true })
            else
                vim.lsp.buf.format()
            end
        end,
        rtxt = "Shift+Alt+F",
    },
    { name = "separator", condition = has_dart_main },
    {
        name = "  Run Dart",
        hl = "ExGreen",
        condition = has_dart_main,
        cmd = function()
            local cwd = vim.fn.getcwd()
            local dart_cmd = "clear; cd '"
                .. cwd
                .. "' && dart run; "
                .. 'code=$?; echo; echo "Process finished with exit code $code"; read'
            local Terminal = require("toggleterm.terminal").Terminal
            local run_term = Terminal:new({
                cmd = dart_cmd,
                hidden = true,
                direction = "float",
                close_on_exit = false,
                display_name = "Run Dart",
                float_opts = {
                    border = "curved",
                    width = math.floor(vim.o.columns * 0.85),
                    height = math.floor(vim.o.lines * 0.80),
                },
            })
            run_term:toggle()
        end,
        rtxt = "Ctrl+Shift+F10",
    },
    {
        name = "  Debug Dart",
        hl = "ExRed",
        condition = has_dart_main,
        cmd = function()
            require("dap").continue()
        end,
    },
    {
        name = "  Code Actions",
        cmd = vim.lsp.buf.code_action,
        rtxt = "Ctrl+.",
    },
    {
        name = "  Refactor...",
        cmd = vim.lsp.buf.code_action,
        rtxt = "Ctrl+Shift+R",
    },
    { name = "separator" },
    {
        name = "  Analyze",
        items = {
            {
                name = "Inspect Code",
                cmd = vim.lsp.buf.code_action,
            },
            {
                name = "Show Error Description",
                cmd = vim.diagnostic.open_float,
            },
            {
                name = "Next Problem",
                cmd = function()
                    vim.diagnostic.goto_next()
                end,
                rtxt = "F8",
            },
            {
                name = "Previous Problem",
                cmd = function()
                    vim.diagnostic.goto_prev()
                end,
                rtxt = "Shift+F8",
            },
        },
    },
    {
        name = "  Folding",
        items = {
            {
                name = "Expand",
                cmd = function()
                    vim.cmd("normal! zo")
                end,
            },
            {
                name = "Collapse",
                cmd = function()
                    vim.cmd("normal! zc")
                end,
            },
            {
                name = "Expand All",
                cmd = function()
                    vim.cmd("normal! zR")
                end,
            },
            {
                name = "Collapse All",
                cmd = function()
                    vim.cmd("normal! zM")
                end,
            },
        },
    },
    { name = "separator" },
    {
        name = "  Cut",
        cmd = function()
            vim.cmd('normal! "+d')
        end,
        rtxt = "Ctrl+X",
    },
    {
        name = "  Copy",
        cmd = function()
            vim.cmd('normal! "+y')
        end,
        rtxt = "Ctrl+C",
    },
    {
        name = "  Copy As",
        items = {
            {
                name = "Copy Relative Path",
                cmd = function()
                    local rel = vim.fn.fnamemodify(get_bufname(), ":~:.")
                    vim.fn.setreg("+", rel)
                    vim.notify("Copied: " .. rel)
                end,
            },
            {
                name = "Copy Absolute Path",
                cmd = function()
                    vim.fn.setreg("+", get_bufname())
                    vim.notify("Copied: " .. get_bufname())
                end,
            },
        },
    },
    {
        name = "  Paste",
        cmd = function()
            vim.cmd('normal! "+p')
        end,
        rtxt = "Ctrl+V",
    },
    { name = "separator" },
    {
        name = "  Open In",
        items = {
            {
                name = "Terminal",
                cmd = function()
                    local dir = vim.fn.fnamemodify(get_bufname(), ":h")
                    vim.cmd("enew")
                    vim.fn.termopen({ vim.o.shell, "-c", "cd " .. dir .. " ; " .. vim.o.shell })
                end,
            },
        },
    },
    {
        name = "  Compare with Clipboard",
        cmd = function()
            local clipboard = vim.fn.getreg("+")
            local tmp = vim.fn.tempname()
            local f = io.open(tmp, "w")
            if f then
                f:write(clipboard)
                f:close()
            end
            vim.cmd("diffsplit " .. tmp)
        end,
        rtxt = "Ctrl+K, C",
    },
}

local python_items = {
    {
        name = "  Go to Definition",
        cmd = vim.lsp.buf.definition,
        rtxt = "F12",
    },
    {
        name = "  Go to Declaration",
        cmd = vim.lsp.buf.declaration,
    },
    {
        name = "  Go to Type Definition",
        cmd = vim.lsp.buf.type_definition,
    },
    {
        name = "  Go to Implementations",
        cmd = vim.lsp.buf.implementation,
        rtxt = "Ctrl+F12",
    },
    {
        name = "  Go to References",
        cmd = vim.lsp.buf.references,
        rtxt = "Shift+F12",
    },
    {
        name = "  Peek",
        items = {
            { name = "Peek Definition", cmd = vim.lsp.buf.definition, rtxt = "Alt+F12" },
            { name = "Peek Type Definition", cmd = vim.lsp.buf.type_definition },
            { name = "Peek Implementations", cmd = vim.lsp.buf.implementation },
            { name = "Peek References", cmd = vim.lsp.buf.references },
        },
    },
    { name = "separator" },
    {
        name = "  Find All References",
        cmd = vim.lsp.buf.references,
        rtxt = "Shift+Alt+F12",
    },
    {
        name = "  Find All Implementations",
        cmd = vim.lsp.buf.implementation,
    },
    {
        name = "  Show Call Hierarchy",
        cmd = vim.lsp.buf.incoming_calls,
        rtxt = "Shift+Alt+H",
    },
    {
        name = "  Show Type Hierarchy",
        cmd = vim.lsp.buf.type_definition,
    },
    { name = "separator" },
    {
        name = "  Rename Symbol",
        cmd = vim.lsp.buf.rename,
        rtxt = "F2",
    },
    {
        name = "  Change All Occurrences",
        cmd = vim.lsp.buf.rename,
        rtxt = "Ctrl+F2",
    },
    {
        name = "  Format Document",
        cmd = function()
            local ok, conform = pcall(require, "conform")
            if ok then
                conform.format({ lsp_fallback = true })
            else
                vim.lsp.buf.format()
            end
        end,
        rtxt = "Shift+Alt+F",
    },
    {
        name = "  Refactor...",
        cmd = vim.lsp.buf.code_action,
        rtxt = "Ctrl+Shift+R",
    },
    {
        name = "  Source Action...",
        cmd = vim.lsp.buf.code_action,
    },
    { name = "separator" },
    {
        name = "  Analyze",
        items = {
            {
                name = "Inspect Code",
                cmd = vim.lsp.buf.code_action,
            },
            {
                name = "Show Error Description",
                cmd = vim.diagnostic.open_float,
            },
            {
                name = "Next Problem",
                cmd = function()
                    vim.diagnostic.goto_next()
                end,
                rtxt = "F8",
            },
            {
                name = "Previous Problem",
                cmd = function()
                    vim.diagnostic.goto_prev()
                end,
                rtxt = "Shift+F8",
            },
        },
    },
    {
        name = "  Folding",
        items = {
            {
                name = "Expand",
                cmd = function()
                    vim.cmd("normal! zo")
                end,
            },
            {
                name = "Collapse",
                cmd = function()
                    vim.cmd("normal! zc")
                end,
            },
            {
                name = "Expand All",
                cmd = function()
                    vim.cmd("normal! zR")
                end,
            },
            {
                name = "Collapse All",
                cmd = function()
                    vim.cmd("normal! zM")
                end,
            },
        },
    },
    { name = "separator" },
    {
        name = "  Cut",
        cmd = function()
            vim.cmd('normal! "+d')
        end,
        rtxt = "Ctrl+X",
    },
    {
        name = "  Copy",
        cmd = function()
            vim.cmd('normal! "+y')
        end,
        rtxt = "Ctrl+C",
    },
    {
        name = "  Copy As",
        items = {
            {
                name = "Copy Relative Path",
                cmd = function()
                    local rel = vim.fn.fnamemodify(get_bufname(), ":~:.")
                    vim.fn.setreg("+", rel)
                    vim.notify("Copied: " .. rel)
                end,
            },
            {
                name = "Copy Absolute Path",
                cmd = function()
                    vim.fn.setreg("+", get_bufname())
                    vim.notify("Copied: " .. get_bufname())
                end,
            },
        },
    },
    {
        name = "  Paste",
        cmd = function()
            vim.cmd('normal! "+p')
        end,
        rtxt = "Ctrl+V",
    },
    { name = "separator" },
    {
        name = "  Run Python",
        hl = "ExGreen",
        items = {
            {
                name = "Run Python File in Terminal",
                cmd = function()
                    local cwd = vim.fn.getcwd()
                    local filepath = vim.fn.expand("%:p")
                    local python_cmd = "clear; cd '"
                        .. cwd
                        .. "' && python3 '"
                        .. filepath
                        .. "'; "
                        .. 'code=$?; echo; echo "Process finished with exit code $code"; read'
                    local Terminal = require("toggleterm.terminal").Terminal
                    local run_term = Terminal:new({
                        cmd = python_cmd,
                        hidden = true,
                        direction = "float",
                        close_on_exit = false,
                        display_name = "Run Python",
                        float_opts = {
                            border = "curved",
                            width = math.floor(vim.o.columns * 0.85),
                            height = math.floor(vim.o.lines * 0.80),
                        },
                    })
                    run_term:toggle()
                end,
                rtxt = "Ctrl+Shift+F10",
            },
            {
                name = "Run Selection/Line in Terminal",
                cmd = function()
                    local mode = vim.fn.mode()
                    local text
                    if mode == "v" or mode == "V" then
                        local start = vim.fn.getpos("'<")
                        local finish = vim.fn.getpos("'>")
                        local lines = vim.api.nvim_buf_get_lines(0, start[2] - 1, finish[2], false)
                        text = table.concat(lines, "\n")
                    else
                        text = vim.api.nvim_get_current_line()
                    end
                    local Terminal = require("toggleterm.terminal").Terminal
                    local run_term = Terminal:new({
                        cmd = "clear; python3 -c '" .. text:gsub("'", "'\\''") .. "'; read",
                        hidden = true,
                        direction = "float",
                        close_on_exit = false,
                        display_name = "Run Selection",
                        float_opts = {
                            border = "curved",
                            width = math.floor(vim.o.columns * 0.85),
                            height = math.floor(vim.o.lines * 0.80),
                        },
                    })
                    run_term:toggle()
                end,
                rtxt = "Shift+Enter",
            },
        },
    },
    { name = "separator" },
    {
        name = "  Compare with Clipboard",
        cmd = function()
            local clipboard = vim.fn.getreg("+")
            local tmp = vim.fn.tempname()
            local f = io.open(tmp, "w")
            if f then
                f:write(clipboard)
                f:close()
            end
            vim.cmd("diffsplit " .. tmp)
        end,
        rtxt = "Ctrl+K, C",
    },
}

local ok, ft = pcall(get_ft)
if ok and ft == "html" then
    return html_items
elseif ok and ft == "css" then
    return css_items
elseif ok and (ft == "javascript" or ft == "javascriptreact" or ft == "typescript" or ft == "typescriptreact") then
    return javascript_items
elseif ok and ft == "java" then
    return java_items
elseif ok and ft == "dart" then
    return dart_items
elseif ok and ft == "python" then
    return python_items
else
    return default_items
end
