return {
  {
    "folke/sidekick.nvim",
    opts = {
      cli = {
        mux = {
          enabled = true,
          backend = "tmux",
        },
        win = {
          split = {
            width = math.floor(vim.o.columns * 0.3), -- 30% of visible window
          },
        },
      },
    },

    keys = {
      {
        "<c-.>",
        false,
        mode = { "n", "t", "i", "x" },
      },
    },
  },
}
