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
        hl.SnacksPicker = { bg = "none", nocombine = true }
        hl.SnacksPickerBorder = { bg = "none", nocombine = true }
        hl.Normal = { bg = "none", nocombine = true }
        hl.NormalFloat = { bg = "none", nocombine = true }
        hl.SnacksTerminal = { bg = "none", nocombine = true }
      end,
    },
  },
  {
    "catppuccin/nvim",
    enabled = false,
  },
}
