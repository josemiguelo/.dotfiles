local Util = require("lazy.core.util")

-- local useful_keys = {
--   ["l"] = { api.node.open.edit, opts("Open") },
--   ["o"] = { api.node.open.edit, opts("Open") },
--   ["<CR>"] = { api.node.open.edit, opts("Open") },
--   ["v"] = { api.node.open.vertical, opts("Open: Vertical Split") },
--   ["h"] = { api.node.navigate.parent_close, opts("Close Directory") },
--   ["C"] = { api.tree.change_root_to_node, opts("CD") },
--   ["gtg"] = { telescope_live_grep, opts("Telescope Live Grep") },
--   ["gtf"] = { telescope_find_files, opts("Telescope Find File") },
-- }
--
-- for lhs, v in pairs(useful_keys) do
--   local opt = { noremap = true, silent = true }
--   local hrs = v[1]
--   opt = v[2]
--   vim.keymap.set("n", lhs, hrs, opt)
-- end

return {
  "LunarVim/bigfile.nvim",
  opts = {
    pattern = function(bufnr, filesize_mib)
      local name = vim.api.nvim_buf_get_name(bufnr)

      if name:find("^fugitive:") ~= nil then
        return false
      end

      -- you can't use `nvim_buf_line_count` because this runs on BufReadPre
      local file_contents = vim.fn.readfile(name)
      local file_length = #file_contents
      local filetype = vim.filetype.match({ buf = bufnr })

      -- json
      if file_length > 5000 and filetype == "json" then
        Util.info("Disabling features on big json..")
        return true
      end

      return false
    end,
    features = { -- features to disable
      "indent_blankline",
      "illuminate",
      "lsp",
      "treesitter",
      "matchparen",
    },
  },
}
