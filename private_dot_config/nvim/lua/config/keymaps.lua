local map = vim.keymap.set
local del = vim.keymap.del

-- tabs
del("n", "<leader><tab>]")
map("n", "<S-l>", "<cmd>tabnext<cr>", { desc = "Next Tab" })
del("n", "<leader><tab>[")
map("n", "<S-h>", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })
map("n", "<leader><tab>e", "<cmd>tab split<cr>", { desc = "Edit current in new Tab" })
map("n", "<leader><tab>m", "<cmd>tabm +1<cr>", { desc = "Move current tab to the right" })
map("n", "<leader><tab>M", "<cmd>tabm -1<cr>", { desc = "Move current tab to the right" })
map("n", "<leader><tab>r", ":TabRename ", { desc = "Rename tab" })

-- when moving across pages, always center the cursor
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

-- save all files
map("n", "<C-S-s>", "<cmd>wa<cr>")

-- jdtls
map("n", "<leader>uj", function()
  require("utils.jdtls").toggle()
end, { desc = "Toggle Jdtls globally" })
