return {
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "storm",
      lualine_bold = true,
      on_colors = function(colors)
        colors.border = "#565f89"
      end,
      on_highlights = function(hl, colors)
        -- vim.notify("on_highlights before")
        -- vim.notify(vim.inspect(hl.FlashLabel))

        hl.CursorLineNr = { fg = colors.cyan }
        hl.LineNrAbove = { fg = colors.blue1 }
        hl.LineNrBelow = { fg = colors.blue1 }
        hl.Comment = { fg = "#7380ba" }

        hl.IlluminatedWord = {}
        hl.IlluminatedCurWord = {}
        hl.IlluminatedWordText = {}
        hl.IlluminatedWordRead = {}
        hl.IlluminatedWordWrite = {}

        -- hl.FlashLabel = { bg = "#ff007c", bold = true, fg = "#c0caf5" }
      end,
    },
  },
}
