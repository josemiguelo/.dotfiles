local session_name_builder = require("util.tmux").build_tmux_session_name
_G.tmux_session_name_builder = session_name_builder

-- tmux-ensure-server first: a server started from here would keep this
-- directory (often a worktree, removed once merged) as its cwd for life.
local start_session = function()
  vim.cmd("term ~/.local/bin/tmux-ensure-server; tmux new -A -t " .. session_name_builder(vim.fn.getcwd()))
  vim.cmd("startinsert")
end

vim.api.nvim_create_user_command("PersistedTerm", function()
  start_session()
end, {})

vim.api.nvim_create_user_command("PersistedTermtab", function()
  vim.cmd("tabnew")
  start_session()
end, {})

vim.api.nvim_set_keymap("t", "<Esc><Esc>", "<C-\\><C-n>", { noremap = true, silent = true })

return {}
