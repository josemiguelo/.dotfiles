return {
  {
    "Grazfather/blinker.nvim",
    dependencies = {
      { "olimorris/onedarkpro.nvim" },
    },
    config = function()
      local colors = require("onedarkpro.helpers").get_colors()

      require("blinker").setup({
        color = colors.red,
      })
    end,
    keys = {
      {
        "<leader>B",
        function()
          require("blinker").blink_cursorline()
        end,
        desc = "Blink cursor",
        mode = { "n" },
      },
    },
  },
}
