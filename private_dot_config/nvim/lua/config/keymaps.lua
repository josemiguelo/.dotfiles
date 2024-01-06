-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local wk = require("which-key")

local Util = require("lazyvim.util")

local function map(mode, lhs, rhs, opts)
  local keys = require("lazy.core.handler").handlers.keys
  ---@cast keys LazyKeysHandler
  -- do not create the keymap if a lazy keys handler exists
  if not keys.active[keys.parse({ lhs, mode = mode }).id] then
    opts = opts or {}
    opts.silent = opts.silent ~= false
    if opts.remap and not vim.g.vscode then
      opts.remap = nil
    end
    vim.keymap.set(mode, lhs, rhs, opts)
  end
end

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
-- lazygit
map("n", "<leader>gul", function()
  Util.terminal.open({ "lazygit" }, vim.tbl_extend("force", opts_terminal, { cwd = Util.get_root(), esc_esc = false }))
end, { desc = "Lazygit (root dir)" })
map("n", "<leader>guL", function()
  Util.terminal.open({ "lazygit" }, vim.tbl_extend("force", opts_terminal, { esc_esc = false }))
end, { desc = "Lazygit (cwd)" })

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
vim.keymap.del("n", "<leader>ww")
vim.keymap.del("n", "<leader>wd")
vim.keymap.del("n", "<leader>w-")
vim.keymap.del("n", "<leader>w|")
vim.keymap.del("n", "<leader>-")
vim.keymap.del("n", "<leader>|")

map("n", "<leader>ww", "<C-W>p", { desc = "Other window", remap = true })
map("n", "<leader>wq", "<C-W>c", { desc = "Delete window", remap = true })
map("n", "<leader>ws", "<C-W>s", { desc = "Split window below", remap = true })
map("n", "<leader>wv", "<C-W>v", { desc = "Split window right", remap = true })
map("n", "<leader>wo", "<cmd>only<CR>", { desc = "Only window", remap = true })

vim.keymap.del("n", "<leader>fn")
map("n", "<leader>bn", "<cmd>enew<cr>", { desc = "New Buffer" })

map("n", "<leader>tt", "<cmd>tabnew<CR>", { desc = "New tab" })
map("n", "<leader>tml", "<cmd>+tabmove<cr>", { desc = "Move next tab" })
map("n", "<leader>tmh", "<cmd>-tabmove<cr>", { desc = "Move prev tab" })
map("n", "<leader>tr", ":TabRename ", { desc = "Rename tab" })
map("n", "<leader>tc", "<cmd>tabclose<CR>", { desc = "Close tab" })
map("n", "<leader>te", "<cmd>tab sb %<CR>", { desc = "Open buffer in new tab" })

map("n", "<S-l>", "<cmd>tabn<CR>", { desc = "Next tab" })
map("n", "<S-h>", "<cmd>tabp<cr>", { desc = "Prev tab" })

-- map("n", "<leader>tr", function()
--   vim.ui.input({ prompt = "Rename tab: " }, function(name)
--     require("tabby").tab_rename(name)
--   end)
-- end, { desc = "Rename tab" })

map("n", "<C-d>", "<C-d>zz")

vim.keymap.del("n", "<C-h>")
vim.keymap.del("n", "<C-j>")
vim.keymap.del("n", "<C-k>")
vim.keymap.del("n", "<C-l>")

map("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Go to left window", remap = true })
map("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>", { desc = "Go to lower window", remap = true })
map("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>", { desc = "Go to upper window", remap = true })
map("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>", { desc = "Go to right window", remap = true })

--   { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Go to left window" },
--   { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Go to lower window" },
--   { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Go to upper window" },
--   { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Go to right window" },

keys["<leader>r"] = { name = "+run" }
require("which-key").register(keys)
