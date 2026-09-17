return {
  {
    "Grazfather/blinker.nvim",
    dependencies = {
      { "folke/tokyonight.nvim" },
    },
    config = function()
      local colors = require("tokyonight.colors").setup({
        style = vim.o.background == "light" and "day" or "night",
      })

      require("blinker").setup({
        color = colors.orange,
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
