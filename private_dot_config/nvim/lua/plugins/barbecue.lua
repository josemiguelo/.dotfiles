return {
  {
    "utilyre/barbecue.nvim",
    dependencies = { "folke/tokyonight.nvim" },
    config = function()
      local colors = require("tokyonight.colors").setup()

      local opts = {
        show_navic = false,
        attach_navic = false,
        exclude_filetypes = { "netrw", "toggleterm" },
        show_modified = true,
        -- custom_section = function(bufnr, winnr)
        --   -- Copied from @akinsho's config
        --   local error_icon = "" -- '✗'
        --   local warning_icon = ""
        --   local info_icon = "" --  
        --   local hint_icon = "⚑" --  ⚑
        --   local errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
        --   local warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
        --   local hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
        --   local info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
        --   local components = {}
        --   if errors > 0 then
        --     components[#components + 1] = { error_icon .. " " .. errors, "DiagnosticError" }
        --   end
        --
        --   if warnings > 0 then
        --     components[#components + 1] =
        --       { (#components > 0 and " " or "") .. warning_icon .. " " .. warnings, "DiagnosticWarning" }
        --   end
        --
        --   if hints > 0 then
        --     components[#components + 1] =
        --       { (#components > 0 and " " or "") .. hint_icon .. " " .. hints, "DiagnosticHint" }
        --   end
        --
        --   if info > 0 then
        --     components[#components + 1] =
        --       { (#components > 0 and " " or "") .. info_icon .. " " .. info, "DiagnosticInfo" }
        --   end
        --
        --   return components
        -- end,
        theme = {
          -- normal = { bold = true, bg = colors.blue },
          normal = { bold = true, fg = colors.fg },
          -- dirname = { fg = colors.black },
          -- basename = { fg = colors.black },
          -- ellipsis = { fg = colors.black },
          -- separator = { fg = colors.black },
          -- modified = { fg = colors.black },
        },
      }
      require("barbecue").setup(opts)
    end,
  },
}
