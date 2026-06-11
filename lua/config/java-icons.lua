-- ~/.config/nvim/lua/config/java-icons.lua
-- Detecta el tipo de clase Java leyendo el contenido
-- Cache persistente en disco para que los iconos sobrevivan entre sesiones

local M = {}

local ICONS = {
    class = { glyph = "󰆦", hl = "JavaIconClass"  }, -- azul IntelliJ
    interface = { glyph = "󰆩", hl = "JavaIconInterface"  }, -- verde azulado IntelliJ
    record = { glyph = "󰻂", hl = "JavaIconRecord" }, -- naranja IntelliJ
    enum = { glyph = "󰾍", hl = "JavaIconEnum"   }, -- amarillo/dorado IntelliJ
    annotation = { glyph = "", hl = "JavaIconAnnotation" }, -- naranja rojizo IntelliJ
    exception = { glyph = "󱐋", hl = "JavaIconException" }, -- rojo IntelliJ
}

-- ── Cache en disco ────────────────────────────────────────────────────────────
local cache_path = vim.fn.stdpath("cache") .. "/java-icons-cache.json"
local cache = {}

-- Cargar cache desde disco al iniciar
local function load_cache()
    local f = io.open(cache_path, "r")
    if not f then return end
    local content = f:read("*a")
    f:close()
    if content and content ~= "" then
        local ok, data = pcall(vim.fn.json_decode, content)
        if ok and type(data) == "table" then
            cache = data
        end
    end
end

-- Guardar cache en disco
local function save_cache()
    local dir = vim.fn.fnamemodify(cache_path, ":h")
    vim.fn.mkdir(dir, "p")
    local f = io.open(cache_path, "w")
    if not f then return end
    local ok, encoded = pcall(vim.fn.json_encode, cache)
    if ok then
        f:write(encoded)
    end
    f:close()
end

-- Cargar cache al arrancar
load_cache()

-- ── Detección de tipo ─────────────────────────────────────────────────────────
local function detect_type(filepath)
    -- Si ya está en cache, retornar directamente
    if cache[filepath] then
        return cache[filepath]
    end

    local f = io.open(filepath, "r")
    if not f then return "class" end

    local content = ""
    for _ = 1, 20 do
        local line = f:read("*l")
        if not line then break end
        content = content .. line .. "\n"
    end
    f:close()

    local result = "class"

    if content:match("public%s+@interface%s+") then
        result = "annotation"
    elseif content:match("public%s+enum%s+") then
        result = "enum"
    elseif content:match("public%s+record%s+") then
        result = "record"
    elseif content:match("public%s+interface%s+") then
        result = "interface"
    elseif content:match("extends%s+RuntimeException")
        or content:match("extends%s+Exception")
        or content:match("extends%s+Error") then
        result = "exception"
    end

    -- Guardar en cache y persistir en disco
    cache[filepath] = result
    save_cache()

    return result
end

-- Retorna el icono para un filepath .java
function M.get_icon(filepath)
    local java_type = detect_type(filepath)
    return ICONS[java_type] or ICONS["class"]
end

-- Limpiar entrada del cache cuando el archivo cambia y repersistir
vim.api.nvim_create_autocmd("BufWritePost", {
    pattern  = "*.java",
    callback = function(ev)
        cache[ev.file] = nil
        save_cache()
        -- Redetectar tipo con el nuevo contenido
        detect_type(ev.file)
        local ok, api = pcall(require, "nvim-tree.api")
        if ok then pcall(api.tree.reload) end
    end,
})

return M
