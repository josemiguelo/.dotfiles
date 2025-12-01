local session_name_builder = require("util.tmux").build_tmux_session_name
_G.tmux_session_name_builder = session_name_builder

local start_session = function()
  vim.cmd("term tmux new -A -t " .. session_name_builder(vim.fn.getcwd()))
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
