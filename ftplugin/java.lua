if vim.b.did_ftplugin_java_custom then
    return
end
vim.b.did_ftplugin_java_custom = true

-- ============================================
-- CONFIGURACIÓN DE SIGNOS DAP (DEBE ESTAR PRIMERO)
-- ============================================

-- Asegurar que los signos están definidos
local function setup_dap_signs()
    -- Definir signos
    vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DapBreakpoint", linehl = "", numhl = "" })
    vim.fn.sign_define(
        "DapBreakpointCondition",
        { text = "󰓏", texthl = "DapBreakpointCondition", linehl = "", numhl = "" }
    )
    vim.fn.sign_define("DapLogPoint", { text = "󰻂", texthl = "DapLogPoint", linehl = "", numhl = "" })
    vim.fn.sign_define("DapStopped", { text = "", texthl = "DapStopped", linehl = "DapStoppedLine", numhl = "" })
    vim.fn.sign_define(
        "DapBreakpointRejected",
        { text = "", texthl = "DapBreakpointRejected", linehl = "", numhl = "" }
    )

    -- Definir colores
    vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#e06c75" })
    vim.api.nvim_set_hl(0, "DapBreakpointCondition", { fg = "#e5c07b" })
    vim.api.nvim_set_hl(0, "DapLogPoint", { fg = "#61afef" })
    vim.api.nvim_set_hl(0, "DapStopped", { fg = "#98c379" })
    vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#2e3a2e" })
    vim.api.nvim_set_hl(0, "DapBreakpointRejected", { fg = "#abb2bf" })
end

setup_dap_signs()

-- ============================================
-- CONFIGURACIÓN DE JDTLS Y DAP
-- ============================================

local jdtls = require("jdtls")
local mason_path = vim.fn.stdpath("data") .. "/mason/packages"

local java_debug_jar =
    vim.fn.glob(mason_path .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar")
local java_test_jars = vim.fn.glob(mason_path .. "/java-test/extension/server/*.jar", true, true)

local bundles = {}
if java_debug_jar ~= "" then
    table.insert(bundles, java_debug_jar)
else
    vim.notify("Java Debug Adapter NO encontrado", vim.log.levels.WARN)
end
vim.list_extend(bundles, java_test_jars)

local config = {
    cmd = {
        "java",
        "-Declipse.application=org.eclipse.jdt.ls.core.id1",
        "-Dosgi.bundles.defaultStartLevel=4",
        "-Declipse.product=org.eclipse.jdt.ls.core.product",
        "-Dlog.protocol=true",
        "-Dlog.level=ALL",
        "-Xmx1g",
        "--add-modules=ALL-SYSTEM",
        "--add-opens", "java.base/java.util=ALL-UNNAMED",
        "--add-opens", "java.base/java.lang=ALL-UNNAMED",
        "-jar",
        vim.fn.glob(mason_path .. "/jdtls/plugins/org.eclipse.equinox.launcher_*.jar"),
        "-configuration", mason_path .. "/jdtls/config_linux",
        "-data",
        vim.fn.stdpath("cache") .. "/jdtls/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t"),
    },
    root_dir = jdtls.setup.find_root({ ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }),
    settings = {
        java = {
            configuration = {
                runtimes = {
                    {
                        name = "JavaSE-21",
                        path = "/usr/lib/jvm/java-21-openjdk-amd64",
                    },
                },
            },
            inlayHints = {
                parameterNames = { enabled = "all" },
            },
        },
    },
    init_options = {
        bundles = bundles,
    },
    on_attach = function(client, bufnr)
        -- Configurar DAP para Java
        jdtls.setup_dap({ hotcodereplace = "auto" })

        local dap = require("dap")

        -- ============================================================
        -- VIRTUAL TEXT INLINE MANUAL PARA JAVA
        -- jdtls no es compatible con nvim-dap-virtual-text estándar,
        -- así que leemos las variables directamente del frame actual
        -- y las mostramos con extmarks inline, igual que IntelliJ IDEA.
        -- ============================================================
        local ns = vim.api.nvim_create_namespace("dap_java_vt_" .. bufnr)

        local function clear_vt()
            vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
        end

        local function show_vt()
            clear_vt()
            local session = dap.session()
            if not session or not session.current_frame then return end
            local scopes = session.current_frame.scopes
            if not scopes then return end

            -- Recopilar todas las variables del scope Local
            local vars = {}
            for _, scope in ipairs(scopes) do
                if scope.variables then
                    for _, var in ipairs(scope.variables) do
                        -- Solo variables simples (no objetos/arrays complejos)
                        if var.variablesReference == 0 then
                            vars[var.name] = var.value
                        else
                            -- Para objetos/arrays mostrar el tipo resumido
                            vars[var.name] = var.value
                        end
                    end
                end
            end

            -- Buscar cada variable en las líneas del buffer y poner el extmark
            local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
            for lnum, line in ipairs(lines) do
                for name, value in pairs(vars) do
                    -- Buscar el nombre como palabra completa
                    if line:match("%f[%w_]" .. vim.pesc(name) .. "%f[^%w_]") then
                        vim.api.nvim_buf_set_extmark(bufnr, ns, lnum - 1, 0, {
                            virt_text = {
                                { " = ", "Comment" },
                                { tostring(value), "DiagnosticInfo" },
                            },
                            virt_text_pos  = "eol",  -- al final de la línea (más estable en Java)
                            hl_mode        = "combine",
                            priority       = 100,
                        })
                        break -- una variable por línea
                    end
                end
            end
        end

        -- Mostrar al pausar, limpiar al continuar/terminar
        dap.listeners.after.event_stopped["java_vt_" .. bufnr]          = function() vim.defer_fn(show_vt, 200) end
        dap.listeners.after.event_continued["java_vt_" .. bufnr]        = clear_vt
        dap.listeners.before.event_terminated["java_vt_" .. bufnr]      = clear_vt
        dap.listeners.before.event_exited["java_vt_" .. bufnr]          = clear_vt

        -- ============================================================
        -- Keymaps Java-específicos
        -- ============================================================
        local opts = { buffer = bufnr, silent = true }

        vim.keymap.set("n", "<leader>djt", jdtls.test_nearest_method,
            vim.tbl_extend("force", opts, { desc = "Java: Debug Test Method" }))
        vim.keymap.set("n", "<leader>djT", jdtls.test_class,
            vim.tbl_extend("force", opts, { desc = "Java: Debug Test Class" }))
        vim.keymap.set("n", "<leader>djo", jdtls.organize_imports,
            vim.tbl_extend("force", opts, { desc = "Java: Organize Imports" }))
        vim.keymap.set("n", "<leader>cxv", jdtls.extract_variable,
            vim.tbl_extend("force", opts, { desc = "Java: Extract Variable" }))
        vim.keymap.set("v", "<leader>cxm", [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]],
            vim.tbl_extend("force", opts, { desc = "Java: Extract Method" }))

        -- Keymaps adicionales para debug
        vim.keymap.set("n", "<leader>db", function()
            require("dap").toggle_breakpoint()
        end, vim.tbl_extend("force", opts, { desc = "Toggle Breakpoint" }))
        vim.keymap.set("n", "<leader>dc", function()
            require("dap").continue()
        end, vim.tbl_extend("force", opts, { desc = "Continue/Start" }))
    end,
}

jdtls.start_or_attach(config)
