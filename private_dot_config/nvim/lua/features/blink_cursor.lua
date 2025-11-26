return {
  "Grazfather/blinker.nvim",
  config = function()
    local colors = require("tokyonight.colors").setup()
    require("blinker").setup({
      color = colors.blue,
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
}
