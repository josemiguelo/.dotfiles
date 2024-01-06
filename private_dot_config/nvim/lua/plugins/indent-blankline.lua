return {
  {
    "lukas-reineke/indent-blankline.nvim",
    config = function(opts)
      vim.opt.list = true
      vim.opt.listchars:append("space:⋅")
      vim.opt.listchars:append("eol:↴")

      require("ibl").setup(opts.opts)
    end,
  },
}
