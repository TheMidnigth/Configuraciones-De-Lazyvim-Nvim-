vim.keymap.set("n", "<leader>ff", function()
    require("telescope.builtin").find_files()
end, { desc = "Find Files", nowait = true })

vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Buffers" })
vim.keymap.set("n", "<leader>sg", "<cmd>Telescope live_grep<cr>", { desc = "Live Grep" })
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Salir modo terminal" })
