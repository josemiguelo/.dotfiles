-- local uv = vim.loop

local M = {}

--- Checks whether a given path exists and is a file.
--- @param path string path to check
--- @returns bool
function M.is_file(path)
  local stat = vim.uv.fs_stat(path)
  return stat and stat.type == "file" or false
end

--- Checks whether a given path exists and is a directory
--- @param path string path to check
--- @returns bool
function M.is_directory(path)
  local stat = vim.uv.fs_stat(path)
  return stat and stat.type == "directory" or false
end

---Checks if an string is empty
---@param s string string
---@return boolean
function M.string_is_empty(s)
  return s == nil or s == ""
end

return M
