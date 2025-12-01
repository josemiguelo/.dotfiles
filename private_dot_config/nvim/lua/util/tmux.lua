local M = {}

-- Generate a tmux session name based on the current working directory
---@param cwd string cwd for the tmux session
function M.build_tmux_session_name(cwd)
  -- Generate a hash of the full path for uniqueness
  local hash = vim.fn.sha256(cwd):sub(1, 8)

  -- Get the current directory name
  local dir_name = vim.fn.fnamemodify(cwd, ":t")

  -- Get the parent directory name
  local parent_path = vim.fn.fnamemodify(cwd, ":h")
  local parent_name_raw = vim.fn.fnamemodify(parent_path, ":t")

  -- Handle edge cases
  if dir_name == "" or dir_name == "." then
    dir_name = "root"
  end

  -- If parent is same as current (e.g., root dir) or empty, use only dir_name
  local parent_name = nil
  if parent_name_raw ~= "" and parent_name_raw ~= "." and parent_name_raw ~= dir_name and parent_path ~= cwd then
    parent_name = parent_name_raw
  end

  -- Replace special characters with underscores for tmux compatibility
  dir_name = dir_name:gsub("[^%w_-]", "_")
  if parent_name then
    parent_name = parent_name:gsub("[^%w_-]", "_")
  end

  -- Combine parent (if exists), current dir, and hash
  local prefix = parent_name and (parent_name .. "_" .. dir_name) or dir_name
  return prefix .. "_" .. hash
end

return M
