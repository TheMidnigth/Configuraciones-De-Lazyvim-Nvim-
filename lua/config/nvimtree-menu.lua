local api = require("nvim-tree.api")
local node = api.tree.get_node_under_cursor

-- ── Detección de contexto Java src ────────────────────────────────
local function is_java_src_context()
    local n = node()
    if not n or not n.absolute_path then
        return false
    end

    local path = n.absolute_path

    -- Debe contener /src o ser la carpeta src
    if not path:match("/src") then
        return false
    end

    -- Subir hasta 6 niveles buscando marcadores de proyecto Java
    local check = path
    for _ = 1, 6 do
        check = vim.fn.fnamemodify(check, ":h")
        if check == "/" then
            break
        end

        -- IntelliJ: busca cualquier archivo .iml
        local iml = vim.fn.glob(check .. "/*.iml")
        if iml ~= "" then
            return true
        end

        -- Maven / Gradle por si acaso
        if
            vim.fn.filereadable(check .. "/pom.xml") == 1
            or vim.fn.filereadable(check .. "/build.gradle") == 1
            or vim.fn.filereadable(check .. "/build.gradle.kts") == 1
        then
            return true
        end
    end

    return false
end

if is_java_src_context() then
    local java_menu = require("config.java-src-menu") -- ← ruta correcta
    return java_menu.get_menu(api, node)
end

return {

    {
        name = "  New file",
        cmd = function()
            api.fs.create(node())
        end,
        rtxt = "a",
    },

    {
        name = "  New folder",
        cmd = function()
            api.fs.create(node())
        end,
        rtxt = "a", -- Same key as for creating a new file or directory
    },

    { name = "separator" },

    {
        name = "  Open in window",
        cmd = function()
            api.node.open.edit(node())
        end,
        rtxt = "o",
    },

    {
        name = "  Open in vertical split",
        cmd = function()
            api.node.open.vertical(node())
        end,
        rtxt = "v",
    },

    {
        name = "  Open in horizontal split",
        cmd = function()
            api.node.open.horizontal(node())
        end,
        rtxt = "s",
    },

    {
        name = "󰓪  Open in new tab",
        cmd = function()
            api.node.open.tab(node())
        end,
        rtxt = "O",
    },

    { name = "separator" },

    {
        name = "  Cut",
        cmd = function()
            api.fs.cut(node())
        end,
        rtxt = "x",
    },

    {
        name = "  Paste",
        cmd = function()
            api.fs.paste(node())
        end,
        rtxt = "p",
    },

    {
        name = "  Copy",
        cmd = function()
            api.fs.copy.node(node())
        end,
        rtxt = "c",
    },

    {
        name = "󰴠  Copy absolute path",
        cmd = function()
            api.fs.copy.absolute_path(node())
        end,
        rtxt = "gy",
    },

    {
        name = "  Copy relative path",
        cmd = function()
            api.fs.copy.relative_path(node())
        end,
        rtxt = "Y",
    },

    { name = "separator" },

    {
        name = "  Open in terminal",
        hl = "ExBlue",
        cmd = function()
            local path = node().absolute_path
            local node_type = vim.uv.fs_stat(path).type
            local dir = node_type == "directory" and path or vim.fn.fnamemodify(path, ":h")

            vim.cmd("enew")
            vim.fn.termopen({ vim.o.shell, "-c", "cd " .. dir .. " ; " .. vim.o.shell })
        end,
    },

    { name = "separator" },

    {
        name = "  Rename",
        cmd = function()
            api.fs.rename(node())
        end,
        rtxt = "r",
    },

    {
        name = "  Trash",
        cmd = function()
            api.fs.trash(node())
        end,
        rtxt = "D",
    },

    {
        name = "  Delete",
        hl = "ExRed",
        cmd = function()
            api.fs.remove(node())
        end,
        rtxt = "d",
    },
}
