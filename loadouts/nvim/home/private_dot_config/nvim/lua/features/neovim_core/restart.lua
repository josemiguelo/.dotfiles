local get_window_by_ft = require("util.windows").get_window_by_ft

--[[
  custom restart command that closes some windows before restarting.
--]]
local function on_restart()
  local fugitive_win = get_window_by_ft("snacks_picker_list")
  if fugitive_win then
    vim.api.nvim_win_close(fugitive_win, true)
  end
end

local function custom_restart(opts)
  on_restart()

  local cmd_str = "restart"
  cmd_str = opts.bang and cmd_str .. "!" or cmd_str
  cmd_str = (opts.args and opts.args ~= "") and (cmd_str .. " " .. opts.args) or cmd_str

  --stylua: ignore
  vim.defer_fn(function() vim.cmd('silent! execute "' .. cmd_str .. '"') end, 50)
end

vim.api.nvim_create_user_command("Restart", custom_restart, {
  bang = true, -- Allows the use of :restart!
  nargs = "*", -- Allows zero or more arguments (e.g., :restart now)
  desc = "Execute custom logic before executing the native restart command",
})

vim.keymap.set("n", "<leader>qQ", "<cmd>Restart<cr>", { desc = "Restart" })

return {}
