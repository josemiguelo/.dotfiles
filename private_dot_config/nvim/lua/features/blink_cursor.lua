return {
  {
    "Grazfather/blinker.nvim",
    dependencies = {
      { "olimorris/onedarkpro.nvim", "folke/snacks.nvim" },
    },
    config = function()
    -- stylua: ignore
    local colors = vim.o.background == "dark"
      and require("onedarkpro.helpers").get_colors()
      or require("tokyonight.colors").setup()

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
  },
}
