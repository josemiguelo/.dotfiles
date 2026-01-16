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
            width = 120, -- set to 0 for default split width
          },
        },
      },
    },
  },
}
