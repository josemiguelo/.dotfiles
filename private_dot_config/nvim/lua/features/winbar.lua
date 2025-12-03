local PATH_SEPARATOR = package.config:sub(1, 1)

local build_path = function(buf)
  local bufnr = buf or vim.api.nvim_get_current_buf()
  local full_path = vim.api.nvim_buf_get_name(bufnr)

  -- 1. Check for invalid or special buffers
  if full_path == "" or full_path:match("^term://") or full_path == "[No Name]" then
    return {}
  end

  -- Get window width and set max content length (using 70% for safety)
  local win_width = vim.api.nvim_win_get_width(0)
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

local excluded_filetypes = {}

return {
  {
    "b0o/incline.nvim",
    dependencies = { "nvim-web-devicons", "olimorris/onedarkpro.nvim", "folke/tokyonight.nvim" },
    config = function()
      require("incline").setup({
        window = {
          padding = 0,
          margin = { horizontal = 0 },
          zindex = 40,
        },
        render = function(props)
          if vim.tbl_contains(excluded_filetypes, vim.bo[props.buf].filetype) then
            return {}
          end

          -- stylua: ignore
          local colors = vim.o.background == "dark"
            and require("onedarkpro.helpers").get_colors()
            or require("tokyonight.colors").setup()

          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
          if filename == "" then
            filename = "[No Name]"
          end
          local modified = vim.bo[props.buf].modified
          local path = build_path(props.buf)

          local render_ret = {
            modified and { "(M)", gui = "bold,italic", guifg = colors.red } or "",
            { path, gui = "bold" },
            guifg = colors.blue,
          }

          if vim.o.background == "dark" then
            render_ret.guibg = colors.cursorline
          end
          return render_ret
        end,
      })

      vim.keymap.set("n", "<leader>uW", "<cmd>lua require('incline').toggle()<cr>", { desc = "Toggle Incline" })
    end,
  },
}
