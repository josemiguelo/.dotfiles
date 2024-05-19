local M = {}

---Checks if an string is empty
---@param s string string
---@return boolean
function M.string_is_empty(s)
  return s == nil or s == ""
end

return M
