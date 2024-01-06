return {
  {
    "nanozuki/tabby.nvim",
    dependencies = {
      { "folke/tokyonight.nvim" },
    },
    config = function()
      local colors = require("tokyonight.colors").setup()
      local theme = {
        fill = "TabLineFill",
        current_tab = { fg = colors.black, bg = colors.blue, style = "bold" },
        tab = { style = "italic" },
      }
      require("tabby.tabline").set(function(line)
        return {
          line.spacer(),
          line.tabs().foreach(function(tab)
            local hl = tab.is_current() and theme.current_tab or theme.tab
            return {
              line.sep(tab.is_current() and "" or "", hl, theme.fill),
              tab.number(),
              string.gsub(tab.name(), "%[..%]", ""),
              line.sep(tab.is_current() and " " or " ", hl, theme.fill),
              hl = hl,
              margin = " ",
            }
          end),
          line.spacer(),
        }
      end)
    end,
  },
}
