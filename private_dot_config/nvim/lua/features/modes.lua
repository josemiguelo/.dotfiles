return {
  "max397574/better-escape.nvim",
  opts = {
    mappings = {
      t = {
        j = {
          -- disable the plugin completely on terminals
          k = false,
        },
      },
    },
  },
  config = function(_, opts)
    require("better_escape").setup(opts)
  end,
}
