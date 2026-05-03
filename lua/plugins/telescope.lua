return {
    "nvim-telescope/telescope.nvim",
    opts = {
        defaults = {
            layout_strategy = "horizontal",
            layout_config = {
                horizontal = {
                    prompt_position = "bottom", -- prompt abajo
                    preview_width = 0.55, -- preview más ancho
                    results_width = 0.45,
                },
                width = 0.9,
                height = 0.85,
            },
            sorting_strategy = "descending", -- resultados de abajo hacia arriba
            prompt_prefix = "> ",
            selection_caret = "> ",
        },
    },
}
