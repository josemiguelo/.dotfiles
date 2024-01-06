return {
  {
    "andymass/vim-matchup",
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
          opts.matchup = {
            enable = true,
            include_match_words = true,
          }
        end,
      },
    },
    event = { "BufReadPost", "BufNewFile" },
  },
}
