local M = {}

local prefix = "lazyvim_"

function M.new_lazyvim_augroup(name)
  return vim.api.nvim_create_augroup(prefix .. name, { clear = true })
end

function M.del_lazyvim_augroup(name)
  vim.schedule(function()
    local group_name = prefix .. name
    vim.api.nvim_clear_autocmds({ group = group_name })
  end)
end

return M
