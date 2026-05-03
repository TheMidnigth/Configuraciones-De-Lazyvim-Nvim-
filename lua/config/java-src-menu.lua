local M = {}

function M.get_menu(api, node_fn)
    local function get_dir(node)
        local path = node.absolute_path
        if vim.uv.fs_stat(path).type ~= "directory" then
            return vim.fn.fnamemodify(path, ":h")
        end
        return path
    end

    local function get_package(dir)
        -- Maven/Gradle: src/main/java/com/example
        local pkg = dir:match("src/main/java/(.+)")
        -- IntelliJ plain: src/com/example (si existe subdirectorio)
        if not pkg then
            pkg = dir:match("/src/(.+)")
        end
        -- Si está directo en src/ sin subdirectorios → sin package
        return pkg and pkg:gsub("/", ".") or ""
    end

    local function create_file(dir, name, extension, content_lines)
        local filepath = dir .. "/" .. name .. extension
        vim.fn.writefile(content_lines or {}, filepath)
        vim.cmd("edit " .. filepath)
        api.tree.reload()
    end

    local function create_java_file(dir, name, lines)
        create_file(dir, name, ".java", lines)
    end

    local function create_kotlin_file(dir, name, lines)
        create_file(dir, name, ".kt", lines)
    end

    local function java_template(type_keyword, name, pkg_name)
        local lines = {}
        if pkg_name ~= "" then
            table.insert(lines, "package " .. pkg_name .. ";")
            table.insert(lines, "")
        end
        table.insert(lines, "public " .. type_keyword .. " " .. name .. " {")
        table.insert(lines, "    ")
        table.insert(lines, "}")
        return lines
    end

    local function kotlin_template(type_keyword, name, pkg_name)
        local lines = {}
        if pkg_name ~= "" then
            table.insert(lines, "package " .. pkg_name)
            table.insert(lines, "")
        end
        table.insert(lines, type_keyword .. " " .. name .. " {")
        table.insert(lines, "    ")
        table.insert(lines, "}")
        return lines
    end

    local function prompt_and_create(label, type_keyword, lang)
        return function()
            local node = node_fn()
            local dir = get_dir(node)
            local pkg_name = get_package(dir)
            vim.ui.input({ prompt = label .. " name: " }, function(name)
                if not name or name == "" then
                    return
                end
                if lang == "java" then
                    create_java_file(dir, name, java_template(type_keyword, name, pkg_name))
                elseif lang == "kotlin" then
                    create_kotlin_file(dir, name, kotlin_template(type_keyword, name, pkg_name))
                end
            end)
        end
    end

    local function create_scratch_file()
        local node = node_fn()
        local dir = get_dir(node)
        vim.ui.input({ prompt = "Scratch file name: " }, function(name)
            if not name or name == "" then
                return
            end
            vim.ui.input({ prompt = "Extension (ej: .java, .py, .js): " }, function(ext)
                if not ext then
                    return
                end
                create_file(dir, name, ext, { "// Scratch file" })
            end)
        end)
    end

    local function create_html_file()
        local node = node_fn()
        local dir = get_dir(node)
        vim.ui.input({ prompt = "HTML file name: " }, function(name)
            if not name or name == "" then
                return
            end
            local content = {
                "<!DOCTYPE html>",
                '<html lang="en">',
                "<head>",
                '    <meta charset="UTF-8">',
                '    <meta name="viewport" content="width=device-width, initial-scale=1.0">',
                "    <title>" .. name .. "</title>",
                "</head>",
                "<body>",
                "    ",
                "</body>",
                "</html>",
            }
            create_file(dir, name, ".html", content)
        end)
    end

    local function create_editorconfig_file()
        local node = node_fn()
        local dir = get_dir(node)
        local content = {
            "root = true",
            "",
            "[*]",
            "charset = utf-8",
            "end_of_line = lf",
            "indent_style = space",
            "indent_size = 4",
            "insert_final_newline = true",
            "trim_trailing_whitespace = true",
            "",
            "[*.{java,kt}]",
            "indent_size = 4",
            "",
            "[*.{xml,html}]",
            "indent_size = 2",
        }
        create_file(dir, ".editorconfig", "", content)
    end

    local function create_resource_bundle()
        local node = node_fn()
        local dir = get_dir(node)
        vim.ui.input({ prompt = "Resource bundle base name: " }, function(name)
            if not name or name == "" then
                return
            end
            local content = {
                "# Resource bundle for " .. name,
                "# Add your key-value pairs here",
            }
            create_file(dir, name, ".properties", content)
        end)
    end

    local function change_folder_icon()
        vim.notify("Change folder icon feature - Implementa según tu configuración", vim.log.levels.INFO)
    end

    -- Submenú "New" usando "items"
    local new_items = {
        {
            name = "  New Java Class",
            hl = "ExBlue",
            items = {
                {
                    name = "󰌗  Class...",
                    cmd = function()
                        local node = node_fn()
                        local dir = get_dir(node)
                        local pkg_name = get_package(dir)
                        vim.ui.input({ prompt = "Class name: " }, function(name)
                            if not name or name == "" then
                                return
                            end
                            local lines = {}
                            if pkg_name ~= "" then
                                table.insert(lines, "package " .. pkg_name .. ";")
                                table.insert(lines, "")
                            end
                            table.insert(lines, "public class " .. name .. " {")
                            table.insert(lines, "}")
                            local file = dir .. "/" .. name .. ".java"
                            vim.fn.writefile(lines, file)
                            vim.cmd("e " .. vim.fn.fnameescape(file))
                            api.tree.reload()
                        end)
                    end,
                },
                {
                    name = "󰜰  Interface...",
                    cmd = function()
                        local node = node_fn()
                        local dir = get_dir(node)
                        local pkg_name = get_package(dir)
                        vim.ui.input({ prompt = "Interface name: " }, function(name)
                            if not name or name == "" then
                                return
                            end
                            local lines = {}
                            if pkg_name ~= "" then
                                table.insert(lines, "package " .. pkg_name .. ";")
                                table.insert(lines, "")
                            end
                            table.insert(lines, "public interface " .. name .. " {")
                            table.insert(lines, "}")
                            local file = dir .. "/" .. name .. ".java"
                            vim.fn.writefile(lines, file)
                            vim.cmd("e " .. vim.fn.fnameescape(file))
                            api.tree.reload()
                        end)
                    end,
                },
                {
                    name = "󰉺  Record...",
                    cmd = function()
                        local node = node_fn()
                        local dir = get_dir(node)
                        local pkg_name = get_package(dir)
                        vim.ui.input({ prompt = "Record name: " }, function(name)
                            if not name or name == "" then
                                return
                            end
                            local lines = {}
                            if pkg_name ~= "" then
                                table.insert(lines, "package " .. pkg_name .. ";")
                                table.insert(lines, "")
                            end
                            table.insert(lines, "public record " .. name .. "() {")
                            table.insert(lines, "}")
                            local file = dir .. "/" .. name .. ".java"
                            vim.fn.writefile(lines, file)
                            vim.cmd("e " .. vim.fn.fnameescape(file))
                            api.tree.reload()
                        end)
                    end,
                },
                {
                    name = "󰕘  Enum...",
                    cmd = function()
                        local node = node_fn()
                        local dir = get_dir(node)
                        local pkg_name = get_package(dir)
                        vim.ui.input({ prompt = "Enum name: " }, function(name)
                            if not name or name == "" then
                                return
                            end
                            local lines = {}
                            if pkg_name ~= "" then
                                table.insert(lines, "package " .. pkg_name .. ";")
                                table.insert(lines, "")
                            end
                            table.insert(lines, "public enum " .. name .. " {")
                            table.insert(lines, "}")
                            local file = dir .. "/" .. name .. ".java"
                            vim.fn.writefile(lines, file)
                            vim.cmd("e " .. vim.fn.fnameescape(file))
                            api.tree.reload()
                        end)
                    end,
                },
                {
                    name = "󰀿  Annotation...",
                    cmd = function()
                        local node = node_fn()
                        local dir = get_dir(node)
                        local pkg_name = get_package(dir)
                        vim.ui.input({ prompt = "Annotation name: " }, function(name)
                            if not name or name == "" then
                                return
                            end
                            local lines = {}
                            if pkg_name ~= "" then
                                table.insert(lines, "package " .. pkg_name .. ";")
                                table.insert(lines, "")
                            end
                            table.insert(lines, "public @interface " .. name .. " {")
                            table.insert(lines, "}")
                            local file = dir .. "/" .. name .. ".java"
                            vim.fn.writefile(lines, file)
                            vim.cmd("e " .. vim.fn.fnameescape(file))
                            api.tree.reload()
                        end)
                    end,
                },
                {
                    name = "󱐋  Exception...",
                    cmd = function()
                        local node = node_fn()
                        local dir = get_dir(node)
                        local pkg_name = get_package(dir)
                        vim.ui.input({ prompt = "Exception name: " }, function(name)
                            if not name or name == "" then
                                return
                            end
                            local lines = {}
                            if pkg_name ~= "" then
                                table.insert(lines, "package " .. pkg_name .. ";")
                                table.insert(lines, "")
                            end
                            table.insert(lines, "public class " .. name .. " extends RuntimeException {")
                            table.insert(lines, "    public " .. name .. "(String message) { super(message); }")
                            table.insert(lines, "}")
                            local file = dir .. "/" .. name .. ".java"
                            vim.fn.writefile(lines, file)
                            vim.cmd("e " .. vim.fn.fnameescape(file))
                            api.tree.reload()
                        end)
                    end,
                },
            },
        },
        {
            name = "  Kotlin Class/File",
            hl = "ExBlue",
            cmd = function()
                local choices = { "Class", "Interface", "Object", "Data Class", "Sealed Class", "Enum Class" }
                vim.ui.select(choices, {
                    prompt = "Select Kotlin type:",
                    format_item = function(item)
                        return item
                    end,
                }, function(choice)
                    if not choice then
                        return
                    end
                    local type_map = {
                        ["Class"] = "class",
                        ["Interface"] = "interface",
                        ["Object"] = "object",
                        ["Data Class"] = "data class",
                        ["Sealed Class"] = "sealed class",
                        ["Enum Class"] = "enum class",
                    }
                    local node = node_fn()
                    local dir = get_dir(node)
                    local pkg_name = get_package(dir)
                    vim.ui.input({ prompt = choice .. " name: " }, function(name)
                        if not name or name == "" then
                            return
                        end
                        create_kotlin_file(dir, name, kotlin_template(type_map[choice], name, pkg_name))
                    end)
                end)
            end,
        },
        {
            name = "  File",
            cmd = function()
                api.fs.create(node_fn())
            end,
            rtxt = "a",
        },
        {
            name = "  Scratch File",
            hl = "ExBlue",
            cmd = create_scratch_file,
            rtxt = "Ctrl+Alt+Shift+Insert",
        },
        {
            name = "  Package",
            cmd = function()
                local node = node_fn()
                local dir = get_dir(node)
                vim.ui.input({ prompt = "Package name (dots allowed): " }, function(name)
                    if not name or name == "" then
                        return
                    end
                    local folder_path = dir .. "/" .. name:gsub("%.", "/")
                    vim.fn.mkdir(folder_path, "p")
                    api.tree.reload()
                end)
            end,
        },
        {
            name = "  package-info.java",
            cmd = function()
                local node = node_fn()
                local dir = get_dir(node)
                local pkg_name = get_package(dir)
                local content = {
                    "/**",
                    " * Package information for " .. (pkg_name ~= "" and pkg_name or "default package"),
                    " */",
                    "package " .. (pkg_name ~= "" and pkg_name or "") .. ";",
                }
                create_file(dir, "package-info", ".java", content)
            end,
        },
        {
            name = "  module-info.java",
            cmd = function()
                local node = node_fn()
                local dir = get_dir(node)
                vim.ui.input({ prompt = "Module name: " }, function(name)
                    if not name or name == "" then
                        return
                    end
                    local content = {
                        "module " .. name .. " {",
                        "    // Add your module dependencies here",
                        "}",
                    }
                    create_file(dir, "module-info", ".java", content)
                end)
            end,
        },
        {
            name = "  Kotlin Notebook",
            hl = "ExBlue",
            cmd = function()
                local node = node_fn()
                local dir = get_dir(node)
                vim.ui.input({ prompt = "Notebook name: " }, function(name)
                    if not name or name == "" then
                        return
                    end
                    local content = {
                        "// Kotlin Notebook",
                        "// Created: " .. os.date("%Y-%m-%d %H:%M:%S"),
                        "",
                        "fun main() {",
                        '    println("Hello from Kotlin Notebook!")',
                        "}",
                        "",
                        "// Add your code here",
                    }
                    create_file(dir, name, ".kts", content)
                end)
            end,
        },
        {
            name = "  HTML File",
            cmd = create_html_file,
        },
        {
            name = "  EditorConfig File",
            cmd = create_editorconfig_file,
        },
        {
            name = "  Resource Bundle",
            cmd = create_resource_bundle,
        },
        {
            name = "  Change Folder Icon",
            cmd = change_folder_icon,
        },
    }

    -- Submenú "Open In"
    local open_in_items = {
        {
            name = "  Explorer",
            cmd = function()
                local node = node_fn()
                local path = node.absolute_path
                if vim.fn.has("win32") == 1 then
                    vim.cmd("silent !explorer.exe " .. vim.fn.shellescape(path))
                elseif vim.fn.has("mac") == 1 then
                    vim.cmd("silent !open " .. vim.fn.shellescape(path))
                else
                    vim.cmd("silent !xdg-open " .. vim.fn.shellescape(path))
                end
            end,
        },
        {
            name = "  Terminal",
            cmd = function()
                local node = node_fn()
                local path = node.absolute_path
                vim.cmd("split")
                vim.cmd("term")
                vim.cmd("cd " .. vim.fn.shellescape(path))
            end,
        },
    }

    -- Submenú "Mark Directory as"
    local mark_directory_items = {
        {
            name = "  Sources Root",
            cmd = function()
                vim.notify("Mark as Sources Root - Integra con tu build tool", vim.log.levels.INFO)
            end,
        },
        {
            name = "  Test Sources Root",
            cmd = function()
                vim.notify("Mark as Test Sources Root - Integra con tu build tool", vim.log.levels.INFO)
            end,
        },
        {
            name = "  Resources Root",
            cmd = function()
                vim.notify("Mark as Resources Root - Integra con tu build tool", vim.log.levels.INFO)
            end,
        },
        {
            name = "  Test Resources Root",
            cmd = function()
                vim.notify("Mark as Test Resources Root - Integra con tu build tool", vim.log.levels.INFO)
            end,
        },
        {
            name = "  Excluded",
            cmd = function()
                vim.notify("Mark as Excluded - Integra con tu build tool", vim.log.levels.INFO)
            end,
        },
    }

    -- Menú principal
    return {
        -- New con items (submenú)
        {
            name = "  New",
            hl = "ExBlue",
            items = new_items, -- Usamos "items" en lugar de "submenu"
        },

        { name = "separator" },

        -- Acciones de edición
        {
            name = "  Cut",
            cmd = function()
                api.fs.cut(node_fn())
            end,
            rtxt = "x",
        },
        {
            name = "  Copy",
            cmd = function()
                api.fs.copy.node(node_fn())
            end,
            rtxt = "c",
        },
        {
            name = "  Paste",
            cmd = function()
                api.fs.paste(node_fn())
            end,
            rtxt = "p",
        },

        { name = "separator" },

        -- Búsqueda
        {
            name = "  Find Usages",
            hl = "ExBlue",
            cmd = function()
                vim.notify("Find Usages - Integra con LSP", vim.log.levels.INFO)
            end,
            rtxt = "Alt+Shift+F7",
        },
        {
            name = "  Find in Files...",
            cmd = function()
                vim.cmd("Telescope live_grep")
            end,
            rtxt = "Ctrl+Shift+F",
        },
        {
            name = "  Replace in Files...",
            cmd = function()
                vim.cmd("Telescope live_grep")
                vim.notify("Replace in files - Consider using :%s or telescope with replace", vim.log.levels.INFO)
            end,
            rtxt = "Ctrl+Shift+R",
        },

        { name = "separator" },

        -- Analyze
        {
            name = "  Analyze",
            hl = "ExBlue",
            cmd = function()
                vim.notify("Analyze - Integra con LSP o linters", vim.log.levels.INFO)
            end,
        },

        -- Rename
        {
            name = "  Rename...",
            cmd = function()
                api.fs.rename(node_fn())
            end,
            rtxt = "r",
        },

        -- Refactor (con submenú si es necesario)
        {
            name = "  Refactor",
            hl = "ExBlue",
            cmd = function()
                vim.lsp.buf.code_action()
            end,
        },

        -- Bookmarks
        {
            name = "  Bookmarks",
            hl = "ExBlue",
            cmd = function()
                vim.cmd("Telescope marks")
            end,
        },

        { name = "separator" },

        -- Reformat Code
        {
            name = "  Reformat Code",
            hl = "ExBlue",
            cmd = function()
                vim.cmd("normal! gg=G")
                vim.notify("Code reformatted", vim.log.levels.INFO)
            end,
            rtxt = "Ctrl+Alt+L",
        },

        -- Optimize Imports
        {
            name = "  Optimize Imports",
            hl = "ExBlue",
            cmd = function()
                -- Para Java con LSP
                vim.lsp.buf.code_action({
                    filter = function(action)
                        return action.title:find("Optimize imports") or action.title:find("Organize imports")
                    end,
                    apply = true,
                })
                vim.notify("Optimizing imports...", vim.log.levels.INFO)
            end,
            rtxt = "Ctrl+Alt+O",
        },

        -- Delete
        {
            name = "  Delete...",
            hl = "ExRed",
            cmd = function()
                api.fs.remove(node_fn())
            end,
            rtxt = "d",
        },

        -- Rebuild
        {
            name = "  Rebuild '<default>'",
            cmd = function()
                vim.notify("Rebuild project - Integra con Maven/Gradle", vim.log.levels.INFO)
            end,
        },

        -- Open In (con items)
        {
            name = "  Open In",
            items = open_in_items, -- Submenú
        },

        -- Local History
        {
            name = "  Local History",
            hl = "ExBlue",
            cmd = function()
                vim.notify("Local History - Consider using git or undo tree", vim.log.levels.INFO)
            end,
        },

        -- Repair IDE on File
        {
            name = "  Repair IDE on File",
            cmd = function()
                vim.notify("Repair IDE - Clear cache and reload", vim.log.levels.INFO)
                api.tree.reload()
            end,
        },

        -- Reload from Disk
        {
            name = "  Reload from Disk",
            cmd = function()
                api.tree.reload()
                vim.cmd("checktime")
                vim.notify("Reloaded from disk", vim.log.levels.INFO)
            end,
            rtxt = "F5",
        },

        -- Compare With
        {
            name = "  Compare With...",
            hl = "ExBlue",
            cmd = function()
                vim.notify("Compare with - Use :diffsplit or plugins like vimdiff", vim.log.levels.INFO)
            end,
        },

        { name = "separator" },

        -- Open Module Settings
        {
            name = "  Open Module Settings",
            cmd = function()
                vim.notify("Module Settings - Edit your build.gradle or pom.xml", vim.log.levels.INFO)
            end,
            rtxt = "F4",
        },

        -- Mark Directory as (con items)
        {
            name = "  Mark Directory as",
            items = mark_directory_items, -- Submenú
        },
    }
end

return M
