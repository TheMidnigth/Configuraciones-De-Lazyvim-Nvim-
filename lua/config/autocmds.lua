-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--
vim.api.nvim_create_user_command("NewJavaClass", function()
    vim.ui.input({ prompt = "Class name: " }, function(name)
        if not name then
            return
        end
        vim.ui.input({
            prompt = "Directory: ",
            default = vim.fn.expand("%:p:h"),
            completion = "dir",
        }, function(dir)
            if not dir then
                return
            end
            vim.ui.select(
                { "Class", "Interface", "Record", "Enum", "Annotation", "Exception" },
                { prompt = "Select type:" },
                function(choice)
                    if not choice then
                        return
                    end
                    local templates = {
                        Class = "public class " .. name .. " {\n}",
                        Interface = "public interface " .. name .. " {\n}",
                        Record = "public record " .. name .. "() {\n}",
                        Enum = "public enum " .. name .. " {\n}",
                        Annotation = "public @interface " .. name .. " {\n}",
                        Exception = "public class "
                            .. name
                            .. " extends Exception {\n  public "
                            .. name
                            .. "(String message) {\n    super(message);\n  }\n}",
                    }
                    local file = dir .. "/" .. name .. ".java"
                    local content = vim.split(templates[choice], "\n")
                    -- escribir directamente al disco
                    vim.fn.writefile(content, file)
                    -- abrir el archivo
                    vim.cmd("e " .. vim.fn.fnameescape(file))
                end
            )
        end)
    end)
end, {})

vim.api.nvim_set_hl(0, "ExBlue", { fg = "#61afef" })
vim.api.nvim_set_hl(0, "ExRed", { fg = "#e06c75" })

-- 🔥 colores tipo NvChad
vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
        vim.api.nvim_set_hl(0, "NvimTreeFolderName", { fg = "#7aa2f7" })
        vim.api.nvim_set_hl(0, "NvimTreeOpenedFolderName", { fg = "#7aa2f7", bold = true })
        vim.api.nvim_set_hl(0, "NvimTreeEmptyFolderName", { fg = "#7aa2f7" })
    end,
})
