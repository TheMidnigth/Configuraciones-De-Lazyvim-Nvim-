-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--

vim.api.nvim_set_hl(0, "ExBlue", { fg = "#61afef" })
vim.api.nvim_set_hl(0, "ExRed", { fg = "#e06c75" })

vim.api.nvim_set_hl(0, "NvimTreeFolderIcon", { fg = "#77bbf2" })
vim.api.nvim_set_hl(0, "NvimTreeFolderArrowOpen", { fg = "#77bbf2", bold = true })
vim.api.nvim_set_hl(0, "NvimTreeFolderArrowClosed", { fg = "#3c4145" })
vim.api.nvim_set_hl(0, "NvimTreeFolderName", { fg = "#77bbf2" })
vim.api.nvim_set_hl(0, "NvimTreeOpenedFolderName", { fg = "#77bbf2", bold = true })
vim.api.nvim_set_hl(0, "NvimTreeEmptyFolderName", { fg = "#77bbf2" })
vim.api.nvim_set_hl(0, "NvimTreeCursorLine", { bg = "#1e2832" })

-- ============================================================
-- Resaltado personalizado (cursiva) para tipos, variables y
-- keywords, funcionando para CUALQUIER lenguaje automáticamente.
-- ============================================================

-- Reglas generales: aplican igual para todos los lenguajes
local base_groups = {
    { group = "type.builtin", italic = true },
    { group = "type", italic = true },
    { group = "variable", italic = false },
    { group = "variable.builtin", italic = true },
    { group = "keyword.conditional", italic = true },
    { group = "keyword.loop", italic = true },
    { group = "keyword.return", italic = true },
    { group = "keyword.exception", italic = true },
}

-- Excepciones: reglas que solo aplican a un lenguaje específico y
-- pisan lo definido en base_groups para ese lenguaje.
-- Ejemplo actual: en Python, las variables y "print()"/"len()"/etc. van en cursiva.
local lang_overrides = {
    python = {
        { group = "variable", italic = true }, -- nombres de variables
        { group = "function.builtin", italic = true }, -- print(), len(), range(), etc.
    },
    -- Agrega aquí más excepciones si las necesitas, por ejemplo:
    -- javascript = {
    --     { group = "variable", italic = true },
    -- },
}

-- Aplica "italic" a un grupo de resaltado, conservando su color y demás
-- atributos (fg, bg, bold, etc. NO se tocan).
-- Si el grupo no existe de forma distinta, lo crea copiando el color
-- del grupo "de respaldo" (fallback) indicado, para no perder color.
local function apply_italic(name, italic, fallback)
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    if ok and hl and not vim.tbl_isempty(hl) then
        hl.italic = italic
        vim.api.nvim_set_hl(0, name, hl)
        return
    end

    if fallback then
        local ok2, hl2 = pcall(vim.api.nvim_get_hl, 0, { name = fallback, link = false })
        if ok2 and hl2 and not vim.tbl_isempty(hl2) then
            hl2.italic = italic
            vim.api.nvim_set_hl(0, name, hl2)
        end
    end
end

-- Aplica todas las reglas (generales + excepciones) para el lenguaje dado
local function set_highlights(lang)
    -- 1. Reglas generales para todos los lenguajes
    for _, spec in ipairs(base_groups) do
        local generic = "@" .. spec.group
        apply_italic(generic, spec.italic)
        if lang and lang ~= "" then
            apply_italic(generic .. "." .. lang, spec.italic, generic)
        end
    end

    -- 2. Excepciones específicas del lenguaje actual (pisan lo anterior)
    local overrides = lang_overrides[lang]
    if overrides then
        for _, spec in ipairs(overrides) do
            local generic = "@" .. spec.group
            apply_italic(generic .. "." .. lang, spec.italic, generic)
        end
    end
end

-- Se ejecuta cuando un LSP se conecta al buffer (de cualquier lenguaje).
-- Desactiva los "semantic tokens" del LSP para que no sobreescriban
-- el resaltado de Treesitter, y luego aplica nuestras reglas de cursiva.
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client then
            client.server_capabilities.semanticTokensProvider = nil
            vim.lsp.semantic_tokens.stop(args.buf, args.data.client_id)
        end
        local ft = vim.api.nvim_get_option_value("filetype", { buf = args.buf })
        vim.schedule(function()
            set_highlights(ft)
        end)
    end,
})

-- Seguro extra: se ejecuta al entrar a CUALQUIER archivo (pattern = "*"),
-- por si el LSP tarda en conectarse o el filetype se detecta antes.
vim.api.nvim_create_autocmd("FileType", {
    pattern = "*",
    callback = function(args)
        local ft = args.match
        vim.defer_fn(function()
            set_highlights(ft)
        end, 100)
    end,
})

-- Dart y Flutter → 2 espacios
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "dart" },
    callback = function()
        vim.opt_local.shiftwidth = 2
        vim.opt_local.tabstop = 2
    end,
})

vim.api.nvim_create_autocmd("CursorHold", {
    callback = function()
        vim.diagnostic.open_float(nil, { focusable = false, scope = "cursor" })
    end,
})

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function()
        vim.diagnostic.config({
            underline = true,
            virtual_text = false,
            update_in_insert = false,
            severity_sort = true,
            signs = {
                text = {
                    [vim.diagnostic.severity.ERROR] = LazyVim.config.icons.diagnostics.Error,
                    [vim.diagnostic.severity.WARN] = LazyVim.config.icons.diagnostics.Warn,
                    [vim.diagnostic.severity.INFO] = LazyVim.config.icons.diagnostics.Info,
                    [vim.diagnostic.severity.HINT] = LazyVim.config.icons.diagnostics.Hint,
                },
            },
            float = {
                border = "rounded",
                source = "if_many",
            },
        })
    end,
})
