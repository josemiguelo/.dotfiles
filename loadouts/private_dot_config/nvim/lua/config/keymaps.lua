local map = vim.keymap.set
local del = vim.keymap.del

-- TmuxNavigator keymaps
del("n", "<C-h>")
del("n", "<C-j>")
del("n", "<C-k>")
del("n", "<C-l>")
map("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Go to left window", remap = true })
map("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>", { desc = "Go to lower window", remap = true })
map("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>", { desc = "Go to upper window", remap = true })
map("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>", { desc = "Go to right window", remap = true })

-- H and L are Vim's (screen top and bottom), not LazyVim's buffer cycling
-- ([b and ]b still do that)
del("n", "<S-h>")
del("n", "<S-l>")
