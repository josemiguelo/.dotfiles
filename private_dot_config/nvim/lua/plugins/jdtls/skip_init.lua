local Util = require("lazy.core.util")
local home = os.getenv("HOME")

local M = {}

local function should_skip_this_dir()
  local skipped_dirs = {
    home .. "/decompiled_jars/fastrack-server-3.3.8",
  }

  local ok, private = pcall(require, "private.jdtls")
  if ok then
    local private_skipped_dirs = private.private_skipped_dirs

    for i = 1, #private_skipped_dirs do
      skipped_dirs[#skipped_dirs + 1] = private_skipped_dirs[i]
    end
  end

  local cdw = vim.fn.getcwd()
  for _, dir in ipairs(skipped_dirs) do
    if dir == cdw then
      return true, cdw
    end
  end

  return false
end

M.should_skip_server = function()
  local should_skip_dir, cdw = should_skip_this_dir()
  if should_skip_dir then
    Util.info("jdtls is disabled on dir " .. cdw, { title = "JDTLS" })
    return true
  end

  return false
end

return M
