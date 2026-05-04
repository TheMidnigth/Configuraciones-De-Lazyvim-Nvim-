local jdtls = require("jdtls")
local mason_path = vim.fn.stdpath("data") .. "/mason/packages"

-- Rutas de los adaptadores
local java_debug_jar =
    vim.fn.glob(mason_path .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar")
local java_test_jars = vim.fn.glob(mason_path .. "/java-test/extension/server/*.jar", true, true)

local bundles = {}
if java_debug_jar ~= "" then
    table.insert(bundles, java_debug_jar)
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
        "--add-opens",
        "java.base/java.util=ALL-UNNAMED",
        "--add-opens",
        "java.base/java.lang=ALL-UNNAMED",
        "-jar",
        vim.fn.glob(mason_path .. "/jdtls/plugins/org.eclipse.equinox.launcher_*.jar"),
        "-configuration",
        mason_path .. "/jdtls/config_linux",
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
        },
    },
    init_options = {
        bundles = bundles,
    },
    on_attach = function(_, bufnr)
        -- setup dap automáticamente al adjuntar el LSP
        jdtls.setup_dap({ hotcodereplace = "auto" })
    end,
}

jdtls.start_or_attach(config)
