return {
  {
    "fgheng/winbar.nvim",
    enabled = false,
    config = function(opts)
      require("winbar").setup({
        enabled = true,
        icons = {
          seperator = "/",
        },
        exclude_filetype = {
          "fugitive",
          "lazyterm",
          "gitcommit",
        },
      })
    end,
  },
}
