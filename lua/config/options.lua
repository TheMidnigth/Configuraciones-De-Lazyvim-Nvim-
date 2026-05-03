-- ===============================
-- BASE
-- ===============================
vim.g.mapleader = " "
vim.g.autoformat = false
vim.scriptencoding = "utf-8"
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

-- ===============================
-- LINEAS Y CURSOR
-- ===============================
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true

-- ===============================
-- INDENTACION / TABS
-- ===============================
vim.opt.autoindent = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.smarttab = true
vim.opt.breakindent = true

-- ===============================
-- BUSQUEDA
-- ===============================
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true

-- ===============================
-- APARIENCIA
-- ===============================
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.wrap = false
vim.opt.colorcolumn = ""


-- ===============================
-- SCROLL / FLUIDEZ
-- ===============================
vim.opt.scrolloff = 0
vim.opt.sidescrolloff = 8
vim.opt.updatetime = 250
vim.opt.timeoutlen = 400

-- ===============================
-- SISTEMA
-- ===============================
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"
vim.opt.backup = false
vim.opt.swapfile = false
vim.opt.writebackup = false
vim.opt.undofile = true

-- ===============================
-- COMANDOS / VENTANAS
-- ===============================
vim.opt.inccommand = "split"
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.splitkeep = "cursor"
vim.opt.laststatus = 3

-- ===============================
-- PATHS / PROYECTOS GRANDES
-- ===============================
vim.opt.wildignore:append({ "*/node_modules/*", "*/.git/*", "*/dist/*", "*/build/*" })

-- ===============================
-- AUTOCOMPLETADO
-- ===============================
vim.opt.completeopt = { "menu", "menuone", "noselect" }

-- ===============================
-- EDICION
-- ===============================
vim.opt.backspace = { "start", "eol", "indent" }
vim.opt.formatoptions:append({ "r" })

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "html" },
    callback = function()
        vim.keymap.set("i", "<CR>", function()
            local line = vim.api.nvim_get_current_line()
            local col = vim.api.nvim_win_get_cursor(0)[2]
            local before = line:sub(1, col)
            local after = line:sub(col + 1)
            -- caso 1: <h1>hola| </h1>
            if before:match("<[%a][^>]*>.+") and after:match("^</[%a]") then
                return "<CR><ESC>O"
            end
            -- caso 2: <h1>|hola</h1>
            if before:match("<[%a][^>]*>$") and after:match(".+</[%a]") then
                return "<CR>"
            end
            -- caso original: <tag>|</tag> sin contenido
            if before:match("<[%a][^>]*>$") and after:match("^</[%a]") then
                return "<CR><ESC>O"
            end
            return "<CR>"
        end, { buffer = true, expr = true, replace_keycodes = true })
    end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "onedark_dark",
    callback = function()
        vim.api.nvim_set_hl(0, "Visual", { bg = "#2c3150", bold = false })
    end,
})

