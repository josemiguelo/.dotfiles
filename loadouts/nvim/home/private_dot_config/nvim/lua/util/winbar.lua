local PATH_SEPARATOR = package.config:sub(1, 1)

local build_path = function(win)
  local bufnr = vim.api.nvim_win_get_buf(win)
  local full_path = vim.api.nvim_buf_get_name(bufnr)

  -- 1. Check for invalid or special buffers
  if full_path == "" or full_path:match("^term://") or full_path == "[No Name]" then
    return {}
  end

  -- Get window width and set max content length (using 70% for safety)
  local win_width = vim.api.nvim_win_get_width(win)
  local max_width = math.floor(win_width * 0.50)

  local filename = vim.fn.fnamemodify(full_path, ":t")
  local dirname_full = vim.fn.fnamemodify(full_path, ":h")
  local separator = PATH_SEPARATOR

  -- The core list starts with the file name and padding: { " ", filename, " " }
  local result = { " ", filename, " " }
  -- Current length calculation: filename + leading space + trailing space
  local current_length = #filename + 2

  -- --- 1. Path Parsing and Setup ---
  local protocol_prefix = ""
  local is_root = false
  local dirs = {}

  local protocol_match = dirname_full:match("^(%a+://)")
  if protocol_match then
    protocol_prefix = protocol_match
    local path_only = dirname_full:sub(#protocol_match + 1)
    dirs = vim.split(path_only, separator, { trimempty = true })
  else
    if dirname_full:sub(1, 1) == "/" or dirname_full == "~" then
      is_root = true
      -- Handle root path extraction for splitting
      local path_to_split = dirname_full:sub(1, 1) == separator and dirname_full:sub(2) or dirname_full
      dirs = vim.split(path_to_split, separator, { trimempty = true })
    else
      dirs = vim.split(dirname_full, separator, { trimempty = true })
    end
  end

  -- --- 2. Build the Path Responsively (Iterate backward) ---
  local truncated = false

  -- Iterate backward through the directory parts
  for i = #dirs, 1, -1 do
    local dir = dirs[i]
    -- Component length is directory name + separator length
    local component_length = #dir + #separator

    if current_length + component_length < max_width then
      -- Insert separator and then the directory name at position 2 (before filename)
      table.insert(result, 2, separator)
      table.insert(result, 2, dir)
      current_length = current_length + component_length
    else
      -- Hit the width limit. Check if we skipped any component before this one.
      if i > 0 and (i > 1 or protocol_prefix ~= "" or is_root) then
        truncated = true
      end
      break
    end
  end

  -- --- 3. Add Truncation Indicator or Protocol/Root Prefix ---
  if truncated then
    -- If truncated, insert an ellipsis component
    table.insert(result, 2, separator)
    table.insert(result, 2, "...")
  elseif protocol_prefix ~= "" then
    -- If fully displayed, add the protocol prefix
    table.insert(result, 2, protocol_prefix)
  elseif is_root and dirname_full:sub(1, 1) == "/" then
    -- If fully displayed, is an absolute path, add the root separator
    table.insert(result, 2, "/")
  elseif #dirs == 0 and not protocol_prefix and not is_root and dirname_full == "." then
    -- Special case for files in the current directory (show './')
    table.insert(result, 2, separator)
    table.insert(result, 2, ".")
  end

  return result
end


local M = { enabled = true }

-- the winbar's text, right-aligned: "(M)" for a modified buffer, then its path
function M.render()
  local win = vim.g.statusline_winid
  local buf = vim.api.nvim_win_get_buf(win)
  local path = table.concat(build_path(win)):gsub("%%", "%%%%")
  local modified = vim.bo[buf].modified and "%#WinbarModified#(M)" or ""
  return "%=" .. modified .. "%#WinbarPath#" .. path .. "%*"
end

local expr = "%!v:lua.require'util.winbar'.render()"
-- a blank bar for a window scrollbound to a file's, so their lines stay level
local spacer = " "

local function ours(win)
  local winbar = vim.wo[win].winbar
  return winbar == expr or winbar == spacer
end

local function set(win, winbar)
  if winbar ~= "" then
    if vim.wo[win].winbar == "" or ours(win) then
      vim.wo[win].winbar = winbar
    end
  elseif ours(win) then
    vim.wo[win].winbar = ""
  end
end

local function is_floating(win)
  return vim.api.nvim_win_get_config(win).relative ~= ""
end

-- a file's window, the ones incline used to show: listed, no special buftype, not
-- floating
local function is_file_win(win)
  local buf = vim.api.nvim_win_get_buf(win)
  return vim.bo[buf].buftype == "" and vim.bo[buf].buflisted and not is_floating(win)
end

-- a :G blame window scrolls with its file's window: give it a blank bar when that
-- one has a bar
local function bound_to_bar(win)
  if not vim.wo[win].scrollbind or is_floating(win) then
    return false
  end
  for _, other in ipairs(vim.api.nvim_tabpage_list_wins(vim.api.nvim_win_get_tabpage(win))) do
    local winbar = vim.wo[other].winbar
    if other ~= win and vim.wo[other].scrollbind and not is_floating(other) and winbar ~= "" and winbar ~= spacer then
      return true
    end
  end
  return false
end

-- files' windows first, so the windows bound to them see their bars. Other winbars
-- (dap-ui's) are left alone; only ours are taken back.
function M.attach_all()
  local wins = vim.api.nvim_list_wins()
  for _, win in ipairs(wins) do
    if is_file_win(win) then
      set(win, M.enabled and expr or "")
    end
  end
  for _, win in ipairs(wins) do
    if not is_file_win(win) then
      set(win, M.enabled and bound_to_bar(win) and spacer or "")
    end
  end
end

function M.toggle()
  M.enabled = not M.enabled
  M.attach_all()
end

return M
