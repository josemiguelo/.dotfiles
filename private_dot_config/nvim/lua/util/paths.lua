local M = {}

M.path_exists = function(path)
  if path == nil or path == "" then
    return false
  end
  return vim.loop.fs_stat(path) ~= nil
end

return M
