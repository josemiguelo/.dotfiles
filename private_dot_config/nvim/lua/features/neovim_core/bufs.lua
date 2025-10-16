vim.keymap.set({ "i", "x", "n", "s" }, "<C-S-s>", "<cmd>wa<cr><esc>", { desc = "Save All Files" })

-- center screen after half-page jump
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

return {}
