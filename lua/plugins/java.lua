return {
    -- DAP (Debugger)
    {
        "mfussenegger/nvim-dap",
        lazy = true,
        config = function() end,
    },
    {
        "rcarriga/nvim-dap-ui",
        dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
        lazy = true,
    },
    -- JDTLS (Java LSP)
    {
        "mfussenegger/nvim-jdtls",
        dependencies = { "mfussenegger/nvim-dap" },
        ft = "java",
        keys = {
            -- Generación de código
            { "<leader>jc",  function() require("jdtls").generate_constructors() end,    desc = "Generate Constructors"   },
            { "<leader>jg",  function() require("jdtls").generate_getters_setters() end, desc = "Generate Getters/Setters" },
            { "<leader>jo",  function() require("jdtls").organize_imports() end,         desc = "Organize Imports"        },
            { "<leader>jev", function() require("jdtls").extract_variable() end,         desc = "Extract Variable"        },
            { "<leader>jem", function() require("jdtls").extract_method() end,           desc = "Extract Method"          },
            -- Tests
            { "<leader>jt",  function() require("jdtls").test_class() end,           desc = "Test Class"  },
            { "<leader>jtn", function() require("jdtls").test_nearest_method() end,  desc = "Test Method" },
            -- Debugger
            { "<leader>jd",  function() require("jdtls").start_debugging() end,  desc = "Start Debugging"   },
            { "<leader>db",  function() require("dap").toggle_breakpoint() end,  desc = "Toggle Breakpoint" },
            { "<leader>dc",  function() require("dap").continue() end,           desc = "Continue"          },
            { "<leader>ds",  function() require("dap").step_over() end,          desc = "Step Over"         },
            { "<leader>di",  function() require("dap").step_into() end,          desc = "Step Into"         },
            { "<leader>du",  function() require("dapui").toggle() end,           desc = "Toggle DAP UI"     },
            -- Correr proyectos
            { "<leader>jr",  function()
                local term = require("snacks.terminal")
                term.open("mvn spring-boot:run", { cwd = vim.fn.getcwd() })
            end, desc = "Run Spring Boot (Maven)" },
            { "<leader>jR",  function()
                local term = require("snacks.terminal")
                term.open("./gradlew bootRun", { cwd = vim.fn.getcwd() })
            end, desc = "Run Spring Boot (Gradle)" },
            { "<leader>jri", function()
                local cwd = vim.fn.getcwd()
                local term = require("snacks.terminal")
                term.open(
                    "cd " .. cwd .. " && mkdir -p out && javac src/*.java -d out && java -cp out Main",
                    { cwd = cwd }
                )
            end, desc = "Run IntelliJ Project" },
            { "<leader>jrm", function()
                local term = require("snacks.terminal")
                term.open("mvn compile exec:java", { cwd = vim.fn.getcwd() })
            end, desc = "Run Maven Project" },
            { "<leader>jrg", function()
                local term = require("snacks.terminal")
                term.open("./gradlew run", { cwd = vim.fn.getcwd() })
            end, desc = "Run Gradle Project" },
            -- Nuevo proyecto (interfaz IntelliJ)
            { "<leader>jn",  function()
                require("config.java-new-project").open()
            end, desc = "New Java Project" },
        },
    },
}
