local M = {}

local prefix = "lazyvim_"

function M.create_augroup(name)
  return vim.api.nvim_create_augroup(prefix .. name, { clear = true })
end

function M.del_augroup(name)
  if vim.fn.exists("#" .. prefix .. name) == 1 then
    vim.cmd(string.format([[ augroup %s autocmd! augroup END ]], prefix .. name))
  end
end

return M
