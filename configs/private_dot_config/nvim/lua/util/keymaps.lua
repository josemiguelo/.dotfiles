local M = {}

M.keymap_exists = function(mode, lhs)
  return vim.fn.maparg(lhs, mode) ~= ""
end

M.del_keymap = function(mode, lhs)
  if M.keymap_exists(mode, lhs) then
    vim.keymap.del(mode, lhs)
  end
end

M.remap = function(mode, lhs, rhs, opts)
  M.del_keymap(mode, lhs)
  vim.keymap.set(mode, lhs, rhs, opts)
end

return M
