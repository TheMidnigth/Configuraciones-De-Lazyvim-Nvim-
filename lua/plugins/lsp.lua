return {
    {
        "williamboman/mason.nvim",
        opts = function(_, opts)
            vim.list_extend(opts.ensure_installed, {
                -- lo que ya tenías
                "html-lsp",
                "css-lsp",
                "typescript-language-server",
                "google-java-format",
                "prettierd",
                -- nuevo: Python
                "pyright",
                "ruff",
                "black",
                "isort",
                "debugpy",
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        opts = {
            inlay_hints = { enabled = true },
            servers = {
                -- ── lo que ya tenías ──────────────────────────────────
                html = {
                    init_options = {
                        provideFormatter = true,
                        embeddedLanguages = {
                            css = true,
                            javascript = true,
                        },
                        configurationSection = { "html", "css", "javascript" },
                    },
                    settings = {
                        html = {
                            format = {
                                enable = true,
                                wrapLineLength = 120,
                                unformatted = "pre,code,textarea",
                                contentUnformatted = "pre,code,textarea",
                                indentInnerHtml = false,
                                preserveNewLines = true,
                                indentHandlebars = false,
                                endWithNewline = false,
                                extraLiners = "head, body, /html",
                                wrapAttributes = "auto",
                                tabSize = 4,
                                insertSpaces = true,
                            },
                            hover = {
                                documentation = true,
                                references = true,
                            },
                            completion = {
                                attributeDefaultValue = "doublequotes",
                            },
                            validate = {
                                scripts = true,
                                styles = true,
                            },
                            suggest = {
                                html5 = true,
                            },
                        },
                    },
                },
                cssls = {
                    settings = {
                        css = {
                            validate = true,
                            lint = { unknownAtRules = "ignore" },
                        },
                        scss = {
                            validate = true,
                            lint = { unknownAtRules = "ignore" },
                        },
                        less = {
                            validate = true,
                            lint = { unknownAtRules = "ignore" },
                        },
                    },
                },
                ts_ls = {
                    single_file_support = true,
                    settings = {
                        typescript = {
                            inlayHints = {
                                includeInlayParameterNameHints = "none",
                                includeInlayFunctionLikeReturnTypeHints = false,
                            },
                        },
                        javascript = {
                            inlayHints = {
                                includeInlayParameterNameHints = "none",
                                includeInlayFunctionLikeReturnTypeHints = false,
                            },
                        },
                    },
                },
                lua_ls = {
                    single_file_support = true,
                    settings = {
                        Lua = {
                            workspace = { checkThirdParty = false },
                            completion = {
                                workspaceWord = true,
                                callSnippet = "Both",
                            },
                            hint = {
                                enable = true,
                                setType = false,
                                paramType = true,
                                paramName = "Disable",
                                semicolon = "Disable",
                                arrayIndex = "Disable",
                            },
                            doc = { privateName = { "^_" } },
                            diagnostics = {
                                disable = { "incomplete-signature-doc", "trailing-space" },
                                groupSeverity = {
                                    strong = "Warning",
                                    strict = "Warning",
                                },
                                unusedLocalExclude = { "_*" },
                            },
                            format = { enable = false },
                        },
                    },
                },

                -- ── nuevo: Python ─────────────────────────────────────
                pyright = {
                    settings = {
                        python = {
                            analysis = {
                                typeCheckingMode = "strict",        -- chequeo de tipos estricto
                                autoSearchPaths = true,
                                useLibraryCodeForTypes = true,
                                autoImportCompletions = true,        -- auto-import como PyCharm
                                diagnosticMode = "workspace",        -- analiza todo el proyecto
                                inlayHints = {
                                    variableTypes = true,
                                    functionReturnTypes = true,
                                    callArgumentNames = true,
                                    pytestParameters = true,
                                },
                            },
                        },
                    },
                },
            },
        },
    },
}
