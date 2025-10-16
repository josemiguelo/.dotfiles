return {
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      style = "storm",
      lualine_bold = true,
      dim_inactive = true,
      on_colors = function(colors)
        colors.border = colors.blue6
      end,
      on_highlights = function(hl, colors)
        hl.CursorLineNr = { fg = colors.cyan }
        hl.LineNrAbove = { fg = colors.blue1 }
        hl.LineNrBelow = { fg = colors.blue1 }
        hl.Comment = { fg = "#7380ba" }
      end,
    },
  },
  {
    "catppuccin/nvim",
    enabled = false,
  },
}
