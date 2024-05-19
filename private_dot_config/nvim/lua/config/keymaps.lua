local wk = require("which-key")

local Util = require("lazyvim.util")

local map = vim.keymap.set
local del = vim.keymap.del

-- terminals
local opts_terminal = { size = { width = 0.9, height = 0.9 }, border = "rounded" }
map("n", "<leader>fT", function()
  Util.terminal.open(nil, vim.tbl_extend("force", opts_terminal, { cwd = Util.get_root() }))
end, { desc = "Terminal (root dir)" })
map("n", "<leader>ft", function()
  Util.terminal.open({}, opts_terminal)
end, { desc = "Terminal (cwd)" })
map("t", "<esc>", "<c-\\><c-n>", { desc = "Close  terminal" })

map("n", "<c-/>", function()
  Util.terminal.open({}, opts_terminal)
end, { desc = "Terminal", remap = true, noremap = false })
-- -- lazygit
-- map("n", "<leader>gul", function()
--   Util.terminal.open({ "lazygit" }, vim.tbl_extend("force", opts_terminal, { cwd = Util.get_root(), esc_esc = false }))
-- end, { desc = "Lazygit (root dir)" })
-- map("n", "<leader>guL", function()
--   Util.terminal.open({ "lazygit" }, vim.tbl_extend("force", opts_terminal, { esc_esc = false }))
-- end, { desc = "Lazygit (cwd)" })

-- tig
map("n", "<leader>gut", function()
  Util.terminal.open({ "tig" }, vim.tbl_extend("force", opts_terminal, { cwd = Util.get_root(), esc_esc = false }))
end, { desc = "tig (root dir)" })
map("n", "<leader>guT", function()
  Util.terminal.open({ "tig" }, vim.tbl_extend("force", opts_terminal, { esc_esc = false }))
end, { desc = "tig (cwd)" })

map("n", "<leader>bn", "<cmd>enew<cr>", { desc = "New Buffer" })

local keys = {
  ["<leader>gu"] = { name = "+UIs" },
  ["<leader>q"] = "which_key_ignore",
}

-- windows
del("n", "<leader>ww")
del("n", "<leader>wd")
del("n", "<leader>w-")
del("n", "<leader>w|")
del("n", "<leader>-")
del("n", "<leader>|")
map("n", "<leader>ww", "<C-W>p", { desc = "Other window", remap = true })
map("n", "<leader>wq", "<C-W>c", { desc = "Delete window", remap = true })
map("n", "<leader>ws", "<C-W>s", { desc = "Split window below", remap = true })
map("n", "<leader>wv", "<C-W>v", { desc = "Split window right", remap = true })
map("n", "<leader>wo", "<cmd>only<CR>", { desc = "Only window", remap = true })

-- buffers
del("n", "<leader>fn")
map("n", "<leader>bn", "<cmd>enew<cr>", { desc = "New Buffer" })
map("n", "<leader>fn", function()
  require("neo-tree.command").execute({ toggle = true, dir = vim.loop.cwd() })
end, { desc = "tig (cwd)" })
map("n", "<leader>fN", function()
  require("neo-tree.command").execute({ toggle = true, dir = Util.root() })
end, { desc = "tig (cwd)" })

-- tabs
del("n", "<leader><tab>l")
del("n", "<leader><tab>f")
del("n", "<leader><tab><tab>")
del("n", "<leader><tab>]")
del("n", "<leader><tab>d")
del("n", "<leader><tab>[")
map("n", "<leader>tL", "<cmd>tablast<cr>", { desc = "Last Tab" })
map("n", "<leader>tF", "<cmd>tabfirst<cr>", { desc = "First Tab" })
map("n", "<leader>tt", "<cmd>tabnew<cr>", { desc = "New Tab (after)" })
map("n", "<leader>tT", "<cmd>-1tabnew<cr>", { desc = "New Tab (before)" })
map("n", "<leader>tl", "<cmd>tabnext<cr>", { desc = "Next Tab" })
map("n", "<leader>th", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })
map("n", "<leader>tq", "<cmd>tabclose<cr>", { desc = "Close Tab" })
map("n", "<leader>tml", "<cmd>+tabmove<cr>", { desc = "Move to next tab" })
map("n", "<leader>tmh", "<cmd>-tabmove<cr>", { desc = "Move to prev tab" })
map("n", "<leader>tr", ":TabRename ", { desc = "Rename tab" })
map("n", "<leader>te", "<cmd>tab sb %<CR>", { desc = "Open curent buffer in new tab (after)" })
map("n", "<leader>tE", "<cmd>-1tab sb %<CR>", { desc = "Open curent buffer in new tab (before)" })
map("n", "<leader>tgm", "1gt", { desc = "Go to tab 1" })
map("n", "<leader>tg,", "2gt", { desc = "Go to tab 2" })
map("n", "<leader>tg.", "3gt", { desc = "Go to tab 3" })
map("n", "<leader>tgj", "4gt", { desc = "Go to tab 4" })
map("n", "<leader>tgk", "5gt", { desc = "Go to tab 5" })
map("n", "<leader>tgl", "6gt", { desc = "Go to tab 6" })
map("n", "<leader>tgu", "7gt", { desc = "Go to tab 7" })
map("n", "<leader>tgi", "8gt", { desc = "Go to tab 8" })
map("n", "<leader>tgo", "9gt", { desc = "Go to tab 9" })
map("n", "gt", "<Nop>")
map("n", "gT", "<Nop>")
keys["<leader>tg"] = { name = "+go to number tab" }
keys["<leader>tm"] = { name = "+move tab" }

-- when moving across pages, always center the cursor
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

map("n", "<C-S-s>", "<cmd>wa<cr>")

map("n", "<leader>uj", function()
  require("utils.jdtls").toggle()
end, { desc = "Toggle Jdtls globally" })

keys["<leader>r"] = { name = "+run" }
wk.register(keys)
