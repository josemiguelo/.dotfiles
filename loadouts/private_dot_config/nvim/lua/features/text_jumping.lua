return {
  {
    "folke/flash.nvim",
    keys = {
      -- Simulate nvim-treesitter incremental selection
      {
        "<c-n>",
        mode = { "n", "o", "x" },
        function()
          require("flash").treesitter({
            actions = {
              ["<c-n>"] = "next",
              ["<c-p>"] = "prev",
            },
            -- don't show the labels, just highlight
            label = {
              after = false,
              before = false,
            },
          })
        end,
        desc = "Treesitter Incremental Selection",
      },
    },
  },
}
